class_name RoundResultCard extends PanelContainer
## One round on the source check results board: the source, the truth, and how the
## player's call and flags measured up.

@onready var _round_num: Label = %RoundNum
@onready var _type_label: Label = %TypeLabel
@onready var _name: Label = %Name
@onready var _truth: PanelContainer = %Truth
@onready var _truth_label: Label = %TruthLabel
@onready var _call_value: Label = %CallValue
@onready var _call_check: TextureRect = %CallCheck
@onready var _call_cross: TextureRect = %CallCross
@onready var _spotted_value: Label = %SpottedValue
@onready var _wrong_value: Label = %WrongValue


func configure(
	round_number: int, source: GuidedLearningSource, called_reliable: bool,
	spotted: int, present: int, wrong: int
) -> void:
	var correct := called_reliable == source.is_reliable

	_round_num.text = "ROUND %02d" % round_number
	_type_label.text = source.source_type
	_name.text = source.display_name

	_truth.theme_type_variation = &"SCTruthGood" if source.is_reliable else &"SCTruthBad"
	_truth_label.theme_type_variation = &"SCTruthTextGood" if source.is_reliable else &"SCTruthTextBad"
	_truth_label.text = "RELIABLE" if source.is_reliable else "UNRELIABLE"

	_call_value.text = "Reliable" if called_reliable else "Not reliable"
	_call_check.visible = correct
	_call_cross.visible = !correct
	_call_value.theme_type_variation = &"SCCardValueGood" if correct else &"SCCardValueBad"
	_spotted_value.text = "%d / %d" % [spotted, present]
	_wrong_value.text = str(wrong)
