class_name GreenditCommentRow
extends HBoxContainer

## Emitted when a [url=...] link inside the comment body is clicked.
## scene_path is the res:// path the link points to.
signal link_activated(scene_path: String)

const LINK_COLOR := "#1d9e5f"

static var _link_regex: RegEx = _make_link_regex()

@onready var _indent_spacer: Control = %IndentSpacer
@onready var _indent_bar: ColorRect = %IndentBar
@onready var _gap_indent: Control = %GapIndent
@onready var _body: RichTextLabel = %Body


func _ready() -> void:
	_body.meta_clicked.connect(_on_body_meta_clicked)


func apply_comment(data: GreenditComment, depth: int) -> void:
	%Avatar.self_modulate = _avatar_color(data.author)
	%AvatarInitial.text = data.author.left(1).to_upper() if data.author != "" else "U"
	%Author.text = data.author if data.author else "u/anonymous"
	%TimeLabel.text = data.time
	%Body.text = _stylize_links(data.body)
	%Score.text = "▲ %d" % data.score

	if depth > 0:
		_indent_spacer.custom_minimum_size = Vector2(depth * 20, 0)
		_indent_spacer.visible = true
		_indent_bar.visible = true
		_gap_indent.visible = true
		var bar_colors: Array[Color] = [
			Color(0.3, 0.55, 0.35, 0.7),
			Color(0.35, 0.45, 0.6, 0.6),
			Color(0.5, 0.4, 0.55, 0.5),
			Color(0.45, 0.45, 0.45, 0.4),
		]
		_indent_bar.color = bar_colors[mini(depth - 1, bar_colors.size() - 1)]
	else:
		_indent_spacer.visible = false
		_indent_spacer.custom_minimum_size = Vector2.ZERO
		_indent_bar.visible = false
		_gap_indent.visible = false


## Deterministic per-user avatar tint, hashed from the username like the mockup.
static func _avatar_color(author: String) -> Color:
	var h := 0
	for i in author.length():
		h = (h * 31 + author.unicode_at(i)) % 360
	return Color.from_ok_hsl(h / 360.0, 0.62, 0.6)


func _on_body_meta_clicked(meta: Variant) -> void:
	link_activated.emit(str(meta))


## Colors [url=...]text[/url] links like a hyperlink, so u only need the [url] tag.
func _stylize_links(text: String) -> String:
	return _link_regex.sub(text, "[url=$1][color=%s]$2[/color][/url]" % LINK_COLOR, true)


static func _make_link_regex() -> RegEx:
	var regex := RegEx.new()
	regex.compile("(?s)\\[url=([^\\]]+)\\](.*?)\\[/url\\]")
	return regex
