extends ColorRect
class_name DayEndOverlay

signal learning_requested

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
@onready var _checklist_vbox: GridContainer = $DayEndCenter/TimeUpPanel/Margin/VBox/Scroll/ChecklistVBox
@onready var _confirm: Button = $DayEndCenter/TimeUpPanel/Margin/VBox/ConfirmButton
@onready var _result: Label = $DayEndCenter/TimeUpPanel/Margin/VBox/ResultLabel
@onready var _vbox: VBoxContainer = $DayEndCenter/TimeUpPanel/Margin/VBox

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
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.42, 0.44, 0.52, 0.95)
	_panel.add_theme_stylebox_override("panel", sb)
	_title.add_theme_color_override("font_color", READABLE_TEXT)
	_hint.add_theme_color_override("font_color", Color(0.75, 0.77, 0.86))
	_hint.add_theme_font_size_override("font_size", 14)
	_result.add_theme_color_override("font_color", Color(0.72, 0.74, 0.82))
	_result.add_theme_font_size_override("font_size", 14)

	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.18, 0.15, 0.06, 0.95)
	btn_normal.set_corner_radius_all(8)
	btn_normal.content_margin_left = 32
	btn_normal.content_margin_right = 32
	btn_normal.content_margin_top = 11
	btn_normal.content_margin_bottom = 11
	btn_normal.border_width_left = 1
	btn_normal.border_width_top = 1
	btn_normal.border_width_right = 1
	btn_normal.border_width_bottom = 1
	btn_normal.border_color = Color(0.7, 0.58, 0.18, 0.88)

	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.24, 0.2, 0.08, 0.98)
	btn_hover.set_corner_radius_all(8)
	btn_hover.content_margin_left = 32
	btn_hover.content_margin_right = 32
	btn_hover.content_margin_top = 11
	btn_hover.content_margin_bottom = 11
	btn_hover.border_width_left = 1
	btn_hover.border_width_top = 1
	btn_hover.border_width_right = 1
	btn_hover.border_width_bottom = 1
	btn_hover.border_color = Color(0.92, 0.78, 0.28, 1.0)

	var btn_pressed := StyleBoxFlat.new()
	btn_pressed.bg_color = Color(0.13, 0.11, 0.05, 0.98)
	btn_pressed.set_corner_radius_all(8)
	btn_pressed.content_margin_left = 32
	btn_pressed.content_margin_right = 32
	btn_pressed.content_margin_top = 11
	btn_pressed.content_margin_bottom = 11

	_confirm.add_theme_stylebox_override("normal", btn_normal)
	_confirm.add_theme_stylebox_override("hover", btn_hover)
	_confirm.add_theme_stylebox_override("pressed", btn_pressed)
	_confirm.add_theme_color_override("font_color", COLOR_GOLD)
	_confirm.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.6))
	_confirm.add_theme_color_override("font_pressed_color", Color(0.8, 0.68, 0.22))
	_confirm.add_theme_font_size_override("font_size", 15)
	_confirm.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


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
	_title.text = "Time's Up"
	_hint.text = "Check every statement you believe is true about the campus werewolf, then confirm."
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.add_theme_color_override("font_color", Color(0.75, 0.77, 0.86))
	_confirm.text = "Submit Answers"
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
		var row_style := _apply_interactive_row_style(row, i)
		var bg_normal := row_style.bg_color
		var bg_hover := bg_normal + Color(0.07, 0.07, 0.09, 0.0)
		var border_normal := row_style.border_color
		var border_hover := Color(0.52, 0.55, 0.66, 0.9)

		row.mouse_entered.connect(func():
			if _confirmed:
				return
			var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.set_parallel(true)
			tw.tween_property(row_style, "bg_color", bg_hover, 0.1)
			tw.tween_property(row_style, "border_color", border_hover, 0.1)
		)
		row.mouse_exited.connect(func():
			if _confirmed:
				return
			var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.set_parallel(true)
			tw.tween_property(row_style, "bg_color", bg_normal, 0.15)
			tw.tween_property(row_style, "border_color", border_normal, 0.15)
		)

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


func _apply_interactive_row_style(row: PanelContainer, index: int) -> StyleBoxFlat:
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
	return style


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
			hint_txt = "True, and you marked it."
			hint_col = RESULT_HINT_BRIGHT
		else:
			style.bg_color = RESULT_GREEN_OMISSION_BG
			style.border_color = RESULT_GREEN_OMISSION_BORDER
			hint_txt = "False, and you left it blank."
			hint_col = RESULT_HINT_TEAL
	else:
		style.bg_color = RESULT_RED_BG
		style.border_color = RESULT_RED_BORDER
		if statement_is_true and not player_marked:
			hint_txt = "True, but you left it unchecked."
		else:
			hint_txt = "False, but you marked it anyway."
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


func _add_continue_button() -> void:
	var btn := Button.new()
	btn.text = "Continue to Guided Learning  →"
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.focus_mode = Control.FOCUS_NONE

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.12, 0.12, 0.16, 0.80)
	st.set_corner_radius_all(8)
	st.content_margin_left   = 24
	st.content_margin_right  = 24
	st.content_margin_top    = 10
	st.content_margin_bottom = 10
	st.border_width_left = 1; st.border_width_top = 1
	st.border_width_right = 1; st.border_width_bottom = 1
	st.border_color = Color(0.55, 0.57, 0.68, 0.80)

	var st_h := StyleBoxFlat.new()
	st_h.bg_color = Color(0.18, 0.19, 0.25, 0.95)
	st_h.set_corner_radius_all(8)
	st_h.content_margin_left   = 24
	st_h.content_margin_right  = 24
	st_h.content_margin_top    = 10
	st_h.content_margin_bottom = 10
	st_h.border_width_left = 1; st_h.border_width_top = 1
	st_h.border_width_right = 1; st_h.border_width_bottom = 1
	st_h.border_color = Color(0.72, 0.75, 0.88, 1.0)

	btn.add_theme_stylebox_override("normal",  st)
	btn.add_theme_stylebox_override("hover",   st_h)
	btn.add_theme_stylebox_override("pressed", st)
	btn.add_theme_stylebox_override("focus",   st)
	btn.add_theme_color_override("font_color",       Color(0.72, 0.75, 0.88))
	btn.add_theme_color_override("font_hover_color", Color(0.95, 0.97, 1.0))
	btn.add_theme_font_size_override("font_size", 14)

	btn.modulate.a = 0.0
	_vbox.add_child(btn)

	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "modulate:a", 1.0, 0.4)

	btn.pressed.connect(func():
		btn.disabled = true
		learning_requested.emit()
	)


func _score_flavor(score: int, total: int) -> String:
	var pct := float(score) / float(total) if total > 0 else 0.0
	if pct >= 1.0:
		return "Perfect. You knew exactly what to look for."
	elif pct >= 0.75:
		return "Sharp eye. You caught most of the signs."
	elif pct >= 0.5:
		return "A few things slipped past you."
	elif pct >= 0.25:
		return "More than half the clues went unnoticed."
	else:
		return "The werewolf walked right past you."


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
	_hint.text = "%d / %d correct" % [score, total]
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.add_theme_color_override("font_color", COLOR_GOLD)
	_result.text = _score_flavor(score, total)
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
	await tw_in.finished

	_add_continue_button()
