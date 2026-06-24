class_name GuidedLearningOverlay
extends ColorRect

signal closed

enum PageState { ANSWERING, RESULTS }

# -- state ---------------------------------------------------------------------
var _sections: Array = []
var _current_page: int = 0
var _dropped_indicators: Dictionary = {}  # page_index -> Array[int]
var _page_states: Dictionary = {}          # page_index -> PageState
var _site_instance: Control = null

# -- ui refs (wired by scene) --------------------------------------------------
@onready var _page_label: Label = %PageLabel
@onready var _chrome_url: Label = %ChromeUrl
@onready var _site_viewport: SubViewport = %SiteViewport
@onready var _drop_label: Label = %DropLabel
@onready var _score_label: Label = %ScoreLabel
@onready var _drop_flow: HFlowContainer = %DropFlow
@onready var _results_label: Label = %ResultsLabel
@onready var _results_flow: HFlowContainer = %ResultsFlow
@onready var _results_zone: PanelContainer = %ResultsZone
@onready var _neg_pool_flow: HFlowContainer = %NegPoolFlow
@onready var _pos_pool_flow: HFlowContainer = %PosPoolFlow
@onready var _pool_section: VBoxContainer = %PoolSection
@onready var _drop_zone: PanelContainer = %DropZone
@onready var _prev_btn: Button = %PrevBtn
@onready var _submit_btn: Button = %SubmitBtn
@onready var _next_btn: Button = %NextBtn
@onready var _done_btn: Button = %DoneBtn
@onready var _sub_label: Label = %SubLabel
@onready var _intro_panel: Control = %IntroPanel
@onready var _content: HBoxContainer = %Content


func _ready() -> void:
	visible = false
	color = Color(0, 0, 0, 0)
	mouse_filter = MOUSE_FILTER_IGNORE

	_sections = GuidedLearningData.get_sections()
	for i in range(_sections.size()):
		_dropped_indicators[i] = []
		_page_states[i] = PageState.ANSWERING

	_prev_btn.pressed.connect(_on_prev)
	_submit_btn.pressed.connect(_on_submit)
	_next_btn.pressed.connect(_on_next)
	_done_btn.pressed.connect(_on_done)

	_drop_zone.set_drag_forwarding(
		func(_p) -> Variant: return null,
		func(_p, data) -> bool:
			return (
				data is Dictionary
				and data.has("indicator_index")
				and _page_states.get(_current_page, PageState.ANSWERING) == PageState.ANSWERING
			),
		func(_p, data) -> void: _on_indicator_dropped(int(data["indicator_index"]))
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
	_current_page = index
	var is_intro: bool = _sections[index].get("type", "") == "intro"
	var state: PageState = _page_states.get(index, PageState.ANSWERING)
	var is_results: bool = not is_intro and state == PageState.RESULTS
	var is_answering: bool = not is_intro and state == PageState.ANSWERING
	var is_last: bool = (index == _sections.size() - 1)
	var site_count: int = _sections.size() - 1

	# Header
	if is_intro:
		_page_label.text = ""
		_chrome_url.text = ""
	else:
		_page_label.text = "%d / %d" % [index, site_count]
		_chrome_url.text = _sections[index]["url"]

	# Nav buttons
	_prev_btn.disabled = (index == 0)
	_submit_btn.visible = is_answering
	_next_btn.visible = is_intro or (is_results and not is_last)
	_done_btn.visible = is_results and is_last

	# Layout visibility
	_sub_label.visible = not is_intro
	_intro_panel.visible = is_intro
	_content.visible = not is_intro

	if not is_intro:
		_drop_label.text = (
			"Your submitted answers:" if is_results
			else "Drag the indicators that apply to this site:"
		)
		_pool_section.visible = is_answering
		_score_label.visible = is_results
		_results_label.visible = is_results
		_results_zone.visible = is_results

		if is_results:
			_update_score(index)

		_load_site_scene(_sections[index]["scene"])
		_rebuild_drop_zone()
		_rebuild_results_zone()


func _update_score(index: int) -> void:
	var user_drops: Array = _dropped_indicators[index]
	var correct_set: Array = _sections[index]["indicator_indices"]
	var hits: int = 0
	for ind_i: int in user_drops:
		if correct_set.has(ind_i):
			hits += 1
	_score_label.text = "%d / %d correct" % [hits, correct_set.size()]


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
		_show_page(_current_page - 1)


func _on_next() -> void:
	if _current_page < _sections.size() - 1:
		_show_page(_current_page + 1)


func _on_submit() -> void:
	_page_states[_current_page] = PageState.RESULTS
	_show_page(_current_page)


func _on_done() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "color:a", 0.0, 0.4)
	await tw.finished
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE
	closed.emit()


# -- drop handling ------------------------------------------------------------

func _on_indicator_dropped(indicator_index: int) -> void:
	var drops: Array = _dropped_indicators[_current_page]
	if drops.has(indicator_index):
		return
	drops.append(indicator_index)
	_rebuild_drop_zone()


# Rebuilds the top zone: user's submitted picks (locked pos/neg) or the drag target
func _rebuild_drop_zone() -> void:
	for child in _drop_flow.get_children():
		child.queue_free()

	var state: PageState = _page_states.get(_current_page, PageState.ANSWERING)
	var user_drops: Array = _dropped_indicators[_current_page]

	if state == PageState.RESULTS:
		# Show what the user submitted, locked in pos/neg colours
		if user_drops.is_empty():
			var none_lbl := Label.new()
			none_lbl.text = "No indicators submitted."
			none_lbl.theme_type_variation = &"GuidedHint"
			none_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_drop_flow.add_child(none_lbl)
		else:
			for ind_i: int in user_drops:
				_drop_flow.add_child(_static_chip(ind_i))
		return

	# ANSWERING: interactive drop target
	if user_drops.is_empty():
		var count: int = (_sections[_current_page]["indicator_indices"] as Array).size()
		var hint := Label.new()
		hint.text = "Find %d indicator%s for this site" % [count, "s" if count != 1 else ""]
		hint.theme_type_variation = &"GuidedHint"
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_drop_flow.add_child(hint)
	else:
		for ind_i: int in user_drops:
			_drop_flow.add_child(_removable_chip(ind_i))


# Rebuilds the results zone: all correct indicators + wrong user picks
func _rebuild_results_zone() -> void:
	for child in _results_flow.get_children():
		child.queue_free()

	var state: PageState = _page_states.get(_current_page, PageState.ANSWERING)
	if state != PageState.RESULTS:
		return

	var user_drops: Array = _dropped_indicators[_current_page]
	var correct_set: Array = _sections[_current_page]["indicator_indices"]

	# All correct indicators in their pos/neg colour
	for ind_i: int in correct_set:
		_results_flow.add_child(_static_chip(ind_i))

	# Wrong user picks shown red after the correct ones
	for ind_i: int in user_drops:
		if not correct_set.has(ind_i):
			_results_flow.add_child(_wrong_chip(ind_i))


# Pos/neg coloured chip, non-interactive (results and submitted views)
func _static_chip(indicator_index: int) -> Button:
	var chip := Button.new()
	chip.text = ReliabilityIndicatorData.INDICATORS[indicator_index]
	chip.focus_mode = Control.FOCUS_NONE
	chip.disabled = true
	chip.theme_type_variation = (
		&"GuidedChipPos" if ReliabilityIndicatorData.IS_POSITIVE[indicator_index]
		else &"GuidedChipNeg"
	)
	return chip


# Red chip for indicators the user dragged but that don't apply
func _wrong_chip(indicator_index: int) -> Button:
	var chip := Button.new()
	chip.text = ReliabilityIndicatorData.INDICATORS[indicator_index]
	chip.focus_mode = Control.FOCUS_NONE
	chip.disabled = true
	chip.theme_type_variation = &"GuidedChipWrong"
	return chip


# Removable chip used during ANSWERING (click to unselect)
func _removable_chip(indicator_index: int) -> Button:
	var chip := Button.new()
	chip.text = ReliabilityIndicatorData.INDICATORS[indicator_index]
	chip.focus_mode = Control.FOCUS_NONE
	chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	chip.theme_type_variation = (
		&"GuidedChipPos" if ReliabilityIndicatorData.IS_POSITIVE[indicator_index]
		else &"GuidedChipNeg"
	)
	chip.pressed.connect(func():
		(_dropped_indicators[_current_page] as Array).erase(indicator_index)
		_rebuild_drop_zone()
	)
	return chip


# -- pool ---------------------------------------------------------------------

func _build_pool_chips() -> void:
	for child in _neg_pool_flow.get_children():
		child.queue_free()
	for child in _pos_pool_flow.get_children():
		child.queue_free()
	for i in range(ReliabilityIndicatorData.INDICATORS.size()):
		var chip := _pool_chip(i)
		if ReliabilityIndicatorData.IS_POSITIVE[i]:
			_pos_pool_flow.add_child(chip)
		else:
			_neg_pool_flow.add_child(chip)


func _pool_chip(indicator_index: int) -> Button:
	var chip := Button.new()
	chip.text = ReliabilityIndicatorData.INDICATORS[indicator_index]
	chip.focus_mode = Control.FOCUS_NONE
	chip.mouse_default_cursor_shape = Control.CURSOR_DRAG
	var variation: StringName = (
		&"GuidedChipPos" if ReliabilityIndicatorData.IS_POSITIVE[indicator_index]
		else &"GuidedChipNeg"
	)
	chip.theme_type_variation = variation
	chip.set_drag_forwarding(
		func(_pos) -> Variant:
			var preview := Button.new()
			preview.text = chip.text
			preview.theme = theme
			preview.theme_type_variation = variation
			chip.set_drag_preview(preview)
			return {"indicator_index": indicator_index},
		func(_pos, _data) -> bool: return false,
		func(_pos, _data) -> void: pass
	)
	return chip
