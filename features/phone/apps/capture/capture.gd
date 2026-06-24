extends Control

# ── Palette ──────────────────────────────────────────────────────────────────
const C_RING_ACTIVE := Color(0.55, 0.75, 0.65)
const C_RING_SELF := Color(0.50, 0.50, 0.52)
const C_STORY_NAME := Color(0.70, 0.68, 0.66)
const C_STORY_PLUS := Color(0.75, 0.65, 0.75)
const C_POST_BG := Color(0.25, 0.23, 0.22, 1)
const C_ACTIONS_BG := Color(0.22, 0.20, 0.19, 1)
const C_TEXT_PRIMARY := Color(0.88, 0.86, 0.84, 1)
const C_TEXT_MUTED := Color(0.75, 0.73, 0.70, 1)
const C_TEXT_DIM := Color(0.60, 0.58, 0.55, 1)
const C_SEPARATOR := Color(0.18, 0.16, 0.16, 1)
const C_PLACEHOLDER := Color(0.35, 0.25, 0.23, 1)
const C_BLACK := Color(0.0, 0.0, 0.0, 1)

# ── Story data ────────────────────────────────────────────────────────────────
const STORY_USERS := ["Your Story", "wolfie", "campus", "night_owl", "chef"]
const STORY_COLORS: Array[Color] = [
	Color(0.55, 0.75, 0.65),
	Color(0.65, 0.80, 0.72),
	Color(0.50, 0.72, 0.68),
	Color(0.60, 0.78, 0.70),
	Color(0.58, 0.76, 0.66),
]

@export var posts: Array[CapturePost] = []

@onready var _stories_hbox: HBoxContainer = $VBox/Stories/StoriesScroll/StoriesHBox
@onready var _posts_vbox: VBoxContainer = $VBox/PostsFeed/PostsVBox

# { vp, media, overlay, user_paused }
var _video_entries: Array = []
# { vp, h } — corrected in _process once texture dimensions are known
var _pending_resize: Array = []

# Shared across all pfp TextureRects so the GPU compiles it once.
static var _pfp_shader: Shader


# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_stories()
	_build_posts()
	if not _video_entries.is_empty():
		var scrollbar := (_posts_vbox.get_parent() as ScrollContainer).get_v_scroll_bar()
		scrollbar.value_changed.connect(func(_v: float): _update_active_video())
		_update_active_video.call_deferred()
	DayClock.day_ended.connect(_stop_all_video)


func _stop_all_video() -> void:
	for entry in _video_entries:
		var vp := entry.vp as VideoStreamPlayer
		if vp and vp.is_playing():
			vp.stop()


func _process(_delta: float) -> void:
	if _pending_resize.is_empty():
		return
	for i in range(_pending_resize.size() - 1, -1, -1):
		var pr: Dictionary = _pending_resize[i]
		var vp: VideoStreamPlayer = pr.vp
		if not vp.is_playing() or vp.paused:
			continue
		var tex := vp.get_video_texture()
		if tex == null or tex.get_size().x <= 0:
			continue
		var sz := tex.get_size()
		var w = pr.h * sz.x / sz.y
		vp.offset_left = -w * 0.5
		vp.offset_right = w * 0.5
		_pending_resize.remove_at(i)


# ── Style helpers ─────────────────────────────────────────────────────────────
static func _flat(bg: Color, radius: float = 0.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	if radius > 0.0:
		s.set_corner_radius_all(roundi(radius))
	return s


static func _flat_padded(bg: Color, ml: float, mt: float, mr: float, mb: float,
		radius: float = 0.0) -> StyleBoxFlat:
	var s := _flat(bg, radius)
	s.content_margin_left = ml
	s.content_margin_top = mt
	s.content_margin_right = mr
	s.content_margin_bottom = mb
	return s


static func _flat_ring(border_color: Color, radius: float, margin: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.border_color = border_color
	s.set_border_width_all(2)
	s.set_corner_radius_all(roundi(radius))
	s.content_margin_left = margin
	s.content_margin_top = margin
	s.content_margin_right = margin
	s.content_margin_bottom = margin
	return s


static func _lbl(text: String, color: Color, size: int,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	l.horizontal_alignment = align
	return l


static func _pfp_mat() -> ShaderMaterial:
	if not _pfp_shader:
		_pfp_shader = Shader.new()
		_pfp_shader.code = "shader_type canvas_item;\nvoid fragment() { vec2 d = UV - vec2(0.5); if (dot(d, d) > 0.25) discard; COLOR = texture(TEXTURE, UV); }"
	var m := ShaderMaterial.new()
	m.shader = _pfp_shader
	return m


# ── Stories ───────────────────────────────────────────────────────────────────
func _build_stories() -> void:
	for i in STORY_USERS.size():
		_stories_hbox.add_child(_make_story_item(i))


func _make_story_item(i: int) -> Control:
	var story := VBoxContainer.new()
	story.custom_minimum_size = Vector2(110, 0)
	story.add_theme_constant_override("separation", 8)
	story.alignment = BoxContainer.ALIGNMENT_CENTER

	var ring := PanelContainer.new()
	ring.custom_minimum_size = Vector2(96, 96)
	ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ring.add_theme_stylebox_override("panel",
		_flat_ring(C_RING_ACTIVE if i > 0 else C_RING_SELF, 48.0, 3.0))

	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(86, 86)
	avatar.add_theme_stylebox_override("panel", _flat(STORY_COLORS[i], 43.0))
	ring.add_child(avatar)
	story.add_child(ring)

	if i == 0:
		var plus := _lbl("+", C_STORY_PLUS, 18, HORIZONTAL_ALIGNMENT_CENTER)
		plus.position = Vector2(70, 64)
		ring.add_child(plus)

	var name_lbl := _lbl(STORY_USERS[i], C_STORY_NAME, 14, HORIZONTAL_ALIGNMENT_CENTER)
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	story.add_child(name_lbl)

	return story


# ── Posts ─────────────────────────────────────────────────────────────────────
func _build_posts() -> void:
	for post in posts:
		_posts_vbox.add_child(_make_post(post))


func _update_active_video() -> void:
	var feed_rect := (_posts_vbox.get_parent() as ScrollContainer).get_global_rect()

	var best_entry: Dictionary = {}
	var best_area := 0.0
	for entry in _video_entries:
		var area := feed_rect.intersection((entry.media as Control).get_global_rect()).get_area()
		if area > best_area:
			best_area = area
			best_entry = entry

	for entry in _video_entries:
		var vp := entry.vp as VideoStreamPlayer
		var overlay := entry.overlay as Control
		if entry == best_entry and not entry.user_paused:
			if not vp.is_playing():
				vp.play()
			vp.paused = false
			overlay.visible = false
		else:
			vp.paused = true


func _make_post(post: CapturePost) -> Control:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 0)
	container.add_child(_make_post_header(post))
	container.add_child(_make_post_media(post))
	container.add_child(_make_post_actions(post))
	var gap := ColorRect.new()
	gap.custom_minimum_size = Vector2(0, 8)
	gap.color = C_SEPARATOR
	container.add_child(gap)
	return container


func _make_post_header(post: CapturePost) -> Control:
	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 64)
	header.add_theme_stylebox_override("panel", _flat_padded(C_POST_BG, 20, 12, 20, 12))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)

	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(44, 44)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	avatar.add_theme_stylebox_override("panel", _flat(post.pfp_color, 22.0))
	if post.pfp_texture:
		var tr := TextureRect.new()
		tr.texture = post.pfp_texture
		tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.material = _pfp_mat()
		avatar.add_child(tr)
	hbox.add_child(avatar)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 2)
	info.add_child(_lbl(post.username, C_TEXT_PRIMARY, 22))
	hbox.add_child(info)

	var more := Button.new()
	more.custom_minimum_size = Vector2(36, 0)
	more.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	more.flat = true
	more.text = "⋮"
	more.add_theme_font_size_override("font_size", 26)
	more.add_theme_color_override("font_color", C_TEXT_DIM)
	hbox.add_child(more)

	header.add_child(hbox)
	return header


func _make_post_media(post: CapturePost) -> Control:
	var media := Control.new()
	media.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	media.custom_minimum_size = Vector2(0, 860)

	if post.media_texture:
		var tr := TextureRect.new()
		tr.texture = post.media_texture
		tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		media.add_child(tr)

	elif post.video_stream:
		var black_bg := ColorRect.new()
		black_bg.color = C_BLACK
		black_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		black_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		media.add_child(black_bg)

		var vp := VideoStreamPlayer.new()
		vp.stream = post.video_stream
		vp.anchor_left = 0.5; vp.anchor_right = 0.5
		vp.anchor_top = 0.0; vp.anchor_bottom = 1.0
		vp.offset_left = -421.0; vp.offset_right = 421.0
		vp.offset_top = 0.0; vp.offset_bottom = 0.0
		vp.expand = true
		vp.autoplay = false
		vp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		media.add_child(vp)
		_pending_resize.append({vp = vp, h = 860.0})

		var overlay := CenterContainer.new()
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.visible = false
		var play_icon := _lbl("▶", Color(1, 1, 1, 0.88), 80)
		play_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(play_icon)
		media.add_child(overlay)

		var entry := {vp = vp, media = media, overlay = overlay, user_paused = false}
		_video_entries.append(entry)

		if post.video_loop:
			vp.finished.connect(func(): vp.play())

		media.mouse_filter = Control.MOUSE_FILTER_STOP
		media.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton \
					and event.button_index == MOUSE_BUTTON_LEFT \
					and event.pressed:
				entry.user_paused = not entry.user_paused
				vp.paused = entry.user_paused
				overlay.visible = entry.user_paused
		)

	else:
		var bg := ColorRect.new()
		bg.color = C_PLACEHOLDER
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		media.add_child(bg)

	return media


func _make_post_actions(post: CapturePost) -> Control:
	var actions := PanelContainer.new()
	actions.add_theme_stylebox_override("panel", _flat_padded(C_ACTIONS_BG, 20, 12, 20, 14))

	var avbox := VBoxContainer.new()
	avbox.add_theme_constant_override("separation", 6)
	avbox.add_child(_lbl("♥  " + str(post.likes) + " likes", C_TEXT_PRIMARY, 26))

	if post.description != "":
		var desc := RichTextLabel.new()
		desc.bbcode_enabled = true
		desc.text = "[b]" + post.username + "[/b]  " + post.description
		desc.fit_content = true
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc.add_theme_color_override("default_color", C_TEXT_MUTED)
		desc.add_theme_font_size_override("normal_font_size", 22)
		desc.add_theme_font_size_override("bold_font_size", 22)
		avbox.add_child(desc)

	actions.add_child(avbox)
	return actions
