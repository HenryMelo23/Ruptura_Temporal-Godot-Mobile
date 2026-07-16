extends SceneTree

const AuraSystem = preload("res://scripts/aura_system.gd")

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)

func _enemy(uid: int, pos := Vector2(100, 100)) -> Dictionary:
	return {
		"uid": uid,
		"type": "common",
		"hp": 1000.0,
		"max_hp": 1000.0,
		"pos": pos,
		"shoot_cd": 0.1,
		"throw_cd": 3.0,
		"stun": 0.0,
		"prepare": 0.0,
	}

func _initialize() -> void:
	var crepuscular := AuraSystem.create("Crepuscular", 1)
	_check(String(crepuscular["crepuscular_phase"]) == "alvorada", "Crepuscular did not start in Alvorada")
	AuraSystem.update(crepuscular, 8.1, {"player_pos": Vector2.ZERO, "hp": 100.0, "hp_max": 100.0})
	_check(float(crepuscular["crepuscular_charge"]) > 50.0, "Alvorada did not gain charge while safe")
	crepuscular["crepuscular_charge"] = 72.0
	crepuscular["crepuscular_phase_timer"] = 0.1
	AuraSystem.on_dash(crepuscular, {"origin_pos": Vector2.ZERO, "target_pos": Vector2(80, 0)})
	_check(float(crepuscular["crepuscular_eclipse"]) > 0.0, "Crepuscular perfect teleport did not trigger Eclipse")
	_check(AuraSystem.damage_multiplier(crepuscular) > 1.0 and AuraSystem.speed_multiplier(crepuscular) > 1.0, "Eclipse did not combine offensive and movement bonuses")

	var peregrino := AuraSystem.create("Peregrino", 1)
	for pos in [Vector2(20, 20), Vector2(340, 20), Vector2(660, 20), Vector2(980, 20), Vector2(1300, 20)]:
		AuraSystem.update(peregrino, 0.1, {"player_pos": pos, "hp": 70.0, "hp_max": 100.0})
	_check(float(peregrino["peregrino_journey"]) > 0.0, "Peregrino did not start Jornada after valid sectors")
	var refuge_pos: Vector2 = peregrino["peregrino_refuge_pos"]
	var events := AuraSystem.update(peregrino, 0.1, {"player_pos": refuge_pos, "hp": 70.0, "hp_max": 100.0})
	_check(events.any(func(e): return String(e.get("text", "")) == "REFUGIO"), "Peregrino did not heal when returning to Refugio")

	var equilibrista := AuraSystem.create("Equilibrista", 1)
	AuraSystem.update(equilibrista, 6.3, {"player_pos": Vector2.ZERO, "hp": 60.0, "hp_max": 100.0})
	_check(float(equilibrista["equilibrista_state"]) > 0.0, "Equilibrista did not activate after holding the safe band")
	var hit := AuraSystem.on_player_hit(AuraSystem.create("Equilibrista", 1), 40.0, 50.0, 100.0)
	_check(float(hit["amount"]) <= 15.1, "Equilibrista did not convert lethal band-crossing into Debt")

	var avarento := AuraSystem.create("Avarento", 2)
	AuraSystem.update(avarento, 0.1, {"player_pos": Vector2.ZERO, "score": 2000, "card_cost": 500, "hp_max": 450.0})
	_check(float(avarento["avarento_lastro"]) > 2.0, "Avarento did not compute Lastro from stored points")
	AuraSystem.on_points_spent(avarento, 500, 450.0)
	_check(float(avarento["avarento_cofre"]) > 0.0 and AuraSystem.speed_multiplier(avarento) > 1.0, "Avarento spending did not rupture the Cofre")

	var oportunista := AuraSystem.create("Oportunista", 3)
	var target := _enemy(10)
	for i in range(3):
		AuraSystem.on_enemy_hit(oportunista, target, {"kind": "eletrica", "source_category": "basic_attack", "player_damage": 100.0}, 90.0)
		target["shoot_cd"] = 0.1
		oportunista["oportunista_enemy_cd"] = {}
	_check(bool(oportunista["oportunista_armed"]), "Oportunista did not arm after openings")
	var consume := AuraSystem.consume_opportunity_damage(oportunista, 100.0)
	_check(float(consume["bonus"]) > 0.0 and not bool(oportunista["oportunista_armed"]), "Oportunista did not consume the armed hit")

	print("NEW_AURAS_MECHANICS_SMOKE_OK count=5 mechanics=true")
	quit(0)
