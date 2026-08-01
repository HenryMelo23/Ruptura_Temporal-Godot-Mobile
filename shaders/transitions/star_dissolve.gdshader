// res://shaders/transitions/star_dissolve.gdshader
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float pixel_size : hint_range(32.0, 256.0) = 128.0;
uniform vec4 star_color : source_color = vec4(0.65, 0.85, 1.0, 1.0);
uniform vec4 nebula_color : source_color = vec4(0.8, 0.3, 0.9, 1.0);

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

void fragment() {
    vec2 uv = UV;
    vec2 grid_uv = floor(uv * pixel_size) / pixel_size;
    float n_val = fbm(grid_uv * 6.0);
    
    // Dissolve threshold
    float threshold = progress * 1.3 - 0.15;
    float black_mask = step(threshold, n_val);
    
    // Edge width for cosmic star glow
    float edge = smoothstep(threshold, threshold + 0.12, n_val) * (1.0 - black_mask);
    
    // Procedural twinkling stars on the edge
    vec2 cell = floor(uv * 40.0);
    vec2 sub_uv = fract(uv * 40.0) - 0.5;
    float cell_hash = hash21(cell);
    float star_sparkle = 0.0;
    if (cell_hash > 0.65) {
        float d = length(sub_uv);
        float blink = sin(TIME * 6.0 + cell_hash * 6.28) * 0.5 + 0.5;
        star_sparkle = smoothstep(0.18, 0.0, d) * blink;
    }
    
    vec4 col = vec4(0.0, 0.0, 0.0, black_mask);
    
    // Add cosmic nebula and glowing star dust on edge
    if (edge > 0.001 || black_mask > 0.5) {
        vec3 nebula = mix(star_color.rgb, nebula_color.rgb, sin(n_val * 10.0 + TIME) * 0.5 + 0.5);
        if (black_mask > 0.5) {
            // Subtle cosmic dust inside black overlay
            float dust = fbm(uv * 12.0 + TIME * 0.1) * 0.15;
            col.rgb += nebula * dust;
        } else {
            // Glowing star dissolve edge
            col.rgb = mix(col.rgb, nebula, edge * 0.9);
            col.rgb += star_color.rgb * star_sparkle * 1.5;
            col.a = max(col.a, clamp(edge * 0.95 + star_sparkle, 0.0, 1.0));
        }
    }
    
    COLOR = col;
}
