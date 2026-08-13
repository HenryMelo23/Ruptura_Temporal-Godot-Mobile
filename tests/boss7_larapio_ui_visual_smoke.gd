extends SceneTree

const OUT_DIR := "res://.codex"

var game: Node
var failed := false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("BOSS7_LARAPIO_UI_VISUAL_FAIL " + message)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await process_frame
	game.startup_thanks_done = true
	game.startup_thanks_fading = false
	game.startup_thanks_timer = 0.0
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.current_phase = 7
	game.player_pos = Vector2(760, 520)
	game.player_hp = game.player_hp_max
	game.boss_active = true
	game.boss_ready = true
	game.boss_hp_max = game._boss_hp_for_phase(7)
	game.boss_hp = game.boss_hp_max
	game.boss_name = "FENIX"
	game.boss_pos = Vector2(830, 320)
	game.boss7_state = game.BOSS7_STATE_FLY
	game.boss7_reborn = true
	game.enemy_bullets.clear()
	game.boss7_flame_waves.clear()

	var impact := Vector2(680, 470)
	game._spawn_boss7_dive_fireball(impact)
	_check(game.enemy_bullets.size() == 1, "boss7 visual fireball missing")
	_check(Vector2(game.enemy_bullets[0].get("impact_pos", Vector2.ZERO)).distance_to(impact) < 0.01, "boss7 visual fireball impact mismatch")
	for i in range(18):
		game._update_enemy_bullets(0.05)
		game.time_alive += 0.05
		await process_frame
	await _capture("boss7_fenix_fireball_1280x720.png")

	for i in range(24):
		game._update_enemy_bullets(0.05)
		game._update_boss7_flame_waves(0.05)
		game.time_alive += 0.05
		await process_frame
	_check(not game.boss7_flame_waves.is_empty(), "boss7 visual fireball wave missing")
	_check(is_equal_approx(float(game.boss7_flame_waves.back().get("max_radius", 0.0)), 375.0), "boss7 visual wave radius mismatch")
	await _capture("boss7_fenix_wave_1280x720.png")

	game.current_phase = 1
	game.boss_active = false
	game.enemy_bullets.clear()
	var larapio: Dictionary = {
		"uid": 7701,
		"type": game.ENEMY_LARAPIO,
		"pos": Vector2(620, 390),
		"hp": 200.0,
		"max_hp": 200.0,
		"speed": 0.0,
		"damage": 0.0,
		"phase": 0.0,
		"hit_cd": 0.0,
		"stun": 0.0,
		"spawned_at": -999.0,
		"stolen": 0
	}
	game.enemies = [larapio]
	game.player_pos = Vector2(760, 430)
	game._throw_larapio_projectile(larapio)
	_check(game.enemy_bullets.size() == 1, "larapio stone was not thrown")
	_check(String(game.enemy_bullets[0].get("type", "")) == "larapio_stone", "larapio projectile is not stone")
	_check(game.enemy_bullets[0].has("spin"), "larapio stone has no spin metadata")
	game._queue_unlock_card_notification(game.CARDS[0], "Eliminar 10/10 inimigos")
	game.unlock_notifications[0]["age"] = 0.72
	game.unlock_notifications[0]["life"] = 5.28
	game._show_event_alert("ANOMALIA VISUAL", Color(1.0, 0.18, 0.86))
	for i in range(6):
		game._update_enemy_bullets(0.05)
		game.time_alive += 0.05
		await process_frame
	await _capture("larapio_popup_mutation_1280x720.png")

	var viewport := Vector2(1280, 720)
	game.player_pos = Vector2(24, 24)
	var top_left_camera: Vector2 = game._camera(viewport)
	game.player_pos = game.WORLD_SIZE - Vector2(24, 24)
	var bottom_right_camera: Vector2 = game._camera(viewport)
	_check(top_left_camera.x < 0.0 and top_left_camera.y < 0.0, "camera does not overscan top-left")
	_check(bottom_right_camera.x > game.WORLD_SIZE.x - viewport.x and bottom_right_camera.y > game.WORLD_SIZE.y - viewport.y, "camera does not overscan bottom-right")

	if failed:
		_cleanup()
		quit(1)
		return
	print("BOSS7_LARAPIO_UI_VISUAL_OK " + ProjectSettings.globalize_path(OUT_DIR))
	_cleanup()
	quit(0)


func _capture(file_name: String) -> void:
	game.queue_redraw()
	await process_frame
	if DisplayServer.get_name() == "headless":
		return
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() == 1280 and image.get_height() == 720, "invalid capture " + file_name)
	if image != null:
		_check(image.save_png(OUT_DIR + "/" + file_name) == OK, "could not save " + file_name)


func _cleanup() -> void:
	if game == null:
		return
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	if game.get_parent() == root:
		root.remove_child(game)
	game.free()
	game = null
