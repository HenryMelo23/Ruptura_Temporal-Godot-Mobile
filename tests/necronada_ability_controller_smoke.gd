extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("NECRONADA_ABILITY_CONTROLLER_SMOKE_FAIL " + message)
	quit(1)


func _vestige(enemy_type: String, pos: Vector2, depth: int) -> Dictionary:
	return {
		"id": game.necronada_next_id,
		"enemy_type": enemy_type,
		"pos": pos,
		"profile": game._necronada_profile(enemy_type),
		"depth": depth,
		"phase": 0.0
	}


func _run() -> void:
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.manifestation_key = "necronada"
	game.player_pos = Vector2(640, 360)
	game.player_hp_max = 450
	game.player_hp = 450
	game.necronada_vestiges.clear()
	game.necronada_remnants.clear()
	game.necronada_vfx.clear()
	game.necronada_horde_progress = 0

	_check(not game._try_use_necronada_skill(game.player_pos), "empty HAB1 succeeded")
	_check(game.necronada_remnants.is_empty() and game.necronada_horde_progress == 0, "empty HAB1 changed combat state")
	_check(game.necronada_ability_controller.core == game, "ability owner was not bound")

	game.necronada_vestiges = [
		_vestige(game.ENEMY_COMMON, game.player_pos + Vector2(36, 0), 1),
		_vestige(game.ENEMY_PROJECTOR, game.player_pos + Vector2(72, 0), 2),
		_vestige(game.ENEMY_STALKER, game.player_pos + Vector2(game.NECRONADA_ROSE_SUMMON_RADIUS + 24, 0), 3)
	]
	_check(game._try_use_necronada_skill(game.player_pos), "near vestiges did not summon")
	_check(game.necronada_remnants.size() == 2, "HAB1 did not create exactly the nearby remnants")
	_check(game.necronada_vestiges.size() == 1, "HAB1 consumed vestige outside radius")
	_check(game.necronada_horde_progress == 2, "HAB1 horde progress changed")
	_check(game.necronada_vfx.any(func(vfx): return String(vfx.get("kind", "")) == "rose_summon_ring"), "HAB1 VFX transaction missing")

	game.necronada_remnants.clear()
	game.necronada_vestiges.clear()
	for index in range(game.NECRONADA_MAX_ACTIVE_REMNANTS + 1):
		game.necronada_vestiges.append(_vestige(game.ENEMY_COMMON, game.player_pos + Vector2(16 + index * 4, 0), 1))
	_check(game._try_use_necronada_skill(game.player_pos), "capped HAB1 did not summon available remnants")
	_check(game.necronada_remnants.size() == game.NECRONADA_MAX_ACTIVE_REMNANTS, "HAB1 exceeded remnant cap")
	_check(game.necronada_vestiges.size() == 1, "HAB1 consumed an unsummonable vestige")

	# The root wrapper must execute the owner loop: it chooses a live target and
	# resolves one real remnant attack rather than only changing registration state.
	game.necronada_remnants.clear()
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(54, 0))
	var target: Dictionary = game.enemies[-1]
	target["hp"] = 180.0
	target["max_hp"] = 180.0
	_check(game._summon_necronada_remnant(game.player_pos, {
		"id": 9001,
		"enemy_type": game.ENEMY_COMMON,
		"profile": game._necronada_profile(game.ENEMY_COMMON),
		"depth": 1
	}), "lifecycle fixture did not summon remnant")
	var remnant: Dictionary = game.necronada_remnants[0]
	remnant["summon"] = 0.0
	remnant["target_timer"] = 0.0
	remnant["attack_cd"] = 0.0
	var target_hp_before := float(target["hp"])
	game._update_necronada_remnants(0.05)
	_check(game.necronada_ability_controller.core == game, "remnant wrapper did not bind owner")
	_check(String(remnant.get("target_kind", "")) == "enemy", "remnant owner did not acquire live enemy")
	_check(float(target["hp"]) < target_hp_before, "remnant owner did not resolve real attack")

	print("NECRONADA_ABILITY_CONTROLLER_SMOKE_OK empty=true radius=true cap=true vfx=true lifecycle=true owner=true")
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	game = null
	for frame in range(4):
		await process_frame
	quit(0)
