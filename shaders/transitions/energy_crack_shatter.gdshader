// res://shaders/transitions/energy_crack_shatter.gdshader
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 green_energy : source_color = vec4(0.2, 1.0, 0.45, 1.0);
uniform vec4 blue_energy : source_color = vec4(0.0, 0.75, 1.0, 1.0);

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
    vec2 uv = UV;
    float seam = sin(uv.y * 14.0) * 0.04 + cos(uv.y * 28.0) * 0.02 + 0.5;
    float dist_seam = abs(uv.x - seam);
    
    // Jagged electric arcs branching off seam
    float lightning = noise(uv * 25.0 + vec2(0.0, TIME * 4.0)) * 0.08;
    float crack_dist = dist_seam + lightning;
    
    float cutoff = progress * 0.65;
    float black_mask = step(cutoff, crack_dist);
    float crack_glow = smoothstep(cutoff, cutoff + 0.06, crack_dist) * (1.0 - black_mask);
    
    vec4 energy_color = mix(green_energy, blue_energy, step(0.5, uv.y + sin(TIME * 2.0) * 0.1));
    vec4 col = vec4(0.0, 0.0, 0.0, black_mask);
    
    if (black_mask > 0.5) {
        // Electric energy pulse inside black overlay
        float pulse = noise(uv * 15.0 - vec2(TIME * 2.0, 0.0)) * 0.12;
        col.rgb += energy_color.rgb * pulse;
    } else if (crack_glow > 0.001) {
        // Glowing plasma crack seam
        col.rgb = mix(col.rgb, energy_color.rgb, crack_glow * 0.95);
        col.rgb += energy_color.rgb * 0.6;
        col.a = max(col.a, crack_glow * 0.95);
    }
    
    COLOR = col;
}
