extends SceneTree

const OUT_DIR := "res://.codex"

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("ANCORADA_VISUAL_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var manifestation_index := -1
	for index in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[index].get("key", "")) == "ancorada":
			manifestation_index = index
			break
	_check(manifestation_index >= 0, "Ancorada manifestation missing")
	game.selected_manifestation = manifestation_index
	game.selected_aura = 0
	game._start_game()
	game.mode = "game"
	game.startup_thanks_done = true
	game.startup_thanks_timer = 0.0
	game.startup_thanks_fading = false
	game.manifestation_key = "ancorada"
	game.vol_master = 0.0
	game.qa_streaming_enabled = false
	game.is_multiplayer = false
	game.gfx_screen_shake = false
	game.gfx_particles = true
	game.time_alive = 32.0
	game.player_pos = Vector2(640, 390)
	game.last_facing = Vector2.RIGHT
	game.enemies.clear()
	game.bullets.clear()
	game.enemy_bullets.clear()
	game.effects.clear()
	game.shockwaves.clear()
	game.manifestation_secondaries.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(118, -34))
	game._spawn_enemy(game.ENEMY_STALKER, game.player_pos + Vector2(206, 44))
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(-162, 58))
	for enemy in game.enemies:
		enemy["hp"] = 1200.0
		enemy["max_hp"] = 1200.0
		enemy["stun"] = 999.0
	game.boss_active = true
	game.boss_dead = false
	game.boss_pos = game.player_pos + Vector2(285, -92)
	game.boss_hp_max = 5000.0
	game.boss_hp = 5000.0
	game.set_process(false)

	game.bullets.append({
		"pos": game.player_pos + Vector2(122.0, -16.0),
		"origin": game.player_pos,
		"dir": Vector2.RIGHT,
		"speed": 0.0,
		"life": 1.0,
		"max_life": 1.0,
		"age": 0.2,
		"phase": 0.0,
		"trail_cd": 99.0,
		"damage": 100.0,
		"kind": "ancorada",
		"color": Color(0.32, 1.0, 0.38),
		"pierce": false,
		"hits": {}
	})
	await _capture("ancorada_projectile_1280x720.png")
	game.bullets.clear()

	game._spawn_secondary_ancorada()
	var secondary: Dictionary = game.manifestation_secondaries.back()
	game._update_secondary_ancorada(secondary, 0.01)
	game._update_secondary_ancorada(secondary, 0.28)
	await _capture("ancorada_ultimate_falling_1280x720.png")

	game.time_alive += 0.48
	game._update_secondary_ancorada(secondary, 0.48)
	await _capture("ancorada_ultimate_impact_1280x720.png")

	print("ANCORADA_VISUAL_OK " + ProjectSettings.globalize_path(OUT_DIR))
	game.queue_free()
	await process_frame
	quit(0)


func _capture(file_name: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() >= 1280 and image.get_height() >= 720, "invalid capture " + file_name)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var output := OUT_DIR.path_join(file_name)
	_check(image.save_png(output) == OK, "could not save " + file_name)
	_check(_green_signal_count(image) > 60, "green Ancorada VFX is not visible in " + file_name)
	if file_name.begins_with("ancorada_ultimate"):
		_check(_orbit_anchor_signal_count(image) > 28, "orbiting Ancorada anchors are not visible in " + file_name)


func _green_signal_count(image: Image) -> int:
	var count := 0
	for y in range(0, image.get_height(), 8):
		for x in range(0, image.get_width(), 8):
			var c := image.get_pixel(x, y)
			if c.g > 0.42 and c.g > c.r * 1.18 and c.g > c.b * 0.92:
				count += 1
	return count


func _orbit_anchor_signal_count(image: Image) -> int:
	var count := 0
	var scale: float = minf(float(image.get_width()) / 1280.0, float(image.get_height()) / 720.0)
	var center := Vector2(image.get_width(), image.get_height()) * 0.5
	var inner := 68.0 * scale
	var outer := 182.0 * scale
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var pos := Vector2(x, y)
			var distance := pos.distance_to(center)
			if distance < inner or distance > outer:
				continue
			var c := image.get_pixel(x, y)
			if c.g > 0.46 and c.g > c.r * 1.12 and c.g > c.b * 0.84:
				count += 1
	return count
