extends SceneTree

var game: Node
var output_dir := "res://.codex"


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _save_frame(filename: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	var image = root.get_texture().get_image()
	assert(image != null and image.get_width() == 1280 and image.get_height() == 720)
	assert(image.save_png(output_dir + "/" + filename) == OK)


func _build_visual_history() -> void:
	game.boss1_rewind_history.clear()
	for sample_index in range(126):
		var t = sample_index * game.BOSS1_REWIND_SAMPLE_INTERVAL
		var ratio = float(sample_index) / 125.0
		game.time_alive = t
		game.elapsed_unpaused = t
		game.player_pos = Vector2(250, 600).lerp(Vector2(900, 330), ratio) + Vector2(0, sin(ratio * TAU * 2.0) * 90.0)
		game.boss_pos = Vector2(1020, 550).lerp(Vector2(620, 350), ratio) + Vector2(cos(ratio * TAU) * 80.0, 0)
		game.player_hp = int(420.0 - ratio * 190.0)
		game.last_facing = Vector2.RIGHT
		game.last_attack_time = t - fmod(t, 0.7)
		game.last_dash_time = t - 1.0
		game.last_skill_time = t - 2.0
		game.last_secondary_time = t - 5.0
		game.last_damage_time = t - 0.4
		game.boss_phase = t * 6.0
		game.boss_attack_timer = 2.0
		game.bullets = [{
			"pos": game.player_pos + Vector2.RIGHT * (55.0 + fmod(t * 190.0, 380.0)),
			"dir": Vector2.RIGHT,
			"kind": "eletrica_charged",
			"life": 1.0,
			"speed": 600.0
		}]
		game.enemy_bullets = [{"pos": game.boss_pos + Vector2.LEFT * (70.0 + fmod(t * 120.0, 280.0)), "dir": Vector2.LEFT, "type": "boss"}]
		game.boss1_rewind_history.append(game._capture_boss1_rewind_snapshot())
	game.bullets.clear()
	game.enemy_bullets.clear()


func _run() -> void:
	game._start_game()
	game.current_phase = 1
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 5000.0
	game.boss_hp = 1450.0
	game.gfx_shadows = true
	game.enemies.clear()
	game.effects.clear()
	game.player_pos = Vector2(820, 400)
	game.boss_pos = Vector2(620, 400)
	game.boss1_rewind_cooldown = game.BOSS1_REWIND_COOLDOWN
	game.boss1_time_wave = {
		"origin": game.boss_pos,
		"radius": 330.0,
		"direction": 1.0,
		"max_radius": 980.0,
		"age": 1.2
	}
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(output_dir))
	await _save_frame("boss1_time_wave_qa_1280x720.png")

	_build_visual_history()
	game.boss1_time_wave.clear()
	game.boss1_rewind_visual_projectiles = Array(game.boss1_rewind_history[-1]["projectiles"]).duplicate(true)
	game.boss1_rewind_sequence = {"elapsed": game.BOSS1_CLOCK_TRAVEL_TIME + game.BOSS1_CLOCK_TURN_TIME * 0.55, "boss_heal": 1400.0, "player_final_hp": 285.0}
	await _save_frame("boss1_clock_qa_1280x720.png")

	game.boss1_rewind_sequence["elapsed"] = game.BOSS1_CLOCK_TRAVEL_TIME + game.BOSS1_CLOCK_TURN_TIME + game.BOSS1_REWIND_PLAYBACK_TIME * 0.58
	game._apply_boss1_rewind_sample(game._boss1_rewind_interpolated_sample(0.58))
	await _save_frame("boss1_rewind_qa_1280x720.png")

	print("BOSS1_REWIND_VISUAL_OK " + ProjectSettings.globalize_path(output_dir))
	quit(0)
