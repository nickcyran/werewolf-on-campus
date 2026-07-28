class_name Browser extends Control

const BrowserTabClusterScene := preload("res://features/browser/browser_tab_cluster.tscn")

const MAX_TABS := 5
const PAGE_FADE_DURATION := 0.15
const ZOOM_STEP := 0.1
const ZOOM_MIN := 0.25
const ZOOM_MAX := 3.0
const ZOOM_DEFAULT := 1.0

@export var home_page: PackedScene
@export var new_tab_btn: Button
@export var zoom_out_btn: Button
@export var zoom_reset_btn: Button
@export var zoom_in_btn: Button

@onready var _site_container: Control = $"Browser Content/Site"
@onready var _tabs_hbox: HBoxContainer = $"Browser Content/TabStrip/TabsHBox"
@onready var _back_btn: Button = $"Browser Content/NavBar/NavBarHBox/BackBtn"
@onready var _forward_btn: Button = $"Browser Content/NavBar/NavBarHBox/ForwardBtn"
@onready var _address_label: Label = $"Browser Content/NavBar/NavBarHBox/AddressBar/AddressLabel"

var _tabs: Array[BrowserTab] = []
var _active_tab: int = -1
var _page_tween: Tween
var _zoom_level: float = ZOOM_DEFAULT


func _ready() -> void:
	_back_btn.pressed.connect(go_back)
	_forward_btn.pressed.connect(go_forward)
	_site_container.resized.connect(_apply_zoom)
	new_tab_btn.pressed.connect(_on_new_tab_pressed)
	zoom_out_btn.pressed.connect(_zoom_out)
	zoom_reset_btn.pressed.connect(_zoom_reset)
	zoom_in_btn.pressed.connect(_zoom_in)

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
	_tabs_hbox.move_child(cluster, new_tab_btn.get_index())
	cluster.tab_button.pressed.connect(_on_tab_clicked.bind(cluster))
	cluster.close_button.pressed.connect(_on_tab_close_clicked.bind(cluster))
	tab.cluster = cluster


func _find_tab_by_cluster(cluster: BrowserTabCluster) -> int:
	for i in range(_tabs.size()):
		if _tabs[i].cluster == cluster:
			return i
	return -1


# --- UI Refresh ---

func _refresh_tab_title(tab: BrowserTab) -> void:
	tab.cluster.tab_button.text = tab.get_title()


func _refresh_tab_visuals() -> void:
	for i in range(_tabs.size()):
		_tabs[i].cluster.tab_button.theme_type_variation = &"TabActive" if i == _active_tab else &"TabInactive"


func _refresh_nav_state() -> void:
	var tab := _active()
	_back_btn.disabled = !(tab && tab.can_go_back())
	_forward_btn.disabled = !(tab && tab.can_go_forward())
	_refresh_address_label()


func _refresh_address_label() -> void:
	var tab := _active()
	if !tab || !tab.current_page:
		_address_label.text = ""
		return

	var url := tab.get_url()
	_address_label.text = url if url != "" else "about:blank"


func _update_new_tab_visibility() -> void:
	new_tab_btn.visible = _tabs.size() < MAX_TABS


# --- Signals ---

func _on_tab_clicked(cluster: BrowserTabCluster) -> void:
	var index := _find_tab_by_cluster(cluster)
	if index >= 0:
		_switch_to_tab(index)


func _on_tab_close_clicked(cluster: BrowserTabCluster) -> void:
	var index := _find_tab_by_cluster(cluster)
	if index >= 0:
		close_tab(index)


func _on_new_tab_pressed() -> void:
	open_new_tab(home_page)


# --- Zoom ---

func _unhandled_input(event: InputEvent) -> void:
	if !visible:
		return

	if event is InputEventKey && event.pressed && event.ctrl_pressed:
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

	if event is InputEventMouseButton && event.pressed && event.ctrl_pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_in()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_out()
			get_viewport().set_input_as_handled()


func _zoom_in() -> void:
	_set_zoom(_zoom_level + ZOOM_STEP)


func _zoom_out() -> void:
	_set_zoom(_zoom_level - ZOOM_STEP)


func _zoom_reset() -> void:
	_set_zoom(ZOOM_DEFAULT)


func _set_zoom(level: float) -> void:
	_zoom_level = clampf(level, ZOOM_MIN, ZOOM_MAX)
	zoom_reset_btn.text = str(roundi(_zoom_level * 100)) + "%"
	zoom_out_btn.disabled = _zoom_level <= ZOOM_MIN
	zoom_in_btn.disabled = _zoom_level >= ZOOM_MAX
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
