class_name Site extends Control

## Shown on the browser tab.
@export var site_name: String = ""
## Shown in the browser address bar.
@export var site_url: String = ""
## When set, this site counts as that guided-learning source the moment it is shown.
@export var source_id: String = ""


func _enter_tree() -> void:
	if source_id != "":
		GameManager.mark_source_visited(source_id)


func request_navigation(scene: PackedScene) -> void:
	var node: Node = self
	while node:
		if node is Browser:
			(node as Browser).load_site(scene)
			return
		if node is Phone:
			(node as Phone).open_app(scene)
			return
		node = node.get_parent()
