extends Node2D

const SelfplayCore = preload("res://tools/umbra_selfplay_core.gd")

@export var episodes: int = 96
@export var max_steps: int = 900
@export var training_seed: int = 20260827
@export var steps_per_frame: int = 5
@export var autoplay: bool = true

var core := SelfplayCore.new()
var session: Dictionary = {}
var snapshot: Dictionary = {}
var paused: bool = false
var _flash_timer: float = 0.0
var _last_completed: int = 0


func _ready() -> void:
	_parse_command_line()
	restart_visual_training()


func _process(delta: float) -> void:
	_flash_timer = maxf(0.0, _flash_timer - delta)
	if not paused and autoplay and not bool(snapshot.get("done", false)):
		snapshot = core.step_visual_session(session, steps_per_frame)
		if int(snapshot.get("completed_episodes", 0)) > _last_completed:
			_last_completed = int(snapshot.get("completed_episodes", 0))
			_flash_timer = 0.55
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_SPACE:
			paused = not paused
		KEY_R:
			restart_visual_training()
		KEY_N:
			step_visual_training(30)
		KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
			steps_per_frame = mini(60, steps_per_frame + 1)
		KEY_MINUS, KEY_KP_SUBTRACT:
			steps_per_frame = maxi(1, steps_per_frame - 1)


func restart_visual_training() -> void:
	session = core.create_visual_session({
		"episodes": episodes,
		"max_steps": max_steps,
		"seed": training_seed
	})
	snapshot = core.step_visual_session(session, 1)
	_last_completed = 0
	_flash_timer = 0.0
	queue_redraw()


func step_visual_training(steps: int = 1) -> Dictionary:
	snapshot = core.step_visual_session(session, max(1, steps))
	queue_redraw()
	return snapshot


func configure_for_smoke(smoke_episodes: int, smoke_max_steps: int, smoke_steps_per_frame: int) -> void:
	episodes = max(1, smoke_episodes)
	max_steps = max(60, smoke_max_steps)
	steps_per_frame = max(1, smoke_steps_per_frame)
	restart_visual_training()


func get_snapshot() -> Dictionary:
	return snapshot.duplicate(true)


func _parse_command_line() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--visual-episodes="):
			episodes = max(1, int(argument.trim_prefix("--visual-episodes=")))
		elif argument.begins_with("--visual-max-steps="):
			max_steps = max(60, int(argument.trim_prefix("--visual-max-steps=")))
		elif argument.begins_with("--visual-seed="):
			training_seed = int(argument.trim_prefix("--visual-seed="))
		elif argument.begins_with("--visual-speed="):
			steps_per_frame = max(1, int(argument.trim_prefix("--visual-speed=")))
		elif argument == "--visual-autoplay=false":
			autoplay = false


func _draw() -> void:
	var state: Dictionary = Dictionary(snapshot.get("state", {}))
	if state.is_empty():
		return
	_draw_background()
	_draw_hazards(Array(state.get("hazards", [])))
	_draw_projectiles(Array(state.get("projectiles", [])))
	_draw_rats(Array(state.get("rats", [])))
	_draw_trail(Array(state.get("player_history", [])), Color(0.18, 0.95, 1.0, 0.6))
	_draw_trail(Array(state.get("umbra_history", [])), Color(0.92, 0.17, 0.38, 0.62))
	_draw_actor(Vector2(state.get("player_pos", Vector2.ZERO)), "APOLO", Color(0.16, 0.85, 1.0), Color(0.86, 1.0, 1.0))
	_draw_actor(Vector2(state.get("umbra_pos", Vector2.ZERO)), "UMBRA", Color(0.87, 0.05, 0.32), Color(1.0, 0.76, 0.9))
	_draw_hud(state)


func _draw_background() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.015, 0.019, 0.03))
	var arena := Rect2(Vector2(40.0, 56.0), SelfplayCore.WORLD_SIZE - Vector2(80.0, 112.0))
	draw_rect(arena.grow(4.0), Color(0.02, 0.12, 0.12, 0.72), true)
	draw_rect(arena, Color(0.04, 0.07, 0.075, 0.92), true)
	for i in range(13):
		var x := arena.position.x + float(i) * arena.size.x / 12.0
		draw_line(Vector2(x, arena.position.y), Vector2(x, arena.end.y), Color(0.16, 0.56, 0.54, 0.18), 1.0)
	for j in range(7):
		var y := arena.position.y + float(j) * arena.size.y / 6.0
		draw_line(Vector2(arena.position.x, y), Vector2(arena.end.x, y), Color(0.16, 0.56, 0.54, 0.18), 1.0)
	draw_rect(arena, Color(0.25, 0.86, 0.78, 0.46), false, 2.0)
	draw_circle(SelfplayCore.ARENA_CENTER, 92.0, Color(0.08, 0.18, 0.13, 0.34))
	draw_arc(SelfplayCore.ARENA_CENTER, 92.0, 0.0, TAU, 96, Color(0.37, 0.92, 0.58, 0.36), 2.0)


func _draw_hazards(hazards: Array) -> void:
	for item in hazards:
		var hazard := Dictionary(item)
		var kind := String(hazard.get("kind", "hazard"))
		var color := _hazard_color(kind, float(hazard.get("delay", 0.0)))
		if hazard.has("from") and hazard.has("to"):
			var a := Vector2(hazard["from"])
			var b := Vector2(hazard["to"])
			var width := maxf(3.0, float(hazard.get("radius", 16.0)) * 0.55)
			draw_line(a, b, Color(color.r, color.g, color.b, 0.18), width * 1.75)
			draw_line(a, b, color, width)
			if kind == "thorns":
				_draw_thorns(a, b, width)
		else:
			var pos := Vector2(hazard.get("pos", Vector2.ZERO))
			var radius := float(hazard.get("radius", 40.0))
			draw_circle(pos, radius, Color(color.r, color.g, color.b, 0.18))
			draw_arc(pos, radius, 0.0, TAU, 64, color, 3.0)


func _draw_projectiles(projectiles: Array) -> void:
	for item in projectiles:
		var projectile := Dictionary(item)
		var pos := Vector2(projectile.get("pos", Vector2.ZERO))
		var projectile_owner := String(projectile.get("owner", ""))
		var color := Color(0.22, 0.92, 1.0) if projectile_owner == "apolo" else Color(1.0, 0.18, 0.36)
		draw_circle(pos, 8.0, Color(color.r, color.g, color.b, 0.24))
		draw_circle(pos, 4.0, color)


func _draw_rats(rats: Array) -> void:
	for item in rats:
		var rat := Dictionary(item)
		var pos := Vector2(rat.get("pos", Vector2.ZERO))
		draw_circle(pos, 9.0, Color(0.19, 0.92, 0.33, 0.26))
		draw_circle(pos, 4.0, Color(0.48, 1.0, 0.43, 0.86))


func _draw_trail(history: Array, color: Color) -> void:
	if history.size() < 2:
		return
	for i in range(1, history.size()):
		var alpha := float(i) / float(history.size())
		draw_line(Vector2(history[i - 1]), Vector2(history[i]), Color(color.r, color.g, color.b, color.a * alpha), 2.0 + alpha * 2.0)


func _draw_actor(pos: Vector2, label: String, core_color: Color, text_color: Color) -> void:
	draw_circle(pos, 25.0, Color(core_color.r, core_color.g, core_color.b, 0.22))
	draw_circle(pos, 15.0, core_color)
	draw_arc(pos, 24.0, -PI * 0.7, PI * 0.7, 32, text_color, 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, pos + Vector2(-28.0, -32.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, text_color)


func _draw_hud(state: Dictionary) -> void:
	var font := ThemeDB.fallback_font
	var scenario: Dictionary = Dictionary(snapshot.get("scenario", {}))
	var winners: Dictionary = Dictionary(snapshot.get("winners", {}))
	var episode_index := int(snapshot.get("episode_index", 0)) + 1
	var total_episodes := int(snapshot.get("episodes", 0))
	var completed := int(snapshot.get("completed_episodes", 0))
	var top_memory: Array = Array(snapshot.get("top_umbra_memory", []))
	var top_apolo: Array = Array(snapshot.get("top_apolo_memory", []))
	var episode_rows: Array = Array(snapshot.get("episode_rows", []))
	var apolo_hp := float(state.get("player_hp", 0.0)) / maxf(1.0, float(state.get("player_hp_max", 1.0)))
	var umbra_hp := float(state.get("umbra_hp", 0.0)) / maxf(1.0, float(state.get("umbra_hp_max", 1.0)))
	var panel := Rect2(Vector2(28.0, 18.0), Vector2(420.0, 184.0))
	draw_rect(panel, Color(0.015, 0.02, 0.028, 0.82), true)
	draw_rect(panel, Color(0.26, 0.74, 0.72, 0.54), false, 2.0)
	draw_string(font, panel.position + Vector2(18.0, 30.0), "APOLO VS UMBRA - TREINO VISUAL", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.9, 1.0, 0.96))
	draw_string(font, panel.position + Vector2(18.0, 58.0), "Geracao %d/%d  completas=%d  vel=%dx" % [episode_index, total_episodes, completed, steps_per_frame], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.76, 0.94, 0.94))
	draw_string(font, panel.position + Vector2(18.0, 82.0), "Cenario: %s / %s" % [String(scenario.get("manifestation", "")), String(scenario.get("spectrum", ""))], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.72, 0.86, 0.8))
	draw_string(font, panel.position + Vector2(18.0, 106.0), "Apolo: %s  Umbra: %s" % [String(state.get("last_apolo_action", "")), String(state.get("last_umbra_action", ""))], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(1.0, 0.92, 0.72))
	draw_string(font, panel.position + Vector2(18.0, 130.0), "Vitorias U:%d  A:%d  empates:%d" % [int(winners.get("UMBRA", 0)), int(winners.get("APOLO", 0)), int(winners.get("DRAW", 0))], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.88, 0.9, 1.0))
	draw_string(font, panel.position + Vector2(18.0, 154.0), "SPACE pausa | R reinicia | N avanca | +/- velocidade", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.68, 0.78, 0.78))

	_draw_bar(Vector2(482.0, 28.0), Vector2(310.0, 16.0), apolo_hp, Color(0.12, 0.85, 1.0), "APOLO HP")
	_draw_bar(Vector2(482.0, 58.0), Vector2(310.0, 16.0), umbra_hp, Color(0.98, 0.11, 0.32), "UMBRA HP")
	_draw_reward_panel(font, state, top_memory, top_apolo, episode_rows)
	if _flash_timer > 0.0:
		var last_episode: Dictionary = Dictionary(snapshot.get("last_episode", {}))
		draw_string(font, Vector2(492.0, 112.0), "Fim geracao: %s" % String(last_episode.get("winner", "DRAW")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color(1.0, 0.88, 0.38, _flash_timer / 0.55))


func _draw_reward_panel(font: Font, state: Dictionary, top_memory: Array, top_apolo: Array, episode_rows: Array) -> void:
	var panel := Rect2(Vector2(846.0, 336.0), Vector2(394.0, 358.0))
	draw_rect(panel, Color(0.017, 0.019, 0.026, 0.82), true)
	draw_rect(panel, Color(0.76, 0.25, 0.38, 0.52), false, 2.0)
	draw_string(font, panel.position + Vector2(16.0, 30.0), "EVOLUCAO AO VIVO", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(1.0, 0.86, 0.9))
	draw_string(font, panel.position + Vector2(16.0, 58.0), "Reward A: %.2f  U: %.2f" % [float(state.get("apolo_reward", 0.0)), float(state.get("umbra_reward", 0.0))], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.9, 0.94, 1.0))
	draw_string(font, panel.position + Vector2(16.0, 84.0), "Dimensao UMBRA: %s" % String(state.get("umbra_dimension", "base")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.76, 1.0, 0.78))
	draw_string(font, panel.position + Vector2(16.0, 112.0), "Top memoria UMBRA", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(1.0, 0.92, 0.72))
	for i in range(mini(5, top_memory.size())):
		var row := Dictionary(top_memory[i])
		draw_string(font, panel.position + Vector2(18.0, 138.0 + i * 16.0), "%d. %s  score %.3f  usos %d" % [i + 1, String(row.get("action", "")), float(row.get("score", 0.0)), int(row.get("uses", 0))], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.82, 0.9, 0.86))
	draw_string(font, panel.position + Vector2(16.0, 230.0), "Top tendencia APOLO", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.68, 0.94, 1.0))
	for i in range(mini(3, top_apolo.size())):
		var row := Dictionary(top_apolo[i])
		draw_string(font, panel.position + Vector2(18.0, 254.0 + i * 16.0), "%d. %s  score %.3f  usos %d" % [i + 1, String(row.get("action", "")), float(row.get("score", 0.0)), int(row.get("uses", 0))], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.78, 0.94, 1.0))
	_draw_episode_history(panel.position + Vector2(16.0, 310.0), episode_rows)


func _draw_episode_history(pos: Vector2, episode_rows: Array) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, pos, "Ultimas geracoes", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.95, 0.92, 0.78))
	var start: int = max(0, episode_rows.size() - 12)
	for i in range(start, episode_rows.size()):
		var row := Dictionary(episode_rows[i])
		var local_index: int = i - start
		var winner := String(row.get("winner", "DRAW"))
		var color := Color(1.0, 0.2, 0.34) if winner == "UMBRA" else Color(0.18, 0.88, 1.0) if winner == "APOLO" else Color(0.72, 0.78, 0.72)
		var x := pos.x + float(local_index) * 29.0
		var height := 10.0 + absf(float(row.get("umbra_reward", 0.0)) - float(row.get("apolo_reward", 0.0))) * 1.8
		draw_rect(Rect2(Vector2(x, pos.y + 14.0 + 28.0 - minf(28.0, height)), Vector2(18.0, minf(28.0, height))), Color(color.r, color.g, color.b, 0.82), true)
		draw_rect(Rect2(Vector2(x, pos.y + 14.0), Vector2(18.0, 28.0)), Color(color.r, color.g, color.b, 0.24), false, 1.0)


func _draw_bar(pos: Vector2, size: Vector2, ratio: float, color: Color, label: String) -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(pos, size), Color(0.02, 0.025, 0.034, 0.88), true)
	draw_rect(Rect2(pos, Vector2(size.x * clampf(ratio, 0.0, 1.0), size.y)), color, true)
	draw_rect(Rect2(pos, size), Color(0.9, 0.96, 1.0, 0.28), false, 1.0)
	draw_string(font, pos + Vector2(0.0, -5.0), "%s %.0f%%" % [label, ratio * 100.0], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.88, 0.96, 1.0))


func _draw_thorns(a: Vector2, b: Vector2, width: float) -> void:
	var dir := (b - a).normalized()
	var normal := Vector2(-dir.y, dir.x)
	var length := a.distance_to(b)
	var count := int(clampf(length / 52.0, 3.0, 18.0))
	for i in range(count):
		var t := (float(i) + 0.5) / float(count)
		var base := a.lerp(b, t)
		var side := -1.0 if i % 2 == 0 else 1.0
		var tip := base + normal * side * (width * 0.92)
		draw_line(base - dir * 7.0, tip, Color(0.72, 1.0, 0.42, 0.82), 2.0)


func _hazard_color(kind: String, delay: float) -> Color:
	var alpha := 0.42 if delay > 0.0 else 0.86
	match kind:
		"vortex":
			return Color(0.72, 0.27, 1.0, alpha)
		"prison":
			return Color(0.28, 0.52, 1.0, alpha)
		"miasma":
			return Color(0.25, 0.98, 0.38, alpha)
		"electric_line":
			return Color(0.9, 0.96, 0.2, alpha)
		"thorns":
			return Color(0.45, 1.0, 0.32, alpha)
		"laser":
			return Color(1.0, 0.18, 0.08, alpha)
		"apolo_gravity":
			return Color(0.2, 0.82, 1.0, alpha)
		_:
			return Color(1.0, 0.72, 0.3, alpha)
