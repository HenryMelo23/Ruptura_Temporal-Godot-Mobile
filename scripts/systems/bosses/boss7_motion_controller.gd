class_name RTBoss7MotionController
extends RefCounted

## Movimento da Fenix (Boss 7): voo fluido em curvas (Lissajous em volta do alvo,
## com inclinacao), rastro de posicoes para a cauda de fogo, altitude para o
## mergulho e o ataque novo "Rasante" (passagem baixa em curva que deixa fogo).

const MAX_SPEED := 270.0
const MAX_SPEED_REBORN := 320.0
const ACCEL := 560.0
const TRAIL_STEP := 0.028
const TRAIL_POINTS := 20
const SWOOP_WARN := 0.8
const SWOOP_TIME := 0.95
const SWOOP_WIDTH := 76.0
const SWOOP_COOLDOWN := 7.5
const STATE_SWOOP_WARN := "swoop_warn"
const STATE_SWOOP := "swoop"

var game: Node
var orbit_angle := 0.0
var orbit_dir := 1.0
var flip_timer := 5.0
var bank := 0.0
var altitude := 0.0
var trail: Array[Vector2] = []
var _trail_acc := 0.0
var swoop: Dictionary = {}
var shadow_pos := Vector2.ZERO
## Tempo restante da pose de pouso depois do mergulho (anim "land").
var land_left := 0.0
const LAND_TIME := 0.55
var _last_state := ""


func bind_game(p_game: Node) -> void:
	game = p_game


func reset() -> void:
	orbit_angle = 0.0
	orbit_dir = 1.0
	flip_timer = 5.0
	bank = 0.0
	altitude = 0.0
	trail.clear()
	swoop.clear()


func visual_snapshot() -> Dictionary:
	return {
		"bank": bank,
		"altitude": altitude,
		"trail": trail.duplicate(),
		"swoop": swoop.duplicate(true),
		"shadow_pos": shadow_pos,
		"land_left": land_left,
	}


func apply_remote_visual_snapshot(data: Dictionary) -> void:
	bank = clampf(float(data.get("bank", bank)), -1.0, 1.0)
	altitude = clampf(float(data.get("altitude", altitude)), 0.0, 1.0)
	trail.assign(Array(data.get("trail", [])))
	swoop = Dictionary(data.get("swoop", {})).duplicate(true)
	shadow_pos = Vector2(data.get("shadow_pos", shadow_pos))
	land_left = maxf(0.0, float(data.get("land_left", land_left)))


## Chamado todo frame da fase 7 (qualquer estado): cauda, inclinacao, altitude.
func update_common(delta: float) -> void:
	var state_now: String = String(game.boss7_state)
	if _last_state == String(game.BOSS7_STATE_DIVE) and state_now == String(game.BOSS7_STATE_RECOVERY):
		land_left = LAND_TIME
	_last_state = state_now
	land_left = maxf(0.0, land_left - delta)
	_trail_acc += delta
	if _trail_acc >= TRAIL_STEP:
		_trail_acc = 0.0
		trail.push_front(Vector2(game.boss_pos))
		while trail.size() > TRAIL_POINTS:
			trail.pop_back()
	var vel: Vector2 = game.boss7_velocity
	var target_bank: float = clampf(vel.x / MAX_SPEED, -1.0, 1.0)
	bank = lerpf(bank, target_bank, clampf(delta * 5.0, 0.0, 1.0))
	var target_alt := 0.0
	match String(game.boss7_state):
		game.BOSS7_STATE_DIVE_PREP:
			target_alt = 1.0
		game.BOSS7_STATE_DIVE_WAIT, game.BOSS7_STATE_DIVE_MARK, game.BOSS7_STATE_DIVE_FAKE:
			target_alt = 1.0
		game.BOSS7_STATE_DIVE:
			target_alt = 0.0
	var rate: float = 1.6 if target_alt > altitude else 4.5
	altitude = move_toward(altitude, target_alt, delta * rate)
	# Sombra do mergulho: caca o jogador e trava no alvo marcado.
	match String(game.boss7_state):
		game.BOSS7_STATE_DIVE_WAIT, game.BOSS7_STATE_DIVE_FAKE:
			shadow_pos = shadow_pos.lerp(game._boss_target_pos(true, 0.2), clampf(delta * 3.2, 0.0, 1.0))
		game.BOSS7_STATE_DIVE_MARK:
			shadow_pos = shadow_pos.lerp(game.boss7_target_pos, clampf(delta * 9.0, 0.0, 1.0))
		game.BOSS7_STATE_DIVE_PREP:
			shadow_pos = game.boss_pos
		_:
			shadow_pos = game.boss_pos


func speed() -> float:
	return Vector2(game.boss7_velocity).length()


## Voo fluido: orbita eliptica que respira em volta do alvo, com troca de sentido.
func update_flight(delta: float) -> void:
	var target: Vector2 = game._boss_target_pos(true, 0.18)
	flip_timer -= delta
	if flip_timer <= 0.0:
		flip_timer = game.rng.randf_range(3.8, 6.5)
		orbit_dir = -orbit_dir
	var t: float = float(game.time_alive)
	orbit_angle = wrapf(orbit_angle + orbit_dir * (0.55 + 0.25 * sin(t * 0.37)) * delta, 0.0, TAU)
	var radius: float = 300.0 + 70.0 * sin(t * 0.71)
	var goal: Vector2 = target + Vector2(cos(orbit_angle) * radius * 1.2, sin(orbit_angle) * radius * 0.62 - 50.0)
	var max_speed: float = MAX_SPEED_REBORN if game.boss7_reborn else MAX_SPEED
	var to_goal: Vector2 = goal - game.boss_pos
	var desired: Vector2 = to_goal.limit_length(max_speed) if to_goal.length() > 30.0 else to_goal * 3.0
	game.boss7_velocity = Vector2(game.boss7_velocity).move_toward(desired, ACCEL * delta)
	game.boss_pos = game.experimental_phase_controller.clamp_to_boss_encounter(game.boss_pos + game.boss7_velocity * delta, Vector2(100, 92))
	if Vector2(game.boss7_velocity).length() > 8.0:
		game.boss7_attack_dir = Vector2(game.boss7_velocity).normalized()


## Rasante: curva baixa que cruza a posicao prevista do jogador.
func start_swoop() -> void:
	var from: Vector2 = game.boss_pos
	var through: Vector2 = game._boss_target_pos(true, 0.35)
	var dir: Vector2 = (through - from).normalized()
	if dir.length() < 0.1:
		dir = Vector2.RIGHT
	var side: Vector2 = dir.orthogonal() * (1.0 if game.rng.randf() < 0.5 else -1.0)
	var to: Vector2 = game.experimental_phase_controller.clamp_to_boss_encounter(through + dir * 360.0 + side * 80.0, Vector2(100, 92))
	var control: Vector2 = through + side * 150.0
	swoop = {"from": from, "control": control, "through": through, "to": to, "t": 0.0, "last": from, "hit": false}
	game.boss7_state = STATE_SWOOP_WARN
	game.boss7_state_timer = SWOOP_WARN
	game.boss7_velocity = Vector2.ZERO
	game.boss7_cooldowns["boss7_swoop"] = game._boss_party_scaled_interval(SWOOP_COOLDOWN, 5.4)
	game._play_sfx("boss_impact", 0.02, 0.36, 1.45)


func swoop_point(u: float) -> Vector2:
	# Bezier quadratico que passa por "through" no meio.
	var a: Vector2 = swoop["from"]
	var c: Vector2 = Vector2(swoop["control"]) * 2.0 - (a + Vector2(swoop["to"])) * 0.5
	var b: Vector2 = swoop["to"]
	var inv: float = 1.0 - u
	return a * inv * inv + c * 2.0 * inv * u + b * u * u


## Retorna true quando o estado foi tratado aqui.
func update_swoop_state(delta: float) -> bool:
	match String(game.boss7_state):
		STATE_SWOOP_WARN:
			game.boss7_state_timer = maxf(0.0, float(game.boss7_state_timer) - delta)
			# Recua levemente antes de arrancar (antecipacao).
			var back: Vector2 = (Vector2(swoop["from"]) - swoop_point(0.08)).normalized()
			game.boss_pos = Vector2(swoop["from"]) + back * 26.0 * sin((1.0 - float(game.boss7_state_timer) / SWOOP_WARN) * PI * 0.5)
			if float(game.boss7_state_timer) <= 0.0:
				game.boss7_state = STATE_SWOOP
				game.boss7_state_timer = SWOOP_TIME
				swoop["last"] = game.boss_pos
			return true
		STATE_SWOOP:
			game.boss7_state_timer = maxf(0.0, float(game.boss7_state_timer) - delta)
			var u: float = 1.0 - float(game.boss7_state_timer) / SWOOP_TIME
			u = u * u * (3.0 - 2.0 * u)
			var old: Vector2 = Vector2(swoop["last"])
			var now: Vector2 = swoop_point(u)
			game.boss_pos = now
			game.boss7_velocity = (now - old) / maxf(delta, 0.001)
			if (now - old).length() > 0.5:
				game.boss7_attack_dir = (now - old).normalized()
			game._add_boss7_dive_trail(old, now)
			if not bool(swoop["hit"]) and game._distance_to_segment(game.player_pos, old, now) <= SWOOP_WIDTH * 0.5 and game._local_player_damageable_by_contact():
				swoop["hit"] = true
				game._damage_player(int(game.player_hp_max * (0.075 if game.boss7_reborn else 0.065) + 22), "boss7_swoop")
				game._apply_boss_burn(2)
				game._shove_player(game._hostile_knockback(Vector2(game.boss7_attack_dir).orthogonal() * 150.0))
			game._damage_remote_player_on_segment(old, now, SWOOP_WIDTH * 0.5, int(game.net_player_hp_max * 0.065 + 22), "boss7_swoop", swoop, "swoop")
			swoop["last"] = now
			if float(game.boss7_state_timer) <= 0.0:
				game.boss7_velocity = Vector2(game.boss7_attack_dir) * 180.0
				game.modern_boss_controller.boss7_enter_recovery(0.4)
			return true
	return false
