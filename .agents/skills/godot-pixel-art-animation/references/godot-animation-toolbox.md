# Godot Animation Toolbox

## Official Godot References

- 2D sprite animation: https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html
- Importing images: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html
- Animation features: https://docs.godotengine.org/en/stable/tutorials/animation/introduction.html
- AnimationTree: https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html
- Cutout animation: https://docs.godotengine.org/en/stable/tutorials/animation/cutout_animation.html
- GPUParticles2D: https://docs.godotengine.org/en/stable/classes/class_gpuparticles2d.html
- ParticleProcessMaterial 2D: https://docs.godotengine.org/en/stable/tutorials/2d/particle_process_material_2d.html
- CanvasItem shaders: https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html

## Node Selection

### AnimatedSprite2D + SpriteFrames

Use for straightforward frame playback. Godot supports individual images and sprite sheets through `SpriteFrames`; the SpriteFrames panel also exposes animation names and FPS. Good defaults:

- `idle`: 4-8 frames, 4-8 FPS, longer holds.
- `run`: 6-10 frames, 8-14 FPS.
- `hurt`: 2-4 frames, 10-16 FPS, one white/red flash shader or material key.
- `attack`: 5-10 frames, uneven timing with a held anticipation and a fast hit frame.

Drive with `play(animation_name)` and keep animation names stable. Avoid repeatedly calling `play()` every frame if the animation is already active.

### Sprite2D + AnimationPlayer

Use when the animation must coordinate more than frame index:

- Sprite `frame` / `hframes` / `vframes`.
- Position, offset, scale, rotation, alpha, material uniforms.
- Collision shape enable/disable.
- Function calls for hit frame, sound, particles, camera shake, and cleanup.

If a property change and `play()` happen in the same frame, advance or structure timing to avoid a one-frame mismatch.

### AnimationTree

Use for stateful characters or bosses:

- Idle/run/attack/hurt/death state travel.
- Directional variants.
- Blend spaces for movement.
- Recovery/interrupt rules.

Keep gameplay authority in script. The tree selects presentation state; damage logic should not be hidden inside hard-to-audit animation tracks unless it is a deliberate call-method track.

### Shaders

Use CanvasItem shaders for cheap per-pixel life:

- Palette cycling and corruption pulses.
- Edge light, hit flash, outline, dissolve, burn, afterimage blend.
- UV quantization for pixel-art procedural edges.
- TIME-based flicker only when it does not desync gameplay-critical readability.

Set shader uniforms from the owning script or AnimationPlayer. Validate uniform names.

### Particles

Use `GPUParticles2D` with `ParticleProcessMaterial` for repeated microdetail:

- Configure amount, lifetime, explosiveness, spread, initial velocity, damping, gravity, scale curve, color ramp, draw order, and local/global coordinates.
- Use emission masks from textures for rich sprite-shaped emissions where useful.
- Prefer local-only VFX in multiplayer; synchronize the gameplay event, not every particle.

Use bounded CPU particles when exact pixel placement, deterministic replay, or low amounts matter more than emitter convenience.

## Import And Pixel Settings

- Inspect import settings before blaming code. Pixel art usually needs nearest filtering and careful mipmap/compression choices.
- Texture atlases can reduce memory for animated 2D sprites.
- Avoid SVG for detailed pixel-art sprite animation; raster PNG/WebP sheets are easier to control.
- Keep sprite origins, offsets, hitboxes, and frame sizes consistent across an animation.

## Implementation Checklist

1. Find existing animation resources and naming style.
2. Select the node layer before writing code.
3. Define animation names, FPS, frame count, and exact hit frame.
4. Add secondary layers: shader, particles, shadow, smear, trail, sound, or camera response.
5. Add cleanup and reset logic.
6. Run visual smoke and inspect terminal output.
