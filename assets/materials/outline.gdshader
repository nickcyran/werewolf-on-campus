shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 outline_color : source_color = vec4(1.224, 0.844, 0.0, 1.0);
uniform float grow_amount : hint_range(0.0, 0.05) = 0.005;

void vertex() {
	VERTEX += normalize(VERTEX) * grow_amount;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
