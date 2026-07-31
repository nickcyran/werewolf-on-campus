class_name EmailEntry extends Button

signal email_selected(entry: EmailEntry)

@onready var _sender_label: Label = %SenderLabel
@onready var _subject_label: Label = %SubjectLabel
@onready var _snippet_label: Label = %SnippetLabel

var _data: EmailData


func _ready() -> void:
	pressed.connect(_on_pressed)


func setup(data: EmailData) -> void:
	_data = data
	_sender_label.text = data.sender
	_subject_label.text = data.subject
	var snippet_text: String = data.body.substr(0, 80).replace("\n", " ")
	if data.body.length() > 80:
		snippet_text += "…"
	_snippet_label.text = snippet_text


func set_selected(value: bool) -> void:
	theme_type_variation = &"EmailEntrySelected" if value else &"EmailEntry"


func get_email_data() -> EmailData:
	return _data


func _on_pressed() -> void:
	if _data:
		email_selected.emit(self)
