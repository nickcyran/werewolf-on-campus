class_name GuidedLearningOverlay
extends ColorRect

signal closed

# -- state ---------------------------------------------------------------------
var _sections: Array = []
var _current_page: int = 0
var _dropped_facts: Dictionary = {}
var _site_instance: Control = null

# -- ui refs (wired by scene) --------------------------------------------------
@onready var _page_label: Label = %PageLabel
@onready var _chrome_url: Label = %ChromeUrl
@onready var _svc: SubViewportContainer = %SiteContainer
@onready var _site_viewport: SubViewport = %SiteViewport
@onready var _drop_flow: HFlowContainer = %DropFlow
@onready var _pool_flow: HFlowContainer = %PoolFlow
@onready var _prev_btn: Button = %PrevBtn
@onready var _next_btn: Button = %NextBtn
@onready var _done_btn: Button = %DoneBtn
@onready var _drop_zone: PanelContainer = %DropZone


func _ready() -> void:
	visible = false
	color = Color(0, 0, 0, 0)
	mouse_filter = MOUSE_FILTER_IGNORE

	_sections = GuidedLearningData.get_sections()
	for i in range(_sections.size()):
		_dropped_facts[i] = []

	_prev_btn.pressed.connect(_on_prev)
	_next_btn.pressed.connect(_on_next)
	_done_btn.pressed.connect(_on_done)

	_drop_zone.set_drag_forwarding(
		func(_p) -> Variant: return null,
		func(_p, data) -> bool: return data is Dictionary and data.has("fact_index"),
		func(_p, data) -> void: _on_fact_dropped(int(data["fact_index"]))
	)

	_build_pool_chips()


# -- public -------------------------------------------------------------------

func run() -> void:
	_current_page = 0
	mouse_filter = MOUSE_FILTER_STOP
	color = Color(0.04, 0.04, 0.06, 0.0)
	visible = true
	_show_page(0)
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "color:a", 0.97, 0.45)


# -- page navigation ----------------------------------------------------------

func _show_page(index: int) -> void:
	var sec: Dictionary = _sections[index]
	_page_label.text = "%d / %d" % [index + 1, _sections.size()]
	_chrome_url.text = sec["url"]
	_prev_btn.disabled = (index == 0)
	_next_btn.visible = (index < _sections.size() - 1)
	_done_btn.visible = (index == _sections.size() - 1)
	_load_site_scene(sec["scene"])
	_rebuild_drop_zone()


func _load_site_scene(scene: PackedScene) -> void:
	if _site_instance:
		_site_instance.queue_free()
		_site_instance = null
	_site_instance = scene.instantiate() as Control
	if _site_instance:
		_site_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
		_site_viewport.add_child(_site_instance)


func _on_prev() -> void:
	if _current_page > 0:
		_current_page -= 1
		_show_page(_current_page)


func _on_next() -> void:
	if _current_page < _sections.size() - 1:
		_current_page += 1
		_show_page(_current_page)


func _on_done() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "color:a", 0.0, 0.4)
	await tw.finished
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE
	closed.emit()


# -- drop handling ------------------------------------------------------------

func _on_fact_dropped(fact_index: int) -> void:
	var drops: Array = _dropped_facts[_current_page]
	if drops.has(fact_index):
		return
	drops.append(fact_index)
	_rebuild_drop_zone()


func _rebuild_drop_zone() -> void:
	for child in _drop_flow.get_children():
		child.queue_free()

	var drops: Array = _dropped_facts[_current_page]
	if drops.is_empty():
		var count: int = (_sections[_current_page]["fact_indices"] as Array).size()
		var hint := Label.new()
		hint.text = "Find %d fact%s from this site" % [count, "s" if count != 1 else ""]
		hint.theme_type_variation = &"GuidedHint"
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_drop_flow.add_child(hint)
		return

	var correct_set: Array = _sections[_current_page]["fact_indices"]
	for fact_i: int in drops:
		_drop_flow.add_child(_result_chip(fact_i, correct_set.has(fact_i)))


func _result_chip(fact_index: int, correct: bool) -> Button:
	var chip := Button.new()
	chip.text = WerewolfFactData.FACTS[fact_index]
	chip.focus_mode = Control.FOCUS_NONE
	chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	chip.theme_type_variation = &"GuidedChipCorrect" if correct else &"GuidedChipWrong"
	chip.pressed.connect(func():
		(_dropped_facts[_current_page] as Array).erase(fact_index)
		_rebuild_drop_zone()
	)
	return chip


# -- pool ---------------------------------------------------------------------

func _build_pool_chips() -> void:
	for child in _pool_flow.get_children():
		child.queue_free()
	for i in range(WerewolfFactData.FACTS.size()):
		_pool_flow.add_child(_pool_chip(i))


func _pool_chip(fact_index: int) -> Button:
	var chip := Button.new()
	chip.text = WerewolfFactData.FACTS[fact_index]
	chip.focus_mode = Control.FOCUS_NONE
	chip.mouse_default_cursor_shape = Control.CURSOR_DRAG
	chip.theme_type_variation = &"GuidedChip"
	chip.set_drag_forwarding(
		func(_pos) -> Variant:
			var preview := Button.new()
			preview.text = chip.text
			preview.theme = theme
			preview.theme_type_variation = &"GuidedChip"
			chip.set_drag_preview(preview)
			return {"fact_index": fact_index},
		func(_pos, _data) -> bool: return false,
		func(_pos, _data) -> void: pass
	)
	return chip
