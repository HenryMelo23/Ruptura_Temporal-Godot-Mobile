extends RefCounted

## Full-state perception for laboratory coverage. Not a 42-feature adapter
## for the old Python checkpoint, and not a claim of human-visible information.
const VERSION := 1
const HAZARDS := ["vortex", "siphon", "sopro_artico", "prison", "miasma", "discharge", "thorns", "umbra_overload_laser"]


static func build(game: Node) -> Dictionary:
	var threats: Array = []
	var unknown := 0
	for bullet in game.enemy_bullets:
		var known := String(bullet.get("type", "")) == "umbra_plasma"
		threats.append({"channel": "projectile", "known": known, "data": _json_value(bullet),
			"velocity": _json_value(Vector2(bullet.get("dir", Vector2.ZERO)) * 210.0 * float(bullet.get("speed_mult", 1.0)) * AuraSystem.world_multiplier(game.aura_state))})
		unknown += 0 if known else 1
	for hazard in game.phase5_hazards:
		var known := HAZARDS.has(String(hazard.get("kind", "")))
		threats.append({"channel": "hazard", "known": known, "data": _json_value(hazard)})
		unknown += 0 if known else 1
	for rat in game.phase5_rats:
		threats.append({"channel": "rat", "known": true, "data": _json_value(rat)})
	for telegraph in game.phase5_telegraphs:
		var known: bool = telegraph.has("from") and telegraph.has("to") and telegraph.has("life")
		threats.append({"channel": "teleport", "known": known, "data": _json_value(telegraph)})
		unknown += 0 if known else 1
	var skills = game._umbra_base_skills()
	for eco in skills.ecos:
		threats.append({"channel": "eco", "known": true, "radius": skills.ECO_RADIUS, "data": _json_value(eco)})
	for rewind in skills.rewinds:
		threats.append({"channel": "rewind", "known": true, "escape": "dash_breaks_mark", "data": _json_value(rewind)})
	return {"schema_version": VERSION, "information_mode": "oracle_state_not_human_visibility",
		"world_size": _json_value(game.WORLD_SIZE), "position": _json_value(game.player_pos), "hp": game.player_hp,
		"hp_max": game.player_hp_max, "stunned": game.player_stun_timer > 0.0,
		"statuses": {"burn_stacks": game.player_burn_stacks, "burn_remaining": game.player_burn_timer,
			"freeze_remaining": game.player_freeze_visual_timer, "invulnerable": game._player_invulnerable()},
		"dash_remaining": maxf(0.0, game._current_dash_cooldown() - (game.time_alive - game.last_dash_time)),
		"heal_orbs": _json_value(game.heal_orbs), "threats": threats,
		"unknown_threat_count": unknown, "coverage_complete": unknown == 0}


static func _json_value(value):
	if value is Vector2:
		return [value.x, value.y]
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value:
			result[String(key)] = _json_value(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_json_value(item))
		return result
	if value is float or value is int or value is String or value is bool or value == null:
		return value
	return str(value)
