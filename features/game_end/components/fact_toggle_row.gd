class_name FactToggleRow extends PanelContainer
## One werewolf statement on the verdict screen. The whole card is the hit area.
##
## The root expands: a grid column only takes its share of the width when a child in
## it asks to expand, and without that the wrapping label collapses to one glyph wide.

signal toggled(index: int, checked: bool)

var _index := -1
var _checked := false
var _hovered := false

@onready var _mark: Label = %Mark
@onready var _mark_icon: TextureRect = %MarkIcon
@onready var _text: Label = %Text


func _ready() -> void:
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))


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


func _set_hovered(hovered: bool) -> void:
	_hovered = hovered
	_apply(_checked)


func _apply(checked: bool) -> void:
	_checked = checked
	if checked:
		theme_type_variation = \
			&"GameEndStatementRowCheckedHover" if _hovered else &"GameEndStatementRowChecked"
	else:
		theme_type_variation = &"GameEndStatementRowHover" if _hovered else &"GameEndStatementRow"
	_mark.theme_type_variation = &"GameEndCheckOn" if checked else &"GameEndCheckOff"
	_mark_icon.visible = checked
	_text.theme_type_variation = &"GameEndStatementChecked" if checked else &"GameEndStatement"
