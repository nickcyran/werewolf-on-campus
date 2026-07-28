# circular progress ring for the "sources visited" stat card.
class_name SourceRing
extends Control

const TRACK_COLOR := Color(1, 1, 1, 0.2)
const FILL_COLOR := Color(1, 1, 1, 1)

var progress: float = 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 4.0
	draw_arc(c, r, 0.0, TAU, 64, TRACK_COLOR, 6.0, true)
	if progress > 0.001:
		draw_arc(c, r, -PI * 0.5, -PI * 0.5 + progress * TAU, 64, FILL_COLOR, 6.0, true)
