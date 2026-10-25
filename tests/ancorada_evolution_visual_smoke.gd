extends SceneTree

const OUT_DIR := "res://.codex"

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("ANCORADA_EVOLUTION_VISUAL_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _entry(evolution_id: String) -> Dictionary:
	for entry_value in game._manifest_evolution_entries("ancorada"):
		var entry := Dictionary(entry_value)
		if String(entry.get("id", "")) == evolution_id:
			return entry
	return {}


func _activate(ev1_id: String, ev2_id: String) -> void:
	game._reset_manifest_evolution_state()
	game.manifest_evolution_options = [_entry(ev1_id)]
	game._choose_manifest_evolution(0)
	game.manifest_evolution_options = [_entry(ev2_id)]
	game._choose_manifest_evolution(0)


func _advance(delta: float, frames: int) -> void:
	for _frame in range(frames):
		game._update_ancorada_standing_still(delta)
		game._update_manifest_evolution_effects(delta)


func _run() -> void:
	await process_frame
	game._start_game()
	game.mode = "game"
	game.startup_thanks_done = true
	game.startup_thanks_timer = 0.0
	game.startup_thanks_fading = false
	game.manifestation_key = "ancorada"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.vol_master = 0.0
	game.qa_streaming_enabled = false
	game.is_multiplayer = false
	game.gfx_screen_shake = false
	game.gfx_particles = true
	game.time_alive = 1000.0
	game.player_pos = Vector2(640, 390)
	game.last_facing = Vector2.RIGHT
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.effects.clear()
	game.shockwaves.clear()
	game.anchors.clear()
	game.manifestation_secondaries.clear()
	for offset in [Vector2(95, -20), Vector2(170, 45), Vector2(-145, 52)]:
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + offset)
		game.enemies.back()["hp"] = 5000.0
		game.enemies.back()["max_hp"] = 5000.0
		game.enemies.back()["stun"] = 999.0
	game.set_process(false)

	_activate("ancorada_ev1_muralha_ruptura", "ancorada_ev2_fortaleza_autoportante")
	game.last_skill_time = -1000.0
	game._use_skill(game.player_pos + Vector2(130, 0))
	_advance(0.10, 5)
	game.effects.clear()
	await _capture("ancorada_evolution_wall_fortress_1280x720.png", true, false)

	game.anchors.clear()
	game.manifestation_secondaries.clear()
	_activate("ancorada_ev1_linha_fundacao", "ancorada_ev2_continente_imovel")
	game._place_anchor(game.player_pos + Vector2(-180, -80), game.player_pos, "ancorada_visual_a", true)
	game._place_anchor(game.player_pos + Vector2(160, -65), game.player_pos, "ancorada_visual_b", true)
	game._place_anchor(game.player_pos + Vector2(155, 110), game.player_pos, "ancorada_visual_c", true)
	game.ancorada_ability_controller.spawn_ultimate(game.player_pos)
	game.effects.clear()
	await _capture("ancorada_evolution_network_continent_1280x720.png", true, true)

	game.anchors.clear()
	game.manifestation_secondaries.clear()
	_activate("ancorada_ev1_territorio_jurado", "ancorada_ev2_ultimo_bastiao")
	game.player_hp_max = 1000.0
	game.player_hp = 240.0
	game.hab1_ancorada_active = false
	game.last_skill_time = -1000.0
	game._use_skill(game.player_pos)
	_advance(0.10, 5)
	game.effects.clear()
	root.size = Vector2i(960, 540)
	game.gfx_low_resource = true
	await process_frame
	await _capture("ancorada_evolution_domain_bastion_960x540.png", false, false)

	print("ANCORADA_EVOLUTION_VISUAL_OK captures=3 desktop=true mobile_landscape=true structures_readable=true " + ProjectSettings.globalize_path(OUT_DIR))
	game._cleanup_runtime_resources()
	game.queue_free()
	game = null
	for _frame in range(3):
		await process_frame
	quit(0)


func _capture(file_name: String, require_structure: bool, require_network: bool) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	var expected_size := Vector2i(960, 540) if file_name.contains("960x540") else Vector2i(1280, 720)
	_check(image != null and image.get_width() >= expected_size.x and image.get_height() >= expected_size.y, "invalid capture " + file_name)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var output := OUT_DIR.path_join(file_name)
	_check(image.save_png(output) == OK, "could not save " + file_name)
	_check(_foundation_signal_count(image) > 45, "foundation palette is not readable in " + file_name)
	if require_structure:
		_check(_dark_structure_count(image) > 24, "structural silhouette is missing in " + file_name)
	if require_network:
		_check(_cyan_signal_count(image) > 16, "load-transmission lines are missing in " + file_name)


func _foundation_signal_count(image: Image) -> int:
	var count := 0
	for y in range(0, image.get_height(), 6):
		for x in range(0, image.get_width(), 6):
			var color := image.get_pixel(x, y)
			if color.g > 0.48 and color.g > color.r * 1.18 and color.g > color.b * 0.88:
				count += 1
	return count


func _dark_structure_count(image: Image) -> int:
	var count := 0
	for y in range(0, image.get_height(), 6):
		for x in range(0, image.get_width(), 6):
			var color := image.get_pixel(x, y)
			if color.g > 0.14 and color.g < 0.58 and color.r < color.g * 1.05 and color.b < color.g * 1.05:
				count += 1
	return count


func _cyan_signal_count(image: Image) -> int:
	var count := 0
	for y in range(0, image.get_height(), 5):
		for x in range(0, image.get_width(), 5):
			var color := image.get_pixel(x, y)
			if color.b > 0.52 and color.g > 0.52 and color.r < color.g * 0.82:
				count += 1
	return count
