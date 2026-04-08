# manages the info-slide overlay panel with smooth transitions.
class_name InfoOverlayController extends Node

const FADE_DURATION := 0.3
const SLIDE_OFFSET := 30.0

# covers the screen (dim + info panel).
var overlay: Control
var info_panel: Info

var _state_before_open: GameManager.State 
var _dim_rect: ColorRect
var _tween: Tween
var _is_animating := false


func initialize(overlay_node: Control, panel: Info) -> void:
	overlay = overlay_node
	info_panel = panel
	overlay.visible = false
	overlay.modulate.a = 0.0
	info_panel.exit_pressed.connect(toggle)

	# Cache dim rect for animation
	_dim_rect = overlay.get_node_or_null("DimRect") as ColorRect


# toggle the overlay open / closed with animation.
func toggle() -> void:
	if _is_animating:
		return

	if overlay.visible:
		_animate_close()
	else:
		_animate_open()


func _animate_open() -> void:
	_is_animating = true
	_state_before_open = GameManager.state
	GameManager.state = GameManager.State.PAUSED

	overlay.visible = true
	overlay.modulate.a = 0.0

	# Slide the info panel up slightly
	info_panel.position.y += SLIDE_OFFSET

	if _tween:
		_tween.kill()

	_tween = overlay.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.set_parallel(true)
	_tween.tween_property(overlay, "modulate:a", 1.0, FADE_DURATION)
	_tween.tween_property(info_panel, "position:y", info_panel.position.y - SLIDE_OFFSET, FADE_DURATION)
	_tween.set_parallel(false)
	_tween.tween_callback(func(): _is_animating = false)


func _animate_close() -> void:
	_is_animating = true

	if _tween:
		_tween.kill()

	_tween = overlay.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.set_parallel(true)
	_tween.tween_property(overlay, "modulate:a", 0.0, FADE_DURATION * 0.8)
	_tween.tween_property(info_panel, "position:y", info_panel.position.y + SLIDE_OFFSET, FADE_DURATION * 0.8)
	_tween.set_parallel(false)
	_tween.tween_callback(func():
		overlay.visible = false
		_is_animating = false
		GameManager.state = _state_before_open
	)
