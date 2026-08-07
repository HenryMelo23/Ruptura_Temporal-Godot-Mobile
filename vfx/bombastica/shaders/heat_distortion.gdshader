shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform float strength : hint_range(0.0, 0.05) = 0.015;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float frequency = 24.0;
uniform float speed = 12.0;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	vec2 uv = UV;
	float dist = distance(uv, center);
	
	// Mask distortion to an expanding ring
	float ring_center = progress * 0.45;
	float ring_width = 0.18;
	float ring_mask = smoothstep(ring_width, 0.0, abs(dist - ring_center)) * (1.0 - progress);
	
	// Wave displacement
	float wave = sin(dist * frequency - TIME * speed) * cos(atan(uv.y - center.y, uv.x - center.x) * 6.0);
	vec2 offset = vec2(wave) * strength * ring_mask;
	
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV + offset);
	COLOR = screen_color;
}
