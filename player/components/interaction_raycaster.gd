# casts a ray from the camera each physics frame, tracking currently hovered Interactable.
class_name InteractionRaycaster extends Node

signal hovered_changed(new_target: Interactable)

@export var interact_distance: float = 5.0
var camera: Camera3D
var _hovered: Interactable

# pre-allocated query object
var _query: PhysicsRayQueryParameters3D


func initialize(cam: Camera3D) -> void:
	camera = cam
	_query = PhysicsRayQueryParameters3D.new()


# runs every physics frame while the game is in the PLAYING state.
func update() -> void:
	var new_target := _raycast()
	if new_target == _hovered:
		return

	if _hovered:
		_hovered.set_hovered(false)

	_hovered = new_target

	if _hovered:
		_hovered.set_hovered(true)

	hovered_changed.emit(_hovered)


func get_hovered() -> Interactable:
	return _hovered


# force clear hover state 
func clear() -> void:
	if _hovered:
		_hovered.set_hovered(false)
		_hovered = null
		hovered_changed.emit(null)


# -- Private -------------------------------------------------------------------

func _raycast() -> Interactable:
	if !camera or !is_inside_tree():
		return null

	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * interact_distance

	# reuse the query instead of creating a new one each frame
	_query.from = from
	_query.to = to

	var world := camera.get_world_3d()
	var space := world.direct_space_state
	if !space:
		return null

	var hit := space.intersect_ray(_query)

	if hit.is_empty():
		return null

	return hit.collider as Interactable
