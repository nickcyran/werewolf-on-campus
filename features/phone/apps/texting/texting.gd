extends Control

const TEXT_COLOR := Color(0.957, 0.965, 0.992, 1)
const SECONDARY_COLOR := Color(0.886, 0.906, 0.969, 0.6)
const PLACEHOLDER_COLOR := Color(0.886, 0.906, 0.969, 0.45)
const SEPARATOR_COLOR := Color(1, 1, 1, 0.06)
const BUBBLE_COLOR := Color(0.11, 0.125, 0.204, 1)
const ACCENT_COLOR := Color(0.357, 0.549, 0.941, 1)

const AVATAR_SIZE := 91
## Fixed gutter the unread dot sits in, so every row's avatar lines up.
const UNREAD_SLOT_WIDTH := 21
const BUBBLE_RADIUS := 38
const BUBBLE_TEXT_WRAP_WIDTH := 600
const BUBBLE_WRAP_THRESHOLD := 40
const IMAGE_WIDTH := 407.0

## Stands in for a photo-only message in the inbox preview line.
@export var photo_icon: Texture2D

@onready var _inbox_view: Control = %InboxView
@onready var _thread_list: VBoxContainer = %ThreadList
@onready var _thread_view: Control = %ThreadView
@onready var _thread_header: Label = %ThreadHeaderLabel
@onready var _thread_avatar: PanelContainer = %ThreadAvatar
@onready var _thread_avatar_initial: Label = %ThreadAvatarInitial
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
	if event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
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

	var row := VBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.add_theme_constant_override("separation", 0)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_top", 24)
	pad.add_theme_constant_override("margin_bottom", 24)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)

	var unread_slot := CenterContainer.new()
	unread_slot.custom_minimum_size = Vector2(UNREAD_SLOT_WIDTH, 0)
	if unread > 0:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(14, 14)
		var dot_style := StyleBoxFlat.new()
		dot_style.bg_color = ACCENT_COLOR
		dot_style.set_corner_radius_all(7)
		dot.add_theme_stylebox_override("panel", dot_style)
		unread_slot.add_child(dot)
	hbox.add_child(unread_slot)

	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(AVATAR_SIZE, AVATAR_SIZE)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = thread.avatar_color
	avatar_style.set_corner_radius_all(AVATAR_SIZE / 2)
	avatar.add_theme_stylebox_override("panel", avatar_style)
	var avatar_label := Label.new()
	avatar_label.text = thread.avatar_initial
	avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_label.add_theme_color_override("font_color", Color(0.051, 0.063, 0.125, 1))
	avatar_label.add_theme_font_size_override("font_size", 35)
	avatar.add_child(avatar_label)
	hbox.add_child(avatar)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 4)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 18)
	var name_lbl := Label.new()
	name_lbl.text = thread.contact_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_color_override("font_color", TEXT_COLOR)
	name_lbl.add_theme_font_size_override("font_size", 28)
	name_row.add_child(name_lbl)
	if !delivered.is_empty():
		var time_lbl := Label.new()
		time_lbl.text = DayClock.progress_to_display_time(delivered.back().trigger_progress)
		time_lbl.add_theme_color_override("font_color", SECONDARY_COLOR)
		time_lbl.add_theme_font_size_override("font_size", 22)
		name_row.add_child(time_lbl)
	info.add_child(name_row)

	var last_msg: TextingMessage = delivered.back() if !delivered.is_empty() else null

	var preview_row := HBoxContainer.new()
	preview_row.add_theme_constant_override("separation", 8)
	if last_msg && last_msg.body == "" && last_msg.image:
		var photo_mark := TextureRect.new()
		photo_mark.texture = photo_icon
		photo_mark.custom_minimum_size = Vector2(25, 25)
		photo_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		photo_mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		photo_mark.self_modulate = SECONDARY_COLOR
		preview_row.add_child(photo_mark)

	var preview_lbl := Label.new()
	preview_lbl.text = _preview_text(last_msg)
	preview_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_lbl.add_theme_color_override(
		"font_color", SECONDARY_COLOR if !delivered.is_empty() else PLACEHOLDER_COLOR
	)
	preview_lbl.add_theme_font_size_override("font_size", 25)
	preview_lbl.clip_text = true
	preview_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	preview_row.add_child(preview_lbl)
	info.add_child(preview_row)

	hbox.add_child(info)

	pad.add_child(hbox)
	row.add_child(pad)

	var separator := ColorRect.new()
	separator.custom_minimum_size = Vector2(0, 1)
	separator.color = SEPARATOR_COLOR
	row.add_child(separator)

	row.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
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
	_thread_avatar.self_modulate = thread.avatar_color
	_thread_avatar_initial.text = thread.avatar_initial

	for child in _messages_vbox.get_children():
		child.queue_free()

	var delivered := Texting.get_delivered_messages(thread_index)
	if !delivered.is_empty():
		_messages_vbox.add_child(_make_date_caption(delivered[0]))
	for msg in delivered:
		_messages_vbox.add_child(_make_bubble(msg))
	await get_tree().process_frame
	_messages_scroll.scroll_vertical = int(_messages_scroll.get_v_scroll_bar().max_value)


func _make_date_caption(msg: TextingMessage) -> Control:
	var caption := Label.new()
	caption.text = "Today " + DayClock.progress_to_display_time(msg.trigger_progress)
	caption.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caption.add_theme_color_override("font_color", SECONDARY_COLOR)
	caption.add_theme_font_size_override("font_size", 24)
	return caption


func _make_bubble(msg: TextingMessage) -> Control:
	if msg.source_id != "":
		GameManager.mark_source_visited(msg.source_id)

	var group := VBoxContainer.new()
	group.add_theme_constant_override("separation", 12)

	if msg.image:
		var frame := PanelContainer.new()
		frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		frame.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = Color(1, 1, 1, 1)
		frame_style.set_corner_radius_all(BUBBLE_RADIUS)
		frame.add_theme_stylebox_override("panel", frame_style)

		var tex_size := msg.image.get_size()
		var img_rect := TextureRect.new()
		img_rect.texture = msg.image
		img_rect.custom_minimum_size = Vector2(IMAGE_WIDTH, IMAGE_WIDTH * tex_size.y / tex_size.x)
		img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		img_rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		img_rect.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
				_show_image_fullscreen(msg.image)
		)
		frame.add_child(img_rect)
		group.add_child(frame)

	if msg.body != "":
		var bubble := PanelContainer.new()
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var style := StyleBoxFlat.new()
		style.bg_color = BUBBLE_COLOR
		style.set_corner_radius_all(BUBBLE_RADIUS)
		style.content_margin_left = 30
		style.content_margin_right = 30
		style.content_margin_top = 20
		style.content_margin_bottom = 20
		bubble.add_theme_stylebox_override("panel", style)

		var lbl := Label.new()
		lbl.text = msg.body
		lbl.add_theme_color_override("font_color", TEXT_COLOR)
		lbl.add_theme_font_size_override("font_size", 34)
		if msg.body.length() > BUBBLE_WRAP_THRESHOLD:
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl.custom_minimum_size = Vector2(BUBBLE_TEXT_WRAP_WIDTH, 0)
		bubble.add_child(lbl)
		group.add_child(bubble)

	return group


func _preview_text(msg: TextingMessage) -> String:
	if !msg:
		return "No messages yet"
	if msg.body != "":
		return msg.body
	if msg.image:
		return "Photo"
	return ""
