extends Control

const BUBBLE_COLOR := Color(0.16, 0.18, 0.32, 1)
const UNREAD_ROW_COLOR := Color(0.17, 0.19, 0.36, 1)
const READ_ROW_COLOR := Color(0.11, 0.12, 0.22, 1)
const UNREAD_DOT_COLOR := Color(0.95, 0.35, 0.35, 1)

@onready var _inbox_view: Control = %InboxView
@onready var _thread_list: VBoxContainer = %ThreadList
@onready var _thread_view: Control = %ThreadView
@onready var _thread_header: Label = %ThreadHeaderLabel
@onready var _messages_vbox: VBoxContainer = %MessagesVBox
@onready var _messages_scroll: ScrollContainer = %MessagesScroll
@onready var _back_btn: Button = %ThreadBackBtn
@onready var _image_viewer: Control = %ImageViewer
@onready var _image_viewer_rect: TextureRect = %ImageViewerRect
@onready var _image_viewer_close_btn: Button = %ImageViewerCloseBtn

var _current_thread_index := -1


func _ready() -> void:
	_back_btn.pressed.connect(_show_inbox)
	Texting.unread_changed.connect(func(_n: int) -> void: _refresh_inbox())
	Texting.message_received.connect(_on_message_received)
	_image_viewer_close_btn.pressed.connect(_hide_image_fullscreen)
	_image_viewer.gui_input.connect(_on_image_viewer_input)
	_show_inbox()


func _on_image_viewer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hide_image_fullscreen()


func _show_image_fullscreen(tex: Texture2D) -> void:
	_image_viewer_rect.texture = tex
	_image_viewer.visible = true


func _hide_image_fullscreen() -> void:
	_image_viewer.visible = false


func _on_message_received(thread_index: int, _msg: TextingMessage) -> void:
	if _current_thread_index == thread_index:
		_populate_thread(thread_index)


func _show_inbox() -> void:
	_current_thread_index = -1
	_thread_view.visible = false
	_inbox_view.visible = true
	_refresh_inbox()


func _refresh_inbox() -> void:
	for child in _thread_list.get_children():
		child.queue_free()
	for ti in Texting.get_thread_count():
		_thread_list.add_child(_make_thread_row(ti))


func _make_thread_row(thread_index: int) -> Control:
	var thread = Texting.get_thread(thread_index)
	var delivered = Texting.get_delivered_messages(thread_index)
	var unread = Texting.get_unread_count(thread_index)

	var row := PanelContainer.new()
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style := StyleBoxFlat.new()
	style.bg_color = UNREAD_ROW_COLOR if unread > 0 else READ_ROW_COLOR
	style.set_corner_radius_all(24)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	row.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 32)

	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(150, 150)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = thread.avatar_color
	avatar_style.set_corner_radius_all(75)
	avatar.add_theme_stylebox_override("panel", avatar_style)
	var avatar_label := Label.new()
	avatar_label.text = thread.avatar_initial
	avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	avatar_label.add_theme_font_size_override("font_size", 60)
	avatar_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	avatar.add_child(avatar_label)
	hbox.add_child(avatar)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 10)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 18)
	var name_lbl := Label.new()
	name_lbl.text = thread.contact_name
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_lbl.add_theme_font_size_override("font_size", 55)
	name_row.add_child(name_lbl)
	if unread > 0:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(30, 30)
		dot.color = UNREAD_DOT_COLOR
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		name_row.add_child(dot)
	info.add_child(name_row)

	var preview_lbl := Label.new()
	preview_lbl.text = _preview_text(delivered.back() if not delivered.is_empty() else null)
	preview_lbl.add_theme_color_override("font_color", Color(0.65, 0.67, 0.78, 1))
	preview_lbl.add_theme_font_size_override("font_size", 40)
	preview_lbl.clip_text = true
	preview_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.add_child(preview_lbl)

	hbox.add_child(info)
	row.add_child(hbox)

	row.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_open_thread(thread_index)
	)
	return row


func _open_thread(thread_index: int) -> void:
	_current_thread_index = thread_index
	Texting.mark_thread_read(thread_index)
	_populate_thread(thread_index)
	_inbox_view.visible = false
	_thread_view.visible = true


func _populate_thread(thread_index: int) -> void:
	var thread = Texting.get_thread(thread_index)
	_thread_header.text = thread.contact_name
	for child in _messages_vbox.get_children():
		child.queue_free()
	for msg in Texting.get_delivered_messages(thread_index):
		_messages_vbox.add_child(_make_bubble(msg))
	await get_tree().process_frame
	_messages_scroll.scroll_vertical = int(_messages_scroll.get_v_scroll_bar().max_value)


func _make_bubble(msg: TextingMessage) -> Control:
	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = BUBBLE_COLOR
	style.set_corner_radius_all(30)
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 26
	style.content_margin_bottom = 26
	bubble.add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)

	if msg.image:
		var img_rect := TextureRect.new()
		img_rect.texture = msg.image
		img_rect.custom_minimum_size = Vector2(0, 340)
		img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		img_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		img_rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		img_rect.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_show_image_fullscreen(msg.image)
		)
		content.add_child(img_rect)

	if msg.body != "":
		var lbl := Label.new()
		lbl.text = msg.body
		lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98, 1))
		lbl.add_theme_font_size_override("font_size", 48)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(lbl)

	bubble.add_child(content)
	return bubble


func _preview_text(msg: TextingMessage) -> String:
	if not msg:
		return "No messages yet"
	if msg.body != "":
		return msg.body
	if msg.image:
		return "📷 Photo"
	return ""
