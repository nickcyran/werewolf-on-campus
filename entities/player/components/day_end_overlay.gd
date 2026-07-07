extends ColorRect
class_name DayEndOverlay

signal learning_requested

const ROW_BG_A := Color(0.2, 0.21, 0.27)
const ROW_BG_B := Color(0.26, 0.27, 0.34)

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
	_panel.theme_type_variation = &"DayEndPanel"
	_title.theme_type_variation = &"DayEndTitle"
	_hint.theme_type_variation = &"DayEndHint"
	_result.theme_type_variation = &"DayEndResult"
	_confirm.theme_type_variation = &"DayEndGoldBtn"
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
	_hint.theme_type_variation = &"DayEndHint"
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
	var facts := WerewolfFactData.get_facts()
	for i in range(facts.size()):
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
		cb.text = facts[i].text
		cb.theme_type_variation = &"DayEndCheckBox"
		cb.toggled.connect(_on_fact_toggled.bind(i))
		cb.set_pressed_no_signal(is_checked)
		inner.add_child(cb)

		var result_hint := Label.new()
		result_hint.name = &"ResultHint"
		result_hint.visible = false
		result_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	var statement_is_true: bool = WerewolfFactData.get_facts()[index].is_correct
	var ok := player_marked == statement_is_true

	var inner := row.get_child(0) as VBoxContainer
	var hint := inner.get_node_or_null("ResultHint") as Label

	row.remove_theme_stylebox_override("panel")
	if ok:
		if player_marked:
			row.theme_type_variation = &"DayEndResultCorrectMarked"
			if hint:
				hint.theme_type_variation = &"DayEndHintCorrectMarked"
				hint.text = "True, and you marked it."
		else:
			row.theme_type_variation = &"DayEndResultCorrectOmission"
			if hint:
				hint.theme_type_variation = &"DayEndHintCorrectOmission"
				hint.text = "False, and you left it blank."
	else:
		row.theme_type_variation = &"DayEndResultWrong"
		if hint:
			hint.theme_type_variation = &"DayEndHintWrong"
			if statement_is_true and not player_marked:
				hint.text = "True, but you left it unchecked."
			else:
				hint.text = "False, but you marked it anyway."

	if hint:
		hint.visible = true


func _add_continue_button() -> void:
	var btn := Button.new()
	btn.text = "Continue to Guided Learning  →"
	btn.theme_type_variation = &"DayEndSecondaryBtn"
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.focus_mode = Control.FOCUS_NONE
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
	_hint.theme_type_variation = &"DayEndHintResult"
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
