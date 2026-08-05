extends SceneTree

const PREVIEW_DIR := "res://assets/previews/manifestations"
const FRAME_SIZE := Vector2i(1280, 720)
const FRAME_COUNT := 24
const ATLAS_COLS := 4
const ATLAS_ROWS := 6
const FPS := 12.0
const DT := 1.0 / FPS
const WEBP_QUALITY := 0.32

var game: Node
var output_dir := PREVIEW_DIR


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MANIFEST_PREVIEW_CAPTURE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = FRAME_SIZE
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name().to_lower().contains("headless"):
		_check(false, "preview capture needs a rendered viewport; run this script without --headless")
	var only_key := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--key="):
			only_key = argument.trim_prefix("--key=").strip_edges().to_lower()
		elif argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=").strip_edges()
	DirAccess.make_dir_recursive_absolute(_globalize_output_dir(output_dir))
	var clip_count := 0
	await process_frame
	game.startup_thanks_done = true
	game.startup_thanks_fading = false
	game.startup_thanks_timer = 0.0
	for i in range(game.MANIFESTATIONS.size()):
		var item: Dictionary = game.MANIFESTATIONS[i]
		if only_key != "" and String(item["key"]) != only_key:
			continue
		for kind in ["atk", "skill", "ultimate"]:
			await _capture_clip(i, String(item["key"]), kind)
			clip_count += 1
	_check(clip_count > 0, "no manifestation matched preview capture filter: " + only_key)
	print("MANIFEST_PREVIEW_CAPTURE_SMOKE_OK clips=%d frames=%d frame_size=%dx%d webp=true key=%s" % [clip_count, FRAME_COUNT, FRAME_SIZE.x, FRAME_SIZE.y, only_key if only_key != "" else "all"])
	game.queue_free()
	await process_frame
	quit(0)


func _capture_clip(index: int, key: String, kind: String) -> void:
	_setup_clip(index, key, kind)
	var atlas := Image.create_empty(FRAME_SIZE.x * ATLAS_COLS, FRAME_SIZE.y * ATLAS_ROWS, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0.0, 0.0, 0.0, 1.0))
	for frame in range(FRAME_COUNT):
		_drive_clip_frame(key, kind, frame)
		await process_frame
		var viewport_texture := root.get_texture()
		_check(viewport_texture != null, "viewport texture is null; run without --headless so Godot can render preview frames")
		var image: Image = viewport_texture.get_image()
		_check(image != null, "viewport image is null; run without --headless so Godot can render preview frames")
		if image.get_size() != FRAME_SIZE:
			image.resize(FRAME_SIZE.x, FRAME_SIZE.y, Image.INTERPOLATE_LANCZOS)
		if image.get_format() != Image.FORMAT_RGBA8:
			image.convert(Image.FORMAT_RGBA8)
		var dst := Vector2i((frame % ATLAS_COLS) * FRAME_SIZE.x, int(frame / ATLAS_COLS) * FRAME_SIZE.y)
		atlas.blit_rect(image, Rect2i(Vector2i.ZERO, FRAME_SIZE), dst)
	var output := _output_path(key, kind)
	var err := atlas.save_webp(output, WEBP_QUALITY)
	_check(err == OK, "failed to save preview atlas: " + output)


func _globalize_output_dir(path: String) -> String:
	path = path.replace("\\", "/")
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path


func _output_path(key: String, kind: String) -> String:
	var base := _globalize_output_dir(output_dir).replace("\\", "/")
	return base.path_join("%s_%s.webp" % [key, kind])


func _setup_clip(index: int, key: String, kind: String) -> void:
	game.selected_manifestation = index
	game.selected_aura = 0
	game._start_game()
	game.startup_thanks_done = true
	game.startup_thanks_fading = false
	game.startup_thanks_timer = 0.0
	game.preview_capture_mode = true
	game.mode = "game"
	game.current_phase = 1
	game.current_music = ""
	if game.music_player:
		game.music_player.stop()
	game.vol_master = 0.0
	game.vol_music = 0.0
	game.vol_sfx = 0.0
	game.gfx_screen_shake = false
	game.gfx_particles = true
	game.gfx_shadows = false
	game.manifestation_key = key
	game.time_alive = 35.0
	game.boss_dead = true
	game.boss_active = false
	game.spawn_timer = 9999.0
	game.next_larapio_spawn_time = 999999.0
	game.player_hp = game.player_hp_max
	game.player_pos = Vector2(780, 485)
	game.last_facing = Vector2.RIGHT
	game.attack_dragging = true
	game.attack_drag_direction = Vector2.RIGHT
	game.attack_lock_selecting = false
	game.bullets.clear()
	game.return_bullets.clear()
	game.enemy_bullets.clear()
	game.effects.clear()
	game.shockwaves.clear()
	game.slashes.clear()
	game.prisms.clear()
	game.anchors.clear()
	game.orbitals.clear()
	game.seed_links.clear()
	game.manifestation_secondaries.clear()
	game.parasite_spit_zones.clear()
	game.enemies.clear()
	_spawn_preview_enemies()
	_prepare_manifestation_context(key)
	game.last_attack_time = -999.0
	game.last_skill_time = -999.0
	game.last_secondary_time = -999.0
	if kind == "skill":
		_prepare_skill_clip(key)
	elif kind == "ultimate":
		_prepare_ultimate_clip(key)


func _spawn_preview_enemies() -> void:
	var points := [
		Vector2(965, 420),
		Vector2(1045, 512),
		Vector2(930, 590),
		Vector2(1110, 438)
	]
	for pos in points:
		game._spawn_enemy(game.ENEMY_COMMON, pos)
	for enemy in game.enemies:
		enemy["stun"] = 999.0
		enemy["hp"] = 999.0
		enemy["max_hp"] = 999.0


func _prepare_manifestation_context(key: String) -> void:
	match key:
		"cartografica":
			game._add_cartographic_coord(game.player_pos + Vector2(120, -62))
			game._add_cartographic_coord(game.player_pos + Vector2(265, 48))
			game._add_cartographic_coord(game.player_pos + Vector2(100, 122))
		"mnesica":
			for enemy in game.enemies:
				game._register_mnesic_memory(enemy, 80.0)
				game._register_mnesic_memory(enemy, 70.0)
				game._register_mnesic_memory(enemy, 60.0)
		"ressonante":
			game.resonant_next_perfect = true
			for enemy in game.enemies:
				enemy["resonant_notes"] = ["grave", "aguda", "quebrada"]
				enemy["resonant_flash"] = 0.7
		"contratual":
			for enemy in game.enemies:
				game._apply_contract_clause(enemy)
				enemy["contract_infractions"] = 2
				enemy["contract_flash"] = 0.85


func _prepare_skill_clip(key: String) -> void:
	if key == "retornante":
		game._fire_returning()
	if key == "gravitante":
		for enemy in game.enemies:
			game.orbitals.append({
				"enemy_uid": int(enemy["uid"]),
				"target_kind": "enemy",
				"life": 4.0,
				"max": 4.0,
				"angle": randf() * TAU,
				"tick": 0.0,
				"damage": 10.0
			})
	if key == "cartografica":
		game.cartographic_route_timer = 3.0
	if key == "mnesica":
		for enemy in game.enemies:
			game._register_mnesic_memory(enemy, 95.0)
			game._register_mnesic_memory(enemy, 85.0)
	if key == "ressonante":
		game.resonant_perfect_streak = 3
		for enemy in game.enemies:
			enemy["resonant_notes"] = ["grave", "aguda", "quebrada"]
	if key == "contratual":
		for enemy in game.enemies:
			if not enemy.has("contract_clause"):
				game._apply_contract_clause(enemy)
			enemy["contract_infractions"] = 3
	game._use_skill(game.player_pos + Vector2(205, 0))


func _prepare_ultimate_clip(key: String) -> void:
	if key == "parasitica":
		for enemy in game.enemies:
			enemy["parasite_mark_time"] = 6.0
			enemy["seeds"] = 3
	if key == "gravitante":
		for enemy in game.enemies:
			enemy["stun"] = 0.0
	if key == "cartografica":
		game.cartographic_route_timer = 4.5
	if key == "mnesica":
		for enemy in game.enemies:
			game._register_mnesic_memory(enemy, 110.0)
			game._register_mnesic_memory(enemy, 90.0)
	if key == "ressonante":
		game.resonant_perfect_streak = 4
		game.resonant_next_perfect = true
	if key == "contratual":
		for enemy in game.enemies:
			if not enemy.has("contract_clause"):
				game._apply_contract_clause(enemy)
			enemy["contract_infractions"] = 3
	game._use_secondary_skill(game.player_pos + Vector2(165, 0))


func _drive_clip_frame(key: String, kind: String, frame: int) -> void:
	if kind == "atk" and frame % 6 == 0:
		game.last_attack_time = -999.0
		game._try_attack()
	if kind == "skill" and frame == 6:
		game.last_skill_time = -999.0
		_prepare_skill_clip(key)
	if kind == "ultimate" and key == "eletrica" and frame % 8 == 0:
		game.manifestation_secondaries.clear()
		game.last_secondary_time = -999.0
		game._use_secondary_skill(game.player_pos + Vector2(165, 0))
