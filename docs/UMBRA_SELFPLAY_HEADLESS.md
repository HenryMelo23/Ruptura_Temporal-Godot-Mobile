# UMBRA Headless Self-Play

This lab runs APOLO and UMBRA against each other without loading the main scene. It is meant to train and validate the boss mind with the same combat categories the player brings into phase 5: cards, manifestation, spectrum, movement, projectiles, hazards, transmutation, cooldowns, and survival rewards.

Run a quick local generation batch:

```powershell
& "C:\Users\Usuario\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "." --script res://tools/umbra_selfplay_train.gd -- --episodes=64 --max-steps=1800 --seed=7705 --out=user://umbra_selfplay
```

Useful options:

- `--episodes=256` or `--generations=256`: number of self-play matches.
- `--max-steps=1800`: maximum simulation steps per match.
- `--seed=7705`: deterministic seed for reproducible batches.
- `--manifestation=eletrica`: force a player manifestation profile.
- `--spectrum=racional`: force a spectrum profile.
- `--out=user://umbra_selfplay`: output directory.

The runner writes:

- `umbra_selfplay_report.json`: compact summary and win/reward balance.
- `umbra_selfplay_memory.json`: UMBRA action memory, scenario memory, and anti-aliasing feature contract.
- `umbra_selfplay_episodes.json`: per-episode reports for audit and leaderboard/server ingestion later.

Current scope:

- This first lab produces a deterministic heuristic memory, not gradient-trained neural weights.
- It is isolated from player saves and from the weekly UMBRA updater.
- The next bridge should convert the memory into the same lightweight mind files consumed by phase 5, then let the weekly updater ship only those mind files.
