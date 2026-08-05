class_name TagRow extends PanelContainer
## One taggable tell in the sniff-test drawer. Tapping anywhere on the row flips it.

signal toggled(indicator_index: int, tagged: bool)

var _index := -1
var _positive := false
var _tagged := false
var _hovered := false

@onready var _box: Label = %Box
@onready var _box_mark: TextureRect = %BoxMark
@onready var _label: Label = %Label


func _ready() -> void:
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))


func configure(indicator_index: int, indicator: ReliabilityIndicator, tagged: bool) -> void:
	_index = indicator_index
	_positive = indicator.is_positive
	_label.text = indicator.label
	_apply(tagged)


## Used when moving to the next source, where the same rows carry different marks.
func set_tagged(tagged: bool) -> void:
	_apply(tagged)


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if !button || button.button_index != MOUSE_BUTTON_LEFT || !button.pressed:
		return

	accept_event()
	_apply(!_tagged)
	toggled.emit(_index, _tagged)


func _set_hovered(hovered: bool) -> void:
	_hovered = hovered
	_apply(_tagged)


func _apply(tagged: bool) -> void:
	_tagged = tagged
	if tagged:
		theme_type_variation = &"GameEndDrawerRowOnHover" if _hovered else &"GameEndDrawerRowOn"
	else:
		theme_type_variation = &"GameEndDrawerRowHover" if _hovered else &"GameEndDrawerRow"
	_label.theme_type_variation = &"GameEndTagLabelOn" if tagged else &"GameEndTagLabel"
	_box_mark.visible = tagged

	if _positive:
		_box.theme_type_variation = &"GameEndTagBoxPosOn" if tagged else &"GameEndTagBoxPos"
	else:
		_box.theme_type_variation = &"GameEndTagBoxNegOn" if tagged else &"GameEndTagBoxNeg"
