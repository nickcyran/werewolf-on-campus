extends Node

signal state_changed(new_state: State)
signal focus_entered(interactable: Node3D)
signal source_visited(id: String, visited_count: int)

enum State { PLAYING, FOCUSED, PAUSED, TIME_UP }

# Every consultable source in the game. Browser sites mark themselves via
# Site.source_id; phone-side media (podcast, capture video, texted
# infographics) mark when viewed.
const SOURCE_IDS: Array[String] = [
	"nowolves", "greendit", "cloudmail", "channel29", "acww", "trifang_news",
	"tricitypod", "bigwolfstar93", "infographic_accurate", "infographic_inaccurate",
]

# Sources the player must visit before the browser home "Continue" unlocks.
const EARLY_END_SOURCE_THRESHOLD := 6

var state: State = State.PLAYING:
	set(value):
		if state == value:
			return
			
		state = value
		state_changed.emit(state)

# Persistent checklist state: maps fact index (int) -> checked (bool)
var werewolf_checklist := {}

# Maps source id (String) -> true once the player has seen it
var sources_visited := {}


func mark_source_visited(id: String) -> void:
	if not SOURCE_IDS.has(id):
		push_warning("Unknown source id: %s" % id)
		return
	if sources_visited.has(id):
		return
	sources_visited[id] = true
	source_visited.emit(id, sources_visited.size())


func visited_source_count() -> int:
	return sources_visited.size()


func total_source_count() -> int:
	return SOURCE_IDS.size()


func can_end_day_early() -> bool:
	return sources_visited.size() >= EARLY_END_SOURCE_THRESHOLD


func request_focus(interactable: Node3D) -> void:
	if state != State.PLAYING:
		return

	state = State.FOCUSED
	focus_entered.emit(interactable)


func release_focus() -> void:
	if state != State.FOCUSED:
		return

	state = State.PLAYING


func is_playing() -> bool:
	return state == State.PLAYING


func reset() -> void:
	werewolf_checklist = {}
	sources_visited = {}
	state = State.PLAYING
