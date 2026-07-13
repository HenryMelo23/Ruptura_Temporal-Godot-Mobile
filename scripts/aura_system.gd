class_name AuraSystem
extends RefCounted

const AURA_NAMES := ["Racional", "Impulsiva", "Devota", "Vanguarda", "Insana", "Voraz", "Nula", "Abissal", "Profetica", "Sanguinaria"]

const COLORS := {
	"Racional": Color(0.0, 0.71, 1.0),
	"Impulsiva": Color(1.0, 0.24, 0.24),
	"Devota": Color(1.0, 0.78, 0.0),
	"Vanguarda": Color(0.90, 0.0, 0.90),
	"Insana": Color(0.63, 0.22, 1.0),
	"Voraz": Color(1.0, 0.44, 0.09),
	"Nula": Color(0.71, 0.92, 1.0),
	"Abissal": Color(0.31, 0.31, 0.75),
	"Profetica": Color(1.0, 0.92, 0.43),
	"Sanguinaria": Color(1.0, 0.18, 0.25),
}

const RATIONAL_STILL_TIME := 4.5
const RATIONAL_DILATION_TIME := 8.0
const RATIONAL_REBOUND_TIME := 3.0
const RATIONAL_COOLDOWN := 30.0
const IMPULSIVE_KILLS := 5
const DEVOTED_CHARGES := 3
const VORACIOUS_BASE_MAX := 100.0
const INSANE_ECHO_DELAY := 1.0
const INSANE_ECHO_BASE := 4
const NULL_IDLE_TIME := 2.3

static func create(aura: String, level := 1) -> Dictionary:
	return {
		"name": aura if aura in AURA_NAMES else "Racional",
		"level": clampi(level, 0, 5),
		"last_pos": Vector2.ZERO,
		"still": 0.0,
		"rational_dilation": 0.0,
		"rational_rebound": 0.0,
		"rational_cooldown": 0.0,
		"impulsive_kills": 0,
		"impulsive_active": 0.0,
		"impulsive_rank": 0,
		"impulsive_panic": 0,
		"devoted_charges": DEVOTED_CHARGES,
		"devoted_recharge": 0.0,
		"devoted_damage": 0.0,
		"devoted_damage_mult": 1.0,
		"devoted_slow": 0.0,
		"vanguard_ring": 0.0,
		"insane_ready": 20.0,
		"insane_echoes": 0,
		"insane_next_echoes": INSANE_ECHO_BASE,
		"insane_queue": [],
		"insane_dash_penalty": false,
		"voracious_hunger": 0.0,
		"voracious_cycles": 0,
		"voracious_last_collect": 0.0,
		"voracious_drain_tick": 0.0,
		"voracious_boss_feed_cd": 0.0,
		"voracious_drops": [],
		"null_charge": 0.0,
		"null_armed": false,
		"last_attack": 0.0,
		"abyss_depth": 0.0,
		"abyss_tide": 0.0,
		"prophecy_next": 8.0,
		"prophecy_uid": -1,
		"prophecy_time": 0.0,
		"prophecy_sequence": 0,
		"prophecy_broken": 0.0,
		"blood_hits": {},
		"blood_thirst": 0.0,
		"blood_last_wound": 0.0,
		"blood_wounds": 0,
		"blood_burst": false,
		"blood_slow": 0.0,
	}

static func update(state: Dictionary, delta: float, context: Dictionary) -> Array:
	var events: Array = []
	var name := String(state.get("name", ""))
	var level := int(state.get("level", 0))
	var player_pos := Vector2(context.get("player_pos", Vector2.ZERO))
	var enemies: Array = context.get("enemies", [])
	state["last_attack"] = float(state.get("last_attack", 0.0)) + delta
	for key in ["rational_dilation", "rational_rebound", "rational_cooldown", "impulsive_active", "devoted_damage", "devoted_slow", "vanguard_ring", "insane_ready", "abyss_tide", "prophecy_next", "prophecy_time", "prophecy_broken", "blood_slow"]:
		state[key] = maxf(0.0, float(state.get(key, 0.0)) - delta)

	match name:
		"Racional":
			var moved := player_pos.distance_to(Vector2(state.get("last_pos", player_pos)))
			state["still"] = float(state.get("still", 0.0)) + delta if moved <= 1.25 else 0.0
			if float(state["still"]) >= RATIONAL_STILL_TIME:
				state["still"] = 0.0
				events.append({"type": "score", "amount": 5 + level * 2, "text": "ANALISE +%d" % (5 + level * 2)})
		"Impulsiva":
			if float(state["impulsive_active"]) <= 0.0 and int(state["impulsive_rank"]) > 0:
				state["impulsive_rank"] = 0
				state["impulsive_kills"] = 0
		"Devota":
			if int(state["devoted_charges"]) <= 0:
				state["devoted_recharge"] = maxf(0.0, float(state.get("devoted_recharge", 0.0)) - delta)
				if float(state["devoted_recharge"]) <= 0.0:
					state["devoted_charges"] = DEVOTED_CHARGES
					events.append({"type": "text", "text": "FE RESTAURADA"})
		"Vanguarda":
			for enemy in enemies:
				if float(enemy.get("aura_burn", 0.0)) > 0.0:
					enemy["aura_burn"] = maxf(0.0, float(enemy["aura_burn"]) - delta)
					enemy["aura_burn_tick"] = float(enemy.get("aura_burn_tick", 0.0)) - delta
					if float(enemy["aura_burn_tick"]) <= 0.0:
						enemy["aura_burn_tick"] = 1.0
						events.append({"type": "enemy_damage", "uid": int(enemy.get("uid", -1)), "amount": maxf(1.0, float(enemy.get("max_hp", 1.0)) * (0.01 + level * 0.002)), "source": "aura_vanguarda"})
		"Insana":
			var queue: Array = state.get("insane_queue", [])
			for echo in queue:
				echo["delay"] = float(echo["delay"]) - delta
				if float(echo["delay"]) <= 0.0:
					events.append({"type": "echo_shot", "pos": echo["pos"], "dir": echo["dir"], "kind": echo.get("kind", "aura_insana"), "damage_mult": 0.12 + level * 0.05})
			state["insane_queue"] = queue.filter(func(e): return float(e["delay"]) > 0.0)
			if int(state["insane_echoes"]) <= 0 and queue.size() > 0 and Array(state["insane_queue"]).is_empty():
				state["insane_dash_penalty"] = true
		"Voraz":
			_update_voracious(state, delta, context, events)
		"Nula":
			if float(state["last_attack"]) >= NULL_IDLE_TIME and not bool(state["null_armed"]):
				state["null_charge"] = minf(100.0, float(state["null_charge"]) + 9.5 * delta)
				state["null_armed"] = float(state["null_charge"]) >= 100.0
		"Abissal":
			if float(state["abyss_tide"]) > 0.0:
				for enemy in enemies:
					var dist := player_pos.distance_to(Vector2(enemy.get("pos", player_pos)))
					if dist <= 190.0:
						var direction := (player_pos - Vector2(enemy["pos"])).normalized()
						enemy["pos"] = Vector2(enemy["pos"]) + direction * (33.0 + level * 2.4) * delta
						if float(enemy.get("hp", 1.0)) / maxf(1.0, float(enemy.get("max_hp", 1.0))) <= 0.20 + level * 0.015:
							events.append({"type": "enemy_damage", "uid": int(enemy.get("uid", -1)), "amount": maxf(1.0, float(enemy.get("max_hp", 1.0)) * (0.010 + level * 0.0015) * delta * 60.0), "source": "aura_abissal"})
			else:
				var nearby := 0
				for enemy in enemies:
					if player_pos.distance_to(Vector2(enemy.get("pos", player_pos))) <= 190.0: nearby += 1
				state["abyss_depth"] = minf(100.0, float(state["abyss_depth"]) + (enemies.size() * 0.20 + nearby * 0.52 + (0.42 if bool(context.get("boss_active", false)) else 0.0)) * delta * (1.0 + level * 0.08))
				if float(state["abyss_depth"]) >= 100.0:
					state["abyss_depth"] = 0.0
					state["abyss_tide"] = 5.2 + level * 0.55
					events.append({"type": "text", "text": "MARE NEGRA"})
		"Profetica":
			_update_prophecy(state, enemies, events)
		"Sanguinaria":
			var hit_keys: Array = Dictionary(state["blood_hits"]).keys()
			for uid in hit_keys:
				var hit_data: Dictionary = state["blood_hits"][uid]
				hit_data["time"] = float(hit_data.get("time", 0.0)) + delta
				if float(hit_data["time"]) > 4.3: hit_data["count"] = 0
				state["blood_hits"][uid] = hit_data
			if float(state["blood_last_wound"]) > 0.0:
				state["blood_last_wound"] += delta
			if float(state["blood_last_wound"]) > 8.5:
				state["blood_thirst"] = maxf(0.0, float(state["blood_thirst"]) - 10.8 * delta)
				if float(state["blood_thirst"]) <= 0.0 and int(state["blood_wounds"]) > 0:
					state["blood_wounds"] = 0
					state["blood_burst"] = false
					state["blood_slow"] = 2.6
	state["last_pos"] = player_pos
	return events

static func on_attack(state: Dictionary, projectile: Dictionary) -> Array:
	var events: Array = []
	state["last_attack"] = 0.0
	match String(state.get("name", "")):
		"Insana":
			var queue: Array = state.get("insane_queue", [])
			if float(state["insane_ready"]) <= 0.0 and int(state["insane_echoes"]) <= 0 and queue.is_empty():
				state["insane_echoes"] = int(state.get("insane_next_echoes", INSANE_ECHO_BASE))
				state["insane_next_echoes"] = INSANE_ECHO_BASE
				state["insane_ready"] = maxf(15.0, 20.0 - int(state.get("level", 0)))
			if int(state["insane_echoes"]) > 0:
				state["insane_echoes"] = int(state["insane_echoes"]) - 1
				queue = state["insane_queue"]
				queue.append({"pos": projectile.get("pos", Vector2.ZERO), "dir": projectile.get("dir", Vector2.RIGHT), "kind": projectile.get("kind", "aura_insana"), "delay": INSANE_ECHO_DELAY})
				state["insane_queue"] = queue
		"Voraz":
			projectile["damage"] = float(projectile.get("damage", 0.0)) * (1.0 + voracious_intensity(state) * (0.07 + int(state["level"]) * 0.004))
			projectile["aura_scale"] = 1.0 + voracious_intensity(state) * 0.12
		"Nula":
			if bool(state["null_armed"]):
				projectile["aura_null"] = true
				state["null_charge"] = 0.0
				state["null_armed"] = false
	return events

static func on_enemy_hit(state: Dictionary, enemy: Dictionary, projectile: Dictionary, damage: float) -> Dictionary:
	var result := {"damage": damage, "events": []}
	var level := int(state.get("level", 0))
	match String(state.get("name", "")):
		"Nula":
			if bool(projectile.get("aura_null", false)):
				enemy["aura_null"] = 4.2 + level * 0.35
				if float(enemy.get("hp", 1.0)) / maxf(1.0, float(enemy.get("max_hp", 1.0))) >= 0.55:
					result["damage"] = damage * (1.18 + level * 0.035)
		"Abissal":
			var ratio := float(enemy.get("hp", 1.0)) / maxf(1.0, float(enemy.get("max_hp", 1.0)))
			if float(state["abyss_tide"]) > 0.0:
				result["damage"] = damage * ((1.22 + level * 0.04) if ratio <= 0.28 + level * 0.015 else (1.06 + level * 0.015))
		"Profetica":
			if int(state["prophecy_uid"]) == int(enemy.get("uid", -1)) and float(state["prophecy_time"]) > 0.0:
				result["damage"] = damage * (1.22 + level * 0.04)
				state["prophecy_sequence"] = int(state["prophecy_sequence"]) + 1
				state["prophecy_uid"] = -1
				state["prophecy_time"] = 0.0
				result["events"].append({"type": "text", "text": "PRESSAGIO CUMPRIDO"})
		"Sanguinaria":
			_apply_blood_hit(state, enemy, result)
	return result

static func on_enemy_killed(state: Dictionary, enemy: Dictionary) -> Array:
	var events: Array = []
	var level := int(state.get("level", 0))
	match String(state.get("name", "")):
		"Impulsiva":
			state["impulsive_kills"] = int(state["impulsive_kills"]) + 1
			while int(state["impulsive_kills"]) >= IMPULSIVE_KILLS:
				state["impulsive_kills"] = int(state["impulsive_kills"]) - IMPULSIVE_KILLS
				if float(state["impulsive_active"]) > 0.0 and float(state["impulsive_active"]) >= 1.0:
					state["impulsive_rank"] = int(state["impulsive_rank"]) + 1
				else:
					state["impulsive_rank"] = maxi(1, int(state["impulsive_rank"]))
				state["impulsive_active"] = 3.0 + level * 0.5
				events.append({"type": "text", "text": "FRENESI x%d" % int(state["impulsive_rank"])})
		"Insana":
			if bool(enemy.get("killed_by_echo", false)):
				state["insane_next_echoes"] = 5
		"Voraz":
			var drops: Array = state["voracious_drops"]
			drops.append({"pos": Vector2(enemy.get("pos", Vector2.ZERO)), "life": 6.8, "value": 28.0})
			state["voracious_drops"] = drops
		"Nula":
			state["null_charge"] = minf(100.0, float(state["null_charge"]) + 18.0)
			state["null_armed"] = float(state["null_charge"]) >= 100.0
		"Profetica":
			if int(state["prophecy_uid"]) == int(enemy.get("uid", -1)):
				var bonus := 35 + level * 15 + int(state["prophecy_sequence"]) * 10
				state["prophecy_sequence"] = int(state["prophecy_sequence"]) + 1
				state["prophecy_uid"] = -1
				state["prophecy_time"] = 0.0
				events.append({"type": "score", "amount": bonus, "text": "+%d PRESSAGIO" % bonus})
		"Sanguinaria":
			if float(enemy.get("aura_wound", 0.0)) > 0.0:
				state["blood_thirst"] = minf(100.0, float(state["blood_thirst"]) + 10.0)
				events.append({"type": "skill_cooldown", "amount": 0.18 + level * 0.03})
	return events


static func on_boss_hit(state: Dictionary, boss_pos: Vector2, damage: float) -> Array:
	if String(state.get("name", "")) != "Voraz" or damage <= 0.0:
		return []
	if float(state.get("voracious_boss_feed_cd", 0.0)) > 0.0:
		return []
	var level := int(state.get("level", 0))
	var value := clampf(8.0 + sqrt(damage) * 0.32 + level * 0.8, 9.0, 18.0)
	var drops: Array = state.get("voracious_drops", [])
	drops.append({
		"pos": boss_pos + Vector2.from_angle(randf_range(0.0, TAU)) * randf_range(18.0, 54.0),
		"life": 5.0,
		"value": value,
		"boss_particle": true,
	})
	state["voracious_drops"] = drops
	state["voracious_boss_feed_cd"] = maxf(0.16, 0.30 - level * 0.018)
	return []

static func on_player_hit(state: Dictionary, amount: float, hp: float, hp_max: float) -> Dictionary:
	var result := {"blocked": false, "amount": amount, "heal": 0.0, "events": []}
	match String(state.get("name", "")):
		"Impulsiva":
			if float(state["impulsive_active"]) > 0.0:
				state["impulsive_panic"] = maxi(1, int(state["impulsive_rank"]))
				state["impulsive_active"] = 0.0
				state["impulsive_rank"] = 0
				result["events"].append({"type": "text", "text": "PANICO ARMADO"})
			elif int(state["impulsive_panic"]) > 0:
				result["amount"] = amount * (2.0 + 0.5 * int(state["impulsive_panic"]))
				state["impulsive_panic"] = 0
		"Devota":
			if int(state["devoted_charges"]) > 0:
				state["devoted_charges"] = int(state["devoted_charges"]) - 1
				result["blocked"] = true
				result["amount"] = 0.0
				result["heal"] = maxf(3.0, (hp_max - hp) * 0.10)
				state["devoted_damage"] = 3.0
				state["devoted_damage_mult"] = 1.25
				if int(state["devoted_charges"]) <= 0:
					state["devoted_damage"] = 4.5
					state["devoted_damage_mult"] = 1.65
					state["devoted_slow"] = 4.5
					state["devoted_recharge"] = maxf(9.5, 22.0 - int(state["level"]) * 2.5)
		"Vanguarda":
			state["vanguard_ring"] = 5.0
	return result

static func on_dash(state: Dictionary) -> Array:
	var events: Array = []
	match String(state.get("name", "")):
		"Racional":
			if float(state["rational_cooldown"]) <= 0.0:
				state["rational_dilation"] = RATIONAL_DILATION_TIME
				state["rational_rebound"] = RATIONAL_DILATION_TIME + RATIONAL_REBOUND_TIME
				state["rational_cooldown"] = RATIONAL_DILATION_TIME + RATIONAL_COOLDOWN
				events.append({"type": "text", "text": "DILATACAO TEMPORAL"})
		"Insana":
			if bool(state["insane_dash_penalty"]):
				state["insane_dash_penalty"] = false
				events.append({"type": "dash_penalty", "amount": 2.0})
	return events

static func speed_multiplier(state: Dictionary) -> float:
	match String(state.get("name", "")):
		"Racional": return 1.35 if float(state["rational_dilation"]) > 0.0 else 1.0
		"Impulsiva": return 1.2 * (1.0 + 0.15 * int(state["impulsive_rank"])) if float(state["impulsive_active"]) > 0.0 else 1.0
		"Devota": return 0.90 if float(state["devoted_slow"]) > 0.0 else 1.0
		"Abissal": return maxf(0.78, 1.0 - float(state["abyss_depth"]) * 0.0016 - (0.04 if float(state["abyss_tide"]) > 0.0 else 0.0))
		"Sanguinaria": return 0.95 if float(state["blood_slow"]) > 0.0 else 1.0
	return 1.0

static func damage_multiplier(state: Dictionary) -> float:
	match String(state.get("name", "")):
		"Impulsiva": return 1.3 * (1.0 + 0.15 * int(state["impulsive_rank"])) if float(state["impulsive_active"]) > 0.0 else 1.0
		"Devota": return float(state["devoted_damage_mult"]) if float(state["devoted_damage"]) > 0.0 else 1.0
	return 1.0

static func attack_interval_multiplier(state: Dictionary) -> float:
	if String(state.get("name", "")) == "Racional" and float(state["rational_dilation"]) > 0.0: return 0.72
	if String(state.get("name", "")) == "Voraz": return maxf(0.88, 1.0 - voracious_intensity(state) * (0.045 + int(state["level"]) * 0.003))
	return 1.0

static func world_multiplier(state: Dictionary) -> float:
	if String(state.get("name", "")) != "Racional": return 1.0
	if float(state["rational_dilation"]) > 0.0: return 0.42
	if float(state["rational_rebound"]) > 0.0 and float(state["rational_dilation"]) <= 0.0: return 1.18
	return 1.0

static func dash_cooldown_multiplier(state: Dictionary, burning_count := 0) -> float:
	var value := 1.0
	match String(state.get("name", "")):
		"Vanguarda": value += burning_count * 0.15
		"Nula": value = 1.04 if float(state["null_charge"]) > 0.0 else 1.0
		"Abissal": value = 1.0 + float(state["abyss_depth"]) * 0.001 + (0.08 if float(state["abyss_tide"]) > 0.0 else 0.0)
		"Profetica": value = 1.12 if float(state["prophecy_broken"]) > 0.0 else 1.0
	return value

static func hunger_max(state: Dictionary) -> float:
	var cycles := int(state.get("voracious_cycles", 0))
	return VORACIOUS_BASE_MAX + cycles * 54.0 + cycles * cycles * 9.0

static func voracious_intensity(state: Dictionary) -> float:
	return minf(1.85, float(state.get("voracious_hunger", 0.0)) / maxf(1.0, hunger_max(state)) + int(state.get("voracious_cycles", 0)) * 0.12)

static func _update_voracious(state: Dictionary, delta: float, context: Dictionary, events: Array) -> void:
	var cycles := int(state["voracious_cycles"])
	var ratio := float(state["voracious_hunger"]) / maxf(1.0, hunger_max(state))
	state["voracious_hunger"] = float(state["voracious_hunger"]) - (7.2 + cycles * 2.25 + ratio * ratio * 5.4) * delta
	while float(state["voracious_hunger"]) < 0.0 and cycles > 0:
		cycles -= 1
		state["voracious_cycles"] = cycles
		state["voracious_hunger"] = float(state["voracious_hunger"]) + hunger_max(state)
	state["voracious_hunger"] = maxf(0.0, float(state["voracious_hunger"]))
	state["voracious_last_collect"] = float(state["voracious_last_collect"]) + delta
	state["voracious_drain_tick"] = maxf(0.0, float(state["voracious_drain_tick"]) - delta)
	state["voracious_boss_feed_cd"] = maxf(0.0, float(state.get("voracious_boss_feed_cd", 0.0)) - delta)
	var player_pos := Vector2(context.get("player_pos", Vector2.ZERO))
	var kept: Array = []
	for drop in Array(state["voracious_drops"]):
		drop["life"] = float(drop["life"]) - delta
		if float(drop["life"]) <= 0.0: continue
		if bool(drop.get("boss_particle", false)):
			var to_player := player_pos - Vector2(drop["pos"])
			if to_player.length() > 0.01:
				drop["pos"] = Vector2(drop["pos"]) + to_player.normalized() * minf(to_player.length(), (250.0 + to_player.length() * 0.55) * delta)
		if player_pos.distance_to(Vector2(drop["pos"])) <= 68.0:
			state["voracious_hunger"] = float(state["voracious_hunger"]) + float(drop["value"]) * pow(0.94, cycles)
			state["voracious_last_collect"] = 0.0
			state["voracious_drain_tick"] = 1.5
			while float(state["voracious_hunger"]) >= hunger_max(state):
				state["voracious_hunger"] = float(state["voracious_hunger"]) - hunger_max(state)
				state["voracious_cycles"] = int(state["voracious_cycles"]) + 1
			events.append({"type": "heal_lost", "ratio": minf(0.145, 0.02 + int(state["voracious_cycles"]) * 0.025), "text": "COAGULO"})
		else: kept.append(drop)
	state["voracious_drops"] = kept
	if float(state["voracious_last_collect"]) >= 30.0 and float(state["voracious_drain_tick"]) <= 0.0:
		state["voracious_drain_tick"] = 1.5
		events.append({"type": "player_damage", "ratio": 0.01, "source": "fome"})

static func _update_prophecy(state: Dictionary, enemies: Array, events: Array) -> void:
	if int(state["prophecy_uid"]) >= 0 and float(state["prophecy_time"]) <= 0.0:
		state["prophecy_uid"] = -1
		state["prophecy_sequence"] = 0
		state["prophecy_broken"] = 3.5
		events.append({"type": "text", "text": "DESTINO QUEBRADO"})
	if int(state["prophecy_uid"]) < 0 and float(state["prophecy_next"]) <= 0.0:
		var candidates := enemies.filter(func(e): return float(e.get("hp", 0.0)) > 0.0)
		if not candidates.is_empty():
			var enemy: Dictionary = candidates[randi() % candidates.size()]
			state["prophecy_uid"] = int(enemy.get("uid", -1))
			state["prophecy_time"] = 6.4
			state["prophecy_next"] = maxf(6.2, 11.0 - int(state["level"]) * 0.85)
			enemy["aura_prophecy"] = 6.4

static func _apply_blood_hit(state: Dictionary, enemy: Dictionary, result: Dictionary) -> void:
	var uid := int(enemy.get("uid", -1))
	var hits: Dictionary = state["blood_hits"]
	var data: Dictionary = hits.get(uid, {"count": 0, "time": 0.0})
	data["time"] = 0.0
	data["count"] = int(data["count"]) + 1
	hits[uid] = data
	var level := int(state["level"])
	if float(enemy.get("aura_wound", 0.0)) <= 0.0 and int(data["count"]) >= (2 if level >= 5 else 3):
		enemy["aura_wound"] = 7.8 + level * 0.45
		state["blood_wounds"] = int(state["blood_wounds"]) + 1
		state["blood_thirst"] = minf(100.0, float(state["blood_thirst"]) + 12.0 + level * 2.0)
		state["blood_last_wound"] = 0.01
		result["events"].append({"type": "text", "text": "FERIDA ABERTA"})
	if float(enemy.get("aura_wound", 0.0)) > 0.0:
		result["damage"] = float(result["damage"]) * (1.12 + level * 0.035 + float(state["blood_thirst"]) / 100.0 * 0.14)
		state["blood_last_wound"] = 0.01
		if bool(state["blood_burst"]):
			result["damage"] = float(result["damage"]) * 1.35
			state["blood_burst"] = false
			state["blood_wounds"] = 0
			result["events"].append({"type": "text", "text": "CARNIFICINA"})
	if int(state["blood_wounds"]) >= (3 if level >= 5 else 4): state["blood_burst"] = true
