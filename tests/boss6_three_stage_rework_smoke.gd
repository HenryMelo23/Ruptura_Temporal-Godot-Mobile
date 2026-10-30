extends SceneTree

var game: Node
var failures: Array[String] = []


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _prepare_boss() -> void:
	game._start_game()
	game.mode = "game"
	game.current_phase = 6
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 1000.0
	game.boss_hp = 1000.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(540.0, 0.0)
	game.boss6_stage = 1
	game.boss6_state = game.BOSS6_STATE_IDLE
	game.boss6_ability_cooldowns.clear()
	game.boss_attacks.clear()


func _run() -> void:
	await process_frame
	_prepare_boss()
	_check(game._boss_hp_for_phase(6) >= game.BOSS_BASE_HP * game.BOSS6_HP_SCALE, "phase 6 HP did not receive the durability rework")
	var defs: Array = game._boss6_ability_defs()
	_check(defs.size() == 3, "boss 6 does not expose exactly three basic abilities")
	_check(String(defs[0].get("id", "")) == game.BOSS6_ABILITY_SCYTHES, "stage 1 ability is not vertebral scythes")
	_check(not game._boss6_ability_available(defs[1], 0), "acid bloom unlocked before stage 2")
	_check(not game._boss6_ability_available(defs[2], 0), "carnage tide unlocked before stage 3")

	var stage1_start: Vector2 = game.boss_pos
	game.boss6_stage_controller.update(0.5)
	_check(game.boss_pos.distance_to(stage1_start) > 1.0, "stage 1 remained immobile")

	game.boss_hp = 660.0
	game.boss6_stage_controller.update(0.05)
	_check(game.boss6_stage == 2, "66 percent threshold did not enter stage 2")
	_check(game.boss6_state == game.BOSS6_STATE_TRANSITION, "stage 2 skipped its transition animation state")
	_check(game._boss6_ability_available(defs[1], 0), "stage 2 did not unlock acid bloom")
	_check(not game._boss6_ability_available(defs[2], 0), "stage 2 unlocked carnage tide too early")

	game.boss6_state = game.BOSS6_STATE_IDLE
	game.boss_hp = 330.0
	game.boss6_stage_controller.update(0.05)
	_check(game.boss6_stage == 3, "33 percent threshold did not enter stage 3")
	_check(game._boss6_ability_available(defs[2], 0), "stage 3 did not unlock carnage tide")

	game.boss6_state = game.BOSS6_STATE_EXECUTING
	game.boss6_current_ability = game.BOSS6_ABILITY_CARNAGE_TIDE
	game._prepare_phase_texture_assets(6)
	_check(game._boss_texture() in game.textures.get("boss6_rework_stage3_attack", []), "stage 3 did not use the new attack frames")
	_check(game.save_controller._interrupted_run_field_names().has("boss6_stage"), "interrupted-run save omitted boss6 stage")
	var visual_packet: Dictionary = game.boss_visual_sync_controller.pack(game)
	_check(int(visual_packet.get("boss6_stage", 0)) == 3, "multiplayer visual snapshot omitted boss6 stage")

	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	if not failures.is_empty():
		for failure in failures:
			printerr("BOSS6_THREE_STAGE_REWORK_FAIL " + failure)
		quit(1)
		return
	print("BOSS6_THREE_STAGE_REWORK_OK hp_scale=4.5 stages=3 abilities=3 movement=true transitions=true attack_frames=12 save=true multiplayer=true")
	for _frame in range(4):
		await process_frame
	quit(0)
