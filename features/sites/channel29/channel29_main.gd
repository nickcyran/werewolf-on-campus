extends Site

@export var about_page_scene: PackedScene
@export var professor_bio_scene: PackedScene

@onready var _byline: RichTextLabel = $Content/BodySection/ArticleMargin/ArticleVBox/Byline
@onready var _body2: RichTextLabel = $Content/BodySection/ArticleMargin/ArticleVBox/Body2


func _ready() -> void:
	_byline.meta_clicked.connect(_on_meta_clicked)
	_body2.meta_clicked.connect(_on_meta_clicked)


## Links in the article body and byline route by their [code][url=…][/code] tag.
func _on_meta_clicked(meta: Variant) -> void:
	var scene: PackedScene = _scene_for(str(meta))
	if !scene:
		return
	request_navigation(scene)


func _scene_for(meta: String) -> PackedScene:
	match meta:
		"about":
			return about_page_scene
		"professor":
			return professor_bio_scene
	return null
