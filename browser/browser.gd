class_name Browser extends Control

@onready var _site_container: Control = $"Browser Content/Site"

var _current_page: Control = null
var _history: Array[PackedScene] = []
var _history_index: int = -1


func load_site(scene: PackedScene) -> void:
	if not scene:
		push_error("Browser: Provided scene is null.")
		return
	_history.resize(_history_index + 1)
	_history.append(scene)
	_history_index = _history.size() - 1
	_display_page(scene)


func go_back() -> void:
	if can_go_back():
		_history_index -= 1
		_display_page(_history[_history_index])


func go_forward() -> void:
	if can_go_forward():
		_history_index += 1
		_display_page(_history[_history_index])


func can_go_back() -> bool:
	return _history_index > 0


func can_go_forward() -> bool:
	return _history_index < _history.size() - 1


func _display_page(scene: PackedScene) -> void:
	if _current_page:
		_site_container.remove_child(_current_page)
		_current_page.queue_free()
	_current_page = scene.instantiate() as Control
	if _current_page:
		_site_container.add_child(_current_page)
