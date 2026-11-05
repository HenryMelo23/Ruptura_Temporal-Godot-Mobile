class_name RTBossPactController
extends RefCounted

## Estado dos pactos da run: multiplicadores consultados pelo core e as mecanicas
## caoticas (raios, escuridao, tremores...). Cada mecanica telegrafa antes de
## machucar, para o debuff ser leitura e nao injustica.

const LIGHTNING_WARN := 0.9
const LIGHTNING_RADIUS := 72.0
const LIGHTNING_DAMAGE := 0.06
const METEOR_WARN := 1.1
const METEOR_RADIUS := 62.0
const METEOR_DAMAGE := 0.05
const BURST_DELAY := 0.6
const BURST_RADIUS := 84.0
const BURST_DAMAGE := 0.04
const BLINK_WARN := 1.0
const GUST_WARN := 0.8
const GUST_TIME := 0.35
const GUST_DISTANCE := 230.0
const TREMOR_WARN := 0.7
const TREMOR_TIME := 1.2
const TREMOR_SLOW := 0.5
const STILL_GRACE := 1.2
const DRAIN_GRACE := 3.0
const TICK := 0.5

var core
var taken: Array[String] = []
var mult := {}
var mech := {}
## Perigos ativos: {"kind", "pos", "t", "warn"}; o presentation desenha.
var hazards: Array[Dictionary] = []
var timers := {}
var gust_dir := Vector2.ZERO
var gust_left := 0.0
var tremor_left := 0.0
var still_time := 0.0
var since_kill := 0.0
var tick_acc := 0.0
var moved_recently := 0.0
var _last_pos := Vector2.INF


func configure(runtime_core) -> void:
	core = runtime_core


func reset() -> void:
	taken.clear()
	mult.clear()
	mech.clear()
	hazards.clear()
	timers.clear()
	gust_left = 0.0
	tremor_left = 0.0
	still_time = 0.0
	since_kill = 0.0
	tick_acc = 0.0
	moved_recently = 0.0
	_last_pos = Vector2.INF


func hero_name() -> String:
	return "Henry" if String(core.active_character_key) == String(core.CHARACTER_HENRY) else "Geovana"


func roll_offer(count: int = 3) -> Array:
	var pool: Array = []
	for pact in RTBossPactCatalog.PACTS:
		if not taken.has(String(pact["id"])):
			pool.append(pact)
	var offer: Array = []
	while offer.size() < count and not pool.is_empty():
		var i: int = core.rng.randi_range(0, pool.size() - 1)
		var pact: Dictionary = Dictionary(pool[i]).duplicate(true)
		pact["lore_text"] = RTBossPactCatalog.lore_for(pact, hero_name())
		offer.append(pact)
		pool.remove_at(i)
	return offer


func apply(pact: Dictionary) -> void:
	var id: String = String(pact.get("id", ""))
	if id == "" or taken.has(id):
		return
	taken.append(id)
	var fx: Dictionary = Dictionary(pact.get("fx", {}))
	for key in fx.keys():
		var k: String = String(key)
		var v: float = float(fx[key])
		match k:
			"crit":
				core.player_crit_chance += v
			"defense":
				core.player_defense = minf(50.0, float(core.player_defense) + v)
			"lifesteal":
				core.player_lifesteal += v
			"luck":
				core.luck += v
			"max_hp":
				var ratio: float = float(core.player_hp) / maxf(1.0, float(core.player_hp_max))
				core.player_hp_max = maxi(1, int(round(float(core.player_hp_max) * v)))
				core.player_hp = maxi(1, int(round(float(core.player_hp_max) * ratio)))
			"enemy_hp":
				core.enemy_base_hp *= v
			"enemy_speed":
				core.enemy_speed_base *= v
			"enemy_dmg":
				core.enemy_close_damage *= v
				core.enemy_far_damage *= v
			_:
				mult[k] = float(mult.get(k, 1.0)) * v
	var m: Dictionary = Dictionary(pact.get("mech", {}))
	for key in m.keys():
		var k2: String = String(key)
		var v2: float = float(m[key])
		match k2:
			"darkness":
				mech[k2] = minf(float(mech.get(k2, 9999.0)), v2)
			"lightning", "blink", "meteors", "gust", "tremor":
				# Intervalo: dois pactos do mesmo tipo deixam mais frequente.
				mech[k2] = minf(float(mech.get(k2, 999.0)), v2) * (0.8 if mech.has(k2) else 1.0)
				timers[k2] = v2 * 0.6
			_:
				mech[k2] = float(mech.get(k2, 0.0)) + v2


func m(key: String) -> float:
	return float(mult.get(key, 1.0))


func has_mech(key: String) -> bool:
	return mech.has(key)


func move_multiplier() -> float:
	return m("move") * (TREMOR_SLOW if tremor_left > 0.0 else 1.0)


func heal_multiplier() -> float:
	if has_mech("heal_still") and moved_recently > 0.0:
		return 0.0
	return m("heal")


func on_enemy_killed(pos: Vector2) -> void:
	since_kill = 0.0
	if has_mech("death_burst") and core.rng.randf() < float(mech["death_burst"]):
		hazards.append({"kind": "burst", "pos": pos, "t": 0.0, "warn": BURST_DELAY})


func update(delta: float) -> void:
	if taken.is_empty() or core.is_dead:
		return
	var p: Vector2 = core.player_pos
	if _last_pos == Vector2.INF:
		_last_pos = p
	var moved: float = p.distance_to(_last_pos)
	_last_pos = p
	moved_recently = 0.25 if moved > 0.6 else maxf(0.0, moved_recently - delta)
	still_time = 0.0 if moved > 0.6 else still_time + delta
	since_kill += delta
	tremor_left = maxf(0.0, tremor_left - delta)
	_tick_damage(delta)
	_update_timers(delta)
	_update_hazards(delta)
	if gust_left > 0.0:
		gust_left = maxf(0.0, gust_left - delta)
		core.player_pos = core._clamp_player_world(core.player_pos + gust_dir * (GUST_DISTANCE / GUST_TIME) * delta)


func _tick_damage(delta: float) -> void:
	tick_acc += delta
	if tick_acc < TICK:
		return
	tick_acc -= TICK
	var hp_max: float = float(core.player_hp_max)
	if has_mech("stillness") and still_time >= STILL_GRACE:
		core._damage_player(maxi(1, int(round(hp_max * float(mech["stillness"]) * TICK))), "pact_stillness", true)
	if has_mech("drain") and since_kill >= DRAIN_GRACE and core.enemies.size() > 0:
		core._damage_player(maxi(1, int(round(hp_max * float(mech["drain"]) * TICK))), "pact_drain", true)


func _update_timers(delta: float) -> void:
	for key in ["lightning", "meteors", "blink", "gust", "tremor"]:
		if not mech.has(key):
			continue
		timers[key] = float(timers.get(key, 0.0)) - delta
		if float(timers[key]) > 0.0:
			continue
		timers[key] = float(mech[key]) * core.rng.randf_range(0.85, 1.15)
		_fire(String(key))


func _fire(kind: String) -> void:
	var p: Vector2 = core.player_pos
	match kind:
		"lightning":
			# Mira onde ela vai estar: forca a se mexer, mas da tempo de ler.
			var lead: Vector2 = Vector2(core.last_facing) * core.rng.randf_range(40.0, 110.0)
			hazards.append({"kind": "lightning", "pos": p + lead + Vector2.from_angle(core.rng.randf() * TAU) * core.rng.randf_range(0.0, 40.0), "t": 0.0, "warn": LIGHTNING_WARN})
		"meteors":
			hazards.append({"kind": "meteor", "pos": p, "t": 0.0, "warn": METEOR_WARN})
			for i in range(2):
				hazards.append({"kind": "meteor", "pos": p + Vector2.from_angle(core.rng.randf() * TAU) * core.rng.randf_range(120.0, 300.0), "t": -0.15 * float(i + 1), "warn": METEOR_WARN})
		"blink":
			var dest: Vector2 = core._clamp_player_world(p + Vector2.from_angle(core.rng.randf() * TAU) * core.rng.randf_range(180.0, 280.0))
			hazards.append({"kind": "blink", "pos": dest, "from": p, "t": 0.0, "warn": BLINK_WARN})
		"gust":
			hazards.append({"kind": "gust", "pos": p, "dir": Vector2.from_angle(core.rng.randf() * TAU), "t": 0.0, "warn": GUST_WARN})
		"tremor":
			hazards.append({"kind": "tremor", "pos": p, "t": 0.0, "warn": TREMOR_WARN})


func _update_hazards(delta: float) -> void:
	var i := 0
	while i < hazards.size():
		var h: Dictionary = hazards[i]
		h["t"] = float(h["t"]) + delta
		if float(h["t"]) < float(h["warn"]):
			if String(h["kind"]) == "blink":
				h["from"] = core.player_pos
			i += 1
			continue
		_resolve(h)
		hazards.remove_at(i)


func _resolve(h: Dictionary) -> void:
	var hp_max: float = float(core.player_hp_max)
	var pos: Vector2 = Vector2(h["pos"])
	match String(h["kind"]):
		"lightning":
			if core.player_pos.distance_to(pos) <= LIGHTNING_RADIUS:
				core._damage_player(int(round(hp_max * LIGHTNING_DAMAGE)), "pact_lightning")
			core._spawn_radial_particles(pos, Color(0.7, 0.9, 1.0), 6 if core._memory_saver_active() else 14)
			core.shockwaves.append({"pos": pos, "radius": 10.0, "max": LIGHTNING_RADIUS + 20.0, "life": 0.25, "max_life": 0.25, "damage": 0.0, "hit": {}, "visual_only": true, "color": Color(0.7, 0.92, 1.0)})
			hazards.append({"kind": "bolt", "pos": pos, "t": 0.0, "warn": 0.28})
		"meteor":
			if core.player_pos.distance_to(pos) <= METEOR_RADIUS:
				core._damage_player(int(round(hp_max * METEOR_DAMAGE)), "pact_meteor")
			core._spawn_radial_particles(pos, Color(1.0, 0.62, 0.3), 6 if core._memory_saver_active() else 12)
			core.shockwaves.append({"pos": pos, "radius": 8.0, "max": METEOR_RADIUS + 16.0, "life": 0.3, "max_life": 0.3, "damage": 0.0, "hit": {}, "visual_only": true, "color": Color(1.0, 0.6, 0.3)})
		"burst":
			if core.player_pos.distance_to(pos) <= BURST_RADIUS:
				core._damage_player(int(round(hp_max * BURST_DAMAGE)), "pact_death_burst")
			core._spawn_radial_particles(pos, Color(0.7, 1.0, 0.4), 5 if core._memory_saver_active() else 10)
			core.shockwaves.append({"pos": pos, "radius": 8.0, "max": BURST_RADIUS, "life": 0.25, "max_life": 0.25, "damage": 0.0, "hit": {}, "visual_only": true, "color": Color(0.66, 1.0, 0.36)})
		"blink":
			core._spawn_radial_particles(core.player_pos, Color(0.7, 0.5, 1.0), 10)
			core.player_pos = pos
			core._spawn_radial_particles(pos, Color(0.7, 0.5, 1.0), 12)
		"gust":
			gust_dir = Vector2(h["dir"])
			gust_left = GUST_TIME
		"tremor":
			tremor_left = TREMOR_TIME
			core._trigger_screen_shake(6.0, 0.4)
		"bolt":
			pass


## Raio ja caiu: fica alguns frames so para desenhar o clarao.
func bolts() -> Array:
	return hazards.filter(func(h): return String(h["kind"]) == "bolt")
