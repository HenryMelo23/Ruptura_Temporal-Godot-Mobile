# Lacerante sprite atlases

The atlases in this folder contain generated, transparent RGBA pixel art. Every cell is 320×256 and uses nearest-neighbour filtering. The wider transparent canvas preserves the full katana without shrinking individual attack poses.

`core.png` is a 6×4 sheet: idle (0–3), down (4–5), right (6–8), left (9–11), up (12–13), damage (14–17), and right-facing attack stages (18–23).

`extra.png` is a 4×4 sheet: start-down (0–5), frozen (6–7), left-facing attack stages (8–13), and two spare idle frames (14–15).

The runtime maps these frames through `scripts/lacerante_sprites.gd` so local and remote players keep the manifestation identity across movement, damage, freeze and attack states.

`tools/import_lacerante_atlas.gd` rebuilds both atlases from the preserved generated sources under `art_sources/lacerante/`. The sources are not exact grids: measured gutters avoid cutting neighbouring heads and swords. Each sheet uses one uniform scale; measured foot pivots align the poses at (160, 240). No character pixels are repainted. Run `godot --headless --path . --script tools/import_lacerante_atlas.gd`, then import the project.

The runtime never mirrors this manifestation because left-facing art already exists and the eyepatch is asymmetric. Idle stays idle for both facing directions. Each combo stage holds the even anticipation pose until the attack is emitted, then shows the odd strike pose for 240 ms before recovering. Damage plays once and holds its final recovery frame. Local rendering and multiplayer snapshots share the same selector, including the left-facing frame offsets. The damage calculation and attack preparation duration remain independent of this visual timing.
