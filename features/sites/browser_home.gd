extends Site

@export var site_scenes: Array[PackedScene] = []
@export var site_labels: PackedStringArray = []
@export var site_descriptions: PackedStringArray = []
@export var site_icons: PackedStringArray = []

@onready var _grid: GridContainer = $CenterContainer/VBoxContainer/Grid


func _ready() -> void:
	_grid.columns = maxi(1, mini(site_scenes.size(), 4))

	for i in range(site_scenes.size()):
		var label_text: String = site_labels[i] if i < site_labels.size() else "Site"
		var desc_text: String = site_descriptions[i] if i < site_descriptions.size() else ""
		var icon_text: String = site_icons[i] if i < site_icons.size() else ""
		_add_tile(label_text, desc_text, icon_text, site_scenes[i])


func _add_tile(text: String, description: String, icon: String, scene: PackedScene) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(200, 120)
	btn.theme_type_variation = &"HomeTile"
	btn.pressed.connect(_navigate_to.bind(scene))

	# Build rich content inside button via a VBoxContainer override
	btn.text = ""

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Icon
	var icon_label := Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 28)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_label)

	# Title
	var title_label := Label.new()
	title_label.text = text
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.25, 1))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_label)

	# Description
	if description != "":
		var desc_label := Label.new()
		desc_label.text = description
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1))
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(desc_label)

	btn.add_child(vbox)
	_grid.add_child(btn)


func _navigate_to(scene: PackedScene) -> void:
	var node: Node = self
	while node:
		if node is Browser:
			(node as Browser).load_site(scene)
			return
		node = node.get_parent()
