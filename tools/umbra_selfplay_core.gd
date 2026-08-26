extends RefCounted

const WORLD_SIZE: Vector2 = Vector2(1280.0, 720.0)
const ARENA_CENTER: Vector2 = WORLD_SIZE * 0.5
const DT: float = 1.0 / 30.0
const PLAYER_RADIUS: float = 18.0
const UMBRA_RADIUS: float = 24.0
const PROJECTILE_RADIUS: float = 10.0
const MAX_THREAT_SLOTS: int = 6
const MAX_HISTORY: int = 24
const SELFPLAY_SCHEMA_VERSION: int = 1

const UMBRA_ACTIONS: Array[String] = [
	"FUGIR",
	"INTERCEPTAR",
	"ORBITAR",
	"CERCAR",
	"ATAQUE",
	"SIFON",
	"TELEPORTE",
	"TELEPORTE_JUKE",
	"TRANSMUTAR_VORTICE",
	"TRANSMUTAR_GRAVIDADE",
	"TRANSMUTAR_NECROSE",
	"TRANSMUTAR_RESSONANCIA",
	"TRANSMUTAR_HEMORRAGIA",
	"TRANSMUTAR_ATRITO",
	"TRANSMUTAR_RASTRO",
	"VORTICE",
	"PRISAO",
	"MIASMA",
	"DESCARGA_ELETRICA",
	"PRAGA_RATOS",
	"LASER_SOBRECARGA",
	"CAMINHO_ESPINHOS",
	"NENHUMA"
]

const APOLO_ACTIONS: Array[String] = [
	"MOVER",
	"DASH",
	"ATIRAR",
	"USAR_MANIFESTACAO",
	"BUSCAR_CENTRO",
	"QUEBRAR_DISTANCIA",
	"FORCAR_DANO",
	"RECUAR",
	"AGUARDAR"
]

const ANTI_ALIASING_FEATURES: Array[String] = [
	"self_position",
	"self_velocity",
	"enemy_position",
	"enemy_velocity",
	"health_ratio",
	"enemy_health_ratio",
	"distance_to_enemy",
	"edge_distance",
	"corner_pressure",
	"center_distance",
	"cooldowns",
	"manifestation",
	"spectrum",
	"cards",
	"known_enemy_actions",
	"incoming_projectiles",
	"telegraphed_hazards",
	"active_dimension",
	"last_damage_source",
	"last_action_result",
	"recent_motion"
]


func run_training(options: Dictionary = {}) -> Dictionary:
	var episodes: int = max(1, int(options.get("episodes", 64)))
	var max_steps: int = max(60, int(options.get("max_steps", 1800)))
	var seed: int = int(options.get("seed", 7705))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var memory: Dictionary = _initial_memory(seed)
	var episode_rows: Array = []
	var winners: Dictionary = {"UMBRA": 0, "APOLO": 0, "DRAW": 0}
	var total_umbra_reward: float = 0.0
	var total_apolo_reward: float = 0.0
	var best_episode: Dictionary = {}
	for episode_index in range(episodes):
		var scenario: Dictionary = _scenario_for_episode(episode_index, rng, options)
		var result: Dictionary = _run_episode(episode_index, scenario, memory, rng, max_steps)
		episode_rows.append(_episode_report_row(result))
		var winner: String = String(result.get("winner", "DRAW"))
		winners[winner] = int(winners.get(winner, 0)) + 1
		total_umbra_reward += float(result.get("umbra_reward", 0.0))
		total_apolo_reward += float(result.get("apolo_reward", 0.0))
		_update_memory_from_episode(memory, result)
		if best_episode.is_empty() or float(result.get("umbra_reward", 0.0)) > float(best_episode.get("umbra_reward", -999999.0)):
			best_episode = result
	var summary: Dictionary = {
		"episodes": episodes,
		"max_steps": max_steps,
		"seed": seed,
		"winners": winners,
		"umbra_average_reward": snappedf(total_umbra_reward / float(episodes), 0.001),
		"apolo_average_reward": snappedf(total_apolo_reward / float(episodes), 0.001),
		"anti_aliasing_features": ANTI_ALIASING_FEATURES.duplicate(),
		"best_episode": _episode_report_row(best_episode)
	}
	memory["summary"] = summary
	memory["trained_episodes"] = int(memory.get("trained_episodes", 0))
	memory["updated_unix"] = int(Time.get_unix_time_from_system())
	return {
		"ok": true,
		"schema_version": SELFPLAY_SCHEMA_VERSION,
		"summary": summary,
		"memory": memory,
		"episodes": episode_rows
	}


func _initial_memory(seed: int) -> Dictionary:
	var action_memory: Dictionary = {}
	for action in UMBRA_ACTIONS:
		action_memory[action] = {
			"score": 0.0,
			"uses": 0,
			"hits": 0,
			"misses": 0,
			"damage": 0.0,
			"reward": 0.0
		}
	return {
		"schema_version": SELFPLAY_SCHEMA_VERSION,
		"source": "godot_headless_selfplay",
		"seed": seed,
		"trained_episodes": 0,
		"actions": action_memory,
		"scenarios": {},
		"anti_aliasing_features": ANTI_ALIASING_FEATURES.duplicate()
	}


func _scenario_for_episode(index: int, rng: RandomNumberGenerator, options: Dictionary) -> Dictionary:
	var requested_manifestation: String = String(options.get("manifestation", "")).to_lower()
	var requested_spectrum: String = String(options.get("spectrum", "")).to_lower()
	var scenarios: Array[Dictionary] = [
		{
			"id": "eletrica_racional_fase5",
			"manifestation": "eletrica",
			"spectrum": "racional",
			"cards": [{"id": "disparo_crescente", "count": 3}, {"id": "defesa", "count": 2}, {"id": "porcao", "count": 2}],
			"player_hp": 1120.0,
			"player_damage": 88.0,
			"player_speed": 245.0,
			"umbra_hp": 22000.0,
			"difficulty": 1.0
		},
		{
			"id": "lacerante_sanguinaria_fase5",
			"manifestation": "lacerante",
			"spectrum": "sanguinaria",
			"cards": [{"id": "feridas", "count": 4}, {"id": "roubo_vida", "count": 2}, {"id": "speed_boost", "count": 1}],
			"player_hp": 980.0,
			"player_damage": 104.0,
			"player_speed": 255.0,
			"umbra_hp": 22600.0,
			"difficulty": 1.08
		},
		{
			"id": "gravitante_vanguarda_fase5",
			"manifestation": "gravitante",
			"spectrum": "vanguarda",
			"cards": [{"id": "teleporte", "count": 2}, {"id": "resistencia", "count": 3}, {"id": "onda", "count": 2}],
			"player_hp": 1280.0,
			"player_damage": 76.0,
			"player_speed": 228.0,
			"umbra_hp": 23200.0,
			"difficulty": 1.14
		},
		{
			"id": "prismatica_devota_fase5",
			"manifestation": "prismatica",
			"spectrum": "devota",
			"cards": [{"id": "espelho", "count": 2}, {"id": "defesa", "count": 4}, {"id": "sorte", "count": 2}],
			"player_hp": 1400.0,
			"player_damage": 68.0,
			"player_speed": 235.0,
			"umbra_hp": 24000.0,
			"difficulty": 1.18
		},
		{
			"id": "ancorada_impulsiva_fase5",
			"manifestation": "ancorada",
			"spectrum": "impulsiva",
			"cards": [{"id": "ancora", "count": 2}, {"id": "petro", "count": 2}, {"id": "mercenaria", "count": 2}],
			"player_hp": 1180.0,
			"player_damage": 92.0,
			"player_speed": 218.0,
			"umbra_hp": 23600.0,
			"difficulty": 1.12
		}
	]
	var selected: Dictionary = scenarios[index % scenarios.size()].duplicate(true)
	if requested_manifestation != "":
		for scenario in scenarios:
			if String(scenario.get("manifestation", "")) == requested_manifestation:
				selected = scenario.duplicate(true)
				break
	if requested_spectrum != "":
		selected["spectrum"] = requested_spectrum
	selected["seed"] = rng.randi()
	selected["generation"] = index
	selected["cards"] = _mutate_cards(Array(selected.get("cards", [])), rng)
	return selected


func _mutate_cards(cards: Array, rng: RandomNumberGenerator) -> Array:
	var result: Array = []
	for card in cards:
		var row: Dictionary = Dictionary(card).duplicate(true)
		row["count"] = max(1, int(row.get("count", 1)) + rng.randi_range(-1, 1))
		result.append(row)
	if rng.randf() < 0.35:
		var extras: Array[String] = ["porcao", "resistencia", "cooldown", "tempestade_crescente", "poison"]
		result.append({"id": extras[rng.randi_range(0, extras.size() - 1)], "count": rng.randi_range(1, 2)})
	return result


func _run_episode(episode_index: int, scenario: Dictionary, memory: Dictionary, rng: RandomNumberGenerator, max_steps: int) -> Dictionary:
	var state: Dictionary = _initial_episode_state(scenario, rng)
	var umbra_action_stats: Dictionary = {}
	for action in UMBRA_ACTIONS:
		umbra_action_stats[action] = {"uses": 0, "hits": 0, "misses": 0, "damage": 0.0, "reward": 0.0}
	var apolo_action_stats: Dictionary = {}
	for action in APOLO_ACTIONS:
		apolo_action_stats[action] = {"uses": 0, "hits": 0, "misses": 0, "damage": 0.0, "reward": 0.0}
	var winner: String = "DRAW"
	var step: int = 0
	while step < max_steps:
		step += 1
		state["step"] = step
		state["time"] = float(step) * DT
		_update_cooldowns(state, DT)
		var apolo_obs: Dictionary = _observe("APOLO", state, scenario)
		var umbra_obs: Dictionary = _observe("UMBRA", state, scenario)
		var apolo_action: Dictionary = _choose_apolo_action(apolo_obs, scenario, rng)
		var umbra_action: String = _choose_umbra_action(umbra_obs, state, memory, rng)
		_register_action_use(apolo_action_stats, String(apolo_action.get("id", "AGUARDAR")))
		_register_action_use(umbra_action_stats, umbra_action)
		state["last_apolo_action"] = String(apolo_action.get("id", "AGUARDAR"))
		state["last_umbra_action"] = umbra_action
		_apply_apolo_action(state, scenario, apolo_action, apolo_action_stats, rng)
		_apply_umbra_action(state, scenario, umbra_action, umbra_action_stats, rng)
		_update_projectiles(state, scenario, apolo_action_stats, umbra_action_stats)
		_update_hazards(state, scenario, apolo_action_stats, umbra_action_stats)
		_update_rats(state, scenario, umbra_action_stats)
		_record_motion(state)
		state["apolo_reward"] = float(state.get("apolo_reward", 0.0)) + 0.004
		state["umbra_reward"] = float(state.get("umbra_reward", 0.0)) + 0.004
		if float(state.get("player_hp", 0.0)) <= 0.0:
			winner = "UMBRA"
			state["umbra_reward"] = float(state.get("umbra_reward", 0.0)) + 25.0
			state["apolo_reward"] = float(state.get("apolo_reward", 0.0)) - 22.0
			_add_action_reward(umbra_action_stats, umbra_action, 8.0)
			break
		if float(state.get("umbra_hp", 0.0)) <= 0.0:
			winner = "APOLO"
			state["apolo_reward"] = float(state.get("apolo_reward", 0.0)) + 25.0
			state["umbra_reward"] = float(state.get("umbra_reward", 0.0)) - 22.0
			_add_action_reward(apolo_action_stats, String(apolo_action.get("id", "AGUARDAR")), 8.0)
			break
	if winner == "DRAW":
		if float(state.get("umbra_hp", 0.0)) / float(state.get("umbra_hp_max", 1.0)) > float(state.get("player_hp", 0.0)) / float(state.get("player_hp_max", 1.0)):
			state["umbra_reward"] = float(state.get("umbra_reward", 0.0)) + 4.0
		else:
			state["apolo_reward"] = float(state.get("apolo_reward", 0.0)) + 4.0
	return {
		"episode": episode_index,
		"scenario": scenario,
		"steps": step,
		"duration_seconds": snappedf(float(step) * DT, 0.01),
		"winner": winner,
		"umbra_reward": snappedf(float(state.get("umbra_reward", 0.0)), 0.001),
		"apolo_reward": snappedf(float(state.get("apolo_reward", 0.0)), 0.001),
		"umbra_hp_ratio": snappedf(float(state.get("umbra_hp", 0.0)) / maxf(1.0, float(state.get("umbra_hp_max", 1.0))), 0.0001),
		"apolo_hp_ratio": snappedf(float(state.get("player_hp", 0.0)) / maxf(1.0, float(state.get("player_hp_max", 1.0))), 0.0001),
		"umbra_actions": umbra_action_stats,
		"apolo_actions": apolo_action_stats,
		"last_observation": {
			"apolo": _observe("APOLO", state, scenario),
			"umbra": _observe("UMBRA", state, scenario)
		}
	}


func _initial_episode_state(scenario: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var player_hp_max: float = float(scenario.get("player_hp", 1000.0)) + _card_count(scenario, "defesa") * 45.0 + _card_count(scenario, "resistencia") * 35.0
	var umbra_hp_max: float = float(scenario.get("umbra_hp", 22000.0))
	return {
		"player_pos": Vector2(ARENA_CENTER.x - 240.0 + rng.randf_range(-80.0, 80.0), ARENA_CENTER.y + rng.randf_range(-90.0, 90.0)),
		"player_vel": Vector2.ZERO,
		"umbra_pos": Vector2(ARENA_CENTER.x + 245.0 + rng.randf_range(-90.0, 90.0), ARENA_CENTER.y + rng.randf_range(-110.0, 110.0)),
		"umbra_vel": Vector2.ZERO,
		"player_hp": player_hp_max,
		"player_hp_max": player_hp_max,
		"umbra_hp": umbra_hp_max,
		"umbra_hp_max": umbra_hp_max,
		"scenario": scenario.duplicate(true),
		"player_dash_cd": 0.0,
		"player_manifest_cd": 0.0,
		"umbra_cooldowns": {},
		"umbra_dimension": "base",
		"umbra_dimension_timer": 0.0,
		"projectiles": [],
		"hazards": [],
		"rats": [],
		"apolo_reward": 0.0,
		"umbra_reward": 0.0,
		"last_damage_source_apolo": "",
		"last_damage_source_umbra": "",
		"last_apolo_action": "",
		"last_umbra_action": "",
		"player_history": [],
		"umbra_history": [],
		"step": 0,
		"time": 0.0
	}


func _observe(actor: String, state: Dictionary, scenario: Dictionary) -> Dictionary:
	var self_pos: Vector2 = Vector2(state["player_pos"]) if actor == "APOLO" else Vector2(state["umbra_pos"])
	var enemy_pos: Vector2 = Vector2(state["umbra_pos"]) if actor == "APOLO" else Vector2(state["player_pos"])
	var self_vel: Vector2 = Vector2(state["player_vel"]) if actor == "APOLO" else Vector2(state["umbra_vel"])
	var enemy_vel: Vector2 = Vector2(state["umbra_vel"]) if actor == "APOLO" else Vector2(state["player_vel"])
	var self_hp: float = float(state["player_hp"]) if actor == "APOLO" else float(state["umbra_hp"])
	var self_hp_max: float = float(state["player_hp_max"]) if actor == "APOLO" else float(state["umbra_hp_max"])
	var enemy_hp: float = float(state["umbra_hp"]) if actor == "APOLO" else float(state["player_hp"])
	var enemy_hp_max: float = float(state["umbra_hp_max"]) if actor == "APOLO" else float(state["player_hp_max"])
	var distance: float = self_pos.distance_to(enemy_pos)
	return {
		"actor": actor,
		"self_position": _vec_report(self_pos),
		"self_velocity": _vec_report(self_vel),
		"enemy_position": _vec_report(enemy_pos),
		"enemy_velocity": _vec_report(enemy_vel),
		"health_ratio": snappedf(self_hp / maxf(1.0, self_hp_max), 0.0001),
		"enemy_health_ratio": snappedf(enemy_hp / maxf(1.0, enemy_hp_max), 0.0001),
		"distance_to_enemy": snappedf(distance, 0.01),
		"edge_distance": snappedf(_edge_distance(self_pos), 0.01),
		"corner_pressure": snappedf(_corner_pressure(self_pos), 0.0001),
		"center_distance": snappedf(self_pos.distance_to(ARENA_CENTER), 0.01),
		"cooldowns": _cooldown_report(actor, state),
		"manifestation": String(scenario.get("manifestation", "")),
		"spectrum": String(scenario.get("spectrum", "")),
		"cards": Array(scenario.get("cards", [])).duplicate(true),
		"known_enemy_actions": UMBRA_ACTIONS.duplicate() if actor == "APOLO" else APOLO_ACTIONS.duplicate(),
		"incoming_projectiles": _incoming_projectiles(actor, state),
		"telegraphed_hazards": _telegraphed_hazards(actor, state),
		"active_dimension": String(state.get("umbra_dimension", "base")),
		"last_damage_source": String(state.get("last_damage_source_apolo", "")) if actor == "APOLO" else String(state.get("last_damage_source_umbra", "")),
		"last_action_result": _last_action_result(actor, state),
		"recent_motion": _recent_motion(actor, state)
	}


func _choose_apolo_action(obs: Dictionary, scenario: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var self_pos: Vector2 = _vec_from_report(Dictionary(obs.get("self_position", {})))
	var enemy_pos: Vector2 = _vec_from_report(Dictionary(obs.get("enemy_position", {})))
	var threat_dir: Vector2 = _combined_threat_escape(obs, self_pos)
	var health_ratio: float = float(obs.get("health_ratio", 1.0))
	var manifest_cd: float = float(Dictionary(obs.get("cooldowns", {})).get("manifestation", 0.0))
	var dash_cd: float = float(Dictionary(obs.get("cooldowns", {})).get("dash", 0.0))
	var distance: float = float(obs.get("distance_to_enemy", 0.0))
	if threat_dir.length() > 0.25:
		if dash_cd <= 0.0 and rng.randf() < 0.56:
			return {"id": "DASH", "move": threat_dir.normalized()}
		return {"id": "MOVER", "move": threat_dir.normalized()}
	if health_ratio < 0.32 and _card_count(scenario, "porcao") > 0 and manifest_cd <= 0.0:
		return {"id": "USAR_MANIFESTACAO", "move": (self_pos - enemy_pos).normalized()}
	if manifest_cd <= 0.0 and rng.randf() < _manifest_use_chance(String(scenario.get("manifestation", "")), distance):
		return {"id": "USAR_MANIFESTACAO", "move": (enemy_pos - self_pos).normalized()}
	if distance > 560.0:
		return {"id": "QUEBRAR_DISTANCIA", "move": (enemy_pos - self_pos).normalized()}
	if distance < 150.0:
		return {"id": "RECUAR", "move": (self_pos - enemy_pos).normalized()}
	if rng.randf() < 0.68:
		return {"id": "ATIRAR", "move": _orbit_dir(self_pos, enemy_pos, rng)}
	return {"id": "MOVER", "move": _orbit_dir(self_pos, enemy_pos, rng)}


func _choose_umbra_action(obs: Dictionary, state: Dictionary, memory: Dictionary, rng: RandomNumberGenerator) -> String:
	var available: Array[String] = _umbra_available_actions(state)
	var self_pos: Vector2 = _vec_from_report(Dictionary(obs.get("self_position", {})))
	var enemy_pos: Vector2 = _vec_from_report(Dictionary(obs.get("enemy_position", {})))
	var distance: float = float(obs.get("distance_to_enemy", 0.0))
	var enemy_edge: float = _edge_distance(enemy_pos)
	var health_ratio: float = float(obs.get("health_ratio", 1.0))
	var pressure: Dictionary = {}
	for action in available:
		var score: float = float(Dictionary(memory.get("actions", {})).get(action, {}).get("score", 0.0))
		score += rng.randf_range(-0.08, 0.08)
		match action:
			"FUGIR":
				score += 0.9 if distance < 150.0 or health_ratio < 0.28 else -0.2
			"INTERCEPTAR":
				score += 0.45 if distance > 260.0 else 0.1
			"ORBITAR":
				score += 0.16
			"CERCAR":
				score += 0.55 if enemy_edge < 155.0 else 0.05
			"ATAQUE":
				score += 0.55 if distance < 720.0 else -0.25
			"SIFON":
				score += 1.05 if health_ratio < 0.6 and distance < 260.0 else -0.35
			"TELEPORTE", "TELEPORTE_JUKE":
				score += 0.48 if distance < 170.0 or enemy_edge < 135.0 else 0.05
			"VORTICE":
				score += 0.72 if enemy_pos.distance_to(ARENA_CENTER) < 330.0 else -0.15
			"PRISAO":
				score += 0.82 if _recent_motion_speed("APOLO", state) > 130.0 else 0.08
			"MIASMA":
				score += 0.58 if distance < 420.0 else -0.1
			"DESCARGA_ELETRICA":
				score += 0.7 if distance < 620.0 else -0.1
			"PRAGA_RATOS":
				score += 0.46 if distance > 240.0 else 0.05
			"LASER_SOBRECARGA":
				score += 1.0 if enemy_edge < 230.0 or distance > 360.0 else 0.15
			"CAMINHO_ESPINHOS":
				score += 0.66 if _recent_motion_speed("APOLO", state) > 95.0 else 0.05
			_:
				if action.begins_with("TRANSMUTAR_"):
					score += 0.28 if String(state.get("umbra_dimension", "base")) == "base" else -0.35
		pressure[action] = score
	var best_action: String = "NENHUMA"
	var best_score: float = -999999.0
	for action in pressure.keys():
		var value: float = float(pressure[action])
		if value > best_score:
			best_score = value
			best_action = String(action)
	return best_action


func _umbra_available_actions(state: Dictionary) -> Array[String]:
	var cooldowns: Dictionary = Dictionary(state.get("umbra_cooldowns", {}))
	var dimension: String = String(state.get("umbra_dimension", "base"))
	var available: Array[String] = ["FUGIR", "INTERCEPTAR", "ORBITAR", "CERCAR", "ATAQUE", "NENHUMA"]
	for action in ["SIFON", "TELEPORTE", "TELEPORTE_JUKE", "TRANSMUTAR_VORTICE", "TRANSMUTAR_GRAVIDADE", "TRANSMUTAR_NECROSE", "TRANSMUTAR_RESSONANCIA", "TRANSMUTAR_HEMORRAGIA", "TRANSMUTAR_ATRITO", "TRANSMUTAR_RASTRO"]:
		if float(cooldowns.get(action, 0.0)) <= 0.0:
			available.append(action)
	match dimension:
		"vortice":
			if float(cooldowns.get("VORTICE", 0.0)) <= 0.0:
				available.append("VORTICE")
		"gravidade":
			if float(cooldowns.get("PRISAO", 0.0)) <= 0.0:
				available.append("PRISAO")
		"necrose":
			if float(cooldowns.get("MIASMA", 0.0)) <= 0.0:
				available.append("MIASMA")
		"ressonancia":
			if float(cooldowns.get("DESCARGA_ELETRICA", 0.0)) <= 0.0:
				available.append("DESCARGA_ELETRICA")
		"hemorragia":
			if float(cooldowns.get("CAMINHO_ESPINHOS", 0.0)) <= 0.0:
				available.append("CAMINHO_ESPINHOS")
		"atrito":
			if float(cooldowns.get("LASER_SOBRECARGA", 0.0)) <= 0.0:
				available.append("LASER_SOBRECARGA")
		"rastro":
			if float(cooldowns.get("PRAGA_RATOS", 0.0)) <= 0.0:
				available.append("PRAGA_RATOS")
		_:
			pass
	return available


func _apply_apolo_action(state: Dictionary, scenario: Dictionary, action: Dictionary, stats: Dictionary, rng: RandomNumberGenerator) -> void:
	var action_id: String = String(action.get("id", "AGUARDAR"))
	var old_pos: Vector2 = Vector2(state["player_pos"])
	var pos: Vector2 = old_pos
	var move: Vector2 = Vector2(action.get("move", Vector2.ZERO))
	if move.length() > 1.0:
		move = move.normalized()
	var speed: float = float(scenario.get("player_speed", 240.0)) + _card_count(scenario, "speed_boost") * 10.0
	var dash_cd: float = float(state.get("player_dash_cd", 0.0))
	var manifest_cd: float = float(state.get("player_manifest_cd", 0.0))
	match action_id:
		"DASH":
			if dash_cd <= 0.0:
				pos += move * 118.0
				state["player_dash_cd"] = 1.45
				state["apolo_reward"] = float(state.get("apolo_reward", 0.0)) + 0.2
			else:
				_add_action_reward(stats, action_id, -0.15)
		"ATIRAR", "FORCAR_DANO":
			_spawn_projectile(state, "apolo", pos, Vector2(state["umbra_pos"]), _player_damage(scenario), 590.0, "apolo_shot")
			pos += move * speed * DT * 0.45
		"USAR_MANIFESTACAO":
			if manifest_cd <= 0.0:
				_apply_manifestation_action(state, scenario, stats, rng)
			else:
				_add_action_reward(stats, action_id, -0.2)
		"BUSCAR_CENTRO":
			pos += (ARENA_CENTER - pos).normalized() * speed * DT
		"QUEBRAR_DISTANCIA", "MOVER", "RECUAR":
			pos += move * speed * DT
		_:
			pos += move * speed * DT * 0.3
	var new_pos: Vector2 = _clamp_pos(pos)
	state["player_pos"] = new_pos
	state["player_vel"] = (new_pos - old_pos) / DT


func _apply_manifestation_action(state: Dictionary, scenario: Dictionary, stats: Dictionary, rng: RandomNumberGenerator) -> void:
	var manifestation: String = String(scenario.get("manifestation", "eletrica"))
	var pos: Vector2 = Vector2(state["player_pos"])
	var umbra_pos: Vector2 = Vector2(state["umbra_pos"])
	var base_damage: float = _player_damage(scenario)
	state["player_manifest_cd"] = 4.8
	match manifestation:
		"eletrica":
			if pos.distance_to(umbra_pos) < 260.0:
				_damage_umbra(state, base_damage * 1.45, "manifest_eletrica", stats, "USAR_MANIFESTACAO")
			else:
				_add_action_reward(stats, "USAR_MANIFESTACAO", -0.18)
		"lacerante":
			_spawn_projectile(state, "apolo", pos, umbra_pos + Vector2(rng.randf_range(-28.0, 28.0), rng.randf_range(-28.0, 28.0)), base_damage * 1.25, 650.0, "manifest_lacerante")
		"gravitante":
			_add_hazard(state, "apolo_gravity", umbra_pos, 115.0, 2.8, base_damage * 0.18, 0.4)
		"prismatica":
			state["player_hp"] = minf(float(state["player_hp_max"]), float(state["player_hp"]) + 65.0 + _card_count(scenario, "espelho") * 12.0)
			state["apolo_reward"] = float(state.get("apolo_reward", 0.0)) + 0.35
		"ancorada":
			if pos.distance_to(umbra_pos) < 340.0:
				_damage_umbra(state, base_damage * 1.15, "manifest_ancorada", stats, "USAR_MANIFESTACAO")
				state["umbra_pos"] = Vector2(state["umbra_pos"]).lerp(pos, 0.18)
			else:
				_add_action_reward(stats, "USAR_MANIFESTACAO", -0.14)
		_:
			_spawn_projectile(state, "apolo", pos, umbra_pos, base_damage, 590.0, "manifest_generic")


func _apply_umbra_action(state: Dictionary, scenario: Dictionary, action: String, stats: Dictionary, rng: RandomNumberGenerator) -> void:
	var pos: Vector2 = Vector2(state["umbra_pos"])
	var player_pos: Vector2 = Vector2(state["player_pos"])
	var move: Vector2 = Vector2.ZERO
	match action:
		"FUGIR":
			move = (pos - player_pos).normalized()
		"INTERCEPTAR":
			move = (_predict_player_pos(state) - pos).normalized()
		"ORBITAR":
			move = _orbit_dir(pos, player_pos, rng)
		"CERCAR":
			var target: Vector2 = _nearest_escape_cutoff(player_pos)
			move = (target - pos).normalized()
		"ATAQUE":
			_spawn_projectile(state, "umbra", pos, _predict_player_pos(state), 42.0 * float(scenario.get("difficulty", 1.0)), 470.0, "umbra_plasma")
			_add_cooldown(state, "ATAQUE", 0.45)
		"SIFON":
			if pos.distance_to(player_pos) < 260.0:
				_damage_apolo(state, 34.0 * float(scenario.get("difficulty", 1.0)), "boss5_sifon", stats, action)
				state["umbra_hp"] = minf(float(state["umbra_hp_max"]), float(state["umbra_hp"]) + 180.0)
			else:
				_add_action_reward(stats, action, -0.18)
			_add_cooldown(state, action, 8.0)
		"TELEPORTE", "TELEPORTE_JUKE":
			var target_pos: Vector2 = player_pos + Vector2(rng.randf_range(-210.0, 210.0), rng.randf_range(-170.0, 170.0))
			if action == "TELEPORTE_JUKE" and rng.randf() < 0.45:
				_add_hazard(state, "fake_teleport", target_pos, 70.0, 0.65, 0.0, 0.65)
			else:
				state["umbra_pos"] = _clamp_pos(target_pos)
			_add_cooldown(state, action, 5.0)
		"VORTICE":
			_add_hazard(state, "vortex", ARENA_CENTER, 170.0, 4.8, 11.0 * float(scenario.get("difficulty", 1.0)), 0.35)
			_add_cooldown(state, action, 12.0)
		"PRISAO":
			_add_hazard(state, "prison", _predict_player_pos(state), 92.0, 1.8, 62.0 * float(scenario.get("difficulty", 1.0)), 0.95)
			_add_cooldown(state, action, 12.0)
		"MIASMA":
			_add_hazard(state, "miasma", player_pos, 135.0, 4.5, 12.0 * float(scenario.get("difficulty", 1.0)), 0.5)
			_add_cooldown(state, action, 10.0)
		"DESCARGA_ELETRICA":
			_add_line_hazard(state, "electric_line", pos, _predict_player_pos(state), 42.0, 1.1, 78.0 * float(scenario.get("difficulty", 1.0)), 0.72)
			_add_cooldown(state, action, 11.0)
		"CAMINHO_ESPINHOS":
			_add_line_hazard(state, "thorns", pos, _predict_player_pos(state), 54.0, 3.2, 18.0 * float(scenario.get("difficulty", 1.0)), 0.45)
			_add_cooldown(state, action, 8.0)
		"LASER_SOBRECARGA":
			_add_line_hazard(state, "laser", pos, _predict_player_pos(state), 58.0, 1.35, 150.0 * float(scenario.get("difficulty", 1.0)), 1.0)
			_add_cooldown(state, action, 24.0)
		"PRAGA_RATOS":
			var rats: Array = Array(state.get("rats", []))
			for _i in range(4):
				var offset := Vector2(rng.randf_range(-90.0, 90.0), rng.randf_range(-90.0, 90.0))
				rats.append({"pos": _clamp_pos(pos + offset), "life": 6.5, "tick": 0.0})
			state["rats"] = rats
			_add_cooldown(state, action, 12.0)
		_:
			if action.begins_with("TRANSMUTAR_"):
				_transmute_dimension(state, action)
	if move.length() > 0.01:
		var speed: float = 185.0 + float(scenario.get("difficulty", 1.0)) * 18.0
		var new_pos: Vector2 = _clamp_pos(Vector2(state["umbra_pos"]) + move.normalized() * speed * DT)
		state["umbra_vel"] = (new_pos - Vector2(state["umbra_pos"])) / DT
		state["umbra_pos"] = new_pos


func _update_projectiles(state: Dictionary, _scenario: Dictionary, apolo_stats: Dictionary, umbra_stats: Dictionary) -> void:
	var remaining: Array = []
	for projectile in Array(state.get("projectiles", [])):
		var row: Dictionary = Dictionary(projectile)
		var pos: Vector2 = Vector2(row.get("pos", Vector2.ZERO)) + Vector2(row.get("vel", Vector2.ZERO)) * DT
		row["pos"] = pos
		row["life"] = float(row.get("life", 0.0)) - DT
		var owner: String = String(row.get("owner", ""))
		if owner == "apolo" and pos.distance_to(Vector2(state["umbra_pos"])) <= UMBRA_RADIUS + PROJECTILE_RADIUS:
			_damage_umbra(state, float(row.get("damage", 0.0)), String(row.get("kind", "apolo_shot")), apolo_stats, "ATIRAR")
			continue
		if owner == "umbra" and pos.distance_to(Vector2(state["player_pos"])) <= PLAYER_RADIUS + PROJECTILE_RADIUS:
			_damage_apolo(state, float(row.get("damage", 0.0)), String(row.get("kind", "umbra_plasma")), umbra_stats, "ATAQUE")
			continue
		if float(row.get("life", 0.0)) > 0.0 and pos.x >= -80.0 and pos.y >= -80.0 and pos.x <= WORLD_SIZE.x + 80.0 and pos.y <= WORLD_SIZE.y + 80.0:
			remaining.append(row)
	state["projectiles"] = remaining


func _update_hazards(state: Dictionary, _scenario: Dictionary, _apolo_stats: Dictionary, umbra_stats: Dictionary) -> void:
	var remaining: Array = []
	for hazard in Array(state.get("hazards", [])):
		var row: Dictionary = Dictionary(hazard)
		row["life"] = float(row.get("life", 0.0)) - DT
		row["delay"] = maxf(0.0, float(row.get("delay", 0.0)) - DT)
		row["tick"] = maxf(0.0, float(row.get("tick", 0.0)) - DT)
		if float(row.get("delay", 0.0)) <= 0.0 and float(row.get("tick", 0.0)) <= 0.0:
			var hit: bool = false
			if row.has("from") and row.has("to"):
				hit = _point_to_segment_distance(Vector2(state["player_pos"]), Vector2(row["from"]), Vector2(row["to"])) <= float(row.get("radius", 0.0))
			else:
				hit = Vector2(state["player_pos"]).distance_to(Vector2(row.get("pos", Vector2.ZERO))) <= float(row.get("radius", 0.0))
			if hit:
				_damage_apolo(state, float(row.get("damage", 0.0)), String(row.get("kind", "hazard")), umbra_stats, _hazard_owner_action(String(row.get("kind", ""))))
				row["tick"] = float(row.get("interval", 0.5))
			elif float(row.get("damage", 0.0)) > 0.0:
				_add_action_reward(umbra_stats, _hazard_owner_action(String(row.get("kind", ""))), -0.012)
		if float(row.get("life", 0.0)) > 0.0:
			remaining.append(row)
	state["hazards"] = remaining


func _update_rats(state: Dictionary, scenario: Dictionary, umbra_stats: Dictionary) -> void:
	var remaining: Array = []
	for rat in Array(state.get("rats", [])):
		var row: Dictionary = Dictionary(rat)
		var pos: Vector2 = Vector2(row.get("pos", Vector2.ZERO))
		var dir: Vector2 = (Vector2(state["player_pos"]) - pos).normalized()
		pos = _clamp_pos(pos + dir * (160.0 + 12.0 * float(scenario.get("difficulty", 1.0))) * DT)
		row["pos"] = pos
		row["life"] = float(row.get("life", 0.0)) - DT
		row["tick"] = maxf(0.0, float(row.get("tick", 0.0)) - DT)
		if row["tick"] <= 0.0 and pos.distance_to(Vector2(state["player_pos"])) <= 34.0:
			_damage_apolo(state, 18.0, "boss5_rato", umbra_stats, "PRAGA_RATOS")
			state["umbra_hp"] = minf(float(state["umbra_hp_max"]), float(state["umbra_hp"]) + 45.0)
			row["tick"] = 0.8
		if float(row.get("life", 0.0)) > 0.0:
			remaining.append(row)
	state["rats"] = remaining


func _update_cooldowns(state: Dictionary, delta: float) -> void:
	state["player_dash_cd"] = maxf(0.0, float(state.get("player_dash_cd", 0.0)) - delta)
	state["player_manifest_cd"] = maxf(0.0, float(state.get("player_manifest_cd", 0.0)) - delta)
	state["umbra_dimension_timer"] = maxf(0.0, float(state.get("umbra_dimension_timer", 0.0)) - delta)
	if float(state.get("umbra_dimension_timer", 0.0)) <= 0.0:
		state["umbra_dimension"] = "base"
	var cooldowns: Dictionary = Dictionary(state.get("umbra_cooldowns", {}))
	for key in cooldowns.keys():
		cooldowns[key] = maxf(0.0, float(cooldowns[key]) - delta)
	state["umbra_cooldowns"] = cooldowns


func _spawn_projectile(state: Dictionary, owner: String, from_pos: Vector2, target_pos: Vector2, damage: float, speed: float, kind: String) -> void:
	var dir: Vector2 = (target_pos - from_pos).normalized()
	if dir.length() <= 0.01:
		dir = Vector2.RIGHT
	var projectiles: Array = Array(state.get("projectiles", []))
	projectiles.append({
		"owner": owner,
		"kind": kind,
		"pos": from_pos,
		"vel": dir * speed,
		"damage": damage,
		"life": 3.0
	})
	state["projectiles"] = projectiles


func _add_hazard(state: Dictionary, kind: String, pos: Vector2, radius: float, life: float, damage: float, delay: float) -> void:
	var hazards: Array = Array(state.get("hazards", []))
	hazards.append({
		"kind": kind,
		"pos": _clamp_pos(pos),
		"radius": radius,
		"life": life,
		"damage": damage,
		"delay": delay,
		"interval": 0.45,
		"tick": 0.0
	})
	state["hazards"] = hazards


func _add_line_hazard(state: Dictionary, kind: String, from_pos: Vector2, to_pos: Vector2, radius: float, life: float, damage: float, delay: float) -> void:
	var hazards: Array = Array(state.get("hazards", []))
	hazards.append({
		"kind": kind,
		"from": _clamp_pos(from_pos),
		"to": _clamp_pos(to_pos),
		"radius": radius,
		"life": life,
		"damage": damage,
		"delay": delay,
		"interval": 0.55,
		"tick": 0.0
	})
	state["hazards"] = hazards


func _damage_apolo(state: Dictionary, amount: float, source: String, stats: Dictionary, action: String) -> void:
	var defense: float = _card_count(Dictionary(state).get("scenario", {}), "defesa") * 0.0
	var final_damage: float = maxf(0.0, amount - defense)
	state["player_hp"] = maxf(0.0, float(state.get("player_hp", 0.0)) - final_damage)
	state["last_damage_source_apolo"] = source
	state["umbra_reward"] = float(state.get("umbra_reward", 0.0)) + final_damage / 55.0
	state["apolo_reward"] = float(state.get("apolo_reward", 0.0)) - final_damage / 70.0
	_register_action_hit(stats, action, final_damage, final_damage / 55.0)


func _damage_umbra(state: Dictionary, amount: float, source: String, stats: Dictionary, action: String) -> void:
	var final_damage: float = maxf(0.0, amount)
	state["umbra_hp"] = maxf(0.0, float(state.get("umbra_hp", 0.0)) - final_damage)
	state["last_damage_source_umbra"] = source
	state["apolo_reward"] = float(state.get("apolo_reward", 0.0)) + final_damage / 650.0
	state["umbra_reward"] = float(state.get("umbra_reward", 0.0)) - final_damage / 900.0
	_register_action_hit(stats, action, final_damage, final_damage / 650.0)


func _transmute_dimension(state: Dictionary, action: String) -> void:
	var dimension: String = action.trim_prefix("TRANSMUTAR_").to_lower()
	state["umbra_dimension"] = dimension
	state["umbra_dimension_timer"] = 16.0
	_add_cooldown(state, action, 16.0)


func _add_cooldown(state: Dictionary, action: String, seconds: float) -> void:
	var cooldowns: Dictionary = Dictionary(state.get("umbra_cooldowns", {}))
	cooldowns[action] = seconds
	state["umbra_cooldowns"] = cooldowns


func _update_memory_from_episode(memory: Dictionary, result: Dictionary) -> void:
	memory["trained_episodes"] = int(memory.get("trained_episodes", 0)) + 1
	var action_memory: Dictionary = Dictionary(memory.get("actions", {}))
	var episode_actions: Dictionary = Dictionary(result.get("umbra_actions", {}))
	for action in episode_actions.keys():
		var row: Dictionary = Dictionary(episode_actions[action])
		var current: Dictionary = Dictionary(action_memory.get(action, {}))
		current["uses"] = int(current.get("uses", 0)) + int(row.get("uses", 0))
		current["hits"] = int(current.get("hits", 0)) + int(row.get("hits", 0))
		current["misses"] = int(current.get("misses", 0)) + int(row.get("misses", 0))
		current["damage"] = snappedf(float(current.get("damage", 0.0)) + float(row.get("damage", 0.0)), 0.01)
		current["reward"] = snappedf(float(current.get("reward", 0.0)) + float(row.get("reward", 0.0)), 0.001)
		var uses: float = maxf(1.0, float(current.get("uses", 0)))
		var reward_per_use: float = float(current.get("reward", 0.0)) / uses
		var hit_rate: float = float(current.get("hits", 0)) / uses
		current["score"] = snappedf(clampf(reward_per_use * 0.35 + hit_rate * 0.65, -3.5, 3.5), 0.0001)
		action_memory[action] = current
	memory["actions"] = action_memory
	var scenario: Dictionary = Dictionary(result.get("scenario", {}))
	var scenario_id: String = String(scenario.get("id", "unknown"))
	var scenarios: Dictionary = Dictionary(memory.get("scenarios", {}))
	var sc: Dictionary = Dictionary(scenarios.get(scenario_id, {"runs": 0, "umbra_wins": 0, "apolo_wins": 0, "draws": 0}))
	sc["runs"] = int(sc.get("runs", 0)) + 1
	match String(result.get("winner", "DRAW")):
		"UMBRA":
			sc["umbra_wins"] = int(sc.get("umbra_wins", 0)) + 1
		"APOLO":
			sc["apolo_wins"] = int(sc.get("apolo_wins", 0)) + 1
		_:
			sc["draws"] = int(sc.get("draws", 0)) + 1
	sc["manifestation"] = String(scenario.get("manifestation", ""))
	sc["spectrum"] = String(scenario.get("spectrum", ""))
	sc["last_cards"] = Array(scenario.get("cards", [])).duplicate(true)
	scenarios[scenario_id] = sc
	memory["scenarios"] = scenarios


func _episode_report_row(result: Dictionary) -> Dictionary:
	if result.is_empty():
		return {}
	return {
		"episode": int(result.get("episode", 0)),
		"scenario_id": String(Dictionary(result.get("scenario", {})).get("id", "")),
		"manifestation": String(Dictionary(result.get("scenario", {})).get("manifestation", "")),
		"spectrum": String(Dictionary(result.get("scenario", {})).get("spectrum", "")),
		"steps": int(result.get("steps", 0)),
		"duration_seconds": float(result.get("duration_seconds", 0.0)),
		"winner": String(result.get("winner", "DRAW")),
		"umbra_reward": float(result.get("umbra_reward", 0.0)),
		"apolo_reward": float(result.get("apolo_reward", 0.0)),
		"umbra_hp_ratio": float(result.get("umbra_hp_ratio", 0.0)),
		"apolo_hp_ratio": float(result.get("apolo_hp_ratio", 0.0))
	}


func _register_action_use(stats: Dictionary, action: String) -> void:
	var row: Dictionary = Dictionary(stats.get(action, {"uses": 0, "hits": 0, "misses": 0, "damage": 0.0, "reward": 0.0}))
	row["uses"] = int(row.get("uses", 0)) + 1
	stats[action] = row


func _register_action_hit(stats: Dictionary, action: String, damage: float, reward: float) -> void:
	var row: Dictionary = Dictionary(stats.get(action, {"uses": 0, "hits": 0, "misses": 0, "damage": 0.0, "reward": 0.0}))
	row["hits"] = int(row.get("hits", 0)) + 1
	row["damage"] = float(row.get("damage", 0.0)) + damage
	row["reward"] = float(row.get("reward", 0.0)) + reward
	stats[action] = row


func _add_action_reward(stats: Dictionary, action: String, reward: float) -> void:
	var row: Dictionary = Dictionary(stats.get(action, {"uses": 0, "hits": 0, "misses": 0, "damage": 0.0, "reward": 0.0}))
	if reward < 0.0:
		row["misses"] = int(row.get("misses", 0)) + 1
	row["reward"] = float(row.get("reward", 0.0)) + reward
	stats[action] = row


func _record_motion(state: Dictionary) -> void:
	var player_history: Array = Array(state.get("player_history", []))
	player_history.append(Vector2(state["player_pos"]))
	while player_history.size() > MAX_HISTORY:
		player_history.pop_front()
	state["player_history"] = player_history
	var umbra_history: Array = Array(state.get("umbra_history", []))
	umbra_history.append(Vector2(state["umbra_pos"]))
	while umbra_history.size() > MAX_HISTORY:
		umbra_history.pop_front()
	state["umbra_history"] = umbra_history


func _incoming_projectiles(actor: String, state: Dictionary) -> Array:
	var self_pos: Vector2 = Vector2(state["player_pos"]) if actor == "APOLO" else Vector2(state["umbra_pos"])
	var owner_to_avoid: String = "umbra" if actor == "APOLO" else "apolo"
	var rows: Array = []
	for projectile in Array(state.get("projectiles", [])):
		var row: Dictionary = Dictionary(projectile)
		if String(row.get("owner", "")) != owner_to_avoid:
			continue
		var pos: Vector2 = Vector2(row.get("pos", Vector2.ZERO))
		var vel: Vector2 = Vector2(row.get("vel", Vector2.ZERO))
		var to_self: Vector2 = self_pos - pos
		var approaching: float = 1.0 if vel.normalized().dot(to_self.normalized()) > 0.25 else 0.0
		rows.append({
			"kind": String(row.get("kind", "")),
			"distance": snappedf(pos.distance_to(self_pos), 0.01),
			"direction": _vec_report(vel.normalized()),
			"approaching": approaching,
			"damage": float(row.get("damage", 0.0))
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("distance", 999999.0)) < float(b.get("distance", 999999.0)))
	return rows.slice(0, MAX_THREAT_SLOTS)


func _telegraphed_hazards(actor: String, state: Dictionary) -> Array:
	if actor != "APOLO":
		return []
	var self_pos: Vector2 = Vector2(state["player_pos"])
	var rows: Array = []
	for hazard in Array(state.get("hazards", [])):
		var row: Dictionary = Dictionary(hazard)
		var distance: float = 0.0
		if row.has("from") and row.has("to"):
			distance = _point_to_segment_distance(self_pos, Vector2(row["from"]), Vector2(row["to"]))
		else:
			distance = self_pos.distance_to(Vector2(row.get("pos", Vector2.ZERO)))
		rows.append({
			"kind": String(row.get("kind", "")),
			"distance": snappedf(distance, 0.01),
			"radius": float(row.get("radius", 0.0)),
			"delay": snappedf(float(row.get("delay", 0.0)), 0.01),
			"life": snappedf(float(row.get("life", 0.0)), 0.01),
			"damage": float(row.get("damage", 0.0))
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("distance", 999999.0)) < float(b.get("distance", 999999.0)))
	return rows.slice(0, MAX_THREAT_SLOTS)


func _combined_threat_escape(obs: Dictionary, self_pos: Vector2) -> Vector2:
	var escape: Vector2 = Vector2.ZERO
	for projectile in Array(obs.get("incoming_projectiles", [])):
		var row: Dictionary = Dictionary(projectile)
		if float(row.get("approaching", 0.0)) <= 0.0:
			continue
		var dir: Vector2 = _vec_from_report(Dictionary(row.get("direction", {})))
		var urgency: float = clampf((320.0 - float(row.get("distance", 999.0))) / 320.0, 0.0, 1.0)
		escape += Vector2(-dir.y, dir.x) * urgency
	for hazard in Array(obs.get("telegraphed_hazards", [])):
		var row: Dictionary = Dictionary(hazard)
		var radius: float = float(row.get("radius", 0.0))
		var distance: float = float(row.get("distance", 999.0))
		var delay: float = float(row.get("delay", 0.0))
		if distance <= radius + 45.0 and delay < 1.2:
			escape += (self_pos - ARENA_CENTER).normalized() * 0.45
	if _edge_distance(self_pos) < 90.0:
		escape += (ARENA_CENTER - self_pos).normalized() * 0.65
	return escape


func _cooldown_report(actor: String, state: Dictionary) -> Dictionary:
	if actor == "APOLO":
		return {
			"dash": snappedf(float(state.get("player_dash_cd", 0.0)), 0.01),
			"manifestation": snappedf(float(state.get("player_manifest_cd", 0.0)), 0.01)
		}
	return Dictionary(state.get("umbra_cooldowns", {})).duplicate(true)


func _last_action_result(actor: String, state: Dictionary) -> Dictionary:
	return {
		"last_action": String(state.get("last_apolo_action", "")) if actor == "APOLO" else String(state.get("last_umbra_action", "")),
		"last_damage_source": String(state.get("last_damage_source_apolo", "")) if actor == "APOLO" else String(state.get("last_damage_source_umbra", ""))
	}


func _recent_motion(actor: String, state: Dictionary) -> Dictionary:
	var history: Array = Array(state.get("player_history", [])) if actor == "APOLO" else Array(state.get("umbra_history", []))
	if history.size() < 2:
		return {"speed": 0.0, "samples": history.size(), "direction": _vec_report(Vector2.ZERO)}
	var first: Vector2 = Vector2(history[0])
	var last: Vector2 = Vector2(history[history.size() - 1])
	var elapsed: float = maxf(DT, float(history.size() - 1) * DT)
	var velocity: Vector2 = (last - first) / elapsed
	return {"speed": snappedf(velocity.length(), 0.01), "samples": history.size(), "direction": _vec_report(velocity.normalized())}


func _recent_motion_speed(actor: String, state: Dictionary) -> float:
	return float(_recent_motion(actor, state).get("speed", 0.0))


func _predict_player_pos(state: Dictionary) -> Vector2:
	var player_pos: Vector2 = Vector2(state["player_pos"])
	var history: Array = Array(state.get("player_history", []))
	if history.size() < 3:
		return player_pos + Vector2(state["player_vel"]) * 0.35
	var oldest: Vector2 = Vector2(history[max(0, history.size() - 8)])
	var newest: Vector2 = Vector2(history[history.size() - 1])
	var velocity: Vector2 = (newest - oldest) / maxf(DT, float(min(8, history.size() - 1)) * DT)
	return _clamp_pos(player_pos + velocity * 0.55)


func _player_damage(scenario: Dictionary) -> float:
	var damage: float = float(scenario.get("player_damage", 80.0))
	damage += _card_count(scenario, "disparo_crescente") * 5.0
	damage += _card_count(scenario, "feridas") * 4.0
	damage += _card_count(scenario, "poison") * 3.0
	return damage


func _manifest_use_chance(manifestation: String, distance: float) -> float:
	match manifestation:
		"eletrica":
			return 0.38 if distance < 285.0 else 0.08
		"lacerante":
			return 0.24
		"gravitante":
			return 0.28 if distance < 520.0 else 0.1
		"prismatica":
			return 0.18
		"ancorada":
			return 0.32 if distance < 360.0 else 0.06
		_:
			return 0.16


func _card_count(scenario: Dictionary, card_id: String) -> int:
	var total: int = 0
	for card in Array(scenario.get("cards", [])):
		var row: Dictionary = Dictionary(card)
		if String(row.get("id", "")) == card_id:
			total += int(row.get("count", 1))
	return total


func _hazard_owner_action(kind: String) -> String:
	match kind:
		"vortex":
			return "VORTICE"
		"prison":
			return "PRISAO"
		"miasma":
			return "MIASMA"
		"electric_line":
			return "DESCARGA_ELETRICA"
		"thorns":
			return "CAMINHO_ESPINHOS"
		"laser":
			return "LASER_SOBRECARGA"
		_:
			return "NENHUMA"


func _nearest_escape_cutoff(pos: Vector2) -> Vector2:
	var target: Vector2 = pos
	if pos.x < WORLD_SIZE.x * 0.5:
		target.x = maxf(70.0, pos.x - 115.0)
	else:
		target.x = minf(WORLD_SIZE.x - 70.0, pos.x + 115.0)
	if pos.y < WORLD_SIZE.y * 0.5:
		target.y = maxf(70.0, pos.y - 85.0)
	else:
		target.y = minf(WORLD_SIZE.y - 70.0, pos.y + 85.0)
	return target


func _orbit_dir(self_pos: Vector2, enemy_pos: Vector2, rng: RandomNumberGenerator) -> Vector2:
	var to_enemy: Vector2 = (enemy_pos - self_pos).normalized()
	var side: float = -1.0 if rng.randf() < 0.5 else 1.0
	return Vector2(-to_enemy.y, to_enemy.x) * side


func _edge_distance(pos: Vector2) -> float:
	return minf(minf(pos.x, WORLD_SIZE.x - pos.x), minf(pos.y, WORLD_SIZE.y - pos.y))


func _corner_pressure(pos: Vector2) -> float:
	var edge_x: float = minf(pos.x, WORLD_SIZE.x - pos.x)
	var edge_y: float = minf(pos.y, WORLD_SIZE.y - pos.y)
	return clampf((180.0 - edge_x) / 180.0, 0.0, 1.0) * clampf((135.0 - edge_y) / 135.0, 0.0, 1.0)


func _point_to_segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var denom: float = maxf(0.0001, ab.length_squared())
	var t: float = clampf((point - a).dot(ab) / denom, 0.0, 1.0)
	return point.distance_to(a + ab * t)


func _clamp_pos(pos: Vector2) -> Vector2:
	return Vector2(clampf(pos.x, 24.0, WORLD_SIZE.x - 24.0), clampf(pos.y, 24.0, WORLD_SIZE.y - 24.0))


func _vec_report(value: Vector2) -> Dictionary:
	return {"x": snappedf(value.x, 0.01), "y": snappedf(value.y, 0.01)}


func _vec_from_report(value: Dictionary) -> Vector2:
	return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))
