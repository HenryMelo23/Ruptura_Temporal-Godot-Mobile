class_name RTPlayerRunLevelController
extends RefCounted

# Run-only progression.  These values are intentionally queried at calculation
# time, rather than added to player_damage/player_defense, so saves cannot
# compound them and cards retain their authored values.
const MAX_LEVEL := 10
# The run level is a long-horizon progression layer, not an opening burst.
# Level 2 now costs 50 common enemies and level 4 costs 250 common enemies
# cumulatively, while the reward and benefit values below remain unchanged.
const XP_THRESHOLDS: Array[int] = [500, 800, 1200, 1750, 2500, 3500, 4800, 6500, 8500]
const XP_COMMON := 10
const XP_ELITE := 25
const XP_MINIBOSS := 90
const XP_BOSS := 180
const DAMAGE_PER_LEVEL := 0.01
const RANGE_PER_LEVEL := 5.0
const MITIGATION_PER_LEVEL := 0.004

var core: Node


func configure(runtime_core: Node) -> void:
	core = runtime_core


func reset() -> void:
	core.player_run_level = 1
	core.player_run_xp = 0


func normalize() -> void:
	core.player_run_level = clampi(int(core.player_run_level), 1, MAX_LEVEL)
	core.player_run_xp = maxi(0, int(core.player_run_xp))
	if core.player_run_level >= MAX_LEVEL:
		core.player_run_xp = 0
		return
	# Old/corrupted snapshots are folded into the same per-level representation.
	while core.player_run_level < MAX_LEVEL and core.player_run_xp >= xp_to_next():
		core.player_run_xp -= xp_to_next()
		core.player_run_level += 1
	if core.player_run_level >= MAX_LEVEL:
		core.player_run_xp = 0


func xp_to_next() -> int:
	if int(core.player_run_level) >= MAX_LEVEL:
		return 0
	return XP_THRESHOLDS[clampi(int(core.player_run_level) - 1, 0, XP_THRESHOLDS.size() - 1)]


func grant_confirmed_enemy(enemy: Dictionary) -> int:
	if core.is_multiplayer and not core._is_world_authority():
		return 0
	return grant_xp(classify_enemy(enemy))


func grant_confirmed_miniboss() -> int:
	if core.is_multiplayer and not core._is_world_authority():
		return 0
	return grant_xp(XP_MINIBOSS)


func grant_confirmed_boss() -> int:
	if core.is_multiplayer and not core._is_world_authority():
		return 0
	return grant_xp(XP_BOSS)


func classify_enemy(enemy: Dictionary) -> int:
	if bool(enemy.get("skip_rewards", false)) or bool(enemy.get("aguilhao_nodule", false)) or bool(enemy.get("eco_vinculado", false)):
		return 0
	var enemy_type := String(enemy.get("type", core.ENEMY_COMMON))
	if bool(enemy.get("mini_boss", false)) or bool(enemy.get("is_mini_boss", false)) or bool(enemy.get("is_event_enemy", false)) or enemy_type == core.ENEMY_LARAPIO:
		return XP_MINIBOSS
	if bool(enemy.get("elite", false)) or bool(enemy.get("is_elite", false)) or enemy_type != core.ENEMY_COMMON:
		return XP_ELITE
	return XP_COMMON


func grant_xp(amount: int) -> int:
	if amount <= 0 or int(core.player_run_level) >= MAX_LEVEL:
		return 0
	core.player_run_xp += amount
	var gained := 0
	while int(core.player_run_level) < MAX_LEVEL and core.player_run_xp >= xp_to_next():
		core.player_run_xp -= xp_to_next()
		core.player_run_level += 1
		gained += 1
		_show_level_up(int(core.player_run_level))
	if int(core.player_run_level) >= MAX_LEVEL:
		core.player_run_xp = 0
	return gained


func _show_level_up(level: int) -> void:
	if String(core.active_character_key) != String(core.CHARACTER_GEOVANA):
		core._add_text("NIVEL %d" % level, core.player_pos + Vector2(0, -108), Color(0.25, 0.92, 1.0), 0.72, 20)
		return
	core.effects.append({
		"kind": "geovana_level_up",
		"level": level,
		"text": "",
		"pos": core.player_pos,
		"life": 1.15,
		"max": 1.15,
		"color": Color(0.24, 0.94, 1.0),
		"size": 1.0
	})


func apply_remote(level: int, xp: int) -> void:
	core.player_run_level = level
	core.player_run_xp = xp
	normalize()


func damage_multiplier() -> float:
	return 1.0 + float(maxi(0, int(core.player_run_level) - 1)) * DAMAGE_PER_LEVEL


func auto_attack_range_bonus() -> float:
	return float(maxi(0, int(core.player_run_level) - 1)) * RANGE_PER_LEVEL


func received_damage_multiplier() -> float:
	return 1.0 - float(maxi(0, int(core.player_run_level) - 1)) * MITIGATION_PER_LEVEL
