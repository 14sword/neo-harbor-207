shader_type canvas_item;
render_mode blend_mix;

uniform vec4 glitch_color : source_color = vec4(0.1, 0.8, 1.0, 0.5);
uniform float intensity : hint_range(0, 1, 0.01) = 0.0;
uniform float time : hint_range(0, 100, 0) = 0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;

	float alpha = 0.0;
	vec3 col = vec3(0.0);

	float block_y = floor(uv.y * 20.0);
	float trigger = hash21(vec2(block_y, floor(time * 8.0)));

	if (trigger > 0.75 && intensity > 0.001) {
		float shift = (hash21(vec2(block_y, floor(time * 10.0))) - 0.5) * 0.08 * intensity;
		float r_shift = (hash21(vec2(block_y, floor(time * 12.0) + 1.0)) - 0.5) * 0.02 * intensity;
		float b_shift = (hash21(vec2(block_y, floor(time * 12.0) + 2.0)) - 0.5) * 0.02 * intensity;

		float in_block = step(abs((uv.x + shift) * 2.0 - 1.0), 0.8);

		col.r = in_block > 0.0 ? glitch_color.r * 0.6 : 0.0;
		col.g = in_block > 0.0 ? glitch_color.g * 1.0 : 0.0;
		col.b = in_block > 0.0 ? glitch_color.b * 1.2 : 0.0;

		float bar = hash21(vec2(block_y, floor(time * 6.0))) > 0.92 ? 0.4 : 0.0;
		col += glitch_color.rgb * bar * intensity;
		alpha = intensity * glitch_color.a * 0.6 + bar * glitch_color.a * 0.4;
	} else {
		float scan = sin(uv.y * 800.0 + time * 50.0) * 0.01 * intensity;
		alpha = max(scan, 0.0);
		col = glitch_color.rgb * alpha * 0.3;
	}

	COLOR = vec4(col, min(alpha, 1.0));
}
