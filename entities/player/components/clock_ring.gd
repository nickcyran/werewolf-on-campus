class_name ClockRing
extends Control

const _TRACK_COLOR := Color(1.0, 1.0, 1.0, 0.07)
const _SAFE_COLOR  := Color(0.42, 0.75, 0.45, 0.72)
const _WARN_COLOR  := Color(0.95, 0.70, 0.18, 0.90)
const _CRIT_COLOR  := Color(0.746, 0.19, 0.219, 1.0)

const _WARN_THRESH := 0.60
const _CRIT_THRESH := 0.85

var _progress: float = 0.0
var _arc_color: Color = _SAFE_COLOR
var _pulse_tween: Tween


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	var p := DayClock.get_progress()
	if p == _progress:
		return

	_progress = p

	if _progress < _WARN_THRESH:
		_arc_color = _SAFE_COLOR
		_stop_pulse()
	elif _progress < _CRIT_THRESH:
		var t := (_progress - _WARN_THRESH) / (_CRIT_THRESH - _WARN_THRESH)
		_arc_color = _SAFE_COLOR.lerp(_WARN_COLOR, t)
		_stop_pulse()
	else:
		var t := (_progress - _CRIT_THRESH) / (1.0 - _CRIT_THRESH)
		_arc_color = _WARN_COLOR.lerp(_CRIT_COLOR, t)
		_start_pulse()

	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 3.0
	draw_arc(c, r, 0.0, TAU, 80, _TRACK_COLOR, 2.0, true)
	if _progress > 0.002:
		var end_a := -PI * 0.5 + _progress * TAU
		draw_arc(c, r, -PI * 0.5, end_a, 80, _arc_color, 3.0, true)


func _start_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_running():
		return
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "modulate:a", 0.35, 0.4)
	_pulse_tween.tween_property(self, "modulate:a", 1.0, 0.4)


func _stop_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	modulate.a = 1.0
