extends RefCounted

const MAX_BACK_HISTORY := 3

var history: Array[PackedScene] = []
var history_index: int = -1
var current_page: Control = null

var button: Button
var close_btn: Button
var container: HBoxContainer


func navigate_to(scene: PackedScene) -> void:
	history.resize(history_index + 1)
	history.append(scene)
	history_index = history.size() - 1

	while history.size() > MAX_BACK_HISTORY + 1:
		history.remove_at(0)
		history_index -= 1


func go_back() -> bool:
	if !can_go_back():
		return false

	history_index -= 1
	return true


func go_forward() -> bool:
	if !can_go_forward():
		return false

	history_index += 1
	return true


func can_go_back() -> bool:
	return history_index > 0


func can_go_forward() -> bool:
	return history_index < history.size() - 1


func get_current_scene() -> PackedScene:
	if history_index >= 0 && history_index < history.size():
		return history[history_index]
		
	return null


func get_title() -> String:
	if current_page && current_page is Site:
		var t := (current_page as Site).get_site_title()
		if t != "":
			return t
	return "New Tab"


func replace_page(scene: PackedScene) -> Control:
	if current_page:
		if current_page.get_parent():
			current_page.get_parent().remove_child(current_page)
			
		current_page.queue_free()

	current_page = scene.instantiate() as Control
	return current_page


func detach_page() -> void:
	if current_page && current_page.get_parent():
		current_page.get_parent().remove_child(current_page)


func destroy() -> void:
	if current_page:
		if current_page.get_parent():
			current_page.get_parent().remove_child(current_page)

		current_page.queue_free()
		current_page = null

	if container:
		container.queue_free()
		container = null
		button = null
		close_btn = null
