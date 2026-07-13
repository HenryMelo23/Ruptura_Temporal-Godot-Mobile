extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("COMBAT_PACK_FAIL " + message)
	quit(1)


func _owned_card_count() -> int:
	var total := 0
	for count in game.cards_bought.values():
		total += int(count)
	return total


func _run() -> void:
	game._start_game()
	game.time_alive = 60.0
	game.current_phase = 1
	game.score = 0
	game.score_total = 0
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 1000.0
	game.boss_hp = 1.0
	var expected_reward := int(round(float(game._points_for_enemy({"points": 75})) * 2.5))
	game._damage_boss(99999.0, "test")
	_check(game.score == expected_reward, "boss reward is not 250 percent of a common enemy")
	_check(_owned_card_count() == 5, "boss did not grant five guaranteed cards")

	game.current_phase = 2
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.phase2_fire_walls.clear()
	game._spawn_enemy(game.ENEMY_PYRO_PENGUIN, Vector2(300, 300))
	game._spawn_enemy(game.ENEMY_PYRO_PENGUIN, Vector2(500, 300))
	_check(game._enemy_type_count(game.ENEMY_PYRO_PENGUIN) == 1, "more than one pyro penguin exists")
	var pyro: Dictionary = game.enemies[0]
	pyro["shoot_cd"] = 0.0
	game.player_pos = Vector2(700, 300)
	game._update_pyro_penguin(pyro, 0.01)
	_check(game.enemy_bullets.any(func(b): return String(b.get("type", "")) == "pyro_wall_seed"), "pyro penguin did not fire")
	_check(is_equal_approx(float(pyro["shoot_cd"]), game.PYRO_WALL_SHOT_INTERVAL), "pyro penguin cadence was not reset to the tuned interval")
	_check(game.PYRO_WALL_SHOT_INTERVAL < 5.0 and game.PYRO_WALL_SHOT_INTERVAL >= 3.4, "pyro penguin cadence is outside the tuned pressure window")
	game._update_enemy_bullets(0.20)
	_check(not game.phase2_fire_walls.is_empty(), "pyro projectile did not create 32px wall tiles")
	_check(is_equal_approx(float(game.phase2_fire_walls[0]["max"]), 15.0), "pyro wall does not last 15 seconds")
	game.player_pos = Vector2(game.phase2_fire_walls[0]["pos"])
	var hp_before_burn: int = game.player_hp
	game._update_phase2_fire_walls(0.01)
	_check(game.player_hp < hp_before_burn, "touching pyro wall did not apply burning damage")
	game.player_pos = Vector2(1200, 700)
	game._update_phase2_fire_walls(15.1)
	_check(game.phase2_fire_walls.is_empty(), "pyro wall survived longer than 15 seconds")

	game.current_phase = 1
	game.enemies.clear()
	game.orbitals.clear()
	game.player_damage = 100.0
	var center := Vector2(800, 450)
	game._spawn_enemy(game.ENEMY_COMMON, center + Vector2(-90, 0))
	game._spawn_enemy(game.ENEMY_COMMON, center + Vector2(90, 0))
	game._spawn_enemy(game.ENEMY_COMMON, center + Vector2(150, 0))
	var marked_a: Dictionary = game.enemies[0]
	var marked_b: Dictionary = game.enemies[1]
	var unmarked: Dictionary = game.enemies[2]
	for enemy in game.enemies:
		enemy["hp"] = 2000.0
		enemy["max_hp"] = 2000.0
	game.orbitals.append({"enemy_uid": marked_a["uid"], "life": 3.0, "target_kind": "enemy", "angle": 0.0, "tick": 1.0, "damage": 10.0})
	game.orbitals.append({"enemy_uid": marked_b["uid"], "life": 3.0, "target_kind": "enemy", "angle": PI, "tick": 1.0, "damage": 10.0})
	var unmarked_before := Vector2(unmarked["pos"])
	game._trigger_gravitante_mark_collision()
	_check(Vector2(marked_a["pos"]).distance_to(Vector2(marked_b["pos"])) <= 40.0, "marked enemies did not collide")
	_check(float(marked_a["hp"]) < 2000.0 and float(marked_b["hp"]) < 2000.0, "marked enemies took no collision damage")
	_check(Vector2(unmarked["pos"]).distance_to(unmarked_before) >= 90.0, "nearby unmarked enemy was not pushed")

	game.enemies.clear()
	game.manifestation_secondaries.clear()
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 5000.0
	game.boss_hp = 5000.0
	game.boss_pos = center + Vector2(220, 0)
	var gravity := {"kind": "gravitante", "life": game.SECONDARY_GRAVITANTE_DURATION * 0.5, "max": game.SECONDARY_GRAVITANTE_DURATION, "center": center, "pulse_tick": 0.0}
	game.manifestation_secondaries.append(gravity)
	var boss_before: Vector2 = game.boss_pos
	var boss_hp_before: float = game.boss_hp
	game._update_secondary_gravitante(gravity, 0.10)
	_check(bool(gravity.get("boss_captured", false)), "gravitante ultimate did not capture boss")
	_check(game.boss_pos != boss_before and game.boss_hp < boss_hp_before, "captured boss was not moved and damaged")
	_check(game._boss_trapped_by_gravitante(), "boss trap state was not exposed to boss controller")

	game.manifestation_secondaries.clear()
	game.current_phase = 3
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 4000.0
	game.boss_hp = 3000.0
	game.boss_pos = Vector2(900, 500)
	game.phase3_cheeses.clear()
	game._spawn_boss3_cheese(game.boss_pos, true, 30.0, 12.0, false)
	game.boss3_consume_uid = int(game.phase3_cheeses[0]["uid"])
	game.boss3_consume_timer = 0.95
	game._update_boss3_cheeses(0.10)
	_check(is_equal_approx(game.boss_hp, 3250.0), "boss3 cheese did not heal exactly 25 percent of missing health")
	game.boss3_is_moving = true
	_check(game._boss_texture() == game.textures["boss_walk"][int(game.boss_phase) % 2], "boss3 walking frames are not selected while moving")

	game.current_phase = 1
	game.boss_pos = Vector2(300, 300)
	var old_pos: Vector2 = game.boss_pos
	game._start_boss_stage()
	game._update_boss_stage(0.10)
	_check(game.boss_stage_approaching, "boss1 wave did not enter center-approach state")
	_check(game.boss_pos != old_pos and game.boss_pos != game.WORLD_SIZE * 0.5, "boss1 teleported instead of walking toward center")

	print("COMBAT_PACK_2_0_10_SMOKE_OK cards=5 pyro_unique=true wall=15s gravity_collision=true boss_capture=true cheese=25pct boss1_walk=true")
	quit(0)
