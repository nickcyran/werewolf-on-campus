class_name ChecklistRow extends PanelContainer

const ROW_BG_A := Color(0.2, 0.21, 0.27, 1.0)
const ROW_BG_B := Color(0.26, 0.27, 0.34, 1.0)

var confirmed: bool = false

@onready var checkbox: CheckBox = %Checkbox
@onready var result_hint: Label = %ResultHint


func configure(index: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = ROW_BG_A if index % 2 == 0 else ROW_BG_B
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.42, 0.5, 0.65)
	add_theme_stylebox_override("panel", style)

	var bg_normal := style.bg_color
	var bg_hover := bg_normal + Color(0.07, 0.07, 0.09, 0.0)
	var border_normal := style.border_color
	var border_hover := Color(0.52, 0.55, 0.66, 0.9)

	mouse_entered.connect(func():
		if confirmed:
			return
		var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.set_parallel(true)
		tw.tween_property(style, "bg_color", bg_hover, 0.1)
		tw.tween_property(style, "border_color", border_hover, 0.1)
	)
	mouse_exited.connect(func():
		if confirmed:
			return
		var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.set_parallel(true)
		tw.tween_property(style, "bg_color", bg_normal, 0.15)
		tw.tween_property(style, "border_color", border_normal, 0.15)
	)
