extends SceneTree

const AuraSystem = preload("res://scripts/aura_system.gd")


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _enemy(uid: int, pos: Vector2 = Vector2.ZERO) -> Dictionary:
	return {"uid": uid, "hp": 1000.0, "max_hp": 1000.0, "pos": pos}


func _collect_voracious(state: Dictionary, count: int) -> Array:
	var all_events: Array = []
	for index in range(count):
		state["voracious_drops"].append({"pos": Vector2.ZERO, "life": 4.0, "value": 20.0})
		all_events.append_array(AuraSystem.update(state, 0.01, {"player_pos": Vector2.ZERO, "enemies": []}))
	return all_events


func _initialize() -> void:
	# Racional: level 1 remains baseline; 2/5/9 change the Focus decision;
	# 10 survives a fresh run creation as an ascension.
	var rational_one := AuraSystem.create("Racional", 1)
	rational_one["last_pos"] = Vector2.ZERO
	AuraSystem.update(rational_one, 4.6, {"player_pos": Vector2.ZERO, "enemies": []})
	_check(int(rational_one["rational_focus"]) == 0, "Racional level 1 gained pilot Focus")
	var rational_two := AuraSystem.create("Racional", 2)
	rational_two["last_pos"] = Vector2.ZERO
	var rational_events := AuraSystem.update(rational_two, 4.6, {"player_pos": Vector2.ZERO, "enemies": []})
	_check(int(rational_two["rational_focus"]) == 1 and rational_events.any(func(event): return String(event.get("text", "")) == "FOCO ANALITICO 1/1"), "Racional level 2 did not expose Focus")
	AuraSystem.on_dash(rational_two)
	_check(is_equal_approx(float(rational_two["rational_dilation"]), 9.25) and is_equal_approx(float(rational_two["rational_cooldown"]), 36.0), "Racional Focus did not change temporal dash")
	var rational_five := AuraSystem.create("Racional", 5)
	rational_five["last_pos"] = Vector2.ZERO
	AuraSystem.update(rational_five, 4.6, {"player_pos": Vector2.ZERO, "enemies": []})
	AuraSystem.update(rational_five, 4.6, {"player_pos": Vector2.ZERO, "enemies": []})
	_check(int(rational_five["rational_focus"]) == 2, "Racional level 5 did not raise Focus capacity")
	var rational_nine := AuraSystem.create("Racional", 9)
	rational_nine["rational_focus"] = 1
	AuraSystem.on_dash(rational_nine)
	_check(is_equal_approx(float(rational_nine["rational_dilation"]), 10.25) and is_equal_approx(float(rational_nine["rational_cooldown"]), 32.0), "Racional level 9 Focus values diverged")
	var rational_ten := AuraSystem.create("Racional", 10)
	_check(bool(rational_ten["ascended"]) and String(rational_ten["ascension_name"]) == "Mente de Laplace", "Racional ascension was lost when a new run was created")

	# Voraz: the reward is movement after a real clot collection, and the level-5
	# milestone is consumed only by a boss hit.
	var voracious_one := AuraSystem.create("Voraz", 1)
	_collect_voracious(voracious_one, 1)
	_check(float(voracious_one["voracious_satiation"]) <= 0.0, "Voraz level 1 gained Saciedade")
	var voracious_two := AuraSystem.create("Voraz", 2)
	var voracious_events := _collect_voracious(voracious_two, 1)
	_check(float(voracious_two["voracious_satiation"]) > 2.9 and is_equal_approx(AuraSystem.speed_multiplier(voracious_two), 1.08) and voracious_events.any(func(event): return String(event.get("text", "")) == "SACIEDADE"), "Voraz level 2 did not create Saciedade")
	var voracious_five := AuraSystem.create("Voraz", 5)
	_collect_voracious(voracious_five, 3)
	_check(bool(voracious_five["voracious_feast_ready"]), "Voraz level 5 did not arm Banquete")
	var feast_events := AuraSystem.on_boss_hit(voracious_five, Vector2.ZERO, 50.0)
	_check(not bool(voracious_five["voracious_feast_ready"]) and feast_events.any(func(event): return String(event.get("text", "")) == "BANQUETE") and feast_events.any(func(event): return is_equal_approx(float(event.get("amount", 0.0)), 0.75)), "Voraz Banquete did not consume once on boss hit")
	var voracious_nine := AuraSystem.create("Voraz", 9)
	_collect_voracious(voracious_nine, 3)
	var nine_events := AuraSystem.on_boss_hit(voracious_nine, Vector2.ZERO, 50.0)
	_check(nine_events.any(func(event): return is_equal_approx(float(event.get("amount", 0.0)), 1.25)), "Voraz level 9 did not improve Banquete")
	_check(bool(AuraSystem.create("Voraz", 10)["ascended"]), "Voraz ascension was not restored")

	# Vanguarda: guard never protects the triggering hit, ring range grows at the
	# milestone, and the level-9 cinder recovery can only occur once per ring.
	var vanguard_one := AuraSystem.create("Vanguarda", 1)
	AuraSystem.on_player_hit(vanguard_one, 100.0, 100.0, 100.0)
	var baseline_followup := AuraSystem.on_player_hit(vanguard_one, 100.0, 100.0, 100.0)
	_check(is_equal_approx(float(baseline_followup["amount"]), 100.0), "Vanguarda level 1 gained Brasa Protetora")
	var vanguard_two := AuraSystem.create("Vanguarda", 2)
	AuraSystem.on_player_hit(vanguard_two, 100.0, 100.0, 100.0)
	var guarded := AuraSystem.on_player_hit(vanguard_two, 100.0, 100.0, 100.0)
	_check(is_equal_approx(float(guarded["amount"]), 86.0) and Array(guarded["events"]).any(func(event): return String(event.get("text", "")) == "BRASA PROTETORA"), "Vanguarda level 2 guard did not protect a following hit")
	_check(is_equal_approx(AuraSystem.vanguard_ring_radius(AuraSystem.create("Vanguarda", 5)), 185.0), "Vanguarda level 5 ring range diverged")
	var vanguard_nine := AuraSystem.create("Vanguarda", 9)
	AuraSystem.on_player_hit(vanguard_nine, 10.0, 100.0, 100.0)
	var burning := _enemy(9)
	burning["aura_burn"] = 3.0
	burning["aura_burn_tick"] = 0.0
	var cinder_events := AuraSystem.update(vanguard_nine, 0.1, {"player_pos": Vector2.ZERO, "enemies": [burning]})
	_check(cinder_events.any(func(event): return String(event.get("type", "")) == "cooldown_recovery") and not bool(vanguard_nine["vanguard_cinder_ready"]), "Vanguarda level 9 cinder was not single-use")
	var second_cinder_events := AuraSystem.update(vanguard_nine, 1.1, {"player_pos": Vector2.ZERO, "enemies": [burning]})
	_check(not second_cinder_events.any(func(event): return String(event.get("type", "")) == "cooldown_recovery"), "Vanguarda level 9 cinder recovered twice in one ring")
	_check(bool(AuraSystem.create("Vanguarda", 10)["ascended"]), "Vanguarda ascension was not restored")

	print("SPECTER_PROGRESSION_PILOT_SMOKE_OK levels=1,2,5,9,10 pilots=3")
	quit(0)
