class_name EvidenceReviewScreen extends Control
## 02 — Evidence review. Judges the statement checks against what the sources actually
## supported, one card each.

signal continued

const _ResultCardScene := preload("res://features/game_end/components/result_card.tscn")

const _QUIPS: Array[String] = [
	"A lot of these slipped past. Worth going back to see what the sources actually supported.",
	"About half. The tricky ones are usually the claims with no evidence attached.",
	"Solid reading. You caught most of what was and wasn't backed up.",
	"Excellent. You separated the supported claims from the noise almost perfectly.",
]

@onready var _score: Label = %Score
@onready var _score_total: Label = %ScoreTotal
@onready var _quip: Label = %Quip
@onready var _cards: GridContainer = %Cards
@onready var _continue_btn: Button = %ContinueBtn


func _ready() -> void:
	_continue_btn.pressed.connect(func(): continued.emit())


func enter() -> void:
	for card: ResultCard in _cards.get_children():
		_cards.remove_child(card)
		card.queue_free()

	var facts := WerewolfFactData.get_facts()
	var score := 0

	for i in range(facts.size()):
		var checked: bool = GameManager.werewolf_checklist.get(i, false)
		var read_correctly: bool = checked == facts[i].is_correct
		if read_correctly:
			score += 1

		var card: ResultCard = _ResultCardScene.instantiate()
		_cards.add_child(card)
		card.configure(facts[i].text, read_correctly, _note_for(facts[i].is_correct, checked))

	_score.text = str(score)
	_score_total.text = "/ %d read correctly" % facts.size()
	_quip.text = _QUIPS[mini(_QUIPS.size() - 1, int(score / 2.2))]


func _note_for(supported: bool, checked: bool) -> String:
	if supported:
		return "Supported by the sources, and you spotted it." if checked \
			else "This one was actually supported, but you left it out."
	return "Not supported, no source backed this up." if checked \
		else "Not supported, and you rightly left it out."
