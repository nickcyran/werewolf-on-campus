class_name SniffTestScreen extends Control
## 04 — Sniff test. Shows one source at a time and lets the player tag the tells they
## spot in it. The tag list is the full checklist, so every tell an authored source
## carries can actually be found.

signal back_requested
signal submitted
## The sequence owns the tag state; this only reports the flip.
signal tag_toggled(indicator_index: int, tagged: bool)

const _TagRowScene := preload("res://features/game_end/components/tag_row.tscn")

@export var play_icon: Texture2D
@export var pause_icon: Texture2D

var _rows: Dictionary = {}  # indicator index -> TagRow
var _scene_instance: Node = null

@onready var _back_btn: Button = %BackBtn
@onready var _source_label: Label = %SourceLabel
@onready var _tagged_count: Label = %TaggedCount
@onready var _scene_container: SubViewportContainer = %SceneContainer
@onready var _scene_viewport: SubViewport = %SceneViewport
## Infographics are tall, so the image scrolls at full width rather than shrinking to fit.
@onready var _image_scroll: ScrollContainer = %ImageScroll
@onready var _image_view: TextureRect = %ImageView
@onready var _video_view: VideoPlayerControl = %VideoView
@onready var _audio_view: VBoxContainer = %AudioView
@onready var _audio_title: Label = %AudioTitle
@onready var _audio_btn: Button = %AudioBtn
@onready var _audio_player: AudioStreamPlayer = %AudioPlayer
@onready var _collapsed_bar: PanelContainer = %CollapsedBar
@onready var _collapsed_count: Label = %CollapsedCount
@onready var _drawer: PanelContainer = %Drawer
@onready var _neg_list: VBoxContainer = %NegList
@onready var _pos_list: VBoxContainer = %PosList
@onready var _neg_count: Label = %NegCount
@onready var _pos_count: Label = %PosCount


func _ready() -> void:
	_back_btn.pressed.connect(func(): back_requested.emit())
	%OpenDrawerBtn.pressed.connect(_toggle_drawer)
	%HideDrawerBtn.pressed.connect(_toggle_drawer)
	%CollapsedSubmitBtn.pressed.connect(func(): submitted.emit())
	%DrawerSubmitBtn.pressed.connect(func(): submitted.emit())
	_audio_btn.pressed.connect(_toggle_audio)
	_audio_player.finished.connect(_on_audio_finished)
	_image_scroll.resized.connect(_refresh_image_size)
	_build_tag_rows()


## [param tagged] holds the indicator indices already marked on this source.
func show_source(index: int, total: int, source: GuidedLearningSource, tagged: Dictionary) -> void:
	_source_label.text = "SOURCE %d/%d" % [index + 1, total]

	for indicator_index: int in _rows:
		(_rows[indicator_index] as TagRow).set_tagged(tagged.get(indicator_index, false))
	refresh_counts(tagged)

	_show_content(source)


## Frees the embedded source and silences any media before the sequence moves on.
func clear_source() -> void:
	_video_view.stop()
	_audio_player.stop()
	_set_audio_btn_playing(false)
	if _scene_instance:
		_scene_instance.queue_free()
		_scene_instance = null


func _build_tag_rows() -> void:
	var indicators := ReliabilityIndicatorData.get_indicators()
	for i in range(indicators.size()):
		var row: TagRow = _TagRowScene.instantiate()
		var list := _pos_list if indicators[i].is_positive else _neg_list
		list.add_child(row)
		row.configure(i, indicators[i], false)
		row.toggled.connect(_on_tag_toggled)
		_rows[i] = row


func _show_content(source: GuidedLearningSource) -> void:
	clear_source()

	_scene_container.visible = source.type == GuidedLearningSource.Type.SCENE
	_image_scroll.visible = source.type == GuidedLearningSource.Type.IMAGE
	_video_view.visible = source.type == GuidedLearningSource.Type.VIDEO
	_audio_view.visible = source.type == GuidedLearningSource.Type.AUDIO

	match source.type:
		GuidedLearningSource.Type.SCENE:
			if source.scene:
				_scene_instance = source.scene.instantiate()
				_scene_viewport.add_child(_scene_instance)
		GuidedLearningSource.Type.IMAGE:
			_image_view.texture = source.image
			_refresh_image_size()
		GuidedLearningSource.Type.VIDEO:
			if source.video:
				_video_view.load_stream(source.video)
		GuidedLearningSource.Type.AUDIO:
			_audio_title.text = source.display_name
			_audio_player.stream = source.audio


## A proportionally-expanding TextureRect reports no minimum size, so inside a scroll
## container it collapses to nothing. Give it a height to scroll through instead.
##
## Height only, and never a width: a minimum width taken from the container's own width
## feeds straight back into the next layout pass and the panel grows without bound. The
## early-out keeps a settled layout from re-triggering itself the same way.
func _refresh_image_size() -> void:
	var texture := _image_view.texture
	if !texture || texture.get_width() <= 0 || _image_scroll.size.x <= 0.0:
		return

	var target := roundf(texture.get_height() * _image_scroll.size.x / texture.get_width())
	if is_equal_approx(_image_view.custom_minimum_size.y, target):
		return

	_image_view.custom_minimum_size = Vector2(0, target)


func _on_tag_toggled(indicator_index: int, tagged: bool) -> void:
	tag_toggled.emit(indicator_index, tagged)


func refresh_counts(tagged: Dictionary) -> void:
	var indicators := ReliabilityIndicatorData.get_indicators()
	var negatives := 0
	var positives := 0

	for indicator_index: int in tagged:
		if !tagged[indicator_index]:
			continue
		if indicators[indicator_index].is_positive:
			positives += 1
		else:
			negatives += 1

	var total := negatives + positives
	_tagged_count.text = str(total)
	_collapsed_count.text = "%d tells tagged on this source" % total
	_neg_count.text = "%d marked" % negatives
	_pos_count.text = "%d marked" % positives


func _toggle_drawer() -> void:
	_drawer.visible = !_drawer.visible
	_collapsed_bar.visible = !_drawer.visible


func _toggle_audio() -> void:
	if _audio_player.playing:
		_audio_player.stop()
		_set_audio_btn_playing(false)
	else:
		_audio_player.play()
		_set_audio_btn_playing(true)


func _on_audio_finished() -> void:
	_set_audio_btn_playing(false)


func _set_audio_btn_playing(playing: bool) -> void:
	_audio_btn.text = "PAUSE" if playing else "PLAY"
	_audio_btn.icon = pause_icon if playing else play_icon
