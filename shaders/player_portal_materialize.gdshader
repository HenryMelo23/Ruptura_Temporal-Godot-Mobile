// res://shaders/player_portal_materialize.gdshader
shader_type canvas_item;

uniform float spawn_progress : hint_range(0.0, 1.0) = 0.0; // 0.0 = invisible/beam, 1.0 = fully materialized
uniform vec4 portal_beam_color : source_color = vec4(0.40, 0.90, 1.0, 1.0);
uniform float scanline_density = 40.0;

void fragment() {
    vec4 sprite_col = texture(TEXTURE, UV);
    if (sprite_col.a <= 0.01) {
        discard;
    }
    
    // Materialization line moving from bottom (1.0) to top (0.0)
    float scanline_pos = 1.0 - spawn_progress;
    float is_materialized = step(scanline_pos, UV.y);
    
    // Hologram / Beam scanlines
    float scanline = sin(UV.y * scanline_density - TIME * 10.0) * 0.5 + 0.5;
    float beam_edge = smoothstep(scanline_pos - 0.06, scanline_pos, UV.y) * (1.0 - is_materialized);
    
    vec3 final_rgb = mix(portal_beam_color.rgb * (1.2 + scanline * 0.5), sprite_col.rgb, is_materialized);
    float final_a = sprite_col.a * (is_materialized + beam_edge * 0.9);
    
    COLOR = vec4(final_rgb, final_a);
}
