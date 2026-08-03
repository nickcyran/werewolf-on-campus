class_name PhoneAppDefinition
extends Resource

@export var scene: PackedScene
@export var label: String = ""
@export var icon: String = ""
## Flat tile colour, and the fallback when no [member tile_gradient] is set.
@export var color: Color = Color(0.3, 0.3, 0.35)
## Optional gradient drawn over the tile, clipped to its rounded corners.
@export var tile_gradient: Texture2D
