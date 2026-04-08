# manages the info-slide overlay panel.
class_name InfoOverlayController extends Node

# covers the screen (dim + info panel).
var overlay: Control
var info_panel: Info

var _state_before_open: GameManager.State

func initialize(overlay_node: Control, panel: Info) -> void:
	overlay = overlay_node
	info_panel = panel
	overlay.visible = false
	info_panel.exit_pressed.connect(toggle)


# toggle the overlay open / closed.
func toggle() -> void:
	overlay.visible = !overlay.visible

	if overlay.visible:
		_state_before_open = GameManager.state
		GameManager.state = GameManager.State.PAUSED
	else:
		GameManager.state = _state_before_open
