---
name: godot-sprite-frame-quality
description: Create or revise Godot character sprite frames with strict in-game scale, crop, continuity, identity, and animation-fluidity checks. Use for new movement, attack, damage, dance, transformation, entrance, exit, or directional sprite sequences; especially for Geovana or Henry.
---

# Godot Sprite Frame Quality

Use this skill only for frames requested now. Do not retrofit or alter previously
created animations unless the user explicitly places them in scope.

## Establish the visual contract first

Before generating or editing frames:

1. Find the exact runtime animation owner, texture-loading contract, canvas size,
   draw profile, anchor, and a visual test that renders the sprite in the game.
2. Record the required frame count only when the user sets a maximum. Otherwise,
   treat the count as flexible and add anticipation, contact, recovery, or
   in-between frames when they materially remove a visual jump.
3. Choose the nearest canonical animation as the scale reference. For Geovana or
   Henry, always inspect and use their actual base sprite files as image
   references. A text-only description is not an identity reference.
4. Record the non-negotiable identity cues: head-to-feet height, head and torso
   proportions, limb thickness, silhouette, palette, hair, eyes, clothing,
   accessories, damage state, and requested costume changes.

Do not infer correctness from equal canvas dimensions. Transparent padding and
the visible alpha bounds determine the perceived in-game size.

## Author frames on a stable coordinate system

- Use one canonical canvas size for frames in the same animation contract unless
  the runtime explicitly supports mixed sizes.
- Keep the foot/contact baseline and body center stable. Document intentional
  displacement such as jumps, recoil, squash, or camera-facing perspective.
- Preserve pixel density and hard pixel edges. Do not hide proportion changes by
  resampling each frame independently to fill the canvas.
- Preserve the requested colors and outfit details in every frame, including
  directional and transitional frames.
- Keep every required part inside the source image with transparent margin. A
  sprite entering or leaving the viewport may be screen-clipped by motion, but
  its source frame must still contain the complete authored silhouette.
- When ImageGen is used, provide the base character sprite as the identity and
  proportion reference, then normalize and audit the result before integration.

For layered entrances or transformations, prefer separate character and effect
layers when that keeps character scale stable. Use foreground masks or shared
contact frames so the layers visibly intersect; never allow the character to
teleport between an empty effect frame and the final pose.

## Mandatory source-frame audit

Run `scripts/audit_sprite_frames.py` on every new or changed sequence. Supply the
expected canvas and the canonical base frame whenever applicable. Example:

```bash
python3 .agents/skills/godot-sprite-frame-quality/scripts/audit_sprite_frames.py \
  assets/sprites/player/skin/fire/*.png \
  --expected-size 312x312 \
  --base assets/sprites/player/skin/idle/idle_0.png \
  --edge-margin 2 \
  --max-height-drift 0.05
```

Treat its output as a diagnostic, not the final visual verdict:

- Wrong canvas dimensions are a failure.
- Any non-transparent pixel touching the forbidden edge margin is a crop failure
  unless that exact edge contact is part of a reviewed tiling contract.
- Inspect every reported connected component. Confirm that small islands are
  intentional particles, slime, hair, weapons, or accessories—not a detached
  fragment from another sprite or a cropped remnant from a generated sheet.
- Compare visible alpha-bound height to the base. Keep ordinary Geovana/Henry
  body-height drift within 5% unless the pose intentionally squashes, stretches,
  crouches, jumps, or changes perspective. Judge those exceptions against the
  adjacent contact frames, not against canvas size alone.
- Reject an image if any limb, hair tip, weapon, effect, jaw, tail, clothing
  piece, or shadow is cut off or mysteriously appears as a disconnected remnant.

## Mandatory animation and in-game validation

Do not call the work complete after inspecting isolated PNGs.

1. Build a contact sheet showing every frame at identical scale, first on a
   contrasting solid background and then at integer zoom. Inspect silhouette,
   outfit, palette, anchors, disconnected pieces, and edge clearance.
2. Preview the frames in order at the intended runtime timing. Inspect the loop
   and the transition into and out of neighboring states. Add frames when motion
   pops, teleports, reverses abruptly, or leaves an unexplained empty interval,
   unless the user explicitly capped the frame count.
3. Render the sequence through the actual Godot draw path at the target gameplay
   resolution. Capture comparable states with the character at the same world
   position and camera.
4. For Geovana or Henry, place idle/walk beside every attack or special pose and
   compare the visible head-to-feet height, head size, torso width, limb length,
   colors, hair, and clothing. Compensate runtime draw height only when the source
   canvases legitimately contain different amounts of transparent padding.
5. For entrances and exits, capture at least: fully outside, first visible,
   approach, contact, primary reveal, separation/recovery, and final gameplay
   pose. The source art must be complete even in frames intentionally moving
   beyond the viewport.
6. Review the screenshots or animation preview yourself. A passing script or
   successful export is not visual evidence.

If any comparison shows scale pulsing, body-proportion drift, palette/costume
loss, clipping, a stray component, or an incomplete transition, iterate on the
assets or draw profile and repeat both the source audit and in-game capture.

## Completion evidence

Report the changed frame paths, canonical base used, source-audit result,
in-game resolutions checked, and any state or platform not exercised. Do not
claim fluidity without an ordered preview or multiple consecutive captures, and
do not claim proportional consistency from canvas dimensions alone.
