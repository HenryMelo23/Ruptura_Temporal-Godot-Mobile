---
name: godot-game-balancing
description: Use for gameplay balance, damage, cooldowns, scaling curves, economy, roguelike progression, and boss tuning.
---

# Godot Game Balancing

Balance changes require identifying the current formula, affected manifestations/cards/enemies, target player experience, and test coverage.

Prefer explicit multipliers and named constants. Avoid hidden magic changes. When changing damage/cooldown/duration, add or update focused smoke tests that assert the new values or behavior.
