class_name RTSertaoController
extends RefCounted

## Dimensao 8 — Sertao das Tartarugas.
## Dono dos inimigos da fase (Jabuti Errante, Tartaruga-Mandacaru, Jabuti-Morteiro,
## Cagado-Piao), do mini chefe Cagado Cangaceiro e do motor de projeteis "bullet hell"
## que o chefe (RTBoss8Controller) tambem usa.
##
## Regras do motor de projeteis:
## - hitbox pequena (o jogador e um ponto de ~9 px), para os padroes densos serem justos;
## - depois de levar um tiro, os outros projeteis do Sertao atravessam por HIT_LOCK
##   segundos (nao existe "tomar 6 tiros no mesmo quadro");
## - "tempo de tartaruga": projeteis podem nascer parados (delay), desacelerar,
##   congelar e mirar de novo.

const PHASE := 8
const JABUTI := "jabuti_errante"
const MANDACARU := "tartaruga_mandacaru"
const MORTEIRO := "jabuti_morteiro"
const PIAO := "cagado_piao"
const CANGACEIRO := "cagado_cangaceiro"
const EGG := "ovo_jabuti"
const KINDS := [JABUTI, MANDACARU, MORTEIRO, PIAO, CANGACEIRO, EGG]
const EGG_HATCH := 3.0
const SPECIALS := [MANDACARU, MORTEIRO, PIAO]

# ---------------------------------------------------------------- projeteis
const MAX_BULLETS := 460
const VISUAL_BULLET_STRIDE := 11
const PLAYER_HIT_RADIUS := 9.0
const HIT_LOCK := 0.5
const GRAZE_RADIUS := 30.0
const COL_SUN := 0
const COL_THORN := 1
const COL_SAND := 2
const COL_GOLD := 3
const COL_FROZEN := 4
const COL_ECLIPSE := 5
const COL_EGG := 6
const PALETTE := [
	Color(1.0, 0.86, 0.3),
	Color(0.6, 1.0, 0.26),
	Color(1.0, 0.92, 0.7),
	Color(1.0, 0.84, 0.26),
	Color(0.42, 0.96, 1.0),
	Color(0.9, 0.68, 1.0),
	Color(1.0, 0.44, 0.16),
]

# ---------------------------------------------------------------- populacao
const ENEMY_LIMIT_BASE := 9
const SPAWN_INTERVAL := 1.08
const SPECIAL_CAP := 2

# ---------------------------------------------------------------- Jabuti Errante (comum)
const JABUTI_SPIN_RANGE := 300.0
const JABUTI_WINDUP := 0.55
const JABUTI_SPIN_TIME := 0.62
const JABUTI_SPIN_SPEED := 430.0
const JABUTI_DIZZY := 0.75
const JABUTI_COOLDOWN := 3.6

# ---------------------------------------------------------------- Tartaruga-Mandacaru
const MANDACARU_ROOT_TIME := 0.6
const MANDACARU_FIRE_TIME := 4.2
const MANDACARU_EMIT := 0.13
const MANDACARU_TURN := 0.36
const MANDACARU_COOLDOWN := 4.8

# ---------------------------------------------------------------- Jabuti-Morteiro
const MORTEIRO_AIM := 0.75
const MORTEIRO_COOLDOWN := 4.6
const MORTEIRO_EGGS := 3
const MORTEIRO_FLIGHT := 1.05
const MORTEIRO_BLAST := 58.0

# ---------------------------------------------------------------- Cagado-Piao
const PIAO_SPINUP := 0.5
const PIAO_SPEED := 600.0
const PIAO_MAX_TIME := 2.0
const PIAO_BOUNCES := 3
const PIAO_TRAIL_STEP := 64.0
const PIAO_DIZZY := 1.0
const PIAO_COOLDOWN := 5.0
const PIAO_BOX := Vector2(960.0, 600.0)

# ---------------------------------------------------------------- Cagado Cangaceiro (mini chefe)
const CANGACEIRO_SPAWN_TIME := 150.0
const CANGACEIRO_HP_MULT := 24.0
const CANGACEIRO_SPEED := 88.0
const CANGACEIRO_ENTRY := 1.1
const CANGACEIRO_GAP := 1.35
const CANGACEIRO_REWARD_POINTS := 900
const CANGACEIRO_ATTACKS := ["rajada", "xaxado", "casco", "tocaia"]

var core: Node
var bullets: Array = []
var hazards: Array = []
var hit_lock: float = 0.0
var hit_lock_by_peer: Dictionary = {}
var graze_count: int = 0
var grazes_this_phase: int = 0
var miniboss_spawned: bool = false
var miniboss_defeated: bool = false
var _last_player_pos := Vector2.ZERO
var player_velocity := Vector2.ZERO
var _graze_text_cd: float = 0.0
var _remote_enemy_visual_by_uid: Dictionary = {}


func configure(p_core: Node) -> void:
	core = p_core


func reset() -> void:
	bullets.clear()
	hazards.clear()
	hit_lock = 0.0
	hit_lock_by_peer.clear()
	graze_count = 0
	grazes_this_phase = 0
	miniboss_spawned = false
	miniboss_defeated = false
	player_velocity = Vector2.ZERO
	if core != null:
		_last_player_pos = core.player_pos


func owns_kind(kind: String) -> bool:
	return kind in KINDS


func active() -> bool:
	return core != null and int(core.current_phase) == PHASE


# ================================================================ projeteis
func enemy_bullet_damage(mult: float = 1.0) -> int:
	return maxi(1, int(round((float(core.player_hp_max) * 0.045 + float(core.enemy_far_damage) * 0.35) * mult)))


func boss_bullet_damage(mult: float = 1.0) -> int:
	return maxi(1, int(round((float(core.player_hp_max) * 0.06 + float(core.enemy_far_damage) * 0.55) * mult)))


## Cria um projetil. opts: acc, smin, smax, w (curva rad/s), delay (parado antes de
## andar), aim (mira no jogador quando o delay acaba), life, r (hitbox), dmg, src,
## size, freeze_col (cor enquanto parado), wave (amplitude de zigue-zague).
func shoot(pos: Vector2, dir: Vector2, speed: float, color: int, opts: Dictionary = {}) -> Dictionary:
	if bullets.size() >= MAX_BULLETS:
		return {}
	var d := dir.normalized()
	if d.length() < 0.01:
		d = Vector2.RIGHT
	var b := {
		"p": pos,
		"v": d,
		"s": speed,
		"acc": float(opts.get("acc", 0.0)),
		"smin": float(opts.get("smin", 0.0)),
		"smax": float(opts.get("smax", 900.0)),
		"w": float(opts.get("w", 0.0)),
		"delay": float(opts.get("delay", 0.0)),
		"aim": bool(opts.get("aim", false)),
		"aim_speed": float(opts.get("aim_speed", speed)),
		"aim_acc": float(opts.get("aim_acc", 0.0)),
		"life": float(opts.get("life", 6.0)),
		"r": float(opts.get("r", 8.0)),
		"dmg": int(opts.get("dmg", enemy_bullet_damage())),
		"src": String(opts.get("src", "sertao")),
		"size": float(opts.get("size", 1.0)),
		"c": color,
		"fc": int(opts.get("freeze_col", color)),
		"t": 0.0,
		"grazed": false,
		"grazed_by": {},
		"owner": int(opts.get("owner", 0)),
	}
	bullets.append(b)
	return b


func ring(pos: Vector2, count: int, speed: float, offset: float, color: int, opts: Dictionary = {}, gap_angle: float = INF, gap_width: int = 0) -> void:
	var n := maxi(1, count)
	for i in range(n):
		var a := offset + TAU * float(i) / float(n)
		if gap_width > 0 and gap_angle != INF:
			var diff := absf(wrapf(a - gap_angle, -PI, PI))
			if diff < (TAU / float(n)) * (float(gap_width) * 0.5):
				continue
		shoot(pos, Vector2.from_angle(a), speed, color, opts)


func fan(pos: Vector2, dir: Vector2, count: int, spread: float, speed: float, color: int, opts: Dictionary = {}) -> void:
	var n := maxi(1, count)
	var base := dir.angle()
	for i in range(n):
		var k := 0.0 if n == 1 else (float(i) / float(n - 1) - 0.5)
		shoot(pos, Vector2.from_angle(base + k * spread), speed, color, opts)


func clear_bullets(owner: int = 0, pop: bool = false) -> void:
	if owner == 0:
		if pop:
			for b in bullets:
				_pop_bullet(b)
		bullets.clear()
		return
	var kept: Array = []
	for b in bullets:
		if int(b.get("owner", 0)) == owner:
			if pop:
				_pop_bullet(b)
		else:
			kept.append(b)
	bullets = kept


func _pop_bullet(b: Dictionary) -> void:
	if core.rng.randf() < 0.35:
		core._spawn_radial_particles(Vector2(b["p"]), Color(PALETTE[int(b["c"])]), 2)


## Congela tudo que estiver no ar por `time` e depois solta com `mult` de velocidade.
func freeze_all(time: float, mult: float = 1.4) -> void:
	for b in bullets:
		if float(b.get("delay", 0.0)) <= 0.0:
			b["delay"] = time
			b["s"] = float(b["s"]) * mult
			b["fc"] = COL_FROZEN


func _update_bullets(delta: float) -> void:
	var world_mult: float = AuraSystem.world_multiplier(core.aura_state)
	var dt: float = delta * world_mult
	var targets: Array = core._combat_targets()
	var reach2 := 0.0
	var any_dead := false
	for b in bullets:
		b["t"] = float(b["t"]) + dt
		b["life"] = float(b["life"]) - dt
		var delay: float = float(b["delay"])
		if delay > 0.0:
			delay -= dt
			b["delay"] = delay
			if delay <= 0.0 and bool(b["aim"]):
				var to_player: Vector2 = _nearest_target_pos(Vector2(b["p"]), targets) - Vector2(b["p"])
				if to_player.length() > 1.0:
					b["v"] = to_player.normalized()
				b["s"] = float(b["aim_speed"])
				b["acc"] = float(b["aim_acc"])
				b["aim"] = false
				b["fc"] = int(b["c"])
		else:
			var s: float = clampf(float(b["s"]) + float(b["acc"]) * dt, float(b["smin"]), float(b["smax"]))
			b["s"] = s
			var w: float = float(b["w"])
			if w != 0.0:
				b["v"] = Vector2(b["v"]).rotated(w * dt)
			b["p"] = Vector2(b["p"]) + Vector2(b["v"]) * s * dt
		var p: Vector2 = b["p"]
		var r: float = float(b["r"]) + PLAYER_HIT_RADIUS
		var grazed_by: Dictionary = Dictionary(b.get("grazed_by", {}))
		for target_value in targets:
			var target: Dictionary = target_value
			var target_pos: Vector2 = Vector2(target.get("pos", p))
			var peer_id: int = int(target.get("peer_id", 0))
			var d2: float = p.distance_squared_to(target_pos)
			if d2 <= r * r:
				if _damage_target(target, int(b["dmg"]), String(b["src"])):
					core._spawn_radial_particles(p, Color(PALETTE[int(b["c"])]), 5)
				b["life"] = 0.0
				break
			if not grazed_by.has(peer_id):
				reach2 = (r + GRAZE_RADIUS) * (r + GRAZE_RADIUS)
				if d2 <= reach2:
					grazed_by[peer_id] = true
					if bool(target.get("local", false)):
						apply_graze(p)
					else:
						core._send_peer_phase8_graze(peer_id, p)
		b["grazed_by"] = grazed_by
		b["grazed"] = not grazed_by.is_empty()
		if float(b["life"]) <= 0.0:
			any_dead = true
			continue
		if p.x < -200.0 or p.y < -200.0 or p.x > core.WORLD_SIZE.x + 200.0 or p.y > core.WORLD_SIZE.y + 200.0:
			b["life"] = 0.0
			any_dead = true
	if any_dead:
		var kept: Array = []
		for b in bullets:
			if float(b["life"]) > 0.0:
				kept.append(b)
		bullets = kept


func apply_graze(pos: Vector2) -> void:
	graze_count += 1
	grazes_this_phase += 1
	core._gain_desvio_charge(pos)
	# Raspao: cada 12 raspoes vira um pouquinho de tempo de cura (dopamina do bullet hell).
	if graze_count % 12 == 0:
		core._heal_player(maxf(1.0, float(core.player_hp_max) * 0.02), "raspao", false)
		if _graze_text_cd <= 0.0:
			_graze_text_cd = 1.2
			core._add_text("RASPAO x%d" % graze_count, core.player_pos + Vector2(0, -96), Color(1.0, 0.92, 0.6), 0.8, 18)


# ================================================================ atualizacao geral
func update(delta: float) -> void:
	if not active():
		return
	var now: Vector2 = core.player_pos
	if delta > 0.0:
		player_velocity = player_velocity.lerp((now - _last_player_pos) / delta, clampf(delta * 10.0, 0.0, 1.0))
	_last_player_pos = now
	hit_lock = maxf(0.0, hit_lock - delta)
	for peer_key in hit_lock_by_peer.keys():
		var remaining: float = maxf(0.0, float(hit_lock_by_peer.get(peer_key, 0.0)) - delta)
		if remaining <= 0.0:
			hit_lock_by_peer.erase(peer_key)
		else:
			hit_lock_by_peer[peer_key] = remaining
	_graze_text_cd = maxf(0.0, _graze_text_cd - delta)
	_update_bullets(delta)
	_update_hazards(delta)
	_update_miniboss_schedule()


func predicted_player(time: float) -> Vector2:
	return predicted_target(time)


func predicted_target(time: float, enemy: Dictionary = {}) -> Vector2:
	if enemy.is_empty():
		return core._boss_target_pos(false, time)
	var target_pos: Vector2 = core._get_enemy_target_pos(enemy)
	var peer_id: int = int(enemy.get("target_peer_id", 0))
	if peer_id == core._mp_unique_id() or not core.is_multiplayer:
		return target_pos + player_velocity.limit_length(core.player_speed * 1.2) * time
	var state: Dictionary = core.net_players_by_peer.get(peer_id, {})
	return target_pos + Vector2(state.get("velocity", Vector2.ZERO)) * time


func _nearest_target_pos(origin: Vector2, targets: Array) -> Vector2:
	if targets.is_empty():
		return core.player_pos
	var best: Vector2 = Vector2(Dictionary(targets[0]).get("pos", core.player_pos))
	var best_d2: float = origin.distance_squared_to(best)
	for target_value in targets:
		var candidate: Vector2 = Vector2(Dictionary(target_value).get("pos", best))
		var d2: float = origin.distance_squared_to(candidate)
		if d2 < best_d2:
			best = candidate
			best_d2 = d2
	return best


func _damage_target(target: Dictionary, amount: int, source: String) -> bool:
	var peer_id: int = int(target.get("peer_id", 0))
	if peer_id <= 0 or float(hit_lock_by_peer.get(peer_id, 0.0)) > 0.0:
		return false
	if bool(target.get("local", false)):
		if core._player_invulnerable():
			return false
		core._damage_player(amount, source, false)
		hit_lock = HIT_LOCK
	else:
		core._send_peer_damage(peer_id, amount, source)
	hit_lock_by_peer[peer_id] = HIT_LOCK
	return true


# ================================================================ populacao
func enemy_limit() -> int:
	var elapsed: float = core._phase_elapsed_time()
	return ENEMY_LIMIT_BASE + (1 if elapsed > 240.0 else 0) + (1 if elapsed > 480.0 else 0)


func spawn_interval() -> float:
	return SPAWN_INTERVAL if core._phase_elapsed_time() > 60.0 else 1.28


func choose_enemy_type() -> String:
	var elapsed: float = core._phase_elapsed_time()
	var roll: float = core.rng.randf()
	if elapsed < 40.0:
		return JABUTI
	if elapsed < 100.0:
		if roll < 0.22 and core._enemy_type_count(MANDACARU) < 1:
			return MANDACARU
		return JABUTI
	if elapsed < 170.0:
		if roll < 0.18 and core._enemy_type_count(MORTEIRO) < SPECIAL_CAP:
			return MORTEIRO
		if roll < 0.34 and core._enemy_type_count(MANDACARU) < SPECIAL_CAP:
			return MANDACARU
		return JABUTI
	if roll < 0.16 and core._enemy_type_count(PIAO) < SPECIAL_CAP:
		return PIAO
	if roll < 0.32 and core._enemy_type_count(MORTEIRO) < SPECIAL_CAP:
		return MORTEIRO
	if roll < 0.48 and core._enemy_type_count(MANDACARU) < SPECIAL_CAP:
		return MANDACARU
	return JABUTI


## Atributos-base de cada bicho (o _spawn_enemy aplica em cima do hp/dano da fase).
func spawn_stats(kind: String, speed: float, damage: float) -> Dictionary:
	match kind:
		JABUTI:
			return {"hp_mult": 1.15, "speed": 70.0, "damage": damage * 0.8, "points": 80}
		MANDACARU:
			return {"hp_mult": 1.9, "speed": 46.0, "damage": damage * 0.7, "points": 150}
		MORTEIRO:
			return {"hp_mult": 1.6, "speed": 58.0, "damage": damage * 0.7, "points": 145}
		PIAO:
			return {"hp_mult": 1.3, "speed": 96.0, "damage": damage * 1.1, "points": 140}
		EGG:
			return {"hp_mult": 0.8, "speed": 0.0, "damage": 0.0, "points": 15}
		CANGACEIRO:
			return {"hp_mult": CANGACEIRO_HP_MULT, "speed": CANGACEIRO_SPEED, "damage": damage * 0.9, "points": CANGACEIRO_REWARD_POINTS}
	return {"hp_mult": 1.0, "speed": speed, "damage": damage, "points": 75}


func on_spawned(enemy: Dictionary) -> void:
	var kind := String(enemy.get("type", ""))
	enemy["shoot_cd"] = 999.0
	enemy["parado"] = true
	enemy["facing_dir"] = Vector2.LEFT
	enemy["s8_state"] = "walk"
	enemy["s8_t"] = 0.0
	enemy["s8_cd"] = core.rng.randf_range(1.2, 2.6)
	enemy["strafe"] = -1.0 if core.rng.randf() < 0.5 else 1.0
	if kind == EGG:
		enemy["contact_grace"] = 999.0
		enemy["s8_state"] = "egg"
	if kind == CANGACEIRO:
		enemy["is_mini_boss"] = true
		enemy["mini_boss"] = true
		enemy["skip_rewards"] = false
		enemy["s8_state"] = "entry"
		enemy["s8_t"] = 0.0
		enemy["s8_cd"] = 0.8
		enemy["s8_last"] = ""
		enemy["contact_grace"] = CANGACEIRO_ENTRY


# ================================================================ inimigos
func update_enemy(enemy: Dictionary, delta: float) -> void:
	enemy["parado"] = true
	enemy["shoot_cd"] = 999.0
	if float(enemy.get("stun", 0.0)) > 0.0 or float(enemy.get("ferrolho_root", 0.0)) > 0.0:
		return
	enemy["s8_cd"] = maxf(0.0, float(enemy.get("s8_cd", 0.0)) - delta)
	enemy["s8_flash"] = maxf(0.0, float(enemy.get("s8_flash", 0.0)) - delta)
	match String(enemy.get("type", "")):
		JABUTI:
			_update_jabuti(enemy, delta)
		MANDACARU:
			_update_mandacaru(enemy, delta)
		MORTEIRO:
			_update_morteiro(enemy, delta)
		PIAO:
			_update_piao(enemy, delta)
		CANGACEIRO:
			_update_cangaceiro(enemy, delta)
		EGG:
			_update_egg(enemy, delta)


## Ovo da Ninhada do chefe: se nao for quebrado em EGG_HATCH segundos vira Jabuti.
func _update_egg(enemy: Dictionary, delta: float) -> void:
	enemy["s8_t"] = float(enemy.get("s8_t", 0.0)) + delta
	if float(enemy["s8_t"]) < EGG_HATCH:
		return
	var stats := spawn_stats(JABUTI, 70.0, 0.06 * float(core.player_hp_max) + float(core.enemy_close_damage))
	var hp: float = float(core.enemy_base_hp) * float(stats["hp_mult"])
	enemy["type"] = JABUTI
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	enemy["speed"] = float(stats["speed"])
	enemy["damage"] = float(stats["damage"])
	enemy["points"] = 40
	on_spawned(enemy)
	enemy["contact_grace"] = 0.3
	core._spawn_radial_particles(Vector2(enemy["pos"]), Color(0.96, 0.88, 0.7), 10)


func _target_info(enemy: Dictionary) -> Dictionary:
	var pos: Vector2 = Vector2(enemy.get("pos", core.player_pos))
	var target: Vector2 = core._get_enemy_target_pos(enemy)
	var to_target: Vector2 = target - pos
	var dist: float = to_target.length()
	var dir: Vector2 = to_target / dist if dist > 0.01 else Vector2(enemy.get("facing_dir", Vector2.LEFT)).normalized()
	return {"pos": pos, "target": target, "dist": dist, "dir": dir}


func _set_state(enemy: Dictionary, state: String) -> void:
	enemy["s8_state"] = state
	enemy["s8_t"] = 0.0


func _move(enemy: Dictionary, dir: Vector2, speed: float, delta: float) -> bool:
	return core._phase7_apply_enemy_move(enemy, dir, speed, delta)


## Anda mantendo uma faixa de distancia e circulando (strafe) dentro dela.
func _keep_band(enemy: Dictionary, info: Dictionary, near: float, far: float, delta: float, speed_mult: float = 1.0) -> void:
	var dir: Vector2 = info["dir"]
	var dist: float = info["dist"]
	var speed: float = float(enemy.get("speed", 60.0)) * speed_mult
	var strafe: float = float(enemy.get("strafe", 1.0))
	var move: Vector2
	if dist > far:
		move = (dir + dir.orthogonal() * strafe * 0.25).normalized()
	elif dist < near:
		move = (-dir + dir.orthogonal() * strafe * 0.4).normalized()
	else:
		move = dir.orthogonal() * strafe
		speed *= 0.55
	if _move(enemy, move, speed, delta):
		enemy["strafe"] = -strafe
	enemy["facing_dir"] = dir


# ---------------------------------------------------------------- Jabuti Errante
func _update_jabuti(enemy: Dictionary, delta: float) -> void:
	var info := _target_info(enemy)
	enemy["s8_t"] = float(enemy.get("s8_t", 0.0)) + delta
	var t: float = float(enemy["s8_t"])
	match String(enemy.get("s8_state", "walk")):
		"windup":
			enemy["facing_dir"] = info["dir"]
			enemy["s8_dir"] = (predicted_target(0.25, enemy) - Vector2(info["pos"])).normalized()
			if t >= JABUTI_WINDUP:
				_set_state(enemy, "spin")
		"spin":
			var spin_dir: Vector2 = Vector2(enemy.get("s8_dir", info["dir"]))
			var blocked := _move(enemy, spin_dir, JABUTI_SPIN_SPEED * (1.0 - t / JABUTI_SPIN_TIME * 0.45), delta)
			enemy["s8_spin"] = float(enemy.get("s8_spin", 0.0)) + delta * 22.0
			if t >= JABUTI_SPIN_TIME or blocked:
				_set_state(enemy, "dizzy")
				core._spawn_radial_particles(Vector2(enemy["pos"]), Color(0.86, 0.72, 0.48), 5)
		"dizzy":
			if t >= JABUTI_DIZZY:
				_set_state(enemy, "walk")
				enemy["s8_cd"] = JABUTI_COOLDOWN + core.rng.randf_range(-0.6, 0.6)
		_:
			enemy["facing_dir"] = info["dir"]
			if float(info["dist"]) < JABUTI_SPIN_RANGE and float(enemy["s8_cd"]) <= 0.0:
				_set_state(enemy, "windup")
			else:
				_move(enemy, info["dir"], float(enemy.get("speed", 70.0)), delta)


# ---------------------------------------------------------------- Tartaruga-Mandacaru
func _update_mandacaru(enemy: Dictionary, delta: float) -> void:
	var info := _target_info(enemy)
	enemy["s8_t"] = float(enemy.get("s8_t", 0.0)) + delta
	var t: float = float(enemy["s8_t"])
	match String(enemy.get("s8_state", "walk")):
		"root":
			if t >= MANDACARU_ROOT_TIME:
				_set_state(enemy, "fire")
				enemy["s8_emit"] = 0.0
				enemy["s8_angle"] = Vector2(info["dir"]).angle()
				enemy["s8_spin_dir"] = float(enemy.get("strafe", 1.0))
		"fire":
			enemy["s8_emit"] = float(enemy.get("s8_emit", 0.0)) - delta
			while float(enemy["s8_emit"]) <= 0.0:
				enemy["s8_emit"] = float(enemy["s8_emit"]) + MANDACARU_EMIT
				var a: float = float(enemy.get("s8_angle", 0.0))
				var origin: Vector2 = Vector2(enemy["pos"]) + Vector2(0, -18)
				for arm in range(2):
					shoot(origin, Vector2.from_angle(a + PI * float(arm)), 90.0, COL_THORN, {"acc": 170.0, "smax": 240.0, "life": 5.0, "r": 7.0, "src": MANDACARU, "size": 0.9})
				enemy["s8_angle"] = a + MANDACARU_TURN * float(enemy.get("s8_spin_dir", 1.0))
			if t >= MANDACARU_FIRE_TIME:
				ring(Vector2(enemy["pos"]) + Vector2(0, -18), 14, 120.0, core.rng.randf() * TAU, COL_THORN, {"acc": 60.0, "smax": 200.0, "r": 7.0, "src": MANDACARU, "size": 0.9})
				_set_state(enemy, "uproot")
		"uproot":
			if t >= 0.6:
				_set_state(enemy, "walk")
				enemy["s8_cd"] = MANDACARU_COOLDOWN
		_:
			_keep_band(enemy, info, 260.0, 400.0, delta)
			if float(enemy["s8_cd"]) <= 0.0 and float(info["dist"]) < 520.0:
				_set_state(enemy, "root")
				enemy["s8_flash"] = MANDACARU_ROOT_TIME


# ---------------------------------------------------------------- Jabuti-Morteiro
func _update_morteiro(enemy: Dictionary, delta: float) -> void:
	var info := _target_info(enemy)
	enemy["s8_t"] = float(enemy.get("s8_t", 0.0)) + delta
	var t: float = float(enemy["s8_t"])
	match String(enemy.get("s8_state", "walk")):
		"aim":
			enemy["facing_dir"] = info["dir"]
			if t >= MORTEIRO_AIM:
				_launch_eggs(enemy)
				_set_state(enemy, "launch")
		"launch":
			if t >= 0.35:
				_set_state(enemy, "walk")
				enemy["s8_cd"] = MORTEIRO_COOLDOWN + core.rng.randf_range(-0.4, 0.6)
		_:
			_keep_band(enemy, info, 420.0, 600.0, delta)
			if float(enemy["s8_cd"]) <= 0.0 and float(info["dist"]) < 760.0:
				_set_state(enemy, "aim")


func _launch_eggs(enemy: Dictionary) -> void:
	var origin: Vector2 = Vector2(enemy["pos"]) + Vector2(0, -34)
	for i in range(MORTEIRO_EGGS):
		var flight: float = MORTEIRO_FLIGHT + float(i) * 0.12
		var target: Vector2 = predicted_target(flight * 0.85, enemy)
		if i > 0:
			target += Vector2.from_angle(core.rng.randf() * TAU) * core.rng.randf_range(60.0, 120.0)
		target = target.clamp(Vector2(40, 40), core.WORLD_SIZE - Vector2(40, 40))
		hazards.append({"kind": "egg", "from": origin, "to": target, "t": 0.0, "flight": flight, "rot": float(i) * PI / 8.0, "dmg": enemy_bullet_damage(1.5)})
	core._spawn_radial_particles(origin, Color(1.0, 0.6, 0.2), 6)


# ---------------------------------------------------------------- Cagado-Piao
func _update_piao(enemy: Dictionary, delta: float) -> void:
	var info := _target_info(enemy)
	enemy["s8_t"] = float(enemy.get("s8_t", 0.0)) + delta
	var t: float = float(enemy["s8_t"])
	match String(enemy.get("s8_state", "walk")):
		"spinup":
			enemy["facing_dir"] = info["dir"]
			enemy["s8_spin"] = float(enemy.get("s8_spin", 0.0)) + delta * (8.0 + t * 30.0)
			if t >= PIAO_SPINUP:
				_begin_ricochet(enemy, (predicted_target(0.3, enemy) - Vector2(info["pos"])).normalized(), PIAO_BOUNCES)
				_set_state(enemy, "dash")
		"dash":
			enemy["s8_spin"] = float(enemy.get("s8_spin", 0.0)) + delta * 30.0
			if _update_ricochet(enemy, delta, PIAO_SPEED, COL_SAND, PIAO) or t >= PIAO_MAX_TIME:
				_set_state(enemy, "dizzy")
		"dizzy":
			if t >= PIAO_DIZZY:
				_set_state(enemy, "walk")
				enemy["s8_cd"] = PIAO_COOLDOWN
		_:
			_keep_band(enemy, info, 260.0, 360.0, delta, 1.0)
			if float(enemy["s8_cd"]) <= 0.0 and float(info["dist"]) < 460.0:
				_set_state(enemy, "spinup")


func _begin_ricochet(enemy: Dictionary, dir: Vector2, bounces: int) -> void:
	# Caixa em volta do jogador que ESTE inimigo caca (multiplayer: pode ser remoto).
	var center: Vector2 = core._get_enemy_target_pos(enemy)
	enemy["s8_box"] = Rect2(center - PIAO_BOX * 0.5, PIAO_BOX)
	enemy["s8_dir"] = dir if dir.length() > 0.1 else Vector2.RIGHT
	enemy["s8_bounces"] = bounces
	enemy["s8_trail"] = 0.0


## Move em linha reta quicando nas bordas de uma caixa em volta do jogador e
## deixa projeteis parados no rastro, que depois disparam para os lados.
## Retorna true quando acabaram os quiques.
func _update_ricochet(enemy: Dictionary, delta: float, speed: float, color: int, src: String) -> bool:
	var dir: Vector2 = Vector2(enemy.get("s8_dir", Vector2.RIGHT))
	var box: Rect2 = enemy.get("s8_box", Rect2(core.player_pos - PIAO_BOX * 0.5, PIAO_BOX))
	var pos: Vector2 = Vector2(enemy["pos"])
	var step: float = speed * AuraSystem.world_multiplier(core.aura_state) * delta
	var next: Vector2 = pos + dir * step
	var bounced := false
	if next.x < box.position.x or next.x > box.end.x:
		dir.x = -dir.x
		bounced = true
	if next.y < box.position.y or next.y > box.end.y:
		dir.y = -dir.y
		bounced = true
	next = pos + dir * step
	next = next.clamp(Vector2(40, 40), core.WORLD_SIZE - Vector2(40, 40))
	enemy["pos"] = next
	enemy["s8_dir"] = dir
	enemy["facing_dir"] = dir
	enemy["s8_trail"] = float(enemy.get("s8_trail", 0.0)) + step
	while float(enemy["s8_trail"]) >= PIAO_TRAIL_STEP:
		enemy["s8_trail"] = float(enemy["s8_trail"]) - PIAO_TRAIL_STEP
		var side: Vector2 = dir.orthogonal()
		for sgn in [-1.0, 1.0]:
			shoot(next, side * float(sgn), 30.0, color, {"delay": 0.55, "aim": false, "acc": 420.0, "smax": 300.0, "life": 4.0, "r": 7.0, "src": src, "freeze_col": COL_FROZEN, "owner": int(enemy.get("uid", 0))})
	if bounced:
		enemy["s8_bounces"] = int(enemy.get("s8_bounces", 0)) - 1
		core._spawn_radial_particles(next, Color(1.0, 0.86, 0.56), 6)
		core.screen_shake_timer = maxf(core.screen_shake_timer, 0.08)
		return int(enemy["s8_bounces"]) < 0
	return false


# ---------------------------------------------------------------- Cagado Cangaceiro
func _update_miniboss_schedule() -> void:
	if miniboss_spawned or core.boss_active or core.boss_dead or core.mode != "game":
		return
	if core._phase_elapsed_time() < CANGACEIRO_SPAWN_TIME:
		return
	miniboss_spawned = true
	var pos: Vector2 = core._spawn_point_on_edge()
	core._spawn_enemy(CANGACEIRO, pos)
	core._add_text("CAGADO CANGACEIRO", core.player_pos + Vector2(0, -150), Color(1.0, 0.82, 0.3), 2.4, 30)
	core._add_text("O SERTAO MANDOU COBRAR", core.player_pos + Vector2(0, -116), Color(1.0, 0.92, 0.7), 2.2, 18)
	core._play_sfx("boss_impact", 0.02, 0.6, 0.8)


func miniboss() -> Dictionary:
	if core == null:
		return {}
	for enemy in core.enemies:
		if String(enemy.get("type", "")) == CANGACEIRO and float(enemy.get("hp", 0.0)) > 0.0:
			return enemy
	return {}


func miniboss_alive() -> bool:
	return active() and not miniboss().is_empty()


func _cangaceiro_low(enemy: Dictionary) -> bool:
	return float(enemy.get("hp", 1.0)) / maxf(1.0, float(enemy.get("max_hp", 1.0))) <= 0.55


func _update_cangaceiro(enemy: Dictionary, delta: float) -> void:
	var info := _target_info(enemy)
	enemy["s8_t"] = float(enemy.get("s8_t", 0.0)) + delta
	var t: float = float(enemy["s8_t"])
	var low := _cangaceiro_low(enemy)
	match String(enemy.get("s8_state", "walk")):
		"entry":
			if t >= CANGACEIRO_ENTRY:
				_set_state(enemy, "walk")
				core._spawn_radial_particles(Vector2(enemy["pos"]), Color(0.9, 0.74, 0.46), 18)
				core.screen_shake_timer = maxf(core.screen_shake_timer, 0.2)
		"rajada_aim":
			enemy["facing_dir"] = info["dir"]
			enemy["s8_aim"] = info["dir"]
			if t >= 0.5:
				_set_state(enemy, "rajada")
				enemy["s8_bursts"] = 4 if low else 3
				enemy["s8_emit"] = 0.0
		"rajada":
			enemy["facing_dir"] = info["dir"]
			enemy["s8_emit"] = float(enemy.get("s8_emit", 0.0)) - delta
			if float(enemy["s8_emit"]) <= 0.0:
				var left: int = int(enemy.get("s8_bursts", 0))
				var gun_side: float = 1.0 if left % 2 == 0 else -1.0
				var origin: Vector2 = Vector2(enemy["pos"]) + Vector2(0, -40 + 12 * gun_side)
				var aim_dir: Vector2 = (predicted_target(0.2, enemy) - origin).normalized()
				fan(origin, aim_dir.rotated(0.08 * gun_side), 5 if not low else 7, 0.55 if not low else 0.8, 290.0, COL_GOLD, {"r": 8.0, "src": CANGACEIRO, "dmg": enemy_bullet_damage(1.2), "owner": int(enemy.get("uid", 0))})
				enemy["s8_flash"] = 0.12
				enemy["s8_bursts"] = left - 1
				enemy["s8_emit"] = 0.32
				if int(enemy["s8_bursts"]) <= 0:
					_end_cangaceiro_attack(enemy)
		"xaxado":
			enemy["s8_spin"] = float(enemy.get("s8_spin", 0.0)) + delta * 2.1 * (1.25 if low else 1.0)
			enemy["s8_emit"] = float(enemy.get("s8_emit", 0.0)) - delta
			enemy["s8_ring"] = float(enemy.get("s8_ring", 0.0)) - delta
			var origin_x: Vector2 = Vector2(enemy["pos"]) + Vector2(0, -36)
			while float(enemy["s8_emit"]) <= 0.0:
				enemy["s8_emit"] = float(enemy["s8_emit"]) + 0.1
				var base_a: float = float(enemy["s8_spin"])
				for arm in range(4):
					shoot(origin_x, Vector2.from_angle(base_a + TAU * float(arm) / 4.0), 210.0, COL_GOLD, {"r": 7.0, "src": CANGACEIRO, "owner": int(enemy.get("uid", 0))})
			if float(enemy["s8_ring"]) <= 0.0:
				enemy["s8_ring"] = 0.85
				ring(origin_x, 14, 140.0, core.rng.randf() * TAU, COL_SAND, {"r": 7.0, "src": CANGACEIRO, "owner": int(enemy.get("uid", 0))})
			if t >= 3.4:
				_end_cangaceiro_attack(enemy)
		"casco_prep":
			enemy["facing_dir"] = info["dir"]
			if t >= 0.45:
				_begin_ricochet(enemy, (predicted_target(0.3, enemy) - Vector2(info["pos"])).normalized(), 4)
				_set_state(enemy, "casco")
		"casco":
			enemy["s8_spin"] = float(enemy.get("s8_spin", 0.0)) + delta * 26.0
			if _update_ricochet(enemy, delta, 560.0, COL_GOLD, CANGACEIRO) or t >= 2.8:
				_set_state(enemy, "dizzy")
		"dizzy":
			if t >= 1.2:
				_end_cangaceiro_attack(enemy)
		"tocaia_prep":
			enemy["facing_dir"] = info["dir"]
			if t >= 0.6:
				_cangaceiro_tocaia(enemy)
				_set_state(enemy, "tocaia")
		"tocaia":
			if t >= 1.6:
				_end_cangaceiro_attack(enemy)
		_:
			_keep_band(enemy, info, 240.0, 380.0, delta)
			if float(enemy["s8_cd"]) <= 0.0:
				_start_cangaceiro_attack(enemy, info)


func _start_cangaceiro_attack(enemy: Dictionary, info: Dictionary) -> void:
	var bag: Array = enemy.get("s8_bag", [])
	var low := _cangaceiro_low(enemy)
	if bag.is_empty() or (low and not bool(enemy.get("s8_bag_low", false))):
		enemy["s8_bag_low"] = low
		bag = ["rajada", "xaxado", "casco"]
		if low:
			bag.append("tocaia")
		bag.shuffle()
		if bag.size() > 1 and String(bag[0]) == String(enemy.get("s8_last", "")):
			bag.append(bag.pop_front())
	var pick: String = String(bag.pop_front())
	enemy["s8_bag"] = bag
	enemy["s8_last"] = pick
	match pick:
		"rajada":
			_set_state(enemy, "rajada_aim")
		"xaxado":
			_set_state(enemy, "xaxado")
			enemy["s8_emit"] = 0.3
			enemy["s8_ring"] = 0.4
			enemy["s8_spin"] = Vector2(info["dir"]).angle()
			core._add_text("XAXADO!", Vector2(enemy["pos"]) + Vector2(0, -110), Color(1.0, 0.84, 0.3), 0.9, 20)
		"casco":
			_set_state(enemy, "casco_prep")
		"tocaia":
			_set_state(enemy, "tocaia_prep")
			core._add_text("TOCAIA!", Vector2(enemy["pos"]) + Vector2(0, -110), Color(0.5, 0.95, 1.0), 1.0, 22)


func _end_cangaceiro_attack(enemy: Dictionary) -> void:
	_set_state(enemy, "walk")
	enemy["s8_cd"] = CANGACEIRO_GAP * (0.75 if _cangaceiro_low(enemy) else 1.0)


## Tocaia: dispara em todas as direcoes, as balas freiam e ficam paradas no ar (o
## tempo emperra) e entao todas miram ao mesmo tempo em onde o jogador esta.
func _cangaceiro_tocaia(enemy: Dictionary) -> void:
	var origin: Vector2 = Vector2(enemy["pos"]) + Vector2(0, -36)
	var n := 28
	for i in range(n):
		var a: float = TAU * float(i) / float(n) + core.rng.randf_range(-0.08, 0.08)
		var speed: float = core.rng.randf_range(300.0, 380.0)
		var hang: float = 0.35 + 0.9
		var b := shoot(origin, Vector2.from_angle(a), speed, COL_GOLD, {"acc": -speed / 0.35, "smin": 0.0, "r": 8.0, "life": 6.0, "src": CANGACEIRO, "owner": int(enemy.get("uid", 0))})
		if not b.is_empty():
			# Fica parado depois de frear; o delay e aplicado em _tocaia_hazard.
			b["tocaia_hang"] = hang
	hazards.append({"kind": "tocaia", "t": 0.0, "owner": int(enemy.get("uid", 0)), "fired": false})
	core.screen_shake_timer = maxf(core.screen_shake_timer, 0.15)


func damage_taken_multiplier(enemy: Dictionary) -> float:
	var kind := String(enemy.get("type", ""))
	if not owns_kind(kind):
		return 1.0
	var state := String(enemy.get("s8_state", "walk"))
	match kind:
		JABUTI:
			if state == "spin":
				return 0.5
			if state == "dizzy":
				return 1.25
		MANDACARU:
			if state in ["root", "fire"]:
				return 1.15
		PIAO:
			if state == "dash":
				return 0.6
			if state == "dizzy":
				return 1.3
		CANGACEIRO:
			if state == "entry":
				return 0.0
			if state in ["casco", "casco_prep"]:
				return 0.3
			if state == "xaxado":
				return 0.85
			if state == "dizzy":
				return 1.35
	return 1.0


func on_enemy_defeated(enemy: Dictionary) -> void:
	if String(enemy.get("type", "")) != CANGACEIRO:
		return
	miniboss_defeated = true
	var pos: Vector2 = Vector2(enemy.get("pos", core.player_pos))
	clear_bullets(int(enemy.get("uid", 0)), true)
	for h in hazards:
		if String(h.get("kind", "")) == "tocaia" and int(h.get("owner", 0)) == int(enemy.get("uid", 0)):
			h["t"] = 99.0
	core._grant_spectral_core(2, pos, "miniboss_phase_8")
	core._add_text("CANGACEIRO DERRUBADO", pos + Vector2(0, -120), Color(1.0, 0.84, 0.3), 2.4, 28)
	core._spawn_radial_particles(pos, Color(1.0, 0.84, 0.3), 40)
	core.screen_shake_timer = maxf(core.screen_shake_timer, 0.3)


# ================================================================ perigos no chao
func _update_hazards(delta: float) -> void:
	if hazards.is_empty():
		return
	var dt: float = delta * AuraSystem.world_multiplier(core.aura_state)
	var kept: Array = []
	for h in hazards:
		h["t"] = float(h.get("t", 0.0)) + dt
		match String(h.get("kind", "")):
			"egg":
				if float(h["t"]) >= float(h["flight"]):
					_egg_land(h)
					continue
			"tocaia":
				if not bool(h.get("fired", false)) and float(h["t"]) >= 0.35:
					h["fired"] = true
					for b in bullets:
						if b.has("tocaia_hang") and int(b.get("owner", 0)) == int(h.get("owner", 0)):
							b["delay"] = float(b["tocaia_hang"]) - 0.35
							b["aim"] = true
							b["aim_speed"] = 40.0
							b["aim_acc"] = 620.0
							b["smax"] = 380.0
							b["acc"] = 0.0
							b["fc"] = COL_FROZEN
							b.erase("tocaia_hang")
				if float(h["t"]) >= 1.4:
					continue
		kept.append(h)
	hazards = kept


func _egg_land(h: Dictionary) -> void:
	var pos: Vector2 = h["to"]
	for target_value in core._combat_targets():
		var target: Dictionary = target_value
		if Vector2(target.get("pos", pos)).distance_to(pos) <= MORTEIRO_BLAST + PLAYER_HIT_RADIUS:
			_damage_target(target, int(h.get("dmg", enemy_bullet_damage(1.5))), MORTEIRO)
	ring(pos, 8, 190.0, float(h.get("rot", 0.0)), COL_EGG, {"acc": -120.0, "smin": 70.0, "life": 3.2, "r": 8.0, "src": MORTEIRO})
	core._spawn_radial_particles(pos, Color(1.0, 0.56, 0.18), 10)
	core.shockwaves.append({"pos": pos, "radius": 10.0, "max": MORTEIRO_BLAST, "life": 0.3, "hit": {}, "visual_only": true, "max_life": 0.3, "color": Color(1.0, 0.6, 0.2)})


func clear_for_boss_call() -> void:
	bullets.clear()
	hazards.clear()


# ================================================================ replica visual
## Gameplay stays authority-only. This compact snapshot gives replicas the
## exact bullet field, telegraphs and animation state without simulating hits.
func visual_snapshot() -> Dictionary:
	var packed := PackedFloat32Array()
	packed.resize(bullets.size() * VISUAL_BULLET_STRIDE)
	var offset := 0
	for bullet_value in bullets:
		var b: Dictionary = bullet_value
		var p: Vector2 = Vector2(b.get("p", Vector2.ZERO))
		var v: Vector2 = Vector2(b.get("v", Vector2.RIGHT))
		packed[offset] = p.x
		packed[offset + 1] = p.y
		packed[offset + 2] = v.x
		packed[offset + 3] = v.y
		packed[offset + 4] = float(b.get("delay", 0.0))
		packed[offset + 5] = float(b.get("size", 1.0))
		packed[offset + 6] = float(b.get("c", COL_SAND))
		packed[offset + 7] = float(b.get("fc", COL_SAND))
		packed[offset + 8] = float(b.get("owner", 0))
		packed[offset + 9] = float(b.get("r", 8.0))
		packed[offset + 10] = float(b.get("t", 0.0))
		offset += VISUAL_BULLET_STRIDE
	var enemy_visuals: Array = []
	for enemy_value in core.enemies:
		if not enemy_value is Dictionary:
			continue
		var enemy: Dictionary = enemy_value
		if not owns_kind(String(enemy.get("type", ""))):
			continue
		enemy_visuals.append({
			"uid": int(enemy.get("uid", 0)),
			"state": String(enemy.get("s8_state", "walk")),
			"t": float(enemy.get("s8_t", 0.0)),
			"flash": float(enemy.get("s8_flash", 0.0)),
			"aim": Vector2(enemy.get("s8_aim", Vector2.RIGHT)),
			"spin": float(enemy.get("s8_spin", 0.0)),
		})
	return {"bullets": packed, "hazards": hazards.duplicate(true), "enemies": enemy_visuals}


func apply_remote_visual_snapshot(data: Dictionary) -> void:
	var incoming = data.get("bullets", PackedFloat32Array())
	if incoming is PackedFloat32Array:
		var packed: PackedFloat32Array = incoming
		var next_bullets: Array = []
		for offset in range(0, packed.size() - VISUAL_BULLET_STRIDE + 1, VISUAL_BULLET_STRIDE):
			next_bullets.append({
				"p": Vector2(packed[offset], packed[offset + 1]),
				"v": Vector2(packed[offset + 2], packed[offset + 3]),
				"delay": packed[offset + 4],
				"size": packed[offset + 5],
				"c": int(packed[offset + 6]),
				"fc": int(packed[offset + 7]),
				"owner": int(packed[offset + 8]),
				"r": packed[offset + 9],
				"t": packed[offset + 10],
			})
		bullets = next_bullets
	hazards = Array(data.get("hazards", [])).duplicate(true)
	_remote_enemy_visual_by_uid.clear()
	for visual_value in Array(data.get("enemies", [])):
		if visual_value is Dictionary:
			var visual: Dictionary = visual_value
			_remote_enemy_visual_by_uid[int(visual.get("uid", 0))] = visual
	_apply_remote_enemy_visuals()


func _apply_remote_enemy_visuals() -> void:
	for enemy_value in core.enemies:
		if not enemy_value is Dictionary:
			continue
		var enemy: Dictionary = enemy_value
		var visual: Dictionary = _remote_enemy_visual_by_uid.get(int(enemy.get("uid", 0)), {})
		if visual.is_empty():
			continue
		enemy["s8_state"] = String(visual.get("state", "walk"))
		enemy["s8_t"] = float(visual.get("t", 0.0))
		enemy["s8_flash"] = float(visual.get("flash", 0.0))
		enemy["s8_aim"] = Vector2(visual.get("aim", Vector2.RIGHT))
		enemy["s8_spin"] = float(visual.get("spin", 0.0))
