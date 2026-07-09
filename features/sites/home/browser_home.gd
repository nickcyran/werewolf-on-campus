extends Site

const HomeSiteTileScene := preload("res://features/sites/home/home_site_tile.tscn")

@export var sites: Array[SiteDefinition] = []

@onready var _grid: GridContainer = %Grid
@onready var _checklist_items: GridContainer = %ChecklistItems


func _ready() -> void:
	_grid.columns = maxi(1, mini(sites.size(), 4))

	for site in sites:
		var tile: HomeSiteTile = HomeSiteTileScene.instantiate() as HomeSiteTile
		tile.navigate_requested.connect(request_navigation)
		tile.configure(site.icon, site.label, site.description, site.scene, site.logo)
		_grid.add_child(tile)

	_build_checklist()


func _build_checklist() -> void:
	var facts := WerewolfFactData.get_facts()
	for i in range(facts.size()):
		var is_checked: bool = GameManager.werewolf_checklist.get(i, false)

		var panel := PanelContainer.new()
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.97, 0.91, 0.78) if i % 2 == 0 else Color(0.91, 0.8, 0.58)
		style.set_corner_radius_all(10)
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.72, 0.55, 0.25, 0.55)
		panel.add_theme_stylebox_override("panel", style)

		var bg_normal := style.bg_color
		var bg_hover := bg_normal.darkened(0.08)
		var border_normal := style.border_color
		var border_hover := Color(0.72, 0.55, 0.2, 0.95)

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
		cb.text = facts[i].text
		cb.theme_type_variation = &"BrowserCheckBox"
		cb.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05, 1))
		cb.add_theme_color_override("font_hover_color", Color(0, 0, 0, 1))
		cb.add_theme_color_override("font_pressed_color", Color(0.05, 0.05, 0.05, 1))
		cb.add_theme_color_override("font_hover_pressed_color", Color(0, 0, 0, 1))
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
