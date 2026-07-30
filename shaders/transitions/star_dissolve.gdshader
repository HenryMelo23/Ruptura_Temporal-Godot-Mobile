// res://shaders/transitions/star_dissolve.gdshader
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform sampler2D noise_tex : repeat_enable, filter_nearest;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float pixel_size : hint_range(16.0, 512.0) = 128.0;
uniform vec4 star_color : source_color = vec4(0.72, 0.90, 1.0, 1.0);

void fragment() {
    vec2 grid_uv = floor(SCREEN_UV * pixel_size) / pixel_size;
    float noise_val = texture(noise_tex, grid_uv * 2.5).r;
    
    // Star shape mask threshold
    float star_threshold = progress * 1.2;
    float dissolve_mask = step(star_threshold, noise_val);
    float star_edge = smoothstep(star_threshold - 0.08, star_threshold, noise_val) * (1.0 - dissolve_mask);
    
    vec4 screen_col = texture(SCREEN_TEXTURE, grid_uv);
    vec4 final_col = mix(screen_col, star_color, star_edge * 0.9);
    final_col.a *= dissolve_mask;
    
    COLOR = final_col;
}
