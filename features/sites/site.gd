class_name Site extends Control

@export var site_title: String = ""

func get_site_title() -> String:
	return site_title


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
