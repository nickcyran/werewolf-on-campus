extends Node3D

@onready var camera: Camera3D = $Camera3D

@export var mouse_sensitivity := 0.0025
@export_range(1.0, 89.0, 0.5) var max_look_radius_degrees := 85.0
@export var interact_max_distance := 5.0

var _hovered_interactable: Interactable
var _base_yaw := 0.0
var _base_pitch := 0.0
var _look_offset := Vector2.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_base_yaw = rotation.y
	_base_pitch = camera.rotation.x

func _physics_process(_delta: float) -> void:
	_update_hovered_interactable()

func _unhandled_input(event: InputEvent) -> void:
	# Toggle mouse mode
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SHIFT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
		return
	
	# Handle interaction click
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and _hovered_interactable:
			
			_hovered_interactable.interact()
		return

	# Handle mouse look
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or not event is InputEventMouseMotion:
		return

	_look_offset -= event.relative * mouse_sensitivity
	_look_offset = _look_offset.limit_length(deg_to_rad(max_look_radius_degrees))

	rotation.y = _base_yaw + _look_offset.x
	camera.rotation.x = _base_pitch + _look_offset.y

func _update_hovered_interactable() -> void:
	if not is_inside_tree(): return
	
	var space_state := get_world_3d().direct_space_state
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * interact_max_distance
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := space_state.intersect_ray(query)

	var new_hover: Interactable = null
	
	# Simplified node climbing: find Interactable on collider or parents
	if result:
		var node := result.collider as Node
		while node and not node is Interactable:
			node = node.get_parent()
		new_hover = node as Interactable

	# State check
	if _hovered_interactable == new_hover: 
		return

	# Apply hover states
	if _hovered_interactable: 
		_hovered_interactable.set_hovered(false)
		
	_hovered_interactable = new_hover
	
	if _hovered_interactable: 
		_hovered_interactable.set_hovered(true)
