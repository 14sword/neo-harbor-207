shader_type canvas_item;
render_mode blend_mix;

uniform vec4 color : source_color = vec4(0.0, 0.85, 1.0, 0.04);
uniform float time : hint_range(0, 100, 0) = 0.0;
uniform float grid_size : hint_range(2, 64, 1) = 32.0;
uniform float line_width : hint_range(0.5, 3, 0.1) = 0.8;
uniform float speed : hint_range(0, 10, 0.1) = 0.8;

void fragment() {
	vec2 uv = FRAGCOORD.xy / (1.0 / SCREEN_PIXEL_SIZE);
	vec2 grid = abs(fract(uv * grid_size - vec2(time * speed * 0.5)) - 0.5);
	float line = min(grid.x, grid.y);
	float alpha = smoothstep(line_width / grid_size, 0.0, line) * color.a;
	COLOR = vec4(color.rgb, alpha);
}
