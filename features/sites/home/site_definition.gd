class_name SiteDefinition
extends Resource

@export var scene: PackedScene
@export var label: String = ""
@export var description: String = ""
@export var icon: String = ""


## Reads the site_logo assigned on the scene's root Site node, so the logo
## only needs to be set once, in the site's own scene.
func get_logo() -> Texture2D:
	return _get_root_property(&"site_logo") as Texture2D


## Reads the tile_color assigned on the scene's root Site node.
func get_tile_color() -> Color:
	var color: Variant = _get_root_property(&"tile_color")
	return color if color is Color else Color(0.42, 0.45, 0.5)


func _get_root_property(prop: StringName) -> Variant:
	if !scene:
		return null

	var state := scene.get_state()
	for i in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == prop:
			return state.get_node_property_value(0, i)

	return null
