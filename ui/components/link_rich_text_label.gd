class_name LinkRichTextLabel extends RichTextLabel
## RichTextLabel that shows the pointing-hand cursor while a [code][url][/code] link
## is hovered. Navigation stays with whoever owns [signal RichTextLabel.meta_clicked].
##
## The shape is set two ways on purpose. [member Control.mouse_default_cursor_shape]
## covers this label being hovered directly, as when the scene is run on its own.
## [method Input.set_default_cursor_shape] covers the embedded screens: those render
## into a SubViewport pinned to a 3D quad, so the root viewport finds no Control under
## the pointer and falls back to the global default shape. It also applies immediately —
## the per-Control shape only takes effect on the next mouse-motion event, which is why
## it otherwise lags behind the hover.

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
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_meta_hover_ended(_meta: Variant) -> void:
	_clear_pointer()


func _clear_pointer() -> void:
	if !_pointing:
		return

	_pointing = false
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
