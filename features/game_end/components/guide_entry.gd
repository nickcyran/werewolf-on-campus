class_name GuideEntry extends PanelContainer
## One tell in the field guide, with the reason it matters.

@onready var _mark: Label = %Mark
@onready var _label: Label = %Label
@onready var _why: Label = %Why


func configure(indicator: ReliabilityIndicator) -> void:
	_label.text = indicator.label
	_why.text = indicator.why
	_why.visible = indicator.why != ""
	_mark.text = "✓" if indicator.is_positive else "✕"
	_mark.theme_type_variation = &"GameEndMarkPos" if indicator.is_positive else &"GameEndMarkNeg"
