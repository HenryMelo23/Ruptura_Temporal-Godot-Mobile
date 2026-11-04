class_name RTBoss6Controller
extends RefCounted

## Matriarca da Chaga: locomocao (rastejar por passos) e Mergulho na Chaga
## (afunda, monte de lama persegue, aviso, irrompe). Estado em game.boss6_ai_state.

const MODE_IDLE := "idle"
const MODE_CRAWL := "crawl"
const MODE_SUBMERGE := "submerge"
const MODE_TRAVEL := "travel"
const MODE_WARN := "warn"
const MODE_EMERGE := "emerge"

const CRAWL_SPEED := {1: 46.0, 2: 72.0, 3: 104.0}
const CRAWL_CYCLE := 0.9
const DESIRED_DISTANCE := 250.0
const DISTANCE_SLACK := 70.0

const BURROW_COOLDOWN := {1: 9.0, 2: 7.0, 3: 5.5}
const BURROW_FAR_DISTANCE := 520.0
const SUBMERGE_TIME := 0.6
const TRAVEL_SPEED := {1: 270.0, 2: 310.0, 3: 350.0}
const TRAVEL_MAX_TIME := 2.2
const WARN_TIME := 0.55
const EMERGE_TIME := 0.55
const EMERGE_RADIUS := 130.0
const EMERGE_OFFSET := 30.0

# Foices Vertebrais: ondas em meia-lua que correm em cone, alternando o lado da varrida.
const SCYTHE_WAVES := {1: 2, 2: 3, 3: 3}
const SCYTHE_GAP := {1: 0.5, 2: 0.45, 3: 0.36}
const SCYTHE_SPEED := {1: 660.0, 2: 720.0, 3: 800.0}
const SCYTHE_ARC_SOLO := deg_to_rad(120.0)
const SCYTHE_ARC_TEAM := deg_to_rad(80.0)
const SCYTHE_START_RADIUS := 60.0
const SCYTHE_MAX_RADIUS := 560.0
const SCYTHE_BAND := 26.0

# Cuspe Florado: bolas de acido em arco que caem em leque nas posicoes previstas.
const SPIT_COUNT := {1: 3, 2: 3, 3: 5}
const SPIT_STAGGER := 0.12
const SPIT_FLIGHT := 0.85
const SPIT_SPREAD := 150.0
const SPIT_SPLASH_RADIUS := 90.0
const SPIT_POOL_RADIUS := 110.0
const SPIT_POOL_TIME := 8.0
const SPIT_MOUTH := Vector2(-30.0, -150.0)

# Cauda Condutiva: varre 220 graus pelas costas e lados; a frente fica livre.
const TAIL_REACH := 260.0
const TAIL_ARC := deg_to_rad(220.0)
const TAIL_SWEEP_TIME := 0.42
const TAIL_TRIGGER_DISTANCE := 330.0

var game: Node


func configure(p_game: Node) -> void:
	game = p_game


func reset() -> void:
	if game == null:
		return
	game.boss6_ai_state = {
		"mode": MODE_IDLE,
		"t": 0.0,
		"facing": -1.0,
		"step": 0.0,
		"moving": false,
		"burrow_cd": float(BURROW_COOLDOWN[1]),
		"mound": Vector2.ZERO,
		"emerge_at": Vector2.ZERO,
		"emerge_hit": false,
	}


func _ai() -> Dictionary:
	if game.boss6_ai_state.is_empty():
		reset()
	return game.boss6_ai_state


func mode() -> String:
	return String(_ai().get("mode", MODE_IDLE))


func is_burrowed() -> bool:
	return mode() in [MODE_TRAVEL, MODE_WARN]


func is_burrow_busy() -> bool:
	return mode() in [MODE_SUBMERGE, MODE_TRAVEL, MODE_WARN, MODE_EMERGE]


func facing() -> float:
	return float(_ai().get("facing", -1.0))


## Progresso do afundar/emergir para a apresentacao (0 = de pe, 1 = todo enterrado).
func sink_ratio() -> float:
	var ai := _ai()
	var t: float = float(ai.get("t", 0.0))
	match mode():
		MODE_SUBMERGE:
			return clampf(t / SUBMERGE_TIME, 0.0, 1.0)
		MODE_TRAVEL, MODE_WARN:
			return 1.0
		MODE_EMERGE:
			return 1.0 - clampf(t / (EMERGE_TIME * 0.45), 0.0, 1.0)
	return 0.0


func _stage() -> int:
	return clampi(int(game.boss6_stage), 1, 3)


## Retorna true quando o mergulho ocupa o turno (a FSM de habilidades espera).
func update(delta: float) -> bool:
	if game == null or game.current_phase != 6 or not game.boss_active or game.boss_dead:
		return false
	if not game._is_world_authority():
		return false
	var ai := _ai()
	ai["t"] = float(ai.get("t", 0.0)) + delta
	ai["burrow_cd"] = maxf(0.0, float(ai.get("burrow_cd", 0.0)) - delta)
	match mode():
		MODE_SUBMERGE:
			if float(ai["t"]) >= SUBMERGE_TIME:
				ai["mound"] = game.boss_pos
				_set_mode(MODE_TRAVEL)
			return true
		MODE_TRAVEL:
			_update_travel(delta)
			return true
		MODE_WARN:
			if float(ai["t"]) >= WARN_TIME:
				game.boss_pos = Vector2(ai.get("emerge_at", game.boss_pos))
				ai["emerge_hit"] = false
				_set_mode(MODE_EMERGE)
			return true
		MODE_EMERGE:
			if not bool(ai.get("emerge_hit", false)):
				ai["emerge_hit"] = true
				_emerge_hit()
			if float(ai["t"]) >= EMERGE_TIME:
				ai["burrow_cd"] = float(BURROW_COOLDOWN[_stage()])
				_set_mode(MODE_IDLE)
			return true
	return false


## Locomocao entre habilidades: so roda quando a FSM esta ociosa/recuperando.
func update_locomotion(delta: float) -> void:
	if game == null or is_burrow_busy():
		return
	var ai := _ai()
	var target: Vector2 = game._boss_target_pos(false, 0.12)
	var offset: Vector2 = target - game.boss_pos
	var distance: float = offset.length()
	if absf(offset.x) > 12.0:
		ai["facing"] = signf(offset.x)
	if float(ai.get("burrow_cd", 0.0)) <= 0.0 and (distance >= BURROW_FAR_DISTANCE or game.rng.randf() < delta * 0.25):
		start_burrow()
		return
	var moving: bool = distance > DESIRED_DISTANCE + DISTANCE_SLACK or distance < DESIRED_DISTANCE - DISTANCE_SLACK * 1.6
	ai["moving"] = moving
	if not moving:
		_set_mode_soft(MODE_IDLE)
		return
	_set_mode_soft(MODE_CRAWL)
	ai["step"] = fposmod(float(ai.get("step", 0.0)) + delta / CRAWL_CYCLE, 1.0)
	# Passo: avanca quando as patas pousam (duas batidas por ciclo), nunca desliza constante.
	var gait: float = 0.25 + 0.75 * absf(sin(float(ai["step"]) * TAU))
	var direction: Vector2 = offset.normalized() if distance > DESIRED_DISTANCE else -offset.normalized()
	var speed: float = float(CRAWL_SPEED[_stage()]) * gait
	game.boss_pos = game.boss6_stage_controller.clamp_to_arena(game.boss_pos + direction * speed * delta, Vector2(150.0, 130.0))


func stop_locomotion() -> void:
	if game == null or is_burrow_busy():
		return
	_ai()["moving"] = false
	_set_mode_soft(MODE_IDLE)


func start_burrow() -> void:
	var ai := _ai()
	ai["burrow_cd"] = float(BURROW_COOLDOWN[_stage()])
	ai["moving"] = false
	_set_mode(MODE_SUBMERGE)
	game._spawn_radial_particles(game.boss_pos + Vector2(0.0, 20.0), Color(0.42, 0.34, 0.16), 22)


func cancel_burrow() -> void:
	if game == null or not is_burrow_busy():
		return
	var ai := _ai()
	if mode() in [MODE_TRAVEL, MODE_WARN]:
		game.boss_pos = Vector2(ai.get("mound", game.boss_pos))
	_set_mode(MODE_IDLE)


func _update_travel(delta: float) -> void:
	var ai := _ai()
	var mound: Vector2 = Vector2(ai.get("mound", game.boss_pos))
	var target: Vector2 = game._boss_target_pos(false, 0.25)
	var to_target: Vector2 = target - mound
	var step: float = float(TRAVEL_SPEED[_stage()]) * delta
	if to_target.length() <= EMERGE_OFFSET + step or float(ai["t"]) >= TRAVEL_MAX_TIME:
		var emerge: Vector2 = target
		if to_target.length() > 1.0:
			emerge = target - to_target.normalized() * EMERGE_OFFSET
		emerge = game.boss6_stage_controller.clamp_to_arena(emerge, Vector2(150.0, 130.0))
		ai["emerge_at"] = emerge
		ai["mound"] = emerge
		if absf(target.x - emerge.x) > 8.0:
			ai["facing"] = signf(target.x - emerge.x)
		_set_mode(MODE_WARN)
		return
	ai["last_trail"] = mound - to_target.normalized() * 90.0
	mound = game.boss6_stage_controller.clamp_to_arena(mound + to_target.normalized() * step, Vector2(150.0, 130.0))
	ai["mound"] = mound
	# O corpo acompanha o monte (barra, alvo e camera seguem algo coerente).
	game.boss_pos = mound
	if absf(to_target.x) > 8.0:
		ai["facing"] = signf(to_target.x)


func _emerge_hit() -> void:
	var center: Vector2 = game.boss_pos
	for target_value in game._combat_targets():
		var target: Dictionary = Dictionary(target_value)
		var peer_id := int(target.get("peer_id", game._mp_unique_id()))
		var position := Vector2(target.get("pos", game.player_pos))
		if position.distance_to(center) > EMERGE_RADIUS:
			continue
		var is_local: bool = bool(target.get("local", peer_id == game._mp_unique_id()))
		var damage: int = int(float(game.player_hp_max) * 0.09 + 34.0) if is_local else 40
		if is_local:
			if float(game.time_alive) - float(game.last_dash_time) <= 0.2:
				continue
			game._damage_player(damage, "boss6_emerge")
			var push: Vector2 = (position - center).normalized()
			if push.length() < 0.1:
				push = Vector2.LEFT
			game.player_pos = game._clamp_player_world(game.player_pos + game._hostile_knockback(push * 150.0))
		else:
			game._send_peer_damage(peer_id, damage, "boss6_emerge")
	game.shockwaves.append({"pos": center, "radius": 24.0, "max": EMERGE_RADIUS + 60.0, "life": 0.45, "damage": 0.0, "hit": {}, "visual_only": true, "color": Color(0.62, 1.0, 0.2)})
	game.screen_shake_timer = maxf(float(game.screen_shake_timer), 0.28)
	game.screen_shake_strength = maxf(float(game.screen_shake_strength), 10.0)
	game._spawn_radial_particles(center, Color(0.56, 0.9, 0.18), 30)
	game._vibrate(170, 0.6)


## Monta as ondas: por alvo (ate 3), alternando o lado; cada onda re-mira no disparo.
func build_scythe_waves() -> Array:
	var stage := _stage()
	var targets: Array = game.boss6_stage_controller.next_team_targets()
	if targets.is_empty():
		targets.append({"peer_id": 0, "pos": game._boss_target_pos(true, 0.18), "local": true})
	var arc: float = SCYTHE_ARC_SOLO if targets.size() <= 1 else SCYTHE_ARC_TEAM
	var waves: Array = []
	var count: int = int(SCYTHE_WAVES[stage])
	if targets.size() > 1:
		count = 2
	for target_index in range(targets.size()):
		var target := Dictionary(targets[target_index])
		for wave_index in range(count):
			waves.append({
				"start": float(wave_index) * float(SCYTHE_GAP[stage]) + float(target_index) * 0.08,
				"side": -1.0 if wave_index % 2 == 0 else 1.0,
				"arc": arc,
				"angle": (Vector2(target.get("pos", game.player_pos)) - game.boss_pos).angle(),
				"aimed": false,
				"target_peer": int(target.get("peer_id", 0)),
				"target_index": target_index,
				"hit": {},
			})
	return waves


static func scythe_duration(waves: Array, stage: int) -> float:
	var last: float = 0.0
	for wave in waves:
		last = maxf(last, float(Dictionary(wave).get("start", 0.0)))
	return last + (SCYTHE_MAX_RADIUS - SCYTHE_START_RADIUS) / float(SCYTHE_SPEED[clampi(stage, 1, 3)]) + 0.12


static func scythe_wave_radius(wave: Dictionary, age: float, stage: int) -> float:
	var local: float = age - float(wave.get("start", 0.0))
	if local < 0.0:
		return -1.0
	return SCYTHE_START_RADIUS + local * float(SCYTHE_SPEED[clampi(stage, 1, 3)])


## Chamado por _update_boss_attacks para o golpe das foices (dano e re-mira).
func update_scythes(attack: Dictionary, age: float) -> void:
	var origin := Vector2(attack.get("origin", game.boss_pos))
	var stage: int = int(attack.get("stage", _stage()))
	var waves: Array = Array(attack.get("waves", []))
	for wave_index in range(waves.size()):
		var wave: Dictionary = waves[wave_index]
		var radius: float = scythe_wave_radius(wave, age, stage)
		if radius < 0.0 or radius > SCYTHE_MAX_RADIUS:
			continue
		if not bool(wave.get("aimed", false)):
			wave["aimed"] = true
			wave["angle"] = _scythe_aim(origin, int(wave.get("target_peer", 0)), float(wave.get("angle", 0.0)))
			if absf(cos(float(wave["angle"]))) > 0.2:
				_ai()["facing"] = signf(cos(float(wave["angle"])))
			game.screen_shake_timer = maxf(float(game.screen_shake_timer), 0.12)
			game.screen_shake_strength = maxf(float(game.screen_shake_strength), 5.0)
		var hit: Dictionary = Dictionary(wave.get("hit", {}))
		for target_value in game._combat_targets():
			var target: Dictionary = Dictionary(target_value)
			var peer_id := int(target.get("peer_id", game._mp_unique_id()))
			var key := str(peer_id)
			if hit.has(key):
				continue
			var position := Vector2(target.get("pos", game.player_pos))
			var offset: Vector2 = position - origin
			if absf(offset.length() - radius) > SCYTHE_BAND + 12.0:
				continue
			if absf(angle_difference(float(wave["angle"]), offset.angle())) > float(wave.get("arc", SCYTHE_ARC_SOLO)) * 0.5:
				continue
			hit[key] = true
			var is_local: bool = bool(target.get("local", peer_id == game._mp_unique_id()))
			if is_local:
				if float(game.time_alive) - float(game.last_dash_time) <= 0.2 or not game._local_player_damageable_by_contact():
					continue
				game._damage_player(int(float(game.player_hp_max) * 0.065 + float(game.enemy_far_damage) * 0.55 + 20.0), "boss6_vertebral_scythe")
				game.player_pos = game._clamp_player_world(game.player_pos + game._hostile_knockback(offset.normalized() * 110.0))
			else:
				game._send_peer_damage(peer_id, int(float(game.net_player_hp_max) * 0.065 + 20.0), "boss6_vertebral_scythe")
		wave["hit"] = hit
		waves[wave_index] = wave
	attack["waves"] = waves


func _scythe_aim(origin: Vector2, peer_id: int, fallback: float) -> float:
	for target_value in game._combat_targets():
		var target: Dictionary = Dictionary(target_value)
		if peer_id == 0 and bool(target.get("local", false)) or int(target.get("peer_id", -1)) == peer_id:
			return (Vector2(target.get("pos", game.player_pos)) - origin).angle()
	if peer_id == 0:
		return (game.player_pos - origin).angle()
	return fallback


func spit_mouth() -> Vector2:
	var offset := SPIT_MOUTH
	if facing() > 0.0:
		offset.x = -offset.x
	return game.boss_pos + offset


func build_spit_attack(scripted: bool) -> Dictionary:
	var targets: Array = game.boss6_stage_controller.next_team_targets()
	if targets.is_empty():
		targets.append({"peer_id": 0, "pos": game._boss_target_pos(true, 0.18), "local": true})
	var per_target: int = int(SPIT_COUNT[_stage()]) if targets.size() <= 1 else 2
	var spots: Array = []
	var launch: float = 0.0
	for target_index in range(targets.size()):
		var target := Dictionary(targets[target_index])
		var peer_id := int(target.get("peer_id", 0))
		var aim: Vector2 = Vector2(target.get("pos", game.player_pos))
		if bool(target.get("local", false)) or targets.size() <= 1:
			aim = game._boss_target_pos(false, 0.45)
		var forward: Vector2 = (aim - game.boss_pos).normalized()
		if forward.length() < 0.1:
			forward = Vector2.LEFT
		for index in range(per_target):
			var lateral: float = (float(index) - float(per_target - 1) * 0.5) * SPIT_SPREAD
			var depth: float = 0.0 if index == int(per_target / 2) else game.rng.randf_range(-50.0, 60.0)
			var land: Vector2 = game.boss6_stage_controller.clamp_to_arena(aim + forward.orthogonal() * lateral + forward * depth, Vector2(90.0, 90.0))
			spots.append({"pos": land, "launch": launch, "landed": false, "hit": {}, "target_peer": peer_id, "target_index": target_index})
			launch += SPIT_STAGGER
	if absf(spots[0]["pos"].x - game.boss_pos.x) > 10.0:
		_ai()["facing"] = signf(spots[0]["pos"].x - game.boss_pos.x)
	return {"kind": game.BOSS6_ABILITY_ACID_BLOOM, "age": 0.0, "duration": launch + SPIT_FLIGHT + 0.3, "origin": spit_mouth(), "spots": spots, "scripted": scripted, "team_target_count": game.boss6_stage_controller.attack_target_count(spots)}


static func spit_progress(spot: Dictionary, age: float) -> float:
	return clampf((age - float(spot.get("launch", 0.0))) / SPIT_FLIGHT, -1.0, 1.0)


func update_spit(attack: Dictionary, age: float) -> void:
	var spots: Array = Array(attack.get("spots", []))
	for index in range(spots.size()):
		var spot: Dictionary = spots[index]
		if bool(spot.get("landed", false)) or spit_progress(spot, age) < 1.0:
			continue
		spot["landed"] = true
		var center: Vector2 = Vector2(spot.get("pos", game.player_pos))
		game._add_boss6_acid_pool(center, SPIT_POOL_RADIUS, SPIT_POOL_TIME, "acid_bloom")
		game.shockwaves.append({"pos": center, "radius": 16.0, "max": SPIT_SPLASH_RADIUS + 30.0, "life": 0.4, "damage": 0.0, "hit": {}, "visual_only": true, "color": Color(0.5, 1.0, 0.16)})
		for target_value in game._combat_targets():
			var target: Dictionary = Dictionary(target_value)
			var peer_id := int(target.get("peer_id", game._mp_unique_id()))
			if Vector2(target.get("pos", game.player_pos)).distance_to(center) > SPIT_SPLASH_RADIUS:
				continue
			if bool(target.get("local", peer_id == game._mp_unique_id())):
				if float(game.time_alive) - float(game.last_dash_time) <= 0.2:
					continue
				game._damage_player(int(float(game.player_hp_max) * 0.055 + 18.0), "boss6_acid_spit")
			else:
				game._send_peer_damage(peer_id, int(float(game.net_player_hp_max) * 0.055 + 18.0), "boss6_acid_spit")
		spots[index] = spot
	attack["spots"] = spots


func tail_in_reach() -> bool:
	for target_value in game._combat_targets():
		if Vector2(Dictionary(target_value).get("pos", game.player_pos)).distance_to(game.boss_pos) <= TAIL_TRIGGER_DISTANCE:
			return true
	return false


## Costas = oposto de para onde ela olha; a varrida vai de uma ponta a outra do arco.
func build_tail_attack() -> Dictionary:
	var back: float = 0.0 if facing() < 0.0 else PI
	var side: float = -1.0 if game.rng.randf() < 0.5 else 1.0
	return {"kind": game.BOSS6_ABILITY_TAIL, "age": 0.0, "duration": TAIL_SWEEP_TIME + 0.35, "origin": game.boss_pos, "back": back, "side": side, "hit": {}}


static func tail_angle(attack: Dictionary, age: float) -> float:
	var u: float = clampf(age / TAIL_SWEEP_TIME, 0.0, 1.0)
	var eased: float = u * u * (3.0 - 2.0 * u)
	var side: float = float(attack.get("side", 1.0))
	var back: float = float(attack.get("back", 0.0))
	return back - side * TAIL_ARC * 0.5 + side * TAIL_ARC * eased


func update_tail(attack: Dictionary, age: float) -> void:
	if age > TAIL_SWEEP_TIME + 0.02:
		return
	var origin: Vector2 = Vector2(attack.get("origin", game.boss_pos))
	var back: float = float(attack.get("back", 0.0))
	var swept: float = absf(angle_difference(back - float(attack.get("side", 1.0)) * TAIL_ARC * 0.5, tail_angle(attack, age)))
	var hit: Dictionary = Dictionary(attack.get("hit", {}))
	for target_value in game._combat_targets():
		var target: Dictionary = Dictionary(target_value)
		var peer_id := int(target.get("peer_id", game._mp_unique_id()))
		var key := str(peer_id)
		if hit.has(key):
			continue
		var offset: Vector2 = Vector2(target.get("pos", game.player_pos)) - origin
		if offset.length() > TAIL_REACH or offset.length() < 20.0:
			continue
		var rel: float = absf(angle_difference(back, offset.angle()))
		if rel > TAIL_ARC * 0.5:
			continue
		var from_start: float = absf(angle_difference(back - float(attack.get("side", 1.0)) * TAIL_ARC * 0.5, offset.angle()))
		if from_start > swept + 0.05:
			continue
		hit[key] = true
		if bool(target.get("local", peer_id == game._mp_unique_id())):
			if float(game.time_alive) - float(game.last_dash_time) <= 0.2:
				continue
			game._damage_player(int(float(game.player_hp_max) * 0.08 + 28.0), "boss6_conductive_tail")
			game.player_pos = game._clamp_player_world(game.player_pos + game._hostile_knockback(offset.normalized() * 190.0))
		else:
			game._send_peer_damage(peer_id, int(float(game.net_player_hp_max) * 0.08 + 28.0), "boss6_conductive_tail")
	attack["hit"] = hit


func _set_mode(next: String) -> void:
	var ai := _ai()
	ai["mode"] = next
	ai["t"] = 0.0


func _set_mode_soft(next: String) -> void:
	if mode() != next:
		_ai()["mode"] = next
