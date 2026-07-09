extends Control

const LINE_SPACING := 42.0
const LINE_COLOR := Color(1, 1, 1, 0.035)


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var x := 0.0
	while x <= size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), LINE_COLOR, 1.0)
		x += LINE_SPACING

	var y := 0.0
	while y <= size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), LINE_COLOR, 1.0)
		y += LINE_SPACING
