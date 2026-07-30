shader_type canvas_item;

// Uniforms
uniform sampler2D dissolve_texture : repeat_enable, filter_nearest;
uniform sampler2D palette_ramp : filter_nearest; // 1D palette: Black -> Dark Red -> Bright Orange -> Yellow/White
uniform float dissolve_value : hint_range(0.0, 1.0) = 0.0; // 0.0 = intact, 1.0 = fully destroyed
uniform float burn_width : hint_range(0.0, 0.2) = 0.05;
uniform float pixel_factor : hint_range(8.0, 512.0) = 128.0; // Pixel art resolution
uniform vec2 noise_scroll_speed = vec2(0.0, -0.2);
uniform float ember_pulse_speed : hint_range(0.0, 10.0) = 4.0;

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
    
    // Output final color
    COLOR = final_color;
}
