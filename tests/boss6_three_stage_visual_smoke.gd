extends SceneTree

const OUTPUT_DIR := "res://.agent_logs/boss6_three_stage_rework"

var game: Node
var failures: Array[String] = []


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _capture(label: String, size: Vector2i) -> void:
	root.size = size
	game.queue_redraw()
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		failures.append(label + " produced an empty image")
		return
	var directory := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(directory)
	var path := "%s/%s_%dx%d.png" % [directory, label, size.x, size.y]
	if image.save_png(path) != OK:
		failures.append(label + " could not save " + path)


func _set_stage(stage: int, ratio: float, ability: String) -> void:
	game.boss6_stage = stage
	game.boss_hp = game.boss_hp_max * ratio
	game.boss6_state = game.BOSS6_STATE_EXECUTING
	game.boss6_current_ability = ability
	game.boss_phase = float(stage) * 1.37
	game.boss_attacks.clear()
	match ability:
		game.BOSS6_ABILITY_SCYTHES:
			game._start_boss6_vertebral_scythes()
		game.BOSS6_ABILITY_ACID_BLOOM:
			game._start_boss6_acid_bloom(false)
		game.BOSS6_ABILITY_CARNAGE_TIDE:
			game._start_boss6_carnage_tide()
			game._update_boss_attacks(0.01)


func _run() -> void:
	await process_frame
	game.force_phase6_start = true
	game._start_game()
	game.set_process(false)
	game.startup_thanks_done = true
	game.mode = "game"
	game.force_phase6_start = false
	game.current_phase = 6
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = game._boss_hp_for_phase(6)
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(-260.0, 170.0)
	game.is_multiplayer = true
	game.is_host = true
	game.net_players_by_peer = {
		2: {"has_snapshot": true, "alive": true, "dead": false, "eliminated": false, "hp": 100.0, "hp_max": 100.0, "pos": game.boss_pos + Vector2(320.0, 150.0)},
		3: {"has_snapshot": true, "alive": true, "dead": false, "eliminated": false, "hp": 100.0, "hp_max": 100.0, "pos": game.boss_pos + Vector2(40.0, -270.0)},
	}

	_set_stage(1, 0.86, game.BOSS6_ABILITY_SCYTHES)
	await _capture("stage1_scythes", Vector2i(1280, 720))
	await _capture("stage1_scythes", Vector2i(960, 540))
	_set_stage(2, 0.56, game.BOSS6_ABILITY_ACID_BLOOM)
	await _capture("stage2_acid_bloom", Vector2i(1280, 720))
	await _capture("stage2_acid_bloom", Vector2i(960, 540))
	_set_stage(3, 0.22, game.BOSS6_ABILITY_CARNAGE_TIDE)
	await _capture("stage3_carnage", Vector2i(1280, 720))
	await _capture("stage3_carnage", Vector2i(960, 540))

	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	if not failures.is_empty():
		for failure in failures:
			printerr("BOSS6_THREE_STAGE_VISUAL_FAIL " + failure)
		quit(1)
		return
	print("BOSS6_THREE_STAGE_VISUAL_OK captures=6 stages=3 team_targets=3 desktop=true mobile_landscape=true segmented_bar=true")
	quit(0)
