shader_type canvas_item;

// Draws a dashed outline around the rect. Fed the rect size by dashed_border.gd.

uniform vec4 line_color : source_color = vec4(0.1, 0.07, 0.02, 1.0);
uniform vec2 rect_size = vec2(120.0, 40.0);
uniform float thickness : hint_range(1.0, 12.0) = 3.0;
uniform float dash : hint_range(2.0, 40.0) = 9.0;
uniform float gap : hint_range(1.0, 40.0) = 7.0;

void fragment() {
	vec2 p = UV * rect_size;
	float dx = min(p.x, rect_size.x - p.x);
	float dy = min(p.y, rect_size.y - p.y);
	float on_border = step(min(dx, dy), thickness);

	// Unwrap the perimeter so the dash pattern stays continuous around corners.
	float t;
	if (dx < dy) {
		t = (p.x < rect_size.x * 0.5) ? p.y : rect_size.y + rect_size.x + p.y;
	} else {
		t = (p.y < rect_size.y * 0.5) ? rect_size.y + p.x : rect_size.y * 2.0 + rect_size.x + p.x;
	}

	float lit = step(mod(t, dash + gap), dash);
	COLOR = vec4(line_color.rgb, line_color.a * on_border * lit);
}
