extends Control

const ROOM_SCENE := "res://features/room/room.tscn"
const SLIDE_DURATION := 0.25

@onready var _slides: Array[Control] = [$Slide1, $Slide2, $Slide3]
@onready var _back_btn: Button = $NavBar/BackSlot/Back
@onready var _forward_btn: Button = $NavBar/NextSlot/Forward
@onready var _begin_btn: Button = $NavBar/NextSlot/Begin
@onready var _page_label: Label = $NavBar/PageIndicator
@onready var _fade_overlay: ColorRect = $FadeOverlay

@onready var _moon_glow: TextureRect = $Background/Moon/Glow
@onready var _hero_title: Label = $Slide1/Scroll/Margin/VBox/Title

var _slide_index: int = 0
var _is_sliding := false
var _started := false


func _ready() -> void:
	_fade_overlay.modulate.a = 1.0
	_back_btn.pressed.connect(_on_back_pressed)
	_forward_btn.pressed.connect(_on_forward_pressed)
	_begin_btn.pressed.connect(_start_game)
	_update_nav()
	_start_ambient()

	# simple fade in from black
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_fade_overlay, "modulate:a", 0.0, 0.8)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		ScreenMode.toggle()


# -- ambience -----------------------------------------------------------------
func _start_ambient() -> void:
	# wait for the first layout pass so the tweens capture settled positions
	await get_tree().process_frame
	await get_tree().process_frame

	_pulse_moon()
	_flicker_title()


func _pulse_moon() -> void:
	var tw := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.set_parallel(true)
	tw.tween_property(_moon_glow, "scale", Vector2(1.14, 1.14), 2.5)
	tw.tween_property(_moon_glow, "modulate:a", 1.0, 2.5)
	tw.chain()
	tw.set_parallel(true)
	tw.tween_property(_moon_glow, "scale", Vector2.ONE, 2.5)
	tw.tween_property(_moon_glow, "modulate:a", 0.7, 2.5)


func _flicker_title() -> void:
	var tw := create_tween().set_loops()
	tw.tween_interval(5.5)
	tw.tween_property(_hero_title, "modulate:a", 0.4, 0.06)
	tw.tween_property(_hero_title, "modulate:a", 1.0, 0.06)
	tw.tween_property(_hero_title, "modulate:a", 0.6, 0.12)
	tw.tween_property(_hero_title, "modulate:a", 1.0, 0.06)
	tw.tween_interval(0.2)


# -- navigation ---------------------------------------------------------------
func _on_back_pressed() -> void:
	if _is_sliding || _slide_index <= 0:
		return
	_change_slide(-1)


func _on_forward_pressed() -> void:
	if _is_sliding || _slide_index >= _slides.size() - 1:
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
	var on_last := _slide_index >= _slides.size() - 1

	_back_btn.visible = _slide_index > 0
	_forward_btn.visible = !on_last
	_begin_btn.visible = on_last
	_page_label.text = "%d / %d" % [_slide_index + 1, _slides.size()]


# -- start game ---------------------------------------------------------------

func _start_game() -> void:
	if _started:
		return

	_started = true
	_begin_btn.disabled = true
	_back_btn.disabled = true

	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_fade_overlay, "modulate:a", 1.0, 0.6)
	tw.tween_interval(0.2)
	tw.tween_callback(func():
		DayClock.start()
		get_tree().change_scene_to_file(ROOM_SCENE)
	)
