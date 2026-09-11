// res://shaders/transitions/slime_drip_melt.gdshader
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 slime_color : source_color = vec4(0.85, 0.78, 0.12, 1.0); // Acid yellow slime
uniform vec4 bubble_color : source_color = vec4(0.95, 0.95, 0.35, 1.0);

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

float acid_bubbles(vec2 uv) {
    vec2 st = uv * vec2(30.0, 15.0) - vec2(0.0, TIME * 2.5);
    vec2 id = floor(st);
    vec2 p = fract(st) - 0.5;
    float h = hash21(id);
    if (h < 0.65) return 0.0;
    p.x += sin(TIME * 4.0 + h * 6.28) * 0.1;
    float d = length(p);
    float bubble_ring = smoothstep(0.18, 0.14, d) * smoothstep(0.06, 0.10, d);
    float bubble_center = smoothstep(0.08, 0.0, d);
    return bubble_ring * 0.9 + bubble_center * 0.5;
}

void fragment() {
    vec2 uv = UV;
    float n1 = noise(vec2(uv.x * 10.0, 0.2));
    float n2 = noise(vec2(uv.x * 28.0, 0.5)) * 0.35;
    float drip_length = (n1 + n2) * 0.38;
    
    float drip_threshold = progress * 1.35 - drip_length;
    float black_mask = step(drip_threshold, uv.y);
    float slime_edge = smoothstep(drip_threshold, drip_threshold + 0.06, uv.y) * (1.0 - black_mask);
    
    float bubbles = acid_bubbles(uv);
    vec4 col = vec4(0.0, 0.0, 0.0, black_mask);
    
    if (black_mask > 0.5) {
        // Toxic slime sheen & rising bubbles inside black overlay
        float sheen = noise(uv * 18.0 + vec2(0.0, TIME * 0.5)) * 0.15;
        col.rgb += slime_color.rgb * (sheen + bubbles * 0.6);
    } else if (slime_edge > 0.001) {
        // Viscous stalactite slime edge with glowing acid bubbles
        vec3 rim = mix(slime_color.rgb, bubble_color.rgb, bubbles);
        col.rgb = mix(col.rgb, rim, slime_edge * 0.95);
        col.rgb += bubble_color.rgb * bubbles * 1.5;
        col.a = max(col.a, clamp(slime_edge * 0.95 + bubbles, 0.0, 1.0));
    }
    
    COLOR = col;
}
