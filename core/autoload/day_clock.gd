extends Node

signal time_changed(display_time: String)
signal day_ended

## Wall-clock seconds for one full in-game day (until day_ended fires). Default 1200 ≈ 20 minutes.
@export_range(30.0, 14400.0, 1.0, "or_greater") var max_game_time_seconds: float = 1200.0

const START_HOUR := 9.0 		# 9 AM
const END_HOUR := 22.0 			# 10 PM
const REFRESH_INTERVAL := 1.0

var elapsed := 0.0
var day_over := false
var started := false

## Debug/testing only: set by the backslash shortcut so the end sequence opens straight
## into the sniff test instead of the verdict screen.
var debug_skip_to_sniff := false

var _prev_display := ""
var _refresh_acc := 0.0


func start() -> void:
	started = true


func reset() -> void:
	elapsed = 0.0
	day_over = false
	started = false
	debug_skip_to_sniff = false
	_prev_display = ""
	_refresh_acc = 0.0


## Force the day to end now (e.g. the browser home "Continue" button).
func end_day() -> void:
	if day_over or !started:
		return
	elapsed = max_game_time_seconds
	day_over = true
	day_ended.emit()


## Debug/testing only: backslash ends the night immediately and skips to the sniff test.
func _unhandled_input(event: InputEvent) -> void:
	if !event.is_action_pressed("debug_end_day"):
		return

	get_viewport().set_input_as_handled()
	if day_over || !started:
		return

	debug_skip_to_sniff = true
	end_day()


func _process(delta: float) -> void:
	if !started or day_over:
		return

	elapsed = minf(elapsed + delta, max_game_time_seconds)
	if not day_over and elapsed >= max_game_time_seconds:
		day_over = true
		day_ended.emit()

	# throttle the expensive string-format path
	_refresh_acc += delta
	if _refresh_acc < REFRESH_INTERVAL:
		return
	_refresh_acc = 0.0

	var display := get_display_time()
	if display != _prev_display:
		_prev_display = display
		time_changed.emit(display)


func get_progress() -> float:
	return clampf(elapsed / max_game_time_seconds, 0.0, 1.0)


func get_display_time() -> String:
	return progress_to_display_time(get_progress())


func progress_to_display_time(progress: float) -> String:
	# Convert progress into total minutes within range
	var total_min := START_HOUR * 60.0 + clampf(progress, 0.0, 1.0) * (END_HOUR - START_HOUR) * 60.0
	var hour := int(total_min / 60.0)

	# Snap minutes to nearest 15-minute interval (0, 15, 30, 45)
	@warning_ignore("integer_division")
	var minute := int(fmod(total_min, 60.0)) / 15 * 15

	# Format to 12-hr format + Hour:Minutes AM/PM
	var hour12 := 12 if hour % 12 == 0 else hour % 12
	return "%d:%02d %s" % [hour12, minute, "AM" if hour < 12 else "PM"]
