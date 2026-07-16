extends Site

@export var professor_page: PackedScene

@onready var _about_btn: Button = $ScrollContainer/Content/Header/HeaderMargin/HeaderRow/NavLinks/AboutBtn


func _ready() -> void:
	if professor_page:
		_about_btn.pressed.connect(_open_professor_page)


func _open_professor_page() -> void:
	if professor_page:
		request_navigation(professor_page)
