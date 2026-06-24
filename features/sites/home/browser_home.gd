extends Site

const HomeSiteTileScene := preload("res://features/sites/home/home_site_tile.tscn")

@export var site_scenes: Array[PackedScene] = []
@export var site_labels: PackedStringArray = []
@export var site_descriptions: PackedStringArray = []
@export var site_icons: PackedStringArray = []
@export var site_logos: Array[Texture2D] = []

@onready var _grid: GridContainer = $Scroll/PageContent/SitesSection/Grid
@onready var _checklist_items: GridContainer = $Scroll/PageContent/ChecklistSection/ChecklistMargin/ChecklistVBox/ChecklistItems


func _ready() -> void:
	_grid.columns = maxi(1, mini(site_scenes.size(), 4))

	for i in range(site_scenes.size()):
		var label_text: String = site_labels[i] if i < site_labels.size() else "Site"
		var desc_text: String = site_descriptions[i] if i < site_descriptions.size() else ""
		var icon_text: String = site_icons[i] if i < site_icons.size() else ""
		var logo: Texture2D = site_logos[i] if i < site_logos.size() else null
		var tile: HomeSiteTile = HomeSiteTileScene.instantiate() as HomeSiteTile
		tile.navigate_requested.connect(_navigate_to)
		tile.configure(icon_text, label_text, desc_text, site_scenes[i], logo)
		_grid.add_child(tile)

	_build_checklist()


func _navigate_to(scene: PackedScene) -> void:
	var node: Node = self
	while node:
		if node is Browser:
			(node as Browser).load_site(scene)
			return
		node = node.get_parent()


const COLOR_TEXT := Color(0.05, 0.06, 0.11)
const COLOR_GOLD := Color(0.65, 0.45, 0.04)

func _build_checklist() -> void:
	for i in range(WerewolfFactData.FACTS.size()):
		var is_checked: bool = GameManager.werewolf_checklist.get(i, false)

		var panel := PanelContainer.new()
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.92, 0.93, 0.96) if i % 2 == 0 else Color(0.86, 0.88, 0.93)
		style.set_corner_radius_all(8)
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.55, 0.58, 0.66, 0.55)
		panel.add_theme_stylebox_override("panel", style)

		var bg_normal := style.bg_color
		var bg_hover := bg_normal.darkened(0.08)
		var border_normal := style.border_color
		var border_hover := Color(0.42, 0.48, 0.70, 0.90)

		panel.mouse_entered.connect(func():
			var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.set_parallel(true)
			tw.tween_property(style, "bg_color", bg_hover, 0.1)
			tw.tween_property(style, "border_color", border_hover, 0.1)
		)
		panel.mouse_exited.connect(func():
			var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.set_parallel(true)
			tw.tween_property(style, "bg_color", bg_normal, 0.15)
			tw.tween_property(style, "border_color", border_normal, 0.15)
		)

		var cb := CheckBox.new()
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cb.text = WerewolfFactData.FACTS[i]
		cb.add_theme_font_size_override("font_size", 16)
		cb.add_theme_color_override("font_color", COLOR_TEXT)
		cb.add_theme_color_override("font_pressed_color", COLOR_GOLD)
		cb.add_theme_color_override("font_hover_pressed_color", COLOR_GOLD)
		cb.add_theme_color_override("font_hover_color", Color(0.02, 0.03, 0.08))
		cb.add_theme_color_override("icon_pressed_color", COLOR_GOLD)
		cb.add_theme_color_override("icon_hover_pressed_color", COLOR_GOLD)
		cb.add_theme_constant_override("outline_size", 1)
		cb.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.7))
		cb.toggled.connect(_on_fact_toggled.bind(i))
		cb.set_pressed_no_signal(is_checked)
		panel.add_child(cb)

		# Toggle the checkbox when clicking the panel padding area (outside the checkbox itself)
		panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				cb.button_pressed = !cb.button_pressed
		)

		_checklist_items.add_child(panel)


func _on_fact_toggled(checked: bool, index: int) -> void:
	GameManager.werewolf_checklist[index] = checked
