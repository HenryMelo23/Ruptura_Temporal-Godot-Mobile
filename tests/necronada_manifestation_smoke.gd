extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("NECRONADA_MANIFESTATION_SMOKE_FAIL " + message)
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


func _spawn_test_enemy(pos: Vector2, hp := 180.0) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var enemy: Dictionary = game.enemies[-1]
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	return enemy


func _run() -> void:
	await process_frame
	var index := _manifestation_index("necronada")
	_check(index >= 0, "Necronada was not registered in MANIFESTATIONS")
	_check(String(game.MANIFESTATIONS[index].get("icon", "")) == "res://assets/sprites/manifestacao-necronada.png", "Necronada icon uses wrong path")
	_check(ResourceLoader.exists("res://assets/sprites/manifestacao-necronada.png"), "Necronada icon is not packable")
	_check(game._manifest_select_item_texture(game.MANIFESTATIONS[index], false) != null, "Necronada icon did not load")

	game.selected_manifestation = index
	game.selected_aura = 0
	game._start_game()
	game.manifestation_key = "necronada"
	game.player_pos = Vector2(640, 360)
	game.player_damage = 120.0
	game.last_facing = Vector2.RIGHT
	game.attack_dragging = true
	game.attack_drag_direction = Vector2.RIGHT
	game.time_alive = 30.0
	game.last_attack_time = -999.0
	game.last_skill_time = -999.0
	game.last_secondary_time = -999.0
	game.enemies.clear()
	game.bullets.clear()
	game.necronada_vestiges.clear()
	game.necronada_ossuary.clear()
	game.necronada_remnants.clear()
	game.necronada_requiem.clear()
	game.necronada_vfx.clear()
	game.boss_active = false

	_check(is_equal_approx(game._manifestation_base_damage(), game.PLAYER_BASE_DAMAGE * 0.84), "base damage is not normalized")
	_check(is_equal_approx(game._manifestation_attack_interval(), 0.64), "base cadence is not 0.64s")
	_check(game._ground_target_profile(false).has("radius"), "Q targeting profile missing")
	_check(game._ground_target_profile(true).has("radius"), "E targeting profile missing")

	var enemy := _spawn_test_enemy(game.player_pos + Vector2(96, 0), 180.0)
	game._try_attack()
	_check(game.bullets.size() == 1, "ATK did not create projectile")
	_check(String(game.bullets[0].get("kind", "")) == "necronada", "ATK projectile has wrong kind")
	game._apply_bullet_effect(game.bullets[0], enemy)
	_check(bool(enemy.get("necronada_epitaph", false)), "ATK did not apply Epitaph")
	_check(int(enemy.get("necronada_epitaph_depth", 0)) == 1, "Epitaph depth did not start at 1")
	for i in range(4):
		game._apply_necronada_epitaph(enemy, Vector2(enemy["pos"]))
	_check(int(enemy.get("necronada_epitaph_depth", 0)) == 5, "Epitaph did not stack to 5")

	enemy["hp"] = 0.0
	enemy["killed_by_source"] = "necronada"
	game._necronada_on_enemy_killed(enemy)
	_check(game.necronada_vestiges.size() == 1, "marked enemy did not leave Vestige")
	_check(game.necronada_pente_history.has(game.ENEMY_COMMON), "marked kill did not register species in pente history")

	game.last_skill_time = -999.0
	game._try_use_necronada_skill(Vector2(enemy["pos"]))
	_check(game.necronada_ossuary.size() == 1, "Q did not capture Vestige into Ossuary")
	_check(game.necronada_vestiges.is_empty(), "captured Vestige remained on field")

	game.necronada_vestiges.append({"id": 777, "enemy_type": game.ENEMY_STALKER, "pos": game.player_pos + Vector2(36, 0), "life": 5.0, "max": 5.0, "depth": 1, "profile": game._necronada_profile(game.ENEMY_STALKER), "phase": 0.0})
	game.necronada_ossuary.clear()
	game._update_necronada_state(0.08)
	_check(game.necronada_ossuary.size() == 1, "nearby Vestige did not auto-capture into Ossuary")
	_check(game.necronada_vestiges.is_empty(), "auto-captured Vestige remained on field")

	game.last_skill_time = -999.0
	game._try_use_necronada_skill(game.player_pos + Vector2(120, 0))
	_check(game.necronada_ossuary.is_empty(), "summon did not consume Ossuary slot")
	_check(game.necronada_remnants.size() == 1, "Q did not summon Remnant")

	var target := _spawn_test_enemy(game.player_pos + Vector2(170, 0), 260.0)
	var hp_before := float(target["hp"])
	for i in range(80):
		game._update_necronada_state(0.08)
		if float(target["hp"]) < hp_before:
			break
	_check(float(target["hp"]) < hp_before, "Remnant did not damage a nearby enemy")

	game.necronada_vestiges.append({"id": 999, "enemy_type": game.ENEMY_COMMON, "pos": game.player_pos + Vector2(60, 0), "life": 5.0, "max": 5.0, "depth": 2, "profile": game._necronada_profile(game.ENEMY_COMMON), "phase": 0.0})
	game.last_secondary_time = -999.0
	game.necronada_ossuary = [
		{"id": 1001, "enemy_type": game.ENEMY_COMMON, "profile": game._necronada_profile(game.ENEMY_COMMON), "depth": 3, "stored_at": game.time_alive},
		{"id": 1002, "enemy_type": game.ENEMY_STALKER, "profile": game._necronada_profile(game.ENEMY_STALKER), "depth": 2, "stored_at": game.time_alive}
	]
	game.necronada_pente_history = [game.ENEMY_COMMON]
	var ossuary_before: Array = game.necronada_ossuary.duplicate(true)
	game._use_secondary_skill(game.player_pos)
	_check(not game.necronada_requiem.is_empty(), "E did not start Requiem")
	_check(game.necronada_ossuary.size() == ossuary_before.size(), "E consumed Ossuary slots")
	_check(game.necronada_ossuary == ossuary_before, "E changed stored Ossuary slots")
	_check(Array(game.necronada_requiem.get("species_pool", [])).size() == 1, "E species pool ignored unique pente history")
	_check(game.necronada_remnants.size() == game.NECRONADA_SUPREME_HORDE_COUNT, "E did not summon 4 supreme allies")
	for remnant in game.necronada_remnants:
		_check(bool(remnant.get("is_ultimate", false)), "E summoned a non-supreme remnant")
		_check(String(remnant.get("enemy_type", "")) == game.ENEMY_COMMON, "E did not repeat the only species in pente history")
	_check(is_equal_approx(float(game.necronada_requiem.get("total_taunt_timer", 0.0)), game.NECRONADA_TOTAL_TAUNT_DURATION), "E did not start 15s total taunt")
	_check(game._necronada_has_active_taunt(), "total taunt was not considered active")
	var taunt_enemy := _spawn_test_enemy(game.player_pos + Vector2(300, 0), 240.0)
	var enemy_target: Vector2 = game._get_enemy_target_pos(taunt_enemy)
	_check(enemy_target.distance_to(game.player_pos) > 20.0, "enemy taunt still targets Geovana")
	game.boss_active = true
	game.boss_hp = 1000.0
	game.boss_pos = game.player_pos + Vector2(420, 0)
	var boss_target: Vector2 = game._boss_target_pos(false, 0.0)
	_check(boss_target.distance_to(game.player_pos) > 20.0, "boss taunt still targets Geovana")

	var details: Dictionary = game._manifestation_details("necronada")
	_check(String(details.get("funcao", "")).contains("Reconstrucao"), "catalog details missing Necronada identity")
	_check(String(details.get("risco", "")).contains("15s"), "catalog details missing total taunt duration")
	game._reset_advanced_manifestation_state()
	_check(game.necronada_vestiges.is_empty(), "reset did not clear Vestiges")
	_check(game.necronada_ossuary.is_empty(), "reset did not clear Ossuary")
	_check(game.necronada_remnants.is_empty(), "reset did not clear Remnants")

	print("NECRONADA_MANIFESTATION_SMOKE_OK icon=true atk=true epitaph=true vestige=true ossuary=true remnant=true requiem=true reset=true")
	root.remove_child(game)
	game.queue_free()
	await process_frame
	quit(0)
