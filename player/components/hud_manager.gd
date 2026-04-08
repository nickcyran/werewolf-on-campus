# keeps HUD elements in sync with game systems.
class_name HUDManager extends Node

var time_label: Label


func initialize(label: Label) -> void:
	time_label = label
	time_label.text = DayClock.get_display_time()
	DayClock.time_changed.connect(_on_time_changed)


func _on_time_changed(display_time: String) -> void:
	time_label.text = display_time
