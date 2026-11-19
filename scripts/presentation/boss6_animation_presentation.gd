class_name RTBoss6AnimationPresentation
extends RefCounted

const ATTACK_FPS := 7.5
const Controller = preload("res://scripts/systems/bosses/boss6_controller.gd")
const MistGuide = preload("res://scripts/presentation/mist_guide_presentation.gd")
const REWORK_DIR := "res://assets/sprites/boss6_rework/"
## Celula da arte nova (448x448, pes em y=420): escala fixa para o corpo (~300 px de arte) ficar ~270 px.
const BODY_CELL := 448.0
const BODY_FEET_Y := 420.0
const BODY_SCALE := 0.9
## Centro dos pes do idle novo em relacao ao centro da celula, ja em escala de tela.
const BODY_FEET_CENTER_X := (257.0 - 224.0) * BODY_SCALE
## Quadros novos que o Codex desenhou fora do centro (corpo inteiro deslocado na celula):
## desloca em pixels da arte para os pes voltarem ao centro dos pes do idle (x~254).
const FRAME_SHIFT_X := {"boss6_scythe_02.png": 96.0, "boss6_scythe_03.png": -57.0}
## boss6_crawl_03 afunda o corpo ~80 px (cabeca cai muito) -> fica fora do ciclo ate ser refeito.
const CRAWL_ORDER := [0, 1, 2, 0, 4, 5]
## Arte antiga de ataque (440x398): corpo menor, pes flutuando e deslocado. Medido contra o
## boss6_idle_00 (pernas sobrepostas): escala = encaixe antigo x 1,18; ancora = (centro dos pes, linha dos pes).
const LEGACY_SCALE_BOOST := 1.18
const LEGACY_FEET := {
	"boss6_stage1_attack_00.png": Vector2(222.0, 345.0), "boss6_stage1_attack_01.png": Vector2(237.0, 346.0),
	"boss6_stage1_attack_02.png": Vector2(241.0, 346.0), "boss6_stage1_attack_03.png": Vector2(236.0, 346.0),
	"boss6_stage2_attack_00.png": Vector2(222.0, 358.0), "boss6_stage2_attack_01.png": Vector2(243.0, 356.0),
	"boss6_stage2_attack_02.png": Vector2(253.0, 360.0), "boss6_stage2_attack_03.png": Vector2(230.0, 359.0),
	"boss6_stage3_attack_00.png": Vector2(221.0, 340.0), "boss6_stage3_attack_01.png": Vector2(242.0, 341.0),
	"boss6_stage3_attack_02.png": Vector2(243.0, 332.0), "boss6_stage3_attack_03.png": Vector2(221.0, 345.0),
}


static func active_texture(game: Node2D) -> Texture2D:
	var body: Texture2D = body_texture(game)
	if body != null:
		return body
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
	if kind == game.BOSS6_ABILITY_ACID_BLOOM and attack.has("origin"):
		draw_spit(game, camera, attack, age)
		return
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


## Foices Vertebrais: meias-luas de osso correndo em cone a partir da Matriarca.
static func draw_scythes(game: Node2D, camera: Vector2, attack: Dictionary, age: float) -> void:
	var origin: Vector2 = Vector2(attack.get("origin", game.boss_pos)) - camera
	var stage: int = int(attack.get("stage", game.boss6_stage))
	var low: bool = game._runtime_visual_budget_active()
	var shard: Texture2D = _optional_texture(game, "boss6_bone_shard")
	var slash: Texture2D = _optional_texture(game, "boss6_scythe_slash")
	for wave_value in Array(attack.get("waves", [])):
		var wave: Dictionary = wave_value
		var radius: float = Controller.scythe_wave_radius(wave, age, stage)
		if radius < 0.0 or radius > Controller.SCYTHE_MAX_RADIUS:
			continue
		var angle: float = float(wave.get("angle", 0.0))
		var arc: float = float(wave.get("arc", Controller.SCYTHE_ARC_SOLO))
		var side: float = float(wave.get("side", 1.0))
		var progress: float = (radius - Controller.SCYTHE_START_RADIUS) / (Controller.SCYTHE_MAX_RADIUS - Controller.SCYTHE_START_RADIUS)
		var fade: float = 1.0 - smoothstep(0.75, 1.0, progress)
		var from_a: float = angle - arc * 0.5
		var to_a: float = angle + arc * 0.5
		# Rastro varrido atras da onda.
		game.draw_arc(origin, maxf(1.0, radius - 30.0), from_a, to_a, 40, Color(0.3, 0.12, 0.02, 0.28 * fade), 40.0, true)
		game.draw_arc(origin, radius, from_a, to_a, 44, Color(0.12, 0.05, 0.02, 0.7 * fade), Controller.SCYTHE_BAND * 1.5, true)
		game.draw_arc(origin, radius, from_a, to_a, 44, Color(0.9, 0.82, 0.62, (0.4 if shard != null else 0.92) * fade), Controller.SCYTHE_BAND * (0.45 if shard != null else 0.8), true)
		game.draw_arc(origin, radius + Controller.SCYTHE_BAND * 0.42, from_a, to_a, 44, Color(1.0, 0.66, 0.18, 0.9 * fade), 4.0, true)
		# A ponta que "corta" anda do lado da varrida e deixa o brilho mais forte.
		var lead: float = to_a if side > 0.0 else from_a
		var lead_pos: Vector2 = origin + Vector2.from_angle(lead) * radius
		MistGuide.draw_blob(game, lead_pos, Vector2(70.0, 70.0), Color(1.0, 0.7, 0.24, 0.6 * fade))
		var shards: int = (7 if low else 13) if shard != null else (5 if low else 9)
		for index in range(shards):
			var u: float = (float(index) + 0.5) / float(shards)
			var a2: float = lerpf(from_a, to_a, u)
			var p: Vector2 = origin + Vector2.from_angle(a2) * (radius + Controller.SCYTHE_BAND * 0.1)
			if shard != null:
				game.draw_set_transform(p, a2, Vector2.ONE)
				game.draw_texture_rect(shard, Rect2(Vector2(-30.0, -30.0), Vector2(60.0, 60.0)), false, Color(1.0, 1.0, 1.0, fade))
				game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				var dir := Vector2.from_angle(a2)
				var tang := dir.orthogonal()
				game.draw_colored_polygon(PackedVector2Array([p + dir * 16.0, p - dir * 6.0 + tang * 6.0, p - dir * 6.0 - tang * 6.0]), Color(0.96, 0.9, 0.72, 0.95 * fade))
		# Clarao de corte no instante da varrida.
		var local: float = age - float(wave.get("start", 0.0))
		if local < 0.22:
			var flash: float = 1.0 - local / 0.22
			if slash != null:
				# A arte tem o fio do lado -x: gira 180 graus para o fio apontar para o alvo.
				game.draw_set_transform(origin, angle + PI, Vector2(1.0, side) * (0.9 + 0.25 * (1.0 - flash)))
				game.draw_texture_rect(slash, Rect2(Vector2(-150.0, -128.0), Vector2(256.0, 256.0)), false, Color(1.0, 1.0, 1.0, flash))
				game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				game.draw_arc(origin, 110.0, from_a, to_a, 32, Color(1.0, 0.92, 0.7, 0.85 * flash), 10.0 * flash + 2.0, true)


## Aviso das foices: cone em direcao a cada alvo com o lado da primeira varrida.
static func draw_scythe_telegraph(game: Node2D, camera: Vector2, attack: Dictionary, age: float) -> bool:
	if String(attack.get("kind", "")) == game.BOSS6_ABILITY_TAIL + "_telegraph":
		_draw_tail_telegraph(game, camera, attack, age)
		return true
	if String(attack.get("kind", "")) == game.BOSS6_ABILITY_ACID_BLOOM + "_telegraph":
		_draw_spit_telegraph(game, camera, attack, age)
		return true
	if String(attack.get("kind", "")) != game.BOSS6_ABILITY_SCYTHES + "_telegraph":
		return false
	var origin: Vector2 = game.boss_pos - camera
	var duration: float = maxf(0.01, float(attack.get("duration", 0.9)))
	var p: float = clampf(age / duration, 0.0, 1.0)
	var target: Vector2 = Vector2(attack.get("target", game.player_pos)) - camera
	var angle: float = (target - origin).angle()
	var arc: float = Controller.SCYTHE_ARC_SOLO if not game.is_multiplayer else Controller.SCYTHE_ARC_TEAM
	var reach: float = Controller.SCYTHE_MAX_RADIUS * (0.35 + 0.65 * p)
	var points := PackedVector2Array([origin])
	for index in range(19):
		points.append(origin + Vector2.from_angle(angle - arc * 0.5 + arc * float(index) / 18.0) * reach)
	game.draw_colored_polygon(points, Color(1.0, 0.6, 0.16, 0.05 + 0.1 * p))
	game.draw_arc(origin, reach, angle - arc * 0.5, angle + arc * 0.5, 36, Color(1.0, 0.78, 0.4, 0.4 + 0.45 * p), 2.5, true)
	game.draw_line(origin, points[1], Color(1.0, 0.7, 0.3, 0.45 * p), 2.0, true)
	game.draw_line(origin, points[points.size() - 1], Color(1.0, 0.7, 0.3, 0.45 * p), 2.0, true)
	for ring in range(3):
		var r: float = fposmod(p * 1.6 + float(ring) / 3.0, 1.0) * reach
		game.draw_arc(origin, r, angle - arc * 0.5, angle + arc * 0.5, 24, Color(0.96, 0.9, 0.7, 0.35 * (1.0 - r / reach)), 2.0, true)
	return true


## Camada do chao: monte/aviso/erupcao e a sombra (some conforme afunda).
static func draw_ground_layer(game: Node2D, camera: Vector2, texture: Texture2D, max_size: Vector2) -> void:
	draw_burrow(game, camera)
	if sink(game) < 0.5:
		draw_shadow(game, texture, game.boss_pos - camera, max_size, 0.44 * (1.0 - sink(game)))


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



## Corpo novo (idle/rastejar/mergulho/emergir) quando a arte existir; null = caminho antigo.
static func body_texture(game: Node2D) -> Texture2D:
	var ctrl = game.boss6_controller
	var ai: Dictionary = game.boss6_ai_state
	var current: String = ctrl.mode()
	var t: float = float(ai.get("t", 0.0))
	match current:
		Controller.MODE_SUBMERGE:
			return _frame(game, "boss6_rework_submerge", int(t / Controller.SUBMERGE_TIME * 3.0))
		Controller.MODE_TRAVEL, Controller.MODE_WARN:
			return _frame(game, "boss6_rework_submerge", 2)
		Controller.MODE_EMERGE:
			return _frame(game, "boss6_rework_emerge", int(t / Controller.EMERGE_TIME * 3.0))
	if game.boss6_state in [game.BOSS6_STATE_TELEGRAPH, game.BOSS6_STATE_EXECUTING, game.BOSS6_STATE_RECOVERY]:
		var action: Texture2D = _action_frame(game)
		if action != null:
			return action
	if game.boss6_state in [game.BOSS6_STATE_TELEGRAPH, game.BOSS6_STATE_EXECUTING] and _attack_key(game) != "":
		return null
	if current == Controller.MODE_CRAWL:
		var crawl: Texture2D = _frame(game, "boss6_rework_crawl", int(CRAWL_ORDER[posmod(int(float(ai.get("step", 0.0)) * 6.0), CRAWL_ORDER.size())]))
		if crawl != null:
			return crawl
		return _form_frame(game, int(float(ai.get("step", 0.0)) * 8.0))
	return _frame(game, "boss6_rework_idle", int(game.boss_phase * 0.6))


static func _frame(game: Node2D, key: String, index: int) -> Texture2D:
	if not game.textures.has(key):
		if not ResourceLoader.exists(REWORK_DIR + key.replace("boss6_rework_", "boss6_") + "_00.png"):
			return null
		game._ensure_runtime_texture(key)
	var frames: Array = game.textures.get(key, [])
	if frames.is_empty():
		return null
	return frames[clampi(index, 0, frames.size() - 1) if key != "boss6_rework_idle" and key != "boss6_rework_crawl" else posmod(index, frames.size())] as Texture2D


static func _form_frame(game: Node2D, index: int) -> Texture2D:
	var frames: Array = game.textures.get(game._boss6_form_key(), [])
	if frames.is_empty():
		return null
	return frames[posmod(index, frames.size())] as Texture2D


static func has_burrow_art() -> bool:
	return ResourceLoader.exists(REWORK_DIR + "boss6_submerge_00.png")


static func should_flip_h(game: Node2D) -> bool:
	return game.boss6_controller.facing() > 0.0


static func sink(game: Node2D) -> float:
	return game.boss6_controller.sink_ratio()


## Corpo com espelhamento e, sem a arte de mergulho, afundamento por recorte na linha do chao.
static func draw_body(game: Node2D, texture: Texture2D, center: Vector2, max_size: Vector2, modulate: Color) -> void:
	if texture == null:
		return
	var amount: float = sink(game)
	if game.boss6_controller.is_burrowed():
		return
	var tex_size: Vector2 = texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var ground_y: float = max_size.y * 0.5
	var rect: Rect2 = body_rect(texture, max_size)
	var draw_size: Vector2 = rect.size
	var flip := Vector2(-1.0, 1.0) if should_flip_h(game) else Vector2.ONE
	var wobble: float = 0.0
	if game.boss6_controller.mode() == Controller.MODE_CRAWL:
		wobble = -absf(sin(float(game.boss6_ai_state.get("step", 0.0)) * TAU)) * 4.0
	game.draw_set_transform(center + Vector2(0.0, wobble), 0.0, flip)
	if amount <= 0.01 or has_burrow_art():
		game.draw_texture_rect(texture, rect, false, modulate)
	else:
		var visible: float = clampf(1.0 - amount, 0.0, 1.0)
		var shown := Vector2(draw_size.x, draw_size.y * visible)
		var top: float = ground_y - shown.y
		game.draw_texture_rect_region(texture, Rect2(Vector2(rect.position.x, top), shown), Rect2(Vector2.ZERO, Vector2(tex_size.x, tex_size.y * visible)), modulate)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if amount > 0.01:
		_draw_mud_line(game, center + Vector2(0.0, ground_y - 6.0), draw_size.x * 0.48, amount)


static func _draw_mud_line(game: Node2D, center: Vector2, half_width: float, amount: float) -> void:
	var t: float = float(Time.get_ticks_msec()) * 0.001
	MistGuide.draw_blob(game, center, Vector2(half_width * 2.4, 46.0), Color(0.2, 0.16, 0.06, 0.75))
	for index in range(7):
		var x: float = lerpf(-half_width, half_width, float(index) / 6.0)
		var bob: float = sin(t * 9.0 + float(index) * 1.7) * 3.0
		game.draw_circle(center + Vector2(x, bob), 6.0 + float(index % 3) * 2.0, Color(0.36, 0.3, 0.12, 0.9))
		game.draw_circle(center + Vector2(x * 0.7, -6.0 - absf(bob) * 2.0 * amount), 2.5, Color(0.6, 1.0, 0.24, 0.8 * amount))


## Monte de lama correndo, aviso de emersao e erupcao (camada do chao).
static func draw_burrow(game: Node2D, camera: Vector2) -> void:
	var ctrl = game.boss6_controller
	var ai: Dictionary = game.boss6_ai_state
	var current: String = ctrl.mode()
	var t: float = float(Time.get_ticks_msec()) * 0.001
	var state_t: float = float(ai.get("t", 0.0))
	if current in [Controller.MODE_TRAVEL, Controller.MODE_WARN]:
		var mound: Vector2 = Vector2(ai.get("mound", game.boss_pos)) - camera
		if current == Controller.MODE_WARN:
			var warn: float = clampf(state_t / Controller.WARN_TIME, 0.0, 1.0)
			var flash: float = 0.5 + 0.5 * sin(t * 26.0)
			game.draw_circle(mound, Controller.EMERGE_RADIUS, Color(0.5, 1.0, 0.16, 0.08 + 0.12 * warn))
			game.draw_arc(mound, Controller.EMERGE_RADIUS, 0.0, TAU, 56, Color(0.78, 1.0, 0.4, 0.5 + 0.4 * flash), 3.0, true)
			game.draw_arc(mound, Controller.EMERGE_RADIUS * (1.0 - warn * 0.85), 0.0, TAU, 48, Color(1.0, 1.0, 0.7, 0.6), 2.0, true)
			for index in range(8):
				var a: float = float(index) * TAU / 8.0 + 0.2
				game.draw_line(mound + Vector2.from_angle(a) * 14.0, mound + Vector2.from_angle(a) * (30.0 + warn * 60.0), Color(0.16, 0.1, 0.04, 0.8), 3.0, true)
		var mound_tex: Texture2D = _optional_texture(game, "boss6_burrow_mound")
		var bob := Vector2(sin(t * 18.0) * 3.0, -absf(sin(t * 9.0)) * 4.0)
		if mound_tex != null:
			game.draw_texture_rect(mound_tex, Rect2(mound - Vector2(96.0, 72.0) + bob, Vector2(192.0, 128.0)), false)
		else:
			MistGuide.draw_blob(game, mound + Vector2(0.0, 10.0), Vector2(230.0, 96.0), Color(0.05, 0.03, 0.0, 0.75))
			game.draw_circle(mound + bob, 38.0, Color(0.16, 0.11, 0.04, 1.0))
			game.draw_circle(mound + bob + Vector2(-30.0, 10.0), 25.0, Color(0.14, 0.1, 0.03, 1.0))
			game.draw_circle(mound + bob + Vector2(28.0, 12.0), 23.0, Color(0.18, 0.13, 0.05, 1.0))
			game.draw_arc(mound + bob, 40.0, PI * 1.05, PI * 1.95, 18, Color(0.62, 1.0, 0.24, 0.85), 3.0, true)
			for crack in range(4):
				var ca: float = PI * (1.15 + float(crack) * 0.22)
				game.draw_line(mound + bob + Vector2.from_angle(ca) * 8.0, mound + bob + Vector2.from_angle(ca) * 34.0, Color(0.62, 1.0, 0.24, 0.7), 2.0, true)
			# Lascas de osso da coroa aparecendo.
			for spike in range(3):
				var sx: float = -16.0 + float(spike) * 16.0
				game.draw_colored_polygon(PackedVector2Array([mound + bob + Vector2(sx - 5.0, -26.0), mound + bob + Vector2(sx + 5.0, -26.0), mound + bob + Vector2(sx + 1.0, -50.0 - float(spike % 2) * 8.0)]), Color(0.86, 0.8, 0.62, 0.95))
			for index in range(5):
				var u: float = fposmod(t * 1.6 + float(index) * 0.2, 1.0)
				game.draw_circle(mound + Vector2(sin(float(index) * 2.4) * 26.0, -20.0 - u * 30.0), 4.0 * (1.0 - u) + 1.0, Color(0.6, 1.0, 0.24, 0.8 * (1.0 - u)))
		# Rastro de lama atras do monte.
		if current == Controller.MODE_TRAVEL and not game._runtime_visual_budget_active():
			var trail: Vector2 = Vector2(game.boss6_ai_state.get("last_trail", Vector2.ZERO))
			if trail != Vector2.ZERO:
				game.draw_line(trail - camera, mound, Color(0.06, 0.04, 0.0, 0.45), 34.0, true)
				game.draw_line(trail - camera, mound, Color(0.5, 0.9, 0.2, 0.25), 6.0, true)
		return
	if current == Controller.MODE_EMERGE and state_t < 0.42:
		var center: Vector2 = game.boss_pos - camera
		var u2: float = clampf(state_t / 0.42, 0.0, 1.0)
		var size: float = lerpf(140.0, 320.0, u2)
		var burst: Texture2D = _optional_texture(game, "boss6_emerge_burst")
		if burst != null:
			game.draw_texture_rect(burst, Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size)), false, Color(1.0, 1.0, 1.0, 1.0 - u2 * 0.8))
		else:
			MistGuide.draw_blob(game, center, Vector2(size, size * 0.7), Color(0.18, 0.12, 0.04, 0.7 * (1.0 - u2)))
			for index in range(14):
				var a2: float = float(index) * TAU / 14.0
				var r: float = size * 0.5 * (0.5 + 0.5 * u2)
				game.draw_circle(center + Vector2.from_angle(a2) * r * Vector2(1.0, 0.7), 7.0 * (1.0 - u2) + 2.0, Color(0.58, 1.0, 0.2, 0.85 * (1.0 - u2)))


static func _optional_texture(game: Node2D, key: String) -> Texture2D:
	if game.textures.has(key):
		return game.textures.get(key) as Texture2D
	if ResourceLoader.exists(REWORK_DIR + key + ".png"):
		game._ensure_runtime_texture(key)
		return game.textures.get(key) as Texture2D
	return null



## Sombra no mesmo tamanho/pes do corpo (a arte nova usa escala fixa, nao o encaixe antigo).
static func draw_shadow(game: Node2D, texture: Texture2D, center: Vector2, max_size: Vector2, alpha: float) -> void:
	if texture == null:
		return
	var rect: Rect2 = body_rect(texture, max_size)
	var flip: float = -1.0 if should_flip_h(game) else 1.0
	var mid: Vector2 = center + Vector2((rect.position.x + rect.size.x * 0.5) * flip, rect.position.y + rect.size.y * 0.5)
	game._draw_dynamic_shadow_fit(texture, mid, rect.size, should_flip_h(game), true, alpha)


## Retangulo local (antes do espelhamento) com os pes de TODA arte na mesma linha (max_size.y/2)
## e o corpo no mesmo tamanho: arte nova com escala fixa; arte antiga normalizada por LEGACY_FEET.
static func body_rect(texture: Texture2D, max_size: Vector2) -> Rect2:
	var tex_size: Vector2 = texture.get_size()
	var ground_y: float = max_size.y * 0.5
	if is_equal_approx(tex_size.x, BODY_CELL) and is_equal_approx(tex_size.y, BODY_CELL):
		var size := tex_size * BODY_SCALE
		var shift: float = float(FRAME_SHIFT_X.get(texture.resource_path.get_file(), 0.0)) * BODY_SCALE
		return Rect2(Vector2(-size.x * 0.5 + shift, ground_y - BODY_FEET_Y * BODY_SCALE), size)
	var fit: float = minf(max_size.x / tex_size.x, max_size.y / tex_size.y)
	var key: String = texture.resource_path.get_file()
	if LEGACY_FEET.has(key):
		var scale: float = fit * LEGACY_SCALE_BOOST
		var anchor: Vector2 = LEGACY_FEET[key]
		return Rect2(Vector2(BODY_FEET_CENTER_X - anchor.x * scale, ground_y - anchor.y * scale), tex_size * scale)
	var draw_size: Vector2 = tex_size * fit
	return Rect2(Vector2(-draw_size.x * 0.5, ground_y - draw_size.y), draw_size)



static func scythe_frame_index(game: Node2D) -> int:
	if game.boss6_state == game.BOSS6_STATE_RECOVERY:
		return 4
	for attack_value in game.boss_attacks:
		var attack: Dictionary = attack_value
		var kind := String(attack.get("kind", ""))
		var age: float = float(attack.get("age", 0.0))
		if kind == game.BOSS6_ABILITY_SCYTHES + "_telegraph":
			return 0 if age < float(attack.get("duration", 0.9)) * 0.45 else 1
		if kind == game.BOSS6_ABILITY_SCYTHES:
			for wave_value in Array(attack.get("waves", [])):
				var wave: Dictionary = wave_value
				var local: float = age - float(wave.get("start", 0.0))
				if local >= 0.0 and local < 0.26:
					return 2 if float(wave.get("side", 1.0)) < 0.0 else 3
			return 1
	return 1



static func _action_frame(game: Node2D) -> Texture2D:
	match game.boss6_current_ability:
		game.BOSS6_ABILITY_SCYTHES:
			return _frame(game, "boss6_rework_scythe", scythe_frame_index(game))
		game.BOSS6_ABILITY_ACID_BLOOM:
			return _frame(game, "boss6_rework_spit", _phase_index(game, game.BOSS6_ABILITY_ACID_BLOOM, 0.35, 3))
		game.BOSS6_ABILITY_TAIL:
			return _frame(game, "boss6_rework_tail", _phase_index(game, game.BOSS6_ABILITY_TAIL, 0.5, 2))
	return null


## 0/1 na carga (dividida em split), "fire" na execucao e o ultimo na recuperacao.
static func _phase_index(game: Node2D, ability: String, split: float, recover_index: int) -> int:
	if game.boss6_state == game.BOSS6_STATE_RECOVERY:
		return recover_index
	if game.boss6_state == game.BOSS6_STATE_EXECUTING:
		return recover_index - 1
	for attack_value in game.boss_attacks:
		var attack: Dictionary = attack_value
		if String(attack.get("kind", "")) == ability + "_telegraph":
			var u: float = float(attack.get("age", 0.0)) / maxf(0.01, float(attack.get("duration", 1.0)))
			return 0 if u < split else mini(1, recover_index - 1)
	return 0


## Cuspe Florado: bolas em arco (boca -> chao), sombra crescendo onde vao cair, respingo.
static func draw_spit(game: Node2D, camera: Vector2, attack: Dictionary, age: float) -> void:
	var mouth: Vector2 = Vector2(attack.get("origin", game.boss_pos)) - camera
	var glob: Texture2D = _optional_texture(game, "boss6_acid_glob")
	var splash: Texture2D = _optional_texture(game, "boss6_acid_splash")
	var t: float = float(Time.get_ticks_msec()) * 0.001
	for spot_value in Array(attack.get("spots", [])):
		var spot: Dictionary = spot_value
		var land: Vector2 = Vector2(spot.get("pos", game.player_pos)) - camera
		var p: float = Controller.spit_progress(spot, age)
		var after: float = age - float(spot.get("launch", 0.0)) - Controller.SPIT_FLIGHT
		if p < 1.0:
			var shadow: float = clampf(p, 0.0, 1.0) if p >= 0.0 else 0.0
			game.draw_circle(land, Controller.SPIT_SPLASH_RADIUS * (0.25 + 0.75 * shadow), Color(0.05, 0.12, 0.0, 0.18 + 0.22 * shadow))
			game.draw_arc(land, Controller.SPIT_SPLASH_RADIUS, 0.0, TAU, 40, Color(0.66, 1.0, 0.24, 0.35 + 0.5 * shadow), 2.5, true)
			draw_acid_target_notches(game, land, Controller.SPIT_SPLASH_RADIUS, int(spot.get("target_index", 0)))
		if p >= 0.0 and p < 1.0:
			var height: float = sin(p * PI) * 210.0
			var pos: Vector2 = mouth.lerp(land, p) + Vector2(0.0, -height)
			var size: float = 46.0 + sin(p * PI) * 14.0
			if glob != null:
				game.draw_set_transform(pos, t * 6.0, Vector2.ONE)
				game.draw_texture_rect(glob, Rect2(-Vector2(size, size) * 0.5, Vector2(size, size)), false)
				game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				game.draw_circle(pos, size * 0.42, Color(0.36, 0.86, 0.1, 0.95))
				game.draw_circle(pos + Vector2(-4.0, -5.0), size * 0.16, Color(0.9, 1.0, 0.6, 0.9))
			for drip in range(3):
				var back: float = clampf(p - 0.05 * float(drip + 1), 0.0, 1.0)
				var trail: Vector2 = mouth.lerp(land, back) + Vector2(0.0, -sin(back * PI) * 210.0)
				game.draw_circle(trail, 5.0 - float(drip), Color(0.5, 1.0, 0.2, 0.6 - 0.15 * float(drip)))
		elif after >= 0.0 and after < 0.35:
			var u: float = after / 0.35
			var s: float = lerpf(120.0, 250.0, u)
			if splash != null:
				game.draw_texture_rect(splash, Rect2(land - Vector2(s, s) * 0.5, Vector2(s, s)), false, Color(1.0, 1.0, 1.0, 1.0 - u))
			else:
				for drop in range(10):
					var a: float = float(drop) * TAU / 10.0
					game.draw_circle(land + Vector2.from_angle(a) * s * 0.4, 6.0 * (1.0 - u) + 1.5, Color(0.56, 1.0, 0.2, 0.85 * (1.0 - u)))


static func _draw_spit_telegraph(game: Node2D, camera: Vector2, attack: Dictionary, age: float) -> void:
	var p: float = clampf(age / maxf(0.01, float(attack.get("duration", 0.9))), 0.0, 1.0)
	var mouth: Vector2 = game.boss6_controller.spit_mouth() - camera
	MistGuide.draw_blob(game, mouth, Vector2(90.0, 90.0) * (0.5 + p), Color(0.5, 1.0, 0.16, 0.5 * p))
	for index in range(6):
		var a: float = float(index) * TAU / 6.0 + age * 4.0
		var r: float = lerpf(80.0, 10.0, fposmod(age * 1.8 + float(index) * 0.16, 1.0))
		game.draw_circle(mouth + Vector2.from_angle(a) * r, 3.0, Color(0.7, 1.0, 0.3, 0.8 * p))


## Cauda: aviso em arco nas costas/lados (a frente fica livre) e varrida com faiscas.
static func _draw_tail_telegraph(game: Node2D, camera: Vector2, attack: Dictionary, age: float) -> void:
	var p: float = clampf(age / maxf(0.01, float(attack.get("duration", 0.72))), 0.0, 1.0)
	var origin: Vector2 = game.boss_pos - camera
	var back: float = 0.0 if game.boss6_controller.facing() < 0.0 else PI
	_draw_sector(game, origin, back, Controller.TAIL_ARC, Controller.TAIL_REACH, Color(0.7, 1.0, 0.24, 0.06 + 0.12 * p))
	var flash: float = 0.5 + 0.5 * sin(age * 30.0)
	game.draw_arc(origin, Controller.TAIL_REACH, back - Controller.TAIL_ARC * 0.5, back + Controller.TAIL_ARC * 0.5, 48, Color(0.86, 1.0, 0.4, 0.45 + 0.45 * p * flash), 3.0, true)


static func draw_tail(game: Node2D, camera: Vector2, attack: Dictionary, age: float) -> void:
	var origin: Vector2 = Vector2(attack.get("origin", game.boss_pos)) - camera
	var angle: float = Controller.tail_angle(attack, age)
	var side: float = float(attack.get("side", 1.0))
	var start: float = float(attack.get("back", 0.0)) - side * Controller.TAIL_ARC * 0.5
	var fade: float = 1.0 - clampf((age - Controller.TAIL_SWEEP_TIME) / 0.35, 0.0, 1.0)
	var swept_from: float = minf(start, angle) if side > 0.0 else minf(angle, start)
	var swept_to: float = maxf(start, angle) if side > 0.0 else maxf(angle, start)
	game.draw_arc(origin, Controller.TAIL_REACH * 0.62, swept_from, swept_to, 40, Color(0.5, 0.9, 0.16, 0.22 * fade), Controller.TAIL_REACH * 0.72, true)
	game.draw_arc(origin, Controller.TAIL_REACH, swept_from, swept_to, 40, Color(0.9, 1.0, 0.5, 0.75 * fade), 4.0, true)
	var tip: Vector2 = origin + Vector2.from_angle(angle) * Controller.TAIL_REACH
	game.draw_line(origin, tip, Color(0.92, 1.0, 0.62, 0.8 * fade), 6.0, true)
	var spark: Texture2D = _optional_texture(game, "boss6_spark")
	for index in range(6):
		var u: float = (float(index) + 1.0) / 6.0
		var p: Vector2 = origin.lerp(tip, u) + Vector2(sin(age * 50.0 + float(index) * 2.0), cos(age * 43.0 + float(index))) * 8.0
		if spark != null:
			game.draw_texture_rect(spark, Rect2(p - Vector2(18.0, 18.0), Vector2(36.0, 36.0)), false, Color(1.0, 1.0, 1.0, fade))
		else:
			game.draw_circle(p, 4.0, Color(1.0, 1.0, 0.7, 0.9 * fade))


static func _draw_sector(game: Node2D, origin: Vector2, center_angle: float, arc: float, radius: float, color: Color) -> void:
	var points := PackedVector2Array([origin])
	for index in range(25):
		points.append(origin + Vector2.from_angle(center_angle - arc * 0.5 + arc * float(index) / 24.0) * radius)
	game.draw_colored_polygon(points, color)
