class_name Phase3EnemyController
extends Node

# Owns Phase 3 enemy behavior. The world authority calls this once per enemy;
# clients receive the resulting enemy/projectile snapshots through the existing
# replication path.

var game: Node = null


func bind_game(p_game: Node) -> void:
	game = p_game


func update_enemy(enemy: Dictionary, delta: float) -> void:
	if game == null:
		return
	enemy["phase3_fervor_timer"] = maxf(0.0, float(enemy.get("phase3_fervor_timer", 0.0)) - delta)
	enemy["phase3_relic_pulse"] = maxf(0.0, float(enemy.get("phase3_relic_pulse", 0.0)) - delta)
	var kind := String(enemy.get("type", game.ENEMY_COMMON))
	if kind == game.ENEMY_DEVOTO and game.phase3_ritual_pulse_controller.update_devotee(enemy, delta):
		return
	var target_pos: Vector2 = game._get_enemy_target_pos(enemy)
	match kind:
		game.ENEMY_DEVOTO:
			_update_devoto(enemy, delta, target_pos)
		game.ENEMY_INCENSARIO:
			_update_incensario(enemy, delta, target_pos)
		game.ENEMY_FLAGELANTE:
			_update_flagelante(enemy, delta, target_pos)
		game.ENEMY_SALMODIANTE:
			_update_salmodiante(enemy, delta, target_pos)
		game.ENEMY_RELICARIO:
			_update_relicario(enemy, delta)
		game.ENEMY_COMMON:
			_update_basic_shot(enemy, delta, target_pos)


func movement_speed_multiplier(enemy: Dictionary) -> float:
	return game.PHASE3_RELIC_FERVOR_SPEED_MULT if float(enemy.get("phase3_fervor_timer", 0.0)) > 0.0 else 1.0


func _update_devoto(enemy: Dictionary, delta: float, target_pos: Vector2) -> void:
	enemy["miasma_cd"] = float(enemy.get("miasma_cd", 0.0)) - delta
	if float(enemy["miasma_cd"]) <= 0.0:
		enemy["miasma_cd"] = 0.26
		game._add_phase3_miasma(Vector2(enemy["pos"]), game.rng.randf_range(18.0, 26.0), 2.5, 0.012)
	_update_basic_shot(enemy, delta, target_pos)


func _update_incensario(enemy: Dictionary, delta: float, target_pos: Vector2) -> void:
	_move_at_range(enemy, target_pos, delta, 220.0, 430.0)
	enemy["shoot_cd"] = float(enemy.get("shoot_cd", 1.0)) - delta
	if float(enemy["shoot_cd"]) <= 0.0 and float(enemy.get("prepare", 0.0)) <= 0.0:
		enemy["prepare"] = 0.55
		enemy["miasma_target"] = target_pos
	if float(enemy.get("prepare", 0.0)) > 0.0:
		enemy["prepare"] = float(enemy["prepare"]) - delta
		if float(enemy["prepare"]) <= 0.0:
			game._add_phase3_miasma(Vector2(enemy.get("miasma_target", game.player_pos)), game.rng.randf_range(58.0, 72.0), game.rng.randf_range(2.8, 3.5), 0.015)
			enemy["shoot_cd"] = game.rng.randf_range(2.2, 3.0)


func _update_flagelante(enemy: Dictionary, delta: float, target_pos: Vector2) -> void:
	enemy["phase3_surge_cd"] = float(enemy.get("phase3_surge_cd", 0.0)) - delta
	enemy["phase3_surge_timer"] = maxf(0.0, float(enemy.get("phase3_surge_timer", 0.0)) - delta)
	if float(enemy["phase3_surge_cd"]) <= 0.0:
		enemy["phase3_surge_cd"] = game.rng.randf_range(game.PHASE3_FLAGELANTE_SURGE_MIN_INTERVAL, game.PHASE3_FLAGELANTE_SURGE_MAX_INTERVAL)
		enemy["phase3_surge_timer"] = game.PHASE3_FLAGELANTE_SURGE_TIME
		game._spawn_radial_particles(Vector2(enemy["pos"]), Color(0.62, 0.86, 0.24), 5)
	var direct := (target_pos - Vector2(enemy["pos"])).normalized()
	if direct.length() <= 0.01:
		direct = Vector2.RIGHT
	var weave: float = sin(float(game.time_alive) * 5.2 + float(int(enemy.get("uid", 0)) % 29)) * float(game.PHASE3_FLAGELANTE_WEAVE)
	var move_dir: Vector2 = (direct + direct.orthogonal() * weave).normalized()
	var surge_mult: float = float(game.PHASE3_FLAGELANTE_SURGE_SPEED_MULT) if float(enemy["phase3_surge_timer"]) > 0.0 else 1.0
	var speed_mult: float = surge_mult * movement_speed_multiplier(enemy)
	enemy["pos"] = (Vector2(enemy["pos"]) + move_dir * float(enemy["speed"]) * speed_mult * delta).clamp(Vector2(40.0, 40.0), game.WORLD_SIZE - Vector2(40.0, 40.0))
	enemy["facing_dir"] = move_dir
	enemy["last_move_dir"] = move_dir
	enemy["parado"] = true


func _update_salmodiante(enemy: Dictionary, delta: float, target_pos: Vector2) -> void:
	_move_at_range(enemy, target_pos, delta, 250.0, 460.0)
	enemy["shoot_cd"] = float(enemy.get("shoot_cd", 1.0)) - delta
	if float(enemy["shoot_cd"]) <= 0.0 and float(enemy.get("phase3_chant_prepare", 0.0)) <= 0.0:
		enemy["phase3_chant_prepare"] = game.PHASE3_SALMODIANTE_WINDUP
		enemy["phase3_chant_target"] = target_pos
	if float(enemy.get("phase3_chant_prepare", 0.0)) <= 0.0:
		return
	enemy["phase3_chant_prepare"] = float(enemy["phase3_chant_prepare"]) - delta
	if float(enemy["phase3_chant_prepare"]) > 0.0:
		return
	var origin := Vector2(enemy["pos"])
	var base_dir := (Vector2(enemy.get("phase3_chant_target", target_pos)) - origin).normalized()
	if base_dir.length() <= 0.01:
		base_dir = Vector2.RIGHT
	var damage: float = float(game.player_hp_max) * float(game.PHASE3_SALMODIANTE_DAMAGE_RATIO) + float(game.enemy_far_damage) * 0.75
	for angle in [-game.PHASE3_SALMODIANTE_FAN_ANGLE, 0.0, game.PHASE3_SALMODIANTE_FAN_ANGLE]:
		game._spawn_phase3_projectile(origin, base_dir.rotated(float(angle)), damage, "rat_shot", 0.72)
	enemy["shoot_cd"] = game.rng.randf_range(game.PHASE3_SALMODIANTE_MIN_INTERVAL, game.PHASE3_SALMODIANTE_MAX_INTERVAL)


func _update_relicario(enemy: Dictionary, delta: float) -> void:
	enemy["phase3_relic_cd"] = float(enemy.get("phase3_relic_cd", 0.0)) - delta
	if float(enemy["phase3_relic_cd"]) > 0.0:
		return
	enemy["phase3_relic_cd"] = game.rng.randf_range(game.PHASE3_RELIC_MIN_INTERVAL, game.PHASE3_RELIC_MAX_INTERVAL)
	enemy["phase3_relic_pulse"] = 0.7
	var origin := Vector2(enemy["pos"])
	var empowered := 0
	for ally in game.enemies:
		if ally == enemy or float(ally.get("hp", 0.0)) <= 0.0:
			continue
		if origin.distance_to(Vector2(ally.get("pos", origin))) > game.PHASE3_RELIC_RADIUS:
			continue
		ally["phase3_fervor_timer"] = maxf(float(ally.get("phase3_fervor_timer", 0.0)), game.PHASE3_RELIC_FERVOR_TIME)
		empowered += 1
		if empowered >= game.PHASE3_RELIC_MAX_TARGETS:
			break
	if empowered > 0:
		game._add_text("FERVOR", origin + Vector2(0.0, -68.0), Color(0.78, 1.0, 0.34), 0.6, 14)
		game._spawn_radial_particles(origin, Color(0.7, 0.9, 0.28), 7)


func _update_basic_shot(enemy: Dictionary, delta: float, target_pos: Vector2) -> void:
	enemy["shoot_cd"] = float(enemy.get("shoot_cd", 1.0)) - delta
	if float(enemy["shoot_cd"]) > 0.0:
		return
	enemy["shoot_cd"] = 1.5
	if game.rng.randf() <= 0.1:
		var direction := (target_pos - Vector2(enemy["pos"])).normalized()
		if direction.length() <= 0.01:
			direction = Vector2.RIGHT
		game._spawn_phase3_projectile(Vector2(enemy["pos"]), direction, game.player_hp_max * 0.07 + game.enemy_far_damage, "rat_shot", 0.62)


func _move_at_range(enemy: Dictionary, target_pos: Vector2, delta: float, min_range: float, max_range: float) -> void:
	var origin := Vector2(enemy["pos"])
	var dist := origin.distance_to(target_pos)
	var radial := (target_pos - origin).normalized()
	if radial.length() <= 0.01:
		radial = Vector2.RIGHT
	var move_dir := radial.orthogonal() * float(enemy.get("strafe", 1.0))
	if dist < min_range:
		move_dir = -radial
	elif dist > max_range:
		move_dir = radial
	if move_dir.length() > 0.05:
		move_dir = move_dir.normalized()
		enemy["pos"] = (origin + move_dir * float(enemy["speed"]) * movement_speed_multiplier(enemy) * delta).clamp(Vector2(40.0, 40.0), game.WORLD_SIZE - Vector2(40.0, 40.0))
		enemy["facing_dir"] = move_dir
		enemy["last_move_dir"] = move_dir
	enemy["parado"] = true
