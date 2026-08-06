extends Node3D

const FADE_IN_DURATION := 0.7

@onready var _fade_overlay: ColorRect = %FadeOverlay


## The landing page hands over on a full black screen, so the room lifts that same black
## rather than cutting straight to the lit scene. The first frames here are the most
## expensive ones — both screen SubViewports render for the first time — so the fade
## also covers whatever hitch that costs.
func _ready() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.1)
	tw.tween_property(_fade_overlay, "modulate:a", 0.0, FADE_IN_DURATION)
	tw.tween_callback(_fade_overlay.hide)
