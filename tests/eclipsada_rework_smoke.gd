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
	_spawn_enemy(Vector2(880, 420), 360.0, game.ENEMY_COMMON)

	_check(game.eclipsada_form == game.ECLIPSADA_FORM_LUA, "default form is not Lua")
	game._try_attack()
	_check(game.bullets.is_empty(), "Lua ATK should be melee blades, not a shuriken")
	_check(float(game.enemies[0].get("hp", 0.0)) < 360.0, "Lua blade did not damage enemy inside 180px")
	_check(game.eclipsada_vfx.any(func(visual): return String(visual.get("style", "")) == "lua_blades"), "Lua blade VFX missing")

	game.bullets.clear()
	game.enemies.clear()
	game.last_attack_time = -999.0
	game.eclipsada_next_attack_time = 0.0
	game._try_attack()
	_check(game.bullets.is_empty(), "Lua blade should not leave ranged bullets behind")

	_check(game._toggle_eclipsada_form(), "form toggle returned false")
	_check(game.eclipsada_form == game.ECLIPSADA_FORM_SOL, "form did not toggle to Sol")
	_check(game.eclipsada_vfx.any(func(visual): return String(visual.get("kind", "")) == "form_swap"), "form swap VFX missing")
	game.bullets.clear()
	game.enemies.clear()
	_spawn_enemy(Vector2(880, 420), 360.0, game.ENEMY_COMMON)
	game.last_attack_time = -999.0
	game.eclipsada_next_attack_time = 0.0
	game._try_attack()
	_check(game.bullets.size() == 1, "Sol ATK did not spawn one shuriken")
	_check(String(game.bullets[0].get("kind", "")) == "eclipsada_sol", "Sol ATK projectile kind mismatch")
	_check(not bool(game.bullets[0].get("pierce", true)), "Sol shuriken should not pierce")
	_check(bool(game.bullets[0].get("solar_splash", false)), "Sol shuriken did not carry splash flag")

	game.eclipsada_sol_last_skill_time = -999.0
	game._sync_eclipsada_visible_cooldowns()
	game.bullets.clear()
	game._use_skill(game.player_pos + Vector2.RIGHT * 180.0)
	_check(game.bullets.size() == 3, "Sol Q did not fire a 3-shuriken fan")
	_check(game.eclipsada_vfx.any(func(visual): return String(visual.get("kind", "")) == "q_sol"), "Sol Q VFX missing")
	_check(game.eclipsada_vfx.any(func(visual): return String(visual.get("kind", "")) == "q_sol" and not bool(visual.get("draw_bars", true))), "Sol Q VFX should not draw yellow bars")
	_check(not game.eclipsada_lua_stealth_active, "Sol Q should not enable Lua stealth")

	game.eclipsada_sol_last_secondary_time = -999.0
	game._sync_eclipsada_visible_cooldowns()
	game._use_secondary_skill(game.player_pos + Vector2.RIGHT * 180.0)
	_check(game.manifestation_secondaries.any(func(sec): return String(sec.get("kind", "")) == "eclipsada_sol"), "Sol E did not create solar secondary")
	var saw_sol_pulse := false
	for i in range(14):
		game._update_eclipsada_state(0.12)
		if game.eclipsada_vfx.any(func(visual): return String(visual.get("kind", "")) == "sol_pulse"):
			saw_sol_pulse = true
		await process_frame
	_check(saw_sol_pulse, "Sol E did not pulse VFX")

	_check(game._toggle_eclipsada_form(), "form toggle back returned false")
	_check(game.eclipsada_form == game.ECLIPSADA_FORM_LUA, "form did not toggle back to Lua")
	var pos_before: Vector2 = game.player_pos
	game.eclipsada_lua_last_skill_time = -999.0
	game._sync_eclipsada_visible_cooldowns()
	game.bullets.clear()
	game.effects.clear()
	game._use_skill(game.player_pos + Vector2.RIGHT * 100.0)
	_check(game.player_pos.distance_to(pos_before) < 1.0, "Lua Q should toggle stealth without dashing")
	_check(game.eclipsada_lua_stealth_active, "Lua Q did not enable toggle stealth")
	_check(game._eclipsada_stealth_overlay_alpha() > 0.0, "Lua Q stealth did not enable blue overlay")
	_check(game.eclipsada_vfx.any(func(visual): return String(visual.get("kind", "")) == "q_dash"), "Lua Q did not create dash VFX")
	_check(not game._local_player_targetable(), "stealthed Eclipsada is still targetable by enemies")
	_check(not game._player_invulnerable(), "Lua stealth should not make player invulnerable")
	var hp_before_drain: float = game.player_hp
	for i in range(5):
		game._update_eclipsada_state(1.0)
		await process_frame
	_check(game.player_hp < hp_before_drain, "Lua stealth did not drain HP after safe time")
	game._use_skill(game.player_pos + Vector2.RIGHT * 100.0)
	_check(not game.eclipsada_lua_stealth_active, "Lua Q did not disable toggle stealth")
	_check(abs(game.eclipsada_lua_last_skill_time - game.time_alive) < 0.01, "Lua stealth cooldown did not start on disable")
	game._use_skill(game.player_pos + Vector2.RIGHT * 100.0)
	_check(not game.eclipsada_lua_stealth_active, "Lua stealth ignored cooldown after disable")

	game.enemies.clear()
	_spawn_enemy(Vector2(842, 420), 18.0, game.ENEMY_PROJECTOR)
	_spawn_enemy(Vector2(900, 420), 120.0, game.ENEMY_COMMON)
	_spawn_enemy(Vector2(990, 420), 120.0, game.ENEMY_STALKER)
	game.eclipsada_lua_stealth_active = false
	game.eclipsada_lua_last_secondary_time = -999.0
	game._sync_eclipsada_visible_cooldowns()
	game.player_pos = Vector2(700, 420)
	game._use_secondary_skill(Vector2(842, 420))
	_check(game.manifestation_secondaries.any(func(sec): return String(sec.get("kind", "")) == "eclipsada_lua_eclipse"), "Lua E did not create eclipse secondary")
	_check(not game._player_invulnerable(), "Lua E should not grant invulnerability")
	for i in range(50):
		game._update_eclipsada_state(0.08)
		await process_frame
		if game.enemies.size() < 3:
			break
	_check(game.enemies.size() < 3, "Lua E eclipse did not cut and remove a low HP target")

	game.eclipsada_passive_timer = 0.0
	var trait_enemy: Dictionary = game.enemies[0]
	game._try_gain_eclipsada_trait(trait_enemy)
	_check(game.eclipsada_trait_timer > 59.0, "passive did not copy trait")
	_check(game.eclipsada_passive_timer > 79.0, "passive cooldown did not restart")
	_check(String(game._manifestation_details("eclipsada").get("disparo", "")).contains("laminas"), "catalog did not describe Lua blades")

	print("ECLIPSADA_REWORK_SMOKE_OK forms=true lua_blades=true stealth_toggle=true e_variants=true passive=true")
	game._cleanup_runtime_resources()
	if game.music_player != null:
		game.music_player.stop()
		game.music_player.stream = null
	if game.rain_audio_player != null:
		game.rain_audio_player.stop()
		game.rain_audio_player.stream = null
	for player in game.sfx_players:
		if player != null:
			player.stop()
			player.stream = null
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
