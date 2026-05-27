class_name Phone extends Control

const PAGE_FADE_DURATION := 0.15

@export var home_screen: PackedScene

@onready var _time_label: Label = $PhoneContent/StatusBar/StatusBarHBox/TimeLabel
@onready var _signal_label: Label = $PhoneContent/StatusBar/StatusBarHBox/SignalLabel
@onready var _battery_label: Label = $PhoneContent/StatusBar/StatusBarHBox/BatteryLabel
@onready var _back_btn: Button = $PhoneContent/StatusBar/StatusBarHBox/BackBtn
@onready var _content: Control = $PhoneContent/Content
@onready var _home_btn: Button = $PhoneContent/HomeBar/HomeBtn

var _current_page: Control = null
var _history: Array[PackedScene] = []
var _page_tween: Tween


func _ready() -> void:
	_content.clip_contents = true
	_back_btn.pressed.connect(_on_back_pressed)
	_home_btn.pressed.connect(_on_home_pressed)

	_time_label.text = DayClock.get_display_time()
	DayClock.time_changed.connect(_on_time_changed)

	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

	if home_screen:
		_show_page(home_screen, false)

	_update_nav_state()


func open_app(scene: PackedScene) -> void:
	if !scene:
		return
	_history.append(scene)
	_show_page(scene, true)
	_update_nav_state()


func go_back() -> void:
	if _history.is_empty():
		return
	_history.pop_back()
	if _history.is_empty():
		_show_page(home_screen, true)
	else:
		_show_page(_history.back(), true)
	_update_nav_state()


func go_home() -> void:
	_history.clear()
	_show_page(home_screen, true)
	_update_nav_state()


func _show_page(scene: PackedScene, animate: bool) -> void:
	if !scene:
		return

	if _current_page:
		_content.remove_child(_current_page)
		_current_page.queue_free()

	_current_page = scene.instantiate() as Control
	if !_current_page:
		return

	if animate:
		_current_page.modulate.a = 0.0

	_content.add_child(_current_page)

	if animate:
		if _page_tween:
			_page_tween.kill()
		_page_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_page_tween.tween_property(_current_page, "modulate:a", 1.0, PAGE_FADE_DURATION)


func _update_nav_state() -> void:
	_back_btn.visible = !_history.is_empty()


func _on_back_pressed() -> void:
	go_back()


func _on_home_pressed() -> void:
	go_home()


func _on_time_changed(display_time: String) -> void:
	_time_label.text = display_time
