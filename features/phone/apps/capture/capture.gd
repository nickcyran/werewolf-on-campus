extends Control

const STORY_USERS := ["Your Story", "wolfie", "campus", "night_owl", "chef"]
const STORY_COLORS: Array[Color] = [
	Color(0.55, 0.75, 0.65),
	Color(0.65, 0.8, 0.72),
	Color(0.5, 0.72, 0.68),
	Color(0.6, 0.78, 0.7),
	Color(0.58, 0.76, 0.66),
]

@onready var _stories_hbox: HBoxContainer = $VBox/Stories/StoriesScroll/StoriesHBox


func _ready() -> void:
	_build_stories()


func _build_stories() -> void:
	for i in range(STORY_USERS.size()):
		var story := VBoxContainer.new()
		story.custom_minimum_size = Vector2(90, 0)
		story.add_theme_constant_override("separation", 6)
		story.alignment = BoxContainer.ALIGNMENT_CENTER

		var ring := PanelContainer.new()
		ring.custom_minimum_size = Vector2(72, 72)
		ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		var ring_style := StyleBoxFlat.new()
		ring_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		ring_style.border_color = Color(0.55, 0.75, 0.65) if i > 0 else Color(0.5, 0.5, 0.52)
		ring_style.set_border_width_all(2)
		ring_style.set_corner_radius_all(36)
		ring_style.content_margin_left = 3
		ring_style.content_margin_top = 3
		ring_style.content_margin_right = 3
		ring_style.content_margin_bottom = 3
		ring.add_theme_stylebox_override("panel", ring_style)

		var avatar := PanelContainer.new()
		avatar.custom_minimum_size = Vector2(62, 62)
		var avatar_style := StyleBoxFlat.new()
		avatar_style.bg_color = STORY_COLORS[i]
		avatar_style.set_corner_radius_all(31)
		avatar.add_theme_stylebox_override("panel", avatar_style)
		ring.add_child(avatar)

		story.add_child(ring)

		if i == 0:
			var plus_label := Label.new()
			plus_label.text = "+"
			plus_label.add_theme_color_override("font_color", Color(0.75, 0.65, 0.75))
			plus_label.add_theme_font_size_override("font_size", 16)
			plus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			plus_label.position = Vector2(52, 48)
			ring.add_child(plus_label)

		var name_label := Label.new()
		name_label.text = STORY_USERS[i]
		name_label.add_theme_color_override("font_color", Color(0.7, 0.68, 0.66))
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		story.add_child(name_label)

		_stories_hbox.add_child(story)
