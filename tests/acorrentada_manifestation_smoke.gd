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


func _spawn_test_enemy(pos: Vector2, hp := 1000.0) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var enemy: Dictionary = game.enemies[-1]
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	return enemy


func _run() -> void:
	await process_frame
	var acorrentada_index := -1
	for i in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[i].get("key", "")) == "acorrentada":
			acorrentada_index = i
			break
	_check(acorrentada_index >= 0, "Acorrentada was not registered in MANIFESTATIONS")
	_check(game._manifest_select_item_texture(game.MANIFESTATIONS[acorrentada_index], false) != null, "Acorrentada icon did not load")

	game.selected_manifestation = acorrentada_index
	game._start_game()
	game.manifestation_key = "acorrentada"
	game.player_damage = 100.0
	game.player_pos = Vector2(700, 450)
	game.last_facing = Vector2.RIGHT
	game.time_alive = 20.0
	game.enemies.clear()
	game.boss_active = false

	var first := _spawn_test_enemy(game.player_pos + Vector2(150, 0))
	game._perform_acorrentada_attack()
	_check(game._acorrentada_enemy_elos(first) == 1, "attack 1 did not apply one Elo")
	_check(game.acorrentada_combo_step == 2, "attack 1 did not advance combo to step 2")
	_check(game.acorrentada_tension > 0.0, "attack 1 did not generate tension")

	game._perform_acorrentada_attack()
	_check(game._acorrentada_enemy_elos(first) >= 2, "attack 2 did not preserve/apply Elos")
	_check(game.acorrentada_combo_step == 3, "attack 2 did not advance combo to step 3")
	game._add_acorrentada_elo_enemy(first, 5)
	_check(game._acorrentada_enemy_elos(first) == game.ACORRENTADA_MAX_ELOS, "Elos exceeded max stack")
	game._perform_acorrentada_attack()
	_check(game._acorrentada_enemy_elos(first) == 0, "attack 3 did not consume Elos")
	_check(game.acorrentada_combo_step == 1, "attack 3 did not reset combo")

	game.acorrentada_combo_step = 2
	game.acorrentada_combo_reset_timer = 0.01
	game._update_acorrentada_state(0.05)
	_check(game.acorrentada_combo_step == 1, "combo did not reset after timer")

	game.enemies.clear()
	var a := _spawn_test_enemy(game.player_pos + Vector2(130, -26), 1000.0)
	var b := _spawn_test_enemy(game.player_pos + Vector2(160, 28), 1000.0)
	_check(game._cast_acorrentada_q(game.player_pos + Vector2(145, 0)), "Q did not cast with two enemies")
	_check(not game.acorrentada_links.is_empty(), "Q did not create a link")
	var b_hp_before := float(b["hp"])
	game._damage_enemy(a, 100.0, "acorrentada_attack_1", false, false, game.player_pos, "basic_attack")
	_check(float(b["hp"]) < b_hp_before, "Q did not share direct damage")

	game.acorrentada_tension = 100.0
	game.acorrentada_overcharge_ready = true
	_check(game._cast_acorrentada_e(game.player_pos + Vector2(145, 0)), "E did not cast")
	_check(game.acorrentada_tension == 35.0, "overcharge E did not drop tension to 35")
	for secondary in game.manifestation_secondaries:
		if String(secondary.get("kind", "")) == "acorrentada":
			secondary["life"] = 0.0
	game._update_secondary_acorrentada(game.manifestation_secondaries[-1], 0.7)
	_check(game._acorrentada_enemy_elos(a) == 0, "E did not consume target Elos")
	_check(game.acorrentada_force_next_attack_3, "overcharge E did not force next attack 3")

	game.enemies.clear()
	var tp_enemy := _spawn_test_enemy(game.player_pos + Vector2(110, 0), 1000.0)
	game.acorrentada_combo_step = 1
	game._start_tp_acorrentada(game.player_pos, game.player_pos + Vector2(260, 0))
	_check(game._acorrentada_enemy_elos(tp_enemy) >= 1, "TP did not apply an Elo to target on line")
	_check(game.acorrentada_combo_step == 2, "TP did not advance combo from marked target")
	game._update_tp_acorrentada(game.tp_effects[-1], 0.05)
	var tp_elos: int = game._acorrentada_enemy_elos(tp_enemy)
	game._update_tp_acorrentada(game.tp_effects[-1], 0.05)
	_check(game._acorrentada_enemy_elos(tp_enemy) == tp_elos, "TP line applied multiple Elos to same enemy")

	game._reset_advanced_manifestation_state()
	_check(game.acorrentada_combo_step == 1, "reset did not restore combo")
	_check(game.acorrentada_tension == 0.0, "reset did not clear tension")
	_check(game.acorrentada_links.is_empty(), "reset did not clear links")
	_check(game._acorrentada_enemy_elos(tp_enemy) == 0, "reset did not clear enemy Elos")

	var details: Dictionary = game._manifestation_details("acorrentada")
	_check(String(details.get("habilidade", "")).contains("Prisao"), "details do not explain Q")
	_check(String(details.get("traco", "")).contains("Sentenca"), "details do not explain E")
	print("ACORRENTADA_MANIFESTATION_SMOKE_OK combo=true elos=true tension=true q=true e=true tp=true reset=true")
	quit(0)
