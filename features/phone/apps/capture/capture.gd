extends Control

const CaptureStoryItemScene := preload("res://features/phone/apps/capture/capture_story_item.tscn")
const VideoPlayerControlScene := preload("res://ui/components/video_player_control.tscn")

# ── Palette (only dynamic/ColorRect colors remain) ────────────────────────────
const C_RING_ACTIVE := Color(0.55, 0.75, 0.65)
const C_RING_SELF := Color(0.50, 0.50, 0.52)
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

var _video_entries: Array[VideoPlayerControl] = []

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
	for vpc in _video_entries:
		vpc.stop()


# ── Style helpers ─────────────────────────────────────────────────────────────
static func _flat(bg: Color, radius: float = 0.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	if radius > 0.0:
		s.set_corner_radius_all(roundi(radius))
	return s


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
	var item: CaptureStoryItem = CaptureStoryItemScene.instantiate()
	item.configure(STORY_USERS[i], C_RING_ACTIVE if i > 0 else C_RING_SELF, STORY_COLORS[i], i == 0)
	return item


# ── Posts ─────────────────────────────────────────────────────────────────────
func _build_posts() -> void:
	for post in posts:
		_posts_vbox.add_child(_make_post(post))


func _update_active_video() -> void:
	var feed_rect := (_posts_vbox.get_parent() as ScrollContainer).get_global_rect()
	var best: VideoPlayerControl = null
	var best_area := 0.0
	for vpc in _video_entries:
		var area := feed_rect.intersection(vpc.get_global_rect()).get_area()
		if area > best_area:
			best_area = area
			best = vpc
	for vpc in _video_entries:
		if vpc == best:
			vpc.auto_play()
		else:
			vpc.auto_pause()


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
	header.theme_type_variation = &"CapturePostHeader"

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)

	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(44, 44)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	avatar.add_theme_stylebox_override("panel", _flat(post.pfp_color, 22.0))
	if post.pfp_texture:
		var tex := TextureRect.new()
		tex.texture = post.pfp_texture
		tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.material = _pfp_mat()
		avatar.add_child(tex)
	hbox.add_child(avatar)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 2)
	var username_lbl := Label.new()
	username_lbl.text = post.username
	username_lbl.theme_type_variation = &"CapturePostUsername"
	info.add_child(username_lbl)
	hbox.add_child(info)

	var more := Button.new()
	more.custom_minimum_size = Vector2(36, 0)
	more.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	more.flat = true
	more.text = "⋮"
	more.theme_type_variation = &"CaptureMoreBtn"
	hbox.add_child(more)

	header.add_child(hbox)
	return header


func _make_post_media(post: CapturePost) -> Control:
	var media := Control.new()
	media.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	media.custom_minimum_size = Vector2(0, 860)

	if post.media_texture:
		var tex := TextureRect.new()
		tex.texture = post.media_texture
		tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		media.add_child(tex)

	elif post.video_stream:
		var vpc: VideoPlayerControl = VideoPlayerControlScene.instantiate()
		vpc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		media.add_child(vpc)
		vpc.set_stream(post.video_stream)
		_video_entries.append(vpc)

	else:
		var bg := ColorRect.new()
		bg.color = C_PLACEHOLDER
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		media.add_child(bg)

	return media


func _make_post_actions(post: CapturePost) -> Control:
	var actions := PanelContainer.new()
	actions.theme_type_variation = &"CapturePostActions"

	var avbox := VBoxContainer.new()
	avbox.add_theme_constant_override("separation", 6)
	var likes_lbl := Label.new()
	likes_lbl.text = "♥  " + str(post.likes) + " likes"
	likes_lbl.theme_type_variation = &"CapturePostLikes"
	avbox.add_child(likes_lbl)

	if post.description != "":
		var desc := RichTextLabel.new()
		desc.bbcode_enabled = true
		desc.text = "[b]" + post.username + "[/b]  " + post.description
		desc.fit_content = true
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc.theme_type_variation = &"CapturePostRTL"
		avbox.add_child(desc)

	actions.add_child(avbox)
	return actions
