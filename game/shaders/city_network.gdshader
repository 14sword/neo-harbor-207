shader_type canvas_item;
render_mode blend_mix;

uniform vec4 base_color : source_color = vec4(0.01, 0.02, 0.05, 1.0);
uniform vec4 accent_color : source_color = vec4(0.0, 0.85, 1.0, 0.15);
uniform float time : hint_range(0, 100, 0) = 0;
uniform float grid_size : hint_range(8, 128, 1) = 40.0;
uniform float node_count : hint_range(1, 5, 1) = 3.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;

	vec2 grid = abs(fract(uv * grid_size - vec2(time * 0.01, time * 0.008)) - 0.5);
	float grid_line = grid.x < 0.04 && grid.y < 0.04 ? accent_color.a * 0.02 : 0.0;
	if (grid_line < 0.001 && grid.x < 0.04) grid_line = accent_color.a * 0.15;
	if (grid_line < 0.001 && grid.y < 0.04) grid_line = accent_color.a * 0.15;

	float node_alpha = 0.0;
	float conn_alpha = 0.0;
	for (float i = 0.0; i < 5.0; i += 1.0) {
		if (i >= node_count) break;
		vec2 npos = vec2(hash21(vec2(i * 13.7, i * 7.3)), hash21(vec2(i * 3.1, i * 17.9)));
		npos += vec2(sin(time * 0.2 + i * 2.1) * 0.02, cos(time * 0.15 + i * 1.7) * 0.02);
		float d = length(uv - npos);
		node_alpha += (d < 0.012 ? accent_color.a * 3.0 : 0.0) + (d < 0.04 ? accent_color.a * 0.5 : 0.0);

		float j = mod(i + 1.0, node_count);
		vec2 opos = vec2(hash21(vec2(j * 13.7, j * 7.3)), hash21(vec2(j * 3.1, j * 17.9)));
		opos += vec2(sin(time * 0.2 + j * 2.1) * 0.02, cos(time * 0.15 + j * 1.7) * 0.02);

		vec2 pa = uv - npos;
		vec2 ba = opos - npos;
		float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
		float lined = length(pa - ba * h);
		conn_alpha += lined < 0.002 ? accent_color.a * 0.6 : 0.0;
	}

	float stream_alpha = 0.0;
	for (float i = 0.0; i < 3.0; i += 1.0) {
		float y = fract(hash21(vec2(i * 5.3, 1.0)) + time * 0.08);
		float x = hash21(vec2(i * 9.1, 3.0));
		float xdist = abs(uv.x - x);
		float half_len = 0.25;
		stream_alpha += (abs(uv.y - y) < 0.003 && xdist < half_len ? accent_color.a * 0.8 : 0.0);
	}

	vec3 col = base_color.rgb + accent_color.rgb * (grid_line + node_alpha + conn_alpha + stream_alpha);
	COLOR = vec4(col, min(base_color.a + node_alpha + conn_alpha + stream_alpha, 1.0));
}
