// res://shaders/transitions/energy_crack_shatter.gdshader
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 green_energy : source_color = vec4(0.2, 1.0, 0.45, 1.0);
uniform vec4 blue_energy : source_color = vec4(0.0, 0.75, 1.0, 1.0);

void fragment() {
    vec2 uv = SCREEN_UV;
    // Central crack seam
    float seam = sin(uv.y * 12.0) * 0.02 + 0.5;
    float is_left = step(uv.x, seam);
    
    // Shift screen halves outward in opposite directions
    vec2 offset = vec2((is_left > 0.5 ? -1.0 : 1.0) * progress * 0.4, 0.0);
    vec2 split_uv = uv + offset;
    
    // Energy shockwave glow along crack seam
    float seam_dist = abs(uv.x - seam);
    float crack_glow = smoothstep(0.04 * (1.0 - progress), 0.0, seam_dist);
    vec4 energy_color = mix(green_energy, blue_energy, step(0.5, uv.y));
    
    vec4 screen_col = texture(SCREEN_TEXTURE, clamp(split_uv, 0.0, 1.0));
    screen_col.rgb = mix(screen_col.rgb, energy_color.rgb, crack_glow * (1.0 - progress));
    screen_col.a *= (1.0 - progress);
    
    COLOR = screen_col;
}
