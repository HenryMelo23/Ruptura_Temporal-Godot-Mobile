# Calm Phase Maps

Eight generated ground textures replace the legacy high-glare backgrounds. The
original art in `assets/sprites/` is preserved. Existing `map_phase_*` keys,
camera framing and UMBRA dimension routing remain unchanged.

| Surface | Theme |
| --- | --- |
| 1 | Fractured temporal stone, muted violet seams |
| 2 | Frozen courtyard, ice and peripheral snow |
| 3 | Poison ritual, worn brass and stagnant channels |
| 4 | Nexo, geometric stone and muted crystals |
| 5 | UMBRA, charcoal stone and jade temporal channels |
| 6 | Chaga, organic roots and stagnant pools |
| 7 | Scorched stone, hand impressions and ember seams |
| 9 | Rastro transmutation, decay and moss channels |

Each PNG is a 592x592 square crop from one of two generated atlases, extracted
without resampling by `tools/prepare_phase_maps.gd`. No baked bloom, central
white hotspot or full-screen lightning. The neutral central floor is static.
`phase_map_life.gdshader` animates only saturated peripheral material, sampling
at most twice per pixel (once in low-resource mode, keeping the local material
animation). A single reused map CanvasItem sits behind gameplay.
World-anchored ambient motes are limited to 18, or 8 in low-resource mode, and
respect the existing particle toggle. Animation uses gameplay time and freezes
when that time stops; it does not create network or physics state.

Visual regression: run `tests/phase_maps_visual_smoke.gd` with a rendering
display, using `-- --out=res://.agent_logs/phase_maps/after`. Headless rendering
is intentionally rejected because it cannot verify screenshots.
