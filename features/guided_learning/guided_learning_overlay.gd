class_name GuidedLearningOverlay
extends ColorRect

signal closed

enum PageState { ANSWERING, RESULTS }

@export var sources: Array[GuidedLearningSource] = []
@export_multiline var intro_text: String = (
	"[b]Reliability Indicators[/b]\n\n"
	+ "All the indicators of reliability or unreliability in the fake sources "
	+ "can be applied to anything you encounter online in real life.\n\n"
	+ "Multiple [color=#f5a0a0]negative[/color] indicators mean a source is likely [b]unreliable[/b], "
	+ "while multiple [color=#a0f5c0]positive[/color] indicators show a more [b]reliable[/b] one.\n\n"
	+ "Match up the actual indicators to the werewolf sources to show why some are "
	+ "reliable and others are not.\n\n"
	+ "[i]Drag indicators from the pools on the right onto each source, then click "
	+ "Submit Response to see how you did.[/i]"
)

# -- state ---------------------------------------------------------------------
var _sources: Array[GuidedLearningSource] = []
var _current_page: int = 0              # 0 = intro, 1..N = sources[page-1]
var _dropped: Dictionary = {}           # source_index -> Array[int]
var _states: Dictionary = {}            # source_index -> PageState
var _scene_instance: Control = null
var _audio_player: AudioStreamPlayer = null
var _audio_scrubbing := false
var _zoom_level   := 1.0

const _ZOOM_STEP    := 0.1
const _ZOOM_MIN     := 0.25
const _ZOOM_MAX     := 3.0
const _ZOOM_DEFAULT := 1.0

# -- ui refs -------------------------------------------------------------------
@onready var _page_label: Label = %PageLabel
@onready var _chrome_url: Label = %ChromeUrl
@onready var _site_container: SubViewportContainer = %SiteContainer
@onready var _site_viewport: SubViewport = %SiteViewport
@onready var _image_display: TextureRect = %ImageDisplay
@onready var _video_display: VideoPlayerControl = %VideoDisplay
@onready var _audio_display: Control = %AudioDisplay
@onready var _audio_title: Label = %AudioTitle
@onready var _audio_play_btn: Button = %AudioPlayBtn
@onready var _audio_scrubber: HSlider = %AudioScrubber
@onready var _audio_time: Label = %AudioTimeLabel
@onready var _drop_label: Label = %DropLabel
@onready var _score_label: Label = %ScoreLabel
@onready var _drop_flow: HFlowContainer = %DropFlow
@onready var _results_label: Label = %ResultsLabel
@onready var _results_flow: HFlowContainer = %ResultsFlow
@onready var _results_zone: PanelContainer = %ResultsZone
@onready var _neg_pool_flow: HFlowContainer = %NegPoolFlow
@onready var _pos_pool_flow: HFlowContainer = %PosPoolFlow
@onready var _pool_section: VBoxContainer = %PoolSection
@onready var _drop_zone: PanelContainer = %DropZone
@onready var _prev_btn: Button = %PrevBtn
@onready var _submit_btn: Button = %SubmitBtn
@onready var _next_btn: Button = %NextBtn
@onready var _done_btn: Button = %DoneBtn
@onready var _sub_label: Label = %SubLabel
@onready var _intro_panel: Control = %IntroPanel
@onready var _intro_text: RichTextLabel = %IntroText
@onready var _content: HBoxContainer = %Content
@onready var _end_panel: Control = %EndPanel
@onready var _end_score: Label = %EndScore
@onready var _end_flavor: Label = %EndFlavor
@onready var _main_menu_btn: Button = %MainMenuBtn
@onready var _play_again_btn: Button = %PlayAgainBtn
@onready var _zoom_out_btn: Button = %ZoomOutBtn
@onready var _zoom_label: Button  = %ZoomLabel
@onready var _zoom_in_btn: Button = %ZoomInBtn


func _ready() -> void:
	visible = false
	color = Color(0, 0, 0, 0)
	mouse_filter = MOUSE_FILTER_IGNORE

	_sources = sources
	for i in range(_sources.size()):
		_dropped[i] = []
		_states[i] = PageState.ANSWERING

	_intro_text.text = intro_text

	_site_container.resized.connect(_sync_viewport_size)
	_sync_viewport_size.call_deferred()

	_prev_btn.pressed.connect(_on_prev)
	_submit_btn.pressed.connect(_on_submit)
	_next_btn.pressed.connect(_on_next)
	_done_btn.pressed.connect(_on_done)
	_audio_play_btn.pressed.connect(_on_audio_play)
	_audio_scrubber.drag_started.connect(func(): _audio_scrubbing = true)
	_audio_scrubber.drag_ended.connect(func(_changed: bool):
		if _audio_player and _audio_player.stream:
			_audio_player.seek(_audio_scrubber.value * _audio_player.stream.get_length())
		_audio_scrubbing = false
	)
	DayClock.day_ended.connect(_stop_media)
	_zoom_out_btn.pressed.connect(_on_zoom_out)
	_zoom_label.pressed.connect(_on_zoom_reset)
	_zoom_in_btn.pressed.connect(_on_zoom_in)
	_main_menu_btn.pressed.connect(func(): pass)
	_play_again_btn.pressed.connect(_on_play_again)

	_drop_zone.set_drag_forwarding(
		func(_p) -> Variant: return null,
		func(_p, data) -> bool:
			return (
				data is Dictionary
				and data.has("indicator_index")
				and _states.get(_src_index(), PageState.ANSWERING) == PageState.ANSWERING
			),
		func(_p, data) -> void: _on_indicator_dropped(int(data["indicator_index"]))
	)

	_build_pool_chips()


# -- public -------------------------------------------------------------------

func run() -> void:
	_current_page = 0
	mouse_filter = MOUSE_FILTER_STOP
	color = Color(0.04, 0.04, 0.06, 0.0)
	visible = true
	_show_page(0)
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "color:a", 0.97, 0.45)


# -- helpers ------------------------------------------------------------------

func _src_index() -> int:
	return _current_page - 1

func _source() -> GuidedLearningSource:
	return _sources[_src_index()]


# -- page navigation ----------------------------------------------------------

func _show_page(index: int) -> void:
	_current_page = index
	var is_intro: bool = (index == 0)
	var si: int = _src_index()
	var state: PageState = _states.get(si, PageState.ANSWERING)
	var is_results: bool = not is_intro and state == PageState.RESULTS
	var is_answering: bool = not is_intro and state == PageState.ANSWERING
	var is_last: bool = (index == _sources.size())

	# Header
	_page_label.text = "" if is_intro else "%d / %d" % [index, _sources.size()]
	_chrome_url.text = "" if is_intro else _source().url

	# Nav
	_prev_btn.disabled = (index == 0)
	_submit_btn.visible = is_answering
	_next_btn.visible = is_intro or (is_results and not is_last)
	_done_btn.visible = is_results and is_last

	# Layout
	_sub_label.visible = not is_intro
	_intro_panel.visible = is_intro
	_content.visible = not is_intro

	# Zoom — reset on every page nav; only show controls for SCENE sources
	var is_scene: bool = not is_intro and _source().type == GuidedLearningSource.Type.SCENE
	_zoom_level = _ZOOM_DEFAULT
	_zoom_label.text = "100%"
	_zoom_out_btn.visible = is_scene
	_zoom_label.visible = is_scene
	_zoom_in_btn.visible = is_scene
	_zoom_out_btn.disabled = false
	_zoom_in_btn.disabled = false

	if not is_intro:
		_drop_label.text = (
			"Your submitted answers:" if is_results
			else "Drag the indicators that apply to this source:"
		)
		_pool_section.visible = is_answering
		_score_label.visible = is_results
		_results_label.visible = is_results
		_results_zone.visible = is_results

		if is_results:
			_update_score(si)

		_load_content(_source())
		_rebuild_drop_zone()
		_rebuild_results_zone()


func _sync_viewport_size() -> void:
	var s := Vector2i(_site_container.size)
	if s.x > 4 and s.y > 4:
		_site_viewport.size = s
		_apply_zoom()


func _on_zoom_out() -> void:
	_set_zoom(_zoom_level - _ZOOM_STEP)


func _on_zoom_in() -> void:
	_set_zoom(_zoom_level + _ZOOM_STEP)


func _on_zoom_reset() -> void:
	_set_zoom(_ZOOM_DEFAULT)


func _set_zoom(level: float) -> void:
	_zoom_level = clampf(level, _ZOOM_MIN, _ZOOM_MAX)
	_zoom_label.text = str(roundi(_zoom_level * 100)) + "%"
	_zoom_out_btn.disabled = _zoom_level <= _ZOOM_MIN
	_zoom_in_btn.disabled = _zoom_level >= _ZOOM_MAX
	_apply_zoom()


func _apply_zoom() -> void:
	if _scene_instance == null:
		return
	var vp_size := Vector2(_site_viewport.size)
	_scene_instance.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_scene_instance.pivot_offset = Vector2.ZERO
	_scene_instance.position = Vector2.ZERO
	_scene_instance.scale = Vector2(_zoom_level, _zoom_level)
	_scene_instance.size = vp_size / _zoom_level


func _process(_delta: float) -> void:
	if _audio_player == null or not _audio_player.playing or _audio_scrubbing:
		return
	var stream := _audio_player.stream
	if stream == null:
		return
	var length := stream.get_length()
	if length <= 0.0:
		return
	var pos := _audio_player.get_playback_position()
	_audio_scrubber.set_value_no_signal(pos / length)
	_audio_time.text = "%s / %s" % [_fmt_time(pos), _fmt_time(length)]


static func _fmt_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]


func _load_content(src: GuidedLearningSource) -> void:
	# Stop any running video/audio first
	_video_display.stop()
	if _audio_player and _audio_player.playing:
		_audio_player.stop()

	_site_container.visible = false
	_image_display.visible = false
	_video_display.visible = false
	_audio_display.visible = false

	match src.type:
		GuidedLearningSource.Type.SCENE:
			_site_container.visible = true
			_load_scene(src.scene)

		GuidedLearningSource.Type.IMAGE:
			_image_display.visible = true
			_image_display.texture = src.image

		GuidedLearningSource.Type.VIDEO:
			_video_display.visible = true
			_video_display.load_stream(src.video)

		GuidedLearningSource.Type.AUDIO:
			_audio_display.visible = true
			_audio_title.text = src.display_name
			_audio_play_btn.text = "▶  Play"
			_audio_scrubber.set_value_no_signal(0.0)
			_audio_time.text = "0:00 / 0:00"
			if not _audio_player:
				_audio_player = AudioStreamPlayer.new()
				add_child(_audio_player)
				_audio_player.finished.connect(func():
					_audio_play_btn.text = "▶  Play"
					_audio_scrubber.set_value_no_signal(0.0)
					_audio_time.text = "0:00 / 0:00"
				)
			_audio_player.stream = src.audio


func _load_scene(scene: PackedScene) -> void:
	if _scene_instance:
		_scene_instance.queue_free()
		_scene_instance = null
	if scene:
		_scene_instance = scene.instantiate() as Control
		if _scene_instance:
			_site_viewport.add_child(_scene_instance)
			_apply_zoom()


func _on_audio_play() -> void:
	if not _audio_player:
		return
	if _audio_player.playing:
		_audio_player.stop()
		_audio_play_btn.text = "▶  Play"
	else:
		_audio_player.play()
		_audio_play_btn.text = "⏹  Stop"


func _on_prev() -> void:
	if _current_page > 0:
		_show_page(_current_page - 1)


func _on_next() -> void:
	if _current_page < _sources.size():
		_show_page(_current_page + 1)


func _on_submit() -> void:
	_states[_src_index()] = PageState.RESULTS
	_show_page(_current_page)


func _on_done() -> void:
	_stop_media()
	_show_end_screen()


func _stop_media() -> void:
	_video_display.stop()
	if _audio_player and _audio_player.playing:
		_audio_player.stop()
		_audio_play_btn.text = "▶  Play"
		_audio_scrubber.set_value_no_signal(0.0)
		_audio_time.text = "0:00 / 0:00"


func _show_end_screen() -> void:
	var total_correct := 0
	var total_hits := 0
	for i in range(_sources.size()):
		var correct: Array[int] = _sources[i].get_indicator_indices()
		total_correct += correct.size()
		for idx: int in (_dropped.get(i, []) as Array):
			if correct.has(idx):
				total_hits += 1

	var pct := float(total_hits) / float(total_correct) if total_correct > 0 else 0.0
	_end_score.text = "%d / %d indicators correctly identified" % [total_hits, total_correct]
	_end_flavor.text = _end_flavor_text(pct)

	_end_panel.modulate.a = 0.0
	_end_panel.visible = true
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_end_panel, "modulate:a", 1.0, 0.5)


func _on_play_again() -> void:
	_play_again_btn.disabled = true
	PodcastPlayer.stop()
	DayClock.reset()
	GameManager.reset()
	Texting.reset()
	DayClock.start()
	get_tree().change_scene_to_file("res://features/room/room.tscn")


func _end_flavor_text(pct: float) -> String:
	if pct >= 1.0:
		return "Perfect score — you spotted every indicator across all sources."
	elif pct >= 0.75:
		return "Strong work. You identified most of the reliability signals."
	elif pct >= 0.5:
		return "Good effort. With practice you'll catch the subtler indicators."
	elif pct >= 0.25:
		return "Keep these indicators in mind next time you evaluate a source."
	else:
		return "Take another look at the indicator list. It gets easier with practice."


# -- score --------------------------------------------------------------------

func _update_score(si: int) -> void:
	var user_drops: Array = _dropped[si]
	var correct: Array[int] = _sources[si].get_indicator_indices()
	var hits: int = 0
	for idx: int in user_drops:
		if correct.has(idx):
			hits += 1
	_score_label.text = "%d / %d correct" % [hits, correct.size()]


# -- drop handling ------------------------------------------------------------

func _on_indicator_dropped(indicator_index: int) -> void:
	var drops: Array = _dropped[_src_index()]
	if not drops.has(indicator_index):
		drops.append(indicator_index)
		_rebuild_drop_zone()


func _rebuild_drop_zone() -> void:
	for child in _drop_flow.get_children():
		child.queue_free()

	var si: int = _src_index()
	var state: PageState = _states.get(si, PageState.ANSWERING)
	var user_drops: Array = _dropped[si]

	if state == PageState.RESULTS:
		if user_drops.is_empty():
			_drop_flow.add_child(_hint_label("No indicators submitted."))
		else:
			for idx: int in user_drops:
				_drop_flow.add_child(_static_chip(idx))
		return

	# ANSWERING
	if user_drops.is_empty():
		var count: int = _source().get_indicator_indices().size()
		_drop_flow.add_child(_hint_label(
			"Find %d indicator%s for this source" % [count, "s" if count != 1 else ""]
		))
	else:
		for idx: int in user_drops:
			_drop_flow.add_child(_removable_chip(idx))


func _rebuild_results_zone() -> void:
	for child in _results_flow.get_children():
		child.queue_free()

	var si: int = _src_index()
	if _states.get(si, PageState.ANSWERING) != PageState.RESULTS:
		return

	var user_drops: Array = _dropped[si]
	var correct: Array[int] = _sources[si].get_indicator_indices()

	for idx: int in correct:
		_results_flow.add_child(_static_chip(idx))
	for idx: int in user_drops:
		if not correct.has(idx):
			_results_flow.add_child(_wrong_chip(idx))


# -- chip factories -----------------------------------------------------------

func _static_chip(indicator_index: int) -> Button:
	var ind := ReliabilityIndicatorData.get_indicators()[indicator_index]
	var chip := Button.new()
	chip.text = ind.label
	chip.focus_mode = Control.FOCUS_NONE
	chip.disabled = true
	chip.theme_type_variation = &"GuidedChipPos" if ind.is_positive else &"GuidedChipNeg"
	return chip


func _wrong_chip(indicator_index: int) -> Button:
	var chip := Button.new()
	chip.text = ReliabilityIndicatorData.get_indicators()[indicator_index].label
	chip.focus_mode = Control.FOCUS_NONE
	chip.disabled = true
	chip.theme_type_variation = &"GuidedChipWrong"
	return chip


func _removable_chip(indicator_index: int) -> Button:
	var ind := ReliabilityIndicatorData.get_indicators()[indicator_index]
	var chip := Button.new()
	chip.text = ind.label
	chip.focus_mode = Control.FOCUS_NONE
	chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	chip.theme_type_variation = &"GuidedChipPos" if ind.is_positive else &"GuidedChipNeg"
	chip.pressed.connect(func():
		(_dropped[_src_index()] as Array).erase(indicator_index)
		_rebuild_drop_zone()
	)
	return chip


func _hint_label(t: String) -> Label:
	var lbl := Label.new()
	lbl.text = t
	lbl.theme_type_variation = &"GuidedHint"
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


# -- pool ---------------------------------------------------------------------

func _build_pool_chips() -> void:
	for child in _neg_pool_flow.get_children():
		child.queue_free()
	for child in _pos_pool_flow.get_children():
		child.queue_free()
	var indicators := ReliabilityIndicatorData.get_indicators()
	for i in range(indicators.size()):
		var chip := _pool_chip(i)
		if indicators[i].is_positive:
			_pos_pool_flow.add_child(chip)
		else:
			_neg_pool_flow.add_child(chip)


func _pool_chip(indicator_index: int) -> Button:
	var ind := ReliabilityIndicatorData.get_indicators()[indicator_index]
	var chip := Button.new()
	chip.text = ind.label
	chip.focus_mode = Control.FOCUS_NONE
	chip.mouse_default_cursor_shape = Control.CURSOR_DRAG
	var variation: StringName = &"GuidedChipPos" if ind.is_positive else &"GuidedChipNeg"
	chip.theme_type_variation = variation
	chip.set_drag_forwarding(
		func(_pos) -> Variant:
			var preview := Button.new()
			preview.text = chip.text
			preview.theme = theme
			preview.theme_type_variation = variation
			chip.set_drag_preview(preview)
			return {"indicator_index": indicator_index},
		func(_pos, _data) -> bool: return false,
		func(_pos, _data) -> void: pass
	)
	return chip
