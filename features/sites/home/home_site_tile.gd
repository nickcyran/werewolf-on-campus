class_name HomeSiteTile
extends Button

signal navigate_requested(target: PackedScene)

const TILE_RADIUS := 22

var _target: PackedScene

@onready var _tile_panel: PanelContainer = %TilePanel
@onready var _initials: Label = %Initials
@onready var _title: Label = %Title


func _ready() -> void:
	text = ""
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(118, 124)
	pressed.connect(_on_pressed)
	mouse_entered.connect(func(): _set_lift(true))
	mouse_exited.connect(func(): _set_lift(false))


func configure(def: SiteDefinition) -> void:
	if !is_node_ready():
		await ready
	_target = def.scene
	_initials.text = def.icon
	_title.text = def.label

	var style := StyleBoxFlat.new()
	style.bg_color = def.tile_color
	style.set_corner_radius_all(TILE_RADIUS)
	style.shadow_color = Color(def.tile_color, 0.33)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	_tile_panel.add_theme_stylebox_override("panel", style)


func _set_lift(hovered: bool) -> void:
	_tile_panel.pivot_offset = _tile_panel.size / 2.0
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_tile_panel, "scale", Vector2(1.06, 1.06) if hovered else Vector2.ONE, 0.15)


func _on_pressed() -> void:
	if _target:
		navigate_requested.emit(_target)
