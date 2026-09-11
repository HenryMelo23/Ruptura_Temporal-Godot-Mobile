shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(0.0, 0.95, 1.0, 0.16);
uniform float line_spacing = 18.0;
uniform float line_speed = 32.0;
uniform float vignette = 0.48;

void fragment() {
	vec2 uv = UV;
	float moving_line = smoothstep(0.92, 1.0, fract((uv.y * line_spacing) + (TIME * line_speed * 0.01)));
	float grid_line = smoothstep(0.965, 1.0, fract(uv.x * 24.0)) * 0.35;
	float edge = distance(uv, vec2(0.5, 0.5)) * vignette;
	vec4 base = COLOR;
	base.rgb += line_color.rgb * (moving_line + grid_line) * line_color.a;
	base.a *= clamp(1.0 - edge, 0.0, 1.0);
	COLOR = base;
}
