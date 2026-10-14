class_name SourceCheckScreen extends Control
## 04 — Source check. One round per source: a gut call on whether it's reliable, then
## the flags it carries, then the reveal. Ends on a board of every round.

signal play_again_requested
signal main_menu_requested

enum Phase { INTRO, VERDICT, CHECKLIST, REVEAL, RESULTS }

const _FlagRowScene := preload("res://features/game_end/components/flag_row.tscn")
const _DotScene := preload("res://features/game_end/components/progress_dot.tscn")
const _ResultCardScene := preload("res://features/game_end/components/round_result_card.tscn")

const _INTRO_SECONDS := 1.3
const _PAW_DRIFT_SECONDS := 14.0
## The browser is big while the player makes the call, then shrinks beside the flags.
const _BROWSER_BIG := Vector2(1200, 533)
const _BROWSER_SMALL := Vector2(760, 484)
## Sites are laid out at this width; a narrower frame scales the page instead of reflowing it.
const _SITE_WIDTH := 1192.0
const _IMAGE_MAX_WIDTH := 600.0
## Scroll distance before the "scroll to see it all" hint is dismissed.
const _SCROLL_HINT_DISMISS := 40.0
const _DOT_SIZE := Vector2(19, 12)
const _DOT_CURRENT_SIZE := Vector2(48, 12)
const _PANEL_SLIDE := 600.0
const _RISE := 53.0
## Wrong-call reveal: a beat on the player's picks, then the swap and a header flash.
const _SWAP_HOLD := 0.6
const _SWAP_FLASHES := 2
const _SWAP_FLASH := Color(2.5, 2.5, 2.5)
## Longer than any phase animation, so stepping a tween by it lands on its final frame.
const _FINISH_STEP := 10.0

@export var play_icon: Texture2D
@export var pause_icon: Texture2D
@export var next_icon: Texture2D

var _sources: Array[GuidedLearningSource] = []
var _round := 0
var _phase := Phase.INTRO
var _called_reliable := false
## Which flag list is on screen: the player's call while ticking, the real answer on reveal.
var _shown_reliable := false
var _picks: Dictionary = {}  # indicator index -> true
var _history: Array[Dictionary] = []
var _rows: Dictionary = {}  # indicator index -> FlagRow
## Only the flags matching the player's call are shown: green for reliable, red for not.
var _green_rows: Array[int] = []
var _red_rows: Array[int] = []
var _scene_instance: Node = null
var _scrolled := false
var _tweens: Array[Tween] = []

@onready var _paws: TextureRect = %Paws
@onready var _dots: HBoxContainer = %Dots
@onready var _round_label: Label = %RoundLabel
@onready var _browser: Control = %Browser
@onready var _nav_bar: SiteNavBar = %NavBar
@onready var _scene_holder: Control = %SceneHolder
@onready var _scene_container: SubViewportContainer = %SceneContainer
@onready var _scene_viewport: SubViewport = %SceneViewport
@onready var _image_area: PanelContainer = %ImageArea
@onready var _image_scroll: ScrollContainer = %ImageScroll
@onready var _image_margin: MarginContainer = %ImageMargin
@onready var _image_view: TextureRect = %ImageView
@onready var _video_area: PanelContainer = %VideoArea
@onready var _video_view: VideoPlayerControl = %VideoView
@onready var _audio_area: PanelContainer = %AudioArea
@onready var _audio_title: Label = %AudioTitle
@onready var _audio_btn: Button = %AudioBtn
@onready var _audio_player: AudioStreamPlayer = %AudioPlayer
@onready var _scroll_hint: PanelContainer = %ScrollHint
@onready var _stamp: PanelContainer = %Stamp
@onready var _stamp_label: Label = %StampLabel
@onready var _ask_layer: Control = %AskLayer
@onready var _call_layer: Control = %CallLayer
@onready var _verdict: PanelContainer = %Verdict
@onready var _verdict_label: Label = %VerdictLabel
@onready var _change_btn: Button = %ChangeBtn
@onready var _call_msg: Label = %CallMsg
@onready var _lesson: Label = %Lesson
@onready var _panel_layer: Control = %PanelLayer
@onready var _pick_count: Label = %PickCount
@onready var _panel_hint: Label = %PanelHint
@onready var _green_head: HBoxContainer = %GreenHead
@onready var _green_list: VBoxContainer = %GreenList
@onready var _red_head: HBoxContainer = %RedHead
@onready var _red_list: VBoxContainer = %RedList
@onready var _panel_btn: Button = %PanelBtn
@onready var _results: Control = %Results
@onready var _results_sub: Label = %ResultsSub
@onready var _cards: HFlowContainer = %Cards
@onready var _intro: Control = %Intro
@onready var _intro_type: Label = %IntroType
@onready var _intro_round: Label = %IntroRound


func _ready() -> void:
	%ReliableBtn.pressed.connect(_choose.bind(true))
	%UnreliableBtn.pressed.connect(_choose.bind(false))
	_change_btn.pressed.connect(_enter_verdict.bind(false))
	_panel_btn.pressed.connect(_on_panel_btn)
	%PlayAgainBtn.pressed.connect(func(): play_again_requested.emit())
	%MainMenuBtn.pressed.connect(func(): main_menu_requested.emit())
	_audio_btn.pressed.connect(_toggle_audio)
	_audio_player.finished.connect(_set_audio_btn_playing.bind(false))
	_scene_holder.resized.connect(_fit_scene)
	_image_scroll.resized.connect(_refresh_image_size)
	_image_scroll.get_v_scroll_bar().value_changed.connect(_on_image_scrolled)

	_build_flag_rows()
	_start_paw_drift()


func start(sources: Array[GuidedLearningSource]) -> void:
	_sources = sources
	_history.clear()
	_build_dots()
	_start_round(0)


# -- rounds --------------------------------------------------------------------

func _start_round(index: int) -> void:
	_finish_tweens()
	_round = index
	_phase = Phase.INTRO
	_picks.clear()
	_scrolled = false

	_results.visible = false
	_browser.visible = false
	_ask_layer.visible = false
	_call_layer.visible = false
	_panel_layer.visible = false
	_stamp.visible = false
	_refresh_top_bar()

	var source := _sources[_round]
	_show_content(source)
	for indicator_index: int in _rows:
		(_rows[indicator_index] as FlagRow).set_state(FlagRow.State.IDLE)

	_intro_type.text = source.source_type.to_upper()
	_intro_round.text = "ROUND %02d" % (_round + 1)
	_intro.visible = true
	_intro.modulate.a = 0.0
	_intro.position = Vector2(0, 24)

	# Untracked: its callback starts the next phase, which finishes every tracked tween.
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_intro, "modulate:a", 1.0, _INTRO_SECONDS * 0.22)
	tw.parallel().tween_property(_intro, "position:y", 0.0, _INTRO_SECONDS * 0.22)
	tw.tween_interval(_INTRO_SECONDS * 0.5)
	tw.tween_property(_intro, "modulate:a", 0.0, _INTRO_SECONDS * 0.28)
	tw.parallel().tween_property(_intro, "position:y", -24.0, _INTRO_SECONDS * 0.28)
	tw.tween_callback(_enter_verdict.bind(true))


## [param first_entry] pops the browser in; otherwise it grows back from the checklist.
func _enter_verdict(first_entry: bool) -> void:
	_finish_tweens()
	_phase = Phase.VERDICT
	_intro.visible = false
	_panel_layer.visible = false
	_call_layer.visible = false
	_set_rows_interactive(false)

	_browser.visible = true
	if first_entry:
		_browser.size = _BROWSER_BIG
		_browser.pivot_offset = _BROWSER_BIG / 2.0
		_browser.scale = Vector2(0.6, 0.6)
		_browser.modulate.a = 0.0
		var pop := _tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(_browser, "scale", Vector2.ONE, 0.7)
		pop.parallel().tween_property(_browser, "modulate:a", 1.0, 0.3)
	else:
		_resize_browser(_BROWSER_BIG)

	_rise_in(_ask_layer, 0.5 if first_entry else 0.15)
	_refresh_scroll_hint()


func _choose(reliable: bool) -> void:
	if _phase != Phase.VERDICT:
		return
	if reliable != _called_reliable:
		_picks.clear()
	_called_reliable = reliable
	_enter_checklist()


func _enter_checklist() -> void:
	_finish_tweens()
	_phase = Phase.CHECKLIST
	_ask_layer.visible = false
	_resize_browser(_BROWSER_SMALL)

	_verdict.theme_type_variation = &"SCVerdictGood" if _called_reliable else &"SCVerdictBad"
	_verdict_label.text = "RELIABLE" if _called_reliable else "NOT RELIABLE"
	_change_btn.visible = true
	_call_msg.visible = false
	_lesson.visible = false
	_rise_in(_call_layer, 0.5)

	_panel_hint.text = "Tick every flag you can find in this source."
	_panel_btn.text = "Lock it in!"
	_panel_btn.icon = null
	_panel_btn.theme_type_variation = &"SCYellowBtn"
	_refresh_pick_count()
	_slide_panel_in()

	_show_flags(_called_reliable)

	_set_rows_interactive(true)
	var order := _shown_rows()
	for i in range(order.size()):
		var row: FlagRow = _rows[order[i]]
		row.set_state(FlagRow.State.PICKED if _picks.get(order[i], false) else FlagRow.State.IDLE)
		row.modulate.a = 0.0
		_tween().tween_property(row, "modulate:a", 1.0, 0.3).set_delay(0.55 + i * 0.04)

	_refresh_scroll_hint()


func _lock_in() -> void:
	_finish_tweens()
	_phase = Phase.REVEAL
	_set_rows_interactive(false)

	var source := _sources[_round]
	var correct := _called_reliable == source.is_reliable
	if correct:
		_reveal_flags(source)
	else:
		_swap_to_real_flags(source)

	_change_btn.visible = false
	_call_msg.visible = true
	_call_msg.text = "Nice call!" if correct else "Not quite!"
	_call_msg.theme_type_variation = &"SCCallGood" if correct else &"SCCallBad"
	_lesson.text = source.explanation
	_lesson.visible = true
	_lesson.modulate.a = 0.0
	_tween().tween_property(_lesson, "modulate:a", 1.0, 0.5).set_delay(0.6)

	_pick_count.text = ""
	_panel_hint.text = "Here's what was really on the page." if correct \
		else "It was the other way! These are the flags to look for."
	_panel_btn.text = "See results" if _is_last_round() else "Next round"
	_panel_btn.icon = next_icon
	_panel_btn.theme_type_variation = &"SCTealBtn"

	_stamp_in(source.is_reliable)
	_refresh_scroll_hint()


func _reveal_flags(source: GuidedLearningSource) -> void:
	var present := source.get_indicator_indices()
	_show_flags(source.is_reliable)
	var order := _shown_rows()
	for i in range(order.size()):
		var indicator_index := order[i]
		var picked: bool = _picks.get(indicator_index, false)
		var state := FlagRow.State.ABSENT
		if present.has(indicator_index):
			state = FlagRow.State.SPOTTED if picked else FlagRow.State.MISSED
		elif picked:
			state = FlagRow.State.NOT_HERE
		(_rows[indicator_index] as FlagRow).set_state(state, 0.3 + i * 0.05)


## A wrong call shows the other list: the panel slides out on the player's picks, comes
## back on the real flags, and the new header flashes so the switch can't be missed.
func _swap_to_real_flags(source: GuidedLearningSource) -> void:
	var head := _green_head if source.is_reliable else _red_head
	var tw := _tween()
	tw.tween_interval(_SWAP_HOLD)
	tw.tween_property(_panel_layer, "position:x", _PANEL_SLIDE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_panel_layer, "modulate:a", 0.0, 0.3)
	tw.tween_callback(_reveal_flags.bind(source))
	tw.tween_property(_panel_layer, "position:x", 0.0, 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_panel_layer, "modulate:a", 1.0, 0.2)
	for i in range(_SWAP_FLASHES):
		tw.tween_property(head, "modulate", Color.WHITE, 0.35).from(_SWAP_FLASH)


func _on_panel_btn() -> void:
	if _phase == Phase.CHECKLIST:
		_lock_in()
		return
	if _phase != Phase.REVEAL:
		return

	_history.append(_summarize())
	if _is_last_round():
		_show_results()
	else:
		_start_round(_round + 1)


func _summarize() -> Dictionary:
	var source := _sources[_round]
	var real_rows := _green_rows if source.is_reliable else _red_rows
	var present := source.get_indicator_indices().filter(
		func(indicator_index: int) -> bool: return real_rows.has(indicator_index))
	var spotted := 0
	var wrong := 0
	for indicator_index: int in _picks:
		if !_picks[indicator_index]:
			continue
		if present.has(indicator_index):
			spotted += 1
		else:
			wrong += 1
	return {
		"source": source, "called_reliable": _called_reliable,
		"spotted": spotted, "present": present.size(), "wrong": wrong,
	}


func _is_last_round() -> bool:
	return _round == _sources.size() - 1


# -- results -------------------------------------------------------------------

func _show_results() -> void:
	_finish_tweens()
	_phase = Phase.RESULTS
	_clear_source()
	_browser.visible = false
	_call_layer.visible = false
	_panel_layer.visible = false
	_refresh_top_bar()

	for card in _cards.get_children():
		_cards.remove_child(card)
		card.queue_free()

	var correct := 0
	for i in range(_history.size()):
		var entry := _history[i]
		var source: GuidedLearningSource = entry.source
		if entry.called_reliable == source.is_reliable:
			correct += 1
		var card: RoundResultCard = _ResultCardScene.instantiate()
		_cards.add_child(card)
		card.configure(i + 1, source, entry.called_reliable, entry.spotted, entry.present, entry.wrong)
		card.modulate.a = 0.0
		_tween().tween_property(card, "modulate:a", 1.0, 0.4).set_delay(0.4 + i * 0.08)

	_results_sub.text = "You called %d of %d sources right." % [correct, _history.size()]
	_results.visible = true
	_results.modulate.a = 0.0
	_tween().tween_property(_results, "modulate:a", 1.0, 0.4)


# -- flags ---------------------------------------------------------------------

func _build_flag_rows() -> void:
	var indicators := ReliabilityIndicatorData.get_indicators()
	for i in range(indicators.size()):
		var row: FlagRow = _FlagRowScene.instantiate()
		(_green_list if indicators[i].is_positive else _red_list).add_child(row)
		row.configure(i, indicators[i])
		row.toggled.connect(_on_flag_toggled)
		_rows[i] = row
		(_green_rows if indicators[i].is_positive else _red_rows).append(i)


func _show_flags(reliable: bool) -> void:
	_shown_reliable = reliable
	_green_head.visible = reliable
	_green_list.visible = reliable
	_red_head.visible = !reliable
	_red_list.visible = !reliable


func _shown_rows() -> Array[int]:
	return _green_rows if _shown_reliable else _red_rows


func _on_flag_toggled(indicator_index: int) -> void:
	if _phase != Phase.CHECKLIST:
		return
	var picked: bool = !_picks.get(indicator_index, false)
	_picks[indicator_index] = picked
	(_rows[indicator_index] as FlagRow).set_state(FlagRow.State.PICKED if picked else FlagRow.State.IDLE)
	_refresh_pick_count()


func _set_rows_interactive(interactive: bool) -> void:
	for indicator_index: int in _rows:
		(_rows[indicator_index] as FlagRow).set_interactive(interactive)


func _refresh_pick_count() -> void:
	var count := 0
	for indicator_index: int in _picks:
		if _picks[indicator_index]:
			count += 1
	_pick_count.text = "%d ticked" % count


# -- top bar -------------------------------------------------------------------

func _build_dots() -> void:
	for dot in _dots.get_children():
		_dots.remove_child(dot)
		dot.queue_free()
	for i in range(_sources.size()):
		_dots.add_child(_DotScene.instantiate())


func _refresh_top_bar() -> void:
	var done := _phase == Phase.RESULTS
	for i in range(_dots.get_child_count()):
		var dot := _dots.get_child(i) as Panel
		var current := i == _round && !done
		dot.custom_minimum_size = _DOT_CURRENT_SIZE if current else _DOT_SIZE
		if done || i < _round:
			dot.theme_type_variation = &"SCDotDone"
		else:
			dot.theme_type_variation = &"SCDotCurrent" if current else &"SCDot"

	_round_label.text = "Results" if done else "Round %d of %d" % [_round + 1, _sources.size()]


# -- source content ------------------------------------------------------------

func _show_content(source: GuidedLearningSource) -> void:
	_clear_source()

	var is_site := source.type == GuidedLearningSource.Type.SCENE
	_nav_bar.visible = is_site
	_nav_bar.set_url(source.url)
	_scene_holder.visible = is_site
	_image_area.visible = source.type == GuidedLearningSource.Type.IMAGE
	_video_area.visible = source.type == GuidedLearningSource.Type.VIDEO
	_audio_area.visible = source.type == GuidedLearningSource.Type.AUDIO

	match source.type:
		GuidedLearningSource.Type.SCENE:
			if source.scene:
				_scene_instance = source.scene.instantiate()
				_scene_viewport.add_child(_scene_instance)
		GuidedLearningSource.Type.IMAGE:
			_image_view.texture = source.image
			_image_scroll.scroll_vertical = 0
			_refresh_image_size()
		GuidedLearningSource.Type.VIDEO:
			if source.video:
				_video_view.load_stream(source.video)
		GuidedLearningSource.Type.AUDIO:
			_audio_title.text = source.display_name
			_audio_player.stream = source.audio


## Frees the embedded source and silences any media.
func _clear_source() -> void:
	_video_view.stop()
	_audio_player.stop()
	_set_audio_btn_playing(false)
	if _scene_instance:
		_scene_instance.queue_free()
		_scene_instance = null


func _fit_scene() -> void:
	var holder_size := _scene_holder.size
	if holder_size.x <= 0.0:
		return
	var s := minf(1.0, holder_size.x / _SITE_WIDTH)
	_scene_container.scale = Vector2(s, s)
	_scene_container.size = holder_size / s


## A proportionally-expanding TextureRect reports no minimum size, so inside a scroll
## container it collapses to nothing. The width is capped below what the scroll offers
## so it never feeds back into the layout; the height follows from it.
func _refresh_image_size() -> void:
	var texture := _image_view.texture
	if !texture || texture.get_width() <= 0:
		return

	var available := _image_scroll.size.x \
		- _image_margin.get_theme_constant("margin_left") \
		- _image_margin.get_theme_constant("margin_right")
	if available <= 0.0:
		return

	var width := roundf(minf(_IMAGE_MAX_WIDTH, available))
	var target := Vector2(width, roundf(texture.get_height() * width / texture.get_width()))
	if _image_view.custom_minimum_size.is_equal_approx(target):
		return

	_image_view.custom_minimum_size = target
	_refresh_scroll_hint()


func _on_image_scrolled(value: float) -> void:
	if !_scrolled && value > _SCROLL_HINT_DISMISS:
		_scrolled = true
		_refresh_scroll_hint()


func _refresh_scroll_hint() -> void:
	var playing := _phase == Phase.VERDICT || _phase == Phase.CHECKLIST
	var tall := _image_view.custom_minimum_size.y > _image_scroll.size.y
	_scroll_hint.visible = playing && _image_area.visible && tall && !_scrolled


func _toggle_audio() -> void:
	if _audio_player.playing:
		_audio_player.stop()
		_set_audio_btn_playing(false)
	else:
		_audio_player.play()
		_set_audio_btn_playing(true)


func _set_audio_btn_playing(playing: bool) -> void:
	_audio_btn.text = "PAUSE" if playing else "PLAY"
	_audio_btn.icon = pause_icon if playing else play_icon


# -- motion --------------------------------------------------------------------

func _start_paw_drift() -> void:
	var tile := _paws.texture.get_size() * _paws.scale
	_paws.position = -tile
	var tw := create_tween().set_loops()
	tw.tween_property(_paws, "position", Vector2.ZERO, _PAW_DRIFT_SECONDS).from(-tile)


func _resize_browser(target: Vector2) -> void:
	_browser.scale = Vector2.ONE
	_browser.modulate.a = 1.0
	_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
		.tween_property(_browser, "size", target, 0.8)


## Layers are full-screen plain Controls, so moving one never fights a container.
func _rise_in(layer: Control, delay: float) -> void:
	layer.visible = true
	layer.position = Vector2(0, _RISE)
	layer.modulate.a = 0.0
	var tw := _tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(layer, "position:y", 0.0, 0.6).set_delay(delay)
	tw.parallel().tween_property(layer, "modulate:a", 1.0, 0.25).set_delay(delay)


func _slide_panel_in() -> void:
	_panel_layer.visible = true
	_panel_layer.position = Vector2(_PANEL_SLIDE, 0)
	_panel_layer.modulate.a = 0.0
	var tw := _tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel_layer, "position:x", 0.0, 0.75).set_delay(0.15)
	tw.parallel().tween_property(_panel_layer, "modulate:a", 1.0, 0.3).set_delay(0.15)


func _stamp_in(reliable: bool) -> void:
	_stamp.theme_type_variation = &"SCStampGood" if reliable else &"SCStampBad"
	_stamp_label.theme_type_variation = &"SCStampTextGood" if reliable else &"SCStampTextBad"
	_stamp_label.text = "RELIABLE" if reliable else "UNRELIABLE"
	_stamp.reset_size()
	_stamp.position = -_stamp.size / 2.0
	_stamp.pivot_offset = _stamp.size / 2.0

	_stamp.visible = true
	_stamp.scale = Vector2(2.6, 2.6)
	_stamp.modulate.a = 0.0
	var tw := _tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_stamp, "scale", Vector2.ONE, 0.55).set_delay(0.2)
	tw.parallel().tween_property(_stamp, "modulate:a", 1.0, 0.2).set_delay(0.2)


func _tween() -> Tween:
	var tw := create_tween()
	_tweens.append(tw)
	return tw


## Phase changes can land mid-animation (e.g. locking in while the flags still fade in),
## so the previous phase jumps to its end state instead of racing the next one.
func _finish_tweens() -> void:
	var running := _tweens
	_tweens = []
	for tw in running:
		if tw.is_valid() && tw.is_running():
			tw.custom_step(_FINISH_STEP)
		if tw.is_valid():
			tw.kill()
