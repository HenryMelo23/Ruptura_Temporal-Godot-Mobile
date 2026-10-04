extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("LARAPIO_MINIBOSS_CLEANUP_FAIL " + message)
	quit(1)


func _spawn_larapio(uid: int, stolen: int, escaping: bool) -> Dictionary:
	game._spawn_enemy(game.ENEMY_LARAPIO, Vector2(680 + float(uid % 7) * 12.0, 420))
	var larapio: Dictionary = game.enemies.back()
	larapio["uid"] = uid
	larapio["hp"] = 321.0 + float(uid % 11)
	larapio["max_hp"] = 777.0
	larapio["stolen"] = stolen
	larapio["portal"] = 1.35 if escaping else 0.25
	larapio["portal_pause"] = 0.42 if escaping else 0.0
	larapio["steal_cd"] = 0.66
	larapio["throw_cd"] = 1.77
	larapio["happy_timer"] = 0.88
	larapio["coin_drop_cd"] = 0.31
	larapio["alerted"] = true
	larapio["direct_steal"] = stolen > 0
	larapio["larapio_corner_time"] = 1.23
	larapio["larapio_escape_timer"] = 1.4 if escaping else 0.0
	larapio["larapio_patrol_timer"] = 2.1
	larapio["larapio_patrol_target"] = Vector2(910, 520)
	larapio["larapio_ult_timer"] = 3.2
	larapio["larapio_ult_cd"] = 4.3
	larapio["larapio_ult_jump_cd"] = 0.7
	larapio["target_peer_id"] = 42
	return larapio


func _assert_same_larapio_state(actual: Dictionary, expected: Dictionary, label: String) -> void:
	_check(actual == expected, label + "_identity_changed")
	_check(int(actual.get("uid", 0)) == int(expected.get("uid", -1)), label + "_uid_changed")
	_check(String(actual.get("type", "")) == game.ENEMY_LARAPIO, label + "_type_changed")
	_check(is_equal_approx(float(actual.get("hp", 0.0)), float(expected.get("hp", -1.0))), label + "_hp_changed")
	_check(is_equal_approx(float(actual.get("max_hp", 0.0)), float(expected.get("max_hp", -1.0))), label + "_max_hp_changed")
	_check(int(actual.get("stolen", -1)) == int(expected.get("stolen", -2)), label + "_stolen_changed")
	_check(is_equal_approx(float(actual.get("portal", -1.0)), float(expected.get("portal", -2.0))), label + "_portal_changed")
	_check(is_equal_approx(float(actual.get("portal_pause", -1.0)), float(expected.get("portal_pause", -2.0))), label + "_portal_pause_changed")
	_check(is_equal_approx(float(actual.get("steal_cd", -1.0)), float(expected.get("steal_cd", -2.0))), label + "_steal_cd_changed")
	_check(is_equal_approx(float(actual.get("throw_cd", -1.0)), float(expected.get("throw_cd", -2.0))), label + "_throw_cd_changed")
	_check(is_equal_approx(float(actual.get("larapio_escape_timer", -1.0)), float(expected.get("larapio_escape_timer", -2.0))), label + "_escape_timer_changed")
	_check(Vector2(actual.get("larapio_patrol_target", Vector2.ZERO)).is_equal_approx(Vector2(expected.get("larapio_patrol_target", Vector2.INF))), label + "_patrol_target_changed")
	_check(int(actual.get("target_peer_id", 0)) == int(expected.get("target_peer_id", -1)), label + "_target_peer_changed")


func _find_enemy_by_uid(uid: int) -> Dictionary:
	var found = game._enemy_by_uid(uid)
	return {} if found == null else Dictionary(found)


func _run_case(label: String, stolen: int, escaping: bool) -> void:
	game._start_game()
	game.current_phase = 1
	game.boss_active = false
	game.boss_dead = false
	game.arauto.clear()
	game.arauto_spawned = false
	game.enemies.clear()
	game.enemy_bullets.clear()
	var larapio: Dictionary = _spawn_larapio(81000 + stolen + (300 if escaping else 0), stolen, escaping)
	var larapio_uid: int = int(larapio["uid"])
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(760, 460))
	var common_uid: int = int(Dictionary(game.enemies.back()).get("uid", -1))
	game._spawn_arauto()
	var preserved: Dictionary = _find_enemy_by_uid(larapio_uid)
	_check(not preserved.is_empty(), label + "_larapio_missing_after_miniboss")
	_assert_same_larapio_state(preserved, larapio, label)
	_check(game._enemy_by_uid(common_uid) == null, label + "_common_enemy_was_not_cleaned")
	_check(game._arauto_active(), label + "_arauto_not_active")
	_check(game.enemies.has(larapio), label + "_larapio_not_resolvable_by_identity")
	larapio["hp"] = 0.0
	game._kill_enemy(larapio)
	_check(game._enemy_by_uid(larapio_uid) == null, label + "_larapio_normal_death_was_blocked")


func _run_network_case() -> void:
	game._start_game()
	game.enemies.clear()
	var larapio: Dictionary = _spawn_larapio(99001, 345, true)
	var client_game: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(client_game)
	client_game._apply_remote_enemy_snapshot(game._pack_net_enemies(), Time.get_ticks_msec())
	var replicated = client_game._enemy_by_uid(99001)
	_check(replicated != null, "replicated_larapio_missing")
	var replicated_larapio: Dictionary = Dictionary(replicated)
	_check(int(replicated_larapio.get("stolen", 0)) == 345, "replicated_stolen_missing")
	_check(is_equal_approx(float(replicated_larapio.get("portal", 0.0)), float(larapio.get("portal", -1.0))), "replicated_portal_missing")
	_check(is_equal_approx(float(replicated_larapio.get("larapio_escape_timer", 0.0)), float(larapio.get("larapio_escape_timer", -1.0))), "replicated_escape_timer_missing")
	_check(Vector2(replicated_larapio.get("larapio_patrol_target", Vector2.ZERO)).is_equal_approx(Vector2(larapio.get("larapio_patrol_target", Vector2.INF))), "replicated_ai_target_missing")
	client_game._cleanup_runtime_resources()
	root.remove_child(client_game)
	client_game.free()
	await process_frame
	await process_frame


func _run() -> void:
	_run_case("no_loot", 0, false)
	_run_case("with_stolen_points", 250, false)
	_run_case("escaping", 700, true)
	await _run_network_case()
	print("LARAPIO_MINIBOSS_CLEANUP_OK preserved=3 normal_death=true common_cleanup=true net_state=true")
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	quit(0)


func _cleanup(code: int) -> void:
	if is_instance_valid(game):
		game._cleanup_runtime_resources()
		root.remove_child(game)
		game.free()
	quit(code)
