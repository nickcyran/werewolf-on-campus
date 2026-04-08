shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 outline_color : source_color = vec4(1.0, 0.82, 0.2, 1.0);
uniform float grow_amount : hint_range(0.0, 0.05) = 0.005;
uniform float pulse_speed : hint_range(0.0, 8.0) = 3.0;
uniform float pulse_min : hint_range(0.0, 1.0) = 0.7;

void vertex() {
	VERTEX += normalize(VERTEX) * grow_amount;
}

void fragment() {
	float pulse = mix(pulse_min, 1.0, 0.5 + 0.5 * sin(TIME * pulse_speed));
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a * pulse;
}
