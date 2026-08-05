class_name VerdictScreen extends Control
## 01 — Opening statement. Call the werewolf, then optionally back it with the signs
## you saw. The statement checks read and write [member GameManager.werewolf_checklist],
## so whatever was ticked in the browser's fact checker is already filled in here.

signal submitted(verdict: String)

const VERDICT_YES := "YES"
const VERDICT_NO := "NO"

const _FactToggleRowScene := preload("res://features/game_end/components/fact_toggle_row.tscn")

var _verdict := ""
var _yes_hovered := false
var _no_hovered := false

@onready var _yes_card: PanelContainer = %YesCard
@onready var _yes_dot: Panel = %YesDot
@onready var _yes_label: Label = %YesLabel
@onready var _yes_hint: Label = %YesHint
@onready var _no_card: PanelContainer = %NoCard
@onready var _no_dot: Panel = %NoDot
@onready var _no_label: Label = %NoLabel
@onready var _no_hint: Label = %NoHint
@onready var _signs_section: VBoxContainer = %SignsSection
@onready var _signs_grid: GridContainer = %SignsGrid
@onready var _selected_label: Label = %SelectedLabel
@onready var _helper: Label = %Helper
@onready var _submit_btn: Button = %SubmitBtn


func _ready() -> void:
	_yes_card.gui_input.connect(_on_card_input.bind(VERDICT_YES))
	_no_card.gui_input.connect(_on_card_input.bind(VERDICT_NO))
	_yes_card.mouse_entered.connect(_set_card_hovered.bind(VERDICT_YES, true))
	_yes_card.mouse_exited.connect(_set_card_hovered.bind(VERDICT_YES, false))
	_no_card.mouse_entered.connect(_set_card_hovered.bind(VERDICT_NO, true))
	_no_card.mouse_exited.connect(_set_card_hovered.bind(VERDICT_NO, false))
	_submit_btn.pressed.connect(_on_submit)


## Rebuilt on entry so a replayed run starts from a clean slate.
func enter() -> void:
	_verdict = ""
	for row: FactToggleRow in _signs_grid.get_children():
		_signs_grid.remove_child(row)
		row.queue_free()
	_build_signs()
	_refresh()


func _build_signs() -> void:
	var facts := WerewolfFactData.get_facts()
	for i in range(facts.size()):
		var row: FactToggleRow = _FactToggleRowScene.instantiate()
		_signs_grid.add_child(row)
		row.configure(i, facts[i].text, GameManager.werewolf_checklist.get(i, false))
		row.toggled.connect(_on_sign_toggled)


func _on_card_input(event: InputEvent, verdict: String) -> void:
	var button := event as InputEventMouseButton
	if !button || button.button_index != MOUSE_BUTTON_LEFT || !button.pressed:
		return

	_verdict = "" if _verdict == verdict else verdict
	_refresh()


func _on_sign_toggled(index: int, checked: bool) -> void:
	GameManager.werewolf_checklist[index] = checked
	_refresh_selected_count()


func _on_submit() -> void:
	if _verdict == "":
		return
	submitted.emit(_verdict)


func _set_card_hovered(verdict: String, hovered: bool) -> void:
	if verdict == VERDICT_YES:
		_yes_hovered = hovered
	else:
		_no_hovered = hovered
	_refresh_cards()


## A picked card keeps its yes/no colour on hover; only the shade lifts.
func _refresh_cards() -> void:
	var yes_picked := _verdict == VERDICT_YES
	var no_picked := _verdict == VERDICT_NO

	if yes_picked:
		_yes_card.theme_type_variation = &"GameEndChoiceYesHover" if _yes_hovered else &"GameEndChoiceYes"
	else:
		_yes_card.theme_type_variation = &"GameEndChoiceHover" if _yes_hovered else &"GameEndChoice"

	if no_picked:
		_no_card.theme_type_variation = &"GameEndChoiceNoHover" if _no_hovered else &"GameEndChoiceNo"
	else:
		_no_card.theme_type_variation = &"GameEndChoiceHover" if _no_hovered else &"GameEndChoice"

	_yes_dot.theme_type_variation = &"GameEndDotOnYes" if yes_picked else &"GameEndDotOff"
	_yes_label.theme_type_variation = &"GameEndChoiceLabelPicked" if yes_picked else &"GameEndChoiceLabel"
	_yes_hint.theme_type_variation = &"GameEndChoiceHintPicked" if yes_picked else &"GameEndChoiceHint"

	_no_dot.theme_type_variation = &"GameEndDotOnNo" if no_picked else &"GameEndDotOff"
	_no_label.theme_type_variation = &"GameEndChoiceLabelPicked" if no_picked else &"GameEndChoiceLabel"
	_no_hint.theme_type_variation = &"GameEndChoiceHintPicked" if no_picked else &"GameEndChoiceHint"


func _refresh() -> void:
	var yes_picked := _verdict == VERDICT_YES
	_refresh_cards()

	# The signs only make sense as backing for a yes.
	_signs_section.visible = yes_picked
	_submit_btn.disabled = _verdict == ""

	if _verdict == "":
		_helper.text = "Pick yes or no to continue."
	elif yes_picked:
		_helper.text = "Add the signs you saw, or submit as is."
	else:
		_helper.text = "Ready when you are."

	_refresh_selected_count()


func _refresh_selected_count() -> void:
	var count := 0
	for i in range(WerewolfFactData.fact_count()):
		if GameManager.werewolf_checklist.get(i, false):
			count += 1
	_selected_label.text = "%d selected · optional" % count
