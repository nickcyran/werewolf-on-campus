extends Control

const ROOM_SCENE := "res://features/room/room.tscn"
const SLIDE_DURATION := 0.25

## How far the claw marks travel as they slash in.
const CLAW_SLASH := Vector2(-24.0, 24.0)

@onready var _back_slot: Control = $NavBar/BackSlot
@onready var _back_btn: Button = $NavBar/BackSlot/Back
@onready var _next_slot: HBoxContainer = $NavBar/NextSlot
@onready var _forward_btn: Button = $NavBar/NextSlot/Forward
@onready var _begin_btn: Button = $NavBar/NextSlot/Begin
@onready var _page_label: Label = $NavBar/PageIndicator
@onready var _fade_overlay: ColorRect = $FadeOverlay

@onready var _hero_title: Label = %Title
@onready var _claws: Array[Control] = [%ClawsLeft, %ClawsRight]

## Every child of Slides is a page, in order, so pages are added in the editor.
var _slides: Array[Control] = []
var _slide_index: int = 0
var _is_sliding := false
var _started := false
var _room_requested := false


func _ready() -> void:
	for child in %Slides.get_children():
		_slides.append(child as Control)
		(child as Control).visible = _slides.size() == 1
	for claw in _claws:
		claw.modulate.a = 0.0

	_fade_overlay.modulate.a = 1.0
	_back_btn.pressed.connect(_on_back_pressed)
	_forward_btn.pressed.connect(_on_forward_pressed)
	_begin_btn.pressed.connect(_start_game)
	_update_nav()
	_start_ambient()
	_preload_room()

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

	_slash_claws()
	_flicker_title()


## Each set rakes in along its own strokes, the right one a beat after the left.
func _slash_claws() -> void:
	for i in range(_claws.size()):
		var claw := _claws[i]
		var rest := claw.position
		claw.position = rest - CLAW_SLASH
		claw.modulate.a = 0.0
		var tw := create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.tween_property(claw, "position", rest, 0.35).set_delay(0.5 + i * 0.18)
		tw.parallel().tween_property(claw, "modulate:a", 1.0, 0.12).set_delay(0.5 + i * 0.18)


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


## A single page drops the paging controls and centres Begin on its own.
func _update_nav() -> void:
	var on_last := _slide_index >= _slides.size() - 1
	var paged := _slides.size() > 1

	_back_slot.visible = paged
	_page_label.visible = paged
	_next_slot.alignment = BoxContainer.ALIGNMENT_BEGIN if paged else BoxContainer.ALIGNMENT_CENTER
	_back_btn.visible = _slide_index > 0
	_forward_btn.visible = !on_last
	_begin_btn.visible = on_last
	_page_label.text = "%d / %d" % [_slide_index + 1, _slides.size()]


# -- start game ---------------------------------------------------------------

## The room pulls in the browser, every site scene and the phone, which is far too much
## to load on the main thread once Begin is pressed. It goes onto a background thread
## while the player is still reading the slides instead.
func _preload_room() -> void:
	# Let the first layout and paint settle before adding load traffic.
	await get_tree().process_frame
	await get_tree().process_frame

	_room_requested = ResourceLoader.load_threaded_request(ROOM_SCENE) == OK


func _start_game() -> void:
	if _started:
		return

	_started = true
	_begin_btn.disabled = true
	_back_btn.disabled = true

	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_fade_overlay, "modulate:a", 1.0, 0.6)
	tw.tween_interval(0.2)
	await tw.finished

	var room: PackedScene = await _await_room()
	DayClock.start()
	get_tree().change_scene_to_packed(room)


## Holds on black for whatever the background load has not already covered — usually
## nothing. Falls back to a blocking load if the threaded request never took.
func _await_room() -> PackedScene:
	while _room_requested:
		match ResourceLoader.load_threaded_get_status(ROOM_SCENE):
			ResourceLoader.THREAD_LOAD_LOADED:
				return ResourceLoader.load_threaded_get(ROOM_SCENE)
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				await get_tree().process_frame
			_:
				break

	return load(ROOM_SCENE)
