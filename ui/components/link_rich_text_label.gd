class_name LinkRichTextLabel extends RichTextLabel
## RichTextLabel that shows the pointing-hand cursor while a [code][url][/code] link
## is hovered. Navigation stays with whoever owns [signal RichTextLabel.meta_clicked].
##
## The shape is set two ways on purpose. [member Control.mouse_default_cursor_shape]
## covers this label being hovered directly, as when the scene is run on its own.
## [method DisplayServer.cursor_set_shape] covers the embedded screens, where nothing
## else will apply it: [FocusSystem] marks each mouse event handled as it pushes it
## into the SubViewport, so the root viewport's GUI pass — the only place Godot turns
## a hovered Control's shape into a hardware cursor — never runs. The SubViewport does
## not stand in for it either; one rendering to a 3D quad leaves the OS cursor alone.
## Setting it here also applies immediately, where the per-Control shape would other-
## wise wait for the next mouse-motion event and lag behind the hover.

var _pointing := false


func _ready() -> void:
	meta_hover_started.connect(_on_meta_hover_started)
	meta_hover_ended.connect(_on_meta_hover_ended)
	mouse_exited.connect(_clear_pointer)
	hidden.connect(_clear_pointer)


## Navigating away can free this label mid-hover, so the shape is released here too.
func _exit_tree() -> void:
	_clear_pointer()


func _on_meta_hover_started(_meta: Variant) -> void:
	_pointing = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_POINTING_HAND)


func _on_meta_hover_ended(_meta: Variant) -> void:
	_clear_pointer()


func _clear_pointer() -> void:
	if !_pointing:
		return

	_pointing = false
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)
