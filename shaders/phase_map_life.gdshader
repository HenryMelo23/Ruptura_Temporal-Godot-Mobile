shader_type canvas_item;
render_mode unshaded;

uniform float elapsed = 0.0;
uniform float motion_scale = 1.0;
uniform bool fluid_surface = true;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float highest = max(base.r, max(base.g, base.b));
	float lowest = min(base.r, min(base.g, base.b));
	// Only colored peripheral channels move. Neutral central masonry stays still.
	float pigment = smoothstep(0.10, 0.27, highest - lowest);
	float perimeter = smoothstep(0.18, 0.32, length(UV - vec2(0.5)));
	float mask = pigment * perimeter;
	vec4 flowing = base;
	if (fluid_surface) {
		vec2 drift = vec2(sin(UV.y * 47.0 + elapsed * 0.65),
			cos(UV.x * 39.0 - elapsed * 0.48));
		vec2 offset = drift * TEXTURE_PIXEL_SIZE * 0.85 * mask * motion_scale;
		flowing = texture(TEXTURE, clamp(UV + offset, TEXTURE_PIXEL_SIZE, vec2(1.0) - TEXTURE_PIXEL_SIZE));
	}
	float ripple = sin(UV.x * 68.0 + UV.y * 43.0 - elapsed * 0.72);
	vec3 color = mix(base.rgb, flowing.rgb, mask);
	// A small local reflectance change, never additive bloom or a global flash.
	color *= 1.0 + ripple * mask * 0.045 * motion_scale;
	COLOR = vec4(color, base.a);
}
