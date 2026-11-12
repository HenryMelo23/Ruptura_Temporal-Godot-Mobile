class_name RTParasiticaController
extends RTAbilityControllerBase

## Parasitica (2026-11): Simbiose Predatoria (HAB1) + Verme-Rei (E).
##
## Ciclo: ATK implanta larvas -> Simbiose transforma acertos em infestados em Fome
## (dano/vel. de ataque/movimento) e mordidas que implantam mais larvas -> o E consome
## o melhor hospedeiro e cria o Verme-Rei, que implanta larvas e devora hospedeiros
## maduros (5 larvas), ficando Alimentado e cada vez mais forte.
##
## Teto de poder alto de proposito: nada aqui tem diminuicao de retorno. Os unicos
## limites sao tecnicos (intervalo minimo de ataque, 1 ataque por quadro, tamanho
## visual e listas de efeitos com tamanho fixo).

# ------------------------------------------------------------------ numeros
const MAX_LARVAE := 5
const MARK_DURATION := 8.0

const SYM_DURATION := 9.0
const SYM_COOLDOWN := 8.0
const SYM_MAX_TOTAL := 18.0
const SYM_KILL_EXTEND := 1.2
const HUNGER_MAX := 12
const HUNGER_GAIN_CD := 0.22
const HUNGER_KILL_GAIN := 2
const HUNGER_IDLE_DELAY := 2.5
const HUNGER_DECAY_PER_SEC := 2.0
const HUNGER_DMG := 0.03
const HUNGER_ATK := 0.02
const HUNGER_MOVE := 0.005
const BITE_EVERY := 4
const BITE_EVERY_MAX := 3
const BITE_DAMAGE := 0.55
const BITE_HEAL := 0.015
const BITE_HEAL_MAX := 0.02
const BITE_CD := 0.65
const BITE_DELAY := 0.08

const KING_COOLDOWN := 75.0
const KING_BASE_DURATION := 14.0
const KING_DMG_BASE := 1.10
const KING_DMG_PER_LARVA := 0.18
const KING_INTERVAL_BASE := 0.72
const KING_INTERVAL_PER_LARVA := 0.04
const KING_TECH_MIN_INTERVAL := 0.05
const KING_FED_DMG := 0.08
const KING_FED_ATK := 0.04
const KING_FED_TIME := 0.8
const KING_FED_TIME_CAP := 10.0
const KING_PERFECT_FED := 2
const KING_RECAST_FED := 2
const DEVOUR_DAMAGE := 3.0
const DEVOUR_BIG_PCT := 0.06
const EXEC_NORMAL := 0.20
const EXEC_PERFECT := 0.25

const KING_EMERGE_TIME := 0.38
const KING_RESURFACE_TIME := 0.2
const KING_BURROW_TIME := 0.16
const KING_LEAVE_TIME := 0.55
const KING_TUNNEL_SPEED := 1650.0
const KING_REACH := 210.0
const KING_SEARCH_RANGE := 1150.0
const PLAYER_TARGET_MEMORY := 2.2
const TRAIL_POINTS := 16
const EVENT_LIMIT := 10

# ------------------------------------------------------------------ simbiose
var sym_active := false
var sym_left := 0.0
var sym_extended := 0.0
var hunger := 0
var hunger_gain_cd := 0.0
var hunger_idle := 99.0
var hunger_decay_acc := 0.0
var hunger_falling := false
var bite_counter := 0
var bite_cd := 0.0
var pending_bites: Array = []
var sym_pulse := 0.0
var bite_visuals: Array = []

# ------------------------------------------------------------------ verme-rei
var king: Dictionary = {}
var events: Array = []

var _player_target: Dictionary = {}
var _player_target_time := -99.0
var _retarget_cd := 0.0
var _clock := 0.0
var _confirmed_infested_kills: Dictionary = {}


func clear_all() -> void:
	_end_symbiosis(false)
	king.clear()
	events.clear()
	bite_visuals.clear()
	pending_bites.clear()
	_player_target = {}
	_confirmed_infested_kills.clear()


func _active_form() -> bool:
	return is_configured() and String(core.manifestation_key) == "parasitica" and String(core.active_character_key) != String(core.CHARACTER_HENRY)


# ================================================================ larvas
func larvae_of(ref: Dictionary) -> int:
	match String(ref.get("kind", "")):
		"boss":
			return int(core.boss_parasite_seeds) if float(core.boss_parasite_mark_time) > 0.0 else 0
		"arauto":
			if not core._arauto_active():
				return 0
			return int(core.arauto.get("seeds", 0)) if float(core.arauto.get("parasite_mark_time", 0.0)) > 0.0 else 0
		"enemy":
			var enemy = core._enemy_by_uid(int(ref.get("uid", -1)))
			if enemy == null:
				return 0
			return int(enemy.get("seeds", 0)) if float(enemy.get("parasite_mark_time", 0.0)) > 0.0 else 0
	return 0


func set_larvae(ref: Dictionary, value: int) -> void:
	var n: int = clampi(value, 0, MAX_LARVAE)
	var mark: float = MARK_DURATION if n > 0 else 0.0
	match String(ref.get("kind", "")):
		"boss":
			core.boss_parasite_seeds = n
			core.boss_parasite_mark_time = mark
		"arauto":
			if core._arauto_active():
				core.arauto["seeds"] = n
				core.arauto["parasite_mark_time"] = mark
		"enemy":
			var enemy = core._enemy_by_uid(int(ref.get("uid", -1)))
			if enemy != null:
				enemy["seeds"] = n
				enemy["parasite_mark_time"] = mark
				if n > 0 and core._is_world_authority():
					enemy["parasite_owner_peer_id"] = core._mp_unique_id()


func add_larva(ref: Dictionary, amount: int = 1) -> int:
	var n: int = mini(MAX_LARVAE, larvae_of(ref) + amount)
	set_larvae(ref, n)
	return n


func ref_alive(ref: Dictionary) -> bool:
	match String(ref.get("kind", "")):
		"boss":
			return bool(core.boss_active) and float(core.boss_hp) > 0.0 and core._boss_available_for_auto_target()
		"arauto":
			return core._arauto_active() and float(core.arauto.get("hp", 0.0)) > 0.0
		"enemy":
			var enemy = core._enemy_by_uid(int(ref.get("uid", -1)))
			return enemy != null and float(enemy.get("hp", 0.0)) > 0.0
	return false


func ref_pos(ref: Dictionary) -> Vector2:
	match String(ref.get("kind", "")):
		"boss":
			return Vector2(core.boss_pos)
		"arauto":
			return Vector2(core.arauto.get("pos", core.player_pos)) if core._arauto_active() else Vector2.INF
		"enemy":
			var enemy = core._enemy_by_uid(int(ref.get("uid", -1)))
			return Vector2(enemy.get("pos", Vector2.INF)) if enemy != null else Vector2.INF
	return Vector2.INF


func ref_radius(ref: Dictionary) -> float:
	match String(ref.get("kind", "")):
		"boss":
			return core._boss_hit_radius()
		"arauto":
			return 58.0
		"enemy":
			var enemy = core._enemy_by_uid(int(ref.get("uid", -1)))
			return core._enemy_radius(enemy) if enemy != null else 24.0
	return 24.0


## 0 = chefe, 1 = Arauto/mini-chefe, 2 = comum.
func ref_rank(ref: Dictionary) -> int:
	match String(ref.get("kind", "")):
		"boss":
			return 0
		"arauto":
			return 1
		"enemy":
			var enemy = core._enemy_by_uid(int(ref.get("uid", -1)))
			if enemy != null and core._is_boss_or_mini_boss_or_larapio(enemy):
				return 1
	return 2


func ref_is_big(ref: Dictionary) -> bool:
	return ref_rank(ref) < 2


func enemy_ref(enemy: Dictionary) -> Dictionary:
	return {"kind": "enemy", "uid": int(enemy.get("uid", -1))}


static func same_ref(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("kind", "")) == String(b.get("kind", "?")) and int(a.get("uid", -1)) == int(b.get("uid", -1))


## Todos os alvos vivos, com larvas e prioridade.
func candidates(only_infested: bool) -> Array:
	var out: Array = []
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		if bool(enemy.get("aguilhao_nodule", false)):
			continue
		var ref := enemy_ref(enemy)
		var seeds: int = int(enemy.get("seeds", 0)) if float(enemy.get("parasite_mark_time", 0.0)) > 0.0 else 0
		if only_infested and seeds <= 0:
			continue
		out.append({"ref": ref, "seeds": seeds, "rank": 1 if core._is_boss_or_mini_boss_or_larapio(enemy) else 2, "pos": Vector2(enemy["pos"])})
	for kind in ["boss", "arauto"]:
		var ref := {"kind": kind, "uid": -1}
		if not ref_alive(ref):
			continue
		var s: int = larvae_of(ref)
		if only_infested and s <= 0:
			continue
		out.append({"ref": ref, "seeds": s, "rank": 0 if kind == "boss" else 1, "pos": ref_pos(ref)})
	return out


## Hospedeiro do E: mais larvas; empate -> chefe, Arauto/mini, mais perto do jogador.
func best_host() -> Dictionary:
	var best: Dictionary = {}
	for c in candidates(true):
		if best.is_empty():
			best = c
			continue
		if int(c["seeds"]) != int(best["seeds"]):
			if int(c["seeds"]) > int(best["seeds"]):
				best = c
			continue
		if int(c["rank"]) != int(best["rank"]):
			if int(c["rank"]) < int(best["rank"]):
				best = c
			continue
		if Vector2(c["pos"]).distance_squared_to(core.player_pos) < Vector2(best["pos"]).distance_squared_to(core.player_pos):
			best = c
	return best


# ================================================================ simbiose
func symbiosis_cooldown_base() -> float:
	return SYM_COOLDOWN


func activate_symbiosis() -> void:
	if sym_active:
		# Reativar renova a duracao e reabre a janela de extensao; a Fome fica.
		sym_left = maxf(sym_left, SYM_DURATION)
		sym_extended = 0.0
		core._add_text("SIMBIOSE RENOVADA", core.player_pos + Vector2(-80, -112), Color(0.78, 1.0, 0.36), 0.9, 19)
	else:
		sym_active = true
		sym_left = SYM_DURATION
		sym_extended = 0.0
		hunger = 0
		bite_counter = 0
		hunger_idle = 0.0
		hunger_decay_acc = 0.0
		core._add_text("SIMBIOSE PREDATORIA", core.player_pos + Vector2(-96, -112), Color(0.72, 1.0, 0.32), 1.2, 22)
	sym_pulse = 1.0
	core._spawn_radial_particles(core.player_pos, Color(0.5, 0.92, 0.22), 18)


func _end_symbiosis(show_text: bool) -> void:
	if sym_active and show_text and is_configured():
		core._add_text("SIMBIOSE ENCERRADA", core.player_pos + Vector2(-86, -104), Color(0.62, 0.78, 0.4), 0.8, 17)
	sym_active = false
	sym_left = 0.0
	sym_extended = 0.0
	hunger = 0
	hunger_falling = false
	bite_counter = 0
	pending_bites.clear()


func damage_multiplier() -> float:
	return 1.0 + HUNGER_DMG * float(hunger) if sym_active else 1.0


func attack_speed_multiplier() -> float:
	return 1.0 + HUNGER_ATK * float(hunger) if sym_active else 1.0


func move_multiplier() -> float:
	return 1.0 + HUNGER_MOVE * float(hunger) if sym_active else 1.0


func bite_every() -> int:
	return BITE_EVERY_MAX if hunger >= HUNGER_MAX else BITE_EVERY


func _gain_hunger(amount: int) -> void:
	hunger = mini(HUNGER_MAX, hunger + amount)


func _is_own_source(source: String) -> bool:
	return source.begins_with("parasite_")


## Chamado pelo runtime a cada dano direto do jogador (antes de aplicar o golpe).
func on_player_damage(kind: String, enemy: Dictionary, source: String, category: String) -> void:
	if not _active_form() or _is_own_source(source):
		return
	if not core._is_direct_player_damage_source(source, category):
		return
	var ref: Dictionary = enemy_ref(enemy) if kind == "enemy" else {"kind": kind, "uid": -1}
	_player_target = ref
	_player_target_time = float(core.time_alive)
	if not sym_active or larvae_of(ref) <= 0:
		return
	hunger_idle = 0.0
	hunger_falling = false
	if hunger_gain_cd <= 0.0 and hunger < HUNGER_MAX:
		_gain_hunger(1)
		hunger_gain_cd = HUNGER_GAIN_CD
		sym_pulse = 1.0
	bite_counter += 1
	if bite_counter >= bite_every() and bite_cd <= 0.0 and pending_bites.size() < 4:
		bite_counter = 0
		bite_cd = BITE_CD
		pending_bites.append({"ref": ref, "t": BITE_DELAY})


func on_infested_kill(_enemy: Dictionary) -> void:
	if not _active_form() or not sym_active:
		return
	_gain_hunger(HUNGER_KILL_GAIN)
	var room: float = maxf(0.0, (SYM_MAX_TOTAL - SYM_DURATION) - sym_extended)
	var ext: float = minf(SYM_KILL_EXTEND, room)
	if ext > 0.0:
		sym_left += ext
		sym_extended += ext
	hunger_idle = 0.0
	sym_pulse = 1.0


func apply_confirmed_infested_kill(event_id: String) -> bool:
	if event_id == "" or bool(_confirmed_infested_kills.get(event_id, false)):
		return false
	_confirmed_infested_kills[event_id] = true
	while _confirmed_infested_kills.size() > 128:
		var keys: Array = _confirmed_infested_kills.keys()
		if keys.is_empty():
			break
		_confirmed_infested_kills.erase(keys[0])
	var before: float = sym_left
	on_infested_kill({})
	return sym_left > before


func _do_bite(ref: Dictionary) -> void:
	if not ref_alive(ref):
		return
	var pos: Vector2 = ref_pos(ref)
	var damage: float = float(core.player_damage) * BITE_DAMAGE
	_damage_ref(ref, damage, "parasite_bite", "skill_q")
	add_larva(ref)
	var heal_ratio: float = BITE_HEAL_MAX if hunger >= HUNGER_MAX else BITE_HEAL
	core._heal_player(float(core.player_hp_max) * heal_ratio, "parasite_bite")
	if bite_visuals.size() >= EVENT_LIMIT:
		bite_visuals.pop_front()
	bite_visuals.append({"from": Vector2(core.player_pos), "to": pos, "life": 0.32, "max": 0.32})
	core._spawn_radial_particles(pos, Color(0.62, 0.9, 0.24), 6)


func _update_symbiosis(delta: float) -> void:
	hunger_gain_cd = maxf(0.0, hunger_gain_cd - delta)
	bite_cd = maxf(0.0, bite_cd - delta)
	sym_pulse = maxf(0.0, sym_pulse - delta * 3.2)
	for i in range(bite_visuals.size() - 1, -1, -1):
		bite_visuals[i]["life"] = float(bite_visuals[i]["life"]) - delta
		if float(bite_visuals[i]["life"]) <= 0.0:
			bite_visuals.remove_at(i)
	if not sym_active:
		return
	for i in range(pending_bites.size() - 1, -1, -1):
		pending_bites[i]["t"] = float(pending_bites[i]["t"]) - delta
		if float(pending_bites[i]["t"]) <= 0.0:
			var bite: Dictionary = pending_bites[i]
			pending_bites.remove_at(i)
			_do_bite(Dictionary(bite["ref"]))
	hunger_idle += delta
	hunger_falling = hunger > 0 and hunger_idle >= HUNGER_IDLE_DELAY
	if hunger_falling:
		hunger_decay_acc += HUNGER_DECAY_PER_SEC * delta
		while hunger_decay_acc >= 1.0 and hunger > 0:
			hunger -= 1
			hunger_decay_acc -= 1.0
	else:
		hunger_decay_acc = 0.0
	sym_left -= delta
	if sym_left <= 0.0:
		_end_symbiosis(true)


# ================================================================ verme-rei
func king_active() -> bool:
	return not king.is_empty() and bool(king.get("active", false))


## Retorna false (e nao gasta recarga) quando nao ha alvo com larvas.
func cast_king() -> bool:
	var host: Dictionary = best_host()
	if host.is_empty():
		core._add_text("NENHUM HOSPEDEIRO COM LARVAS", core.player_pos + Vector2(-120, -110), Color(0.72, 1.0, 0.42), 1.0, 19)
		return false
	var ref: Dictionary = host["ref"]
	var consumed: int = clampi(int(host["seeds"]), 1, MAX_LARVAE)
	set_larvae(ref, 0)
	var host_pos: Vector2 = ref_pos(ref)
	if king_active():
		# Nova ativacao alimenta o rei existente em vez de criar outro.
		king["life"] = float(king["life"]) + KING_BASE_DURATION + float(consumed)
		king["max_life"] = maxf(float(king["max_life"]), float(king["life"]))
		if consumed > int(king["consumed"]):
			king["consumed"] = consumed
		if consumed >= MAX_LARVAE:
			king["perfect"] = true
		_add_fed(KING_RECAST_FED, false)
		king["target"] = ref
		_begin_tunnel(host_pos)
		_push_event("recast", host_pos)
		core._add_text("O REI SE ALIMENTA x%d" % consumed, host_pos + Vector2(-90, -96), Color(1.0, 0.82, 0.3), 1.2, 22)
		return true
	var perfect: bool = consumed >= MAX_LARVAE
	king = {
		"active": true,
		"state": "emerge",
		"state_t": 0.0,
		"pos": host_pos + Vector2(ref_radius(ref) + 26.0, 10.0),
		"target": ref,
		"consumed": consumed,
		"perfect": perfect,
		"fed": 0,
		"fed_time": 0.0,
		"life": KING_BASE_DURATION + float(consumed),
		"max_life": KING_BASE_DURATION + float(consumed),
		"atk_cd": 0.25,
		"bite": 0.0,
		"devour": 0.0,
		"facing": 1.0,
		"trail": [],
		"attacks": 0,
		"devours": 0,
		"seed": int(core.rng.randi() % 100000)
	}
	if perfect:
		_add_fed(KING_PERFECT_FED, false)
	_push_event("emerge", host_pos)
	core._add_text("REI PERFEITO" if perfect else "VERME-REI", host_pos + Vector2(-70, -110), Color(1.0, 0.78, 0.26) if perfect else Color(0.74, 1.0, 0.36), 1.4, 28 if perfect else 24)
	core._spawn_radial_particles(host_pos, Color(0.46, 0.86, 0.2), 26)
	return true


func king_damage_multiplier() -> float:
	if king.is_empty():
		return 0.0
	return (KING_DMG_BASE + KING_DMG_PER_LARVA * float(king.get("consumed", 1))) * (1.0 + KING_FED_DMG * float(king.get("fed", 0)))


func king_damage() -> float:
	return float(core.player_damage) * king_damage_multiplier()


func king_interval() -> float:
	if king.is_empty():
		return KING_INTERVAL_BASE
	var base: float = KING_INTERVAL_BASE - KING_INTERVAL_PER_LARVA * float(king.get("consumed", 1))
	# Velocidade de ataque do jogador (cartas, Fome, auras) tambem acelera o rei.
	var attack_ratio: float = float(core.PLAYER_BASE_ATTACK_INTERVAL) / maxf(0.01, float(core._current_attack_interval()))
	var interval: float = base / (1.0 + KING_FED_ATK * float(king.get("fed", 0))) / maxf(0.05, attack_ratio)
	return maxf(KING_TECH_MIN_INTERVAL, interval)


func execute_threshold() -> float:
	return EXEC_PERFECT if bool(king.get("perfect", false)) else EXEC_NORMAL


## extend=false para os acumulos iniciais (Rei Perfeito / nova ativacao): a duracao
## inicial ja e 14s + 1s por larva; so Devorar Hospedeiro estende o tempo.
func _add_fed(stacks: int, extend: bool = true) -> void:
	king["fed"] = int(king.get("fed", 0)) + stacks
	if not extend:
		return
	var room: float = maxf(0.0, KING_FED_TIME_CAP - float(king.get("fed_time", 0.0)))
	var ext: float = minf(KING_FED_TIME * float(stacks), room)
	if ext > 0.0:
		king["fed_time"] = float(king.get("fed_time", 0.0)) + ext
		king["life"] = float(king["life"]) + ext
		king["max_life"] = maxf(float(king["max_life"]), float(king["life"]))


func _push_event(kind: String, pos: Vector2) -> void:
	if events.size() >= EVENT_LIMIT:
		events.pop_front()
	events.append({"kind": kind, "pos": pos, "life": 0.6, "max": 0.6})


func _set_state(state: String) -> void:
	king["state"] = state
	king["state_t"] = 0.0


func _begin_tunnel(destination: Vector2) -> void:
	king["dest"] = destination
	if String(king.get("state", "")) in ["tunnel", "burrow"]:
		return
	_set_state("burrow")


func _pick_target() -> Dictionary:
	var kpos: Vector2 = Vector2(king.get("pos", core.player_pos))
	# 1) o alvo que Geovana esta atacando
	if not _player_target.is_empty() and float(core.time_alive) - _player_target_time <= PLAYER_TARGET_MEMORY and ref_alive(_player_target):
		return _player_target
	var all: Array = candidates(false)
	var best: Dictionary = {}
	var best_class := 99
	var best_d := INF
	for c in all:
		var pos: Vector2 = c["pos"]
		if pos.distance_to(core.player_pos) > KING_SEARCH_RANGE:
			continue
		var s: int = int(c["seeds"])
		var cls: int = 0 if s >= MAX_LARVAE else (1 if s > 0 else 2)
		var d: float = pos.distance_squared_to(kpos)
		if cls < best_class or (cls == best_class and d < best_d):
			best = c["ref"]
			best_class = cls
			best_d = d
	return best


func _desired_attack_pos(ref: Dictionary) -> Vector2:
	var tpos: Vector2 = ref_pos(ref)
	var side: float = 1.0 if Vector2(king.get("pos", tpos)).x >= tpos.x else -1.0
	return tpos + Vector2(side * (ref_radius(ref) + 24.0), 12.0)


func _face(ref: Dictionary) -> void:
	var tpos: Vector2 = ref_pos(ref)
	if tpos != Vector2.INF and absf(tpos.x - Vector2(king["pos"]).x) > 2.0:
		king["facing"] = -1.0 if tpos.x < Vector2(king["pos"]).x else 1.0


func _king_attack(ref: Dictionary) -> void:
	_face(ref)
	king["attacks"] = int(king.get("attacks", 0)) + 1
	if larvae_of(ref) >= MAX_LARVAE:
		_devour(ref)
		return
	_damage_ref(ref, king_damage(), "parasite_king", "skill_e")
	king["bite"] = 0.22
	if ref_alive(ref):
		var n: int = add_larva(ref)
		if n >= MAX_LARVAE:
			_devour(ref)


## Devorar Hospedeiro: consome as 5 larvas.
func _devour(ref: Dictionary) -> void:
	var tpos: Vector2 = ref_pos(ref)
	if not king.is_empty():
		_face(ref)
	set_larvae(ref, 0)
	king["devour"] = 0.5
	king["devours"] = int(king.get("devours", 0)) + 1
	_push_event("devour", tpos)
	var fed_mult: float = 1.0 + KING_FED_DMG * float(king.get("fed", 0))
	if ref_is_big(ref):
		_damage_ref(ref, king_damage(), "parasite_king", "skill_e")
		if ref_alive(ref):
			_damage_ref(ref, _ref_current_hp(ref) * DEVOUR_BIG_PCT, "parasite_devour", "skill_e")
		core._add_text("DEVORAR HOSPEDEIRO", tpos + Vector2(-96, -120), Color(1.0, 0.7, 0.24), 0.9, 21)
	else:
		var enemy = core._enemy_by_uid(int(ref.get("uid", -1)))
		if enemy != null:
			enemy["parasite_devoured"] = true
		_damage_ref(ref, float(core.player_damage) * DEVOUR_DAMAGE * fed_mult, "parasite_devour", "skill_e")
		if enemy != null and float(enemy.get("hp", 0.0)) > 0.0:
			var ratio: float = float(enemy["hp"]) / maxf(1.0, float(enemy.get("max_hp", enemy["hp"])))
			if ratio < execute_threshold():
				_damage_ref(ref, float(enemy["hp"]) * 50.0 + float(enemy.get("max_hp", 1.0)), "parasite_devour", "skill_e")
				core._add_text("DEVORADO", tpos + Vector2(-50, -90), Color(1.0, 0.62, 0.2), 0.8, 20)
	_add_fed(1)
	core._spawn_radial_particles(tpos, Color(0.9, 0.62, 0.16), 14)


func _ref_current_hp(ref: Dictionary) -> float:
	match String(ref.get("kind", "")):
		"boss":
			return float(core.boss_hp)
		"arauto":
			return float(core.arauto.get("hp", 0.0))
		"enemy":
			var enemy = core._enemy_by_uid(int(ref.get("uid", -1)))
			return float(enemy.get("hp", 0.0)) if enemy != null else 0.0
	return 0.0


func _damage_ref(ref: Dictionary, amount: float, source: String, category: String) -> void:
	if amount <= 0.0 or not ref_alive(ref):
		return
	var origin: Vector2 = Vector2(king.get("pos", core.player_pos)) if source != "parasite_bite" else Vector2(core.player_pos)
	match String(ref.get("kind", "")):
		"boss":
			core._damage_boss(amount, source, true, true, category, origin)
		"arauto":
			core._damage_arauto(amount, source, true, true, category, origin)
		"enemy":
			var enemy = core._enemy_by_uid(int(ref.get("uid", -1)))
			if enemy != null:
				core._damage_enemy(enemy, amount, source, true, true, origin, category)


func _update_king(delta: float) -> void:
	for i in range(events.size() - 1, -1, -1):
		events[i]["life"] = float(events[i]["life"]) - delta
		if float(events[i]["life"]) <= 0.0:
			events.remove_at(i)
	if not king_active():
		return
	king["state_t"] = float(king.get("state_t", 0.0)) + delta
	king["bite"] = maxf(0.0, float(king.get("bite", 0.0)) - delta)
	king["devour"] = maxf(0.0, float(king.get("devour", 0.0)) - delta)
	var state: String = String(king.get("state", "attack"))
	if state != "leave":
		king["life"] = float(king["life"]) - delta
		if float(king["life"]) <= 0.0:
			_set_state("leave")
			_push_event("leave", Vector2(king["pos"]))
			return
	var t: float = float(king["state_t"])
	match state:
		"leave":
			if t >= KING_LEAVE_TIME:
				king.clear()
			return
		"emerge", "resurface":
			if t >= (KING_EMERGE_TIME if state == "emerge" else KING_RESURFACE_TIME):
				_set_state("attack")
			return
		"burrow":
			if t >= KING_BURROW_TIME:
				_set_state("tunnel")
			return
		"tunnel":
			var dest: Vector2 = Vector2(king.get("dest", king["pos"]))
			var target: Dictionary = Dictionary(king.get("target", {}))
			if ref_alive(target):
				dest = _desired_attack_pos(target)
				king["dest"] = dest
			var pos: Vector2 = Vector2(king["pos"])
			pos = pos.move_toward(dest, KING_TUNNEL_SPEED * delta)
			king["pos"] = pos
			_trail_add(pos)
			if pos.distance_to(dest) <= 8.0:
				_set_state("resurface" if ref_alive(target) else "follow")
				if ref_alive(target):
					_push_event("surface", pos)
			return
		"follow":
			_retarget_cd -= delta
			var home: Vector2 = Vector2(core.player_pos) + Vector2(-70.0 * float(king.get("facing", 1.0)), 46.0)
			king["pos"] = Vector2(king["pos"]).lerp(home, clampf(delta * 4.0, 0.0, 1.0))
			_trail_add(Vector2(king["pos"]))
			if _retarget_cd <= 0.0:
				_retarget_cd = 0.25
				var next: Dictionary = _pick_target()
				if not next.is_empty():
					king["target"] = next
					_begin_tunnel(_desired_attack_pos(next))
			return
	# ---- attack
	var target: Dictionary = Dictionary(king.get("target", {}))
	_retarget_cd -= delta
	if not ref_alive(target) or _retarget_cd <= 0.0:
		_retarget_cd = 0.6
		var next: Dictionary = _pick_target()
		if next.is_empty():
			if not ref_alive(target):
				king["target"] = {}
				_set_state("burrow")
				king["dest"] = Vector2(core.player_pos)
			return
		if not same_ref(next, target):
			king["target"] = next
			target = next
			var dest: Vector2 = _desired_attack_pos(target)
			if dest.distance_to(Vector2(king["pos"])) > 40.0:
				_begin_tunnel(dest)
				return
	if not ref_alive(target):
		return
	var desired: Vector2 = _desired_attack_pos(target)
	var kpos: Vector2 = Vector2(king["pos"])
	if kpos.distance_to(desired) > KING_REACH:
		_begin_tunnel(desired)
		return
	king["pos"] = kpos.move_toward(desired, 260.0 * delta)
	_face(target)
	# Um ataque por quadro no maximo (limite tecnico).
	king["atk_cd"] = float(king.get("atk_cd", 0.0)) - delta
	if float(king["atk_cd"]) <= 0.0:
		king["atk_cd"] = maxf(float(king["atk_cd"]) + king_interval(), 0.0)
		_king_attack(target)


func _trail_add(pos: Vector2) -> void:
	var trail: Array = king.get("trail", [])
	if trail.is_empty() or Vector2(trail[-1]).distance_to(pos) > 18.0:
		trail.append(pos)
		while trail.size() > TRAIL_POINTS:
			trail.pop_front()
	king["trail"] = trail


# ================================================================ ciclo
func update(delta: float) -> void:
	_clock += delta
	if not _active_form():
		if sym_active or king_active():
			clear_all()
		return
	_update_symbiosis(delta)
	_update_king(delta)


func visual_level() -> float:
	if king.is_empty():
		return 1.0
	# Escala visual limitada (limite tecnico de leitura); o poder nao tem teto.
	var base: float = 1.0 + 0.07 * float(king.get("consumed", 1)) + (0.16 if bool(king.get("perfect", false)) else 0.0)
	return minf(2.3, base + 0.035 * float(int(king.get("fed", 0))))


# ================================================================ save / rede
func save_state() -> Dictionary:
	return {
		"sym_active": sym_active, "sym_left": sym_left, "sym_extended": sym_extended,
		"hunger": hunger, "bite_counter": bite_counter, "bite_cd": bite_cd, "hunger_idle": hunger_idle,
		"king": king.duplicate(true),
	}


func load_state(data: Dictionary) -> void:
	clear_all()
	if data.is_empty():
		return
	sym_active = bool(data.get("sym_active", false))
	sym_left = float(data.get("sym_left", 0.0))
	sym_extended = float(data.get("sym_extended", 0.0))
	hunger = clampi(int(data.get("hunger", 0)), 0, HUNGER_MAX)
	bite_counter = int(data.get("bite_counter", 0))
	bite_cd = float(data.get("bite_cd", 0.0))
	hunger_idle = float(data.get("hunger_idle", 0.0))
	var k = data.get("king", {})
	king = Dictionary(k).duplicate(true) if k is Dictionary else {}


## Estado compacto para replicas (sem refs de alvo; so o que e visual).
func visual_snapshot() -> Dictionary:
	var snap: Dictionary = {
		"sym": sym_active, "sym_left": snappedf(sym_left, 0.1), "hunger": hunger, "falling": hunger_falling,
	}
	if king_active():
		var target: Dictionary = Dictionary(king.get("target", {}))
		snap["king"] = {
			"pos": Vector2(king["pos"]), "state": String(king["state"]), "state_t": snappedf(float(king["state_t"]), 0.01),
			"consumed": int(king["consumed"]), "perfect": bool(king["perfect"]), "fed": int(king["fed"]),
			"life": snappedf(float(king["life"]), 0.1), "max_life": snappedf(float(king["max_life"]), 0.1),
			"bite": snappedf(float(king.get("bite", 0.0)), 0.01), "devour": snappedf(float(king.get("devour", 0.0)), 0.01),
			"facing": float(king.get("facing", 1.0)), "trail": Array(king.get("trail", [])).slice(-8),
			"target_pos": ref_pos(target) if ref_alive(target) else Vector2.INF, "seed": int(king.get("seed", 0)),
		}
	return snap
