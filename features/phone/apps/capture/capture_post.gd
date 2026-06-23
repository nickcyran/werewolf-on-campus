class_name CapturePost
extends Resource

@export var username: String = "user"
@export var pfp_color: Color = Color(0.6, 0.8, 0.72, 1)
@export var pfp_texture: Texture2D
@export var media_texture: Texture2D
@export var video_stream: VideoStream
## Height-to-width ratio of the video. 9/16 = landscape 16:9, 16/9 = vertical portrait.
@export var video_aspect: float = 9.0 / 16.0
@export var description: String = ""
@export var likes: int = 0
@export var video_loop: bool = true
