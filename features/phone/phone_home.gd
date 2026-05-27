extends Control

const PhoneAppIconScene := preload("res://features/phone/phone_app_icon.tscn")

@export var app_scenes: Array[PackedScene] = []
@export var app_labels: PackedStringArray = []
@export var app_icons: PackedStringArray = []
@export var app_colors: PackedColorArray = []

@onready var _grid: GridContainer = $ScrollContainer/CenterMargin/VBox/Grid


func _ready() -> void:
	for i in range(app_scenes.size()):
		var label_text: String = app_labels[i] if i < app_labels.size() else "App"
		var icon_text: String = app_icons[i] if i < app_icons.size() else "?"
		var color: Color = app_colors[i] if i < app_colors.size() else Color(0.3, 0.3, 0.35)

		var icon_node: PhoneAppIcon = PhoneAppIconScene.instantiate() as PhoneAppIcon
		icon_node.app_opened.connect(_on_app_opened)
		icon_node.configure(icon_text, label_text, color, app_scenes[i])
		_grid.add_child(icon_node)


func _on_app_opened(scene: PackedScene) -> void:
	var node: Node = self
	while node:
		if node is Phone:
			(node as Phone).open_app(scene)
			return
		node = node.get_parent()
