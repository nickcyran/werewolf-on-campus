shader_type spatial;
render_mode unshaded;

uniform sampler2D screen_texture : source_color, filter_linear;
// Physical size of the screen quad in meters.
uniform vec2 screen_size = vec2(0.075, 0.139);
// Corner radius in meters; keep concentric with the phone body's bezel radius.
uniform float corner_radius = 0.0075;

void fragment() {
	vec2 p = (UV - 0.5) * screen_size;
	vec2 inner_half = screen_size * 0.5 - vec2(corner_radius);
	vec2 d = abs(p) - inner_half;
	if (length(max(d, vec2(0.0))) > corner_radius) {
		discard;
	}
	ALBEDO = texture(screen_texture, UV).rgb;
}
