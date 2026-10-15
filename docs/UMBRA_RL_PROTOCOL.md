# UMBRA RL Protocol 1

The trainer is a development-only Python/PyTorch tool. It is never packaged in
the APK, EXE or Linux build. Godot remains the authoritative simulator and
validates every requested command before applying it.

## Rollout contract

The Python trainer writes a request JSON and launches one headless Godot
process per rollout:

```json
{
  "protocol": "ruptura_umbra_rl",
  "protocol_version": 1,
  "seed": 731,
  "max_steps": 96,
  "step_seconds": 0.16,
  "policy_mode": "model",
  "policy_model": "/absolute/path/to/policy.json"
}
```

Godot returns transitions in this strict order:

```text
observation -> masked action/target/space -> authoritative simulation
            -> reward, done, info
```

Each transition contains 83 normalized observation values, a 23-action mask,
a 3-slot target mask, the validated command, reward, terminal marker and
compact execution information. A deterministic scripted Apolo movement is the
current opponent reference. It is not self-play and must not be described as a
human-play evaluation.

The target and spatial parameters are validated and logged, but current UMBRA
abilities do not yet consume their generic parameter contract. PPO therefore
optimizes the real action branch now; a future executor task must bind target
and space to concrete abilities before reporting those heads as trained.

## Model/checkpoint contract

`tools/train_umbra_ppo.py` exports the exact
`ruptura_umbra_multihead_policy@1` JSON contract accepted by
`RTUmbraMultiheadPolicy`: encoder, explicit GRU gates, action/target/spatial
heads, value head, FP32 tensors and SHA-256 tensor integrity. Training
checkpoints (`.pt`) include model, optimizer, update index, seed and contract;
they are not game artifacts.

The trainer first asks Godot to dump the live observation/action contract, so
Python does not hardcode the 83-feature ordering. It refuses resume when that
contract differs.

## Commands

```bash
# Protocol-only rollout smoke; does not require PyTorch.
python3 tools/umbra_rl_protocol_smoke.py --godot godot

# Tiny real PPO run after installing PyTorch in the development environment.
python3 tools/train_umbra_ppo.py --godot godot --updates 1 --episodes-per-update 2 --max-steps 24 --workers 2 --out artifacts/umbra_rl

# Resume training and export a game-model JSON.
python3 tools/train_umbra_ppo.py --godot godot --resume path/to/checkpoint.pt --updates 10 --out artifacts/umbra_rl

# Evaluation never changes optimizer or checkpoint state.
python3 tools/train_umbra_ppo.py --godot godot --evaluate path/to/checkpoint.pt --episodes 8 --workers 2
```

DQN v1 and `tools/umbra_selfplay_train.gd` remain baseline/reference paths.
They are neither overwritten nor silently promoted by PPO training.

## Curriculum and reward

`tools/config/umbra_rl_curriculum_v1.json` is the sole source for curriculum
and reward versions. It has three training stages: foundation, adaptation and
pressure. Together they vary manifestations, spectra, card-count profiles,
player durability/damage/speed, movement patterns, seeds and safe encounter
pressure. Multiplayer is intentionally deferred; these are single-player
episodes until target selection and remote-player execution are causal.

The principal reward is outcome only: `+1` when UMBRA eliminates Apolo, `-1`
when UMBRA is eliminated, and `0` on timeout. Shaping is deliberately capped
and subordinate: actual player damage gives a small positive signal, damage to
UMBRA is a small negative signal, and a tiny step cost discourages endless
stalling. Repeating a command with no real effect and long no-effect streaks
are penalized only after their configured windows. There is no reward for raw
action count, hidden damage, removing telegraphs or bypassing cooldowns.

Held-out scenarios use different IDs and manifestations than training stages.
The trainer never selects them during updates; it writes
`generalization_report.json` after each update and in standalone evaluation.
The report includes reward decomposition, outcomes, action use, ineffective
repetition and passivity markers per scenario.

After each PPO update, the trainer also writes a separately seeded report from
the existing `umbra_selfplay_train.gd` heuristic reference. It is a comparison
signal only, never PPO experience or a source of gradients. Disable it only
for a narrow local iteration with `--no-selfplay-reference`; it should remain
enabled for runs whose metrics will be compared.

```bash
# Curriculum, reward cap and anti-repeat smoke; does not require PyTorch.
python3 tools/umbra_rl_curriculum_smoke.py --godot godot
```
