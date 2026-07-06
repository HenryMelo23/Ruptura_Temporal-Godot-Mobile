extends SceneTree

const PREVIEW_DIR := "res://assets/previews/manifestations"
const FRAME_SIZE := Vector2i(320, 180)
const FRAME_COUNT := 100
const ATLAS_COLS := 10
const ATLAS_ROWS := 10
const FPS := 24.0
const DT := 1.0 / FPS

var game: Node


func _initialize() -> void:
	root.size = FRAME_SIZE
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW_DIR))
	var only_key := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--key="):
			only_key = argument.trim_prefix("--key=").strip_edges().to_lower()
	var clip_count := 0
	await process_frame
	for i in range(game.MANIFESTATIONS.size()):
		var item: Dictionary = game.MANIFESTATIONS[i]
		if only_key != "" and String(item["key"]) != only_key:
			continue
		for kind in ["atk", "skill", "ultimate"]:
			await _capture_clip(i, String(item["key"]), kind)
			clip_count += 1
	assert(clip_count > 0, "no manifestation matched preview capture filter: " + only_key)
	print("MANIFEST_PREVIEW_CAPTURE_SMOKE_OK clips=%d frames=%d webp=true key=%s" % [clip_count, FRAME_COUNT, only_key if only_key != "" else "all"])
	quit(0)


func _capture_clip(index: int, key: String, kind: String) -> void:
	_setup_clip(index, key, kind)
	var atlas := Image.create_empty(FRAME_SIZE.x * ATLAS_COLS, FRAME_SIZE.y * ATLAS_ROWS, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0.0, 0.0, 0.0, 1.0))
	for frame in range(FRAME_COUNT):
		_drive_clip_frame(key, kind, frame)
		await process_frame
		var image: Image = root.get_texture().get_image()
		if image.get_size() != FRAME_SIZE:
			image.resize(FRAME_SIZE.x, FRAME_SIZE.y, Image.INTERPOLATE_LANCZOS)
		if image.get_format() != Image.FORMAT_RGBA8:
			image.convert(Image.FORMAT_RGBA8)
		var dst := Vector2i((frame % ATLAS_COLS) * FRAME_SIZE.x, int(frame / ATLAS_COLS) * FRAME_SIZE.y)
		atlas.blit_rect(image, Rect2i(Vector2i.ZERO, FRAME_SIZE), dst)
	var output := "%s/%s_%s.webp" % [PREVIEW_DIR, key, kind]
	var err := atlas.save_webp(output, 0.48)
	assert(err == OK, "failed to save preview atlas: " + output)


func _setup_clip(index: int, key: String, kind: String) -> void:
	game.selected_manifestation = index
	game.selected_aura = 0
	game._start_game()
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
	game._use_skill(game.player_pos + Vector2(205, 0))


func _prepare_ultimate_clip(key: String) -> void:
	if key == "parasitica":
		for enemy in game.enemies:
			enemy["parasite_mark_time"] = 6.0
			enemy["seeds"] = 3
	if key == "gravitante":
		for enemy in game.enemies:
			enemy["stun"] = 0.0
	game._use_secondary_skill(game.player_pos + Vector2(165, 0))


func _drive_clip_frame(key: String, kind: String, frame: int) -> void:
	if kind == "atk" and frame % 18 == 0:
		game.last_attack_time = -999.0
		game._try_attack()
	if kind == "skill" and frame == 46:
		game.last_skill_time = -999.0
		_prepare_skill_clip(key)
	if kind == "ultimate" and key == "eletrica" and frame % 24 == 0:
		game.manifestation_secondaries.clear()
		game.last_secondary_time = -999.0
		game._use_secondary_skill(game.player_pos + Vector2(165, 0))
