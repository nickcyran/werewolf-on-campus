extends Control

const PhoneAppIconScene := preload("res://features/phone/phone_app_icon.tscn")

@export var apps: Array[PhoneAppDefinition] = []

@onready var _grid: GridContainer = $ScrollContainer/CenterMargin/VBox/Grid


func _ready() -> void:
	for app in apps:
		var icon_node: PhoneAppIcon = PhoneAppIconScene.instantiate() as PhoneAppIcon
		icon_node.app_opened.connect(_on_app_opened)
		icon_node.configure(app.icon, app.label, app.color, app.scene)
		_grid.add_child(icon_node)


func _on_app_opened(scene: PackedScene) -> void:
	var node: Node = self
	while node:
		if node is Phone:
			(node as Phone).open_app(scene)
			return
		node = node.get_parent()
