extends Node

signal time_changed(display_time: String)
signal day_ended

const REAL_DURATION := 1200.0 	# 20 real-life minutes per in-game day
const START_HOUR := 9.0 		# 9 AM
const END_HOUR := 22.0 			# 10 PM
const REFRESH_INTERVAL := 1.0

var elapsed := 0.0
var day_over := false
var started := false

var _prev_display := ""
var _refresh_acc := 0.0


func start() -> void:
	started = true


func _process(delta: float) -> void:
	if !started or day_over:
		return

	elapsed = minf(elapsed + delta, REAL_DURATION)
	if elapsed == REAL_DURATION:
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
	return clampf(elapsed / REAL_DURATION, 0.0, 1.0)


func get_display_time() -> String:
	# Convert current progress into total minutes within range
	var total_min := START_HOUR * 60.0 + get_progress() * (END_HOUR - START_HOUR) * 60.0
	var hour := int(total_min / 60.0)

	# Snap minutes to nearest 15-minute interval (0, 15, 30, 45)
	@warning_ignore("integer_division")
	var minute := int(fmod(total_min, 60.0)) / 15 * 15

	# Format to 12-hr format + Hour:Minutes AM/PM
	var hour12 := 12 if hour % 12 == 0 else hour % 12
	return "%d:%02d %s" % [hour12, minute, "AM" if hour < 12 else "PM"]
