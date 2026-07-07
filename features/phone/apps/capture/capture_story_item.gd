class_name CaptureStoryItem extends VBoxContainer

@onready var _ring: PanelContainer = $Ring
@onready var _avatar: PanelContainer = $Ring/Avatar
@onready var _plus: Label = $Ring/PlusLabel
@onready var _name_lbl: Label = $NameLabel


func configure(username: String, ring_color: Color, avatar_color: Color, show_plus: bool) -> void:
	if !is_node_ready():
		await ready
	_ring.add_theme_stylebox_override("panel", _flat_ring(ring_color, 48.0, 3.0))
	_avatar.add_theme_stylebox_override("panel", _flat(avatar_color, 43.0))
	_plus.visible = show_plus
	_name_lbl.text = username


static func _flat(bg: Color, radius: float = 0.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	if radius > 0.0:
		s.set_corner_radius_all(roundi(radius))
	return s


static func _flat_ring(border_color: Color, radius: float, margin: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.border_color = border_color
	s.set_border_width_all(2)
	s.set_corner_radius_all(roundi(radius))
	s.content_margin_left = margin
	s.content_margin_top = margin
	s.content_margin_right = margin
	s.content_margin_bottom = margin
	return s
