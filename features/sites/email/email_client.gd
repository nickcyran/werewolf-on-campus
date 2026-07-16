extends Site

const EmailDataRes := preload("res://features/sites/email/email_data.gd")
const EmailEntryClass := preload("res://features/sites/email/email_entry.gd")
const EmailEntryScene := preload("res://features/sites/email/EmailEntry.tscn")
const PresidentLetterScene := preload("res://features/sites/email/letters/president_announcement_email.tscn")

@onready var _list_header: Label = %ListHeader
@onready var _list_vbox: VBoxContainer = %ListVBox
@onready var _detail_sender: Label = %DetailSender
@onready var _detail_subject: Label = %DetailSubject
@onready var _detail_body: RichTextLabel = %DetailBody
@onready var _detail_placeholder: Label = %DetailPlaceholder
@onready var _detail_custom_host: MarginContainer = %DetailCustomHost
@onready var _detail_rule: PanelContainer = %DetailRule

@export var emails: Array[EmailData] = []

var _emails: Array[EmailData] = []
var _current_category: String = "inbox"
var _selected_entry: EmailEntryClass = null
var _category_buttons: Dictionary = {}


func _ready() -> void:
	site_title = "CloudMail"
	_category_buttons = {
		"inbox": %BtnInbox,
		"spam": %BtnSpam,
		"trash": %BtnTrash,
	}
	for cat: String in _category_buttons:
		(_category_buttons[cat] as Button).pressed.connect(_on_sidebar_pressed.bind(cat))

	_emails = emails if not emails.is_empty() else _make_sample_data()
	_select_category("inbox")


func _make_sample_data() -> Array[EmailData]:
	var president := _make_email(
		2,
		"dbenso@tri-fang.edu",
		"Breaking News: Campus Werewolf Apprehended",
		"Dear campus community,\n\nThe campus werewolf has been identified and taken into custody, says university president Dr. Derek Hale. There is no need for students to worry. All is safe, and classes will resume as normal. Thank you for your cooperation during this time!",
		"inbox",
	)
	president.sent_line = _sent_line_six_years_ago()
	president.to_line = "ALLSTUDENTS@LISTSERV.TRI-FANG.EDU"
	president.reading_layout = PresidentLetterScene

	return [
		_make_email(1, "test@cloudmail.edu", "Test Subject",
			"This is a test email body.\n\nIt contains some placeholder text for development purposes.",
			"inbox"),
		president,
	]


func _sent_line_six_years_ago() -> String:
	## Same clock/calendar moment as the player’s machine, minus six years (English, 12h).
	const WEEKDAYS: PackedStringArray = [
		"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
	]
	const MONTHS: PackedStringArray = [
		"January", "February", "March", "April", "May", "June", "July", "August",
		"September", "October", "November", "December",
	]
	var now: Dictionary = Time.get_datetime_dict_from_system(false)
	var y: int = int(now["year"]) - 6
	var mo: int = int(now["month"])
	var day: int = int(now["day"])
	if mo == 2 and day == 29:
		var leap: bool = (y % 4 == 0 and y % 100 != 0) or (y % 400 == 0)
		if not leap:
			day = 28
	var past_local := {
		"year": y,
		"month": mo,
		"day": day,
		"hour": int(now["hour"]),
		"minute": int(now["minute"]),
		"second": int(now.get("second", 0)),
	}
	var unix_ts: float = Time.get_unix_time_from_datetime_dict(past_local)
	if unix_ts < 0.0:
		return "Wednesday, April 15, 2020 9:42 AM"
	var past: Dictionary = Time.get_datetime_dict_from_unix_time(int(unix_ts))
	var wd: int = int(past["weekday"])
	var hour24: int = int(past["hour"])
	var am_pm: String
	var hour12: int
	if hour24 == 0:
		hour12 = 12
		am_pm = "AM"
	elif hour24 < 12:
		hour12 = hour24
		am_pm = "AM"
	elif hour24 == 12:
		hour12 = 12
		am_pm = "PM"
	else:
		hour12 = hour24 - 12
		am_pm = "PM"
	var min_str: String = "%02d" % int(past["minute"])
	return "%s, %s %d, %d %d:%s %s" % [
		WEEKDAYS[wd],
		MONTHS[int(past["month"]) - 1],
		int(past["day"]),
		int(past["year"]),
		hour12,
		min_str,
		am_pm,
	]


func _make_email(id: int, sender: String, subject: String, body: String,
		category: String) -> EmailDataRes:
	var d: EmailDataRes = EmailDataRes.new()
	d.id = id
	d.sender = sender
	d.subject = subject
	d.body = body
	d.category = category
	return d


func _get_emails_in_category(category: String) -> Array:
	var result: Array = []
	for email in _emails:
		if email.category == category:
			result.append(email)
	return result


func _select_category(category: String) -> void:
	_current_category = category
	_selected_entry = null

	for cat_key: String in _category_buttons:
		_apply_sidebar_active(_category_buttons[cat_key], cat_key == category)

	_list_header.text = "   %s" % category.to_upper()

	for child in _list_vbox.get_children():
		_list_vbox.remove_child(child)
		child.queue_free()

	for email_data in _get_emails_in_category(category):
		var entry: EmailEntryClass = EmailEntryScene.instantiate() as EmailEntryClass
		_list_vbox.add_child(entry)
		entry.setup(email_data)
		entry.email_selected.connect(_on_email_selected)

	_show_detail(false)


func _apply_sidebar_active(btn: Button, active: bool) -> void:
	btn.theme_type_variation = &"SidebarButtonActive" if active else &"SidebarButton"


func _on_sidebar_pressed(category: String) -> void:
	if category != _current_category:
		_select_category(category)


func _on_email_selected(data: EmailDataRes) -> void:
	if _selected_entry:
		_selected_entry.set_selected(false)

	for child in _list_vbox.get_children():
		if child is EmailEntryClass and child.get_email_data() == data:
			_selected_entry = child
			_selected_entry.set_selected(true)
			break

	_clear_detail_custom()

	if data.reading_layout:
		var reader: Node = data.reading_layout.instantiate()
		_detail_custom_host.add_child(reader)
		if reader.has_method("apply_data"):
			reader.call("apply_data", data)
	else:
		_detail_sender.text = data.sender
		_detail_subject.text = data.subject
		_detail_body.text = data.body

	_show_detail(true)


func _show_detail(visible_flag: bool) -> void:
	if !visible_flag:
		_clear_detail_custom()

	var has_custom := visible_flag and _detail_custom_host.get_child_count() > 0
	_detail_custom_host.visible = has_custom
	_detail_sender.visible = visible_flag and not has_custom
	_detail_subject.visible = visible_flag and not has_custom
	_detail_body.visible = visible_flag and not has_custom
	_detail_rule.visible = visible_flag and not has_custom
	_detail_placeholder.visible = not visible_flag


func _clear_detail_custom() -> void:
	for c in _detail_custom_host.get_children():
		_detail_custom_host.remove_child(c)
		c.queue_free()
