shader_type canvas_item;
render_mode blend_mix;

uniform vec4 line_color : source_color = vec4(0.0, 0.85, 1.0, 0.03);
uniform float time : hint_range(0, 100, 0) = 0;
uniform float line_density : hint_range(1, 10, 1) = 3.0;
uniform float scan_speed : hint_range(0, 5, 0.1) = 0.5;

void fragment() {
	vec2 uv = UV;

	float scanline = sin(uv.y * line_density * 200.0) * 0.5 + 0.5;
	scanline = pow(scanline, 8.0);
	float line_a = scanline * line_color.a;

	float sweep_y = fract(time * scan_speed * 0.05);
	float sweep = 1.0 - smoothstep(0.0, 0.03, abs(uv.y - sweep_y));
	float sweep_a = sweep * line_color.a * 10.0;

	float final_a = line_a + sweep_a;

	COLOR = vec4(line_color.rgb, min(final_a, 1.0));
}
