extends Node3D

# -- child components (added as scene nodes) -----------------------------------
@onready var _camera_ctl: PlayerCamera = $PlayerCamera
@onready var _raycaster: InteractionRaycaster = $InteractionRaycaster
@onready var _info_ctl: InfoOverlayController = $InfoOverlayController
@onready var _hud: HUDManager = $HUDManager

# -- scene references ----------------------------------------------------------
@onready var _camera: Camera3D = $Camera3D
@onready var _time_label: Label = %TimeLabel
@onready var _info_overlay: Control = %InfoOverlay
@onready var _info_panel: Info = %InfoOverlay.get_node("InfoPanel")


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	_camera_ctl.initialize(_camera, self )
	_raycaster.initialize(_camera)
	_info_ctl.initialize(_info_overlay, _info_panel)
	_hud.initialize(_time_label)

	GameManager.state_changed.connect(_on_game_state_changed)


func _physics_process(_delta: float) -> void:
	if GameManager.is_playing():
		_raycaster.update()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		_toggle_fullscreen()
		return

	if event.is_action_pressed("toggle_info"):
		_info_ctl.toggle()
		return

	if !GameManager.is_playing():
		return

	if event.is_action_pressed("toggle_mouse"):
		_toggle_mouse_capture()
		return

	if event.is_action_pressed("interact"):
		var target := _raycaster.get_hovered()
		if target:
			target.interact()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_camera_ctl.apply_mouse_look(event.relative)


# -- signal handlers -----------------------------------------------------------

func _on_game_state_changed(new_state: GameManager.State) -> void:
	var playing := new_state == GameManager.State.PLAYING
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if playing else Input.MOUSE_MODE_VISIBLE

	if !playing:
		_raycaster.clear()


# -- helpers -------------------------------------------------------------------

func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _toggle_fullscreen() -> void:
	var window := get_window()
	if window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		window.mode = Window.MODE_WINDOWED
	else:
		window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
