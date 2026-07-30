// res://shaders/transitions/black_hole_vortex.gdshader
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float vortex_strength : hint_range(0.0, 20.0) = 8.0;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    vec2 diff = SCREEN_UV - center;
    float dist = length(diff);
    
    // Vortex twist angle based on distance and progress
    float angle = (1.0 - dist) * vortex_strength * progress;
    mat2 rot = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
    
    // Pull UVs inward toward center as progress grows
    vec2 distorted_uv = center + (rot * diff) * (1.0 - progress * 0.95);
    
    // Event horizon black hole radius
    float event_horizon = progress * 0.65;
    float hole_mask = step(dist, event_horizon);
    
    vec4 screen_col = texture(SCREEN_TEXTURE, distorted_uv);
    screen_col.rgb = mix(screen_col.rgb, vec3(0.0), hole_mask);
    screen_col.a *= (1.0 - smoothstep(0.8, 1.0, progress));
    
    COLOR = screen_col;
}
