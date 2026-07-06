extends SceneTree

const AuraSystem = preload("res://scripts/aura_system.gd")

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)

func _enemy(uid: int, hp := 100.0, pos := Vector2(100, 100)) -> Dictionary:
	return {"uid": uid, "hp": hp, "max_hp": hp, "pos": pos}

func _initialize() -> void:
	var rational := AuraSystem.create("Racional", 2)
	rational["last_pos"] = Vector2(50, 50)
	var events := AuraSystem.update(rational, 4.6, {"player_pos": Vector2(50, 50), "enemies": []})
	_check(events.size() == 1 and int(events[0]["amount"]) == 9, "Racional stationary score diverged from desktop")
	AuraSystem.on_dash(rational)
	_check(is_equal_approx(AuraSystem.world_multiplier(rational), 0.42), "Racional dilation world factor must be 0.42")
	_check(is_equal_approx(AuraSystem.speed_multiplier(rational), 1.35), "Racional movement factor must be 1.35")

	var impulsive := AuraSystem.create("Impulsiva", 1)
	for i in range(5): AuraSystem.on_enemy_killed(impulsive, _enemy(i))
	_check(int(impulsive["impulsive_rank"]) == 1 and float(impulsive["impulsive_active"]) == 3.5, "Impulsiva did not activate after five kills")
	var panic := AuraSystem.on_player_hit(impulsive, 10, 100, 100)
	_check(not bool(panic["blocked"]) and int(impulsive["impulsive_panic"]) == 1, "Impulsiva hit did not arm Panic")
	panic = AuraSystem.on_player_hit(impulsive, 10, 90, 100)
	_check(is_equal_approx(float(panic["amount"]), 25.0), "Impulsiva Panic multiplier diverged")

	var devoted := AuraSystem.create("Devota", 2)
	var shield := AuraSystem.on_player_hit(devoted, 80, 50, 100)
	_check(bool(shield["blocked"]) and int(devoted["devoted_charges"]) == 2, "Devota did not consume one shield charge")
	_check(is_equal_approx(float(shield["heal"]), 5.0), "Devota must heal ten percent of missing health")
	AuraSystem.on_player_hit(devoted, 80, 55, 100)
	AuraSystem.on_player_hit(devoted, 80, 60, 100)
	_check(is_equal_approx(AuraSystem.damage_multiplier(devoted), 1.65), "Devota final break must grant 1.65 damage")

	var vanguard := AuraSystem.create("Vanguarda", 3)
	AuraSystem.on_player_hit(vanguard, 10, 100, 100)
	var burning := _enemy(20, 1000.0)
	burning["aura_burn"] = 8.0
	burning["aura_burn_tick"] = 0.0
	events = AuraSystem.update(vanguard, 0.1, {"player_pos": Vector2.ZERO, "enemies": [burning]})
	_check(events.any(func(e): return String(e["type"]) == "enemy_damage" and float(e["amount"]) == 16.0), "Vanguarda burn formula diverged")

	var insane := AuraSystem.create("Insana", 2)
	insane["insane_ready"] = 0.0
	AuraSystem.on_attack(insane, {"pos": Vector2(40, 40), "dir": Vector2.RIGHT, "damage": 10.0})
	events = AuraSystem.update(insane, 1.01, {"player_pos": Vector2.ZERO, "enemies": []})
	_check(events.any(func(e): return String(e["type"]) == "echo_shot" and is_equal_approx(float(e["damage_mult"]), 0.22)), "Insana echo delay or damage diverged")

	var voracious := AuraSystem.create("Voraz", 1)
	AuraSystem.on_enemy_killed(voracious, _enemy(30, 100, Vector2(70, 70)))
	events = AuraSystem.update(voracious, 0.1, {"player_pos": Vector2(70, 70), "enemies": []})
	_check(events.any(func(e): return String(e["type"]) == "heal_lost"), "Voraz clot was not collected")
	_check(float(voracious["voracious_hunger"]) > 0.0, "Voraz clot did not feed Hunger")

	var null_aura := AuraSystem.create("Nula", 1)
	AuraSystem.update(null_aura, 11.0, {"player_pos": Vector2.ZERO, "enemies": []})
	var null_shot := {"damage": 100.0}
	AuraSystem.on_attack(null_aura, null_shot)
	_check(bool(null_shot.get("aura_null", false)), "Nula did not arm the next shot at full Void")
	var null_hit := AuraSystem.on_enemy_hit(null_aura, _enemy(40, 1000), null_shot, 100.0)
	_check(float(null_hit["damage"]) > 118.0, "Nula robust-target bonus was not applied")

	var abyss := AuraSystem.create("Abissal", 1)
	abyss["abyss_depth"] = 99.9
	var crowd := []
	for i in range(10): crowd.append(_enemy(50 + i, 100, Vector2(10 + i, 10)))
	AuraSystem.update(abyss, 1.0, {"player_pos": Vector2.ZERO, "enemies": crowd, "boss_active": true})
	_check(float(abyss["abyss_tide"]) > 0.0, "Abissal did not trigger Black Tide at full Depth")

	var prophecy := AuraSystem.create("Profetica", 1)
	prophecy["prophecy_next"] = 0.0
	var marked := _enemy(70)
	AuraSystem.update(prophecy, 0.01, {"player_pos": Vector2.ZERO, "enemies": [marked]})
	_check(int(prophecy["prophecy_uid"]) == 70, "Profetica did not mark an available target")
	var prophecy_hit := AuraSystem.on_enemy_hit(prophecy, marked, {}, 100.0)
	_check(float(prophecy_hit["damage"]) > 120.0, "Profetica marked-target reward was not applied")

	var blood := AuraSystem.create("Sanguinaria", 1)
	var wounded := _enemy(80)
	for i in range(3): AuraSystem.on_enemy_hit(blood, wounded, {}, 100.0)
	_check(float(wounded.get("aura_wound", 0.0)) > 0.0, "Sanguinaria did not open a wound after three hits")
	_check(float(blood["blood_thirst"]) > 0.0, "Sanguinaria wound did not feed Thirst")

	print("AURAS_DESKTOP_FIDELITY_SMOKE_OK count=10 mechanics=true penalties=true")
	quit(0)
