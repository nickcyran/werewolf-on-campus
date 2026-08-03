class_name ResultCard extends PanelContainer
## One judged statement on the evidence-review screen.

@onready var _badge: Label = %Badge
@onready var _label: Label = %Label
@onready var _note: Label = %Note


func configure(statement: String, read_correctly: bool, note: String) -> void:
	_label.text = statement
	_note.text = note
	_badge.text = "✓" if read_correctly else "✕"
	_badge.theme_type_variation = &"GameEndBadgeGood" if read_correctly else &"GameEndBadgeBad"
