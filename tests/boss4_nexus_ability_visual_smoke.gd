extends SceneTree

const OUT_DIR := "res://.codex/boss4_nexus_abilities"
const CAPTURE_SIZE := Vector2i(1280, 720)

var game: Node
var captures: Array[String] = []


func _initialize() -> void:
	root.size = CAPTURE_SIZE
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("BOSS4_NEXUS_ABILITY_VISUAL_FAIL " + message)
	quit(1)


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_prepare_game()

	_prepare_boss4_scene()
	game._spawn_boss4_comet()
	game.effects.clear()
	_check(game.enemy_bullets.size() == 1, "comet was not spawned")
	_check(String(game.enemy_bullets[0].get("type", "")) == "boss4_comet", "wrong comet bullet type")
	var comet_dir_before: Vector2 = Vector2(game.enemy_bullets[0].get("dir", Vector2.LEFT))
	game.player_pos = Vector2(500, 250)
	game._update_enemy_bullets(0.32)
	_check(Vector2(game.enemy_bullets[0].get("dir", Vector2.LEFT)).distance_to(comet_dir_before) > 0.0001, "comet did not steer toward the player")
	await _capture("boss4_01_comet_projectile_1280x720.png", "comet")

	_prepare_boss4_scene()
	game._start_boss4_secondary()
	game.effects.clear()
	_check(game.phase4_enemy_hazards.filter(func(h): return String(Dictionary(h).get("kind", "")) == "boss4_bubble").size() == game.BOSS4_SECONDARY_UP_COUNT + game.BOSS4_SECONDARY_DOWN_COUNT, "secondary did not create seven bubbles")
	game._update_phase4_enemy_hazards(3.20)
	await _capture("boss4_02_bubble_lanes_1280x720.png", "bubble")

	_prepare_boss4_scene()
	game._start_boss4_ultimate()
	game.effects.clear()
	game._update_boss4_ultimate(0.01)
	var rays: Array = game.phase4_enemy_hazards.filter(func(h): return String(Dictionary(h).get("kind", "")) == "boss4_ultimate_ray")
	_check(rays.size() == 1, "ultimate did not spawn first ray")
	rays[0]["pos"] = game.player_pos
	game._update_phase4_enemy_hazards(game.BOSS4_ULTIMATE_RAY_WARNING + 0.04)
	_check(bool(rays[0].get("triggered", false)), "ultimate ray did not trigger after warning")
	_check(not game.boss4_strike_sequence.is_empty(), "ultimate did not start electric capture sequence")
	game.effects.clear()
	game.damage_flash_timer = 0.0
	game.player_hp = game.player_hp_max
	await _capture("boss4_03_ultimate_lightning_1280x720.png", "lightning")

	_prepare_boss4_scene()
	game.boss4_meteor_event_started = false
	game.boss4_meteor_event_timer = 0.0
	game._update_boss4_meteorites(0.01)
	_check(game.boss4_meteorites.size() == game.BOSS4_METEOR_COUNT, "meteor event did not create three meteorites")
	var meteor_targets := [Vector2(360, 360), Vector2(660, 500), Vector2(960, 350)]
	for index in range(game.boss4_meteorites.size()):
		var target: Vector2 = meteor_targets[index]
		game.boss4_meteorites[index]["target"] = target
		game.boss4_meteorites[index]["pos"] = Vector2(target.x, -170.0)
		game.boss4_meteorites[index]["age"] = 0.0
	game.effects.clear()
	game._update_boss4_meteorites(game.BOSS4_METEOR_WARNING + 0.06)
	_check(game.boss4_meteorites.all(func(m): return bool(Dictionary(m).get("impacted", false))), "meteorites did not impact")
	game._update_boss4_meteorites(game.BOSS4_METEOR_ARM_TIME + 0.12)
	_check(game.boss4_meteorites.any(func(m): return bool(Dictionary(m).get("draining", false))), "meteorites did not start draining")
	var first_bonus: float = game.boss4_meteor_damage_bonus
	game._update_boss4_meteorites(0.35)
	_check(game.boss4_meteor_damage_bonus > first_bonus, "meteor drain bonus did not accumulate")
	await _capture("boss4_04_meteor_drain_1280x720.png", "meteor")

	print("BOSS4_NEXUS_ABILITY_VISUAL_OK captures=", ", ".join(captures))
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	quit(0)


func _prepare_game() -> void:
	game.startup_thanks_done = true
	game.startup_thanks_timer = 0.0
	game.startup_thanks_fading = false
	game.vol_master = 0.0
	game.qa_streaming_enabled = false
	game.gfx_screen_shake = false
	game.gfx_particles = true
	game.show_fps_counter = false
	game.ui_platform_override = "desktop"
	game.ui_platform_override_unlocked = true
	game._start_game(false)
	game.set_process(false)


func _prepare_boss4_scene() -> void:
	root.size = CAPTURE_SIZE
	game.mode = "game"
	game.current_phase = 4
	game.time_alive = 24.0
	game.player_pos = Vector2(500, 430)
	game.last_facing = Vector2.RIGHT
	game.player_hp_max = 1000.0
	game.player_hp = 1000.0
	game.player_defense = 0.0
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 8000.0
	game.boss_hp = 8000.0
	game.boss_pos = Vector2(900, 385)
	game.boss4_instability = 10.0
	game.boss4_attack_pose_timer = 0.0
	game.boss4_secondary_active = false
	game.boss4_secondary_elapsed = 0.0
	game.boss4_ultimate_active = false
	game.boss4_ultimate_timer = 0.0
	game.boss4_ultimate_ray_index = 0
	game.boss4_ultimate_laser_timer = 0.0
	game.boss4_strike_sequence.clear()
	game.boss4_meteorites.clear()
	game.boss4_meteor_event_started = false
	game.boss4_meteor_event_timer = 999.0
	game.boss4_meteor_damage_bonus = 0.0
	game.enemies.clear()
	game.bullets.clear()
	game.enemy_bullets.clear()
	game.phase4_enemy_hazards.clear()
	game.phase4_planets.clear()
	game.phase4_null_zones.clear()
	game.effects.clear()
	game.shockwaves.clear()
	game.buttons.clear()
	game.screen_shake_timer = 0.0
	game.screen_shake_strength = 0.0


func _capture(file_name: String, signal_kind: String) -> void:
	game.buttons.clear()
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null:
		_check(false, "invalid capture " + file_name)
		return
	_check(image.get_width() == CAPTURE_SIZE.x and image.get_height() == CAPTURE_SIZE.y, "invalid capture " + file_name)
	_check(image.get_used_rect().size.x > int(float(CAPTURE_SIZE.x) * 0.70) and image.get_used_rect().size.y > int(float(CAPTURE_SIZE.y) * 0.70), "blank capture " + file_name)
	_check(_visual_signal_count(image, signal_kind) > _visual_signal_minimum(signal_kind), "weak visual signal for " + signal_kind)
	var output := OUT_DIR.path_join(file_name)
	_check(image.save_png(output) == OK, "could not save " + file_name)
	captures.append(ProjectSettings.globalize_path(output))


func _visual_signal_minimum(signal_kind: String) -> int:
	match signal_kind:
		"comet":
			return 10
		"bubble":
			return 18
		"lightning":
			return 16
		"meteor":
			return 22
		_:
			return 4


func _visual_signal_count(image: Image, signal_kind: String) -> int:
	var count := 0
	for y in range(0, image.get_height(), 6):
		for x in range(0, image.get_width(), 6):
			var c: Color = image.get_pixel(x, y)
			if _matches_visual_signal(c, signal_kind):
				count += 1
	return count


func _matches_visual_signal(c: Color, signal_kind: String) -> bool:
	match signal_kind:
		"comet":
			return (c.b > 0.52 and c.g > 0.42 and c.r < 0.86) or (c.r > 0.82 and c.g > 0.46 and c.b < 0.34)
		"bubble":
			return c.b > 0.62 and c.g > 0.46 and c.r < 0.58
		"lightning":
			return (c.r > 0.82 and c.g > 0.64 and c.b < 0.42) or (c.r > 0.72 and c.g < 0.24 and c.b < 0.30)
		"meteor":
			return c.r > 0.72 and c.g > 0.34 and c.b < 0.34
		_:
			return c.a > 0.1
