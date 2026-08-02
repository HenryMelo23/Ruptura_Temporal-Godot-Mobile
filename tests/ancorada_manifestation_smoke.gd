extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("ANCORADA_MANIFESTATION_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game._start_game()
	game.mode = "game"
	game.manifestation_key = "ancorada"
	game.player_pos = Vector2(640, 360)
	game.ancorada_prev_pos = game.player_pos
	game.player_damage = 100.0
	game.player_crit_chance = 0.10
	game.ancorada_crit_bonus = 0.0
	game.ancorada_weight_knockback = 5.0
	game.ancorada_weight_timer = 0.0
	game.ancorada_still_timer = 0.0

	game._update_ancorada_standing_still(3.05)
	_check(is_equal_approx(float(game.ancorada_crit_bonus), 0.02), "standing still did not add the first 2% crit bonus")
	game._update_ancorada_standing_still(90.0)
	_check(is_equal_approx(float(game.ancorada_crit_bonus), 0.50), "standing still crit bonus did not cap at 50%")
	_check(float(game.ancorada_weight_knockback) <= 50.0 and float(game.ancorada_weight_knockback) >= 49.0, "weighted shot knockback did not build toward 50px")

	game.player_pos += Vector2(12, 0)
	game._update_ancorada_standing_still(0.016)
	_check(is_zero_approx(float(game.ancorada_crit_bonus)), "moving did not reset crit bonus")
	_check(is_equal_approx(float(game.ancorada_weight_knockback), 5.0), "moving did not reset shot weight")

	game.player_crit_chance = 1.20
	game.ancorada_crit_bonus = 0.0
	var overcap_damage: float = game._critical_damage(10.0)
	_check(is_equal_approx(overcap_damage, 36.0), "crit overcap did not convert 20% overflow into crit damage")

	game.enemies = [
		{"uid": 1, "type": game.ENEMY_COMMON, "pos": game.player_pos + Vector2(80, 0), "hp": 200.0, "max_hp": 200.0, "speed": 80.0, "shoot_cd": 9.0, "ferrolho_root": 0.0, "stun": 0.0}
	]
	game.ancorada_weight_knockback = 31.0
	var before_push: Vector2 = Vector2(game.enemies[0]["pos"])
	game._apply_bullet_effect({
		"kind": "ancorada",
		"damage": 10.0,
		"pos": before_push,
		"origin": game.player_pos,
		"dir": Vector2.RIGHT,
		"always_crit": false,
		"source_category": "basic_attack"
	}, game.enemies[0])
	_check(Vector2(game.enemies[0]["pos"]).x > before_push.x + 28.0, "weighted anchored projectile did not push the enemy back")

	game.ancorada_spinning.clear()
	game.enemies = [
		{"uid": 2, "type": game.ENEMY_COMMON, "pos": game.player_pos + Vector2(92, 0), "hp": 200.0, "max_hp": 200.0, "speed": 80.0, "shoot_cd": 9.0, "ferrolho_root": 0.0, "stun": 0.0}
	]
	game.ancorada_spinning.append({"life": 5.0, "max": 5.0, "angle": 0.0, "damage_tick": 0.0, "hit": {}})
	game._update_ancorada_spinning(0.0)
	_check(float(game.enemies[0]["hp"]) < 200.0, "spinning anchors did not damage a nearby enemy")
	_check(is_equal_approx(float(game.ancorada_spinning[0].get("life", 0.0)), 5.0), "spinning anchors did not keep the expected 5s duration on spawn")
	_check(is_equal_approx(game._skill_cooldown(), 10.0), "Ancorada HAB1 cooldown is not 10s")

	game.enemies = [
		{"uid": 3, "type": game.ENEMY_COMMON, "pos": game.player_pos + Vector2(140, 0), "hp": 300.0, "max_hp": 300.0, "speed": 80.0, "shoot_cd": 9.0, "ferrolho_root": 0.0, "stun": 0.0}
	]
	game.boss_active = true
	game.boss_dead = false
	game.boss_pos = game.player_pos + Vector2(160, 0)
	game.boss_hp_max = 1000.0
	game.boss_hp = 1000.0
	game.boss_tp_stun_timer = 0.0
	game.arauto = {"active": true, "pos": game.player_pos + Vector2(-160, 0), "hp": 500.0, "max_hp": 500.0, "stun": 0.0}
	game._spawn_secondary_ancorada(game.player_pos)
	_check(game.manifestation_secondaries.size() > 0, "Ancorada ultimate did not create an active rain field")
	var secondary: Dictionary = game.manifestation_secondaries.back()
	_check(is_equal_approx(float(secondary.get("radius", 0.0)), 350.0), "Ancorada ultimate radius is not 350px")
	_check(is_equal_approx(float(secondary.get("max", 0.0)), 10.0), "Ancorada ultimate duration is not 10s")
	game._update_secondary_ancorada(secondary, 0.01)
	_check(Array(secondary.get("drops", [])).size() >= 3, "Ancorada ultimate did not spawn falling anchors for targets in radius")
	game._update_secondary_ancorada(secondary, 0.70)
	_check(float(game.enemies[0]["hp"]) <= 115.0, "Ancorada ultimate did not apply high scaling damage to enemies on impact")
	_check(float(game.enemies[0].get("evolution_slow", 0.0)) >= 2.0, "Ancorada ultimate did not slow common enemies on impact")
	_check(is_equal_approx(float(game.enemies[0].get("evolution_slow_mult", 1.0)), 0.35), "Ancorada ultimate slow is not 65%")
	_check(float(game.boss_hp) < 1000.0, "Ancorada ultimate did not damage the boss")
	_check(is_zero_approx(float(game.boss_tp_stun_timer)), "Ancorada ultimate should not slow/stun the boss")
	_check(float(game.arauto.get("hp", 500.0)) < 500.0, "Ancorada ultimate did not damage Arauto")
	_check(is_zero_approx(float(game.arauto.get("stun", 0.0))), "Ancorada ultimate should not stun Arauto")
	_check(is_equal_approx(game._secondary_skill_cooldown(), 65.0), "Ancorada ultimate cooldown is not 65s")

	game._cleanup_runtime_resources()
	game.free()
	await process_frame
	print("ANCORADA_MANIFESTATION_SMOKE_OK passive=true overcap=true weighted_shot=true hab1=true ultimate=true")
	quit(0)
