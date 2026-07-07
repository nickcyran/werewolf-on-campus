class_name VideoPlayerControl
extends Control

## Aspect-ratio-correct, looping video player with click-to-pause.
##
## Guided learning:  call load_stream(stream) to begin.
## Capture app:      call set_stream(stream) then drive playback via
##                   auto_play() / auto_pause() from scroll logic.

var user_paused := false

@onready var _vp: VideoStreamPlayer = $VideoPlayer
@onready var _overlay: Control = $Overlay


func _ready() -> void:
	_vp.finished.connect(func(): _vp.play())
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
	if !is_node_ready():
		await ready
	_vp.stream = stream
	user_paused = false
	_overlay.visible = false
	_vp.play()


## Set stream without starting playback (for Capture; call auto_play() later).
func set_stream(stream: VideoStream) -> void:
	if !is_node_ready():
		await ready
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
