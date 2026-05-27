class_name EmailData extends Resource
## Lightweight data container for a single email.
## Used as the "backend" — keeps all content out of the UI layer.

@export var id: int = 0
@export var sender: String = ""
@export var subject: String = ""
@export var body: String = ""
@export_enum("inbox", "spam", "trash") var category: String = "inbox"
## Optional full-width reading layout (e.g. announcement letter). When set,
## the detail pane uses this scene instead of the default sender/subject/body stack.
@export var reading_layout: PackedScene = null
## Shown on the second line of the header as "Sent: …" when using a reading layout.
@export var sent_line: String = ""
## Shown as "To: …" when using a reading layout.
@export var to_line: String = ""
