class_name CapturePost
extends Resource

@export var username: String = "user"
@export var pfp_color: Color = Color(0.6, 0.8, 0.72, 1)
@export var pfp_texture: Texture2D
@export var media_texture: Texture2D
@export var video_stream: VideoStream
## Guided-learning source credited when this post's media is viewed.
@export var source_id: String = ""
@export var description: String = ""
@export var likes: int = 0
