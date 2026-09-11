shader_type canvas_item;

uniform sampler2D tex_old : hint_default_black;
uniform sampler2D tex_new : hint_default_black;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center_uv = vec2(0.5, 0.5);
uniform float aspect_ratio = 1.7777778;
uniform vec4 transmute_color : source_color = vec4(0.36, 1.0, 0.56, 1.0);

float rand(vec2 n) {
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 ip = floor(p);
	vec2 u = fract(p);
	u = u * u * (3.0 - 2.0 * u);
	float res = mix(
		mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
		mix(rand(ip + vec2(0.0, 1.0)), rand(ip + vec2(1.0, 1.0)), u.x), u.y
	);
	return res * res;
}

float fbm(vec2 p) {
	float total = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 3; i++) {
		total += noise(p) * amplitude;
		p *= 2.0;
		amplitude *= 0.5;
	}
	return total;
}

void fragment() {
	vec4 c_old = texture(tex_old, UV);
	vec4 c_new = texture(tex_new, UV);

	// Distance from center_uv (Geovana) considering aspect ratio
	vec2 diff = (UV - center_uv);
	diff.x *= aspect_ratio;
	float dist_to_center = length(diff);

	// Max possible distance from center_uv to any screen corner (~1.5)
	float max_dist = 1.5;

	// Inward shrinking radius from outer screen borders down to center_uv (Geovana)
	// At progress = 0.0: radius = 1.5 (old map covers everything)
	// At progress = 1.0: radius = 0.0 (new map covers everything)
	float current_radius = (1.0 - progress) * max_dist;

	// Oscillating energy wave distortion using FBM noise + TIME animation
	vec2 noise_uv = UV * 14.0 + vec2(TIME * 1.8, TIME * 0.9);
	float wave_distortion = (fbm(noise_uv) - 0.5) * 0.24;
	float masked_dist = dist_to_center + wave_distortion;

	// Width of the glowing energy curtain edge
	float edge_width = 0.09;

	if (masked_dist > current_radius + edge_width) {
		// Outside the shrinking old-dimension area -> reveal new dimension underneath
		COLOR = c_new;
	} else if (masked_dist > current_radius) {
		// On the oscillating energy curtain edge -> intense glowing energy line
		float edge_t = (masked_dist - current_radius) / edge_width;
		float glow_pulse = 1.3 + sin(TIME * 20.0 + dist_to_center * 25.0) * 0.5;
		vec4 edge_glow = vec4(transmute_color.rgb * glow_pulse * 1.8, 1.0);
		vec4 blended_map = mix(c_old, c_new, edge_t);
		COLOR = mix(blended_map, edge_glow, smoothstep(0.0, 1.0, sin(edge_t * 3.14159) * 0.92));
	} else {
		// Inside the shrinking old-dimension area -> old map still visible
		COLOR = c_old;
	}
}
