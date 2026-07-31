@tool
class_name DynamicDateRichTextLabel extends RichTextLabel
## RichTextLabel with [code]{date}[/code] tokens, for article bodies and comment threads
## that mention dates inline. Token syntax is documented in [GameDate].

## Body text, BBCode included. Every [code]{date}[/code] token is replaced.
@export_multiline var template: String = "{date}":
	set(value):
		template = value
		_refresh()

## Format for tokens without their own pattern, e.g. [code]"MMM D"[/code].
@export var pattern: String = GameDate.DEFAULT_PATTERN:
	set(value):
		pattern = value
		_refresh()

@export_group("Offset From Today")
## Days added to today for tokens without their own offset. Negative is the past.
@export var offset_days: int = 0:
	set(value):
		offset_days = value
		_refresh()

## Months added to today. Negative is the past.
@export var offset_months: int = 0:
	set(value):
		offset_months = value
		_refresh()

## Years added to today. Negative is the past.
@export var offset_years: int = 0:
	set(value):
		offset_years = value
		_refresh()


func _ready() -> void:
	refresh()


## Rebuilds the text. Call this if the offsets change at runtime, or after midnight.
func refresh() -> void:
	text = GameDate.substitute(template, offset_days, offset_months, offset_years, pattern)


func _refresh() -> void:
	if is_inside_tree():
		refresh()
