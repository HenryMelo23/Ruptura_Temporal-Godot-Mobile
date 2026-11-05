class_name RTArautoThreatController
extends RefCounted

## Mecanicas de confronto dos Arautos (sem mexer na vida/armadura deles).
## Condutor de Ecos (fase 1): Coro de Ecos, Olhar Prismatico, Silencio Total, Inversao de Eco.
## Aguilhao (fase 6): Investida Ricochete (no core), Ferrao Venenoso, Casca Endurecida.
## Roda so na autoridade do mundo. O estado publico fica em `abilities` / `stings` para
## a apresentacao (RTArautoThreatPresentation).

# --- Condutor -----------------------------------------------------------------
const CHOIR_COOLDOWN := 9.0
const CHOIR_COOLDOWN_PHASE2 := 6.5
const CHOIR_TELEGRAPH := 0.95
const CHOIR_LOCK := 0.6
const CHOIR_BEAM_WIDTH := 24.0
const CHOIR_BEAM_LENGTH := 980.0
const CHOIR_PHASE2_RESPAWN := 3

const PRISM_COOLDOWN := 13.0
const PRISM_COOLDOWN_PHASE2 := 10.0
const PRISM_TELEGRAPH := 0.95
const PRISM_DURATION := 3.4
const PRISM_SPIN := 0.85
const PRISM_BEAMS := 3
const PRISM_WIDTH := 26.0
const PRISM_LENGTH := 900.0
const PRISM_TICK := 0.55

const HUSH_COOLDOWN := 17.0
const HUSH_COOLDOWN_PHASE2 := 12.5
const HUSH_TELEGRAPH := 1.6
const HUSH_SAFE_RADIUS := 86.0
const HUSH_SILENCE := 3.0

const INVERSION_COOLDOWN := 11.0
const INVERSION_DELAY := 2.0
const INVERSION_DETONATE := 0.55
const INVERSION_RADIUS := 74.0

# --- Aguilhao -----------------------------------------------------------------
const RICOCHET_BOUNCES := 3
const RICOCHET_AIM := 0.5
const STING_COOLDOWN := 6.0
const STING_COOLDOWN_PHASE2 := 4.4
const STING_SPEED := 640.0
const STING_RADIUS := 20.0
const VENOM_MAX := 5
const VENOM_DPS_RATIO := 0.011
const VENOM_STACK_LIFE := 7.0
const SHELL_COOLDOWN := 14.0
const SHELL_COOLDOWN_PHASE2 := 10.5
const SHELL_TELEGRAPH := 0.6
const SHELL_DURATION := 3.0
const SHELL_FRONT_MULT := 0.1
const SHELL_SPIKE_CD := 0.3

var game: Node
## Habilidade em andamento (vazio = livre). Chaves: kind, age, ...
var ability: Dictionary = {}
## Marca da Inversao de Eco (independente das outras habilidades).
var inversion: Dictionary = {}
var stings: Array = []
var spikes: Array = []
var venom_stacks: Array = []  # lista de tempos restantes (local)
var venom_tick := 0.0
var shell_spike_cd := 0.0
var _cds: Dictionary = {}
var _last_nodules := -1
var _phase2_seen := false
var _player_prev := Vector2.ZERO
var _player_vel := Vector2.ZERO


func bind_game(p_game: Node) -> void:
	game = p_game


func reset() -> void:
	ability.clear()
	inversion.clear()
	stings.clear()
	spikes.clear()
	venom_stacks.clear()
	venom_tick = 0.0
	shell_spike_cd = 0.0
	_cds = {"choir": 4.0, "prism": 7.0, "hush": 11.0, "inversion": 6.0, "sting": 3.0, "shell": 8.0}
	_last_nodules = -1
	_phase2_seen = false


func busy() -> bool:
	return not ability.is_empty()


func shell_active() -> bool:
	return String(ability.get("kind", "")) == "shell" and float(ability.get("age", 0.0)) >= SHELL_TELEGRAPH


func _cd(key: String) -> float:
	return float(_cds.get(key, 0.0))


## Chamado pelo _update_arauto (autoridade). Devolve true quando a habilidade nova
## esta ocupando o Arauto e a IA base nao deve escolher outra acao neste quadro.
func update(delta: float, phase2: bool) -> bool:
	if game == null or not game._arauto_active():
		return false
	if _cds.is_empty():
		reset()
	if game._arauto_is_aguilhao():
		return _update_aguilhao(delta, phase2)
	return _update_condutor(delta, phase2)


## Atualizacoes que continuam mesmo sem Arauto (veneno, ferroes, espinhos).
func update_world(delta: float) -> void:
	if game == null:
		return
	if _cds.is_empty():
		reset()
	# Recargas correm sempre (antes so nos quadros livres do Arauto).
	if game._arauto_active() and float(game.arauto.get("entry_timer", 0.0)) <= 0.0:
		for key in _cds.keys():
			_cds[key] = maxf(0.0, float(_cds[key]) - delta)
	if delta > 0.0:
		var vel: Vector2 = (game.player_pos - _player_prev) / delta
		_player_vel = _player_vel.lerp(vel, 0.25) if vel.length() < 2000.0 else _player_vel
		_player_prev = game.player_pos
	_update_stings(delta)
	_update_spikes(delta)
	_update_venom(delta)
	if not game._arauto_active():
		if not ability.is_empty() or not inversion.is_empty():
			ability.clear()
			inversion.clear()


# ============================== CONDUTOR ======================================

func _update_condutor(delta: float, phase2: bool) -> bool:
	if phase2 and not _phase2_seen:
		_phase2_seen = true
		if game._count_arauto_echoes() < CHOIR_PHASE2_RESPAWN:
			game._spawn_arauto_echoes(CHOIR_PHASE2_RESPAWN)
			game._add_text("O CORO RENASCE!", Vector2(game.arauto["pos"]) + Vector2(-110, -170), Color(0.64, 0.92, 1.0), 1.6, 22)
	_update_inversion(delta, phase2)
	if not ability.is_empty():
		ability["age"] = float(ability.get("age", 0.0)) + delta
		match String(ability.get("kind", "")):
			"choir":
				_update_choir(phase2)
			"prism":
				_update_prism(delta)
			"hush":
				_update_hush()
		return true
	if bool(game.arauto.get("gaze_active", false)) or bool(game.arauto.get("silence_active", false)):
		return false
	var dist: float = Vector2(game.arauto["pos"]).distance_to(game.player_pos)
	if _cd("hush") <= 0.0:
		_start_hush(phase2)
	elif _cd("prism") <= 0.0 and dist < 760.0:
		_start_prism()
	elif _cd("choir") <= 0.0 and game._count_arauto_echoes() > 0:
		_start_choir()
	elif _cd("inversion") <= 0.0 and inversion.is_empty():
		_start_inversion()
		return false
	else:
		return false
	return true


func _start_choir() -> void:
	ability = {"kind": "choir", "age": 0.0, "target": game.player_pos, "sources": [], "fired": false}
	_cds["choir"] = CHOIR_COOLDOWN
	game._add_text("CORO DE ECOS!", Vector2(game.arauto["pos"]) + Vector2(-90, -160), Color(0.62, 0.92, 1.0), 1.1, 21)


func _choir_sources() -> Array:
	var result: Array = []
	for enemy in game.enemies:
		if bool(enemy.get("eco_vinculado", false)) and float(enemy.get("hp", 0.0)) > 0.0:
			result.append(Vector2(enemy["pos"]))
	return result


func _update_choir(phase2: bool) -> void:
	var age: float = float(ability["age"])
	ability["sources"] = _choir_sources()
	if age < CHOIR_LOCK:
		ability["target"] = game.player_pos
	if age >= CHOIR_TELEGRAPH and not bool(ability["fired"]):
		ability["fired"] = true
		var target: Vector2 = ability["target"]
		var damage := int((game.player_hp_max * 0.05 + game.enemy_far_damage * 0.3) * game.ARAUTO_DAMAGE_MULT)
		var hit := false
		for src_value in ability["sources"]:
			var src: Vector2 = src_value
			var dir: Vector2 = (target - src).normalized()
			var end: Vector2 = src + dir * CHOIR_BEAM_LENGTH
			if not hit and game._local_player_damageable_by_contact() and game._distance_to_segment(game.player_pos, src, end) <= CHOIR_BEAM_WIDTH:
				hit = true
				game._damage_player(damage, "coro_ecos")
			game._damage_remote_player_on_segment(src, end, CHOIR_BEAM_WIDTH, damage, "coro_ecos")
		game.screen_shake_timer = maxf(float(game.screen_shake_timer), 0.12)
		game.screen_shake_strength = maxf(float(game.screen_shake_strength), 4.0)
	if age >= CHOIR_TELEGRAPH + 0.35:
		_cds["choir"] = CHOIR_COOLDOWN_PHASE2 if phase2 else CHOIR_COOLDOWN
		ability.clear()


func _start_prism() -> void:
	var to_player: Vector2 = game.player_pos - Vector2(game.arauto["pos"])
	ability = {"kind": "prism", "age": 0.0, "base_angle": to_player.angle() + PI / float(PRISM_BEAMS), "spin": 1.0 if game.rng.randf() < 0.5 else -1.0, "tick": 0.0}
	_cds["prism"] = PRISM_COOLDOWN
	game._add_text("OLHAR PRISMATICO!", Vector2(game.arauto["pos"]) + Vector2(-110, -160), Color(1.0, 0.6, 1.0), 1.1, 21)


func prism_angle(i: int) -> float:
	var age: float = float(ability.get("age", 0.0))
	var spin_t: float = maxf(0.0, age - PRISM_TELEGRAPH)
	return float(ability.get("base_angle", 0.0)) + float(i) * TAU / float(PRISM_BEAMS) + spin_t * PRISM_SPIN * float(ability.get("spin", 1.0))


func _update_prism(delta: float) -> void:
	var age: float = float(ability["age"])
	if age >= PRISM_TELEGRAPH:
		ability["tick"] = float(ability["tick"]) - delta
		if float(ability["tick"]) <= 0.0:
			ability["tick"] = PRISM_TICK
			var origin: Vector2 = Vector2(game.arauto["pos"])
			var damage := int((game.player_hp_max * 0.014 + game.enemy_far_damage * 0.1) * game.ARAUTO_DAMAGE_MULT)
			for i in range(PRISM_BEAMS):
				var end: Vector2 = origin + Vector2.from_angle(prism_angle(i)) * PRISM_LENGTH
				if game._local_player_damageable_by_contact() and game._distance_to_segment(game.player_pos, origin, end) <= PRISM_WIDTH:
					game._damage_player(damage, "olhar_prismatico")
					break
				game._damage_remote_player_on_segment(origin, end, PRISM_WIDTH, damage, "olhar_prismatico")
	if age >= PRISM_TELEGRAPH + PRISM_DURATION:
		ability.clear()


func _start_hush(phase2: bool) -> void:
	var safes: Array = []
	var count := 2 if phase2 else 3
	var base: float = game.rng.randf_range(0.0, TAU)
	for i in range(count):
		var ang: float = base + float(i) * TAU / float(count) + game.rng.randf_range(-0.3, 0.3)
		var dist: float = game.rng.randf_range(200.0, 320.0)
		safes.append((game.player_pos + Vector2.from_angle(ang) * dist).clamp(Vector2(100, 100), game.WORLD_SIZE - Vector2(100, 100)))
	ability = {"kind": "hush", "age": 0.0, "safes": safes, "fired": false}
	_cds["hush"] = HUSH_COOLDOWN_PHASE2 if phase2 else HUSH_COOLDOWN
	game._add_text("SILENCIO TOTAL - ENTRE NUM CIRCULO!", game.player_pos + Vector2(-190, -130), Color(0.78, 0.92, 1.0), 1.6, 22)


func _update_hush() -> void:
	var age: float = float(ability["age"])
	if age >= HUSH_TELEGRAPH and not bool(ability["fired"]):
		ability["fired"] = true
		var damage := int((game.player_hp_max * 0.06 + game.enemy_far_damage * 0.3) * game.ARAUTO_DAMAGE_MULT)
		var safe := false
		for p_value in ability["safes"]:
			if game.player_pos.distance_to(Vector2(p_value)) <= HUSH_SAFE_RADIUS:
				safe = true
		if not safe and game._local_player_damageable_by_contact():
			game.player_silence_timer = maxf(float(game.player_silence_timer), HUSH_SILENCE)
			game._damage_player(damage, "silencio_total")
			game._add_text("SILENCIADO!", game.player_pos + Vector2(-50, -88), Color(0.72, 0.92, 1.0), 0.9, 21)
		game.screen_shake_timer = maxf(float(game.screen_shake_timer), 0.2)
		game.screen_shake_strength = maxf(float(game.screen_shake_strength), 6.0)
	if age >= HUSH_TELEGRAPH + 0.5:
		ability.clear()


func _start_inversion() -> void:
	inversion = {"pos": game.player_pos, "age": 0.0, "pulled": false, "pull_age": 0.0}
	_cds["inversion"] = INVERSION_COOLDOWN
	game._add_text("INVERSAO DE ECO", game.player_pos + Vector2(-80, -110), Color(0.86, 0.6, 1.0), 1.0, 19)


func _update_inversion(delta: float, _phase2: bool) -> void:
	if inversion.is_empty():
		return
	inversion["age"] = float(inversion["age"]) + delta
	var age: float = float(inversion["age"])
	if age >= INVERSION_DELAY and not bool(inversion["pulled"]):
		inversion["pulled"] = true
		var offset: Vector2 = Vector2(inversion["pos"]) - game.player_pos
		if offset.length() > 6.0:
			game._shove_player(offset)
		game._add_text("PUXADO DE VOLTA!", Vector2(inversion["pos"]) + Vector2(-80, -90), Color(0.86, 0.6, 1.0), 0.8, 18)
	if bool(inversion["pulled"]):
		inversion["pull_age"] = float(inversion["pull_age"]) + delta
		if float(inversion["pull_age"]) >= INVERSION_DETONATE:
			var center: Vector2 = inversion["pos"]
			var damage := int((game.player_hp_max * 0.055 + game.enemy_far_damage * 0.3) * game.ARAUTO_DAMAGE_MULT)
			if game.player_pos.distance_to(center) <= INVERSION_RADIUS and game._local_player_damageable_by_contact():
				game._damage_player(damage, "inversao_eco")
			game._damage_remote_player_in_radius(center, INVERSION_RADIUS, damage, "inversao_eco")
			game.shockwaves.append({"pos": center, "radius": 10.0, "max": INVERSION_RADIUS + 60.0, "life": 0.36, "damage": 0.0, "hit": {}, "visual_only": true, "color": Color(0.86, 0.5, 1.0)})
			inversion.clear()


# ============================== AGUILHAO ======================================

func _update_aguilhao(delta: float, phase2: bool) -> bool:
	# Veneno so sai quando um nodulo e destruido.
	var nodules: int = game._count_aguilhao_nodules()
	if _last_nodules >= 0 and nodules < _last_nodules and not venom_stacks.is_empty():
		venom_stacks.clear()
		game._add_text("VENENO PURGADO!", game.player_pos + Vector2(-80, -100), Color(0.7, 1.0, 0.4), 1.0, 19)
	_last_nodules = nodules
	if not ability.is_empty():
		ability["age"] = float(ability.get("age", 0.0)) + delta
		if String(ability["kind"]) == "shell" and float(ability["age"]) >= SHELL_TELEGRAPH + SHELL_DURATION:
			ability.clear()
			_cds["shell"] = SHELL_COOLDOWN_PHASE2 if phase2 else SHELL_COOLDOWN
			game._add_text("CASCA ABERTA!", Vector2(game.arauto["pos"]) + Vector2(-70, -110), Color(0.7, 1.0, 0.3), 0.9, 19)
			return false
		# Na casca ele fica parado (o ataque por tras e a resposta).
		return true
	if String(game.arauto.get("state", "idle")) != "idle":
		return false
	if _cd("shell") <= 0.0:
		ability = {"kind": "shell", "age": 0.0}
		_cds["shell"] = 99.0
		game._add_text("CASCA ENDURECIDA - ATAQUE POR TRAS!", Vector2(game.arauto["pos"]) + Vector2(-190, -120), Color(0.78, 1.0, 0.4), 1.4, 20)
		return true
	if _cd("sting") <= 0.0:
		_fire_sting(phase2)
		_cds["sting"] = STING_COOLDOWN_PHASE2 if phase2 else STING_COOLDOWN
	return false


func _fire_sting(phase2: bool) -> void:
	var origin: Vector2 = Vector2(game.arauto["pos"]) + Vector2(0, -20)
	# Mira a frente do jogador (ele corre para dentro do ferrao se nao mudar de rumo).
	var travel: float = origin.distance_to(game.player_pos) / STING_SPEED + 0.35
	var aim: Vector2 = game.player_pos + _player_vel * travel * 0.85
	var dir: Vector2 = (aim - origin).normalized()
	if dir.length() <= 0.05:
		dir = Vector2.RIGHT
	var spreads: Array = [0.0, -0.16, 0.16] if phase2 else [0.0]
	for spread in spreads:
		stings.append({"pos": origin, "dir": dir.rotated(float(spread)), "life": 2.2, "telegraph": 0.35})
	game._play_sfx("boss_impact", 0.012, 0.5, 1.6)


func _update_stings(delta: float) -> void:
	if stings.is_empty():
		return
	for sting_value in stings:
		var sting: Dictionary = sting_value
		var tele: float = float(sting.get("telegraph", 0.0))
		if tele > 0.0:
			sting["telegraph"] = tele - delta
			continue
		sting["life"] = float(sting["life"]) - delta
		var before: Vector2 = sting["pos"]
		var after: Vector2 = before + Vector2(sting["dir"]) * STING_SPEED * delta
		sting["pos"] = after
		if game._local_player_damageable_by_contact() and game._distance_to_segment(game.player_pos, before, after) <= STING_RADIUS:
			sting["life"] = 0.0
			_add_venom()
	stings = stings.filter(func(s): return float(Dictionary(s)["life"]) > 0.0)


func _add_venom() -> void:
	if venom_stacks.size() < VENOM_MAX:
		venom_stacks.append(VENOM_STACK_LIFE)
	else:
		for i in range(venom_stacks.size()):
			venom_stacks[i] = VENOM_STACK_LIFE
	game._damage_player(int(game.player_hp_max * 0.03), "ferrao_venenoso")
	game._add_text("VENENO x%d" % venom_stacks.size(), game.player_pos + Vector2(-46, -96), Color(0.6, 1.0, 0.24), 0.8, 19)


func _update_venom(delta: float) -> void:
	if venom_stacks.is_empty():
		return
	# Com nodulos vivos o veneno nao expira (so destruindo um); sem nodulos, vai sumindo.
	var nodules_alive: bool = game._arauto_active() and game._arauto_is_aguilhao() and game._count_aguilhao_nodules() > 0
	if not nodules_alive:
		for i in range(venom_stacks.size()):
			venom_stacks[i] = float(venom_stacks[i]) - delta
		venom_stacks = venom_stacks.filter(func(v): return float(v) > 0.0)
	venom_tick -= delta
	if venom_tick <= 0.0 and not venom_stacks.is_empty():
		venom_tick = 0.5
		var dmg: int = maxi(1, int(game.player_hp_max * VENOM_DPS_RATIO * 0.5 * float(venom_stacks.size())))
		if game.player_hp > 1:
			game._damage_player(mini(dmg, int(game.player_hp) - 1), "veneno_aguilhao", true)


## Multiplicador de dano no Aguilhao com a casca: frente quase imune, costas inteiras.
func shell_damage_multiplier(attack_origin: Vector2) -> float:
	if not shell_active():
		return 1.0
	var pos: Vector2 = Vector2(game.arauto.get("pos", game.player_pos))
	var origin: Vector2 = attack_origin if attack_origin != Vector2.ZERO else game.player_pos
	var facing: float = float(game.arauto.get("facing", 1.0))
	var from_behind: bool = (origin.x - pos.x) * facing < 0.0
	if from_behind:
		return 1.0
	if shell_spike_cd <= 0.0:
		shell_spike_cd = SHELL_SPIKE_CD
		var dir: Vector2 = (origin - pos).normalized()
		spikes.append({"pos": pos + dir * 50.0, "dir": dir, "life": 1.6})
	return SHELL_FRONT_MULT


func _update_spikes(delta: float) -> void:
	shell_spike_cd = maxf(0.0, shell_spike_cd - delta)
	if spikes.is_empty():
		return
	for spike_value in spikes:
		var spike: Dictionary = spike_value
		spike["life"] = float(spike["life"]) - delta
		var before: Vector2 = spike["pos"]
		var after: Vector2 = before + Vector2(spike["dir"]) * 620.0 * delta
		spike["pos"] = after
		if game._local_player_damageable_by_contact() and game._distance_to_segment(game.player_pos, before, after) <= 18.0:
			spike["life"] = 0.0
			game._damage_player(int(game.player_hp_max * 0.035 + game.enemy_far_damage * 0.2), "casca_reflexo")
	spikes = spikes.filter(func(s): return float(Dictionary(s)["life"]) > 0.0)


## Investida Ricochete (fase 2): devolve a nova direcao ao bater numa borda, ou ZERO.
func ricochet_direction(current_dir: Vector2, hit_pos: Vector2) -> Vector2:
	var left: int = int(game.arauto.get("ricochet_left", 0))
	if left <= 0:
		return Vector2.ZERO
	game.arauto["ricochet_left"] = left - 1
	# No mapa grande a borda quase nunca e alcancada: o quique vale no fim de cada
	# perna; so reflete de verdade quando bateu numa borda.
	var margin := Vector2(60.0, 70.0)
	var normal := Vector2.ZERO
	if hit_pos.x <= margin.x:
		normal.x = 1.0
	elif hit_pos.x >= game.WORLD_SIZE.x - margin.x:
		normal.x = -1.0
	if hit_pos.y <= margin.y:
		normal.y = 1.0
	elif hit_pos.y >= game.WORLD_SIZE.y - margin.y:
		normal.y = -1.0
	var reflected: Vector2 = current_dir.bounce(normal.normalized()) if normal != Vector2.ZERO else current_dir.rotated(PI * 0.6 * (1.0 if game.rng.randf() < 0.5 else -1.0))
	var to_player: Vector2 = (game.player_pos - hit_pos).normalized()
	return reflected.lerp(to_player, RICOCHET_AIM).normalized()
