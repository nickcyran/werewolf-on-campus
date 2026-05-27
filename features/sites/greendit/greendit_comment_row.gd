class_name GreenditCommentRow
extends HBoxContainer

@onready var _indent_spacer: Control = %IndentSpacer
@onready var _indent_bar: ColorRect = %IndentBar
@onready var _gap_indent: Control = %GapIndent


func apply_comment(data: Dictionary, depth: int) -> void:
	%Author.text = str(data.get("author", "u/anonymous"))
	%TimeLabel.text = str(data.get("time", ""))
	%Body.text = str(data.get("body", ""))
	%Score.text = "▲ %d" % int(data.get("score", 0))

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
