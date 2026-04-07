extends Node3D

@export_group("Camera")
@export var fov: float = 70.0
@export var mouse_sensitivity: float = 0.0025
@export_range(1.0, 89.0, 0.5) var max_look_radius: float = 76.0

@export_group("Interaction")
@export var interact_distance: float = 5.0

@onready var camera: Camera3D = $Camera3D
@onready var _time_label: Label = %TimeLabel
@onready var _info_btn: Button = %InfoButton
@onready var _info_overlay: Control = %InfoOverlay

var _hovered_interactable: Interactable
var _base_yaw: float
var _base_pitch: float
var _look_offset: Vector2 = Vector2.ZERO
var _state_before_info: GameManager.State


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.fov = fov
	_base_yaw = rotation.y
	_base_pitch = camera.rotation.x
	_time_label.text = DayClock.get_display_time()
	GameManager.state_changed.connect(_on_game_state_changed)
	DayClock.time_changed.connect(func(t: String): _time_label.text = t)
	_info_btn.pressed.connect(_toggle_info)
	_info_overlay.visible = false


func _physics_process(_delta: float) -> void:
	if GameManager.is_playing():
		_update_hover()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_info"):
		_toggle_info()
		return

	if !GameManager.is_playing():
		return

	if event.is_action_pressed("toggle_mouse"):
		_toggle_mouse_capture()
		return

	if event.is_action_pressed("interact") and _hovered_interactable:
		_hovered_interactable.interact()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_mouse_look(event.relative)


# -- Look ---------------------------------------------------------------------
func _apply_mouse_look(relative: Vector2) -> void:
	_look_offset -= relative * mouse_sensitivity
	_look_offset = _look_offset.limit_length(deg_to_rad(max_look_radius))
	rotation.y = _base_yaw + _look_offset.x
	camera.rotation.x = _base_pitch + _look_offset.y


# -- Hover / interaction ------------------------------------------------------
func _update_hover() -> void:
	var new_target := _raycast_for_interactable()
	if new_target == _hovered_interactable:
		return

	if _hovered_interactable:
		_hovered_interactable.set_hovered(false)

	_hovered_interactable = new_target
	if _hovered_interactable:
		_hovered_interactable.set_hovered(true)


func _raycast_for_interactable() -> Interactable:
	if !is_inside_tree():
		return null

	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * interact_distance

	var hit := get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(from, to)
	)

	if !hit:
		return null

	return hit.collider as Interactable


func _clear_hover() -> void:
	if _hovered_interactable:
		_hovered_interactable.set_hovered(false)
		_hovered_interactable = null


# -- Signal handlers ----------------------------------------------------------
func _on_game_state_changed(new_state: GameManager.State) -> void:
	var playing := new_state == GameManager.State.PLAYING
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if playing else Input.MOUSE_MODE_VISIBLE

	if !playing:
		_clear_hover()


# -- Info panel ---------------------------------------------------------------
func _toggle_info() -> void:
	_info_overlay.visible = !_info_overlay.visible
	if _info_overlay.visible:
		_state_before_info = GameManager.state
		GameManager.state = GameManager.State.PAUSED
	else:
		GameManager.state = _state_before_info


# -- Helpers ------------------------------------------------------------------
func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
