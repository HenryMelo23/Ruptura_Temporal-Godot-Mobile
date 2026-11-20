class_name RTBossDnaController
extends RefCounted

## Rede do Petro: banco de DNA dos chefes, habilidades fundidas e execucao
## dos gatilhos/efeitos durante a fase. Dados em RTBossDnaCatalog.
##
## Vale so para a run: nova run zera tudo; retomar a run restaura banco,
## habilidades, recargas e as falas da maquina ja vistas (save_state entra no
## snapshot da oficina do Mercador).
##
## MULTIPLAYER (validacao adiada): efeitos que mexem no mundo (dano, lentidao,
## congelamento, puxao, rewind dos inimigos) so rodam na autoridade do mundo;
## efeitos pessoais (cura, escudo, guarda, invulnerabilidade) rodam no dono.

const SOURCE := "petro"
const SOURCE_CATEGORY := "ally"
const REWIND_SAMPLE := 0.5
const REWIND_WINDOW := 10.5
const SLOW_REFRESH := 0.5
const ORBIT_HIT_CD := 0.45
const ZONE_TICK := 0.5
const WAVE_BAND := 46.0

var core: Node = null
## phase -> DNA guardado (ainda nao fundido).
var bank: Dictionary = {}
## ability_id -> rank (1..3).
var owned: Dictionary = {}
## ability_id -> segundos ate poder disparar de novo.
var cooldowns: Dictionary = {}
## ability_id -> abates acumulados (gatilho on_kill).
var kill_counters: Dictionary = {}
var fusions_done := 0
## O Mercador ja apresentou a maquina nesta run (fala longa).
var presented := false
## DNA novo desde a ultima visita a oficina (ele lembra na entrada).
var reminder_pending := false

## ---------------------------------------------- estado transitorio (sem save)
var slow_all_timer := 0.0
var slow_all_mult := 1.0
var slow_all_boss_ratio := 0.0
var _slow_refresh := 0.0
var shield := 0.0
var shield_timer := 0.0
var guard_ratio := 0.0
var guard_timer := 0.0
var waves: Array[Dictionary] = []
var zones: Array[Dictionary] = []
var orbits: Array[Dictionary] = []
## Flashes curtos para a apresentacao: {kind, pos, radius, life, max, color}.
var bursts: Array[Dictionary] = []
var rewind_history: Array[Dictionary] = []
var _rewind_sample := 0.0
## Ultimo rewind para a apresentacao (rastro do relogio).
var rewind_fx: Dictionary = {}
## Chip do HUD que acabou de disparar.
var last_fired := ""
var last_fired_timer := 0.0
## Chefe caiu: abre uma Fenda do Mercador assim que a arena liberar, para ela
## poder levar o DNA a maquina (compensacao da passagem do chefe).
var rift_requested := false


func configure(runtime_core: Node) -> void:
	core = runtime_core


func reset_run() -> void:
	bank.clear()
	owned.clear()
	cooldowns.clear()
	kill_counters.clear()
	fusions_done = 0
	presented = false
	reminder_pending = false
	rift_requested = false
	_clear_transient()


func _clear_transient() -> void:
	slow_all_timer = 0.0
	slow_all_mult = 1.0
	slow_all_boss_ratio = 0.0
	shield = 0.0
	shield_timer = 0.0
	guard_ratio = 0.0
	guard_timer = 0.0
	waves.clear()
	zones.clear()
	orbits.clear()
	bursts.clear()
	rewind_history.clear()
	rewind_fx = {}


# ================================================================ banco/fusao
func dna_count(phase: int) -> int:
	return int(bank.get(phase, 0))


func total_dna() -> int:
	var total := 0
	for phase in bank.keys():
		total += int(bank[phase])
	return total


func rank(id: String) -> int:
	return int(owned.get(id, 0))


func next_cost() -> int:
	return RTBossDnaCatalog.fusion_cost(int(core.card_cost) if core != null else 1, fusions_done)


## Chefe derrotado: guarda um DNA dele (UMBRA nao tem).
func on_boss_defeated(phase: int, pos: Vector2) -> bool:
	if not RTBossDnaCatalog.has_boss(phase):
		return false
	bank[phase] = dna_count(phase) + 1
	reminder_pending = true
	rift_requested = true
	if core != null:
		var color := RTBossDnaCatalog.boss_color(phase)
		core._add_text("DNA: %s" % String(RTBossDnaCatalog.boss(phase).get("name", "")), pos + Vector2(-120.0, -150.0), color, 2.6, 24)
		core._add_text("GUARDADO PARA A MÁQUINA DO MERCADOR", pos + Vector2(-170.0, -118.0), Color(0.86, 0.94, 1.0), 2.6, 16)
		bursts.append({"kind": "dna", "pos": pos, "radius": 140.0, "life": 1.4, "max": 1.4, "color": color})
	return true


## "" quando pode fundir; senao o motivo (texto curto da tela).
func fusion_block_reason(phase: int, id: String) -> String:
	if not RTBossDnaCatalog.boss_abilities(phase).has(id):
		return "HABILIDADE INVÁLIDA"
	if dna_count(phase) <= 0:
		return "SEM DNA DESTE CHEFE: ENFRENTE-O DE NOVO"
	if rank(id) >= RTBossDnaCatalog.MAX_RANK:
		return "NO NÍVEL MÁXIMO"
	if int(core.score) < next_cost():
		return "PONTOS INSUFICIENTES"
	return ""


func fuse(phase: int, id: String) -> bool:
	if fusion_block_reason(phase, id) != "":
		return false
	var cost := next_cost()
	core.score -= cost
	core.run_points_spent += cost
	core._record_telemetry_score_delta(-cost, "boss_dna_fusion")
	core._play_sfx("shop_spend", 0.01, 0.72, 0.9)
	bank[phase] = dna_count(phase) - 1
	if dna_count(phase) <= 0:
		bank.erase(phase)
	owned[id] = rank(id) + 1
	cooldowns[id] = 0.0
	kill_counters[id] = 0
	fusions_done += 1
	return true


# ================================================================ tick
func active_in_world() -> bool:
	return core != null and not owned.is_empty() and String(core.mode) == "game" and not core._merchant_dimension().active and not bool(core.is_dead)


func update(delta: float) -> void:
	last_fired_timer = maxf(0.0, last_fired_timer - delta)
	_update_bursts(delta)
	_maybe_open_rift()
	if not active_in_world():
		return
	for id in owned.keys():
		cooldowns[id] = maxf(0.0, float(cooldowns.get(id, 0.0)) - delta)
	shield_timer = maxf(0.0, shield_timer - delta)
	if shield_timer <= 0.0:
		shield = 0.0
	guard_timer = maxf(0.0, guard_timer - delta)
	_record_rewind(delta)
	_update_slow_all(delta)
	_update_waves(delta)
	_update_zones(delta)
	_update_orbits(delta)
	_auto_cast()


func _maybe_open_rift() -> void:
	if not rift_requested or core == null or String(core.mode) != "game" or bool(core.boss_active) or core._merchant_dimension().active:
		return
	rift_requested = false
	var rift = core.shop_rift_controller
	if rift.enabled() and not rift.active() and core._is_world_authority():
		rift.spawn("boss_dna")


func _auto_cast() -> void:
	for id in owned.keys():
		var data := RTBossDnaCatalog.ability(String(id))
		if String(data.get("trigger", "")) != "cooldown" or float(cooldowns.get(id, 0.0)) > 0.0:
			continue
		if _threat_near(RTBossDnaCatalog.AUTO_CAST_RANGE):
			fire(String(id))


func _threat_near(radius: float) -> bool:
	var me: Vector2 = core.player_pos
	if bool(core.boss_active) and float(core.boss_hp) > 0.0 and Vector2(core.boss_pos).distance_to(me) <= radius + 200.0:
		return true
	if core._arauto_active() and Vector2(core.arauto.get("pos", me)).distance_to(me) <= radius:
		return true
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) > 0.0 and Vector2(enemy.get("pos", me)).distance_to(me) <= radius:
			return true
	return false


# ================================================================ gatilhos
## Golpe no jogador (depois das mitigacoes do core, antes de tirar vida).
## Devolve o dano que sobra; 0 = golpe anulado.
func on_player_hit(final: int) -> int:
	if core == null or owned.is_empty() or final <= 0:
		return final
	var amount := float(final)
	if guard_timer > 0.0:
		amount *= 1.0 - guard_ratio
	if shield > 0.0:
		var absorbed := minf(shield, amount)
		shield -= absorbed
		amount -= absorbed
		if absorbed > 0.0:
			bursts.append({"kind": "shield_hit", "pos": core.player_pos, "radius": 46.0, "life": 0.3, "max": 0.3, "color": Color(0.7, 0.95, 1.0)})
	var result := int(round(amount))
	if result > 0 and _try_near_death(result):
		return 0
	if result > 0:
		var ratio := float(result) / maxf(1.0, float(core.player_hp_max))
		for id in owned.keys():
			var data := RTBossDnaCatalog.ability(String(id))
			if String(data.get("trigger", "")) == "on_hit" and float(cooldowns.get(id, 0.0)) <= 0.0 and ratio >= float(data.get("min_ratio", 0.0)):
				fire(String(id))
	return result


func _try_near_death(damage: int) -> bool:
	var hp_max := maxf(1.0, float(core.player_hp_max))
	var hp_after := float(core.player_hp) - float(damage)
	var lethal := hp_after <= 0.0
	var big := float(damage) >= hp_max * RTBossDnaCatalog.NEAR_DEATH_BIG_HIT
	if not lethal and not (big and hp_after <= hp_max * RTBossDnaCatalog.NEAR_DEATH_HP_RATIO):
		return false
	for id in owned.keys():
		var data := RTBossDnaCatalog.ability(String(id))
		if String(data.get("trigger", "")) == "near_death" and float(cooldowns.get(id, 0.0)) <= 0.0:
			fire(String(id))
			# Garantia explicita: o golpe que ativa nunca mata.
			core.player_hp = maxi(1, int(core.player_hp))
			return true
	return false


func on_enemy_killed() -> void:
	if not active_in_world():
		return
	for id in owned.keys():
		var data := RTBossDnaCatalog.ability(String(id))
		if String(data.get("trigger", "")) != "on_kill":
			continue
		kill_counters[id] = int(kill_counters.get(id, 0)) + 1
		if int(kill_counters[id]) >= int(data.get("kills", 10)) and float(cooldowns.get(id, 0.0)) <= 0.0:
			kill_counters[id] = 0
			fire(String(id))


## Executa a habilidade agora (tambem usado pelos testes/capturas).
func fire(id: String) -> bool:
	var data := RTBossDnaCatalog.ability(id)
	if data.is_empty() or core == null:
		return false
	var r: int = maxi(1, rank(id))
	var potency := RTBossDnaCatalog.potency_for(r)
	var color := RTBossDnaCatalog.boss_color(int(data.get("phase", 1)))
	cooldowns[id] = RTBossDnaCatalog.cooldown_for(id, r)
	for effect in data.get("effects", []):
		_apply_effect(Dictionary(effect), potency, color)
	last_fired = id
	last_fired_timer = 1.6
	core._add_text(String(data.get("name", "")).to_upper(), Vector2(core.player_pos) + Vector2(-90.0, -128.0), color, 1.3, 20)
	core._play_sfx("Portal.mp3", 0.03, 0.42, 1.25)
	return true


# ================================================================ efeitos
func _world_authority() -> bool:
	return core._is_world_authority()


func _apply_effect(effect: Dictionary, potency: float, color: Color) -> void:
	var me: Vector2 = core.player_pos
	match String(effect.get("kind", "")):
		"slow_all":
			slow_all_timer = maxf(slow_all_timer, float(effect.get("duration", 15.0)))
			slow_all_mult = float(effect.get("mult", 0.55))
			slow_all_boss_ratio = float(effect.get("boss_ratio", 0.25))
			_slow_refresh = 0.0
			bursts.append({"kind": "tide", "pos": me, "radius": 900.0, "life": 1.6, "max": 1.6, "color": color})
		"rewind":
			_rewind(float(effect.get("seconds", 10.0)), float(effect.get("min_hp", 0.4)), color)
		"wave":
			waves.append({"pos": me, "r": 20.0, "max": float(effect.get("radius", 900.0)), "speed": float(effect.get("speed", 760.0)), "damage": float(effect.get("damage", 1.0)) * potency, "slow": float(effect.get("slow", 0.0)), "mult": float(effect.get("mult", 1.0)), "stun": float(effect.get("stun", 0.0)), "hit": {}, "color": color})
		"nova":
			_nova(me, float(effect.get("radius", 200.0)), float(effect.get("damage", 1.0)) * potency, effect, color)
		"zone":
			zones.append({"pos": me, "radius": float(effect.get("radius", 200.0)), "life": float(effect.get("duration", 6.0)), "max": float(effect.get("duration", 6.0)), "dps": float(effect.get("dps", 0.5)) * potency, "mult": float(effect.get("mult", 1.0)), "follow": bool(effect.get("follow", false)), "tick": 0.0, "color": color})
		"orbit":
			orbits.append({"count": int(effect.get("count", 3)), "radius": float(effect.get("radius", 110.0)), "life": float(effect.get("duration", 7.0)), "max": float(effect.get("duration", 7.0)), "damage": float(effect.get("damage", 1.0)) * potency, "angle": 0.0, "hit": {}, "color": color})
		"freeze":
			_freeze(me, float(effect.get("radius", 0.0)), float(effect.get("duration", 2.0)) * minf(1.5, potency), float(effect.get("boss_ratio", 0.0)), color)
		"pull":
			_pull(me, float(effect.get("radius", 400.0)), float(effect.get("strength", 200.0)), color)
		"drain":
			_drain(me, float(effect.get("radius", 300.0)), float(effect.get("damage", 1.5)) * potency, float(effect.get("heal_ratio", 0.4)), color)
		"shield":
			shield = maxf(shield, float(core.player_hp_max) * float(effect.get("amount", 0.25)) * potency)
			shield_timer = maxf(shield_timer, float(effect.get("duration", 8.0)))
		"guard":
			guard_ratio = clampf(float(effect.get("reduction", 0.5)) * minf(1.3, potency), 0.0, 0.8)
			guard_timer = maxf(guard_timer, float(effect.get("duration", 5.0)))
		"heal":
			core._heal_player(float(core.player_hp_max) * float(effect.get("amount", 0.2)) * minf(1.4, potency), "petro_dna", false)
		"invuln":
			core.run_retry_invulnerability_timer = maxf(float(core.run_retry_invulnerability_timer), float(effect.get("duration", 1.5)))
	bursts.append({"kind": "cast", "pos": me, "radius": 70.0, "life": 0.5, "max": 0.5, "color": color})


func _damage_amount(units: float) -> float:
	return maxf(1.0, float(core.player_damage) * units)


## Dano/controle num inimigo. Devolve o dano aplicado (para a drenagem).
func _hit_enemy(enemy: Dictionary, units: float, slow: float, mult: float, stun: float) -> float:
	if float(enemy.get("hp", 0.0)) <= 0.0:
		return 0.0
	var hp_before := float(enemy.get("hp", 0.0))
	if slow > 0.0:
		enemy["evolution_slow"] = maxf(float(enemy.get("evolution_slow", 0.0)), slow)
		enemy["evolution_slow_mult"] = minf(float(enemy.get("evolution_slow_mult", 1.0)), mult)
	if stun > 0.0:
		enemy["stun"] = maxf(float(enemy.get("stun", 0.0)), stun)
	if units > 0.0:
		core._damage_enemy(enemy, _damage_amount(units), SOURCE, true, true, core.player_pos, SOURCE_CATEGORY)
	return maxf(0.0, hp_before - maxf(0.0, float(enemy.get("hp", 0.0))))


func _hit_bosses_in(center: Vector2, radius: float, units: float, slow_ratio: float = 0.0) -> float:
	var dealt := 0.0
	if bool(core.boss_active) and float(core.boss_hp) > 0.0 and Vector2(core.boss_pos).distance_to(center) <= radius + core._boss_hit_radius():
		var before := float(core.boss_hp)
		if units > 0.0:
			core._damage_boss(_damage_amount(units), SOURCE, true, true, SOURCE_CATEGORY, center)
		dealt += maxf(0.0, before - float(core.boss_hp))
		if slow_ratio > 0.0:
			core.boss_ferrolho_slow_timer = maxf(float(core.boss_ferrolho_slow_timer), 2.0)
			core.boss_ferrolho_slow_ratio = maxf(float(core.boss_ferrolho_slow_ratio), slow_ratio)
	if core._arauto_active() and Vector2(core.arauto.get("pos", center)).distance_to(center) <= radius + 70.0 and units > 0.0:
		core._damage_arauto(_damage_amount(units), SOURCE, true, true, SOURCE_CATEGORY, center)
	return dealt


func _nova(center: Vector2, radius: float, units: float, effect: Dictionary, color: Color) -> void:
	bursts.append({"kind": "nova", "pos": center, "radius": radius, "life": 0.55, "max": 0.55, "color": color})
	if not _world_authority():
		return
	var push := float(effect.get("push", 0.0))
	for enemy in core.enemies.duplicate():
		var pos := Vector2(enemy.get("pos", center))
		if pos.distance_to(center) > radius:
			continue
		if push > 0.0:
			var dir := (pos - center).normalized() if pos != center else Vector2.RIGHT
			enemy["pos"] = (pos + dir * push).clamp(Vector2(40, 40), Vector2(core.WORLD_SIZE) - Vector2(40, 40))
		_hit_enemy(enemy, units, float(effect.get("slow", 0.0)), float(effect.get("mult", 1.0)), float(effect.get("stun", 0.0)))
	_hit_bosses_in(center, radius, units, 0.2 if float(effect.get("slow", 0.0)) > 0.0 else 0.0)


func _freeze(center: Vector2, radius: float, seconds: float, boss_ratio: float, color: Color) -> void:
	bursts.append({"kind": "freeze", "pos": center, "radius": radius if radius > 0.0 else 1100.0, "life": 0.9, "max": 0.9, "color": color})
	if not _world_authority():
		return
	for enemy in core.enemies:
		if radius <= 0.0 or Vector2(enemy.get("pos", center)).distance_to(center) <= radius:
			enemy["stun"] = maxf(float(enemy.get("stun", 0.0)), seconds)
	if core._arauto_active() and (radius <= 0.0 or Vector2(core.arauto.get("pos", center)).distance_to(center) <= radius + 70.0):
		core.arauto["stun"] = maxf(float(core.arauto.get("stun", 0.0)), minf(1.0, seconds))
	if boss_ratio > 0.0 and bool(core.boss_active):
		core.boss_ferrolho_slow_timer = maxf(float(core.boss_ferrolho_slow_timer), seconds)
		core.boss_ferrolho_slow_ratio = maxf(float(core.boss_ferrolho_slow_ratio), boss_ratio)


func _pull(center: Vector2, radius: float, strength: float, color: Color) -> void:
	bursts.append({"kind": "pull", "pos": center, "radius": radius, "life": 0.6, "max": 0.6, "color": color})
	if not _world_authority():
		return
	for enemy in core.enemies:
		var pos := Vector2(enemy.get("pos", center))
		var dist := pos.distance_to(center)
		if dist > radius or dist < 50.0:
			continue
		enemy["pos"] = pos + (center - pos).normalized() * minf(strength, dist - 46.0)


func _drain(center: Vector2, radius: float, units: float, heal_ratio: float, color: Color) -> void:
	bursts.append({"kind": "drain", "pos": center, "radius": radius, "life": 0.7, "max": 0.7, "color": color})
	if not _world_authority():
		return
	var drained := 0.0
	for enemy in core.enemies.duplicate():
		if Vector2(enemy.get("pos", center)).distance_to(center) <= radius:
			drained += _hit_enemy(enemy, units, 0.0, 1.0, 0.0)
	drained += _hit_bosses_in(center, radius, units)
	if drained > 0.0:
		core._heal_player(drained * heal_ratio, "petro_dna", false)


# ================================================================ efeitos com duracao
func _update_slow_all(delta: float) -> void:
	if slow_all_timer <= 0.0:
		return
	slow_all_timer = maxf(0.0, slow_all_timer - delta)
	_slow_refresh -= delta
	if _slow_refresh > 0.0 or not _world_authority():
		return
	_slow_refresh = SLOW_REFRESH
	# Reaplica em todos (inclusive quem nasceu depois da mare).
	var hold := minf(slow_all_timer, SLOW_REFRESH + 0.2)
	for enemy in core.enemies:
		enemy["evolution_slow"] = maxf(float(enemy.get("evolution_slow", 0.0)), hold)
		enemy["evolution_slow_mult"] = minf(float(enemy.get("evolution_slow_mult", 1.0)), slow_all_mult)
	if bool(core.boss_active):
		core.boss_ferrolho_slow_timer = maxf(float(core.boss_ferrolho_slow_timer), hold)
		core.boss_ferrolho_slow_ratio = maxf(float(core.boss_ferrolho_slow_ratio), slow_all_boss_ratio)


func _enemy_key(enemy: Dictionary) -> int:
	var uid := int(enemy.get("uid", 0))
	return uid if uid != 0 else hash(enemy.get("spawn_pos", enemy.get("pos", Vector2.ZERO)))


func _update_waves(delta: float) -> void:
	for i in range(waves.size() - 1, -1, -1):
		var wave: Dictionary = waves[i]
		wave["r"] = float(wave["r"]) + float(wave["speed"]) * delta
		var r := float(wave["r"])
		if _world_authority():
			var hit: Dictionary = wave["hit"]
			var center := Vector2(wave["pos"])
			for enemy in core.enemies.duplicate():
				var key := _enemy_key(enemy)
				if hit.has(key):
					continue
				var dist := Vector2(enemy.get("pos", center)).distance_to(center)
				if dist <= r and dist >= r - WAVE_BAND - float(wave["speed"]) * delta:
					hit[key] = true
					_hit_enemy(enemy, float(wave["damage"]), float(wave["slow"]), float(wave["mult"]), float(wave["stun"]))
			if not hit.has(-1) and bool(core.boss_active) and Vector2(core.boss_pos).distance_to(center) <= r:
				hit[-1] = true
				_hit_bosses_in(Vector2(core.boss_pos), 1.0, float(wave["damage"]), 0.25 if float(wave["slow"]) > 0.0 else 0.0)
		if r >= float(wave["max"]):
			waves.remove_at(i)


func _update_zones(delta: float) -> void:
	for i in range(zones.size() - 1, -1, -1):
		var zone: Dictionary = zones[i]
		zone["life"] = float(zone["life"]) - delta
		if bool(zone["follow"]):
			zone["pos"] = core.player_pos
		zone["tick"] = float(zone["tick"]) - delta
		if float(zone["tick"]) <= 0.0 and _world_authority():
			zone["tick"] = ZONE_TICK
			var center := Vector2(zone["pos"])
			var radius := float(zone["radius"])
			var units := float(zone["dps"]) * ZONE_TICK
			var slowed := float(zone["mult"]) < 1.0
			for enemy in core.enemies.duplicate():
				if Vector2(enemy.get("pos", center)).distance_to(center) <= radius:
					_hit_enemy(enemy, units, ZONE_TICK + 0.3 if slowed else 0.0, float(zone["mult"]), 0.0)
			_hit_bosses_in(center, radius, units, 0.15 if slowed else 0.0)
		if float(zone["life"]) <= 0.0:
			zones.remove_at(i)


func _update_orbits(delta: float) -> void:
	for i in range(orbits.size() - 1, -1, -1):
		var orbit: Dictionary = orbits[i]
		orbit["life"] = float(orbit["life"]) - delta
		orbit["angle"] = float(orbit["angle"]) + delta * 4.2
		var hit: Dictionary = orbit["hit"]
		for key in hit.keys():
			hit[key] = float(hit[key]) - delta
			if float(hit[key]) <= 0.0:
				hit.erase(key)
		if _world_authority():
			for point in orbit_points(orbit):
				for enemy in core.enemies.duplicate():
					var key := _enemy_key(enemy)
					if not hit.has(key) and Vector2(enemy.get("pos", point)).distance_to(point) <= 44.0:
						hit[key] = ORBIT_HIT_CD
						_hit_enemy(enemy, float(orbit["damage"]), 0.0, 1.0, 0.0)
				if not hit.has(-1) and bool(core.boss_active) and Vector2(core.boss_pos).distance_to(point) <= core._boss_hit_radius() + 30.0:
					hit[-1] = ORBIT_HIT_CD
					_hit_bosses_in(Vector2(core.boss_pos), 1.0, float(orbit["damage"]))
		if float(orbit["life"]) <= 0.0:
			orbits.remove_at(i)


func orbit_points(orbit: Dictionary) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var count := maxi(1, int(orbit.get("count", 3)))
	for k in range(count):
		var a := float(orbit.get("angle", 0.0)) + TAU * float(k) / float(count)
		out.append(Vector2(core.player_pos) + Vector2.from_angle(a) * float(orbit.get("radius", 110.0)))
	return out


func _update_bursts(delta: float) -> void:
	for i in range(bursts.size() - 1, -1, -1):
		bursts[i]["life"] = float(bursts[i]["life"]) - delta
		if float(bursts[i]["life"]) <= 0.0:
			bursts.remove_at(i)
	if not rewind_fx.is_empty():
		rewind_fx["life"] = float(rewind_fx.get("life", 0.0)) - delta
		if float(rewind_fx["life"]) <= 0.0:
			rewind_fx = {}


# ================================================================ rewind
func _has_rewind() -> bool:
	for id in owned.keys():
		for effect in RTBossDnaCatalog.ability(String(id)).get("effects", []):
			if String(Dictionary(effect).get("kind", "")) == "rewind":
				return true
	return false


func _record_rewind(delta: float) -> void:
	_rewind_sample -= delta
	if _rewind_sample > 0.0 or not _has_rewind():
		return
	_rewind_sample = REWIND_SAMPLE
	var positions: Array = []
	for enemy in core.enemies:
		positions.append([enemy, Vector2(enemy.get("pos", Vector2.ZERO))])
	rewind_history.append({"t": float(core.time_alive), "pos": Vector2(core.player_pos), "hp": int(core.player_hp), "enemies": positions})
	while rewind_history.size() > 1 and float(core.time_alive) - float(rewind_history[0]["t"]) > REWIND_WINDOW:
		rewind_history.pop_front()


## Volta ela e os inimigos `seconds` no tempo. Posicoes de inimigos que ainda
## existem voltam; quem nasceu depois e empurrado para longe. O dano ja
## causado neles fica (o rewind e da Geovana, nao deles).
func _rewind(seconds: float, min_hp_ratio: float, color: Color) -> void:
	var from := Vector2(core.player_pos)
	var target := {}
	var now := float(core.time_alive)
	for sample in rewind_history:
		if now - float(sample["t"]) <= seconds + 0.01:
			target = sample
			break
	var hp_max := int(core.player_hp_max)
	var min_hp := int(ceil(float(hp_max) * min_hp_ratio))
	if not target.is_empty():
		core.player_pos = Vector2(target["pos"])
		core.player_hp = clampi(maxi(int(target["hp"]), min_hp), 1, hp_max)
		if _world_authority():
			var restored := {}
			for pair in target["enemies"]:
				var enemy: Dictionary = pair[0]
				enemy["pos"] = Vector2(pair[1])
				restored[_enemy_key(enemy)] = true
			for enemy in core.enemies:
				if not restored.has(_enemy_key(enemy)):
					var pos := Vector2(enemy.get("pos", from))
					var dir := (pos - Vector2(core.player_pos)).normalized() if pos != core.player_pos else Vector2.RIGHT
					if pos.distance_to(core.player_pos) < 360.0:
						enemy["pos"] = (Vector2(core.player_pos) + dir * 360.0).clamp(Vector2(40, 40), Vector2(core.WORLD_SIZE) - Vector2(40, 40))
	else:
		core.player_hp = clampi(maxi(int(core.player_hp), min_hp), 1, hp_max)
	core.camera_follow_initialized = false
	rewind_history.clear()
	rewind_fx = {"from": from, "to": Vector2(core.player_pos), "life": 1.2, "max": 1.2, "color": color}
	core._add_text("O TEMPO VOLTOU %d s" % int(seconds), Vector2(core.player_pos) + Vector2(-110.0, -160.0), color, 2.0, 22)
	core.screen_shake_timer = maxf(float(core.screen_shake_timer), 0.35)
	core.screen_shake_strength = maxf(float(core.screen_shake_strength), 10.0)


# ================================================================ save
func save_state() -> Dictionary:
	var bank_out := {}
	for phase in bank.keys():
		bank_out[str(phase)] = int(bank[phase])
	return {"bank": bank_out, "owned": owned.duplicate(), "cooldowns": cooldowns.duplicate(), "kills": kill_counters.duplicate(), "fusions": fusions_done, "presented": presented, "reminder": reminder_pending}


func load_state(data: Dictionary) -> void:
	reset_run()
	for key in Dictionary(data.get("bank", {})).keys():
		var phase := int(key)
		if RTBossDnaCatalog.has_boss(phase) and int(data["bank"][key]) > 0:
			bank[phase] = int(data["bank"][key])
	for id in Dictionary(data.get("owned", {})).keys():
		if not RTBossDnaCatalog.ability(String(id)).is_empty():
			owned[String(id)] = clampi(int(data["owned"][id]), 1, RTBossDnaCatalog.MAX_RANK)
	for id in Dictionary(data.get("cooldowns", {})).keys():
		if owned.has(String(id)):
			cooldowns[String(id)] = maxf(0.0, float(data["cooldowns"][id]))
	for id in Dictionary(data.get("kills", {})).keys():
		if owned.has(String(id)):
			kill_counters[String(id)] = int(data["kills"][id])
	fusions_done = maxi(0, int(data.get("fusions", 0)))
	presented = bool(data.get("presented", false))
	reminder_pending = bool(data.get("reminder", false))
