class_name GameDate
## Formats the player's real system date, optionally offset into the past or future,
## so in-game pages, ads and images always look "current".
##
## [b]Template tokens[/b] — used by [method substitute] and by [DynamicDateLabel]:
## [codeblock]
## {date}                  today, using the caller's default offset + pattern
## {date:MMM D, YYYY}      today, with an explicit pattern
## {date+30d}              30 days from now
## {date-2y+3m:MMMM YYYY}  2 years and 3 months back, explicit pattern
## [/codeblock]
## Offsets in a token replace the caller's defaults; [code]d[/code]/[code]m[/code]/[code]y[/code]
## mean days/months/years and may be combined in any order.
##
## [b]Pattern tokens[/b] — used by [method format]:
## [codeblock]
## YYYY 2026     YY 26
## MMMM July     MMM Jul    MM 07    M 7
## DD 09         D 9        Do 9th
## dddd Thursday ddd Thu
## HH 14         H 14       hh 02    h 2
## mm 05         ss 09      A PM     a pm
## [text]        copied verbatim
## [/codeblock]

const DEFAULT_PATTERN := "MMMM D, YYYY"

const WEEKDAYS: PackedStringArray = [
	"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
]
const MONTHS: PackedStringArray = [
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December",
]

const _SECONDS_PER_DAY := 86400
const _TOKEN_PATTERN := "\\{date([^:}]*)(?::([^}]*))?\\}"
const _OFFSET_PATTERN := "([+\\-])\\s*(\\d+)\\s*([dmy])"

static var _token_re: RegEx
static var _offset_re: RegEx


## System date shifted by the given offsets, as a [Time] datetime dictionary.
## Negative offsets point into the past. Day-of-month is clamped when the target
## month is shorter (Jan 31 + 1 month is Feb 28/29).
static func resolve(offset_days: int = 0, offset_months: int = 0, offset_years: int = 0) -> Dictionary:
	var now: Dictionary = Time.get_datetime_dict_from_system(false)

	# Shift whole months on the calendar first so month lengths stay meaningful.
	var months_total: int = int(now["year"]) * 12 + int(now["month"]) - 1 \
		+ offset_years * 12 + offset_months
	@warning_ignore("integer_division")
	var year: int = months_total / 12
	var month: int = months_total % 12 + 1
	var shifted := {
		"year": year,
		"month": month,
		"day": mini(int(now["day"]), days_in_month(year, month)),
		"hour": int(now["hour"]),
		"minute": int(now["minute"]),
		"second": int(now["second"]),
	}

	# Day offsets go through unix time so the weekday comes back correct.
	var unix: int = int(Time.get_unix_time_from_datetime_dict(shifted)) \
		+ offset_days * _SECONDS_PER_DAY
	return Time.get_datetime_dict_from_unix_time(unix)


## Shorthand for [code]format(resolve(...), pattern)[/code].
static func text(pattern: String = DEFAULT_PATTERN, offset_days: int = 0,
		offset_months: int = 0, offset_years: int = 0) -> String:
	return format(resolve(offset_days, offset_months, offset_years), pattern)


## Renders a datetime dictionary using the pattern tokens listed above.
static func format(datetime: Dictionary, pattern: String = DEFAULT_PATTERN) -> String:
	var out := ""
	var i := 0
	var length := pattern.length()
	while i < length:
		var c := pattern[i]

		if c == "[":
			var close := pattern.find("]", i + 1)
			if close == -1:
				out += pattern.substr(i + 1)
				break
			out += pattern.substr(i + 1, close - i - 1)
			i = close + 1
			continue

		var run := 1
		while i + run < length && pattern[i + run] == c:
			run += 1
		var token := c.repeat(run)

		# "Do" is the only two-letter-kind token, so it needs a peek.
		if token == "D" && i + 1 < length && pattern[i + 1] == "o":
			out += _ordinal(int(datetime.get("day", 1)))
			i += 2
			continue

		var replacement := _token_text(datetime, token)
		out += token if replacement.is_empty() else replacement
		i += run
	return out


## Replaces every [code]{date}[/code] token in [param template]. Tokens without their own
## offset or pattern fall back to the arguments passed here.
static func substitute(template: String, offset_days: int = 0, offset_months: int = 0,
		offset_years: int = 0, pattern: String = DEFAULT_PATTERN) -> String:
	if !template.contains("{date"):
		return template

	_ensure_regex()
	var out := template
	var matches := _token_re.search_all(template)
	# Walk backwards so each match's indices into `template` stay valid.
	for index in range(matches.size() - 1, -1, -1):
		var m := matches[index]
		var days := offset_days
		var months := offset_months
		var years := offset_years

		var spec := m.get_string(1).strip_edges()
		if !spec.is_empty():
			days = 0
			months = 0
			years = 0
			for om in _offset_re.search_all(spec):
				var amount := int(om.get_string(2))
				if om.get_string(1) == "-":
					amount = -amount
				match om.get_string(3):
					"d": days += amount
					"m": months += amount
					"y": years += amount

		var token_pattern := m.get_string(2)
		if token_pattern.is_empty():
			token_pattern = pattern

		var rendered := format(resolve(days, months, years), token_pattern)
		out = out.substr(0, m.get_start()) + rendered + out.substr(m.get_end())
	return out


static func days_in_month(year: int, month: int) -> int:
	match month:
		2: return 29 if is_leap_year(year) else 28
		4, 6, 9, 11: return 30
	return 31


static func is_leap_year(year: int) -> bool:
	return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0


static func _token_text(datetime: Dictionary, token: String) -> String:
	var hour24 := int(datetime.get("hour", 0))
	var weekday := int(datetime.get("weekday", 0)) % WEEKDAYS.size()
	var month := clampi(int(datetime.get("month", 1)), 1, MONTHS.size())

	match token:
		"YYYY": return "%04d" % int(datetime.get("year", 0))
		"YY": return "%02d" % (int(datetime.get("year", 0)) % 100)
		"MMMM": return MONTHS[month - 1]
		"MMM": return MONTHS[month - 1].substr(0, 3)
		"MM": return "%02d" % month
		"M": return str(month)
		"DD": return "%02d" % int(datetime.get("day", 1))
		"D": return str(int(datetime.get("day", 1)))
		"dddd": return WEEKDAYS[weekday]
		"ddd": return WEEKDAYS[weekday].substr(0, 3)
		"HH": return "%02d" % hour24
		"H": return str(hour24)
		"hh": return "%02d" % _to_hour12(hour24)
		"h": return str(_to_hour12(hour24))
		"mm": return "%02d" % int(datetime.get("minute", 0))
		"ss": return "%02d" % int(datetime.get("second", 0))
		"A": return "AM" if hour24 < 12 else "PM"
		"a": return "am" if hour24 < 12 else "pm"
	return ""


static func _to_hour12(hour24: int) -> int:
	var hour12 := hour24 % 12
	return 12 if hour12 == 0 else hour12


static func _ordinal(day: int) -> String:
	var suffix := "th"
	if day % 100 < 11 || day % 100 > 13:
		match day % 10:
			1: suffix = "st"
			2: suffix = "nd"
			3: suffix = "rd"
	return "%d%s" % [day, suffix]


static func _ensure_regex() -> void:
	if _token_re == null:
		_token_re = RegEx.create_from_string(_TOKEN_PATTERN)
	if _offset_re == null:
		_offset_re = RegEx.create_from_string(_OFFSET_PATTERN)
