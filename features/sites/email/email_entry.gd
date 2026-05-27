class_name EmailEntry extends Button

const EmailDataRes := preload("res://features/sites/email/email_data.gd")

signal email_selected(data: EmailDataRes)

@onready var _sender_label: Label = %SenderLabel
@onready var _subject_label: Label = %SubjectLabel
@onready var _snippet_label: Label = %SnippetLabel

var _data: EmailDataRes
var _is_selected: bool = false


func _ready() -> void:
	text = ""
	clip_text = true
	flat = false
	toggle_mode = false
	theme_type_variation = &"EmailEntry"
	pressed.connect(_on_pressed)


func setup(data: EmailDataRes) -> void:
	_data = data
	_sender_label.text = data.sender
	_subject_label.text = data.subject
	var snippet_text: String = data.body.substr(0, 80).replace("\n", " ")
	if data.body.length() > 80:
		snippet_text += "…"
	_snippet_label.text = snippet_text
	_apply_theme_type()


func set_selected(value: bool) -> void:
	_is_selected = value
	_apply_theme_type()


func get_email_data() -> EmailDataRes:
	return _data


func _apply_theme_type() -> void:
	if !_data:
		return
	theme_type_variation = &"EmailEntrySelected" if _is_selected else &"EmailEntry"


func _on_pressed() -> void:
	if _data:
		email_selected.emit(_data)
