// res://shaders/transitions/worm_devour.gdshader
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 worm_red : source_color = vec4(0.88, 0.12, 0.16, 1.0);
uniform vec4 worm_dark : source_color = vec4(0.25, 0.05, 0.08, 1.0);

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

float worm_segments(vec2 uv) {
    vec2 st = uv * 20.0 + vec2(sin(uv.y * 10.0 + TIME * 3.0) * 0.5, TIME * 1.5);
    float n = noise(st);
    float rings = sin(st.y * 12.0) * 0.5 + 0.5;
    return n * 0.7 + rings * 0.3;
}

void fragment() {
    vec2 uv = UV;
    float dist_center = length(uv - vec2(0.5));
    float bite_teeth = noise(uv * 28.0 + vec2(0.0, TIME * 1.2)) * 0.22;
    
    float cutoff = progress * 0.78;
    float black_mask = step(cutoff, dist_center + bite_teeth);
    float worm_rim = smoothstep(cutoff, cutoff + 0.08, dist_center + bite_teeth) * (1.0 - black_mask);
    
    float segments = worm_segments(uv);
    vec4 col = vec4(0.0, 0.0, 0.0, black_mask);
    
    if (black_mask > 0.5) {
        // Writhing organic worm flesh texture inside black overlay
        col.rgb += mix(worm_dark.rgb, worm_red.rgb, segments * 0.25);
    } else if (worm_rim > 0.001) {
        // Crimson organic jaw devour edge
        vec3 rim = mix(worm_red.rgb, vec3(1.0, 0.3, 0.2), segments);
        col.rgb = mix(col.rgb, rim, worm_rim * 0.95);
        col.rgb += worm_red.rgb * segments * 0.5;
        col.a = max(col.a, worm_rim * 0.95);
    }
    
    COLOR = col;
}
