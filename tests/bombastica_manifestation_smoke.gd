extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _manifestation_index(key: String) -> int:
	for i in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[i].get("key", "")) == key:
			return i
	return -1


func _spawn_test_enemy(pos: Vector2, hp := 1000.0) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var enemy: Dictionary = game.enemies[-1]
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	return enemy


func _run() -> void:
	await process_frame
	var bombastica_index := _manifestation_index("bombastica")
	_check(bombastica_index >= 0, "Bombastica was not registered in MANIFESTATIONS")
	_check(game._manifest_select_item_texture(game.MANIFESTATIONS[bombastica_index], false) != null, "Bombastica icon did not load")

	game.selected_manifestation = bombastica_index
	game.selected_aura = 0
	game._start_game()
	game.manifestation_key = "bombastica"
	game.player_damage = 100.0
	game.player_pos = Vector2(640, 360)
	game.last_facing = Vector2.RIGHT
	game.attack_dragging = true
	game.attack_drag_direction = Vector2.RIGHT
	game.time_alive = 30.0
	game.last_attack_time = -999.0
	game.last_skill_time = -999.0
	game.last_secondary_time = -999.0
	game.enemies.clear()
	game.bullets.clear()
	game.bombastica_bombs.clear()
	game.bombastica_powder_marks.clear()
	game.bombastica_vfx.clear()
	game.manifestation_secondaries.clear()
	game.boss_active = false

	_check(is_equal_approx(game._manifestation_base_damage(), game.PLAYER_BASE_DAMAGE * 0.90), "Bombastica base damage is not normalized to 90%")
	_check(is_equal_approx(game._manifestation_attack_interval(), 0.58), "Bombastica base cadence is not 0.58s")
	_check(game._ground_target_profile(false).has("radius"), "Bombastica Q does not expose a ground targeting profile")
	_check(game._ground_target_profile(true).has("radius"), "Bombastica E does not expose a ground targeting profile")
	_check(game.audio_streams.has("Bomba-Bombastica.mp3"), "Bombastica bomb SFX is not registered")
	_check(game.audio_streams.has("Mina-Bombastica.mp3"), "Bombastica mine SFX is not registered")

	var enemy: Dictionary = _spawn_test_enemy(game.player_pos + Vector2(96, 0), 1000.0)
	game._try_attack()
	_check(game.bullets.size() == 1, "Bombastica ATK did not create a projectile")
	_check(String(game.bullets[0].get("kind", "")) == "bombastica", "Bombastica ATK projectile has wrong kind")
	game._apply_bullet_effect(game.bullets[0], enemy)
	var powder_key: String = game._bombastica_target_key("enemy", int(enemy["uid"]))
	_check(game.bombastica_powder_marks.has(powder_key), "Bombastica ATK did not apply Polvora Instavel")
	_check(int(game.bombastica_powder_marks[powder_key].get("stacks", 0)) == 1, "Bombastica ATK did not create one powder stack")

	game._apply_bombastica_powder_to_target("enemy", int(enemy["uid"]), Vector2(enemy["pos"]))
	game._apply_bombastica_powder_to_target("enemy", int(enemy["uid"]), Vector2(enemy["pos"]))
	_check(int(game.bombastica_powder_marks[powder_key].get("stacks", 0)) == game.BOMBASTICA_POWDER_MAX_STACKS, "Bombastica powder did not cap at three stacks")

	var hp_before_q: float = float(enemy["hp"])
	for player in game.sfx_players:
		player.stop()
		player.stream = null
	game._try_cast_bombastica_q(Vector2(enemy["pos"]))
	_check(game.sfx_players.any(func(player): return player.stream == game.audio_streams["Bomba-Bombastica.mp3"]), "Bombastica Q did not play bomb SFX")
	_check(game.bombastica_bombs.size() == 1, "Bombastica Q did not create a bomb")
	_check(game._bombastica_ready_charges() == 2, "Bombastica Q did not consume exactly one charge")
	game.bombastica_bombs[0]["state"] = "armed"
	game.bombastica_bombs[0]["pos"] = Vector2(enemy["pos"])
	game.bombastica_bombs[0]["fuse"] = 0.01
	game._update_bombastica_state(0.05)
	_check(float(enemy["hp"]) < hp_before_q, "Bombastica Q explosion did not damage enemy")
	_check(not game.bombastica_powder_marks.has(powder_key), "Bombastica ignition did not consume max powder stacks")

	game.last_secondary_time = -999.0
	var mine_enemy: Dictionary = _spawn_test_enemy(game.player_pos + Vector2(150, 0), 1000.0)
	for player in game.sfx_players:
		player.stop()
		player.stream = null
	game._use_secondary_skill(Vector2(mine_enemy["pos"]))
	_check(game.sfx_players.any(func(player): return player.stream == game.audio_streams["Mina-Bombastica.mp3"]), "Bombastica E did not play minefield SFX")
	_check(not game.manifestation_secondaries.is_empty(), "Bombastica E did not create a minefield")
	var minefield: Dictionary = game.manifestation_secondaries[-1]
	_check(String(minefield.get("kind", "")) == "bombastica", "Bombastica E secondary has wrong kind")
	_check(Array(minefield.get("mines", [])).size() == game.BOMBASTICA_E_MINE_COUNT, "Bombastica E did not create five mines")
	var mines: Array = minefield["mines"]
	mine_enemy["pos"] = Vector2(mines[0].get("pos", mine_enemy["pos"]))
	var hp_before_mine: float = float(mine_enemy["hp"])
	game._update_secondary_bombastica(minefield, game.BOMBASTICA_E_ARM_TIME + 0.05)
	_check(float(mine_enemy["hp"]) < hp_before_mine, "Bombastica E mine did not damage enemy")

	game.bombastica_bombs.clear()
	var chain_radius: float = game.BOMBASTICA_Q_RADIUS
	game.bombastica_bombs.append({"id": 101, "kind": "q_bomb", "pos": game.player_pos, "state": "armed", "fuse": 4.0, "fuse_total": 4.0, "damage": 10.0, "radius": chain_radius, "exploded": false})
	game.bombastica_bombs.append({"id": 102, "kind": "q_bomb", "pos": game.player_pos + Vector2(chain_radius * 2.0 - 1.0, 0), "state": "armed", "fuse": 4.0, "fuse_total": 4.0, "damage": 10.0, "radius": chain_radius, "exploded": false})
	game._detonate_bombastica_bomb(game.bombastica_bombs[0], false, 0, {})
	_check(bool(game.bombastica_bombs[1].get("exploded", false)), "Bombastica chain did not detonate a bomb whose radii were touching")

	game.bombastica_bombs.clear()
	game.bombastica_q_recharges = [0.0, 0.0, 0.0]
	game._try_cast_bombastica_q(game.player_pos + Vector2(130, 0))
	game._try_cast_bombastica_q(game.player_pos + Vector2(164, 0))
	_check(game.bombastica_bombs.size() >= 2, "Bombastica did not keep multiple Q bombs for chain/detonation")
	for bomb in game.bombastica_bombs:
		bomb["state"] = "armed"
	_check(game._trigger_bombastica_detonator(false), "Bombastica detonator did not trigger an armed bomb")
	_check(game.bombastica_bombs.any(func(bomb): return bool(bomb.get("exploded", false))), "Bombastica detonator did not mark chained bombs as exploded")

	var details: Dictionary = game._manifestation_details("bombastica")
	_check(String(details.get("habilidade", "")).contains("Triade"), "Bombastica details do not explain Q")
	_check(String(details.get("traco", "")).contains("Campo Minado"), "Bombastica details do not explain E")
	game._reset_advanced_manifestation_state()
	_check(game.bombastica_bombs.is_empty(), "Bombastica reset did not clear bombs")
	_check(game.bombastica_powder_marks.is_empty(), "Bombastica reset did not clear powder marks")
	print("BOMBASTICA_MANIFESTATION_SMOKE_OK icon=true atk=true powder=true q=true e=true chain=true detonator=true reset=true")
	root.remove_child(game)
	game.queue_free()
	await process_frame
	quit(0)
