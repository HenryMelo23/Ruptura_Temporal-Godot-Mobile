# UMBRA model artifacts

`umbra_dqn_weights.json` is the preserved legacy export (22 outputs, no versioned
ABI metadata). It is incompatible with the 23-action runtime contract and must
not be renamed, padded, or relabeled to enable it.

`umbra_dqn_2_0_actions_23.json` is the model the game loads (24 -> 128 -> 64 -> 23,
LeakyReLU 0.01, versioned `ruptura_neural_model@1` with SHA-256 tensor integrity).
It is only shipped when it was genuinely trained and passed the paired evaluation
below. No fabricated or padded weights.

## How it is produced (no PyTorch needed)
1. Transitions from the real phase 5 simulator, headless, against the Apolo bot:
   `godot --headless --path . --script res://tools/umbra_dqn_collect.gd -- --episodes=12 --seconds=50 --epsilon=0.35 --seed=N --out=res://.agent_logs/umbra_dqn/x_N.jsonl`
   Each UMBRA decision is `(s, legal mask, a, r, s', mask', done)`, where `s` is
   `_umbra_discretizar_estado()` (the exact network input) and
   `r = 10*(damage dealt / player max HP) - 30*(damage taken / UMBRA max HP)` until the next decision.
2. Offline Double DQN with a conservative (CQL-lite) penalty and legal-action masks, numpy only:
   `python3 tools/umbra_dqn_train.py ".agent_logs/umbra_dqn/*.jsonl" --out .agent_logs/umbra_dqn/dqn_net.json`
3. Versioned export: `python3 tools/export_umbra_weights.py --from-json .agent_logs/umbra_dqn/dqn_net.json`
4. Paired evaluation (same seeds, epsilon 0): run the collector with `--dqn=res://assets/weights/umbra_dqn_2_0_actions_23.json`
   and without it, then compare the mean score, damage dealt and damage taken per episode.

The opponent is the scripted Apolo bot, not a human. A better score against it is
not evidence about human play.

## Current shipped model (2026-11-17)
Round 2: 180 episodes of scripted-policy data plus on-policy data collected with the
round-1 model, then `umbra_dqn_train.py --steps 40000 --reward_scale 3 --cql 0.3 --seed 21`.
Paired evaluation over 96 episodes (same seeds, epsilon 0, `tools/umbra_dqn_compare.py`):

| model | score diff vs. no net | 95% CI | episodes where it did better |
|---|---|---|---|
| r2 (shipped) | +0.03 | [-0.44, +0.50] | 45/96 |
| s3 (round 1) | -0.06 | [-0.52, +0.40] | 42/96 |

So the shipped model is a statistical TIE with the heuristic. Its Q-values are added
to the heuristic scores in `_umbra_choose_action`. It is not a measurable gain yet.
Raw outputs are in `.agent_logs/umbra_dqn/cmp_*_96.txt`.
