class_name Interactable extends Node

var outline_mesh: MeshInstance3D
var _is_hovered: bool = false

func initialize_outline(mesh: MeshInstance3D) -> void:
	outline_mesh = mesh
	if outline_mesh:
		outline_mesh.hide()

func apply_outline() -> void:
	if outline_mesh:
		outline_mesh.show()

func remove_outline() -> void:
	if outline_mesh:
		outline_mesh.hide()

func set_hovered(hovered: bool) -> void:
	_is_hovered = hovered
	
	if _is_hovered:
		apply_outline()
	else:
		remove_outline()

func interact() -> void:
	print("Interacted with ", name)
