extends Site

const EmailEntryScene := preload("res://features/sites/email/email_entry.tscn")

@onready var _list_header: Label = %ListHeader
@onready var _list_vbox: VBoxContainer = %ListVBox
@onready var _detail_sender: Label = %DetailSender
@onready var _detail_subject: Label = %DetailSubject
@onready var _detail_body: RichTextLabel = %DetailBody
@onready var _detail_placeholder: Label = %DetailPlaceholder
@onready var _detail_custom_host: MarginContainer = %DetailCustomHost
@onready var _detail_rule: PanelContainer = %DetailRule
@onready var _category_buttons: Dictionary[String, Button] = {
	"inbox": %BtnInbox,
	"spam": %BtnSpam,
	"trash": %BtnTrash,
}

## Every email in this client, authored as EmailData resources under emails/.
@export var emails: Array[EmailData] = []

var _current_category: String = "inbox"
var _selected_entry: EmailEntry = null


func _ready() -> void:
	for cat: String in _category_buttons:
		_category_buttons[cat].pressed.connect(_on_sidebar_pressed.bind(cat))

	_select_category("inbox")


func _select_category(category: String) -> void:
	_current_category = category
	_selected_entry = null

	for cat: String in _category_buttons:
		_category_buttons[cat].theme_type_variation = \
			&"SidebarButtonActive" if cat == category else &"SidebarButton"

	_list_header.text = "   %s" % category.to_upper()

	_free_children(_list_vbox)
	for email in emails:
		if !email || email.category != category:
			continue
		var entry: EmailEntry = EmailEntryScene.instantiate() as EmailEntry
		_list_vbox.add_child(entry)
		entry.setup(email)
		entry.email_selected.connect(_on_email_selected)

	_show_detail(false)


func _on_sidebar_pressed(category: String) -> void:
	if category != _current_category:
		_select_category(category)


func _on_email_selected(entry: EmailEntry) -> void:
	if entry == _selected_entry:
		return

	if _selected_entry:
		_selected_entry.set_selected(false)
	_selected_entry = entry
	entry.set_selected(true)

	var data: EmailData = entry.get_email_data()
	_free_children(_detail_custom_host)

	if data.reading_layout:
		var reader := data.reading_layout.instantiate() as EmailReadingLayout
		_detail_custom_host.add_child(reader)
		reader.apply_data(data)
	else:
		_detail_sender.text = data.sender
		_detail_subject.text = data.subject
		_detail_body.text = data.body

	_show_detail(true)


func _show_detail(has_selection: bool) -> void:
	if !has_selection:
		_free_children(_detail_custom_host)

	var has_custom := has_selection && _detail_custom_host.get_child_count() > 0
	var show_default := has_selection && !has_custom
	_detail_custom_host.visible = has_custom
	_detail_sender.visible = show_default
	_detail_subject.visible = show_default
	_detail_body.visible = show_default
	_detail_rule.visible = show_default
	_detail_placeholder.visible = !has_selection


func _free_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
