extends Site

const HomeSiteTileScene := preload("res://features/sites/home/home_site_tile.tscn")

# palette lifted from the Tri-Search design mockup
const ACCENT := Color("9d6400")
const INK := Color("26241f")
const MUTED := Color("9b9585")
const BODY_TEXT := Color("4c4a41")
const ROW_BG_A := Color("faf9f6")
const ROW_BG_B := Color("f2f0eb")
const ROW_BORDER := Color("efede6")
const CHECK_BORDER := Color("c9c5b8")
const INDEX_COLOR := Color("c2beb2")
const CONTINUE_LOCKED_TEXT := Color("6f6a80")

@export var sites: Array[SiteDefinition] = []
## Fills the checklist box once a fact is confirmed.
@export var check_icon: Texture2D

@onready var _grid: GridContainer = %Grid
@onready var _checklist_items: VBoxContainer = %ChecklistItems
@onready var _dest_count_label: Label = %DestCountLabel
@onready var _marked_label: Label = %MarkedLabel
@onready var _ring: SourceRing = %SourceRing
@onready var _ring_label: Label = %RingLabel
@onready var _threshold_label: Label = %ThresholdLabel
@onready var _continue_btn: Button = %ContinueBtn

# per-fact visual refs: {"row_style": StyleBoxFlat, "check_style": StyleBoxFlat, "mark": TextureRect}
var _fact_rows: Array[Dictionary] = []


func _ready() -> void:
	for site in sites:
		var tile: HomeSiteTile = HomeSiteTileScene.instantiate() as HomeSiteTile
		tile.navigate_requested.connect(request_navigation)
		tile.configure(site)
		_grid.add_child(tile)

	_dest_count_label.text = "%d destinations" % sites.size()
	_threshold_label.text = "Visit %d+ to end early" % GameManager.early_end_source_threshold()

	_setup_continue_button()
	_build_checklist()
	_update_marked_tag()
	_refresh_sources()

	GameManager.source_visited.connect(_on_source_visited)
	GameManager.werewolf_fact_toggled.connect(_on_fact_toggled)


# -- sources visited / continue --------------------------------------------------

func _on_source_visited(_id: String, _count: int) -> void:
	_refresh_sources()


func _refresh_sources() -> void:
	var visited := GameManager.visited_source_count()
	var total := GameManager.total_source_count()
	_ring.progress = float(visited) / float(total) if total > 0 else 0.0
	_ring_label.text = "%d/%d" % [visited, total]

	var unlocked := GameManager.can_end_day_early()
	_continue_btn.disabled = not unlocked
	_continue_btn.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_FORBIDDEN
	)


func _setup_continue_button() -> void:
	var base := StyleBoxFlat.new()
	base.set_corner_radius_all(12)
	base.content_margin_left = 24.0
	base.content_margin_right = 24.0
	base.content_margin_top = 12.0
	base.content_margin_bottom = 12.0

	var normal := base.duplicate() as StyleBoxFlat
	normal.bg_color = ACCENT
	var hover := base.duplicate() as StyleBoxFlat
	hover.bg_color = ACCENT.lightened(0.1)
	var pressed := base.duplicate() as StyleBoxFlat
	pressed.bg_color = ACCENT.darkened(0.1)
	var disabled := base.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(1, 1, 1, 0.12)

	_continue_btn.add_theme_stylebox_override("normal", normal)
	_continue_btn.add_theme_stylebox_override("hover", hover)
	_continue_btn.add_theme_stylebox_override("pressed", pressed)
	_continue_btn.add_theme_stylebox_override("disabled", disabled)
	_continue_btn.add_theme_color_override("font_color", Color.WHITE)
	_continue_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_continue_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	_continue_btn.add_theme_color_override("font_disabled_color", CONTINUE_LOCKED_TEXT)
	_continue_btn.pressed.connect(_on_continue_pressed)


func _on_continue_pressed() -> void:
	if GameManager.can_end_day_early():
		DayClock.end_day()


# -- fact checker -----------------------------------------------------------------

func _build_checklist() -> void:
	var facts := WerewolfFactData.get_facts()
	for i in range(facts.size()):
		_checklist_items.add_child(_make_fact_row(i, facts[i].text))


func _make_fact_row(index: int, fact_text: String) -> Control:
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = ROW_BG_A if index % 2 == 0 else ROW_BG_B
	row_style.set_corner_radius_all(10)
	row_style.set_border_width_all(1)
	row_style.border_color = ROW_BORDER
	row_style.content_margin_left = 14
	row_style.content_margin_right = 14
	row_style.content_margin_top = 13
	row_style.content_margin_bottom = 13

	var row := PanelContainer.new()
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.add_theme_stylebox_override("panel", row_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)

	var idx := Label.new()
	idx.text = "%02d" % (index + 1)
	idx.add_theme_color_override("font_color", INDEX_COLOR)
	idx.add_theme_font_size_override("font_size", 11)
	idx.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(idx)

	var check_style := StyleBoxFlat.new()
	check_style.set_corner_radius_all(6)
	check_style.set_border_width_all(2)
	# Plain Panel keeps a fixed 19x19 box: toggling the mark can never change row height.
	var check := Panel.new()
	check.custom_minimum_size = Vector2(19, 19)
	check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	check.add_theme_stylebox_override("panel", check_style)
	var mark := TextureRect.new()
	mark.texture = check_icon
	mark.self_modulate = Color.WHITE
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 5)
	check.add_child(mark)
	hbox.add_child(check)

	var lbl := Label.new()
	lbl.text = fact_text
	lbl.add_theme_color_override("font_color", BODY_TEXT)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)

	row.add_child(hbox)

	_fact_rows.append({"row_style": row_style, "check_style": check_style, "mark": mark})
	_apply_fact_visual(index, GameManager.werewolf_checklist.get(index, false))

	row.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_toggle_fact(index)
	)
	row.mouse_entered.connect(func(): row_style.border_color = Color(ACCENT, 0.33))
	row.mouse_exited.connect(func(): row_style.border_color = ROW_BORDER)
	return row


func _toggle_fact(index: int) -> void:
	var checked: bool = !GameManager.werewolf_checklist.get(index, false)
	GameManager.set_werewolf_fact(index, checked)


func _on_fact_toggled(index: int, checked: bool) -> void:
	_apply_fact_visual(index, checked)
	_update_marked_tag()


func _apply_fact_visual(index: int, checked: bool) -> void:
	var refs: Dictionary = _fact_rows[index]
	var check_style: StyleBoxFlat = refs["check_style"]
	check_style.bg_color = ACCENT if checked else Color(0, 0, 0, 0)
	check_style.border_color = ACCENT if checked else CHECK_BORDER
	(refs["mark"] as TextureRect).visible = checked


func _update_marked_tag() -> void:
	var total := WerewolfFactData.fact_count()
	var checked_count := 0
	for i in range(total):
		if GameManager.werewolf_checklist.get(i, false):
			checked_count += 1
	_marked_label.text = "%d/%d marked" % [checked_count, total]
