extends ColorRect
class_name DayEndOverlay

signal learning_requested

const ChecklistRowScene := preload("res://entities/player/components/checklist_row.tscn")

@onready var _panel: PanelContainer = $DayEndCenter/TimeUpPanel
@onready var _title: Label = $DayEndCenter/TimeUpPanel/Margin/VBox/TitleLabel
@onready var _hint: Label = $DayEndCenter/TimeUpPanel/Margin/VBox/HintLabel
@onready var _scroll: ScrollContainer = $DayEndCenter/TimeUpPanel/Margin/VBox/Scroll
@onready var _checklist_vbox: GridContainer = $DayEndCenter/TimeUpPanel/Margin/VBox/Scroll/ChecklistVBox
@onready var _confirm: Button = $DayEndCenter/TimeUpPanel/Margin/VBox/ConfirmButton
@onready var _result: Label = $DayEndCenter/TimeUpPanel/Margin/VBox/ResultLabel
@onready var _vbox: VBoxContainer = $DayEndCenter/TimeUpPanel/Margin/VBox

var _rows: Array[ChecklistRow] = []
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
	var info_overlay := get_node_or_null("%InfoOverlay") as Control
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
	_rows.clear()


func _build_checklist() -> void:
	var facts := WerewolfFactData.get_facts()
	for i in range(facts.size()):
		var row: ChecklistRow = ChecklistRowScene.instantiate()
		_checklist_vbox.add_child(row)
		row.configure(i)
		row.checkbox.text = facts[i].text
		row.checkbox.toggled.connect(_on_fact_toggled.bind(i))
		row.checkbox.set_pressed_no_signal(GameManager.werewolf_checklist.get(i, false))
		_rows.append(row)


func _apply_results_row_style(row: ChecklistRow, index: int) -> void:
	var player_marked: bool = bool(GameManager.werewolf_checklist.get(index, false))
	var statement_is_true: bool = WerewolfFactData.get_facts()[index].is_correct
	var ok := player_marked == statement_is_true

	row.remove_theme_stylebox_override("panel")
	if ok:
		if player_marked:
			row.theme_type_variation = &"DayEndResultCorrectMarked"
			row.result_hint.theme_type_variation = &"DayEndHintCorrectMarked"
			row.result_hint.text = "True, and you marked it."
		else:
			row.theme_type_variation = &"DayEndResultCorrectOmission"
			row.result_hint.theme_type_variation = &"DayEndHintCorrectOmission"
			row.result_hint.text = "False, and you left it blank."
	else:
		row.theme_type_variation = &"DayEndResultWrong"
		row.result_hint.theme_type_variation = &"DayEndHintWrong"
		if statement_is_true and not player_marked:
			row.result_hint.text = "True, but you left it unchecked."
		else:
			row.result_hint.text = "False, but you marked it anyway."

	row.result_hint.visible = true


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
	for row in _rows:
		row.checkbox.disabled = true
		row.confirmed = true
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
