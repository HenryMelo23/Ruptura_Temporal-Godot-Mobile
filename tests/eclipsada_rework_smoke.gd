extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("ECLIPSADA_REWORK_SMOKE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var index := _manifestation_index("eclipsada")
	_check(index >= 0, "eclipsada manifestation not registered")
	game.selected_manifestation = index
	game.selected_aura = 0
	game._start_game()
	game.mode = "game"
	game.manifestation_key = "eclipsada"
	game.preview_capture_mode = true
	game.vol_master = 0.0
	game.vol_music = 0.0
	game.vol_sfx = 0.0
	game.qa_streaming_enabled = false
	game.qa_streaming_frame_active = false
	game.qa_streaming_permission_pending = false
	game._reset_qa_streaming_runtime()
	game.is_multiplayer = false
	game.player_pos = Vector2(700, 420)
	game.last_facing = Vector2.RIGHT
	game.attack_dragging = true
	game.attack_drag_direction = Vector2.RIGHT
	game.time_alive = 10.0
	game.last_attack_time = -999.0
	game.last_skill_time = -999.0
	game.last_secondary_time = -999.0
	game.bullets.clear()
	game.enemies.clear()
	_spawn_enemy(Vector2(724, 420), 360.0, game.ENEMY_COMMON)
	_spawn_enemy(Vector2(780, 420), 360.0, game.ENEMY_STALKER)
	_spawn_enemy(Vector2(842, 420), 28.0, game.ENEMY_PROJECTOR)

	var hp_before := float(game.enemies[0]["hp"])
	var ranged_hp_before := float(game.enemies[1]["hp"])
	game._try_attack()
	_check(game.bullets.is_empty(), "eclipsada ATK spawned projectile")
	_check(float(game.enemies[0]["hp"]) < hp_before, "first short slash did not damage nearby enemy")
	_check(float(game.enemies[1]["hp"]) < ranged_hp_before, "ATK radius did not reach 80px target")
	_check(game.eclipsada_vfx.any(func(visual): return String(visual.get("kind", "")) == "attack"), "ATK did not create slash VFX")
	_check(game.eclipsada_attack_step == 1, "first slash did not advance combo")
	_check(abs(game.eclipsada_next_attack_time - 10.3) < 0.02, "first slash interval is not 0.300s")

	for hit in range(2, 5):
		game.time_alive = game.eclipsada_next_attack_time
		game._try_attack()
		_check(game.eclipsada_attack_step == (0 if hit == 4 else hit), "combo step mismatch at hit %d" % hit)
	_check(abs(game.eclipsada_next_attack_time - (game.time_alive + 1.2)) < 0.03, "fourth slash cooldown is not 1.2s")

	var pos_before: Vector2 = game.player_pos
	game.last_skill_time = -999.0
	game._use_skill(game.player_pos + Vector2.RIGHT * 100.0)
	_check(game.player_pos.distance_to(pos_before) >= 18.0, "Q did not dash about 20px")
	_check(game.eclipsada_q_speed_timer > 5.8, "Q speed timer missing")
	_check(abs(game._eclipsada_speed_multiplier() - 1.20) < 0.001, "Q speed bonus is not 20 percent")
	_check(game.eclipsada_stealth_timer > 4.8, "Q stealth timer missing")
	_check(game._eclipsada_stealth_overlay_alpha() > 0.0, "Q stealth did not enable blue overlay")
	_check(game.eclipsada_vfx.any(func(visual): return String(visual.get("kind", "")) == "q_dash"), "Q did not create dash VFX")
	_check(game.enemies.all(func(enemy): return float(enemy.get("eclipsada_weak_time", 0.0)) > 4.8), "Q did not create weak points")
	_check(not game._local_player_targetable(), "stealthed eclipsada is still targetable by enemies")

	game.enemies.clear()
	_spawn_enemy(Vector2(842, 420), 18.0, game.ENEMY_PROJECTOR)
	_spawn_enemy(Vector2(900, 420), 120.0, game.ENEMY_COMMON)
	_spawn_enemy(Vector2(990, 420), 120.0, game.ENEMY_STALKER)
	game.eclipsada_stealth_timer = 0.0
	game.last_secondary_time = -999.0
	game.player_pos = Vector2(700, 420)
	game._use_secondary_skill(Vector2(842, 420))
	_check(not game._active_eclipsada_secondary().is_empty(), "E did not start execution secondary")
	_check(game._player_invulnerable(), "E execution is not invulnerable")
	_check(game.eclipsada_vfx.any(func(visual): return String(visual.get("kind", "")) == "e_entry"), "E did not create entry VFX")
	for i in range(50):
		game._update_eclipsada_state(0.08)
		await process_frame
		if game.enemies.size() < 3 or game._active_eclipsada_secondary().is_empty():
			break
	_check(game.enemies.size() < 3, "E did not execute and remove a low HP target")
	_check(game.eclipsada_vfx.any(func(visual): return String(visual.get("kind", "")) == "e_cut"), "E did not create cut VFX")

	if not game._active_eclipsada_secondary().is_empty():
		game._use_secondary_skill(Vector2(game.enemies[0]["pos"]))
		_check(game._active_eclipsada_secondary().is_empty(), "E did not cancel active chain")
	game.last_secondary_time = -999.0
	game._use_secondary_skill(Vector2(game.enemies[0]["pos"]))
	_check(not game._active_eclipsada_secondary().is_empty(), "E did not restart for cancel test")
	game._use_secondary_skill(Vector2(game.enemies[0]["pos"]))
	_check(game._active_eclipsada_secondary().is_empty(), "E did not cancel on second press")

	game.eclipsada_passive_timer = 0.0
	var trait_enemy: Dictionary = game.enemies[0]
	game._try_gain_eclipsada_trait(trait_enemy)
	_check(game.eclipsada_trait_timer > 59.0, "passive did not copy trait")
	_check(game.eclipsada_passive_timer > 79.0, "passive cooldown did not restart")
	_check(game._manifestation_details("eclipsada").has("info_rows"), "catalog details missing rows")

	print("ECLIPSADA_REWORK_SMOKE_OK atk_combo=true q_stealth=true e_chain=true passive=true")
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
	for i in range(4):
		await process_frame
	quit(0)


func _manifestation_index(key: String) -> int:
	for i in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[i].get("key", "")) == key:
			return i
	return -1


func _spawn_enemy(pos: Vector2, hp: float, enemy_type: String) -> void:
	game._spawn_enemy(enemy_type, pos)
	var index: int = game.enemies.size() - 1
	game.enemies[index]["hp"] = hp
	game.enemies[index]["max_hp"] = hp
	game.enemies[index]["stun"] = 999.0
