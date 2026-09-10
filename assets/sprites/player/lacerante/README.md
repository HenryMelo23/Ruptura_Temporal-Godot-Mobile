# Lacerante sprite atlases

The atlases in this folder are generated, transparent RGBA pixel art. Every cell is 256×256 and uses nearest-neighbour filtering.

`core.png` is a 6×4 sheet: idle (0–3), down (4–5), right (6–8), left (9–11), up (12–13), damage (14–17), and right-facing attack stages (18–23).

`extra.png` is a 4×4 sheet: start-down (0–5), frozen (6–7), left-facing attack stages (8–13), and two spare idle frames (14–15).

The runtime maps these frames through `scripts/lacerante_sprites.gd` so local and remote players keep the manifestation identity across movement, damage, freeze and attack states.
