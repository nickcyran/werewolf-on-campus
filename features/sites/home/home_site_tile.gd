class_name HomeSiteTile
extends Button

signal navigate_requested(target: PackedScene)

var _target: PackedScene


func _ready() -> void:
	text = ""
	custom_minimum_size = Vector2(200, 120)
	theme_type_variation = &"HomeTile"
	pressed.connect(_on_pressed)


func configure(icon_text: String, title_text: String, desc_text: String, target: PackedScene) -> void:
	_target = target
	%Icon.text = icon_text
	%Title.text = title_text
	if desc_text.is_empty():
		%Desc.visible = false
	else:
		%Desc.visible = true
		%Desc.text = desc_text


func _on_pressed() -> void:
	if _target:
		navigate_requested.emit(_target)
