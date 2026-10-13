extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MANIFEST_EVOLUTION_PIERCE_CONTRACT_FAIL " + message)
	quit(1)


func _activate_pierce(include_grand: bool) -> void:
	game.manifestation_key = "eletrica"
	game._reset_manifest_evolution_state()
	var pierce: Dictionary = game._manifest_evolution_entries("eletrica", "ev1")[1]
	game.manifest_evolution_options = [pierce]
	game._choose_manifest_evolution(0)
	if include_grand:
		var grand: Dictionary = game._manifest_evolution_entries("eletrica", "ev2")[5]
		game.manifest_evolution_options = [grand]
		game._choose_manifest_evolution(0)


func _clear_combat() -> void:
	game.enemies.clear()
	game.bullets.clear()
	game.return_bullets.clear()
	game.arauto.clear()
	game.boss_active = false
	game.boss_dead = false
	game.boss_hp = 0.0
	game.manifest_evolution_combat_event_log.clear()


func _spawn_aligned_targets(count: int, pos: Vector2) -> Array:
	var targets: Array = []
	for index in range(count):
		game._spawn_enemy(game.ENEMY_COMMON, pos)
		var target: Dictionary = game.enemies.back()
		target["hp"] = 100000.0
		target["max_hp"] = 100000.0
		targets.append(target)
	return targets


func _bullet_at(pos: Vector2) -> Dictionary:
	return {
		"pos": pos,
		"origin": game.player_pos,
		"dir": Vector2.RIGHT,
		"speed": 0.0,
		"life": 1.0,
		"max_life": 1.0,
		"age": 0.0,
		"phase": 0.0,
		"trail_cd": 1.0,
		"damage": 20.0,
		"player_damage": 20.0,
		"kind": "eletrica",
		"pierce": false,
		"hits": {},
		"color": Color.WHITE
	}


func _damaged_target_count(targets: Array) -> int:
	var count := 0
	for target_value in targets:
		if float(Dictionary(target_value).get("hp", 100000.0)) < 100000.0:
			count += 1
	return count


func _run_collision_case(label: String, include_evolution: bool, include_grand: bool, expected_hits: int) -> void:
	_clear_combat()
	if include_evolution:
		_activate_pierce(include_grand)
	else:
		game.manifestation_key = "eletrica"
		game._reset_manifest_evolution_state()
	var hit_pos: Vector2 = game.player_pos + Vector2(120.0, 0.0)
	var targets := _spawn_aligned_targets(4, hit_pos)
	var bullet := _bullet_at(hit_pos)
	if include_evolution:
		game._apply_manifest_evolution_to_bullet(bullet)
	game.bullets.append(bullet)
	game._update_bullets(0.0)
	_check(_damaged_target_count(targets) == expected_hits, "%s hit count expected %d" % [label, expected_hits])
	_check(game.bullets.is_empty(), "%s projectile must be removed once its final collision is resolved" % label)


func _run_distinct_target_case() -> void:
	_clear_combat()
	_activate_pierce(true)
	var bullet := _bullet_at(game.player_pos)
	game._apply_manifest_evolution_to_bullet(bullet)
	_check(bool(bullet.get("native_pierce", true)) == false, "ordinary shot was incorrectly classified as native pierce")
	_check(int(bullet.get("evolution_pierce_left", 0)) == 2, "EV1 plus grand manifestation must contribute two evolution charges")
	var target := {"uid": "distinct_target", "kind": "enemy", "pos": game.player_pos + Vector2(64.0, 0.0), "hp": 100000.0}
	_check(game._manifest_evolution_on_projectile_hit(bullet, target, Vector2(target["pos"])), "first distinct target should consume one charge")
	_check(int(bullet.get("evolution_pierce_left", 0)) == 1, "first target did not consume exactly one charge")
	_check(not game._manifest_evolution_on_projectile_hit(bullet, target, Vector2(target["pos"])), "replayed target callback must not preserve the projectile")
	_check(int(bullet.get("evolution_pierce_left", 0)) == 1, "replayed target callback consumed an extra charge")


func _run_boss_and_arauto_case() -> void:
	_clear_combat()
	_activate_pierce(true)
	var hit_pos: Vector2 = game.player_pos + Vector2(140.0, 0.0)
	game.arauto = {"active": true, "hp": 100000.0, "max_hp": 100000.0, "pos": hit_pos, "variant": game.ARAUTO_VARIANT_CONDUTOR}
	game.boss_active = true
	game.boss_hp = 100000.0
	game.boss_pos = hit_pos
	# Enemy -> Arauto -> boss exercises all three authoritative collision paths.
	# The boss is the third valid collision, so it proves the depleted charge
	# cannot carry the shot beyond its permitted extra targets.
	_spawn_aligned_targets(1, hit_pos)
	var bullet := _bullet_at(hit_pos)
	game._apply_manifest_evolution_to_bullet(bullet)
	game.bullets.append(bullet)
	game._update_bullets(0.0)
	_check(float(game.arauto.get("hp", 100000.0)) < 100000.0, "Arauto did not receive the valid projectile hit")
	_check(game.boss_hp < 100000.0, "boss did not receive the valid projectile hit")
	_check(game.bullets.is_empty(), "two valid boss-family hits must exhaust two evolution charges")


func _run_native_returning_case() -> void:
	_clear_combat()
	_activate_pierce(true)
	var returning := _bullet_at(game.player_pos)
	returning["kind"] = "retornante"
	returning["pierce"] = true
	game._apply_manifest_evolution_to_bullet(returning)
	var first := {"uid": "return_a", "kind": "enemy", "pos": game.player_pos + Vector2(60.0, 0.0)}
	var second := {"uid": "return_b", "kind": "enemy", "pos": game.player_pos + Vector2(90.0, 0.0)}
	_check(bool(returning.get("native_pierce", false)), "Retornante native pierce was not recorded")
	_check(game._manifest_evolution_on_projectile_hit(returning, first, Vector2(first["pos"])), "Retornante lost native pierce on first hit")
	_check(game._manifest_evolution_on_projectile_hit(returning, second, Vector2(second["pos"])), "Retornante lost native pierce on second hit")
	_check(int(returning.get("evolution_pierce_left", 0)) == 2, "Retornante consumed evolution charges despite native pierce")


func _run_public_attack_case() -> void:
	# This is the public-flow counterpart to the exact low-level collision
	# cases above.  It proves a real input attack produces one additional hit,
	# rather than only proving a hand-built bullet can hold a counter.
	_clear_combat()
	_activate_pierce(false)
	var targets: Array = []
	for index in range(3):
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(112.0 + 46.0 * index, 0.0))
		var target: Dictionary = game.enemies.back()
		# Runtime spawn ids use a time-derived seed; a same-frame smoke spawn can
		# otherwise legitimately collide before the actual projectile contract is
		# exercised.  Give this three-target fixture the stable distinct ids a
		# real authoritative spawn stream guarantees.
		target["uid"] = 9100 + index
		target["hp"] = 100000.0
		target["max_hp"] = 100000.0
		targets.append(target)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.time_alive = 1000.0
	game.last_attack_time = -1000.0
	game._try_attack()
	for _frame in range(24):
		game._update_bullets(0.03)
	_check(_damaged_target_count(targets) == 2, "public attack did not stop after one evolution pierce")
	var hit_events := 0
	var seen_ids: Dictionary = {}
	for event_value in game.manifest_evolution_combat_event_log:
		var event: Dictionary = Dictionary(event_value)
		if String(event.get("type", "")) != "hit_resolved":
			continue
		var event_id := String(event.get("id", ""))
		_check(not seen_ids.has(event_id), "public projectile emitted a duplicate hit event")
		seen_ids[event_id] = true
		hit_events += 1
	_check(hit_events == 2, "public projectile must resolve exactly two hit events")


func _run() -> void:
	game._start_game()
	game.mode = "game"
	game.current_phase = 1
	game.player_pos = Vector2(640.0, 360.0)
	game.last_facing = Vector2.RIGHT
	game.player_damage = 20.0
	game.enemy_base_hp = 100000.0

	_run_collision_case("zero charges", false, false, 1)
	_run_collision_case("one charge", true, false, 2)
	_run_collision_case("two charges", true, true, 3)
	_run_distinct_target_case()
	_run_boss_and_arauto_case()
	_run_native_returning_case()
	_run_public_attack_case()

	print("MANIFEST_EVOLUTION_PIERCE_CONTRACT_OK charges=0/1/2 boss_arauto=ok returning_native=ok")
	game.set_process(false)
	game._cleanup_runtime_resources()
	game.queue_free()
	game = null
	for _frame in range(4):
		await process_frame
	quit(0)
