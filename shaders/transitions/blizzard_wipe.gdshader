// res://shaders/transitions/blizzard_wipe.gdshader
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ice_color : source_color = vec4(0.82, 0.94, 1.0, 1.0);
uniform vec4 snow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

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

float snowflake_layer(vec2 uv, float scale, float speed) {
    vec2 st = uv * scale + vec2(TIME * speed, TIME * speed * 0.4);
    vec2 id = floor(st);
    vec2 p = fract(st) - 0.5;
    float h = hash21(id);
    if (h < 0.6) return 0.0;
    p += vec2(sin(TIME * 2.0 + h * 6.28) * 0.15, cos(TIME * 2.0 + h * 6.28) * 0.15);
    float d = length(p);
    float flake = smoothstep(0.12 * (h - 0.5) * 2.0, 0.0, d);
    return flake;
}

void fragment() {
    vec2 uv = UV;
    float sweep_pos = uv.x * 0.7 + uv.y * 0.3;
    float n_val = noise(uv * 12.0 + vec2(TIME * 1.8, 0.0)) * 0.16;
    
    float cutoff = progress * 1.35 - 0.15;
    float black_mask = step(cutoff, sweep_pos + n_val);
    
    // Ice frost rim width
    float ice_rim = smoothstep(cutoff, cutoff + 0.09, sweep_pos + n_val) * (1.0 - black_mask);
    
    // Multi-layered procedural blizzard snow particles
    float snow1 = snowflake_layer(uv, 25.0, 1.2);
    float snow2 = snowflake_layer(uv + vec2(0.3, 0.7), 40.0, 2.0);
    float total_snow = clamp(snow1 + snow2, 0.0, 1.0);
    
    vec4 col = vec4(0.0, 0.0, 0.0, black_mask);
    
    if (black_mask > 0.5) {
        // Frost texture & blowing blizzard inside black overlay
        float frost = noise(uv * 30.0) * 0.12;
        col.rgb += ice_color.rgb * (frost + total_snow * 0.8);
    } else if (ice_rim > 0.001) {
        // Glowing ice frost rim along advancing blizzard front
        vec3 rim = mix(ice_color.rgb, snow_color.rgb, total_snow);
        col.rgb = mix(col.rgb, rim, ice_rim * 0.92);
        col.rgb += snow_color.rgb * total_snow * 1.2;
        col.a = max(col.a, clamp(ice_rim * 0.95 + total_snow, 0.0, 1.0));
    }
    
    COLOR = col;
}
