# Pixel Animation Craft

## Web Inspiration References

- Pedro Medeiros / Saint11 pixel-art tutorial archive: https://saint11.art/blog/pixel-art-tutorials/
- Lospec animation tutorial index: https://lospec.com/pixel-art-tutorials/tags/animation
- 12 principles for game animation: https://www.gamedeveloper.com/game-platforms/12-principles-for-game-animation
- 5 tips for making great animations for 2D games: https://www.gamedeveloper.com/art/5-tips-for-making-great-animations-for-2d-games
- Smear frame overview: https://www.bloopanimation.com/the-art-of-smear-frames/

Use these as technique inspiration, not as assets to copy.

## Make It Feel Alive

A strong pixel animation usually has:

- A readable silhouette before detail.
- Uneven timing: holds, fast frames, recovery, not equal spacing everywhere.
- Anticipation before force.
- A clear impact frame.
- Follow-through after force: cloth, hair, weapon, shadow, dust, aura.
- Smear or stretched in-between for fast motion.
- Secondary particles or residue that explain material.
- A final settled pose, not an abrupt stop.

## Frame Planning

### Idle

- Use 4-8 frames.
- Move chest/head by 1-2 pixels, not the whole sprite uniformly.
- Add small asynchronous motion: coat, hair, eye, hand, aura, weapon tip.
- Keep one frame as a longer hold so it breathes.

### Run / Dash

- Define contact, down, passing, up poses.
- Push the silhouette; make legs/coat/weapon readable.
- Add dust on contact and afterimage on dash.
- Use smears for speed instead of smooth tweening.

### Attack

- Use anticipation, strike, impact hold, recoil, recovery.
- Put the gameplay hit on the strike or first impact hold.
- Add a weapon trail, edge flash, body compression, and particles from the material being struck.
- Make the attack direction readable from the first frame.

### Hurt / Death

- Hurt needs instant readability: flash, recoil, deformation, and short invulnerability language.
- Death needs collapse stages and residue. Avoid simply fading out.
- Boss deaths should have phases: destabilize, rupture, fragment, silence.

### UI / Card / Icon

- Use 2-5 frame accents for hover/press/selection.
- Animate border, symbol, material, small particles, and sound timing.
- Keep text stable and readable.

## Detail Layers

Choose 2-4 layers based on cost:

- Sprite frame change.
- One material/shader uniform.
- Small particles/debris.
- Shadow squish or ground mark.
- Trail/afterimage.
- Camera nudge or hit-stop.
- Audio cue.

If everything moves, nothing reads. Give priority to the focal shape and keep background motion quieter.

## Ruptura-Specific Motion Prompts

- Temporal slash: anticipation ring, cyan split-frame duplicate, white impact, delayed echo fragments.
- D37 growth: quiet warning pulse, asymmetric thorn/tendril expansion, green residue, spore drift.
- Western shot: shoulder compression, muzzle snap, dust kick, hard recoil, warm ember trail.
- UMBRA action: predatory stillness, sudden intent shift, delayed shadow, dimensional color read.
- Phase reveal: old image tears/warps away, new image remains visible and stable underneath.

## Anti-Flatness Checklist

Reject the result if:

- Every frame has equal timing.
- The sprite only translates without pose change.
- The effect is a circle, line, or glow with no material language.
- The impact frame is not obvious in a screenshot.
- There is no anticipation or recovery for a strong action.
- Particles use default values.
- Pixel art is blurred by filtering, fractional scale, or uncontrolled rotation.
- The animation hides gameplay or makes hitboxes feel unfair.
