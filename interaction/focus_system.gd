class_name FocusSystem
extends Node

@export var camera_path: NodePath
@export var tween_duration: float = 0.45

var camera: Camera3D
var tween: Tween

var target: Interactable
var focused_node: Node3D
var saved_transform: Transform3D

var is_animating := false


func _ready() -> void:
	camera = get_node(camera_path) as Camera3D
	GameManager.focus_entered.connect(_on_focus_requested)


func _input(event: InputEvent) -> void:
	if GameManager.state != GameManager.State.FOCUSED:
		return

	get_viewport().set_input_as_handled()

	if is_animating:
		return

	if event.is_action_pressed("exit_focus"):
		_unfocus()
	elif target and target.embedded_viewport:
		_forward_input(event)


func _on_focus_requested(node: Node3D) -> void:
	target = node as Interactable
	if !target:
		return

	focused_node = _resolve_focus_node()
	saved_transform = focused_node.global_transform

	var destination := _compute_destination()
	_tween_to(destination)


func _unfocus() -> void:
	_tween_to(saved_transform, GameManager.release_focus)


func _resolve_focus_node() -> Node3D:
	return camera as Node3D if target.focus_point else target as Node3D


func _compute_destination() -> Transform3D:
	if target.focus_point:
		# Move camera to focus point
		var t := target.focus_point.global_transform
		t.origin -= t.basis.z * target.focus_offset
		return t
	
	# Else, compute how the object should move
	return target.get_held_transform(camera)


func _tween_to(dest: Transform3D, on_complete: Callable = Callable()) -> void:
	# Kill active tweens to avoid a conflict
	if tween:
		tween.kill()

	is_animating = true

	tween = create_tween() \
		.set_trans(target.tween_transition) \
		.set_ease(target.tween_ease)

	tween.tween_property(focused_node, "global_transform", dest, tween_duration)

	# Cleanup
	tween.finished.connect(func():
		is_animating = false
		if on_complete.is_valid():
			on_complete.call()
	, CONNECT_ONE_SHOT)


func _forward_input(event: InputEvent) -> void:
	var vp := target.embedded_viewport

	# Any non-mouse events forwarded
	if !(event is InputEventMouse):
		vp.push_input(event)
		return

	# Screen-space mouse pos to viewport space
	var rect := _get_screen_rect()
	var vp_size := Vector2(vp.size)

	var scale := vp_size / rect.size
	var mouse_event := (event as InputEventMouse).duplicate()

	# Change pos into viewport coordinates
	mouse_event.position = ((event.position - rect.position) * scale).clamp(Vector2.ZERO, vp_size)
	mouse_event.global_position = mouse_event.position

	# Scale motion to match the viewport resolution
	if mouse_event is InputEventMouseMotion:
		mouse_event.relative *= scale
		mouse_event.velocity *= scale

	vp.push_input(mouse_event)


func _get_screen_rect() -> Rect2:
	# Get mesh displaying viewport
	var mesh := target.embedded_viewport.get_parent() as MeshInstance3D
	var quad := mesh.mesh as QuadMesh

	var size := quad.size
	var t := mesh.global_transform

	# Find corners of quad (world-space)
	var half_w := t.basis.x * size.x * 0.5
	var half_h := t.basis.y * size.y * 0.5

	# Project corners to screen-space
	var top_left := camera.unproject_position(t.origin - half_w + half_h)
	var bottom_right := camera.unproject_position(t.origin + half_w - half_h)

	return Rect2(top_left, bottom_right - top_left)
