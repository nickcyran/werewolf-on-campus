class_name FullscreenButton
extends Button
## Toggles fullscreen on click or on the "toggle_fullscreen" action (F11),
## and keeps its label in sync when the mode changes from anywhere else.

@export var windowed_text: String = "Fullscreen"
@export var fullscreen_text: String = "Exit Fullscreen"


func _ready() -> void:
	pressed.connect(_toggle)
	get_window().size_changed.connect(_sync_text)
	_sync_text()


func _shortcut_input(event: InputEvent) -> void:
	if !event.is_action_pressed("toggle_fullscreen"):
		return

	_toggle()
	get_viewport().set_input_as_handled()


func _toggle() -> void:
	ScreenMode.toggle()
	_sync_text()


func _sync_text() -> void:
	text = fullscreen_text if ScreenMode.is_on() else windowed_text
