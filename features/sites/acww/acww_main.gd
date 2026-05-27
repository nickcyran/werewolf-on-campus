extends Site

@export var about_page_scene: PackedScene

@onready var _about_button: Button = $ScrollContainer/Content/NavBar/NavLinks/AboutBtn


func _ready() -> void:
	_about_button.pressed.connect(_open_about_page)


func _open_about_page() -> void:
	if !about_page_scene:
		return
	request_navigation(about_page_scene)
