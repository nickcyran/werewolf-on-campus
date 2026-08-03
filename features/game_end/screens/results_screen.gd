class_name GameEndResultsScreen extends Control
## 05 — Results. Scores the tags the player placed against the tells each source
## actually carries.

signal play_again_requested
signal main_menu_requested

@onready var _hits: Label = %Hits
@onready var _total: Label = %Total
@onready var _quip: Label = %Quip
@onready var _play_again_btn: Button = %PlayAgainBtn
@onready var _main_menu_btn: Button = %MainMenuBtn


func _ready() -> void:
	_play_again_btn.pressed.connect(func(): play_again_requested.emit())
	_main_menu_btn.pressed.connect(func(): main_menu_requested.emit())


func show_score(hits: int, total: int) -> void:
	_hits.text = str(hits)
	_total.text = "/ %d tells found" % total
	_quip.text = _quip_for(float(hits) / float(total) if total > 0 else 0.0)
	_play_again_btn.disabled = false


func _quip_for(share: float) -> String:
	if share >= 0.75:
		return "Nice work. Counting the signs before believing a page is the whole skill."
	if share >= 0.45:
		return "Good start. Keep working on the quiet tells, missing dates and unnamed funding count as much as the loud ones."
	return "Worth another try. Run the checklist top to bottom instead of going on how the writing feels."
