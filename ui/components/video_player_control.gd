class_name VideoPlayerControl
extends Control

## Aspect-ratio-correct, looping video player with click-to-pause.
##
## Guided learning:  call load_stream(stream) to begin.
## Capture app:      call set_stream(stream) then drive playback via
##                   auto_play() / auto_pause() from scroll logic.

var user_paused := false

var _vp: VideoStreamPlayer
var _overlay: Control


func _ready() -> void:
	clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_vp = VideoStreamPlayer.new()
	_vp.expand = true
	_vp.autoplay = false
	# Centred horizontally so we can widen/narrow to preserve aspect ratio.
	_vp.anchor_left = 0.5
	_vp.anchor_right = 0.5
	_vp.anchor_top = 0.0
	_vp.anchor_bottom = 1.0
	_vp.offset_left = -200.0
	_vp.offset_right = 200.0
	_vp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp.finished.connect(func(): _vp.play())  # always loop
	add_child(_vp)

	_overlay = CenterContainer.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	var icon := Label.new()
	icon.text = "▶"
	icon.add_theme_font_size_override("font_size", 80)
	icon.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.88))
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(icon)
	add_child(_overlay)

	gui_input.connect(_on_gui_input)


func _process(_delta: float) -> void:
	if not _vp.is_playing() or _vp.paused:
		return
	var tex := _vp.get_video_texture()
	if tex == null or tex.get_size().x <= 0:
		return
	var sz := tex.get_size()
	var w := size.y * sz.x / sz.y
	_vp.offset_left = -w * 0.5
	_vp.offset_right = w * 0.5


# ── Public API ────────────────────────────────────────────────────────────────

## Set stream and immediately start playing (for guided learning).
func load_stream(stream: VideoStream) -> void:
	_vp.stream = stream
	user_paused = false
	_overlay.visible = false
	_vp.play()


## Set stream without starting playback (for Capture; call auto_play() later).
func set_stream(stream: VideoStream) -> void:
	_vp.stream = stream
	user_paused = false
	_overlay.visible = false


## Resume playback if the user hasn't explicitly paused (Capture scroll logic).
func auto_play() -> void:
	if user_paused:
		return
	if not _vp.is_playing():
		_vp.play()
	_vp.paused = false
	_overlay.visible = false


## Pause without marking as user-paused (Capture scroll logic).
func auto_pause() -> void:
	_vp.paused = true


func stop() -> void:
	if _vp.is_playing():
		_vp.stop()
	_overlay.visible = false
	user_paused = false


func is_playing() -> bool:
	return _vp.is_playing() and not _vp.paused


# ── Internal ──────────────────────────────────────────────────────────────────

func _on_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
			and event.pressed):
		return
	user_paused = not user_paused
	_vp.paused = user_paused
	_overlay.visible = user_paused
