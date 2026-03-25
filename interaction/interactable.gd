class_name Interactable extends StaticBody3D

enum FocusMode { NONE, CAMERA_TO_OBJECT, PICKUP }

const OUTLINE_MATERIAL := preload("res://assets/materials/outline.tres")

@export var focus_mode: FocusMode = FocusMode.NONE
@export var tween_transition: Tween.TransitionType = Tween.TRANS_SINE
@export var tween_ease: Tween.EaseType = Tween.EASE_IN_OUT

@export_group("Outline")
@export_range(0.001, 0.05, 0.001) var outline_grow: float = 0.005

@export_group("Camera Focus")
@export var viewport_path: NodePath
@export_range(-1.0, 1.0, 0.01) var focus_offset: float = 0.0

@export_group("Pickup")
@export var hold_distance: float = 0.35
@export var hold_offset := Vector3(0.0, -0.03, 0.0)

var focus_point: Marker3D
var embedded_viewport: SubViewport

var _mesh: MeshInstance3D
var _outline: ShaderMaterial
var _is_hovered: bool


func _ready() -> void:
	_discover_children()
	_init_outline()

	# Fetch subviewport safely
	if !viewport_path.is_empty():
		embedded_viewport = get_node_or_null(viewport_path) as SubViewport


func set_hovered(hovered: bool) -> void:
	if _is_hovered == hovered:
		return

	_is_hovered = hovered
	if _mesh:
		# Outline the hovered interactable mesh
		_mesh.material_overlay = _outline if hovered else null


func interact() -> void:
	if focus_mode == FocusMode.NONE:
		return
	GameManager.request_focus(self)


func get_held_transform(cam: Camera3D) -> Transform3D:
	var cam_basis := cam.global_transform.basis
	var pos := cam.global_position - cam_basis.z * hold_distance + cam_basis * hold_offset
	return Transform3D(Basis(cam_basis.x, cam_basis.z, -cam_basis.y), pos)


func _discover_children() -> void:
	for child in get_children():
		# Assume first mesh3d child is the visual component of model
		if !_mesh and child is MeshInstance3D:
			_mesh = child

		# Marker used as focus target
		if !focus_point and child is Marker3D:
			focus_point = child


func _init_outline() -> void:
	if !_mesh:
		return

	_outline = OUTLINE_MATERIAL.duplicate() as ShaderMaterial
	_outline.set_shader_parameter("grow_amount", outline_grow)
