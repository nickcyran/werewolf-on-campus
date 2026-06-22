# keeps HUD elements in sync with game systems.
class_name HUDManager extends Node

var time_label: Label
var day_end_overlay: ColorRect

var _time_tween: Tween

const _LABEL_SAFE := Color(0.95, 0.92, 0.82, 1.0)
const _LABEL_WARN := Color(0.98, 0.80, 0.28, 1.0)
const _LABEL_CRIT := Color(0.98, 0.42, 0.30, 1.0)


func initialize(label: Label, end_overlay: ColorRect) -> void:
	time_label = label
	day_end_overlay = end_overlay
	time_label.text = DayClock.get_display_time()
	DayClock.time_changed.connect(_on_time_changed)
	DayClock.day_ended.connect(_on_day_ended)


func _on_time_changed(display_time: String) -> void:
	var p := DayClock.get_progress()
	var label_color: Color
	if p < 0.60:
		label_color = _LABEL_SAFE
	elif p < 0.85:
		label_color = _LABEL_SAFE.lerp(_LABEL_WARN, (p - 0.60) / 0.25)
	else:
		label_color = _LABEL_WARN.lerp(_LABEL_CRIT, (p - 0.85) / 0.15)

	if _time_tween:
		_time_tween.kill()

	_time_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_time_tween.tween_property(time_label, "modulate:a", 0.5, 0.08)
	_time_tween.tween_callback(func():
		time_label.text = display_time
		time_label.add_theme_color_override("font_color", label_color)
	)
	_time_tween.tween_property(time_label, "modulate:a", 1.0, 0.2)


func _on_day_ended() -> void:
	if !day_end_overlay:
		return
	if day_end_overlay.has_method("run_time_up_sequence"):
		await day_end_overlay.run_time_up_sequence()
