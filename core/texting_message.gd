class_name TextingMessage
extends Resource

@export_multiline var body: String = ""
## Optional image attached to the message. Leave body empty for an image-only message.
@export var image: Texture2D = null
## Fraction of the in-game day (matches DayClock.get_progress(), 0 = day start, 1 = day end)
## at which this message is delivered to the player.
@export_range(0.0, 1.0, 0.01) var trigger_progress: float = 0.0
