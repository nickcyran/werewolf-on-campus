extends Control

const ROOM_SCENE := "res://features/room/room.tscn"
const SLIDE_DURATION := 0.25

@onready var _slides: Array[Panel] = [$Slide1, $Slide2, $Slide3]
@onready var _back_btn: Button = $NavBar/NavContent/Back 
@onready var _forward_btn: Button = $NavBar/NavContent/Forward 
@onready var _page_label: Label = $NavBar/NavContent/PageIndicator 
@onready var _fade_overlay: ColorRect = $FadeOverlay

var _slide_index: int = 0
var _is_sliding := false
var _started := false


func _ready() -> void:
	_fade_overlay.modulate.a = 1.0
	_back_btn.pressed.connect(_on_back_pressed)
	_forward_btn.pressed.connect(_on_forward_pressed)
	_update_nav()

	# simple fade in from black
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_fade_overlay, "modulate:a", 0.0, 0.8)


# -- navigation ---------------------------------------------------------------
func _on_back_pressed() -> void:
	if _is_sliding or _slide_index <= 0:
		return
	_change_slide(-1)


func _on_forward_pressed() -> void:
	if _is_sliding:
		return

	# last slide -> start the game
	if _slide_index >= _slides.size() - 1:
		_start_game()
		return

	_change_slide(1)


func _change_slide(direction: int) -> void:
	_is_sliding = true
	var old_panel := _slides[_slide_index]
	_slide_index += direction
	var new_panel := _slides[_slide_index]

	new_panel.show()
	new_panel.modulate.a = 0.0
	new_panel.position.x = direction * 40.0

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

	_update_nav()


func _update_nav() -> void:
	_back_btn.disabled = _slide_index <= 0
	_back_btn.visible = _slide_index > 0
	_page_label.text = "%d / %d" % [_slide_index + 1, _slides.size()]

	_forward_btn.text = "Begin ▶" if (_slide_index >= _slides.size() - 1) else "Next ▶"


# -- start game ---------------------------------------------------------------

func _start_game() -> void:
	if _started:
		return

	_started = true
	_forward_btn.disabled = true
	_back_btn.disabled = true

	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_fade_overlay, "modulate:a", 1.0, 0.6)
	tw.tween_interval(0.2)
	tw.tween_callback(func():
		DayClock.start()
		get_tree().change_scene_to_file(ROOM_SCENE)
	)
