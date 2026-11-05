shader_type canvas_item;

// Uniforms
uniform sampler2D dissolve_texture : repeat_enable, filter_nearest;
uniform sampler2D palette_ramp : filter_nearest; // 1D palette: Black -> Dark Red -> Bright Orange -> Yellow/White
uniform float dissolve_value : hint_range(0.0, 1.0) = 0.0; // 0.0 = intact, 1.0 = fully destroyed
uniform float burn_width : hint_range(0.0, 0.2) = 0.05;
uniform float pixel_factor : hint_range(8.0, 512.0) = 128.0; // Pixel art resolution
uniform vec2 noise_scroll_speed = vec2(0.0, -0.2);
uniform float ember_pulse_speed : hint_range(0.0, 10.0) = 4.0;
// 0..1: quanto fogo vivo sobe pela carta (cresce com as cargas de Cinzas).
uniform float heat : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    // 1. Pixelate UV coordinates
    vec2 grid_uv = floor(UV * pixel_factor) / pixel_factor;
    
    // 2. Animated noise offset for flame movement
    vec2 scrolled_uv = grid_uv + noise_scroll_speed * TIME;
    
    // 3. Sample original card sprite & noise texture
    vec4 card_tex = texture(TEXTURE, grid_uv);
    float noise_val = texture(dissolve_texture, scrolled_uv).r;
    
    // 4. Calculate burn threshold and masks
    float active_dissolve = clamp(dissolve_value, 0.0, 1.0);
    float alpha_cutoff = step(active_dissolve, noise_val);
    
    // Glowing ember rim mask
    float ember_rim = smoothstep(active_dissolve - burn_width, active_dissolve, noise_val) * (1.0 - alpha_cutoff);
    
    // Pulsing heat glow
    float pulse = 0.85 + 0.15 * sin(TIME * ember_pulse_speed);
    
    // 5. Sample palette color based on ember rim position
    float palette_x = clamp((noise_val - (active_dissolve - burn_width)) / max(burn_width, 0.001), 0.0, 1.0);
    vec4 ember_color = texture(palette_ramp, vec2(palette_x, 0.0));
    ember_color.rgb *= pulse * 1.4; // Boost brightness for glow
    
    // 6. Combine layers
    vec4 final_color = card_tex;
    
    // Mix ember color onto burn edge
    final_color.rgb = mix(final_color.rgb, ember_color.rgb, ember_rim);
    
    // Apply alpha mask (discard fully burned pixels)
    final_color.a *= alpha_cutoff;
    
    // Carvao perto da borda queimada.
    float char_mask = smoothstep(active_dissolve + 0.12, active_dissolve, noise_val) * alpha_cutoff;
    final_color.rgb *= 1.0 - char_mask * 0.45;

    // Chamas vivas subindo da base: mais cargas = mais fogo, a arte nunca some.
    if (heat > 0.0) {
        float rise = 1.0 - grid_uv.y;
        float flame_noise = texture(dissolve_texture, grid_uv * vec2(1.6, 0.8) + vec2(0.0, TIME * 0.55)).r;
        float flame_height = 0.12 + heat * 0.38;
        float shape = rise + (flame_noise - 0.5) * 0.3;
        float flame = 1.0 - smoothstep(flame_height * 0.45, flame_height, shape);
        float core = clamp(1.0 - shape / max(flame_height, 0.001), 0.0, 1.0);
        vec4 flame_color = texture(palette_ramp, vec2(0.35 + core * 0.65, 0.0));
        flame_color.rgb *= 1.25 * pulse;
        float flame_a = flame * (0.55 + 0.35 * heat);
        final_color.rgb = mix(final_color.rgb, flame_color.rgb, flame_a);
        final_color.a = max(final_color.a, flame * 0.85);
    }

    // Output final color
    COLOR = final_color;
}
