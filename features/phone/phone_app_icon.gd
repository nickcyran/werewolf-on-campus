class_name PhoneAppIcon extends Control
## Home-screen app tile: rounded gradient square, glyph, label, and unread badge.

signal app_opened(target: PackedScene)

var _target: PackedScene
var _style_normal := StyleBoxFlat.new()
var _style_hover := StyleBoxFlat.new()
var _style_pressed := StyleBoxFlat.new()

@onready var _icon_btn: Button = %IconButton
@onready var _glyph: Label = %Glyph
@onready var _tile_gradient: TextureRect = %TileGradient
@onready var _label: Label = %AppLabel
@onready var _badge_panel: PanelContainer = %BadgePanel
@onready var _badge_label: Label = %BadgeLabel


func _ready() -> void:
	_icon_btn.pressed.connect(_on_pressed)
	for style in [_style_normal, _style_hover, _style_pressed]:
		style.set_corner_radius_all(35)
	_icon_btn.add_theme_stylebox_override("normal", _style_normal)
	_icon_btn.add_theme_stylebox_override("hover", _style_hover)
	_icon_btn.add_theme_stylebox_override("pressed", _style_pressed)
	_icon_btn.add_theme_stylebox_override("focus", _style_normal)


func configure(definition: PhoneAppDefinition) -> void:
	_target = definition.scene
	if !is_node_ready():
		await ready

	_glyph.text = definition.icon
	_label.text = definition.label
	_style_normal.bg_color = definition.color
	_style_hover.bg_color = definition.color.lightened(0.15)
	_style_pressed.bg_color = definition.color.darkened(0.15)
	_tile_gradient.texture = definition.tile_gradient
	_tile_gradient.visible = definition.tile_gradient != null


func _on_pressed() -> void:
	if _target:
		app_opened.emit(_target)


func set_badge(count: int) -> void:
	if !is_node_ready():
		await ready

	_badge_panel.visible = count > 0
	_badge_label.text = str(count) if count <= 9 else "9+"
