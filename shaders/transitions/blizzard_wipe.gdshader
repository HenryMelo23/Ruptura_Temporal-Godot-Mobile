// res://shaders/transitions/blizzard_wipe.gdshader
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D noise_tex : repeat_enable, filter_nearest;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ice_color : source_color = vec4(0.85, 0.94, 1.0, 1.0);

void fragment() {
    vec2 uv = SCREEN_UV;
    // Diagonal slant sweep
    float sweep_pos = uv.x * 0.7 + uv.y * 0.3;
    float noise_val = texture(noise_tex, uv * 4.0 + vec2(TIME * 0.8, 0.0)).r * 0.15;
    
    float edge_front = progress * 1.3 - (sweep_pos + noise_val);
    float wipe_mask = step(0.0, edge_front);
    float ice_rim = smoothstep(-0.06, 0.0, edge_front) * (1.0 - wipe_mask);
    
    vec4 screen_col = texture(SCREEN_TEXTURE, uv);
    vec4 final_col = mix(screen_col, ice_color, ice_rim * 0.85);
    final_col.a *= (1.0 - wipe_mask);
    
    COLOR = final_col;
}
