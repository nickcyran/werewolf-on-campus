class_name SiteNavBar extends VBoxContainer
## The in-game browser's navigation bar, shown above a source so it reads as the same
## browser the player used. The buttons are for show; only the address changes.

@onready var _address_label: Label = %AddressLabel


func set_url(url: String) -> void:
	_address_label.text = url
