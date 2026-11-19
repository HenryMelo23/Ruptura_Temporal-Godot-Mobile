class_name RTBoss8Controller
extends RefCounted

## Chefe da Dimensao 8: CASCO-DE-SOL, o jabuti-relogio.
## O casco e um relogio de sol: 12 runas de horas no anel e um gnomon no centro.
## Usa o motor de projeteis do RTSertaoController.
##
## Estagio 1 (100-65%): Ponteiro das Horas, Doze Badaladas, Areia da Ampulheta.
## Estagio 2 (65-30%): + Sombra do Gnomon (fique na sombra), Rolagem do Casco, Ninhada.
## Estagio 3 (<=30%): Eclipse (uma vez: o tempo para) e tudo mais rapido, ponteiros duplos.

const ENTRY_TIME := 2.4
const HIT_RADIUS := 118.0
const DRAW_SIZE := Vector2(380, 380)
const WALK_SPEED := 34.0
const KEEP_DISTANCE := 250.0
const STAGE2_PCT := 0.65
const STAGE3_PCT := 0.30
const RIM_RADIUS := 86.0
const RIM_FLATTEN := 0.42
const SHELL_TOP := Vector2(-22, -88)

const PONTEIRO_TIME := 3.6
const PONTEIRO_EMIT := 0.045
const BADALADA_GAP := 0.16
const AMPULHETA_TIME := 3.8
const AMPULHETA_ROW := 0.34
const AMPULHETA_SPACING := 56.0
const GNOMON_CHARGE := 2.0
const GNOMON_BLAZE := 1.9
const GNOMON_HALF_WIDTH := 0.4
const GNOMON_LENGTH := 1200.0
const GNOMON_TICK := 0.35
const ROLL_RETRACT := 0.6
const ROLL_TELEGRAPH := 0.55
const ROLL_SPEED := 720.0
const ROLL_DISTANCE := 700.0
const ECLIPSE_TIME := 9.0

var game: Node
var mode: String = "entry"
var t: float = 0.0
var anim: String = "walk"
var anim_t: float = 0.0
var attack_cd: float = 1.4
var stage: int = 1
var last_attack: String = ""
var facing: float = 1.0
var hand_angle: float = 0.0
var hand_dir: float = 1.0
var emit: float = 0.0
var count: int = 0
var gaps: Array = []
var rolls_left: int = 0
var roll_dir: Vector2 = Vector2.RIGHT
var roll_from: Vector2 = Vector2.ZERO
var shadow_angle: float = 0.0
var shadow_on: bool = false
var shadow_spin: float = 1.0
var sun_power: float = 0.0
var sun_tick: float = 0.0
var eclipse_done: bool = false
var eclipse_frozen: bool = false
var contact_cd: float = 0.0
var contact_cd_by_peer: Dictionary = {}
var moving: bool = false
var death_t: float = -1.0
var death_pos: Vector2 = Vector2.ZERO
var interlude_done: bool = false
var bag: Array = []
var bag_stage: int = 0


func configure(p_game: Node) -> void:
	game = p_game


func s8() -> RTSertaoController:
	return game.sertao_controller


func reset() -> void:
	mode = "entry"
	t = 0.0
	anim = "rise"
	anim_t = 0.0
	attack_cd = 1.4
	stage = 1
	last_attack = ""
	facing = 1.0
	hand_angle = 0.0
	hand_dir = 1.0
	emit = 0.0
	count = 0
	gaps = []
	rolls_left = 0
	shadow_on = false
	sun_power = 0.0
	sun_tick = 0.0
	eclipse_done = false
	eclipse_frozen = false
	contact_cd = 0.0
	contact_cd_by_peer.clear()
	moving = false
	death_t = -1.0
	interlude_done = false
	bag = []
	bag_stage = 0


func pct() -> float:
	return float(game.boss_hp) / maxf(1.0, float(game.boss_hp_max))


func shell_center() -> Vector2:
	return Vector2(game.boss_pos) + Vector2(SHELL_TOP.x * facing, SHELL_TOP.y)


func rim_point(angle: float, radius: float = RIM_RADIUS) -> Vector2:
	return shell_center() + Vector2(cos(angle) * radius, sin(angle) * radius * RIM_FLATTEN)


func damage_taken_multiplier() -> float:
	match mode:
		"entry":
			return 0.0
		"roll", "roll_prep", "retract":
			return 0.5
		"eclipse":
			return 0.55
	return 1.0


func _gap() -> float:
	var base: float = 1.3 if stage == 1 else (1.0 if stage == 2 else 0.75)
	return game._boss_party_scaled_interval(base, 0.55)


func _set_mode(m: String, a: String = "") -> void:
	mode = m
	t = 0.0
	if a != "":
		anim = a
		anim_t = 0.0


# ================================================================ atualizacao
func update(delta: float) -> void:
	if game == null or not game.boss_active or game.boss_dead:
		return
	var dt: float = delta * AuraSystem.world_multiplier(game.aura_state)
	t += dt
	anim_t += dt
	game.boss_phase += dt * (5.0 if moving else 2.0)
	contact_cd = maxf(0.0, contact_cd - dt)
	for peer_key in contact_cd_by_peer.keys():
		var remaining: float = maxf(0.0, float(contact_cd_by_peer.get(peer_key, 0.0)) - dt)
		if remaining <= 0.0:
			contact_cd_by_peer.erase(peer_key)
		else:
			contact_cd_by_peer[peer_key] = remaining
	sun_power = maxf(0.0, sun_power - dt * 0.8) if not shadow_on else sun_power
	_update_stage()
	match mode:
		"entry":
			_update_entry(dt)
		"walk":
			_update_walk(dt)
		"interlude":
			_update_interlude(dt)
		"ponteiro":
			_update_ponteiro(dt)
		"badaladas":
			_update_badaladas(dt)
		"ampulheta":
			_update_ampulheta(dt)
		"gnomon":
			_update_gnomon(dt)
		"retract", "roll_prep", "roll":
			_update_roll(dt)
		"ninhada":
			_update_ninhada(dt)
		"eclipse":
			_update_eclipse(dt)
	_update_contact()


func _update_stage() -> void:
	if mode == "entry" or mode == "eclipse":
		return
	var p := pct()
	if stage == 1 and p <= STAGE2_PCT:
		stage = 2
		if mode == "walk" or not interlude_done:
			interlude_done = true
			_cancel_attack()
			_set_mode("interlude", "sun")
			game._add_text("MEIO-DIA", Vector2(game.boss_pos) + Vector2(0, -230), Color(1.0, 0.86, 0.4), 1.6, 32)
			s8().ring(shell_center(), 24, 150.0, 0.0, RTSertaoController.COL_SUN, {"acc": 60.0, "smax": 240.0, "r": 9.0, "src": "boss8_sol", "dmg": s8().boss_bullet_damage()})
	elif stage == 2 and p <= STAGE3_PCT and not eclipse_done:
		stage = 3
		eclipse_done = true
		_cancel_attack()
		_start_eclipse()


func _cancel_attack() -> void:
	shadow_on = false
	gaps = []


func _update_entry(_dt: float) -> void:
	if t >= ENTRY_TIME:
		game._boss_entry_impact_feedback(0.8)
		game._spawn_radial_particles(Vector2(game.boss_pos), Color(0.92, 0.76, 0.48), 60)
		s8().ring(shell_center(), 20, 120.0, 0.0, RTSertaoController.COL_SAND, {"acc": 40.0, "smax": 200.0, "r": 9.0, "src": "boss8_sol", "dmg": s8().boss_bullet_damage()})
		game._add_text("O TEMPO AQUI ANDA DEVAGAR", Vector2(game.boss_pos) + Vector2(0, -240), Color(1.0, 0.9, 0.62), 2.0, 22)
		_set_mode("walk", "walk")
		attack_cd = 1.2


func _update_walk(dt: float) -> void:
	var player: Vector2 = game._boss_target_pos(false)
	var to_player: Vector2 = player - Vector2(game.boss_pos)
	var dist: float = to_player.length()
	if absf(to_player.x) > 20.0:
		facing = signf(to_player.x)
	moving = false
	if dist > KEEP_DISTANCE + 60.0:
		_step_toward(player, WALK_SPEED * (1.25 if stage == 3 else 1.0), dt)
		moving = true
	elif dist < KEEP_DISTANCE - 80.0:
		_step_toward(Vector2(game.boss_pos) - to_player, WALK_SPEED * 0.8, dt)
		moving = true
	anim = "walk"
	attack_cd -= dt
	if attack_cd <= 0.0:
		_start_next_attack()


func _step_toward(target: Vector2, speed: float, dt: float) -> void:
	var dir: Vector2 = (target - Vector2(game.boss_pos)).normalized()
	var next: Vector2 = Vector2(game.boss_pos) + dir * speed * dt
	game.boss_pos = game.experimental_phase_controller.clamp_to_boss_encounter(next, Vector2(140, 140))


func _update_contact() -> void:
	if mode == "entry":
		return
	var radius: float = HIT_RADIUS * (0.85 if mode == "roll" else 0.62)
	var center: Vector2 = Vector2(game.boss_pos) + Vector2(0, 16)
	for target_value in game._combat_targets():
		var target: Dictionary = target_value
		var peer_id: int = int(target.get("peer_id", 0))
		if float(contact_cd_by_peer.get(peer_id, 0.0)) > 0.0:
			continue
		if Vector2(target.get("pos", center)).distance_to(center) > radius:
			continue
		contact_cd_by_peer[peer_id] = 1.0
		contact_cd = 1.0
		var dmg: int = s8().boss_bullet_damage(1.6) if mode == "roll" else game._boss_contact_damage()
		if bool(target.get("local", false)):
			game._damage_player(dmg, "boss8_casco")
		else:
			game._send_peer_damage(peer_id, dmg, "boss8_casco")


func _start_next_attack() -> void:
	shadow_on = false
	gaps = []
	# Saco embaralhado: todo ataque do estagio aparece antes de algum repetir.
	if bag.is_empty() or bag_stage != stage:
		bag_stage = stage
		bag = ["ponteiro", "badaladas", "ampulheta"]
		if stage >= 2:
			bag.append_array(["gnomon", "rolagem", "ninhada"])
		if stage >= 3:
			bag.append_array(["ponteiro", "gnomon"])
		for i in range(bag.size() - 1, 0, -1):
			var j: int = game.rng.randi_range(0, i)
			var tmp = bag[i]
			bag[i] = bag[j]
			bag[j] = tmp
		if bag.size() > 1 and String(bag[0]) == last_attack:
			bag.append(bag.pop_front())
	var pick: String = String(bag.pop_front())
	if pick == "ninhada" and game.enemies.size() >= 6:
		pick = "badaladas"
	last_attack = pick
	var target_pos: Vector2 = game._boss_target_pos(false, 0.15)
	match pick:
		"ponteiro":
			_set_mode("ponteiro", "cast")
			hand_angle = (target_pos - shell_center()).angle() + PI * 0.5
			hand_dir = -hand_dir
			emit = 0.5
			game._add_text("PONTEIRO DAS HORAS", Vector2(game.boss_pos) + Vector2(0, -230), Color(1.0, 0.78, 0.3), 1.0, 20)
		"badaladas":
			_set_mode("badaladas", "cast")
			count = 0
			emit = 0.45
		"ampulheta":
			_set_mode("ampulheta", "cast")
			emit = 0.6
			gaps = [game.rng.randf_range(0.2, 0.4), game.rng.randf_range(0.6, 0.8)]
			game._add_text("AREIA DA AMPULHETA", game.player_pos + Vector2(0, -170), Color(1.0, 0.92, 0.68), 1.0, 20)
		"gnomon":
			_set_mode("gnomon", "cast")
			shadow_on = true
			sun_tick = 0.0
			emit = 0.8
			# A sombra nasce ao lado do jogador e gira na direcao dele (e passa por ele).
			var side: float = 1.0 if game.rng.randf() < 0.5 else -1.0
			shadow_angle = (target_pos - Vector2(game.boss_pos)).angle() + 1.0 * side
			shadow_spin = -side
			game._add_text("FIQUE NA SOMBRA", game.player_pos + Vector2(0, -170), Color(0.66, 0.84, 1.0), 1.6, 24)
		"rolagem":
			_set_mode("retract", "retract")
			rolls_left = 4 if stage >= 3 else 3
		"ninhada":
			_set_mode("ninhada", "cast")
			_lay_eggs()


func _end_attack() -> void:
	shadow_on = false
	gaps = []
	_set_mode("walk", "walk")
	attack_cd = _gap()


func _update_interlude(_dt: float) -> void:
	if t >= 1.3:
		_end_attack()


# ---------------------------------------------------------------- Ponteiro das Horas
func _update_ponteiro(dt: float) -> void:
	var duration: float = PONTEIRO_TIME * (0.88 if stage == 3 else 1.0)
	hand_angle += hand_dir * (TAU / duration) * dt
	emit -= dt
	var arms: int = 1 if stage == 1 else 2
	while emit <= 0.0:
		emit += PONTEIRO_EMIT
		for arm in range(arms):
			var a: float = hand_angle + PI * float(arm)
			s8().shoot(rim_point(a, RIM_RADIUS * 0.7), Vector2.from_angle(a), 235.0, RTSertaoController.COL_SUN, {"r": 8.0, "life": 4.6, "src": "boss8_sol", "dmg": s8().boss_bullet_damage()})
		if stage == 3:
			# Ponteiro dos minutos: mais fino, gira ao contrario e mais rapido.
			var m: float = -hand_angle * 1.6
			s8().shoot(rim_point(m, RIM_RADIUS * 0.5), Vector2.from_angle(m), 200.0, RTSertaoController.COL_SAND, {"r": 7.0, "life": 4.6, "size": 0.85, "src": "boss8_sol", "dmg": s8().boss_bullet_damage(0.85)})
	if t >= duration:
		_end_attack()


# ---------------------------------------------------------------- Doze Badaladas
func _update_badaladas(dt: float) -> void:
	emit -= dt
	var gap: float = BADALADA_GAP * (0.7 if stage == 3 else 1.0)
	while emit <= 0.0 and count < 12:
		emit += gap
		var hour_angle: float = -PI * 0.5 + TAU * float(count) / 12.0
		var origin: Vector2 = rim_point(hour_angle)
		s8().ring(origin, 10 if stage < 3 else 12, 165.0, float(count) * 0.26, RTSertaoController.COL_SUN, {"acc": 25.0, "smax": 230.0, "r": 8.0, "life": 5.0, "src": "boss8_sol", "dmg": s8().boss_bullet_damage()})
		game._spawn_radial_particles(origin, Color(1.0, 0.84, 0.36), 3)
		count += 1
	if count >= 12 and t >= 12.0 * gap + 0.4:
		_end_attack()


# ---------------------------------------------------------------- Areia da Ampulheta
func gap_centers() -> Array:
	var out: Array = []
	for i in range(gaps.size()):
		var g: float = float(gaps[i]) + sin(t * 0.9 + float(i) * 2.0) * 0.12
		out.append(clampf(g, 0.08, 0.92))
	return out


func _update_ampulheta(dt: float) -> void:
	emit -= dt
	var viewport: Vector2 = game.get_viewport_rect().size
	var width: float = viewport.x + 160.0
	var target_pos: Vector2 = game._boss_target_pos(false)
	var left: float = target_pos.x - width * 0.5
	var top: float = target_pos.y - viewport.y * 0.62
	while emit <= 0.0 and t < AMPULHETA_TIME:
		emit += AMPULHETA_ROW * (0.85 if stage == 3 else 1.0)
		var centers := gap_centers()
		var cols: int = int(width / AMPULHETA_SPACING)
		var offset: float = AMPULHETA_SPACING * 0.5 * float(int(t / AMPULHETA_ROW) % 2)
		for c in range(cols):
			var x: float = left + offset + float(c) * AMPULHETA_SPACING
			var u: float = (x - left) / width
			var in_gap := false
			for g in centers:
				if absf(u - float(g)) < 0.075:
					in_gap = true
					break
			if in_gap:
				continue
			s8().shoot(Vector2(x, top), Vector2.DOWN, 210.0, RTSertaoController.COL_SAND, {"r": 8.0, "life": 4.2, "src": "boss8_areia", "dmg": s8().boss_bullet_damage(0.9)})
	if t >= AMPULHETA_TIME + 0.6:
		_end_attack()


# ---------------------------------------------------------------- Sombra do Gnomon
func player_in_shadow() -> bool:
	return point_in_shadow(game.player_pos)


func point_in_shadow(point: Vector2) -> bool:
	var to_p: Vector2 = point - Vector2(game.boss_pos)
	var dist: float = to_p.length()
	if dist < 60.0:
		return true
	if dist > GNOMON_LENGTH:
		return false
	return absf(wrapf(to_p.angle() - shadow_angle, -PI, PI)) <= GNOMON_HALF_WIDTH


func _update_gnomon(dt: float) -> void:
	shadow_angle += dt * shadow_spin * (0.32 if stage < 3 else 0.45)
	if t < GNOMON_CHARGE:
		sun_power = clampf(t / GNOMON_CHARGE, 0.0, 1.0) * 0.6
		anim = "cast"
		return
	anim = "sun"
	sun_power = 1.0
	sun_tick -= dt
	if sun_tick <= 0.0:
		sun_tick = GNOMON_TICK
		for target_value in game._combat_targets():
			var target: Dictionary = target_value
			var target_pos: Vector2 = Vector2(target.get("pos", game.player_pos))
			if point_in_shadow(target_pos):
				continue
			var peer_id: int = int(target.get("peer_id", 0))
			if bool(target.get("local", false)):
				if not game._player_invulnerable():
					game._damage_player(s8().boss_bullet_damage(0.75), "boss8_sol_a_pino")
					game._add_text("SOL A PINO", target_pos + Vector2(0, -90), Color(1.0, 0.95, 0.7), 0.5, 16)
			else:
				game._send_peer_damage(peer_id, s8().boss_bullet_damage(0.75), "boss8_sol_a_pino")
	emit -= dt
	if emit <= 0.0:
		emit = 0.7
		var aim: Vector2 = (s8().predicted_target(0.3) - shell_center()).normalized()
		s8().fan(shell_center(), aim, 3, 0.3, 250.0, RTSertaoController.COL_SUN, {"r": 8.0, "src": "boss8_sol", "dmg": s8().boss_bullet_damage()})
	if t >= GNOMON_CHARGE + GNOMON_BLAZE:
		sun_power = 0.6
		_end_attack()


# ---------------------------------------------------------------- Rolagem do Casco
func _update_roll(dt: float) -> void:
	match mode:
		"retract":
			anim = "retract"
			if t >= ROLL_RETRACT:
				_begin_roll_prep()
		"roll_prep":
			anim = "shell"
			if t >= ROLL_TELEGRAPH:
				mode = "roll"
				t = 0.0
				anim = "roll"
				roll_from = game.boss_pos
		"roll":
			var next: Vector2 = Vector2(game.boss_pos) + roll_dir * ROLL_SPEED * dt
			var clamped: Vector2 = game.experimental_phase_controller.clamp_to_boss_encounter(next, Vector2(120, 120))
			game.boss_pos = clamped
			if absf(roll_dir.x) > 0.1:
				facing = signf(roll_dir.x)
			if Vector2(game.boss_pos).distance_to(roll_from) >= ROLL_DISTANCE or clamped.distance_squared_to(next) > 4.0 or t > 1.6:
				_roll_impact()


func _begin_roll_prep() -> void:
	mode = "roll_prep"
	t = 0.0
	var target: Vector2 = s8().predicted_target(0.45)
	roll_dir = (target - Vector2(game.boss_pos)).normalized()
	if roll_dir.length() < 0.1:
		roll_dir = Vector2.RIGHT


func _roll_impact() -> void:
	var pos: Vector2 = Vector2(game.boss_pos) + Vector2(0, 60)
	s8().ring(pos, 18, 180.0, game.rng.randf() * TAU, RTSertaoController.COL_SUN, {"acc": 30.0, "smax": 240.0, "r": 9.0, "src": "boss8_sol", "dmg": s8().boss_bullet_damage()})
	game._spawn_radial_particles(pos, Color(0.94, 0.78, 0.5), 22)
	game.shockwaves.append({"pos": pos, "radius": 20.0, "max": 160.0, "life": 0.35, "max_life": 0.35, "hit": {}, "visual_only": true, "color": Color(1.0, 0.8, 0.4)})
	game.screen_shake_timer = maxf(game.screen_shake_timer, 0.25)
	game.screen_shake_strength = maxf(game.screen_shake_strength, 12.0)
	rolls_left -= 1
	if rolls_left > 0:
		_begin_roll_prep()
	else:
		_end_attack()


# ---------------------------------------------------------------- Ninhada
func _lay_eggs() -> void:
	var n: int = 4 if stage < 3 else 5
	var target: Vector2 = game._boss_target_pos(false)
	for i in range(n):
		var a: float = TAU * float(i) / float(n) + game.rng.randf_range(-0.3, 0.3)
		var pos: Vector2 = target + Vector2.from_angle(a) * game.rng.randf_range(220.0, 300.0)
		pos = pos.clamp(Vector2(60, 60), game.WORLD_SIZE - Vector2(60, 60))
		game._spawn_enemy(RTSertaoController.EGG, pos)
	game._add_text("NINHADA", Vector2(game.boss_pos) + Vector2(0, -230), Color(1.0, 0.86, 0.6), 1.2, 22)


func _update_ninhada(_dt: float) -> void:
	if t >= 1.0:
		_end_attack()


# ---------------------------------------------------------------- Eclipse
func _start_eclipse() -> void:
	_set_mode("eclipse", "eclipse")
	emit = 1.0
	count = 0
	eclipse_frozen = false
	game._add_text("ECLIPSE", Vector2(game.boss_pos) + Vector2(0, -250), Color(0.86, 0.7, 1.0), 2.4, 40)
	game._add_text("O TEMPO VAI PARAR", Vector2(game.boss_pos) + Vector2(0, -212), Color(0.6, 0.96, 1.0), 2.2, 20)
	game.screen_shake_timer = maxf(game.screen_shake_timer, 0.4)


func eclipse_power() -> float:
	if mode != "eclipse":
		return 0.0
	return clampf(minf(t / 0.8, (ECLIPSE_TIME + 0.6 - t) / 0.8), 0.0, 1.0)


func _update_eclipse(dt: float) -> void:
	emit -= dt
	if t < 6.6:
		while emit <= 0.0:
			emit += 0.5
			var dir: float = 1.0 if count % 2 == 0 else -1.0
			var gap_angle: float = (game._boss_target_pos(false) - shell_center()).angle() + float(count) * 0.5
			s8().ring(shell_center(), 30, 150.0, float(count) * 0.21, RTSertaoController.COL_ECLIPSE, {"w": 0.35 * dir, "r": 8.0, "life": 6.5, "src": "boss8_eclipse", "dmg": s8().boss_bullet_damage()}, gap_angle, 3)
			count += 1
	if not eclipse_frozen and t >= 4.0:
		eclipse_frozen = true
		s8().freeze_all(0.9, 1.35)
		game._add_text("O TEMPO PAROU", game.player_pos + Vector2(0, -160), Color(0.5, 0.96, 1.0), 1.2, 30)
	if t >= 7.2 and count < 999:
		count = 999
		s8().ring(shell_center(), 40, 60.0, game.rng.randf() * TAU, RTSertaoController.COL_ECLIPSE, {"delay": 0.5, "acc": 260.0, "smax": 300.0, "r": 8.0, "life": 6.0, "src": "boss8_eclipse", "dmg": s8().boss_bullet_damage(), "freeze_col": RTSertaoController.COL_FROZEN})
	if t >= ECLIPSE_TIME:
		_end_attack()
		game._add_text("CASCO RACHADO", Vector2(game.boss_pos) + Vector2(0, -230), Color(1.0, 0.8, 0.4), 1.4, 24)


# ================================================================ morte
func on_death() -> void:
	death_t = 0.0
	death_pos = game.boss_pos
	shadow_on = false
	s8().clear_bullets(0, true)
	s8().hazards.clear()
	game._spawn_radial_particles(Vector2(game.boss_pos) + SHELL_TOP, Color(1.0, 0.84, 0.36), 70)


func update_death(delta: float) -> void:
	if death_t >= 0.0:
		death_t += delta
		if death_t > 3.0:
			death_t = -1.0


# ================================================================ apresentacao
## Chave de textura + indice de quadro para a apresentacao.
func frame_info() -> Array:
	match anim:
		"rise", "walk":
			return ["boss8_walk", int(anim_t * 5.0) if moving or anim == "rise" else int(anim_t * 1.5)]
		"cast":
			return ["boss8_cast", mini(3, int(anim_t / 0.16)) if anim_t < 0.64 else 2 + int(anim_t * 6.0) % 2]
		"sun":
			return ["boss8_sun", 0]
		"retract":
			return ["boss8_retract", 0]
		"shell":
			return ["boss8_retract", 1]
		"roll":
			return ["boss8_roll", int(anim_t * 12.0)]
		"eclipse":
			return ["boss8_eclipse", int(anim_t * 6.0)]
	return ["boss8_walk", 0]


## Quanto o chefe esta enterrado durante a entrada (0 = de pe).
func sink() -> float:
	if mode != "entry":
		return 0.0
	return 1.0 - clampf(t / (ENTRY_TIME * 0.8), 0.0, 1.0)


func visual_snapshot() -> Dictionary:
	return {
		"mode": mode,
		"t": t,
		"anim": anim,
		"anim_t": anim_t,
		"stage": stage,
		"facing": facing,
		"hand_angle": hand_angle,
		"hand_dir": hand_dir,
		"count": count,
		"gaps": gaps.duplicate(),
		"roll_dir": roll_dir,
		"shadow_angle": shadow_angle,
		"shadow_on": shadow_on,
		"shadow_spin": shadow_spin,
		"sun_power": sun_power,
		"eclipse_done": eclipse_done,
		"eclipse_frozen": eclipse_frozen,
		"moving": moving,
		"death_t": death_t,
		"death_pos": death_pos,
	}


func apply_remote_visual_snapshot(data: Dictionary) -> void:
	mode = String(data.get("mode", mode))
	t = float(data.get("t", t))
	anim = String(data.get("anim", anim))
	anim_t = float(data.get("anim_t", anim_t))
	stage = int(data.get("stage", stage))
	facing = float(data.get("facing", facing))
	hand_angle = float(data.get("hand_angle", hand_angle))
	hand_dir = float(data.get("hand_dir", hand_dir))
	count = int(data.get("count", count))
	gaps = Array(data.get("gaps", gaps)).duplicate()
	roll_dir = Vector2(data.get("roll_dir", roll_dir))
	shadow_angle = float(data.get("shadow_angle", shadow_angle))
	shadow_on = bool(data.get("shadow_on", shadow_on))
	shadow_spin = float(data.get("shadow_spin", shadow_spin))
	sun_power = float(data.get("sun_power", sun_power))
	eclipse_done = bool(data.get("eclipse_done", eclipse_done))
	eclipse_frozen = bool(data.get("eclipse_frozen", eclipse_frozen))
	moving = bool(data.get("moving", moving))
	death_t = float(data.get("death_t", death_t))
	death_pos = Vector2(data.get("death_pos", death_pos))
