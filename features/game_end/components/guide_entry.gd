class_name GuideEntry extends PanelContainer
## One tell in the field guide, with the reason it matters.

@onready var _mark_pos: TextureRect = %MarkPos
@onready var _mark_neg: TextureRect = %MarkNeg
@onready var _label: Label = %Label
@onready var _why: Label = %Why


func configure(indicator: ReliabilityIndicator) -> void:
	_label.text = indicator.label
	_why.text = indicator.why
	_why.visible = indicator.why != ""
	_mark_pos.visible = indicator.is_positive
	_mark_neg.visible = !indicator.is_positive


## The bottom row sits on the panel's rounded edge, so it drops its divider rather than
## drawing a straight line across the corners.
func set_last(is_last: bool) -> void:
	theme_type_variation = &"GameEndGuideRowLast" if is_last else &"GameEndGuideRow"
