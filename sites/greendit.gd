extends Site

# Greendit – a Reddit-style single post page with a comment thread.

@export var comments: Array[Dictionary] = []

@onready var _comment_list: VBoxContainer = $ScrollContainer/Content/BodySection/Feed/PostColumn/CommentSection


func _ready() -> void:
	if comments.is_empty():
		_add_default_comments()

	for comment in comments:
		_add_comment(comment, _comment_list)


# ---- default data -----------------------------------------------------------

func _add_default_comments() -> void:
	comments = [
		{
			"author": "u/testuser02",
			"time": "2h",
			"score": 55,
			"body": "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident.",
			"replies": [
				{
					"author": "u/testuser03",
					"time": "1h",
					"score": 21,
					"body": "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.",
				},
				{
					"author": "u/testuser02",
					"time": "1h",
					"score": 14,
					"body": "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.",
				},
			],
		},
		{
			"author": "u/testuser04",
			"time": "1h",
			"score": 38,
			"body": "Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.",
		},
		{
			"author": "u/testuser05",
			"time": "50m",
			"score": 27,
			"body": "Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit.",
			"replies": [
				{
					"author": "u/testuser01",
					"time": "30m",
					"score": 9,
					"body": "Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur.",
				},
			],
		},
		{
			"author": "u/testuser06",
			"time": "25m",
			"score": 12,
			"body": "At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti.",
		},
		{
			"author": "u/testuser07",
			"time": "10m",
			"score": 3,
			"body": "TEST TEST - Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus lacinia odio vitae vestibulum vestibulum.",
		},
	]


# ---- build UI ---------------------------------------------------------------

func _add_comment(data: Dictionary, parent: VBoxContainer, depth: int = 0) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	parent.add_child(row)

	# indent bar for nested replies
	if depth > 0:
		var indent := ColorRect.new()
		indent.custom_minimum_size = Vector2(2, 0)
		indent.size_flags_vertical = Control.SIZE_EXPAND_FILL
		indent.color = Color(0.3, 0.45, 0.32, 0.6)
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(depth * 18, 0)
		row.add_child(spacer)
		row.add_child(indent)
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(8, 0)
		row.add_child(gap)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)

	# author + time + score
	var meta := Label.new()
	meta.text = "%s  %s  %s pts" % [
		data.get("author", "u/anonymous"),
		data.get("time", ""),
		str(data.get("score", 0)),
	]
	meta.add_theme_font_size_override("font_size", 10)
	meta.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	col.add_child(meta)

	# comment body
	var body := Label.new()
	body.text = data.get("body", "")
	body.add_theme_font_size_override("font_size", 12)
	body.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78, 1))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(body)

	# bottom spacer
	var spacer_bottom := Control.new()
	spacer_bottom.custom_minimum_size = Vector2(0, 4)
	col.add_child(spacer_bottom)

	# recurse into replies
	var replies = data.get("replies", [])
	for reply in replies:
		_add_comment(reply, parent, depth + 1)
