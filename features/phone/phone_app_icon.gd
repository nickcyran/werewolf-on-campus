class_name PhoneAppIcon extends Control

signal app_opened(target: PackedScene)

var _target: PackedScene
var _style_normal := StyleBoxFlat.new()
var _style_hover := StyleBoxFlat.new()
var _style_pressed := StyleBoxFlat.new()

@onready var _icon_btn: Button = $VBox/IconButton
@onready var _label: Label = $VBox/AppLabel
@onready var _badge_panel: PanelContainer = %BadgePanel
@onready var _badge_label: Label = %BadgeLabel


func _ready() -> void:
	_icon_btn.pressed.connect(_on_pressed)
	for style in [_style_normal, _style_hover, _style_pressed]:
		style.set_corner_radius_all(28)
	_icon_btn.add_theme_stylebox_override("normal", _style_normal)
	_icon_btn.add_theme_stylebox_override("hover", _style_hover)
	_icon_btn.add_theme_stylebox_override("pressed", _style_pressed)


func configure(icon_text: String, label_text: String, color: Color, target: PackedScene) -> void:
	_target = target
	if !is_node_ready():
		await ready
	_icon_btn.text = icon_text
	_label.text = label_text
	_style_normal.bg_color = color
	_style_hover.bg_color = color.lightened(0.15)
	_style_pressed.bg_color = color.darkened(0.15)


func _on_pressed() -> void:
	if _target:
		app_opened.emit(_target)


func set_badge(count: int) -> void:
	if not is_node_ready():
		await ready
	if count <= 0:
		_badge_panel.visible = false
	else:
		_badge_panel.visible = true
		_badge_label.text = str(count) if count <= 9 else "9+"
