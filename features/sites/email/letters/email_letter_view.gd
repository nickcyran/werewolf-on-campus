class_name EmailLetterView extends Control
## A single email's reading layout on its own, without the CloudMail client around it.
## Used where one letter stands in as a source, such as the sniff test.

@export var email: EmailData

@onready var _letter: EmailReadingLayout = %Letter


func _ready() -> void:
	_letter.apply_data(email)
