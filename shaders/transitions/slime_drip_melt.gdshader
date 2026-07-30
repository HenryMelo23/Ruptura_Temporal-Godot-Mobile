// res://shaders/transitions/slime_drip_melt.gdshader
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform sampler2D noise_tex : repeat_enable, filter_nearest;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 slime_color : source_color = vec4(0.85, 0.78, 0.12, 1.0); // Acid yellow slime

void fragment() {
    vec2 uv = SCREEN_UV;
    // Multi-frequency noise for stalactite drip shapes
    float n1 = texture(noise_tex, vec2(uv.x * 3.0, 0.2)).r;
    float n2 = texture(noise_tex, vec2(uv.x * 8.0, 0.5)).r * 0.3;
    float drip_length = (n1 + n2) * 0.4;
    
    float drip_threshold = progress * 1.4 - drip_length;
    float slime_mask = step(uv.y, drip_threshold);
    float slime_edge = smoothstep(drip_threshold - 0.04, drip_threshold, uv.y) * slime_mask;
    
    vec4 screen_col = texture(SCREEN_TEXTURE, uv);
    vec4 final_col = mix(screen_col, slime_color, slime_edge * 0.95);
    final_col.a *= (1.0 - slime_mask);
    
    COLOR = final_col;
}
