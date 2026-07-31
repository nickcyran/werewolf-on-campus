@tool
extends Control

## Decorative rotation for a Control, applied around its centre.
## Containers clear rotation whenever they sort, so it is re-applied after
## every layout pass. Optionally wobbles back and forth at runtime.

@export_range(-90.0, 90.0, 0.1) var tilt_degrees: float = 0.0:
	set = _set_tilt_degrees
@export_range(0.0, 10.0, 0.1) var wobble_degrees: float = 0.0
@export_range(0.5, 20.0, 0.1) var wobble_seconds: float = 5.0


func _ready() -> void:
	resized.connect(_apply)

	var parent := get_parent()
	if parent is Container:
		(parent as Container).sort_children.connect(_apply_deferred)
	_apply()

	if Engine.is_editor_hint() || wobble_degrees <= 0.0:
		return

	var tw := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "rotation_degrees", tilt_degrees + wobble_degrees, wobble_seconds * 0.5)
	tw.tween_property(self, "rotation_degrees", tilt_degrees - wobble_degrees, wobble_seconds * 0.5)


func _set_tilt_degrees(value: float) -> void:
	tilt_degrees = value
	rotation_degrees = value


func _apply_deferred() -> void:
	_apply.call_deferred()


func _apply() -> void:
	pivot_offset = size * 0.5
	# while wobbling the tween owns rotation, so leave it alone
	if wobble_degrees <= 0.0:
		rotation_degrees = tilt_degrees
