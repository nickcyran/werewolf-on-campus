extends Control

const PhoneAppIconScene := preload("res://features/phone/phone_app_icon.tscn")
const TextingAppScene := preload("res://features/phone/apps/texting/texting.tscn")

@export var apps: Array[PhoneAppDefinition] = []

@onready var _grid: GridContainer = %Grid
@onready var _time_label: Label = %TimeLabel


func _ready() -> void:
	_time_label.text = DayClock.get_display_time()
	DayClock.time_changed.connect(_on_time_changed)

	for app in apps:
		var icon_node: PhoneAppIcon = PhoneAppIconScene.instantiate() as PhoneAppIcon
		icon_node.app_opened.connect(_on_app_opened)
		icon_node.configure(app)
		_grid.add_child(icon_node)

		if app.scene == TextingAppScene:
			icon_node.set_badge(Texting.get_total_unread())
			Texting.unread_changed.connect(icon_node.set_badge)


func _on_time_changed(display_time: String) -> void:
	_time_label.text = display_time


func _on_app_opened(scene: PackedScene) -> void:
	var node: Node = self
	while node:
		if node is Phone:
			(node as Phone).open_app(scene)
			return
		node = node.get_parent()
