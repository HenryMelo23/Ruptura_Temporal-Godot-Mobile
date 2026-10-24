extends SceneTree

const EXPECTED_BASE_RANGE := 300.0
const EXPECTED_RANGE_PER_COPY := 30.0
const EXPECTED_DAMAGE_PER_COPY := 0.025
const EXPECTED_PRISMATIC_RICOCHET_CRIT_PER_COPY := 0.03

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("RANGED_ATTACK_RANGE_SMOKE_FAIL " + message)
	_cleanup(1)


func _spawn_target(offset: Vector2, hp := 5000.0) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + offset)
	var enemy: Dictionary = game.enemies[-1]
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	enemy["stun"] = 999.0
	return enemy


func _cleanup(code := 0) -> void:
	if game != null:
		game.mode = "menu"
		game.visible = false
		game.set_process(false)
		game.set_physics_process(false)
		game._cleanup_runtime_resources()
		root.remove_child(game)
		game.free()
		game = null
	quit(code)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.online_connected = false
	game.boss_active = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(900.0, 620.0)
	game.last_facing = Vector2.RIGHT
	game.desktop_attack_aim_mode = game.DESKTOP_ATTACK_AIM_AUTO
	game.attack_dragging = false
	game.attack_drag_direction = Vector2.ZERO
	game.locked_target_kind = ""
	game.enemies.clear()
	game.bullets.clear()
	game.return_bullets.clear()
	game.cards_bought[game.CARD_RANGE_ID] = 0

	var card: Dictionary = game._find_card_by_id(game.CARD_RANGE_ID)
	_check(not card.is_empty(), "card_missing")
	_check(game._is_uncommon_card(card), "card_is_not_uncommon")
	_check(not game._can_burn_shop_card(card), "uncommon_card_is_burnable")
	_check(not game._card_at_max(card), "card_has_a_finite_limit")
	_check(game.textures.get("card_" + String(card["name"])) != null, "card_frame_1_missing")
	_check(game.textures.get("card_" + String(card["name"]) + "_2") != null, "card_frame_2_missing")
	_check(is_equal_approx(game._ranged_primary_attack_range(), EXPECTED_BASE_RANGE), "base_range_is_not_300")

	# Automatic aim must not spend the shot if no valid target is inside the ring.
	game.time_alive = 20.0
	game.last_attack_time = -999.0
	game._try_attack()
	_check(game.bullets.is_empty() and game.return_bullets.is_empty(), "automatic_aim_fired_without_target")
	_check(is_equal_approx(game.last_attack_time, -999.0), "automatic_aim_spent_cooldown_without_target")

	var outside := _spawn_target(Vector2(EXPECTED_BASE_RANGE + 70.0, 0.0))
	game._try_attack()
	_check(game.bullets.is_empty(), "automatic_aim_fired_at_target_outside_range")
	_check(game._auto_target_enemy().is_empty(), "out_of_range_target_entered_auto_selection")

	outside["pos"] = game.player_pos + Vector2(EXPECTED_BASE_RANGE - 5.0, 0.0)
	game._try_attack()
	_check(game.bullets.size() == 1, "automatic_aim_did_not_fire_inside_range")
	var inside_bullet: Dictionary = game.bullets[0]
	_check(is_equal_approx(float(inside_bullet.get("max_range", 0.0)), EXPECTED_BASE_RANGE), "projectile_missing_base_range")
	game.bullets.clear()

	# A lock outside the ring remains visible, but automatic fire must stop.
	outside["pos"] = game.player_pos + Vector2(EXPECTED_BASE_RANGE + 10.0, 0.0)
	game.locked_target_kind = "enemy"
	game.locked_target_uid = int(outside["uid"])
	var hp_before := float(outside["hp"])
	game.last_attack_time = -999.0
	game._try_attack()
	_check(game.bullets.is_empty(), "automatic_aim_fired_at_locked_target_outside_range")
	_check(game._locked_attack_target_pos() == Vector2(outside["pos"]), "outside_lock_was_dropped")
	game.attack_dragging = true
	game.attack_drag_direction = Vector2.RIGHT
	game._try_attack()
	game.attack_dragging = false
	game.attack_drag_direction = Vector2.ZERO
	_check(game.bullets.size() == 1, "manual_aim_could_not_fire_at_locked_target_outside_range")
	var furthest_travel := 0.0
	for step in range(120):
		if game.bullets.is_empty():
			break
		game._update_bullets(1.0 / 120.0)
		if not game.bullets.is_empty():
			furthest_travel = maxf(furthest_travel, float(game.bullets[0].get("range_traveled", 0.0)))
	_check(game.bullets.is_empty(), "projectile_survived_past_range_boundary")
	_check(furthest_travel <= EXPECTED_BASE_RANGE + 8.0, "projectile_traveled_beyond_boundary")
	_check(is_equal_approx(float(outside["hp"]), hp_before), "outside_locked_target_was_hit")

	# The same limit and fade state must survive the lightweight multiplayer replica.
	game.remote_bullets.clear()
	game._spawn_remote_bullet(77, "range:remote", game.player_pos, Vector2.RIGHT, 600.0, 2.0, "eletrica", false, Color.CYAN, 0.0, "linear", 0, EXPECTED_BASE_RANGE, 0.0)
	_check(game.remote_bullets.size() == 1, "remote_projectile_was_not_spawned")
	_check(is_equal_approx(float(game.remote_bullets[0].get("max_range", 0.0)), EXPECTED_BASE_RANGE), "remote_projectile_lost_range")
	for step in range(120):
		if game.remote_bullets.is_empty():
			break
		game._update_remote_bullets(1.0 / 120.0)
	_check(game.remote_bullets.is_empty(), "remote_projectile_survived_past_range_boundary")

	# Copies are progressive and deliberately uncapped.
	game.locked_target_kind = ""
	game.cards_bought[game.CARD_RANGE_ID] = 0
	for copy_index in range(20):
		_check(not game._card_at_max(card), "card_capped_at_copy_%d" % copy_index)
		game._apply_card(card)
	_check(int(game.cards_bought.get(game.CARD_RANGE_ID, 0)) == 20, "card_did_not_stack_to_twenty")
	_check(is_equal_approx(game._ranged_primary_attack_range(), EXPECTED_BASE_RANGE + EXPECTED_RANGE_PER_COPY * 20.0), "progressive_range_formula_changed")
	_check(is_equal_approx(game._ranged_primary_damage_multiplier(), 1.0 + EXPECTED_DAMAGE_PER_COPY * 20.0), "progressive_damage_formula_changed")

	game.bullets.clear()
	game._add_bullet({
		"pos": game.player_pos,
		"origin": game.player_pos,
		"source_category": "basic_attack",
		"dir": Vector2.RIGHT,
		"speed": 600.0,
		"life": 10.0,
		"max_life": 10.0,
		"age": 0.0,
		"phase": 0.0,
		"trail_cd": 10.0,
		"damage": 100.0,
		"kind": "eletrica",
		"pierce": false,
		"hits": {},
		"color": Color.CYAN,
	})
	var stacked_bullet: Dictionary = game.bullets[0]
	_check(is_equal_approx(float(stacked_bullet["max_range"]), 900.0), "stacked_projectile_range_wrong")
	_check(is_equal_approx(float(stacked_bullet["damage"]), 150.0), "stacked_projectile_damage_wrong")
	var derived_bullet: Dictionary = stacked_bullet.duplicate(true)
	derived_bullet["uid"] = "derived-range-smoke"
	derived_bullet["damage"] = 108.0
	game._add_bullet(derived_bullet)
	_check(is_equal_approx(float(game.bullets[-1]["damage"]), 108.0), "derived_projectile_received_card_damage_twice")

	# Prismatica alone keeps an uncapped projectile. Its automatic acquisition
	# remains fixed at 300 px and every range stack becomes ricochet crit chance.
	game.active_character_key = game.CHARACTER_GEOVANA
	game.manifestation_key = "prismatica"
	game.locked_target_kind = ""
	game.locked_target_uid = -1
	_check(is_equal_approx(game._ranged_primary_attack_range(), EXPECTED_BASE_RANGE), "prismatica_auto_range_grew_with_card")
	_check(is_equal_approx(game.RangedAttackRange.prismatica_ricochet_crit_bonus(game), EXPECTED_PRISMATIC_RICOCHET_CRIT_PER_COPY * 20.0), "prismatica_ricochet_crit_conversion_wrong")
	outside["pos"] = game.player_pos + Vector2(EXPECTED_BASE_RANGE + 10.0, 0.0)
	game.bullets.clear()
	game.last_attack_time = -999.0
	game._try_attack()
	_check(game.bullets.is_empty(), "prismatica_auto_fired_outside_targeting_ring")
	_check(game._auto_target_enemy().is_empty(), "prismatica_auto_locked_outside_targeting_ring")

	game._add_bullet({
		"pos": game.player_pos,
		"origin": game.player_pos,
		"source_category": "basic_attack",
		"dir": Vector2.RIGHT,
		"speed": 600.0,
		"life": 10.0,
		"max_life": 10.0,
		"damage": 100.0,
		"kind": "prismatica",
		"pierce": true,
		"hits": {},
		"color": Color.CYAN,
	})
	var prismatica_bullet: Dictionary = game.bullets[-1]
	_check(not prismatica_bullet.has("max_range"), "prismatica_projectile_received_physical_range_cap")
	_check(is_equal_approx(float(prismatica_bullet["life"]), 10.0), "prismatica_authored_lifetime_was_shortened")
	_check(is_equal_approx(float(prismatica_bullet["damage"]), 150.0), "prismatica_lost_card_damage_bonus")
	_check(is_equal_approx(float(prismatica_bullet.get("prismatica_ricochet_crit_bonus", 0.0)), 0.6), "prismatica_bullet_lost_ricochet_crit_bonus")

	game.player_crit_chance = 0.0
	game.ancorada_crit_bonus = 0.0
	var guaranteed_ricochet := {"damage": 100.0, "kind": "prismatica", "ricocheted": true, "prismatica_ricochet_crit_bonus": 1.02}
	var overcrit_result: Dictionary = game._bullet_critical_damage(guaranteed_ricochet)
	_check(bool(overcrit_result["critical"]), "prismatica_ricochet_bonus_did_not_guarantee_critical")
	_check(is_equal_approx(float(overcrit_result["amount"]), 306.0), "prismatica_ricochet_overcrit_lost_infinite_progression")
	var first_hit_result: Dictionary = game._bullet_critical_damage({"damage": 100.0, "kind": "prismatica", "prismatica_ricochet_crit_bonus": 1.02})
	_check(not bool(first_hit_result["critical"]), "prismatica_bonus_applied_before_ricochet")
	var prism_desc := String(game.MANIFESTATIONS[game._manifestation_index_for_key("prismatica", -1)].get("desc", ""))
	_check(prism_desc.find("Todo alcance adicional vira chance de critico nos ricochetes") >= 0, "prismatica_passive_description_missing_conversion")
	var prism_details: Dictionary = game._manifestation_details("prismatica")
	_check(String(prism_details.get("disparo", "")).find("PASSIVA") >= 0, "prismatica_details_missing_passive_label")
	_check(String(prism_details.get("disparo", "")).find("+3% de critico") >= 0, "prismatica_details_missing_conversion_value")
	_check(String(card.get("desc", "")).find("+3% de critico nos ricochetes") >= 0, "card_description_missing_prismatica_conversion")

	# Melee identities retain their authored range and never receive the ring rule.
	game.active_character_key = game.CHARACTER_GEOVANA
	game.manifestation_key = "lacerante"
	_check(not game.RangedAttackRange.is_ranged_primary(game), "lacerante_was_converted_to_ranged")
	game.active_character_key = game.CHARACTER_HENRY
	game.mutation_key = "colosso"
	_check(not game.RangedAttackRange.is_ranged_primary(game), "colosso_was_converted_to_ranged")
	game.mutation_key = "incendiario"
	_check(game.RangedAttackRange.is_ranged_primary(game), "incendiario_missing_ranged_contract")
	game.mutation_key = "barometrico"
	_check(game.RangedAttackRange.is_ranged_primary(game), "barometrico_missing_ranged_contract")

	print("RANGED_ATTACK_RANGE_SMOKE_OK base=300 card_range_per_copy=30 card_damage_per_copy=2.5pct prismatica_uncapped=true prismatica_ricochet_crit_per_copy=3pct auto_gate=true outside_lock_manual_only=true melee_excluded=true")
	_cleanup(0)
