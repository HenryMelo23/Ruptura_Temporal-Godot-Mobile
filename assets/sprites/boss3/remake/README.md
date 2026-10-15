# Pai-Rato animation remake

Runtime frames use a fixed 256 x 256 transparent canvas and a shared bottom-center pivot. The game keeps the historical 184 x 170 draw box, so collision and gameplay scale do not change.

Frames are isolated from the real alpha components in each source atlas instead of being cut from an assumed uniform grid. Every runtime frame keeps a transparent safety margin, so neighboring poses, tails and effects cannot leak into the image or be clipped by the canvas. Where the generated source itself merged two poses, the animation reuses the nearest clean pose from the same sequence.

Visual direction: diseased liturgical authority. The amber wax skull-mask is the primary read; hands and tail carry secondary motion. Near-black plum cloth, acid-green faith/miasma accents, muted pink flesh and cream highlights keep the silhouette readable over the active phase 3 arena at `assets/maps/calm/phase_3.png`.

Animation sets:

- idle 6, walk 8, entry 8;
- rat spit 6, tail 6, rain 6;
- cheese ritual 8, consume 6, faith 7;
- sector ritual 8, miasma 7;
- hit 3, stun 5, death 10.

The `source/` directory preserves the generated concept and source atlases. Runtime uses only the sliced animation directories. Legacy `Boss3_*.png` and `Bossandando3_*.png` remain as compatibility fallbacks.

## Runtime orientation and state contract

The source character art faces left. Runtime mirrors only the fitted visual and
its shadow when effective horizontal velocity points right; world position,
hitboxes, projectiles and ability VFX are never mirrored. A deadzone preserves
the last valid facing while idle and ignores teleport-sized position changes.

Animation priority is centralized in `boss3_animation_presentation.gd`:
death/entry, explicit stun, movement-blocking casts, effective locomotion,
locomotion-compatible action poses, eligible idle hit, then idle. Damage always
applies independently. While walking or casting, impact feedback is a short
color overlay and cannot replace the active animation or create hit-stun.
