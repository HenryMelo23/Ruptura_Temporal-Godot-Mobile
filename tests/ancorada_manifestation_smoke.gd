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
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(640, 360)
	game.ancorada_prev_pos = game.player_pos
	game.player_damage = 100.0
	game.lastro_stacks = 0
	game.lastro_points = 0
	game._update_ancorada_standing_still(20.0)
	_check(is_zero_approx(float(game.ancorada_crit_bonus)), "standing still must not grant crit after the mobile rework")
	_check(is_equal_approx(float(game.ancorada_weight_knockback), 5.0), "legacy stationary weight must stay neutral")

	game.lastro_stacks = 5
	_check(is_equal_approx(game._anchor_bonus(), 1.20), "five LASTRO stacks must grant 20% attack damage")
	var fast_interval: float = game._current_attack_interval()
	game.lastro_stacks = 0
	var base_interval: float = game._current_attack_interval()
	_check(fast_interval < base_interval, "LASTRO must improve attack cadence without locking movement")

	game.enemies = [{"uid": 1, "type": game.ENEMY_COMMON, "pos": game.player_pos + Vector2(180, 0), "hp": 1200.0, "max_hp": 1200.0, "speed": 80.0, "shoot_cd": 9.0, "ferrolho_root": 0.0, "stun": 0.0}]
	var bullet := {"kind": "ancorada", "damage": 10.0, "pos": game.enemies[0]["pos"], "origin": game.player_pos, "dir": Vector2.RIGHT, "always_crit": false, "source_category": "basic_attack"}
	game._apply_bullet_effect(bullet, game.enemies[0])
	_check(game.anchors.size() == 1, "Ancorada projectile hit must deploy exactly one territory anchor")
	_check(Vector2(game.anchors[0].get("link_from", Vector2.ZERO)) == game.player_pos, "territory line must begin at the shot origin")
	_check(game.lastro_points == 1, "projectile hit must grant one LASTRO point")
	game.player_pos = Vector2(game.anchors[0]["pos"])
	game._update_ancorada_standing_still(0.1)
	_check(game.lastro_points == 3, "crossing the deployed anchor must grant two LASTRO points")
	_check(bool(game.anchors[0].get("claimed", false)), "crossed anchor must be idempotently marked as claimed")
	var tether_target := {"uid": 2, "type": game.ENEMY_COMMON, "pos": Vector2(game.anchors[0]["link_from"]).lerp(Vector2(game.anchors[0]["pos"]), 0.5), "hp": 1000.0, "max_hp": 1000.0, "speed": 80.0, "shoot_cd": 9.0, "ferrolho_root": 0.0, "stun": 0.0}
	game.enemies.append(tether_target)
	game.anchors[0]["tether_tick"] = 0.0
	game._update_ancorada_standing_still(0.13)
	var tether_hp_after_first: float = float(tether_target["hp"])
	_check(tether_hp_after_first < 1000.0, "territory line must damage an enemy crossing it")
	game._update_ancorada_standing_still(0.13)
	_check(is_equal_approx(float(tether_target["hp"]), tether_hp_after_first), "one territory line must not damage the same target twice")

	game.anchors.clear()
	var teleport_origin: Vector2 = game.player_pos
	var teleport_destination: Vector2 = teleport_origin + Vector2(180, 90)
	game._execute_teleport(teleport_destination)
	_check(game.anchors.size() == 2, "Ancorada teleport must place origin and arrival anchors")
	_check(String(game.anchors[1].get("source", "")) == "ancorada_tp_arrival", "arrival anchor source must remain explicit for replication")
	_check(Vector2(game.anchors[1].get("link_from", Vector2.ZERO)) == teleport_origin, "teleport arrival must link back to its origin")
	game._finish_teleport_effect_cooldown()

	game.lastro_stacks = 4
	game.lastro_points = 0
	game.last_skill_time = -999.0
	game.player_pos = Vector2(500, 500)
	var q_target := Vector2(700, 500)
	game.enemies[0]["pos"] = q_target + Vector2(90, 0)
	var enemy_before_q := Vector2(game.enemies[0]["pos"])
	game._use_skill(q_target)
	_check(game.hab1_ancorada_active, "Q must start Arranco de Fundacao")
	_check(game.last_skill_time == game.time_alive, "Q cooldown must start on a valid cast")
	game._update_hab1_ancorada(game.ANCORADA_HAB1_IMPACT_TIME + 0.01)
	_check(Vector2(game.enemies[0]["pos"]).distance_to(q_target) < enemy_before_q.distance_to(q_target), "Q must pull a common enemy toward the foundation")
	_check(game.lastro_stacks == 0, "Q must consume captured LASTRO")
	_check(game.anchors.any(func(anchor): return String(anchor.get("source", "")) == "ancorada_q"), "Q must leave a territory line")

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
	var march_origin: Vector2 = game.player_pos
	game.player_pos += Vector2(280, 0)
	game.enemies[0]["pos"] = game.player_pos + Vector2(140, 0)
	game.boss_pos = game.player_pos + Vector2(160, 0)
	game.arauto["pos"] = game.player_pos + Vector2(-160, 0)
	game._update_secondary_ancorada(secondary, 0.01)
	_check(Vector2(secondary.get("center", Vector2.ZERO)) == game.player_pos, "Marcha da Fortaleza must follow the player")
	_check(float(secondary.get("momentum", 0.0)) > 0.45, "moving during the ultimate must generate momentum")
	_check(Vector2(secondary.get("center", Vector2.ZERO)) != march_origin, "ultimate must not remain fixed at its cast point")
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
	await process_frame
	print("ANCORADA_MANIFESTATION_SMOKE_OK passive=mobile_territory attack=tether q=pull ultimate=marching")
	quit(0)
