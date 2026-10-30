class_name RTBoss6AnimationPresentation
extends RefCounted

const ATTACK_FPS := 7.5


static func active_texture(game: Node2D) -> Texture2D:
	var key := _attack_key(game)
	if key == "":
		return null
	var frames: Array = game.textures.get(key, [])
	if frames.is_empty():
		return null
	var frame_index := 0
	match game.boss6_state:
		game.BOSS6_STATE_TELEGRAPH:
			frame_index = mini(1, int(game.boss_phase * 0.55) % 2)
		game.BOSS6_STATE_EXECUTING:
			frame_index = 1 + int(game.boss_phase * ATTACK_FPS * 0.16) % 2
		game.BOSS6_STATE_RECOVERY:
			frame_index = 3
		_:
			frame_index = int(game.boss_phase) % frames.size()
	return frames[mini(frame_index, frames.size() - 1)] as Texture2D


static func draw_position(game: Node2D) -> Vector2:
	var offset := Vector2.ZERO
	if game.boss6_state == game.BOSS6_STATE_TRANSITION:
		var pulse := sin(game.boss6_state_timer * 16.0)
		offset = Vector2(pulse * 5.0, -absf(pulse) * 5.0)
	elif game.boss6_current_ability == game.BOSS6_ABILITY_CARNAGE_TIDE and game.boss6_state == game.BOSS6_STATE_EXECUTING:
		offset = Vector2(0.0, -8.0 - sin(game.boss_phase * 1.8) * 5.0)
	return game.boss_pos + offset


static func draw_stage_bar(game: Node2D, pos: Vector2, width: float) -> void:
	for segment in range(1, 3):
		var x := pos.x + width * float(segment) / 3.0
		game.draw_line(Vector2(x, pos.y - 2.0), Vector2(x, pos.y + 11.0), Color(0.08, 0.025, 0.015, 0.96), 4.0)
		game.draw_line(Vector2(x, pos.y - 1.0), Vector2(x, pos.y + 10.0), Color(1.0, 0.86, 0.48, 0.92), 1.5)
	var stage_color := Color(1.0, 0.76, 0.26)
	if game.boss6_stage == 2:
		stage_color = Color(0.68, 1.0, 0.22)
	elif game.boss6_stage >= 3:
		stage_color = Color(1.0, 0.28, 0.12)
	game._draw_centered("ESTAGIO %d" % game.boss6_stage, pos + Vector2(width * 0.5, -10.0), 12, stage_color)


static func draw_acid_target_notches(game: Node2D, screen: Vector2, radius: float, target_index: int) -> void:
	var color := Color(0.88, 1.0, 0.68, 0.78)
	for notch in range(3):
		var angle := float(notch) * TAU / 3.0 + float(target_index) * 0.42
		game.draw_line(screen + Vector2.from_angle(angle) * radius * 0.72, screen + Vector2.from_angle(angle) * radius * 0.94, color, 3.0, true)


static func draw_scythe_target_warning(game: Node2D, origin: Vector2, target: Vector2, camera: Vector2, age: float) -> void:
	var alpha: float = 0.2 + 0.32 * (1.0 - age / 0.62)
	var target_screen := target - camera
	game.draw_dashed_line(origin - camera, target_screen, Color(0.78, 1.0, 0.46, alpha), 3.0, 18.0, true)
	game.draw_arc(target_screen, 34.0 + age * 18.0, 0.0, TAU, 36, Color(0.9, 1.0, 0.7, alpha + 0.18), 2.5)


static func draw_carnage_target_ring(game: Node2D, ground: Vector2, radius: float, target_index: int) -> void:
	var angle := float(target_index) * 0.5
	game.draw_arc(ground, radius, angle, TAU + angle, 48, Color(0.84, 1.0, 0.54, 0.68), 2.5)


static func draw_acid_or_incubation(game: Node2D, camera: Vector2, attack: Dictionary, kind: String, age: float) -> void:
	var warn_time: float = game.BOSS6_ACID_BLOOM_FALL_TIME if kind == game.BOSS6_ABILITY_ACID_BLOOM else 0.9
	var progress := clampf(age / warn_time, 0.0, 1.0)
	for spot in Array(attack.get("spots", [])):
		var spot_data: Dictionary = Dictionary(spot) if spot is Dictionary else {"pos": Vector2(spot), "target_index": 0}
		var screen := Vector2(spot_data.get("pos", game.player_pos)) - camera
		var color := Color(0.42, 1.0, 0.12, 0.7) if kind == game.BOSS6_ABILITY_ACID_BLOOM else Color(1.0, 0.62, 0.28, 0.64)
		var radius: float = game.BOSS6_ACID_BLOOM_RADIUS if kind == game.BOSS6_ABILITY_ACID_BLOOM else 42.0
		game.draw_circle(screen, radius * (0.18 + progress * 0.82), Color(color.r, color.g, color.b, 0.05 + progress * 0.1))
		game.draw_arc(screen, radius * (0.22 + progress * 0.78), -game.time_alive * 2.2, TAU - game.time_alive * 2.2, 72, color, 2.4)
		if kind == game.BOSS6_ABILITY_ACID_BLOOM:
			draw_acid_target_notches(game, screen, radius, int(spot_data.get("target_index", 0)))
		if kind == game.BOSS6_ABILITY_ACID_BLOOM and not bool(attack.get("spawned", false)):
			var high: Vector2 = (game.boss_pos - camera) + Vector2(0, -170.0 - sin(progress * PI) * 80.0)
			var spit_pos: Vector2 = high.lerp(screen, progress)
			game.draw_line(game.boss_pos - camera, spit_pos, Color(0.42, 1.0, 0.12, 0.24), 3.0, true)
			game.draw_circle(spit_pos, 9.0 + progress * 5.0, Color(0.58, 1.0, 0.16, 0.84))


static func draw_scythes(game: Node2D, camera: Vector2, attack: Dictionary, age: float) -> void:
	var origin := Vector2(attack.get("origin", game.boss_pos))
	var duration := float(attack.get("duration", 2.85))
	var warned_peers: Dictionary = {}
	for bone in attack.get("bones", []):
		var bone_data: Dictionary = bone
		var target_peer := int(bone_data.get("target_peer", 0))
		if age < 0.62 and target_peer > 0 and not warned_peers.has(target_peer):
			warned_peers[target_peer] = true
			draw_scythe_target_warning(game, origin, Vector2(bone_data.get("target_pos", origin)), camera, age)
		var pos: Vector2 = game._boss6_vertebral_scythe_pos(origin, bone_data, age, duration) - camera
		var direction := Vector2(bone_data.get("dir", Vector2.RIGHT)).normalized()
		if direction.length() <= 0.05:
			direction = Vector2.RIGHT
		var spin: float = game.time_alive * 10.0 + float(bone_data.get("phase", 0.0))
		var bone_axis := direction.rotated(sin(spin) * 0.62)
		var side := bone_axis.orthogonal()
		var p0: Vector2 = pos - bone_axis * 18.0
		var p1: Vector2 = pos + bone_axis * 18.0
		game.draw_line(p0, p1, Color(0.1, 0.08, 0.05, 0.62), 10.0, true)
		game.draw_line(p0, p1, Color(0.78, 0.74, 0.58, 0.92), 5.0, true)
		game.draw_circle(p0 + side * 3.8, 4.4, Color(0.92, 0.86, 0.68, 0.88))
		game.draw_circle(p0 - side * 3.8, 4.4, Color(0.92, 0.86, 0.68, 0.88))
		game.draw_circle(p1 + side * 3.8, 4.0, Color(0.92, 0.86, 0.68, 0.88))
		game.draw_circle(p1 - side * 3.8, 4.0, Color(0.92, 0.86, 0.68, 0.88))


static func draw_carnage(game: Node2D, camera: Vector2, attack: Dictionary) -> void:
	for drop in Array(attack.get("drops", [])):
		var drop_data: Dictionary = drop
		var fall := clampf(float(drop_data.get("fall", 0.0)) / maxf(0.01, float(drop_data.get("max", 0.68))), 0.0, 1.0)
		var ground := Vector2(drop_data.get("pos", game.player_pos)) - camera
		var high: Vector2 = (game.boss_pos - camera) + Vector2(0, -180.0)
		var pos: Vector2 = high.lerp(ground, 1.0 - fall)
		game.draw_line(high, pos, Color(0.62, 1.0, 0.16, 0.18 + 0.22 * (1.0 - fall)), 3.0, true)
		game.draw_circle(ground, game.BOSS6_CARNAGE_POOL_RADIUS * (0.3 + (1.0 - fall) * 0.7), Color(0.5, 1.0, 0.1, 0.09 + 0.08 * (1.0 - fall)))
		draw_carnage_target_ring(game, ground, game.BOSS6_CARNAGE_POOL_RADIUS * (0.72 + (1.0 - fall) * 0.28), int(drop_data.get("target_index", 0)))
		game.draw_circle(pos, 10.0 + (1.0 - fall) * 5.0, Color(0.58, 1.0, 0.16, 0.84))


static func _attack_key(game: Node2D) -> String:
	if game.boss6_state not in [game.BOSS6_STATE_TELEGRAPH, game.BOSS6_STATE_EXECUTING, game.BOSS6_STATE_RECOVERY]:
		return ""
	match game.boss6_current_ability:
		game.BOSS6_ABILITY_SCYTHES:
			return "boss6_rework_stage1_attack"
		game.BOSS6_ABILITY_ACID_BLOOM:
			return "boss6_rework_stage2_attack"
		game.BOSS6_ABILITY_CARNAGE_TIDE:
			return "boss6_rework_stage3_attack"
	return ""
