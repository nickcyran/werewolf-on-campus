class_name FactToggleRow extends PanelContainer
## One werewolf statement on the verdict screen. The whole card is the hit area.
##
## The root expands: a grid column only takes its share of the width when a child in
## it asks to expand, and without that the wrapping label collapses to one glyph wide.

signal toggled(index: int, checked: bool)

var _index := -1
var _checked := false

@onready var _mark: Label = %Mark
@onready var _text: Label = %Text


func configure(index: int, statement: String, checked: bool) -> void:
	_index = index
	_text.text = statement
	_apply(checked)


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if !button || button.button_index != MOUSE_BUTTON_LEFT || !button.pressed:
		return

	accept_event()
	_apply(!_checked)
	toggled.emit(_index, _checked)


func _apply(checked: bool) -> void:
	_checked = checked
	theme_type_variation = &"GameEndStatementRowChecked" if checked else &"GameEndStatementRow"
	_mark.theme_type_variation = &"GameEndCheckOn" if checked else &"GameEndCheckOff"
	_mark.text = "✕" if checked else ""
	_text.theme_type_variation = &"GameEndStatementChecked" if checked else &"GameEndStatement"
