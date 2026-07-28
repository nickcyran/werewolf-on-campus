class_name SiteDefinition
extends Resource

@export var scene: PackedScene
@export var label: String = ""
@export var description: String = ""
@export var icon: String = ""
@export var logo: Texture2D
## Background color of this site's tile on the browser home page.
@export var tile_color: Color = Color(0.42, 0.45, 0.5)
