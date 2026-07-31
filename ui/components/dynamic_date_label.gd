@tool
class_name DynamicDateLabel extends Label
## Label whose text is rebuilt from the player's system date every time the scene loads.
## Drop it into a page, or on top of a TextureRect to stamp a date onto artwork.
## Token syntax is documented in [GameDate].

## Text to show. Every [code]{date}[/code] token is replaced; anything else is literal.
@export_multiline var template: String = "{date}":
	set(value):
		template = value
		_refresh()

## Format for tokens without their own pattern, e.g. [code]"M/D/YY"[/code].
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
