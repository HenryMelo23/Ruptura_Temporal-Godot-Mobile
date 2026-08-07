class_name AuraSystem
extends RefCounted

const AURA_NAMES: = ["Racional", "Impulsiva", "Devota", "Vanguarda", "Insana", "Voraz", "Nula", "Abissal", "Profetica", "Sanguinaria", "Crepuscular", "Peregrino", "Equilibrista", "Avarento", "Oportunista"]
const RUN_MAX_LEVEL: = 10

const COLORS: = {
	"Racional": Color(0.0, 0.71, 1.0), 
	"Impulsiva": Color(1.0, 0.24, 0.24), 
	"Devota": Color(1.0, 0.78, 0.0), 
	"Vanguarda": Color(0.9, 0.0, 0.9), 
	"Insana": Color(0.63, 0.22, 1.0), 
	"Voraz": Color(1.0, 0.44, 0.09), 
	"Nula": Color(0.71, 0.92, 1.0), 
	"Abissal": Color(0.31, 0.31, 0.75), 
	"Profetica": Color(1.0, 0.92, 0.43), 
	"Sanguinaria": Color(1.0, 0.18, 0.25), 
	"Crepuscular": Color(0.98, 0.58, 1.0), 
	"Peregrino": Color(0.3, 0.92, 0.74), 
	"Equilibrista": Color(0.92, 0.88, 0.5), 
	"Avarento": Color(1.0, 0.72, 0.18), 
	"Oportunista": Color(1.0, 0.86, 0.24), 
}

const RATIONAL_STILL_TIME: = 4.5
const RATIONAL_DILATION_TIME: = 8.0
const RATIONAL_REBOUND_TIME: = 3.0
const RATIONAL_COOLDOWN: = 30.0
const IMPULSIVE_KILLS: = 5
const DEVOTED_CHARGES: = 3
const VORACIOUS_BASE_MAX: = 100.0
const INSANE_ECHO_DELAY: = 1.0
const INSANE_ECHO_BASE: = 4
const NULL_IDLE_TIME: = 2.3
const CREPUSCULAR_PHASE_TIME: = 8.0
const PEREGRINO_SECTOR_SIZE: = 300.0
const PEREGRINO_REFUGE_RADIUS: = 85.0
const OPPORTUNITY_ENEMY_COOLDOWN: = 0.75

static func create(aura: String, level: = 1) -> Dictionary:
	return {
		"name": aura if aura in AURA_NAMES else "Racional", 
		"level": clampi(level, 1, RUN_MAX_LEVEL), 
		"ascended": false, 
		"ascension_name": "", 
		"ascension_flash": 0.0, 
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
		"crepuscular_phase": "alvorada", 
		"crepuscular_phase_timer": CREPUSCULAR_PHASE_TIME, 
		"crepuscular_charge": 0.0, 
		"crepuscular_eclipse": 0.0, 
		"crepuscular_after_eclipse": "ocaso", 
		"crepuscular_no_damage": 0.0, 
		"peregrino_sector": Vector2i(999999, 999999), 
		"peregrino_recent": [], 
		"peregrino_steps": 0, 
		"peregrino_journey": 0.0, 
		"peregrino_refuge_pos": Vector2.ZERO, 
		"peregrino_refuge_active": false, 
		"peregrino_sequence_start": Vector2.ZERO, 
		"peregrino_idle": 0.0, 
		"peregrino_decay": 0.0, 
		"peregrino_trails": [], 
		"peregrino_trail_speed": 0.0, 
		"equilibrista_balance": 0.0, 
		"equilibrista_state": 0.0, 
		"equilibrista_debt": 0.0, 
		"equilibrista_debt_timer": 0.0, 
		"equilibrista_shield": 0.0, 
		"equilibrista_lock": 0.0, 
		"avarento_lastro": 0.0, 
		"avarento_cofre": 0.0, 
		"avarento_shield": 0.0, 
		"avarento_weight_suspension": 0.0, 
		"avarento_fragments": [], 
		"avarento_cache_score": -999999, 
		"avarento_cache_cost": -1, 
		"oportunista_charges": 0, 
		"oportunista_armed": false, 
		"oportunista_decay": 0.0, 
		"oportunista_enemy_cd": {}, 
	}

static func _rank(state: Dictionary) -> int:
	return clampi(int(state.get("level", 1)), 1, RUN_MAX_LEVEL)


static func run_upgrade_cost(next_level: int) -> int:
	var costs: = {2: 5, 3: 9, 4: 15, 5: 24, 6: 38, 7: 58, 8: 86, 9: 124, 10: 180}
	return int(costs.get(clampi(next_level, 2, RUN_MAX_LEVEL), 9999))


static func ascension_title(aura_name: String) -> String:
	match aura_name:
		"Racional": return "Mente de Laplace"
		"Devota": return "Voto Inquebravel"
		"Voraz": return "Abismo Digestivo"
		"Crepuscular": return "Eclipse Soberano"
		"Peregrino": return "Caminho Inevitavel"
		"Equilibrista": return "Prumo Absoluto"
		"Avarento": return "Cofre Vivo"
		"Oportunista": return "Brecha Final"
	return "Ascensao Espectral"


static func apply_run_upgrade(state: Dictionary, new_level: int) -> Array:
	var previous: = _rank(state)
	state["level"] = clampi(new_level, 1, RUN_MAX_LEVEL)
	var events: Array = []
	if int(state["level"]) == 5 and previous < 5:
		events.append({"type": "text", "text": "MARCO ESPECTRAL"})
	if int(state["level"]) == 9 and previous < 9:
		events.append({"type": "text", "text": "PRE-ASCENSAO"})
	if int(state["level"]) >= RUN_MAX_LEVEL and not bool(state.get("ascended", false)):
		events.append_array(ascend(state))
	return events


static func ascend(state: Dictionary) -> Array:
	var aura_name: = String(state.get("name", "Racional"))
	state["ascended"] = true
	state["ascension_name"] = ascension_title(aura_name)
	state["ascension_flash"] = 3.8
	match aura_name:
		"Devota":
			state["devoted_charges"] = max(int(state.get("devoted_charges", 0)), DEVOTED_CHARGES + 1)
		"Voraz":
			state["voracious_hunger"] = minf(hunger_max(state), float(state.get("voracious_hunger", 0.0)) + 35.0)
		"Crepuscular":
			state["crepuscular_charge"] = maxf(float(state.get("crepuscular_charge", 0.0)), 60.0)
		"Peregrino":
			state["peregrino_journey"] = maxf(float(state.get("peregrino_journey", 0.0)), 3.0)
		"Equilibrista":
			state["equilibrista_balance"] = maxf(float(state.get("equilibrista_balance", 0.0)), 50.0)
		"Avarento":
			state["avarento_cofre"] = maxf(float(state.get("avarento_cofre", 0.0)), 4.0)
		"Oportunista":
			state["oportunista_charges"] = _oportunista_required(state)
			state["oportunista_armed"] = true
	return [{"type": "ascension", "text": String(state["ascension_name"])}]

static func _is_direct_category(category: String) -> bool:
	return category in ["basic_attack", "skill_q", "skill_e", "teleport", "manifestation_secondary"]

static func _crepuscular_is_eclipse(state: Dictionary) -> bool:
	return float(state.get("crepuscular_eclipse", 0.0)) > 0.0

static func _crepuscular_phase_bonus_factor(state: Dictionary, phase_name: String) -> float:
	if _crepuscular_is_eclipse(state):
		return 0.65
	return 1.0 if String(state.get("crepuscular_phase", "")) == phase_name else 0.0

static func _crepuscular_defense_ratio(state: Dictionary) -> float:
	return minf(0.35, 0.1 + 0.025 * _rank(state)) * _crepuscular_phase_bonus_factor(state, "alvorada")

static func _crepuscular_damage_bonus(state: Dictionary) -> float:
	return (0.1 + 0.035 * _rank(state)) * _crepuscular_phase_bonus_factor(state, "ocaso")

static func _crepuscular_attack_reduction(state: Dictionary) -> float:
	return minf(0.25, 0.04 + 0.02 * _rank(state)) * _crepuscular_phase_bonus_factor(state, "ocaso")

static func _crepuscular_perfect_window(state: Dictionary) -> bool:
	if _crepuscular_is_eclipse(state):
		return false
	var window: = 0.7 + 0.08 * _rank(state)
	return float(state.get("crepuscular_phase_timer", 0.0)) <= window

static func _crepuscular_gain_charge(state: Dictionary, amount: float) -> void :
	state["crepuscular_charge"] = clampf(float(state.get("crepuscular_charge", 0.0)) + amount, 0.0, 100.0)

static func _crepuscular_activate_eclipse(state: Dictionary, next_phase: String) -> Array:
	state["crepuscular_charge"] = 0.0
	state["crepuscular_eclipse"] = 2.7 + 0.3 * _rank(state)
	state["crepuscular_after_eclipse"] = next_phase
	return [{"type": "text", "text": "ECLIPSE"}]

static func _crepuscular_toggle_phase(state: Dictionary) -> void :
	var next_phase: = "ocaso" if String(state.get("crepuscular_phase", "alvorada")) == "alvorada" else "alvorada"
	state["crepuscular_phase"] = next_phase
	state["crepuscular_phase_timer"] = CREPUSCULAR_PHASE_TIME
	state["crepuscular_no_damage"] = 0.0

static func _peregrino_steps_required(state: Dictionary) -> int:
	return max(3, 5 - int(floor(float(_rank(state) - 1) / 2.0)))

static func _peregrino_sector_for(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / PEREGRINO_SECTOR_SIZE)), int(floor(pos.y / PEREGRINO_SECTOR_SIZE)))

static func _peregrino_grant_step(state: Dictionary, sector: Vector2i, pos: Vector2, amount: = 1) -> Array:
	var events: Array = []
	if float(state.get("peregrino_journey", 0.0)) > 0.0:
		return events
	var recent: Array = state.get("peregrino_recent", [])
	if recent.has(sector):
		return events
	if int(state.get("peregrino_steps", 0)) <= 0:
		state["peregrino_sequence_start"] = pos
	state["peregrino_sector"] = sector
	recent.append(sector)
	while recent.size() > 3:
		recent.pop_front()
	state["peregrino_recent"] = recent
	state["peregrino_steps"] = mini(_peregrino_steps_required(state), int(state.get("peregrino_steps", 0)) + amount)
	state["peregrino_idle"] = 0.0
	state["peregrino_decay"] = 0.0
	if int(state["peregrino_steps"]) >= _peregrino_steps_required(state):
		state["peregrino_steps"] = 0
		state["peregrino_journey"] = 5.0 + 0.55 * _rank(state)
		state["peregrino_refuge_pos"] = Vector2(state.get("peregrino_sequence_start", pos))
		state["peregrino_refuge_active"] = true
		events.append({"type": "text", "text": "JORNADA"})
	return events

static func _equilibrista_shield_cap(state: Dictionary, hp_max: float) -> float:
	return (0.15 + 0.02 * _rank(state)) * hp_max

static func _avarento_recalculate(state: Dictionary, score: int, card_cost: int) -> void :
	if int(state.get("avarento_cache_score", -999999)) == score and int(state.get("avarento_cache_cost", -1)) == card_cost:
		return
	state["avarento_cache_score"] = score
	state["avarento_cache_cost"] = card_cost
	state["avarento_lastro"] = log(1.0 + float(max(0, score)) / max(1.0, float(max(1, card_cost)))) / log(2.0)

static func _oportunista_required(state: Dictionary) -> int:
	return max(2, 4 - int(floor(float(_rank(state) - 1) / 2.0)))

static func _enemy_in_opening(enemy: Dictionary) -> bool:
	if float(enemy.get("stun", 0.0)) > 0.0:
		return true
	if float(enemy.get("prepare", 0.0)) > 0.0 or float(enemy.get("nexus_casting", 0.0)) > 0.0:
		return true
	if bool(enemy.get("sprint_active", false)) or bool(enemy.get("alerted", false)):
		return true
	var shoot_cd: = float(enemy.get("shoot_cd", 99.0))
	var throw_cd: = float(enemy.get("throw_cd", 99.0))
	if shoot_cd <= 0.28 or throw_cd <= 0.28:
		return true
	return String(enemy.get("state", "")) in ["recovering", "preparing", "casting", "recoil"]

static func _oportunista_register_opening(state: Dictionary, enemy: Dictionary, events: Array) -> void :
	if String(state.get("name", "")) != "Oportunista" or bool(state.get("oportunista_armed", false)):
		return
	var uid: = str(enemy.get("uid", "boss"))
	var cds: Dictionary = state.get("oportunista_enemy_cd", {})
	if float(cds.get(uid, 0.0)) > 0.0:
		return
	cds[uid] = OPPORTUNITY_ENEMY_COOLDOWN
	state["oportunista_enemy_cd"] = cds
	state["oportunista_charges"] = mini(_oportunista_required(state), int(state.get("oportunista_charges", 0)) + 1)
	state["oportunista_decay"] = 0.0
	events.append({"type": "text", "text": "ABERTURA"})
	if int(state["oportunista_charges"]) >= _oportunista_required(state):
		state["oportunista_charges"] = _oportunista_required(state)
		state["oportunista_armed"] = true
		events.append({"type": "text", "text": "OPORTUNIDADE ARMADA"})

static func update(state: Dictionary, delta: float, context: Dictionary) -> Array:
	var events: Array = []
	var name: = String(state.get("name", ""))
	var level: = int(state.get("level", 0))
	var player_pos: = Vector2(context.get("player_pos", Vector2.ZERO))
	var enemies: Array = context.get("enemies", [])
	state["last_attack"] = float(state.get("last_attack", 0.0)) + delta
	state["ascension_flash"] = maxf(0.0, float(state.get("ascension_flash", 0.0)) - delta)
	for key in ["rational_dilation", "rational_rebound", "rational_cooldown", "impulsive_active", "devoted_damage", "devoted_slow", "vanguard_ring", "insane_ready", "abyss_tide", "prophecy_next", "prophecy_time", "prophecy_broken", "blood_slow"]:
		state[key] = maxf(0.0, float(state.get(key, 0.0)) - delta)

	match name:
		"Crepuscular":
			if float(state.get("crepuscular_eclipse", 0.0)) > 0.0:
				var before: = float(state["crepuscular_eclipse"])
				state["crepuscular_eclipse"] = maxf(0.0, before - delta)
				if before > 0.0 and float(state["crepuscular_eclipse"]) <= 0.0:
					state["crepuscular_phase"] = String(state.get("crepuscular_after_eclipse", "alvorada"))
					state["crepuscular_phase_timer"] = CREPUSCULAR_PHASE_TIME
					state["crepuscular_no_damage"] = 0.0
			else:
				state["crepuscular_phase_timer"] = maxf(0.0, float(state.get("crepuscular_phase_timer", CREPUSCULAR_PHASE_TIME)) - delta)
				if String(state.get("crepuscular_phase", "alvorada")) == "alvorada":
					state["crepuscular_no_damage"] = float(state.get("crepuscular_no_damage", 0.0)) + delta
					if float(state["crepuscular_no_damage"]) > 1.5:
						_crepuscular_gain_charge(state, 8.0 * delta)
				if float(state["crepuscular_phase_timer"]) <= 0.0:
					var next_phase: = "ocaso" if String(state.get("crepuscular_phase", "alvorada")) == "alvorada" else "alvorada"
					if float(state.get("crepuscular_charge", 0.0)) >= 100.0:
						events.append_array(_crepuscular_activate_eclipse(state, next_phase))
					else:
						_crepuscular_toggle_phase(state)
		"Peregrino":
			state["peregrino_trail_speed"] = maxf(0.0, float(state.get("peregrino_trail_speed", 0.0)) - delta)
			var trails: Array = state.get("peregrino_trails", [])
			for trail in trails:
				trail["life"] = float(trail.get("life", 0.0)) - delta
			state["peregrino_trails"] = trails.filter( func(t): return float(t.get("life", 0.0)) > 0.0)
			var sector: = _peregrino_sector_for(player_pos)
			if sector != Vector2i(state.get("peregrino_sector", Vector2i(999999, 999999))):
				events.append_array(_peregrino_grant_step(state, sector, player_pos, 1))
			elif float(state.get("peregrino_journey", 0.0)) <= 0.0:
				state["peregrino_idle"] = float(state.get("peregrino_idle", 0.0)) + delta
				if float(state["peregrino_idle"]) >= 4.0:
					state["peregrino_decay"] = float(state.get("peregrino_decay", 0.0)) + delta
					if float(state["peregrino_decay"]) >= 2.0:
						state["peregrino_decay"] = 0.0
						state["peregrino_steps"] = maxi(0, int(state.get("peregrino_steps", 0)) - 1)
			if float(state.get("peregrino_journey", 0.0)) > 0.0:
				state["peregrino_journey"] = maxf(0.0, float(state["peregrino_journey"]) - delta)
				events.append({"type": "heal_missing_ratio", "ratio": (0.002 + 0.0005 * level) * delta})
				if bool(state.get("peregrino_refuge_active", false)) and player_pos.distance_to(Vector2(state.get("peregrino_refuge_pos", player_pos))) <= PEREGRINO_REFUGE_RADIUS:
					state["peregrino_journey"] = 0.0
					state["peregrino_refuge_active"] = false
					events.append({"type": "heal_missing_ratio", "ratio": 0.04 + 0.01 * level, "text": "REFUGIO"})
				elif float(state["peregrino_journey"]) <= 0.0:
					state["peregrino_refuge_active"] = false
		"Equilibrista":
			state["equilibrista_lock"] = maxf(0.0, float(state.get("equilibrista_lock", 0.0)) - delta)
			var hp: = float(context.get("hp", 0.0))
			var hp_max: = maxf(1.0, float(context.get("hp_max", 1.0)))
			var hp_ratio: = hp / hp_max
			if float(state.get("equilibrista_state", 0.0)) > 0.0:
				state["equilibrista_state"] = maxf(0.0, float(state["equilibrista_state"]) - delta)
			elif float(state.get("equilibrista_lock", 0.0)) <= 0.0:
				if hp_ratio >= 0.35 and hp_ratio <= 0.8:
					state["equilibrista_balance"] = minf(100.0, float(state.get("equilibrista_balance", 0.0)) + (14.0 + 2.0 * level) * delta)
				else:
					state["equilibrista_balance"] = maxf(0.0, float(state.get("equilibrista_balance", 0.0)) - maxf(5.0, 13.0 - level) * delta)
				if float(state["equilibrista_balance"]) >= 100.0:
					state["equilibrista_balance"] = 0.0
					state["equilibrista_state"] = 5.5 + 0.5 * level
					events.append({"type": "text", "text": "EQUILIBRIO"})
			if float(state.get("equilibrista_debt", 0.0)) > 0.0:
				state["equilibrista_debt_timer"] = float(state.get("equilibrista_debt_timer", 0.0)) - delta
				if float(state["equilibrista_debt_timer"]) <= 0.0:
					var chunk: float = minf(float(state["equilibrista_debt"]), hp_max * 0.045)
					state["equilibrista_debt"] = maxf(0.0, float(state["equilibrista_debt"]) - chunk)
					state["equilibrista_debt_timer"] = 0.65
					events.append({"type": "player_damage_flat", "amount": chunk, "source": "divida_equilibrista"})
		"Avarento":
			_avarento_recalculate(state, int(context.get("score", 0)), int(context.get("card_cost", 1)))
			state["avarento_cofre"] = maxf(0.0, float(state.get("avarento_cofre", 0.0)) - delta)
			state["avarento_weight_suspension"] = maxf(0.0, float(state.get("avarento_weight_suspension", 0.0)) - delta)
			if float(state.get("avarento_cofre", 0.0)) <= 0.0:
				state["avarento_shield"] = 0.0
			var fragments: Array = state.get("avarento_fragments", [])
			var kept_fragments: Array = []
			for frag in fragments:
				frag["life"] = float(frag.get("life", 0.0)) - delta
				if float(frag["life"]) <= 0.0:
					continue
				if player_pos.distance_to(Vector2(frag.get("pos", player_pos))) <= 48.0:
					state["avarento_shield"] = maxf(float(state.get("avarento_shield", 0.0)), maxf(6.0, float(context.get("hp_max", 100.0)) * 0.035))
					state["avarento_weight_suspension"] = maxf(float(state.get("avarento_weight_suspension", 0.0)), 0.35)
					events.append({"type": "text", "text": "LASTRO"})
				else:
					kept_fragments.append(frag)
			state["avarento_fragments"] = kept_fragments
		"Oportunista":
			var cds: Dictionary = state.get("oportunista_enemy_cd", {})
			for uid in cds.keys():
				cds[uid] = maxf(0.0, float(cds[uid]) - delta)
			state["oportunista_enemy_cd"] = cds
			if not bool(state.get("oportunista_armed", false)):
				state["oportunista_decay"] = float(state.get("oportunista_decay", 0.0)) + delta
				if float(state["oportunista_decay"]) >= 12.0 and int(state.get("oportunista_charges", 0)) > 0:
					state["oportunista_decay"] = 8.0
					state["oportunista_charges"] = maxi(0, int(state["oportunista_charges"]) - 1)
		"Racional":
			var moved: = player_pos.distance_to(Vector2(state.get("last_pos", player_pos)))
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
			state["insane_queue"] = queue.filter( func(e): return float(e["delay"]) > 0.0)
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
					var dist: = player_pos.distance_to(Vector2(enemy.get("pos", player_pos)))
					if dist <= 190.0:
						var direction: = (player_pos - Vector2(enemy["pos"])).normalized()
						enemy["pos"] = Vector2(enemy["pos"]) + direction * (33.0 + level * 2.4) * delta
						if float(enemy.get("hp", 1.0)) / maxf(1.0, float(enemy.get("max_hp", 1.0))) <= 0.2 + level * 0.015:
							events.append({"type": "enemy_damage", "uid": int(enemy.get("uid", -1)), "amount": maxf(1.0, float(enemy.get("max_hp", 1.0)) * (0.01 + level * 0.0015) * delta * 60.0), "source": "aura_abissal"})
			else:
				var nearby: = 0
				for enemy in enemies:
					if player_pos.distance_to(Vector2(enemy.get("pos", player_pos))) <= 190.0: nearby += 1
				state["abyss_depth"] = minf(100.0, float(state["abyss_depth"]) + (enemies.size() * 0.2 + nearby * 0.52 + (0.42 if bool(context.get("boss_active", false)) else 0.0)) * delta * (1.0 + level * 0.08))
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
	var result: = {"damage": damage, "events": []}
	var level: = _rank(state)
	var category: = String(projectile.get("source_category", "basic_attack"))
	var direct_hit: = _is_direct_category(category) and not String(projectile.get("kind", "")).begins_with("aura_")
	match String(state.get("name", "")):
		"Crepuscular":
			if direct_hit and String(state.get("crepuscular_phase", "")) == "ocaso" and not _crepuscular_is_eclipse(state):
				var base_damage: = maxf(1.0, float(projectile.get("player_damage", damage)))
				_crepuscular_gain_charge(state, clampf(damage / base_damage * 4.0, 1.0, 12.0))
		"Oportunista":
			if direct_hit:
				var was_armed: = bool(state.get("oportunista_armed", false))
				if _enemy_in_opening(enemy):
					_oportunista_register_opening(state, enemy, result["events"])
				if was_armed:
					result["damage"] = float(result["damage"]) + float(projectile.get("player_damage", damage)) * (0.5 + 0.12 * level)
					state["oportunista_armed"] = false
					state["oportunista_charges"] = 0
					var delay: = 0.28 + 0.08 * level
					enemy["shoot_cd"] = float(enemy.get("shoot_cd", 0.0)) + delay
					enemy["throw_cd"] = float(enemy.get("throw_cd", 0.0)) + delay
					enemy["stun"] = maxf(float(enemy.get("stun", 0.0)), delay * (0.5 if bool(enemy.get("elite", false)) else 1.0))
					result["events"].append({"type": "cooldown_recovery", "amount": 0.5 + 0.15 * level, "max_ratio": 0.3})
					result["events"].append({"type": "text", "text": "GOLPE DE OPORTUNIDADE"})
		"Nula":
			if bool(projectile.get("aura_null", false)):
				enemy["aura_null"] = 4.2 + level * 0.35
				if float(enemy.get("hp", 1.0)) / maxf(1.0, float(enemy.get("max_hp", 1.0))) >= 0.55:
					result["damage"] = damage * (1.18 + level * 0.035)
		"Abissal":
			var ratio: = float(enemy.get("hp", 1.0)) / maxf(1.0, float(enemy.get("max_hp", 1.0)))
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
	var level: = _rank(state)
	match String(state.get("name", "")):
		"Crepuscular":
			if String(state.get("crepuscular_phase", "")) == "ocaso" and not _crepuscular_is_eclipse(state):
				_crepuscular_gain_charge(state, 15.0 if bool(enemy.get("elite", false)) or String(enemy.get("type", "")).find("boss") >= 0 else 8.0)
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
				var bonus: = 35 + level * 15 + int(state["prophecy_sequence"]) * 10
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
	if damage <= 0.0:
		return []
	if String(state.get("name", "")) == "Crepuscular" and String(state.get("crepuscular_phase", "")) == "ocaso" and not _crepuscular_is_eclipse(state):
		_crepuscular_gain_charge(state, clampf(sqrt(damage) * 0.45, 2.0, 15.0))
	if String(state.get("name", "")) != "Voraz":
		return []
	if float(state.get("voracious_boss_feed_cd", 0.0)) > 0.0:
		return []
	var level: = _rank(state)
	var value: = clampf(3.2 + sqrt(damage) * 0.12 + level * 0.32, 4.0, 8.5)
	var drops: Array = state.get("voracious_drops", [])
	drops.append({
		"pos": boss_pos + Vector2.from_angle(randf_range(0.0, TAU)) * randf_range(18.0, 54.0), 
		"life": 4.2, 
		"value": value, 
		"boss_particle": true, 
	})
	state["voracious_drops"] = drops
	state["voracious_boss_feed_cd"] = maxf(0.85, 1.45 - level * 0.06)
	return []

static func on_player_hit(state: Dictionary, amount: float, hp: float, hp_max: float) -> Dictionary:
	var result: = {"blocked": false, "amount": amount, "heal": 0.0, "events": []}
	var level: = _rank(state)
	match String(state.get("name", "")):
		"Crepuscular":
			state["crepuscular_no_damage"] = 0.0
			state["crepuscular_charge"] = maxf(0.0, float(state.get("crepuscular_charge", 0.0)) - 18.0)
			var reduction: = _crepuscular_defense_ratio(state)
			if reduction > 0.0:
				result["amount"] = amount * (1.0 - reduction)
		"Equilibrista":
			var shield: = float(state.get("equilibrista_shield", 0.0))
			if shield > 0.0:
				var absorbed: = minf(shield, amount)
				state["equilibrista_shield"] = shield - absorbed
				result["amount"] = maxf(0.0, amount - absorbed)
				if absorbed > 0.0:
					result["events"].append({"type": "text", "text": "ESCUDO %.0f" % absorbed})
			var incoming: = float(result.get("amount", amount))
			var before_ratio: = hp / maxf(1.0, hp_max)
			var after_ratio: = (hp - incoming) / maxf(1.0, hp_max)
			if before_ratio > 0.35 and after_ratio < 0.35 and float(state.get("equilibrista_debt", 0.0)) <= 0.0:
				var allowed: = maxf(0.0, hp - hp_max * 0.35)
				var debt: = maxf(0.0, incoming - allowed)
				result["amount"] = allowed
				state["equilibrista_debt"] = debt
				state["equilibrista_debt_timer"] = 0.65
				state["equilibrista_lock"] = 1.0
				result["events"].append({"type": "text", "text": "DIVIDA"})
		"Avarento":
			var av_shield: = float(state.get("avarento_shield", 0.0))
			if av_shield > 0.0:
				var av_absorb: = minf(av_shield, float(result.get("amount", amount)))
				state["avarento_shield"] = av_shield - av_absorb
				result["amount"] = maxf(0.0, float(result.get("amount", amount)) - av_absorb)
			var lastro: = float(state.get("avarento_lastro", 0.0))
			var protection: = minf(0.3, lastro * (0.025 + 0.01 * level))
			if protection > 0.0:
				result["amount"] = float(result.get("amount", amount)) * (1.0 - protection)
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
				result["heal"] = maxf(3.0, (hp_max - hp) * 0.1)
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

static func on_dash(state: Dictionary, context: = {}) -> Array:
	var events: Array = []
	match String(state.get("name", "")):
		"Crepuscular":
			if _crepuscular_perfect_window(state) and float(state.get("crepuscular_charge", 0.0)) >= 70.0:
				var next_phase: = "ocaso" if String(state.get("crepuscular_phase", "alvorada")) == "alvorada" else "alvorada"
				events.append_array(_crepuscular_activate_eclipse(state, next_phase))
		"Peregrino":
			var pos: = Vector2(context.get("target_pos", context.get("player_pos", Vector2.ZERO)))
			var sector: = _peregrino_sector_for(pos)
			events.append_array(_peregrino_grant_step(state, sector, pos, 2))
			state["peregrino_trail_speed"] = 1.8 + 0.2 * _rank(state)
			var trails: Array = state.get("peregrino_trails", [])
			trails.append({"pos": pos, "life": state["peregrino_trail_speed"], "max": state["peregrino_trail_speed"]})
			state["peregrino_trails"] = trails
		"Avarento":
			state["avarento_weight_suspension"] = maxf(float(state.get("avarento_weight_suspension", 0.0)), 1.5)
			var origin: = Vector2(context.get("origin_pos", context.get("player_pos", Vector2.ZERO)))
			var fragments: Array = state.get("avarento_fragments", [])
			for i in range(3):
				fragments.append({"pos": origin + Vector2.from_angle(float(i) * TAU / 3.0) * 38.0, "life": 3.0})
			state["avarento_fragments"] = fragments
		"Oportunista":
			if bool(context.get("escaped_telegraph", false)):
				state["oportunista_charges"] = mini(_oportunista_required(state), int(state.get("oportunista_charges", 0)) + 2)
				state["oportunista_decay"] = 0.0
				if int(state["oportunista_charges"]) >= _oportunista_required(state):
					state["oportunista_armed"] = true
					events.append({"type": "text", "text": "OPORTUNIDADE ARMADA"})
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
	var ascended: = bool(state.get("ascended", false))
	match String(state.get("name", "")):
		"Racional": return (1.45 if ascended else 1.35) if float(state["rational_dilation"]) > 0.0 else 1.0
		"Impulsiva": return 1.2 * (1.0 + 0.15 * int(state["impulsive_rank"])) if float(state["impulsive_active"]) > 0.0 else 1.0
		"Devota": return 0.9 if float(state["devoted_slow"]) > 0.0 else 1.0
		"Crepuscular": return 1.0 + (0.1 + 0.02 * _rank(state) if ascended else 0.08 + 0.02 * _rank(state)) if _crepuscular_is_eclipse(state) else 1.0
		"Peregrino":
			var mult: = 1.0
			if float(state.get("peregrino_journey", 0.0)) > 0.0:
				mult += 0.08 + 0.025 * _rank(state) + (0.08 if ascended else 0.0)
			if float(state.get("peregrino_trail_speed", 0.0)) > 0.0:
				mult += 0.08
			return mult
		"Avarento":
			var mult: = 1.0
			if float(state.get("avarento_cofre", 0.0)) > 0.0:
				mult += 0.08 + 0.02 * _rank(state) + minf(0.12, float(state.get("avarento_lastro", 0.0)) * 0.025)
			elif float(state.get("avarento_weight_suspension", 0.0)) <= 0.0:
				var penalty: = minf(0.15, float(state.get("avarento_lastro", 0.0)) * 0.022)
				var penalty_mult: = maxf(0.4, 1.0 - 0.1 * float(_rank(state) - 1))
				mult -= penalty * penalty_mult
			return maxf(0.72, mult)
		"Abissal": return maxf(0.78, 1.0 - float(state["abyss_depth"]) * 0.0016 - (0.04 if float(state["abyss_tide"]) > 0.0 else 0.0))
		"Sanguinaria": return 0.95 if float(state["blood_slow"]) > 0.0 else 1.0
	return 1.0

static func damage_multiplier(state: Dictionary) -> float:
	var ascended: = bool(state.get("ascended", false))
	match String(state.get("name", "")):
		"Impulsiva": return 1.3 * (1.0 + 0.15 * int(state["impulsive_rank"])) if float(state["impulsive_active"]) > 0.0 else 1.0
		"Devota": return (float(state["devoted_damage_mult"]) + (0.18 if ascended else 0.0)) if float(state["devoted_damage"]) > 0.0 else 1.0
		"Voraz": return 1.0 + (voracious_intensity(state) * 0.12 if ascended else 0.0)
		"Crepuscular": return 1.0 + _crepuscular_damage_bonus(state) + (0.08 if ascended and _crepuscular_is_eclipse(state) else 0.0)
		"Equilibrista": return 1.0 + (0.1 + 0.03 * _rank(state) if ascended and float(state.get("equilibrista_state", 0.0)) > 0.0 else 0.07 + 0.03 * _rank(state) if float(state.get("equilibrista_state", 0.0)) > 0.0 else 0.0)
		"Oportunista": return 1.08 if ascended and bool(state.get("oportunista_armed", false)) else 1.0
	return 1.0

static func attack_interval_multiplier(state: Dictionary) -> float:
	if String(state.get("name", "")) == "Racional" and float(state["rational_dilation"]) > 0.0: return 0.66 if bool(state.get("ascended", false)) else 0.72
	if String(state.get("name", "")) == "Voraz": return maxf(0.84 if bool(state.get("ascended", false)) else 0.88, 1.0 - voracious_intensity(state) * (0.045 + int(state["level"]) * 0.003))
	if String(state.get("name", "")) == "Crepuscular": return maxf(0.75, 1.0 - _crepuscular_attack_reduction(state))
	return 1.0

static func world_multiplier(state: Dictionary) -> float:
	if String(state.get("name", "")) != "Racional": return 1.0
	if float(state["rational_dilation"]) > 0.0: return 0.36 if bool(state.get("ascended", false)) else 0.42
	if float(state["rational_rebound"]) > 0.0 and float(state["rational_dilation"]) <= 0.0: return 1.08 if bool(state.get("ascended", false)) else 1.18
	return 1.0

static func dash_cooldown_multiplier(state: Dictionary, burning_count: = 0) -> float:
	var value: = 1.0
	match String(state.get("name", "")):
		"Vanguarda": value += burning_count * 0.15
		"Nula": value = 1.04 if float(state["null_charge"]) > 0.0 else 1.0
		"Abissal": value = 1.0 + float(state["abyss_depth"]) * 0.001 + (0.08 if float(state["abyss_tide"]) > 0.0 else 0.0)
		"Profetica": value = 1.12 if float(state["prophecy_broken"]) > 0.0 else 1.0
	return value

static func on_heal(state: Dictionary, applied: float, overheal: float, hp: float, hp_max: float) -> Dictionary:
	var result: = {"extra_heal": 0.0, "events": []}
	var level: = _rank(state)
	match String(state.get("name", "")):
		"Crepuscular":
			if String(state.get("crepuscular_phase", "")) == "alvorada" and not _crepuscular_is_eclipse(state) and applied > 0.0:
				_crepuscular_gain_charge(state, clampf(applied / maxf(1.0, hp_max) * 150.0, 1.0, 10.0))
				result["extra_heal"] = applied * (0.09 + 0.03 * level)
			elif String(state.get("crepuscular_phase", "")) == "ocaso" and not _crepuscular_is_eclipse(state) and applied > 0.0:
				result["extra_heal"] = - applied * 0.18
		"Equilibrista":
			if float(state.get("equilibrista_state", 0.0)) > 0.0 and overheal > 0.0:
				var converted: = overheal * (0.35 + 0.05 * level)
				state["equilibrista_shield"] = minf(_equilibrista_shield_cap(state, hp_max), float(state.get("equilibrista_shield", 0.0)) + converted)
	return result

static func on_points_spent(state: Dictionary, amount: int, hp_max: float) -> Array:
	var events: Array = []
	if String(state.get("name", "")) != "Avarento" or amount <= 0:
		return events
	var level: = _rank(state)
	var lastro_before: = maxf(1.0, float(state.get("avarento_lastro", 0.0)))
	state["avarento_cofre"] = 3.5 + 0.4 * level
	state["avarento_weight_suspension"] = maxf(float(state.get("avarento_weight_suspension", 0.0)), float(state["avarento_cofre"]))
	state["avarento_shield"] = maxf(float(state.get("avarento_shield", 0.0)), hp_max * minf(0.3, (0.025 + 0.01 * level) * lastro_before))
	events.append({"type": "text", "text": "COFRE ROMPIDO"})
	return events

static func on_direct_damage_dealt(state: Dictionary, target: Dictionary, damage: float, source_category: String, player_damage: float) -> Array:
	var events: Array = []
	if damage <= 0.0 or not _is_direct_category(source_category):
		return events
	match String(state.get("name", "")):
		"Crepuscular":
			if String(state.get("crepuscular_phase", "")) == "ocaso" and not _crepuscular_is_eclipse(state):
				_crepuscular_gain_charge(state, clampf(damage / maxf(1.0, player_damage) * 4.0, 1.0, 12.0))
		"Oportunista":
			if _enemy_in_opening(target):
				_oportunista_register_opening(state, target, events)
	return events

static func consume_opportunity_damage(state: Dictionary, player_damage: float) -> Dictionary:
	if String(state.get("name", "")) != "Oportunista" or not bool(state.get("oportunista_armed", false)):
		return {"bonus": 0.0, "events": []}
	var level: = _rank(state)
	state["oportunista_armed"] = false
	state["oportunista_charges"] = 0
	return {
		"bonus": player_damage * (0.5 + 0.12 * level), 
		"events": [
			{"type": "cooldown_recovery", "amount": 0.5 + 0.15 * level, "max_ratio": 0.3}, 
			{"type": "text", "text": "GOLPE DE OPORTUNIDADE"}
		]
	}

static func hunger_max(state: Dictionary) -> float:
	var cycles: = int(state.get("voracious_cycles", 0))
	return VORACIOUS_BASE_MAX + cycles * 54.0 + cycles * cycles * 9.0

static func voracious_intensity(state: Dictionary) -> float:
	return minf(1.85, float(state.get("voracious_hunger", 0.0)) / maxf(1.0, hunger_max(state)) + int(state.get("voracious_cycles", 0)) * 0.12)

static func _update_voracious(state: Dictionary, delta: float, context: Dictionary, events: Array) -> void :
	var cycles: = int(state["voracious_cycles"])
	var ratio: = float(state["voracious_hunger"]) / maxf(1.0, hunger_max(state))
	state["voracious_hunger"] = float(state["voracious_hunger"]) - (7.2 + cycles * 2.25 + ratio * ratio * 5.4) * delta
	while float(state["voracious_hunger"]) < 0.0 and cycles > 0:
		cycles -= 1
		state["voracious_cycles"] = cycles
		state["voracious_hunger"] = float(state["voracious_hunger"]) + hunger_max(state)
	state["voracious_hunger"] = maxf(0.0, float(state["voracious_hunger"]))
	state["voracious_last_collect"] = float(state["voracious_last_collect"]) + delta
	state["voracious_drain_tick"] = maxf(0.0, float(state["voracious_drain_tick"]) - delta)
	state["voracious_boss_feed_cd"] = maxf(0.0, float(state.get("voracious_boss_feed_cd", 0.0)) - delta)
	var player_pos: = Vector2(context.get("player_pos", Vector2.ZERO))
	var kept: Array = []
	for drop in Array(state["voracious_drops"]):
		drop["life"] = float(drop["life"]) - delta
		if float(drop["life"]) <= 0.0: continue
		if bool(drop.get("boss_particle", false)):
			var to_player: = player_pos - Vector2(drop["pos"])
			if to_player.length() > 0.01:
				drop["pos"] = Vector2(drop["pos"]) + to_player.normalized() * minf(to_player.length(), (115.0 + to_player.length() * 0.18) * delta)
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

static func _update_prophecy(state: Dictionary, enemies: Array, events: Array) -> void :
	if int(state["prophecy_uid"]) >= 0 and float(state["prophecy_time"]) <= 0.0:
		state["prophecy_uid"] = -1
		state["prophecy_sequence"] = 0
		state["prophecy_broken"] = 3.5
		events.append({"type": "text", "text": "DESTINO QUEBRADO"})
	if int(state["prophecy_uid"]) < 0 and float(state["prophecy_next"]) <= 0.0:
		var candidates: = enemies.filter( func(e): return float(e.get("hp", 0.0)) > 0.0)
		if not candidates.is_empty():
			var enemy: Dictionary = candidates[randi() % candidates.size()]
			state["prophecy_uid"] = int(enemy.get("uid", -1))
			state["prophecy_time"] = 6.4
			state["prophecy_next"] = maxf(6.2, 11.0 - int(state["level"]) * 0.85)
			enemy["aura_prophecy"] = 6.4

static func _apply_blood_hit(state: Dictionary, enemy: Dictionary, result: Dictionary) -> void :
	var uid: = int(enemy.get("uid", -1))
	var hits: Dictionary = state["blood_hits"]
	var data: Dictionary = hits.get(uid, {"count": 0, "time": 0.0})
	data["time"] = 0.0
	data["count"] = int(data["count"]) + 1
	hits[uid] = data
	var level: = int(state["level"])
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
