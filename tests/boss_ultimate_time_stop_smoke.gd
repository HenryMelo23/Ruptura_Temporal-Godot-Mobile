extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("BOSS_ULTIMATE_TIME_STOP_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.current_phase = 3
	game.boss_active = true
	game.boss_hp_max = 2000.0
	game.boss_hp = 2000.0
	game.player_pos = Vector2(720, 420)
	game.boss_pos = Vector2(560, 420)
	game.player_speed = 250.0
	game._start_boss3_miasma(3)
	_check(game.boss3_miasma_variant == 3, "third miasma variant did not start")
	_check(game.boss3_miasma_clouds.size() == game.BOSS3_MIASMA_CLOUD_COUNT, "miasma cloud count is wrong")
	_check(float(game.boss3_miasma_clouds[0]["speed"]) >= game.player_speed * game.BOSS3_MIASMA_CLOUD_SPEED_MULT, "miasma cloud speed does not track player speed")

	game.aura_state = game.AuraSystem.create("Devota", 1)
	game.aura_state["devoted_charges"] = 3
	game.mandamento_invulnerability = 4.0
	game.passagem_intangivel_timer = 4.0
	game.player_hp_max = 450
	game.player_hp = 450
	game._damage_player(70, "boss3_miasma_cloud")
	_check(game.player_hp < 450, "boss ultimate damage was blocked by card/aura invulnerability")
	_check(int(game.aura_state["devoted_charges"]) == 3, "Devota consumed a charge against a boss ultimate")

	game.current_phase = 1
	game.boss_active = true
	game.boss_hp_max = 1000.0
	game.boss_hp = 1000.0
	game.boss1_absorb_timer = 1.0
	game.boss1_absorb_damage = 0.0
	game.bullets = [{
		"pos": Vector2(300, 300),
		"origin": Vector2(300, 300),
		"dir": Vector2.RIGHT,
		"speed": 500.0,
		"life": 2.0,
		"max_life": 2.0,
		"age": 0.0,
		"phase": 0.0,
		"trail_cd": 0.0,
		"damage": 120.0,
		"kind": "prismatica",
		"color": Color(0.32, 1.0, 0.96),
		"pierce": false,
		"hits": {}
	}]
	var frozen_pos: Vector2 = Vector2(game.bullets[0]["pos"])
	var frozen_life: float = float(game.bullets[0]["life"])
	game._update_bullets(0.35)
	_check(Vector2(game.bullets[0]["pos"]).distance_to(frozen_pos) <= 0.01, "projectile moved during boss absorb time stop")
	_check(is_equal_approx(float(game.bullets[0]["life"]), frozen_life), "projectile lifetime drained during boss absorb time stop")
	game._damage_boss(150.0, "prismatica")
	_check(is_equal_approx(game.boss_hp, 1000.0), "boss took damage during absorb time stop")
	_check(is_equal_approx(game.boss1_absorb_damage, 0.0), "frozen damage was converted into absorb retaliation")

	game.boss1_absorb_timer = 0.0
	game._update_bullets(0.10)
	_check(Vector2(game.bullets[0]["pos"]).distance_to(frozen_pos) > 1.0, "projectile did not resume after time stop")

	game.aura_state = game.AuraSystem.create("Voraz", 3)
	game.current_phase = 2
	game.boss_active = true
	game.boss_hp = 1000.0
	game.boss_hp_max = 1000.0
	game.boss_pos = Vector2(700, 420)
	game._damage_boss(180.0, "aura_voraz")
	_check(Array(game.aura_state["voracious_drops"]).is_empty(), "Voraz boss feed was released by passive aura bite")
	game._damage_boss(180.0, "prismatica", true, true, "basic_attack", game.player_pos)
	_check(Array(game.aura_state["voracious_drops"]).size() == 1, "Voraz boss feed did not release from direct player pressure")

	game.player_hp = int(game.player_hp_max * 0.20)
	game.current_phase = 1
	game.boss1_absorb_timer = 0.0
	game.boss1_absorb_cooldown = 0.0
	game._start_boss1_absorb()
	_check(game.boss1_absorb_timer <= 0.0 and game.boss1_absorb_cooldown > 0.0, "boss started absorb while player was low HP")

	print("BOSS_ULTIMATE_TIME_STOP_SMOKE_OK clouds=%d devota_bypass=true time_stop=true voraz_gated=true" % game.boss3_miasma_clouds.size())
	quit(0)
