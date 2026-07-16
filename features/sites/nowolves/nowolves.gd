extends Site

const _GARLIC_POPUP_DELAY := 1.5
const _GARLIC_POPUP_FADE := 0.3

@onready var _garlic_popup: Control = %GarlicAdPopup
@onready var _garlic_close_btn: Button = %CloseBtn


func _ready() -> void:
	_garlic_close_btn.pressed.connect(_on_garlic_close_pressed)
	_garlic_popup.modulate.a = 0.0
	get_tree().create_timer(_GARLIC_POPUP_DELAY).timeout.connect(_show_garlic_popup)


func _show_garlic_popup() -> void:
	_garlic_popup.visible = true
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_garlic_popup, "modulate:a", 1.0, _GARLIC_POPUP_FADE)


func _on_garlic_close_pressed() -> void:
	_garlic_popup.visible = false
