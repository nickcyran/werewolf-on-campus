class_name Browser extends Control

const BrowserTab = preload("res://browser/browser_tab.gd")
const BROWSER_THEME = preload("res://browser/browser_theme.tres")

const MAX_TABS := 5

@export var home_page: PackedScene

@onready var _site_container: Control = $"Browser Content/Site"
@onready var _tabs_hbox: HBoxContainer = $"Browser Content/TabStrip/TabsHBox"
@onready var _back_btn: Button = $"Browser Content/NavBar/NavBarHBox/BackBtn"
@onready var _forward_btn: Button = $"Browser Content/NavBar/NavBarHBox/ForwardBtn"
@onready var _address_label: Label = $"Browser Content/NavBar/NavBarHBox/AddressBar/AddressLabel"

var _tabs: Array[BrowserTab] = []
var _active_tab: int = -1
var _new_tab_btn: Button


func _ready() -> void:
	theme = BROWSER_THEME
	_back_btn.pressed.connect(go_back)
	_forward_btn.pressed.connect(go_forward)

	_new_tab_btn = Button.new()
	_new_tab_btn.text = "+"
	_new_tab_btn.custom_minimum_size = Vector2(40, 0)
	_new_tab_btn.size_flags_vertical = Control.SIZE_SHRINK_END
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
	_show_page(tab)
	_refresh_nav_state()


func go_back() -> void:
	var tab := _active()

	if tab && tab.go_back():
		_show_page(tab)
		_refresh_nav_state()


func go_forward() -> void:
	var tab := _active()

	if tab && tab.go_forward():
		_show_page(tab)
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

	_refresh_nav_state()
	_refresh_tab_visuals()


func _show_page(tab: BrowserTab) -> void:
	var scene := tab.get_current_scene()
	if !scene:
		return

	var page := tab.replace_page(scene)
	if page && _tabs[_active_tab] == tab:
		_site_container.add_child(page)
	_refresh_tab_title(tab)
	_refresh_address_label()


func _active() -> BrowserTab:
	if _active_tab >= 0 && _active_tab < _tabs.size():
		return _tabs[_active_tab]

	return null


# --- Tab Bar UI ---

func _build_tab_ui(tab: BrowserTab) -> void:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 0)

	var btn := Button.new()
	btn.text = "New Tab"
	btn.custom_minimum_size = Vector2(144, 0)
	btn.size_flags_vertical = Control.SIZE_SHRINK_END
	btn.clip_text = true
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	btn.theme_type_variation = &"TabInactive"
	btn.pressed.connect(_on_tab_clicked.bind(container))

	var close_btn := Button.new()
	close_btn.text = "\u00d7"
	close_btn.custom_minimum_size = Vector2(28, 0)
	close_btn.size_flags_vertical = Control.SIZE_SHRINK_END
	close_btn.theme_type_variation = &"TabClose"
	close_btn.pressed.connect(_on_tab_close_clicked.bind(container))

	container.add_child(btn)
	container.add_child(close_btn)

	tab.button = btn
	tab.close_btn = close_btn
	tab.container = container

	_tabs_hbox.add_child(container)
	_tabs_hbox.move_child(container, _tabs_hbox.get_child_count() - 2)


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
