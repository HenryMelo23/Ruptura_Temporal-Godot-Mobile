class_name RTUmbraBaseSkills
extends RefCounted

## Kit da dimensao base da UMBRA, alem de ataque, teleporte e Sifao:
##   REBOBINAR      - marca o jogador; 1,5 s depois puxa ele de volta ao ponto
##                    marcado. Teleportar durante a marca quebra o efeito.
##   ECO_PROFETICO  - preve onde o jogador vai estar e detona ali com atraso.
## As duas aprendem com o jogador (como ele desvia e se foge com teleporte).
## Esse aprendizado vive em `learned` e e salvo pela mente da UMBRA.

const REBOBINAR := "REBOBINAR"
const ECO_PROFETICO := "ECO_PROFETICO"
const ACTIONS: Array[String] = [REBOBINAR, ECO_PROFETICO]

const REWIND_COOLDOWN := 13.0
const REWIND_DELAY := 1.5
const REWIND_PULL_TIME := 0.22
const REWIND_DAMAGE_RATE := 0.05
const REWIND_DAMAGE_FLAT := 30.0
const REWIND_STUN := 0.35
const REWIND_MIN_DISTANCE := 150.0

const ECO_COOLDOWN := 7.5
const ECO_WARNING := 1.1
const ECO_RADIUS := 96.0
const ECO_DAMAGE_RATE := 0.085
const ECO_DAMAGE_FLAT := 40.0
const ECO_BLAST_TIME := 0.45
const ECO_SIDE_DISTANCE := 150.0

var core: Node = null
var cooldowns: Dictionary = {REBOBINAR: 4.0, ECO_PROFETICO: 2.0}
## Marcas de rebobinar ativas: {anchor, timer, cast_time, pull, from, path}
var rewinds: Array[Dictionary] = []
## Sigilos do eco: {pos, timer, blast, hit, origin, vel, cast_time}
var ecos: Array[Dictionary] = []
## Aprendizado sobre o jogador (persistido pela mente).
var learned: Dictionary = {}
## Estatisticas do encontro (mente coletiva).
var stats: Dictionary = {}
var encounter_started := 0.0
## Treino headless: chance de o bot Apolo teleportar para fugir da marca.
var bot_rewind_reflex := 0.7


func configure(runtime_core: Node) -> void:
	core = runtime_core
	learned = default_learned()


static func default_learned() -> Dictionary:
	return {
		"eco_along": 0.85,        # quanto do movimento previsto o jogador mantem
		"eco_side": 0.0,          # -1 desvia pra esquerda do proprio movimento, +1 direita
		"eco_samples": 0,
		"rewind_escape": 0.35,    # taxa de fuga do rebobinar com teleporte
		"rewind_samples": 0,
		"weights": {REBOBINAR: 0.0, ECO_PROFETICO: 0.0},
	}


## Comeca o encontro ja sabendo algo: priors {chave: [valor, amostras]} vindos
## da mente (base/coletiva/jogador) e do que as fases anteriores observaram.
func seed_learned(priors: Dictionary) -> void:
	var weights: Dictionary = learned.get("weights", {})
	learned = default_learned()
	learned["weights"] = weights
	for key in ["eco_along", "eco_side", "rewind_escape"]:
		if not priors.has(key):
			continue
		var entry: Array = priors[key]
		learned[key] = float(entry[0])
		var samples_key: String = "eco_samples" if key.begins_with("eco") else "rewind_samples"
		# Conta como poucas amostras: a luta atual ainda corrige rapido.
		learned[samples_key] = maxi(int(learned.get(samples_key, 0)), mini(4, int(float(entry[1]))))


func reset_encounter() -> void:
	encounter_started = float(core.time_alive) if core != null else 0.0
	cooldowns = {REBOBINAR: 4.0, ECO_PROFETICO: 2.0}
	rewinds.clear()
	ecos.clear()
	stats = {
		REBOBINAR: {"casts": 0, "hits": 0, "escapes": 0},
		ECO_PROFETICO: {"casts": 0, "hits": 0},
	}


func active() -> bool:
	return not rewinds.is_empty() or not ecos.is_empty()


# ================================================================ decisao
func append_available(available: Array) -> void:
	if String(core.boss5_dimension) != "base" or float(core.boss5_transmute_hangover) > 0.0:
		return
	if float(cooldowns.get(ECO_PROFETICO, 0.0)) <= 0.0:
		available.append(ECO_PROFETICO)
	if float(cooldowns.get(REBOBINAR, 0.0)) <= 0.0 and rewinds.is_empty() and _target_is_local():
		available.append(REBOBINAR)


func score(scores: Dictionary, available: Array, dist: float) -> void:
	var weights: Dictionary = learned.get("weights", {})
	var dash_ready: bool = _player_dash_ready()
	if available.has(ECO_PROFETICO):
		var s: float = 0.5 + float(weights.get(ECO_PROFETICO, 0.0))
		# Jogador em movimento constante e facil de profetizar.
		if RTUmbraAim.history_velocity(core.phase5_player_history, core.player_pos).length() > 120.0:
			s += 0.35
		# Combo: com rebobinar armado, o eco cai no ponto de retorno.
		if not rewinds.is_empty():
			s += 1.2
		s += 0.25 * clampf(float(learned.get("eco_samples", 0)) / 8.0, 0.0, 1.0)
		scores[ECO_PROFETICO] = float(scores.get(ECO_PROFETICO, 0.0)) + s
	if available.has(REBOBINAR):
		var r: float = 0.35 + float(weights.get(REBOBINAR, 0.0))
		# Melhor logo depois de o jogador gastar o teleporte.
		r += -0.6 * float(learned.get("rewind_escape", 0.35)) if dash_ready else 0.9
		# Rebobinar perto do ponto de origem nao faz nada.
		if dist < 260.0:
			r += 0.25
		scores[REBOBINAR] = float(scores.get(REBOBINAR, 0.0)) + r


func cast(action: String) -> bool:
	match action:
		REBOBINAR:
			_cast_rewind()
			return true
		ECO_PROFETICO:
			_cast_eco()
			return true
	return false


# ================================================================ rebobinar
func _cast_rewind() -> void:
	cooldowns[REBOBINAR] = REWIND_COOLDOWN
	var now: float = float(core.time_alive)
	rewinds.append({
		"anchor": Vector2(core.player_pos), "timer": REWIND_DELAY, "cast_time": now,
		"pull": -1.0, "from": Vector2.ZERO, "path": [Vector2(core.player_pos)],
	})
	_stat(REBOBINAR, "casts")
	core._add_text("REBOBINAR", core.player_pos + Vector2(0, -96), Color(0.5, 1.0, 0.7), 1.0, 20)
	core._play_sfx("ui_manifest_switch", 0.05, 0.55, 0.62)


func _update_rewinds(delta: float) -> void:
	var i := rewinds.size() - 1
	while i >= 0:
		var r: Dictionary = rewinds[i]
		if float(r["pull"]) >= 0.0:
			r["pull"] = float(r["pull"]) + delta
			var k: float = clampf(float(r["pull"]) / REWIND_PULL_TIME, 0.0, 1.0)
			core.player_pos = Vector2(r["from"]).lerp(Vector2(r["anchor"]), k * k * (3.0 - 2.0 * k))
			if k >= 1.0:
				rewinds.remove_at(i)
			i -= 1
			continue
		r["timer"] = float(r["timer"]) - delta
		var path: Array = r["path"]
		if path.is_empty() or Vector2(path[path.size() - 1]).distance_to(core.player_pos) > 24.0:
			path.append(Vector2(core.player_pos))
			if path.size() > 40:
				path.pop_front()
		# Teleportar depois da marca quebra o rebobinar.
		if float(core.last_dash_time) > float(r["cast_time"]) + 0.05:
			_learn_rewind(true)
			core._add_text("MARCA QUEBRADA", core.player_pos + Vector2(0, -90), Color(0.7, 0.9, 1.0), 0.9, 17)
			rewinds.remove_at(i)
			i -= 1
			continue
		if float(r["timer"]) <= 0.0:
			var from: Vector2 = Vector2(core.player_pos)
			if from.distance_to(Vector2(r["anchor"])) >= REWIND_MIN_DISTANCE * 0.5:
				r["from"] = from
				r["pull"] = 0.0
				core.player_stun_timer = maxf(float(core.player_stun_timer), REWIND_STUN)
				core._damage_player(int(float(core.player_hp_max) * REWIND_DAMAGE_RATE + REWIND_DAMAGE_FLAT), "umbra_rebobinar")
				core._spawn_radial_particles(from, Color(0.5, 1.0, 0.7), 26)
				_learn_rewind(false)
			else:
				# Nao se moveu: o rebobinar vira so um aviso; conta como fuga leve.
				_learn_rewind(true, 0.4)
				rewinds.remove_at(i)
		i -= 1


func _learn_rewind(escaped: bool, strength: float = 1.0) -> void:
	var n: int = int(learned.get("rewind_samples", 0)) + 1
	learned["rewind_samples"] = n
	var alpha: float = maxf(0.12, 1.0 / float(n)) * strength
	learned["rewind_escape"] = lerpf(float(learned.get("rewind_escape", 0.35)), 1.0 if escaped else 0.0, alpha)
	_reward(REBOBINAR, -0.25 * strength if escaped else 0.6)
	if escaped:
		_stat(REBOBINAR, "escapes")
	else:
		_stat(REBOBINAR, "hits")


# ================================================================ eco profetico
func _cast_eco() -> void:
	cooldowns[ECO_PROFETICO] = ECO_COOLDOWN
	var origin: Vector2 = Vector2(core.player_pos)
	var vel: Vector2 = RTUmbraAim.history_velocity(core.phase5_player_history, origin)
	var targets: Array[Vector2] = []
	if not rewinds.is_empty() and float(Dictionary(rewinds[0]).get("pull", -1.0)) < 0.0:
		# Combo: detona no ponto para onde o jogador sera puxado.
		targets.append(Vector2(Dictionary(rewinds[0])["anchor"]))
	else:
		targets.append(predict(origin, vel, ECO_WARNING))
		# Com leitura suficiente, cobre tambem o lado oposto do desvio favorito.
		if int(learned.get("eco_samples", 0)) >= 3 or float(core.boss_hp) < float(core.boss_hp_max) * 0.5:
			targets.append(predict(origin, vel, ECO_WARNING, -1.0))
	for t in targets:
		ecos.append({
			"pos": t.clamp(Vector2(80, 80), Vector2(core.WORLD_SIZE) - Vector2(80, 80)),
			"timer": ECO_WARNING, "blast": -1.0, "hit": false,
			"origin": origin, "vel": vel, "cast_time": float(core.time_alive),
		})
	_stat(ECO_PROFETICO, "casts")
	core._add_text("ECO PROFETICO", core.boss_pos + Vector2(0, -118), Color(0.6, 1.0, 0.72), 1.0, 20)


## Posicao prevista. `side_sign` = 1 usa o lado aprendido; -1 espelha.
func predict(origin: Vector2, vel: Vector2, seconds: float, side_sign: float = 1.0) -> Vector2:
	var along: float = clampf(float(learned.get("eco_along", 0.85)), 0.0, 1.4)
	var side: float = clampf(float(learned.get("eco_side", 0.0)), -1.0, 1.0)
	var dir: Vector2 = vel.normalized() if vel.length() > 30.0 else (origin - Vector2(core.boss_pos)).normalized().orthogonal()
	var perp: Vector2 = dir.orthogonal()
	var side_amount: float = side * side_sign
	if side_sign < 0.0 and absf(side) < 0.2:
		side_amount = -0.8
	return origin + vel * seconds * along + perp * side_amount * ECO_SIDE_DISTANCE


func _update_ecos(delta: float) -> void:
	var i := ecos.size() - 1
	while i >= 0:
		var e: Dictionary = ecos[i]
		if float(e["blast"]) >= 0.0:
			e["blast"] = float(e["blast"]) + delta
			if float(e["blast"]) >= ECO_BLAST_TIME:
				ecos.remove_at(i)
			i -= 1
			continue
		e["timer"] = float(e["timer"]) - delta
		if float(e["timer"]) <= 0.0:
			e["blast"] = 0.0
			var pos: Vector2 = Vector2(e["pos"])
			var dmg: int = int(float(core.player_hp_max) * ECO_DAMAGE_RATE + ECO_DAMAGE_FLAT)
			if pos.distance_to(core.player_pos) <= ECO_RADIUS:
				e["hit"] = true
				core._damage_player(dmg, "umbra_eco")
				core._increase_umbra_cadence(0.06)
				_stat(ECO_PROFETICO, "hits")
				_reward(ECO_PROFETICO, 0.55)
			elif core._damage_remote_player_in_radius(pos, ECO_RADIUS, dmg, "umbra_eco"):
				e["hit"] = true
			else:
				_reward(ECO_PROFETICO, -0.12)
			_learn_dodge(e)
			core._spawn_radial_particles(pos, Color(0.55, 1.0, 0.6), 22)
		i -= 1


## Aprende como o jogador desviou: quanto manteve o movimento e para que lado.
func _learn_dodge(e: Dictionary) -> void:
	var origin: Vector2 = Vector2(e["origin"])
	var vel: Vector2 = Vector2(e["vel"])
	var actual: Vector2 = Vector2(core.player_pos) - origin
	var dir: Vector2 = vel.normalized() if vel.length() > 30.0 else (origin - Vector2(core.boss_pos)).normalized().orthogonal()
	var n: int = int(learned.get("eco_samples", 0)) + 1
	learned["eco_samples"] = n
	var alpha: float = maxf(0.15, 1.0 / float(n))
	if vel.length() > 30.0:
		var along: float = actual.dot(dir) / maxf(1.0, vel.length() * ECO_WARNING)
		learned["eco_along"] = lerpf(float(learned.get("eco_along", 0.85)), clampf(along, 0.0, 1.4), alpha)
	var side: float = actual.dot(dir.orthogonal()) / ECO_SIDE_DISTANCE
	learned["eco_side"] = lerpf(float(learned.get("eco_side", 0.0)), clampf(side, -1.0, 1.0), alpha)


# ================================================================ bot Apolo (treino)
## Perigo dos sigilos do eco para o desvio do Apolo.
func danger_at(pos: Vector2, forecast: float) -> float:
	var danger := 0.0
	for e in ecos:
		if float(e["blast"]) >= 0.0:
			continue
		var d: float = pos.distance_to(Vector2(e["pos"]))
		if d < ECO_RADIUS + 40.0 and float(e["timer"]) < 0.75 + forecast:
			danger += 900.0 * (1.0 - d / (ECO_RADIUS + 40.0))
	return danger


## O Apolo foge do rebobinar com teleporte (com chance de reflexo).
func bot_should_escape(rng: RandomNumberGenerator) -> bool:
	for r in rewinds:
		if float(r["pull"]) < 0.0 and float(r["timer"]) < 0.55 and not bool(r.get("bot_rolled", false)):
			r["bot_rolled"] = true
			return rng.randf() < bot_rewind_reflex
	return false


# ================================================================ ciclo
func update(delta: float, cadence_rate: float = 1.0) -> void:
	for key in cooldowns.keys():
		cooldowns[key] = maxf(0.0, float(cooldowns[key]) - delta * cadence_rate)
	if not rewinds.is_empty():
		_update_rewinds(delta)
	if not ecos.is_empty():
		_update_ecos(delta)


func _reward(action: String, reward: float) -> void:
	var weights: Dictionary = learned.get("weights", {})
	weights[action] = clampf(lerpf(float(weights.get(action, 0.0)), reward * 2.0, 0.08), -2.0, 2.0)
	learned["weights"] = weights


func _stat(action: String, key: String) -> void:
	var entry: Dictionary = stats.get(action, {})
	entry[key] = int(entry.get(key, 0)) + 1
	stats[action] = entry


func _player_dash_ready() -> bool:
	if not core.has_method("_current_dash_cooldown"):
		return true
	return float(core.time_alive) - float(core.last_dash_time) >= float(core._current_dash_cooldown())


func _target_is_local() -> bool:
	var decision: Dictionary = core.boss5_authoritative_decision
	return int(decision.get("target_peer_id", core._mp_unique_id())) == int(core._mp_unique_id())


# ================================================================ save
func save_state() -> Dictionary:
	var rw: Array = []
	for r in rewinds:
		rw.append({"anchor": r["anchor"], "timer": r["timer"], "cast_time": r["cast_time"]})
	var ec: Array = []
	for e in ecos:
		ec.append({"pos": e["pos"], "timer": e["timer"], "origin": e["origin"], "vel": e["vel"], "cast_time": e["cast_time"]})
	return {"cooldowns": cooldowns.duplicate(), "rewinds": rw, "ecos": ec, "stats": stats.duplicate(true)}


func load_state(data: Dictionary) -> void:
	cooldowns = Dictionary(data.get("cooldowns", cooldowns)).duplicate()
	stats = Dictionary(data.get("stats", {})).duplicate(true)
	rewinds.clear()
	for r in Array(data.get("rewinds", [])):
		var d: Dictionary = r
		rewinds.append({"anchor": Vector2(d.get("anchor", Vector2.ZERO)), "timer": float(d.get("timer", 0.0)), "cast_time": float(d.get("cast_time", 0.0)), "pull": -1.0, "from": Vector2.ZERO, "path": []})
	ecos.clear()
	for e in Array(data.get("ecos", [])):
		var d: Dictionary = e
		ecos.append({"pos": Vector2(d.get("pos", Vector2.ZERO)), "timer": float(d.get("timer", 0.0)), "blast": -1.0, "hit": false, "origin": Vector2(d.get("origin", Vector2.ZERO)), "vel": Vector2(d.get("vel", Vector2.ZERO)), "cast_time": float(d.get("cast_time", 0.0))})
