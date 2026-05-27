class_name Info
extends Control

signal exit_pressed

const SLIDE_DURATION := 0.25

@onready var info_panels: Array[Panel] = [$Slide1 as Panel, $Slide2 as Panel, $Slide3 as Panel]
@onready var _back_btn: Button = $NavBar/NavContent/Back as Button
@onready var _forward_btn: Button = $NavBar/NavContent/Forward as Button
@onready var _page_indicator: Label = $NavBar/NavContent/PageIndicator as Label

var panel_index: int = 0
var _is_sliding := false


func _ready() -> void:
	_update_ui()


func _on_back_pressed() -> void:
	_handle_panel_change(-1)


func _on_forward_pressed() -> void:
	_handle_panel_change(1)


func _handle_panel_change(increment_amount: int) -> void:
	if _is_sliding:
		return

	var new_index := clampi(panel_index + increment_amount, 0, info_panels.size() - 1)
	if new_index == panel_index:
		return

	_is_sliding = true
	var old_panel := info_panels[panel_index]
	var new_panel := info_panels[new_index]
	var direction := float(increment_amount)

	# Show new panel and position it offscreen
	new_panel.show()
	new_panel.modulate.a = 0.0
	new_panel.position.x = direction * 40.0

	# Animate old panel out and new panel in
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(old_panel, "modulate:a", 0.0, SLIDE_DURATION)
	tw.tween_property(old_panel, "position:x", -direction * 40.0, SLIDE_DURATION)
	tw.tween_property(new_panel, "modulate:a", 1.0, SLIDE_DURATION)
	tw.tween_property(new_panel, "position:x", 0.0, SLIDE_DURATION)
	tw.set_parallel(false)
	tw.tween_callback(func():
		old_panel.hide()
		old_panel.position.x = 0.0
		old_panel.modulate.a = 1.0
		_is_sliding = false
	)

	panel_index = new_index
	_update_ui()


func _on_exit_pressed() -> void:
	exit_pressed.emit()


func _update_ui() -> void:
	_back_btn.disabled = panel_index <= 0
	_forward_btn.disabled = panel_index >= info_panels.size() - 1
	if _page_indicator:
		_page_indicator.text = "%d / %d" % [panel_index + 1, info_panels.size()]
