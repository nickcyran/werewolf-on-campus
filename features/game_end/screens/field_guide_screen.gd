class_name FieldGuideScreen extends Control
## 03 — Field guide. The short version of the checklist before the player runs it on
## real sources: the first few tells from each side, with why each one counts.

signal continued

const _GuideEntryScene := preload("res://features/game_end/components/guide_entry.tscn")

## Enough to teach the pattern without turning the page into the full list.
const _ENTRIES_PER_SIDE := 4

@onready var _neg_list: VBoxContainer = %NegList
@onready var _pos_list: VBoxContainer = %PosList
@onready var _continue_btn: Button = %ContinueBtn


func _ready() -> void:
	_continue_btn.pressed.connect(func(): continued.emit())
	_build()


func _build() -> void:
	var negatives: Array[ReliabilityIndicator] = []
	var positives: Array[ReliabilityIndicator] = []

	for indicator in ReliabilityIndicatorData.get_indicators():
		var side := positives if indicator.is_positive else negatives
		if side.size() < _ENTRIES_PER_SIDE:
			side.append(indicator)

	_fill(_neg_list, negatives)
	_fill(_pos_list, positives)


func _fill(list: VBoxContainer, indicators: Array[ReliabilityIndicator]) -> void:
	for i in range(indicators.size()):
		var entry: GuideEntry = _GuideEntryScene.instantiate()
		list.add_child(entry)
		entry.configure(indicators[i])
		entry.set_last(i == indicators.size() - 1)
