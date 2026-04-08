extends Site

@export var site_scenes: Array[PackedScene] = []
@export var site_labels: PackedStringArray = []

@onready var _grid: GridContainer = $CenterContainer/VBoxContainer/Grid


func _ready() -> void:
	_grid.columns = maxi(1, mini(site_scenes.size(), 4))

	for i in range(site_scenes.size()):
		var text: String = site_labels[i] if i < site_labels.size() else "Site"
		_add_tile(text, site_scenes[i])


func _add_tile(text: String, scene: PackedScene) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(160, 100)
	btn.theme_type_variation = &"HomeTile"
	btn.pressed.connect(_navigate_to.bind(scene))
	_grid.add_child(btn)


func _navigate_to(scene: PackedScene) -> void:
	var node: Node = self
	while node:
		if node is Browser:
			(node as Browser).load_site(scene)
			return
		node = node.get_parent()
