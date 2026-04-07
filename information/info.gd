extends Control

@onready var info_panels: Array[Panel] = [$Slide1, $Slide2, $Slide3]
@onready var _back_btn: Button = $HBoxContainer/Back
@onready var _forward_btn: Button = $HBoxContainer/Forward

var panel_index: int = 0


func _ready() -> void:
	_update_buttons()


func _on_back_pressed() -> void:
	_handle_panel_change(-1)


func _on_forward_pressed() -> void:
	_handle_panel_change(1)


func _handle_panel_change(increment_amount: int) -> void:
	panel_index = clampi(panel_index + increment_amount, 0, info_panels.size() - 1)

	for i in range(info_panels.size()):
		if i == panel_index:
			info_panels[i].show()
		else:
			info_panels[i].hide()

	_update_buttons()


func _update_buttons() -> void:
	_back_btn.disabled = panel_index <= 0
	_forward_btn.disabled = panel_index >= info_panels.size() - 1
