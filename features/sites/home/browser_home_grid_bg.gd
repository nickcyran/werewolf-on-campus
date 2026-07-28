extends Control

const DOT_SPACING := 26.0
const DOT_RADIUS := 1.4
const DOT_COLOR := Color(0, 0, 0, 0.07)


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var y := DOT_SPACING * 0.5
	while y <= size.y:
		var x := DOT_SPACING * 0.5
		while x <= size.x:
			draw_circle(Vector2(x, y), DOT_RADIUS, DOT_COLOR)
			x += DOT_SPACING
		y += DOT_SPACING
