# handles first-person camera look within a constrained radius.
class_name PlayerCamera extends Node

@export_group("Camera")
@export var fov: float = 70.0
@export var mouse_sensitivity: float = 0.0025
@export_range(1.0, 89.0, 0.5) var max_look_radius: float = 76.0


var camera: Camera3D
var yaw_node: Node3D

var _base_yaw: float
var _base_pitch: float
var _look_offset: Vector2 = Vector2.ZERO


func initialize(cam: Camera3D, yaw: Node3D) -> void:
	camera = cam
	yaw_node = yaw
	camera.fov = fov
	_base_yaw = yaw_node.rotation.y
	_base_pitch = camera.rotation.x


# apply a relative mouse-motion delta to the look offset.
func apply_mouse_look(relative: Vector2) -> void:
	_look_offset -= relative * mouse_sensitivity
	_look_offset = _look_offset.limit_length(deg_to_rad(max_look_radius))
	yaw_node.rotation.y = _base_yaw + _look_offset.x
	camera.rotation.x = _base_pitch + _look_offset.y
