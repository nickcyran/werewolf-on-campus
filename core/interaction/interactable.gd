class_name Interactable extends StaticBody3D

enum FocusMode {NONE, CAMERA_TO_OBJECT, PICKUP}

const OUTLINE_MATERIAL := preload("res://vfx/outline/outline.tres")

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

@export_group("Embedded Screen")
## Screen refreshes per second while the player is not focused on this object. The
## screens are several times larger than the main viewport, so redrawing them every
## frame when nobody is reading them is the single biggest cost in the room. Set to 0
## to freeze the screen entirely until it is focused.
@export_range(0.0, 60.0, 0.5) var idle_refresh_hz: float = 6.0
## Web GPUs cannot absorb the supersampled screens, so the render target is scaled on
## that platform only. 0.5 drops both screens to their authored 2D size (no
## supersampling); 1.0 keeps the full authored resolution.
@export_range(0.25, 1.0, 0.05) var web_resolution_scale: float = 0.5

var focus_point: Marker3D
var embedded_viewport: SubViewport

var _mesh: GeometryInstance3D
var _outline: ShaderMaterial
var _is_hovered: bool
var _screen_focused := false
var _idle_elapsed: float = 0.0


func _ready() -> void:
	_discover_children()

	# Fetch subviewport safely
	if !viewport_path.is_empty():
		embedded_viewport = get_node_or_null(viewport_path) as SubViewport

	set_process(embedded_viewport != null)
	if embedded_viewport:
		if OS.has_feature("web") && web_resolution_scale < 1.0:
			embedded_viewport.size = Vector2i(Vector2(embedded_viewport.size) * web_resolution_scale)
		# One render so the screen has content, then the idle throttle drives it.
		embedded_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## Unfocused screens redraw at [member idle_refresh_hz] instead of every frame.
## UPDATE_ONCE renders a single frame and reverts to disabled on its own, so the last
## drawn image stays on the quad in between.
func _process(delta: float) -> void:
	if _screen_focused || idle_refresh_hz <= 0.0:
		return

	_idle_elapsed += delta
	if _idle_elapsed < 1.0 / idle_refresh_hz:
		return

	_idle_elapsed = 0.0
	embedded_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## Driven by [FocusSystem]: a screen being read has to run at the full frame rate.
func set_screen_focused(focused: bool) -> void:
	if !embedded_viewport:
		return

	_screen_focused = focused
	_idle_elapsed = 0.0
	embedded_viewport.render_target_update_mode = \
		SubViewport.UPDATE_ALWAYS if focused else SubViewport.UPDATE_ONCE


func set_hovered(hovered: bool) -> void:
	if _is_hovered == hovered:
		return

	_is_hovered = hovered
	if _mesh:
		if hovered && !_outline:
			_init_outline()
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
		# Assume first geometry child is the visual component of model
		if !_mesh and child is GeometryInstance3D:
			_mesh = child

		# Marker used as focus target
		if !focus_point and child is Marker3D:
			focus_point = child


func _init_outline() -> void:
	if !_mesh:
		return

	_outline = OUTLINE_MATERIAL.duplicate() as ShaderMaterial
	_outline.set_shader_parameter("grow_amount", outline_grow)
