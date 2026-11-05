class_name RTBoss2MotionController
extends RefCounted

## Movimento do Sentinela Pinguim (Boss 2) menos previsivel.
## Na nevasca: orbita com sentido, velocidade e raio mudando ao acaso e botes pela
## tempestade que o reposicionam de surpresa. Fora dela: deslize de barriga mais
## rapido nas trocas de posicao, que pode mudar de rumo e cair no flanco do jogador.
## Autoridade do mundo (o boss_pos ja e replicado). `trail` e so visual.

const ORBIT_SPEED := 0.62
const ORBIT_SPEED_LOW_HP := 0.82
## Escondido: fundo na nevoa (fora do anel seguro de 480).
const ORBIT_RADIUS_MIN := 630.0
const ORBIT_RADIUS_MAX := 760.0
## Para cuspir, sai andando da nevasca ate a borda do anel.
const EMERGE_RADIUS_OFFSET := -24.0
const EMERGE_SPEED := 240.0
const SUBMERGE_SPEED := 175.0
const FOG_HIDE_START := 10.0
const FOG_HIDE_DEPTH := 115.0
const DASH_COOLDOWN_MIN := 5.5
const DASH_COOLDOWN_MAX := 8.5
const DASH_TIME := 0.55
const SLIDE_CHANCE := 0.55
const SLIDE_SPEED_MULT := 2.5
const SLIDE_REDIRECT_CHANCE := 0.4
const TRAIL_LIFE := 1.1
const DASH_WINDUP := 0.45

var game: Node
var orbit_dir := 1.0
var dir_timer := 3.0
var speed_mult := 1.0
var speed_timer := 1.0
var radius := 640.0
var radius_target := 640.0
var radius_timer := 2.0
var dash: Dictionary = {}
var dash_cd := 6.0
var sliding := false
var slide_redirected := false
var slide_start_distance := 0.0
var trail: Array = []


func bind_game(p_game: Node) -> void:
	game = p_game


func reset() -> void:
	orbit_dir = 1.0 if game == null or game.rng.randf() < 0.5 else -1.0
	dir_timer = 3.0
	speed_mult = 1.0
	speed_timer = 1.0
	radius = 640.0
	radius_target = 640.0
	radius_timer = 2.0
	dash.clear()
	dash_cd = 6.0
	sliding = false
	slide_redirected = false
	trail.clear()


func visual_snapshot() -> Dictionary:
	return {
		"dash": dash.duplicate(true),
		"sliding": sliding,
		"trail": trail.duplicate(true),
	}


func apply_remote_visual_snapshot(data: Dictionary) -> void:
	dash = Dictionary(data.get("dash", {})).duplicate(true)
	sliding = bool(data.get("sliding", false))
	trail = Array(data.get("trail", [])).duplicate(true)


func dashing() -> bool:
	return not dash.is_empty()


## Saindo da nevasca para atacar (janela de aviso do cuspe ou vento).
func emerging() -> bool:
	return game._boss2_ultimate_boss_visible()


## 0..1 de quanto o pinguim aparece pela posicao (1 = fora da nevoa).
func fog_reveal_at(world_pos: Vector2) -> float:
	var depth: float = world_pos.distance_to(game.boss2_ultimate_center) - float(game.BOSS2_ULTIMATE_SAFE_RADIUS)
	return 1.0 - clampf((depth - FOG_HIDE_START) / FOG_HIDE_DEPTH, 0.0, 1.0)


func in_blizzard() -> bool:
	return fog_reveal_at(game.boss_pos) < 0.5


## 0..1 durante o preparo do bote (0 = sem preparo).
func dash_windup() -> float:
	if dash.is_empty() or float(dash["t"]) >= 0.0:
		return 0.0
	return 1.0 - (-float(dash["t"]) / DASH_WINDUP)


func _leave_trail() -> void:
	var now: float = float(game.time_alive)
	if trail.is_empty() or Vector2(Dictionary(trail[-1])["pos"]).distance_to(game.boss_pos) > 26.0:
		trail.append({"pos": game.boss_pos + Vector2(0, 30), "t": now})
	while not trail.is_empty() and now - float(Dictionary(trail[0])["t"]) > TRAIL_LIFE:
		trail.pop_front()


func update_trail_only() -> void:
	var now: float = float(game.time_alive)
	while not trail.is_empty() and now - float(Dictionary(trail[0])["t"]) > TRAIL_LIFE:
		trail.pop_front()


## Substitui a orbita fixa da ultimate.
func update_orbit(delta: float) -> void:
	var center: Vector2 = game.boss2_ultimate_center
	if not dash.is_empty():
		dash["t"] = float(dash["t"]) + delta
		if float(dash["t"]) < 0.0:
			# Preparo do bote: para, olha para o destino (telegrafado na tela).
			game.boss2_facing_dir = 1.0 if Vector2(dash["to"]).x >= game.boss_pos.x else -1.0
			dash["from"] = game.boss_pos
			return
		var k: float = clampf(float(dash["t"]) / DASH_TIME, 0.0, 1.0)
		var eased: float = k * k * (3.0 - 2.0 * k)
		game.boss_pos = Vector2(dash["from"]).lerp(Vector2(dash["to"]), eased)
		game.boss2_facing_dir = 1.0 if Vector2(dash["to"]).x >= Vector2(dash["from"]).x else -1.0
		_leave_trail()
		if k >= 1.0:
			game.boss2_ultimate_orbit_angle = (game.boss_pos - center).angle()
			radius = game.boss_pos.distance_to(center)
			dash.clear()
		return
	var out: bool = emerging()
	var safe: float = float(game.BOSS2_ULTIMATE_SAFE_RADIUS)
	dir_timer -= delta
	if dir_timer <= 0.0:
		dir_timer = game.rng.randf_range(2.4, 5.2)
		if game.rng.randf() < 0.55:
			orbit_dir = -orbit_dir
	speed_timer -= delta
	if speed_timer <= 0.0:
		speed_timer = game.rng.randf_range(0.8, 2.0)
		speed_mult = game.rng.randf_range(0.45, 1.6)
	radius_timer -= delta
	if radius_timer <= 0.0:
		radius_timer = game.rng.randf_range(1.6, 3.4)
		radius_target = game.rng.randf_range(ORBIT_RADIUS_MIN, ORBIT_RADIUS_MAX)
	var angular: float = 1.0
	if out:
		# Sai andando da neve em direcao ao anel; quase nao gira enquanto sai.
		radius = move_toward(radius, safe + EMERGE_RADIUS_OFFSET, EMERGE_SPEED * delta)
		angular = 0.22
	elif radius < ORBIT_RADIUS_MIN:
		# Depois do ataque volta andando para dentro da nevasca.
		radius = move_toward(radius, radius_target, SUBMERGE_SPEED * delta)
		angular = 0.45
	else:
		radius = lerpf(radius, radius_target, clampf(delta * 1.2, 0.0, 1.0))
	var pct: float = game.boss_hp / maxf(1.0, game.boss_hp_max)
	var base: float = ORBIT_SPEED if pct > 0.4 else ORBIT_SPEED_LOW_HP
	game.boss2_ultimate_orbit_angle = wrapf(game.boss2_ultimate_orbit_angle + base * speed_mult * orbit_dir * angular * delta, 0.0, TAU)
	# Perto da borda do mapa a orbita cortaria a nevoa: desvia para um angulo que cabe
	# (assim ele nunca aparece "sem querer" fora da nevasca nem fica preso na parede).
	if not _angle_fits(game.boss2_ultimate_orbit_angle, radius):
		var fixed: float = _nearest_fitting_angle(game.boss2_ultimate_orbit_angle, radius)
		if fixed != game.boss2_ultimate_orbit_angle:
			orbit_dir = signf(angle_difference(game.boss2_ultimate_orbit_angle, fixed)) if absf(angle_difference(game.boss2_ultimate_orbit_angle, fixed)) > 0.001 else -orbit_dir
			game.boss2_ultimate_orbit_angle = fixed
	var target: Vector2 = (center + Vector2.from_angle(game.boss2_ultimate_orbit_angle) * radius).clamp(Vector2(100, 100), game.WORLD_SIZE - Vector2(100, 100))
	if out:
		game.boss2_facing_dir = 1.0 if game.player_pos.x >= game.boss_pos.x else -1.0
	else:
		game.boss2_facing_dir = 1.0 if target.x >= game.boss_pos.x else -1.0
	game.boss_pos = game.boss_pos.move_toward(target, maxf(260.0, 230.0 * speed_mult) * game._boss_card_move_multiplier() * delta)
	update_trail_only()
	dash_cd -= delta
	# Bote so escondido no fundo da neve e longe da hora de sair.
	var can_dash: bool = not out and radius >= ORBIT_RADIUS_MIN - 5.0 and float(game.boss2_ultimate_spit_timer) > float(game.BOSS2_ULTIMATE_WARNING_TIME) + 1.2
	if dash_cd <= 0.0 and can_dash:
		dash_cd = game.rng.randf_range(DASH_COOLDOWN_MIN, DASH_COOLDOWN_MAX)
		var jump: float = game.rng.randf_range(0.9, 1.6) * (1.0 if game.rng.randf() < 0.5 else -1.0)
		var dash_r: float = game.rng.randf_range(ORBIT_RADIUS_MIN, ORBIT_RADIUS_MAX)
		var new_angle: float = _nearest_fitting_angle(game.boss2_ultimate_orbit_angle + jump, dash_r)
		var to: Vector2 = (center + Vector2.from_angle(new_angle) * dash_r).clamp(Vector2(100, 100), game.WORLD_SIZE - Vector2(100, 100))
		dash = {"from": game.boss_pos, "to": to, "t": -DASH_WINDUP}
		orbit_dir = signf(jump)


func _angle_fits(angle: float, r: float) -> bool:
	var p: Vector2 = game.boss2_ultimate_center + Vector2.from_angle(angle) * r
	var lo := Vector2(100, 100)
	var hi: Vector2 = game.WORLD_SIZE - Vector2(100, 100)
	return p.x >= lo.x and p.y >= lo.y and p.x <= hi.x and p.y <= hi.y


func _nearest_fitting_angle(angle: float, r: float) -> float:
	if _angle_fits(angle, r):
		return angle
	for i in range(1, 32):
		var step: float = float(i) * 0.1
		if _angle_fits(angle + step, r):
			return wrapf(angle + step, 0.0, TAU)
		if _angle_fits(angle - step, r):
			return wrapf(angle - step, 0.0, TAU)
	return angle


## Reposicionamento normal: decide se vai de barriga.
func begin_reposition() -> void:
	var distance: float = game.boss_pos.distance_to(game.boss2_target_position)
	sliding = distance > 160.0 and game.rng.randf() < SLIDE_CHANCE
	slide_redirected = false
	slide_start_distance = distance
	if sliding:
		game.boss2_action_timer = maxf(0.7, distance / maxf(1.0, game.boss2_walk_speed * SLIDE_SPEED_MULT) + 0.35)


func reposition_speed_mult() -> float:
	return SLIDE_SPEED_MULT if sliding else 1.0


func update_reposition() -> void:
	if not sliding:
		update_trail_only()
		return
	_leave_trail()
	var remaining: float = game.boss_pos.distance_to(game.boss2_target_position)
	if not slide_redirected and remaining < slide_start_distance * 0.6:
		slide_redirected = true
		if game.rng.randf() < SLIDE_REDIRECT_CHANCE:
			# Muda de rumo e cai no flanco do jogador.
			var to_player: Vector2 = (game.player_pos - game.boss_pos).normalized()
			var side: Vector2 = to_player.orthogonal() * (1.0 if game.rng.randf() < 0.5 else -1.0)
			var flank: Vector2 = game.player_pos + side * game.rng.randf_range(190.0, 260.0)
			game.boss2_target_position = game.experimental_phase_controller.clamp_to_boss_encounter(flank, Vector2(150, 130))
			game.boss2_action_timer = maxf(float(game.boss2_action_timer), game.boss_pos.distance_to(game.boss2_target_position) / maxf(1.0, game.boss2_walk_speed * SLIDE_SPEED_MULT) + 0.3)


func end_reposition() -> void:
	sliding = false
