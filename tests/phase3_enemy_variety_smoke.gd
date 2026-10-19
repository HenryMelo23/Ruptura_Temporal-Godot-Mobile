extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _enemy(kind: String) -> Dictionary:
	for enemy in game.enemies:
		if String(enemy.get("type", "")) == kind:
			return enemy
	return {}


func _run() -> void:
	game._start_game()
	game._advance_to_phase(3)
	game.enemies.clear()
	var kinds := [
		game.ENEMY_DEVOTO,
		game.ENEMY_INCENSARIO,
		game.ENEMY_GUARDIAO,
		game.ENEMY_FLAGELANTE,
		game.ENEMY_SALMODIANTE,
		game.ENEMY_RELICARIO,
	]
	for i in range(kinds.size()):
		game._spawn_enemy(String(kinds[i]), Vector2(260.0 + float(i) * 150.0, 360.0))
	assert(game.enemies.size() == kinds.size())
	var texture_paths: Dictionary = {}
	for kind in kinds:
		var enemy := _enemy(String(kind))
		assert(not enemy.is_empty())
		enemy["phase"] = 0.0
		var texture_a: Texture2D = game._enemy_texture(enemy)
		enemy["phase"] = 1.0
		var texture_b: Texture2D = game._enemy_texture(enemy)
		assert(texture_a != null)
		assert(texture_b != null)
		assert(texture_a.get_size() == Vector2(259.0, 270.0))
		assert(texture_b.get_size() == Vector2(259.0, 270.0))
		var texture_a_path := String(texture_a.resource_path)
		var texture_b_path := String(texture_b.resource_path)
		assert(texture_a_path.ends_with("_01.png"))
		assert(texture_b_path.ends_with("_02.png"))
		assert(texture_a_path != texture_b_path)
		assert(not texture_paths.has(texture_a_path))
		assert(not texture_paths.has(texture_b_path))
		texture_paths[texture_a_path] = true
		texture_paths[texture_b_path] = true
		enemy["facing_dir"] = Vector2.RIGHT
		assert(not game._enemy_should_flip(enemy))
		enemy["facing_dir"] = Vector2.LEFT
		assert(game._enemy_should_flip(enemy))
		assert(game.NET_ENEMY_TYPES.has(kind))
	_enemy(game.ENEMY_FLAGELANTE)["phase3_surge_timer"] = 0.41
	_enemy(game.ENEMY_SALMODIANTE)["phase3_chant_prepare"] = 0.37
	_enemy(game.ENEMY_SALMODIANTE)["phase3_chant_target"] = Vector2(777.0, 333.0)
	_enemy(game.ENEMY_RELICARIO)["phase3_relic_pulse"] = 0.29
	_enemy(game.ENEMY_DEVOTO)["phase3_fervor_timer"] = 1.2
	var packed_enemies: PackedFloat32Array = game._pack_net_enemies()
	var unpacked_enemies: Array = game.RTNetContractScript.unpack_enemy_snapshot(
		packed_enemies,
		{},
		game.NET_ENEMY_TYPES,
		game.ENEMY_COMMON,
		game.NET_LEECH_STATES,
		game.ENEMY_CHRONAL_LEECH,
		Time.get_ticks_msec()
	)
	for kind in kinds:
		assert(unpacked_enemies.any(func(enemy): return String(enemy.get("type", "")) == String(kind)))
	var remote_flagelante: Dictionary = unpacked_enemies.filter(func(enemy): return String(enemy.get("type", "")) == game.ENEMY_FLAGELANTE)[0]
	var remote_salmodiante: Dictionary = unpacked_enemies.filter(func(enemy): return String(enemy.get("type", "")) == game.ENEMY_SALMODIANTE)[0]
	var remote_relicario: Dictionary = unpacked_enemies.filter(func(enemy): return String(enemy.get("type", "")) == game.ENEMY_RELICARIO)[0]
	var remote_devoto: Dictionary = unpacked_enemies.filter(func(enemy): return String(enemy.get("type", "")) == game.ENEMY_DEVOTO)[0]
	assert(is_equal_approx(float(remote_flagelante.get("phase3_surge_timer", 0.0)), 0.41))
	assert(is_equal_approx(float(remote_salmodiante.get("phase3_chant_prepare", 0.0)), 0.37))
	assert(Vector2(remote_salmodiante.get("phase3_chant_target", Vector2.ZERO)).is_equal_approx(Vector2(777.0, 333.0)))
	assert(is_equal_approx(float(remote_relicario.get("phase3_relic_pulse", 0.0)), 0.29))
	assert(is_equal_approx(float(remote_devoto.get("phase3_fervor_timer", 0.0)), 1.2))
	var previous_packet: PackedFloat32Array = packed_enemies.slice(0, game.RTNetContractScript.PREVIOUS_ENEMY_STRIDE)
	previous_packet[53] = game.RTNetContractScript.PREVIOUS_ENEMY_SNAPSHOT_SCHEMA
	var previous_unpacked: Array = game.RTNetContractScript.unpack_enemy_snapshot(
		previous_packet, {}, game.NET_ENEMY_TYPES, game.ENEMY_COMMON, game.NET_LEECH_STATES,
		game.ENEMY_CHRONAL_LEECH, Time.get_ticks_msec()
	)
	assert(previous_unpacked.size() == 1)
	assert(String(previous_unpacked[0].get("type", "")) == game.ENEMY_DEVOTO)

	var flagelante := _enemy(game.ENEMY_FLAGELANTE)
	var flagelante_start := Vector2(flagelante["pos"])
	flagelante["phase3_surge_cd"] = 0.0
	game.phase3_enemy_controller.update_enemy(flagelante, 0.1)
	assert(float(flagelante["phase3_surge_timer"]) > 0.0)
	assert(Vector2(flagelante["pos"]).distance_to(flagelante_start) > 0.0)

	var salmodiante := _enemy(game.ENEMY_SALMODIANTE)
	salmodiante["shoot_cd"] = 0.0
	var bullets_before: int = game.enemy_bullets.size()
	game.phase3_enemy_controller.update_enemy(salmodiante, 0.01)
	assert(float(salmodiante["phase3_chant_prepare"]) > 0.0)
	assert(game.enemy_bullets.size() == bullets_before)
	game.phase3_enemy_controller.update_enemy(salmodiante, game.PHASE3_SALMODIANTE_WINDUP + 0.01)
	assert(game.enemy_bullets.size() == bullets_before + 3)

	var relicario := _enemy(game.ENEMY_RELICARIO)
	var devoto := _enemy(game.ENEMY_DEVOTO)
	relicario["pos"] = Vector2(500.0, 420.0)
	devoto["pos"] = Vector2(540.0, 420.0)
	relicario["phase3_relic_cd"] = 0.0
	game.phase3_enemy_controller.update_enemy(relicario, 0.01)
	assert(float(devoto["phase3_fervor_timer"]) > 0.0)
	assert(is_equal_approx(game.phase3_enemy_controller.movement_speed_multiplier(devoto), game.PHASE3_RELIC_FERVOR_SPEED_MULT))

	game.run_pacing_profile = game.PACING_PROFILE_ONBOARDING
	assert(is_equal_approx(game._phase3_flagelante_unlock_time(), 150.0))
	assert(is_equal_approx(game._phase3_salmodiante_unlock_time(), 210.0))
	assert(is_equal_approx(game._phase3_relicario_unlock_time(), 300.0))
	game.run_pacing_profile = game.PACING_PROFILE_EXPERIENCED
	assert(is_equal_approx(game._phase3_flagelante_unlock_time(), 110.0))
	assert(is_equal_approx(game._phase3_salmodiante_unlock_time(), 160.0))
	assert(is_equal_approx(game._phase3_relicario_unlock_time(), 225.0))

	print("PHASE3_ENEMY_VARIETY_SMOKE_OK kinds=%d walk_frames=%d mirrored_directions=%d net_roundtrip=%d fan_projectiles=3 fervor=%.2f" % [kinds.size(), texture_paths.size(), kinds.size(), unpacked_enemies.size(), float(devoto["phase3_fervor_timer"])])
	game.mode = "menu"
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.visible = false
	game.set_process(false)
	game.set_physics_process(false)
	game._cleanup_runtime_resources()
	for i in range(4):
		await process_frame
	root.remove_child(game)
	game.free()
	game = null
	await process_frame
	await process_frame
	quit(0)
