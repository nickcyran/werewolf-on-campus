class_name FlagRow extends PanelContainer
## One flag in the source check panel. Tapping flips it while the panel is open; the
## reveal then shows whether it was really on the page.

signal toggled(indicator_index: int)

enum State { IDLE, PICKED, SPOTTED, MISSED, NOT_HERE, ABSENT }

const _ABSENT_ALPHA := 0.45
const _STATUS_FADE := 0.3

var _index := -1
var _positive := false
var _interactive := false

@onready var _box: PanelContainer = %Box
@onready var _check: TextureRect = %Check
@onready var _cross: TextureRect = %Cross
@onready var _bang: Label = %Bang
@onready var _text: Label = %Text
@onready var _status: Label = %Status


func configure(indicator_index: int, indicator: ReliabilityIndicator) -> void:
	_index = indicator_index
	_positive = indicator.is_positive
	_text.text = indicator.label
	set_state(State.IDLE)


func set_interactive(interactive: bool) -> void:
	_interactive = interactive
	mouse_default_cursor_shape = CURSOR_POINTING_HAND if interactive else CURSOR_ARROW


## [param status_delay] staggers the reveal chip so the verdicts land one after another.
func set_state(state: State, status_delay := 0.0) -> void:
	var picked_row := &"SCFlagRowPos" if _positive else &"SCFlagRowNeg"
	var flat_row := &"SCFlagRowPosFlat" if _positive else &"SCFlagRowNegFlat"
	var picked_box := &"SCFlagBoxPos" if _positive else &"SCFlagBoxNeg"

	modulate.a = _ABSENT_ALPHA if state == State.ABSENT else 1.0
	_check.visible = state == State.PICKED || state == State.SPOTTED
	_cross.visible = state == State.NOT_HERE
	_bang.visible = state == State.MISSED

	match state:
		State.PICKED:
			_apply(picked_row, picked_box, "", &"")
		State.SPOTTED:
			_apply(flat_row, picked_box, "Correct!", &"SCStatusSpotted")
		State.MISSED:
			_apply(&"SCFlagRowMiss", &"SCFlagBoxMiss", "Missed", &"SCStatusMissed")
		State.NOT_HERE:
			_apply(&"SCFlagRowNotHere", &"SCFlagBoxNotHere", "Not here", &"SCStatusNotHere")
		_:
			_apply(&"SCFlagRow", &"SCFlagBox", "", &"")

	if _status.visible:
		_status.modulate.a = 0.0
		create_tween().tween_property(_status, "modulate:a", 1.0, _STATUS_FADE).set_delay(status_delay)


func _apply(row: StringName, box: StringName, status: String, status_type: StringName) -> void:
	theme_type_variation = row
	_box.theme_type_variation = box
	_status.visible = status != ""
	_status.text = status
	_status.theme_type_variation = status_type


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if !_interactive || !button || button.button_index != MOUSE_BUTTON_LEFT || !button.pressed:
		return

	accept_event()
	toggled.emit(_index)
