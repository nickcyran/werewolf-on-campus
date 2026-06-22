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
@onready var _info_panel: Info = %InfoOverlay.get_node("InfoPanel") as Info
@onready var _interact_prompt: Label = %InteractPrompt
@onready var _day_end_overlay: ColorRect = %DayEndOverlay
@onready var _guided_learning: GuidedLearningOverlay = %GuidedLearningOverlay
@onready var _crosshair_dot: ColorRect = $UI/Control/Crosshair/CrosshairDot
@onready var _exit_focus_btn: Button = %ExitFocusBtn
@onready var _controls_hint: VBoxContainer = %ControlsHint

var _controls_hint_tween: Tween
var _controls_hint_timer: float = 8.0 # auto-hide after 8 seconds
var _controls_visible := true


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	_camera_ctl.initialize(_camera, self )
	_raycaster.initialize(_camera)
	_info_ctl.initialize(_info_overlay, _info_panel)
	_hud.initialize(_time_label, _day_end_overlay)

	_raycaster.hovered_changed.connect(_on_hovered_changed)
	GameManager.state_changed.connect(_on_game_state_changed)
	_exit_focus_btn.pressed.connect(_on_exit_focus_pressed)
	_day_end_overlay.learning_requested.connect(_on_learning_requested)
	_guided_learning.closed.connect(_on_guided_learning_closed)

	# Start controls hint visible, fade after timer
	_controls_hint.modulate.a = 0.9


func _process(delta: float) -> void:
	# Auto-hide controls hint after a few seconds
	if _controls_visible and _controls_hint_timer > 0.0:
		_controls_hint_timer -= delta
		if _controls_hint_timer <= 0.0:
			_hide_controls_hint()


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
			_pulse_crosshair()
			target.interact()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_camera_ctl.apply_mouse_look(event.relative)


# -- signal handlers -----------------------------------------------------------

func _on_game_state_changed(new_state: GameManager.State) -> void:
	var playing := new_state == GameManager.State.PLAYING
	var focused := new_state == GameManager.State.FOCUSED
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if playing else Input.MOUSE_MODE_VISIBLE

	# Show/hide crosshair and prompt based on state
	_set_crosshair_visible(playing)
	_interact_prompt.visible = false

	# Show exit-focus button only while focused
	_exit_focus_btn.visible = focused

	if !playing:
		_raycaster.clear()


func _on_hovered_changed(target: Interactable) -> void:
	if target and target.focus_mode != Interactable.FocusMode.NONE:
		_interact_prompt.text = "[LMB] Interact"
		_interact_prompt.visible = true
		# Expand crosshair on hover
		_tween_crosshair_color(Color(1.0, 0.85, 0.3, 0.95))
	else:
		_interact_prompt.visible = false
		_tween_crosshair_color(Color(1.0, 1.0, 1.0, 0.6))


# -- helpers -------------------------------------------------------------------

func _set_crosshair_visible(vis: bool) -> void:
	var crosshair := $UI/Control/Crosshair as CenterContainer
	if crosshair:
		crosshair.visible = vis


func _tween_crosshair_color(color: Color) -> void:
	if _crosshair_dot:
		var dot_color := Color(color.r, color.g, color.b, 0.9)
		var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(_crosshair_dot, "color", dot_color, 0.15)


func _pulse_crosshair() -> void:
	# Brief scale pulse on interact
	var dot := _crosshair_dot
	if dot:
		var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		dot.pivot_offset = dot.size / 2.0
		tw.tween_property(dot, "scale", Vector2(2.0, 2.0), 0.08)
		tw.tween_property(dot, "scale", Vector2(1.0, 1.0), 0.15)


func _hide_controls_hint() -> void:
	if _controls_hint_tween:
		_controls_hint_tween.kill()

	_controls_visible = false
	_controls_hint_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_controls_hint_tween.tween_property(_controls_hint, "modulate:a", 0.0, 0.5)


func _on_exit_focus_pressed() -> void:
	var focus_system := get_parent().get_node_or_null("FocusSystem") as FocusSystem
	if focus_system:
		focus_system.unfocus()


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


func _on_learning_requested() -> void:
	_guided_learning.run()


func _on_guided_learning_closed() -> void:
	_day_end_overlay.visible = false
