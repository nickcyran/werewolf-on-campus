extends Site

@export var about_page_scene: PackedScene

@onready var _author_btn: Button = $ScrollContainer/Content/BodySection/ArticleMargin/ArticleVBox/AuthorBtn


func _ready() -> void:
	_author_btn.pressed.connect(_open_about_page)


func _open_about_page() -> void:
	if !about_page_scene:
		return
	request_navigation(about_page_scene)
