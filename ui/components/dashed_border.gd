@tool
extends ColorRect

## Overlay that draws a dashed outline on top of whatever it covers.
## The shader needs the rect size in pixels, which only the node knows.

@export var line_color: Color = Color(0.102, 0.071, 0.024, 1.0):
	set = _set_line_color
@export_range(1.0, 12.0, 0.5) var thickness: float = 3.0:
	set = _set_thickness
@export_range(2.0, 40.0, 0.5) var dash: float = 9.0:
	set = _set_dash
@export_range(1.0, 40.0, 0.5) var gap: float = 7.0:
	set = _set_gap


func _ready() -> void:
	resized.connect(_push_size)
	_push_all()


func _set_line_color(value: Color) -> void:
	line_color = value
	_set_param("line_color", value)


func _set_thickness(value: float) -> void:
	thickness = value
	_set_param("thickness", value)


func _set_dash(value: float) -> void:
	dash = value
	_set_param("dash", value)


func _set_gap(value: float) -> void:
	gap = value
	_set_param("gap", value)


func _push_all() -> void:
	_set_param("line_color", line_color)
	_set_param("thickness", thickness)
	_set_param("dash", dash)
	_set_param("gap", gap)
	_push_size()


func _push_size() -> void:
	_set_param("rect_size", size)


func _set_param(name: String, value: Variant) -> void:
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter(name, value)
