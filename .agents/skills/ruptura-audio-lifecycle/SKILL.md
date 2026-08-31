---
name: ruptura-audio-lifecycle
description: Use for Ruptura Temporal menu music, phase playlist rotation, looping boss/weather audio, SFX volume, stereo/mono behavior, and sound asset regressions.
---

# Ruptura Audio Lifecycle

Use this skill when music keeps playing in the wrong screen, phase tracks do not rotate, `Sounds/` assets are not called, boss/weather loops persist after death, or an ability SFX is too loud.

## Control Points

Search first instead of reading large files:

```powershell
rg -n "music_player|menu_music|_play_phase_music_random|_on_music_finished|_stop_battle_music|_update_audio_volumes|audio_streams|_play_sfx|nevasca|prismatica|racional|Sounds|Fases" scripts tests -g "*.gd"
```

In `scripts/main.gd`, keep these lifecycle separations clear:

- Menu music belongs to menu/update screens and must stop before entering gameplay unless the current code explicitly crossfades.
- Phase music is selected by `_shared_phase_music_tracks()`, `_phase_music_tracks(phase)`, `_play_phase_music_random()`, and `_on_music_finished()`.
- Looping boss/weather/ultimate sounds need explicit stop calls on death, phase transition, boss reset, pause/menu transition, and game-over.
- SFX should be event-gated. Do not prove an audio fix by asset presence alone.
- Stereo/mono behavior matters; SFX using `AudioStreamPlayer2D` may pan in stereo and should be centered in mono.

## Asset Portability

- Verify sound files are tracked or intentionally generated: `git ls-files Sounds assets | rg "\.(mp3|ogg|wav|import)$"`.
- If a file exists locally but not in Git, check `.gitignore` before assuming export includes it.
- Do not rely on `.import` files alone as proof that the actual audio asset will travel to another machine.

## Focused Validation

Use the smallest smoke that exercises the event:

- `tests/audio_lifecycle_smoke.gd`
- `tests/sounds_playlist_crossfade_smoke.gd`
- `tests/audio_spatial_mix_smoke.gd`
- `tests/boss2_freeze_wind_audio_smoke.gd`
- A targeted phase/boss smoke when a specific loop or transition is affected

After code changes that touch shared audio state, run the deep validator and inspect logs for warnings that indicate missing resources or orphaned audio nodes.
