class_name ScreenMode
## Window fullscreen helpers, shared by the F11 shortcut and [FullscreenButton]
## so every entry point toggles the same way.

const FULLSCREEN := Window.MODE_EXCLUSIVE_FULLSCREEN


static func is_on() -> bool:
	return _window().mode == FULLSCREEN


static func set_on(enabled: bool) -> void:
	_window().mode = FULLSCREEN if enabled else Window.MODE_WINDOWED


static func toggle() -> void:
	set_on(!is_on())


static func _window() -> Window:
	return (Engine.get_main_loop() as SceneTree).root
