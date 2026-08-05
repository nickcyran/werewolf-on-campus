class_name ResultCard extends PanelContainer
## One judged statement on the evidence-review screen.

@onready var _badge: Label = %Badge
@onready var _badge_good: TextureRect = %BadgeGood
@onready var _badge_bad: TextureRect = %BadgeBad
@onready var _label: Label = %Label
@onready var _note: Label = %Note


func configure(statement: String, read_correctly: bool, note: String) -> void:
	_label.text = statement
	_note.text = note
	_badge_good.visible = read_correctly
	_badge_bad.visible = !read_correctly
	_badge.theme_type_variation = &"GameEndBadgeGood" if read_correctly else &"GameEndBadgeBad"
