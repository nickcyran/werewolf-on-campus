class_name EmailData extends Resource
## Lightweight data container for a single email.
## Used as the "backend" — keeps all content out of the UI layer.

## Format used by {date} tokens in [member sent_line] that don't specify their own.
const SENT_LINE_PATTERN := "dddd, MMMM D, YYYY h:mm A"

@export var sender: String = ""
@export var subject: String = ""
@export var body: String = ""
@export_enum("inbox", "spam", "trash") var category: String = "inbox"
## Optional full-width reading layout (e.g. announcement letter). When set,
## the detail pane uses this scene instead of the default sender/subject/body stack.
@export var reading_layout: PackedScene = null
## Shown on the second line of the header as "Sent: …" when using a reading layout.
## Accepts {date} tokens, e.g. "{date-6y}" for six years ago or "{date-3d:MMM D}"
## for three days ago in a shorter format. See [GameDate] for the full syntax.
@export var sent_line: String = ""
## Shown as "To: …" when using a reading layout.
@export var to_line: String = ""


## [member sent_line] with its {date} tokens resolved against the system clock.
func get_sent_line() -> String:
	return GameDate.substitute(sent_line, 0, 0, 0, SENT_LINE_PATTERN)
