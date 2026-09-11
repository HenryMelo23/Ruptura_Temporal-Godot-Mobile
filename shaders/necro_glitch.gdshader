// res://shaders/necro_glitch.gdshader
shader_type canvas_item;

uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float chromatic_split : hint_range(0.0, 0.05) = 0.015;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void fragment() {
    vec2 uv = UV;
    
    // Slice scanline glitch shift
    float slice_y = floor(uv.y * 32.0);
    float slice_hash = hash21(vec2(slice_y, floor(TIME * 12.0)));
    float offset_x = 0.0;
    if (slice_hash > 0.82) {
        offset_x = (hash21(vec2(slice_y, TIME)) - 0.5) * 0.08 * glitch_intensity;
    }
    
    vec2 shifted_uv = vec2(uv.x + offset_x, uv.y);
    
    // Chromatic aberration (RGB split)
    float r = texture(TEXTURE, shifted_uv + vec2(chromatic_split * glitch_intensity, 0.0)).r;
    float g = texture(TEXTURE, shifted_uv).g;
    float b = texture(TEXTURE, shifted_uv - vec2(chromatic_split * glitch_intensity, 0.0)).b;
    float a = texture(TEXTURE, shifted_uv).a;
    
    // Digital noise flicker
    float flicker = hash21(uv + vec2(TIME)) * 0.15 * glitch_intensity;
    
    vec4 col = vec4(r + flicker, g + flicker, b + flicker, a);
    
    // Cyan/magenta dimensional aura tint on edges
    if (a > 0.01) {
        vec3 anomaly_tint = mix(vec3(0.1, 0.9, 0.8), vec3(0.9, 0.1, 0.7), sin(TIME * 8.0 + uv.y * 10.0) * 0.5 + 0.5);
        col.rgb = mix(col.rgb, anomaly_tint, 0.20 * glitch_intensity);
    }
    
    COLOR = col;
}
