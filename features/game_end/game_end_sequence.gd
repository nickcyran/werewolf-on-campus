class_name GameEndSequence extends ColorRect
## The end-of-round sequence, shown the moment the clock stops — whether it ran out or
## the browser ended the round early. Five screens in order: call the werewolf, see how
## the statements held up, learn the tells, run them on every source, then score.
##
## It also owns the hand-off out of play: dropping the player out of a focused screen
## and holding the run in [constant GameManager.State.TIME_UP].

## Emitted when the sequence hands control back. Nothing raises it yet; the run ends
## with Play Again or Main Menu.
signal closed

## Sources the sniff test walks through, in order. Set in the Inspector.
@export var sources: Array[GuidedLearningSource] = []

const _FOCUS_EXIT_FRAMES := 300
const _ROOM_SCENE := "res://features/room/room.tscn"
const _MAIN_MENU_SCENE := "res://features/landing_page/landing_page.tscn"

## source index -> { indicator index -> true }
var _tags: Dictionary = {}
var _source_index := 0

@onready var _background: Control = %Background
@onready var _verdict_screen: VerdictScreen = %VerdictScreen
@onready var _evidence_screen: EvidenceReviewScreen = %EvidenceReviewScreen
@onready var _guide_screen: FieldGuideScreen = %FieldGuideScreen
@onready var _sniff_screen: SniffTestScreen = %SniffTestScreen
@onready var _results_screen: GameEndResultsScreen = %GameEndResultsScreen


func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE

	_verdict_screen.submitted.connect(_on_verdict_submitted)
	_evidence_screen.continued.connect(_on_evidence_continued)
	_guide_screen.continued.connect(_on_guide_continued)
	_sniff_screen.back_requested.connect(_on_sniff_back)
	_sniff_screen.submitted.connect(_on_sniff_submitted)
	_sniff_screen.tag_toggled.connect(_on_tag_toggled)
	_results_screen.play_again_requested.connect(_on_play_again)
	_results_screen.main_menu_requested.connect(_on_main_menu)


func run() -> void:
	await _exit_focus_if_needed()

	GameManager.state = GameManager.State.TIME_UP
	mouse_filter = MOUSE_FILTER_STOP
	_tags.clear()
	_source_index = 0
	_verdict_screen.enter()
	_show(_verdict_screen)

	modulate.a = 0.0
	visible = true

	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.45)


# -- navigation ----------------------------------------------------------------

func _on_verdict_submitted(_verdict: String) -> void:
	_evidence_screen.enter()
	_show(_evidence_screen)


func _on_evidence_continued() -> void:
	_show(_guide_screen)


func _on_guide_continued() -> void:
	_source_index = 0
	_open_source()


## Back steps through the sources, then out to the guide from the first one.
func _on_sniff_back() -> void:
	if _source_index == 0:
		_sniff_screen.clear_source()
		_show(_guide_screen)
		return

	_source_index -= 1
	_open_source()


func _on_sniff_submitted() -> void:
	if _source_index < sources.size() - 1:
		_source_index += 1
		_open_source()
		return

	_sniff_screen.clear_source()
	_results_screen.show_score(_count_hits(), _count_tells())
	_show(_results_screen)


func _open_source() -> void:
	_show(_sniff_screen)
	_sniff_screen.show_source(
		_source_index, sources.size(), sources[_source_index], _tags_for(_source_index)
	)


func _on_tag_toggled(indicator_index: int, tagged: bool) -> void:
	var tags := _tags_for(_source_index)
	tags[indicator_index] = tagged
	_sniff_screen.refresh_counts(tags)


## The sniff test draws its own background, so the moon and sky stay behind the rest.
func _show(screen: Control) -> void:
	for child in %Screens.get_children():
		(child as Control).visible = child == screen
	_background.visible = screen != _sniff_screen


# -- scoring -------------------------------------------------------------------

func _tags_for(source_index: int) -> Dictionary:
	if !_tags.has(source_index):
		_tags[source_index] = {}
	return _tags[source_index]


func _count_hits() -> int:
	var hits := 0
	for i in range(sources.size()):
		var tags: Dictionary = _tags.get(i, {})
		for indicator_index: int in sources[i].get_indicator_indices():
			if tags.get(indicator_index, false):
				hits += 1
	return hits


func _count_tells() -> int:
	var total := 0
	for source in sources:
		total += source.get_indicator_indices().size()
	return total


# -- run lifecycle -------------------------------------------------------------

## A screen focused when the clock runs out has to release the camera first, and the
## release is tweened, so wait for the state to settle before covering the screen.
func _exit_focus_if_needed() -> void:
	if GameManager.state != GameManager.State.FOCUSED:
		return

	var focus_system := _find_focus_system()
	if !focus_system:
		return

	focus_system.unfocus()

	var frames := 0
	while GameManager.state == GameManager.State.FOCUSED && frames < _FOCUS_EXIT_FRAMES:
		await get_tree().process_frame
		frames += 1


func _find_focus_system() -> FocusSystem:
	var node: Node = get_parent()
	while node:
		var focus_system := node.get_node_or_null("FocusSystem") as FocusSystem
		if focus_system:
			return focus_system
		node = node.get_parent()
	return null


func _on_play_again() -> void:
	_reset_run()
	DayClock.start()
	get_tree().change_scene_to_file(_ROOM_SCENE)


## The menu starts its own clock when the player begins, so this one stays stopped.
func _on_main_menu() -> void:
	_reset_run()
	get_tree().change_scene_to_file(_MAIN_MENU_SCENE)


func _reset_run() -> void:
	PodcastPlayer.stop()
	DayClock.reset()
	GameManager.reset()
	Texting.reset()
