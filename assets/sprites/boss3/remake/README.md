# Pai-Rato animation remake

Runtime frames use a fixed 256 x 256 transparent canvas and a shared bottom-center pivot. The game keeps the historical 184 x 170 draw box, so collision and gameplay scale do not change.

Visual direction: diseased liturgical authority. The amber wax skull-mask is the primary read; hands and tail carry secondary motion. Near-black plum cloth, acid-green faith/miasma accents, muted pink flesh and cream highlights keep the silhouette readable over the active phase 3 arena at `assets/maps/calm/phase_3.png`.

Animation sets:

- idle 6, walk 8, entry 8;
- rat spit 6, tail 6, rain 6;
- cheese ritual 8, consume 6, faith 7;
- sector ritual 8, miasma 7;
- hit 3, stun 5, death 10.

The `source/` directory preserves the generated concept and source atlases. Runtime uses only the sliced animation directories. Legacy `Boss3_*.png` and `Bossandando3_*.png` remain as compatibility fallbacks.
