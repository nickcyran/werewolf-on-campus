extends Site

const CommentRowScene := preload("res://features/sites/greendit/greendit_comment_row.tscn")

@export var comments: Array[GreenditComment] = []
@onready var _comment_list: VBoxContainer = $ScrollContainer/Content/BodySection/Feed/PostColumn/CommentSection


func _ready() -> void:
	for comment in comments:
		_add_comment(comment, _comment_list)


func _add_comment(data: GreenditComment, parent: VBoxContainer, depth: int = 0) -> void:
	var row: GreenditCommentRow = CommentRowScene.instantiate() as GreenditCommentRow
	parent.add_child(row)
	row.apply_comment(data, depth)
	row.link_activated.connect(_on_comment_link_activated)

	if depth == 0:
		parent.add_child(_make_thread_divider())

	for reply in data.replies:
		_add_comment(reply, parent, depth + 1)


func _on_comment_link_activated(scene_path: String) -> void:
	var scene := load(scene_path) as PackedScene
	if scene:
		request_navigation(scene)


func _make_thread_divider() -> PanelContainer:
	var divider := PanelContainer.new()
	divider.custom_minimum_size = Vector2(0, 1)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	divider.theme_type_variation = &"GreenditTopLevelDivider"
	return divider
