// res://shaders/transitions/black_hole_vortex.gdshader
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float vortex_strength : hint_range(0.0, 20.0) = 12.0;
uniform vec4 vortex_purple : source_color = vec4(0.68, 0.22, 0.98, 1.0);
uniform vec4 vortex_cyan : source_color = vec4(0.2, 0.85, 1.0, 1.0);

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    vec2 diff = UV - center;
    float dist = length(diff);
    float angle = atan(diff.y, diff.x);
    
    // Spiral arms swirl math
    float spiral = sin(angle * 4.0 - dist * 18.0 + TIME * 3.0) * 0.5 + 0.5;
    float n_val = noise(UV * 10.0 + vec2(TIME * 0.5, 0.0)) * 0.1;
    
    float hole_radius = progress * 0.78 + n_val;
    float black_mask = step(hole_radius, dist);
    float vortex_rim = smoothstep(hole_radius, hole_radius + 0.10, dist) * (1.0 - step(hole_radius + 0.10, dist));
    
    vec4 col = vec4(0.0, 0.0, 0.0, black_mask);
    
    if (black_mask > 0.5) {
        // Swirling space energy inside black hole overlay
        float inner_swirl = sin(angle * 6.0 - dist * 30.0 + TIME * 4.0) * 0.5 + 0.5;
        col.rgb += mix(vortex_purple.rgb, vortex_cyan.rgb, inner_swirl) * 0.15;
    } else if (vortex_rim > 0.001) {
        // Gravitational event horizon accretion disk glow
        vec3 rim_col = mix(vortex_purple.rgb, vortex_cyan.rgb, spiral);
        col.rgb = mix(col.rgb, rim_col, vortex_rim * 0.95);
        col.rgb += vortex_cyan.rgb * spiral * 0.8;
        col.a = max(col.a, vortex_rim * 0.95);
    }
    
    COLOR = col;
}
