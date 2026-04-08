# keeps HUD elements in sync with game systems.
class_name HUDManager extends Node

var time_label: Label
var day_end_overlay: ColorRect

var _time_tween: Tween


func initialize(label: Label, end_overlay: ColorRect) -> void:
	time_label = label
	day_end_overlay = end_overlay
	time_label.text = DayClock.get_display_time()
	DayClock.time_changed.connect(_on_time_changed)
	DayClock.day_ended.connect(_on_day_ended)


func _on_time_changed(display_time: String) -> void:
	# Smooth pulse effect when time changes
	if _time_tween:
		_time_tween.kill()

	_time_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_time_tween.tween_property(time_label, "modulate:a", 0.5, 0.08)
	_time_tween.tween_callback(func(): time_label.text = display_time)
	_time_tween.tween_property(time_label, "modulate:a", 1.0, 0.2)


func _on_day_ended() -> void:
	if !day_end_overlay:
		return

	day_end_overlay.visible = true
	var day_label := day_end_overlay.get_node_or_null("DayEndLabel") as Label

	# Fade in the overlay bg
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(day_end_overlay, "color:a", 0.65, 1.5)

	# Fade in the label text
	if day_label:
		var tw2 := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw2.tween_interval(0.5)
		tw2.tween_property(day_label, "theme_override_colors/font_color:a", 1.0, 1.0)
