class_name Browser extends Control

const BrowserTab = preload("res://features/browser/browser_tab.gd")
const BrowserTabClusterScene := preload("res://features/browser/browser_tab_cluster.tscn")

const MAX_TABS := 5
const PAGE_FADE_DURATION := 0.15
const ZOOM_STEP := 0.1
const ZOOM_MIN := 0.25
const ZOOM_MAX := 3.0
const ZOOM_DEFAULT := 1.0

@export var home_page: PackedScene

@onready var _site_container: Control = $"Browser Content/Site"
@onready var _tabs_hbox: HBoxContainer = $"Browser Content/TabStrip/TabsHBox"
@onready var _back_btn: Button = $"Browser Content/NavBar/NavBarHBox/BackBtn"
@onready var _forward_btn: Button = $"Browser Content/NavBar/NavBarHBox/ForwardBtn"
@onready var _address_label: Label = $"Browser Content/NavBar/NavBarHBox/AddressBar/AddressLabel"
@onready var _nav_hbox: HBoxContainer = $"Browser Content/NavBar/NavBarHBox"

var _tabs: Array[BrowserTab] = []
var _active_tab: int = -1
var _new_tab_btn: Button
var _page_tween: Tween
var _zoom_level: float = 1.0
var _zoom_label: Button
var _zoom_out_btn: Button
var _zoom_in_btn: Button


func _ready() -> void:
	_back_btn.pressed.connect(go_back)
	_forward_btn.pressed.connect(go_forward)
	_site_container.clip_contents = true
	_site_container.resized.connect(_apply_zoom)

	_build_zoom_controls()

	_new_tab_btn = Button.new()
	_new_tab_btn.text = "+"
	_new_tab_btn.custom_minimum_size = Vector2(40, 0)
	_new_tab_btn.size_flags_vertical = Control.SIZE_FILL
	_new_tab_btn.theme_type_variation = &"NewTabButton"
	_new_tab_btn.pressed.connect(_on_new_tab_pressed)
	_tabs_hbox.add_child(_new_tab_btn)

	for child in _site_container.get_children():
		_site_container.remove_child(child)
		child.queue_free()

	open_new_tab(home_page)


# --- Public API ---

func open_new_tab(scene: PackedScene = null) -> void:
	if _tabs.size() >= MAX_TABS:
		return

	var tab := BrowserTab.new()
	_tabs.append(tab)
	_build_tab_ui(tab)
	_switch_to_tab(_tabs.size() - 1)

	if scene:
		load_site(scene)

	_update_new_tab_visibility()


func close_tab(index: int) -> void:
	if index < 0 || index >= _tabs.size() || _tabs.size() <= 1:
		return

	var was_active := (index == _active_tab)
	_tabs[index].destroy()
	_tabs.remove_at(index)

	if was_active:
		_active_tab = -1
		_switch_to_tab(mini(index, _tabs.size() - 1))
	elif _active_tab > index:
		_active_tab -= 1
		_refresh_tab_visuals()
	else:
		_refresh_tab_visuals()

	_update_new_tab_visibility()


func load_site(scene: PackedScene) -> void:
	if !scene || _active_tab < 0:
		return

	var tab := _tabs[_active_tab]
	tab.navigate_to(scene)
	_show_page_animated(tab)
	_refresh_nav_state()


func go_back() -> void:
	var tab := _active()

	if tab && tab.go_back():
		_show_page_animated(tab)
		_refresh_nav_state()


func go_forward() -> void:
	var tab := _active()

	if tab && tab.go_forward():
		_show_page_animated(tab)
		_refresh_nav_state()


# --- Tab Switching ---

func _switch_to_tab(index: int) -> void:
	if index < 0 || index >= _tabs.size():
		return

	var old := _active()
	if old:
		old.detach_page()

	_active_tab = index
	var tab := _tabs[_active_tab]
	if tab.current_page && tab.current_page.get_parent() != _site_container:
		_site_container.add_child(tab.current_page)

	_apply_zoom()
	_refresh_nav_state()
	_refresh_tab_visuals()


func _show_page_animated(tab: BrowserTab) -> void:
	var scene := tab.get_current_scene()
	if !scene:
		return

	var page := tab.replace_page(scene)
	if page && _tabs[_active_tab] == tab:
		page.modulate.a = 0.0
		_site_container.add_child(page)

		# Fade in the new page
		if _page_tween:
			_page_tween.kill()
			
		_page_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_page_tween.tween_property(page, "modulate:a", 1.0, PAGE_FADE_DURATION)

	_apply_zoom()
	_refresh_tab_title(tab)
	_refresh_address_label()


func _active() -> BrowserTab:
	if _active_tab >= 0 && _active_tab < _tabs.size():
		return _tabs[_active_tab]

	return null


# --- Tab Bar UI ---

func _build_tab_ui(tab: BrowserTab) -> void:
	var cluster: BrowserTabCluster = BrowserTabClusterScene.instantiate()
	_tabs_hbox.add_child(cluster)
	_tabs_hbox.move_child(cluster, _tabs_hbox.get_child_count() - 2)
	cluster.tab_button.pressed.connect(_on_tab_clicked.bind(cluster))
	cluster.close_button.pressed.connect(_on_tab_close_clicked.bind(cluster))
	tab.button = cluster.tab_button
	tab.close_btn = cluster.close_button
	tab.container = cluster


func _find_tab_by_container(container: HBoxContainer) -> int:
	for i in range(_tabs.size()):
		if _tabs[i].container == container:
			return i
	return -1


# --- UI Refresh ---

func _refresh_tab_title(tab: BrowserTab) -> void:
	if tab.button:
		tab.button.text = tab.get_title()


func _refresh_tab_visuals() -> void:
	for i in range(_tabs.size()):
		if _tabs[i].button:
			_tabs[i].button.theme_type_variation = &"TabActive" if i == _active_tab else &"TabInactive"


func _refresh_nav_state() -> void:
	var tab := _active()
	_back_btn.disabled = not (tab and tab.can_go_back())
	_forward_btn.disabled = not (tab and tab.can_go_forward())
	_refresh_address_label()


func _refresh_address_label() -> void:
	var tab := _active()
	if !tab || !tab.current_page:
		_address_label.text = ""
		return
		
	var title := tab.get_title()
	_address_label.text = title if title != "New Tab" else "about:blank"


func _update_new_tab_visibility() -> void:
	if _new_tab_btn:
		_new_tab_btn.visible = _tabs.size() < MAX_TABS


# --- Signals ---

func _on_tab_clicked(container: HBoxContainer) -> void:
	var index := _find_tab_by_container(container)
	if index >= 0:
		_switch_to_tab(index)


func _on_tab_close_clicked(container: HBoxContainer) -> void:
	var index := _find_tab_by_container(container)
	if index >= 0:
		close_tab(index)


func _on_new_tab_pressed() -> void:
	open_new_tab(home_page)


# --- Zoom ---

func _unhandled_input(event: InputEvent) -> void:
	if !visible:
		return

	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed:
			match event.keycode:
				KEY_EQUAL:
					_zoom_in()
					get_viewport().set_input_as_handled()
				KEY_MINUS:
					_zoom_out()
					get_viewport().set_input_as_handled()
				KEY_0:
					_set_zoom(ZOOM_DEFAULT)
					get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.pressed and event.ctrl_pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_in()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_out()
			get_viewport().set_input_as_handled()


func _build_zoom_controls() -> void:
	_zoom_out_btn = Button.new()
	_zoom_out_btn.text = "-"
	_zoom_out_btn.custom_minimum_size = Vector2(28, 28)
	_zoom_out_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_zoom_out_btn.theme_type_variation = &"NavButton"
	_zoom_out_btn.tooltip_text = "Zoom out (Ctrl+-)"
	_zoom_out_btn.pressed.connect(_zoom_out)

	var reset_btn := Button.new()
	reset_btn.custom_minimum_size = Vector2(48, 28)
	reset_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	reset_btn.theme_type_variation = &"NavButton"
	reset_btn.text = "100%"
	reset_btn.tooltip_text = "Reset zoom (Ctrl+0)"
	reset_btn.pressed.connect(_zoom_reset)
	_zoom_label = reset_btn

	_zoom_in_btn = Button.new()
	_zoom_in_btn.text = "+"
	_zoom_in_btn.custom_minimum_size = Vector2(28, 28)
	_zoom_in_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_zoom_in_btn.theme_type_variation = &"NavButton"
	_zoom_in_btn.tooltip_text = "Zoom in (Ctrl+=)"
	_zoom_in_btn.pressed.connect(_zoom_in)

	_nav_hbox.add_child(_zoom_out_btn)
	_nav_hbox.add_child(_zoom_label)
	_nav_hbox.add_child(_zoom_in_btn)


func _zoom_in() -> void:
	_set_zoom(_zoom_level + ZOOM_STEP)


func _zoom_out() -> void:
	_set_zoom(_zoom_level - ZOOM_STEP)


func _zoom_reset() -> void:
	_set_zoom(ZOOM_DEFAULT)


func _set_zoom(level: float) -> void:
	_zoom_level = clampf(level, ZOOM_MIN, ZOOM_MAX)
	_zoom_label.text = str(roundi(_zoom_level * 100)) + "%"
	_zoom_out_btn.disabled = _zoom_level <= ZOOM_MIN
	_zoom_in_btn.disabled = _zoom_level >= ZOOM_MAX
	_apply_zoom()


func _apply_zoom() -> void:
	var container_size := _site_container.size
	for child in _site_container.get_children():
		if child is Control:
			child.set_anchors_preset(Control.PRESET_TOP_LEFT)
			child.pivot_offset = Vector2.ZERO
			child.position = Vector2.ZERO
			child.scale = Vector2(_zoom_level, _zoom_level)
			child.size = container_size / _zoom_level
