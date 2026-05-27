class_name PhoneAppIcon extends Control

signal app_opened(target: PackedScene)

var _target: PackedScene

@onready var _icon_btn: Button = $VBox/IconButton
@onready var _label: Label = $VBox/AppLabel


func _ready() -> void:
	_icon_btn.pressed.connect(_on_pressed)


func configure(icon_text: String, label_text: String, color: Color, target: PackedScene) -> void:
	_target = target
	if !is_node_ready():
		await ready
	_icon_btn.text = icon_text
	_label.text = label_text
	_apply_icon_style(color)


func _on_pressed() -> void:
	if _target:
		app_opened.emit(_target)


func _apply_icon_style(color: Color) -> void:
	_icon_btn.add_theme_color_override("font_color", Color.WHITE)
	_icon_btn.add_theme_stylebox_override("normal", _make_rounded_style(color))
	_icon_btn.add_theme_stylebox_override("hover", _make_rounded_style(color.lightened(0.15)))
	_icon_btn.add_theme_stylebox_override("pressed", _make_rounded_style(color.darkened(0.15)))


static func _make_rounded_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(22)
	return style
