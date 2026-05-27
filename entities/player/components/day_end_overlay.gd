extends ColorRect
class_name DayEndOverlay

const COLOR_GOLD := Color(0.95, 0.82, 0.35)
const READABLE_TEXT := Color(0.96, 0.97, 0.98)
const ROW_BG_A := Color(0.2, 0.21, 0.27)
const ROW_BG_B := Color(0.26, 0.27, 0.34)

## You checked the box and that matched the key (statement is true).
const RESULT_GREEN_MARKED_BG := Color(0.1, 0.4, 0.24, 0.96)
const RESULT_GREEN_MARKED_BORDER := Color(0.4, 0.92, 0.55, 1.0)
## You left the box empty and that matched the key (statement is false).
const RESULT_GREEN_OMISSION_BG := Color(0.1, 0.32, 0.38, 0.96)
const RESULT_GREEN_OMISSION_BORDER := Color(0.35, 0.82, 0.92, 1.0)
const RESULT_RED_BG := Color(0.4, 0.14, 0.16, 0.96)
const RESULT_RED_BORDER := Color(0.95, 0.4, 0.42, 1.0)
const RESULT_TEXT := Color(0.98, 0.99, 1.0)
const RESULT_HINT_BRIGHT := Color(0.82, 0.95, 0.88)
const RESULT_HINT_TEAL := Color(0.78, 0.93, 0.96)
const RESULT_HINT_WRONG := Color(0.98, 0.82, 0.82)

@onready var _panel: PanelContainer = $DayEndCenter/TimeUpPanel
@onready var _title: Label = $DayEndCenter/TimeUpPanel/Margin/VBox/TitleLabel
@onready var _hint: Label = $DayEndCenter/TimeUpPanel/Margin/VBox/HintLabel
@onready var _scroll: ScrollContainer = $DayEndCenter/TimeUpPanel/Margin/VBox/Scroll
@onready var _checklist_vbox: VBoxContainer = $DayEndCenter/TimeUpPanel/Margin/VBox/Scroll/ChecklistVBox
@onready var _confirm: Button = $DayEndCenter/TimeUpPanel/Margin/VBox/ConfirmButton
@onready var _result: Label = $DayEndCenter/TimeUpPanel/Margin/VBox/ResultLabel

var _checkboxes: Array[CheckBox] = []
var _rows: Array[PanelContainer] = []
var _confirmed := false


func _ready() -> void:
	visible = false
	color = Color(0, 0, 0, 0)
	mouse_filter = MOUSE_FILTER_IGNORE
	modulate = Color.WHITE
	_confirm.pressed.connect(_on_confirm_pressed)
	_panel.visible = true
	_apply_panel_style()


func _apply_panel_style() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.14, 0.17, 0.94)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.42, 0.44, 0.52, 0.95)
	_panel.add_theme_stylebox_override("panel", sb)
	_title.add_theme_color_override("font_color", READABLE_TEXT)
	_hint.add_theme_color_override("font_color", Color(0.82, 0.84, 0.9))
	_hint.add_theme_font_size_override("font_size", 15)
	_result.add_theme_color_override("font_color", READABLE_TEXT)
	_result.add_theme_font_size_override("font_size", 18)


func run_time_up_sequence() -> void:
	await _exit_focus_if_needed()
	var ui_root := get_parent() as CanvasLayer
	if ui_root:
		var info_overlay := ui_root.get_node_or_null("InfoOverlay") as Control
		if info_overlay:
			info_overlay.visible = false
			info_overlay.modulate.a = 0.0
	GameManager.state = GameManager.State.TIME_UP
	mouse_filter = MOUSE_FILTER_STOP
	_panel.modulate = Color.WHITE
	_title.text = "Time's up"
	_hint.text = "Werewolf Fact Checker — one last pass. Check every statement you believe is true, then confirm."
	_confirmed = false
	_result.visible = false
	_result.modulate.a = 0.0
	_confirm.visible = true
	_confirm.disabled = false
	_clear_checklist()
	_build_checklist()
	color = Color(0, 0, 0, 0)
	visible = true

	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "color:a", 0.72, 1.2)
	await tw.finished

	_panel.modulate.a = 0.0
	var tw2 := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw2.tween_property(_panel, "modulate:a", 1.0, 0.5)


func _exit_focus_if_needed() -> void:
	if GameManager.state != GameManager.State.FOCUSED:
		return
	var player := get_parent().get_parent() as Node
	if player == null:
		return
	var room := player.get_parent()
	if room == null:
		return
	var fs := room.get_node_or_null("FocusSystem") as FocusSystem
	if fs:
		fs.unfocus()
	var safety := 0
	while GameManager.state == GameManager.State.FOCUSED and safety < 300:
		await get_tree().process_frame
		safety += 1


func _clear_checklist() -> void:
	for child in _checklist_vbox.get_children():
		child.queue_free()
	_checkboxes.clear()
	_rows.clear()


func _build_checklist() -> void:
	for i in range(WerewolfFactData.FACTS.size()):
		var is_checked: bool = GameManager.werewolf_checklist.get(i, false)

		var row := PanelContainer.new()
		_apply_interactive_row_style(row, i)

		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 8)

		var cb := CheckBox.new()
		cb.text = WerewolfFactData.FACTS[i]
		cb.add_theme_font_size_override("font_size", 16)
		cb.add_theme_color_override("font_color", READABLE_TEXT)
		cb.add_theme_color_override("font_pressed_color", COLOR_GOLD)
		cb.add_theme_color_override("font_hover_pressed_color", COLOR_GOLD)
		cb.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
		cb.add_theme_color_override("icon_normal_color", READABLE_TEXT)
		cb.add_theme_color_override("icon_pressed_color", COLOR_GOLD)
		cb.add_theme_color_override("icon_hover_pressed_color", COLOR_GOLD)
		cb.add_theme_color_override("font_disabled_color", READABLE_TEXT)
		cb.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
		cb.add_theme_constant_override("outline_size", 1)
		cb.toggled.connect(_on_fact_toggled.bind(i))
		cb.set_pressed_no_signal(is_checked)
		inner.add_child(cb)

		var result_hint := Label.new()
		result_hint.name = &"ResultHint"
		result_hint.visible = false
		result_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_hint.add_theme_font_size_override("font_size", 13)
		inner.add_child(result_hint)

		row.add_child(inner)
		_checklist_vbox.add_child(row)
		_checkboxes.append(cb)
		_rows.append(row)


func _apply_interactive_row_style(row: PanelContainer, index: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = ROW_BG_A if index % 2 == 0 else ROW_BG_B
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.42, 0.5, 0.65)
	row.add_theme_stylebox_override("panel", style)


func _apply_results_row_style(row: PanelContainer, index: int) -> void:
	var player_marked: bool = bool(GameManager.werewolf_checklist.get(index, false))
	var statement_is_true: bool = WerewolfFactData.CORRECT_CHECKED[index]
	var ok := player_marked == statement_is_true

	var inner := row.get_child(0) as VBoxContainer
	var cb := inner.get_child(0) as CheckBox
	var hint := inner.get_node_or_null("ResultHint") as Label

	var style := StyleBoxFlat.new()
	var hint_txt: String
	var hint_col: Color

	if ok:
		if player_marked:
			style.bg_color = RESULT_GREEN_MARKED_BG
			style.border_color = RESULT_GREEN_MARKED_BORDER
			hint_txt = "Correct — you checked this. The answer key treats this statement as true, and you marked it."
			hint_col = RESULT_HINT_BRIGHT
		else:
			style.bg_color = RESULT_GREEN_OMISSION_BG
			style.border_color = RESULT_GREEN_OMISSION_BORDER
			hint_txt = "Correct — you left this unchecked. The answer key treats this statement as false, so the right move was not to mark it."
			hint_col = RESULT_HINT_TEAL
	else:
		style.bg_color = RESULT_RED_BG
		style.border_color = RESULT_RED_BORDER
		if statement_is_true and not player_marked:
			hint_txt = "Wrong — the answer key says this statement is true, so you should have checked it."
		else:
			hint_txt = "Wrong — the answer key says this statement is false, so you should have left it unchecked."
		hint_col = RESULT_HINT_WRONG

	style.set_corner_radius_all(8)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	row.add_theme_stylebox_override("panel", style)

	if cb:
		cb.add_theme_color_override("font_color", RESULT_TEXT)
		cb.add_theme_color_override("font_disabled_color", RESULT_TEXT)
		cb.add_theme_color_override("icon_disabled_color", RESULT_TEXT)

	if hint:
		hint.text = hint_txt
		hint.visible = true
		hint.add_theme_color_override("font_color", hint_col)


func _on_fact_toggled(checked: bool, index: int) -> void:
	if _confirmed:
		return
	GameManager.werewolf_checklist[index] = checked


func _on_confirm_pressed() -> void:
	if _confirmed:
		return
	_confirmed = true
	for cb in _checkboxes:
		cb.disabled = true
	_confirm.visible = false

	var tw_out := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_out.tween_property(_panel, "modulate:a", 0.0, 0.4)
	await tw_out.finished
	_panel.visible = false

	var tw_black := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_black.tween_property(self, "color", Color(0, 0, 0, 1.0), 0.65)
	await tw_black.finished

	var score := WerewolfFactData.count_matches(GameManager.werewolf_checklist)
	var total := WerewolfFactData.fact_count()
	_title.text = "Results"
	_hint.text = "Green (lively) — right because you checked a true line. Green (teal) — right because you did not check a false line. Red — your check/omit choice did not match the key."
	_result.text = "You got %d out of %d correct." % [score, total]
	_result.visible = true
	_result.modulate.a = 0.0

	for i in range(_rows.size()):
		_apply_results_row_style(_rows[i], i)

	_panel.visible = true
	_panel.modulate.a = 0.0
	var tw_in := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_in.set_parallel(true)
	tw_in.tween_property(_panel, "modulate:a", 1.0, 0.55)
	tw_in.tween_property(_result, "modulate:a", 1.0, 0.5)
