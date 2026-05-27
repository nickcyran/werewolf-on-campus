extends Site

const CommentRowScene := preload("res://features/sites/greendit/greendit_comment_row.tscn")
const ThreadDividerScene := preload("res://features/sites/greendit/greendit_thread_divider.tscn")

@export var comments: Array[Dictionary] = []

@onready var _comment_list: VBoxContainer = $ScrollContainer/Content/BodySection/Feed/PostColumn/CommentSection


func _ready() -> void:
	if comments.is_empty():
		comments = GreenditDemoThreads.threads()

	for comment in comments:
		_add_comment(comment, _comment_list)


func _add_comment(data: Dictionary, parent: VBoxContainer, depth: int = 0) -> void:
	var row: GreenditCommentRow = CommentRowScene.instantiate() as GreenditCommentRow
	parent.add_child(row)
	row.apply_comment(data, depth)

	if depth == 0:
		parent.add_child(ThreadDividerScene.instantiate())

	for reply in data.get("replies", []):
		_add_comment(reply, parent, depth + 1)
