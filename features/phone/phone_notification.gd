class_name PhoneNotification extends CanvasLayer
## Mirrors each new text onto the HUD: a phone peeks up from the bottom-right, where
## the real one sits beside the monitor, and buzzes. Only the chime played before, so
## a text was easy to miss while reading the browser. Purely visual, so clicks pass
## through to whatever is underneath.

## The phone on the desk. While the player holds it, the real screen already shows the text.
@export var phone: Interactable
## Seconds the phone stays up before sliding away.
@export var hold_seconds := 6.0
## Shown after the Esc keycap while the player is at the computer.
@export var hint_at_screen := "then pick up your phone"
@export var hint_in_room := "Pick up your phone to read it"

## Far enough to clear the peeking phone.
const _SLIDE := 320.0
const _BUZZ_ANGLE := 0.06
const _BUZZ_STEP := 0.045
const _BUZZ_SHAKES := 6

var _holding_phone := false
var _tween: Tween

@onready var _slide: Control = %Slide
@onready var _phone_body: Control = %PhoneBody
@onready var _key: Control = %Key
@onready var _hint: Label = %HintLabel
@onready var _clock: Label = %Clock
@onready var _sender: Label = %Sender
@onready var _preview: Label = %Preview


func _ready() -> void:
	_slide.visible = false
	_phone_body.resized.connect(_refresh_pivot)
	Texting.message_received.connect(_on_message_received)
	GameManager.focus_entered.connect(_on_focus_entered)
	GameManager.state_changed.connect(_on_state_changed)


func _on_message_received(thread_index: int, message: TextingMessage) -> void:
	if _holding_phone || GameManager.state == GameManager.State.TIME_UP:
		return

	_sender.text = Texting.get_thread(thread_index).contact_name
	_preview.text = message.body if message.body != "" else "Photo"
	_clock.text = DayClock.get_display_time()
	_refresh_hint()
	_pop()


## Focus is set after the state flips, so this is where the phone becomes the target.
func _on_focus_entered(node: Node3D) -> void:
	_holding_phone = node == phone
	if _holding_phone:
		_dismiss()


func _on_state_changed(state: GameManager.State) -> void:
	if state != GameManager.State.FOCUSED:
		_holding_phone = false
	if state == GameManager.State.TIME_UP:
		_dismiss()
	else:
		_refresh_hint()


func _refresh_hint() -> void:
	var at_screen := GameManager.state == GameManager.State.FOCUSED
	_key.visible = at_screen
	_hint.text = hint_at_screen if at_screen else hint_in_room


## A second text while the phone is up re-buzzes it and restarts the hold.
func _pop() -> void:
	if _tween:
		_tween.kill()
	if !_slide.visible:
		_slide.position.y = _SLIDE
		_slide.visible = true

	_tween = create_tween()
	_tween.tween_property(_slide, "position:y", 0.0, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_buzz()
	_tween.tween_interval(0.25)
	_buzz()
	_tween.tween_interval(hold_seconds)
	_tween.tween_property(_slide, "position:y", _SLIDE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_slide.hide)


func _buzz() -> void:
	for i in range(_BUZZ_SHAKES):
		var angle := _BUZZ_ANGLE if i % 2 == 0 else -_BUZZ_ANGLE
		_tween.tween_property(_phone_body, "rotation", angle, _BUZZ_STEP)
	_tween.tween_property(_phone_body, "rotation", 0.0, _BUZZ_STEP)


func _dismiss() -> void:
	if !_slide.visible:
		return
	if _tween:
		_tween.kill()
	_phone_body.rotation = 0.0
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(_slide, "position:y", _SLIDE, 0.25)
	_tween.tween_callback(_slide.hide)


## Rocks from the bottom edge, so the top of the phone swings like it's rattling the desk.
func _refresh_pivot() -> void:
	_phone_body.pivot_offset = Vector2(_phone_body.size.x / 2.0, _phone_body.size.y)
