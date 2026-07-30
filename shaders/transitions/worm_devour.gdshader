// res://shaders/transitions/worm_devour.gdshader
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform sampler2D noise_tex : repeat_enable, filter_nearest;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 worm_color : source_color = vec4(0.18, 0.08, 0.06, 1.0);

void fragment() {
    vec2 uv = SCREEN_UV;
    // Distance from screen center (0.0 at center, ~0.7 at corners)
    float dist_center = length(uv - vec2(0.5));
    
    // Worm bite noise pattern along advancing front
    float bite_noise = texture(noise_tex, uv * 6.0 + vec2(0.0, TIME * 0.5)).r * 0.18;
    float devour_front = (1.0 - progress * 1.3) + bite_noise;
    
    float intact_mask = step(dist_center, devour_front);
    float worm_rim = smoothstep(devour_front, devour_front + 0.05, dist_center) * intact_mask;
    
    vec4 screen_col = texture(SCREEN_TEXTURE, uv);
    vec4 final_col = mix(screen_col, worm_color, worm_rim * 0.95);
    final_col.a *= intact_mask;
    
    COLOR = final_col;
}
