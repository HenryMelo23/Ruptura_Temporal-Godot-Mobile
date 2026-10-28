extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("HENRY_COLOSSUS_SMOKE_FAIL " + message)
	_cleanup(1)


func _spawn_target(position: Vector2, hp := 5000.0) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, position)
	var enemy: Dictionary = game.enemies[-1]
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	enemy["stun"] = 0.0
	return enemy


func _rear_tie_blue_count(image: Image, row: int) -> int:
	var total := 0
	for y in range(row * 256, (row + 1) * 256):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a > 0.12 and color.b > 0.68 and color.b > color.r + 0.25 and color.b > color.g + 0.2:
				total += 1
	return total


func _run() -> void:
	game.active_character_key = game.CHARACTER_HENRY
	game.selected_mutation = 2
	game.selected_effect = 2
	game.forced_initial_phase = 1
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.henry_incendiary_ability_controller.cancel_entrance()
	game.henry_entry_timer = 0.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(700.0, 450.0)
	game.last_facing = Vector2.RIGHT
	game.player_damage = 100.0
	game.player_defense = 0.0
	game.enemies.clear()
	var owner = game.henry_colossus_ability_controller

	_check(game.mutation_key == "colosso" and game.effect_key == "lastro", "selection did not reach runtime")
	_check(owner.core == game, "owner was not bound")
	_check(String(game._selection_manifest_item(game.HENRY_SELECTION_INDEX).get("name", "")) == "Colosso D37", "selection facade lost mutation name")
	_check(String(game._selection_aura_item(game.HENRY_SELECTION_INDEX).get("name", "")) == "Lastro", "selection facade lost effect name")
	_check(game._known_manifestation_key("colosso") and game._manifestation_index_for_key("colosso", 0) == game.HENRY_SELECTION_INDEX, "network key contract rejected Colosso")
	var saved_fields: Dictionary = game._build_interrupted_run_snapshot().get("fields", {})
	_check(String(saved_fields.get("mutation_key", "")) == "colosso" and String(saved_fields.get("effect_key", "")) == "lastro", "save selection contract lost Colosso/Lastro")

	var transform := load("res://assets/sprites/player/player_2_suit/henry_colossus_transform_sheet_v1.png") as Texture2D
	var walk := load("res://assets/sprites/player/player_2_suit/henry_colossus_walk_sheet_v1.png") as Texture2D
	var attack := load("res://assets/sprites/player/player_2_suit/henry_colossus_attack_sheet_v1.png") as Texture2D
	var skill := load("res://assets/sprites/player/player_2_suit/henry_colossus_skill_sheet_v1.png") as Texture2D
	var normal_attack := load("res://assets/sprites/player/player_2_suit/henry_colossus_normal_attack_sheet_v1.png") as Texture2D
	var normal_skill := load("res://assets/sprites/player/player_2_suit/henry_colossus_normal_skill_sheet_v1.png") as Texture2D
	_check(transform != null and transform.get_size() == Vector2(2048, 256), "transform atlas dimensions changed")
	_check(walk != null and walk.get_size() == Vector2(768, 768), "giant walk atlas dimensions changed")
	_check(attack != null and attack.get_size() == Vector2(1024, 768), "giant attack atlas dimensions changed")
	_check(skill != null and skill.get_size() == Vector2(768, 768), "giant skill atlas dimensions changed")
	_check(normal_attack != null and normal_attack.get_size() == Vector2(1024, 768), "normal attack atlas dimensions changed")
	_check(normal_skill != null and normal_skill.get_size() == Vector2(768, 768), "normal skill atlas dimensions changed")
	_check(_rear_tie_blue_count(walk.get_image(), 2) == 0 and _rear_tie_blue_count(attack.get_image(), 2) == 0 and _rear_tie_blue_count(skill.get_image(), 2) == 0, "a rear-facing giant frame contains tie blue")
	_check(_rear_tie_blue_count(normal_attack.get_image(), 2) == 0 and _rear_tie_blue_count(normal_skill.get_image(), 2) == 0, "a rear-facing normal frame contains tie blue")
	_check(Array(game.textures.get("henry_colossus_normal_fire_network", [])).size() == 40, "normal network attack pool is incomplete")
	_check(Array(game.textures.get("henry_colossus_fire_network", [])).size() == 40, "giant network attack pool is incomplete")

	var target := _spawn_target(game.player_pos + Vector2(90.0, 0.0))
	var normal_hp := float(target["hp"])
	_check(owner.fire_auto_attack(), "normal melee did not start")
	_check(float(target["hp"]) < normal_hp and owner.impetus == 1 and owner.fury >= owner.FURY_PER_HIT, "normal melee did not damage or build Impetus/Fury")
	_check(Vector2(target.get("henry_colossus_knockback", Vector2.ZERO)).x > 0.0, "normal hit did not start natural knockback")
	var normal_push_speed := Vector2(target["henry_colossus_knockback"]).length()
	owner.combo_stage = 2
	owner.on_damage_confirmed_enemy(target, 10.0, 0, "henry_colossus_melee_third")
	_check(Vector2(target["henry_colossus_knockback"]).length() > normal_push_speed + owner.HIT_PUSH_SPEED, "third hit did not apply stronger knockback")
	var pushed_from := Vector2(target["pos"])
	owner.update(0.08)
	_check(Vector2(target["pos"]).x > pushed_from.x, "knockback teleported or failed to move over time")
	_check(owner.impact_armor > 0.0 and owner.impact_armor <= owner._impact_armor_cap(), "melee contact did not grant capped impact armor")
	var armor_before_hit: float = owner.impact_armor
	var fury_before_hit: float = owner.fury
	var damage_after_armor: float = owner.modify_incoming_damage(10.0, "test")
	_check(damage_after_armor < 10.0 and owner.impact_armor < armor_before_hit, "impact armor did not absorb incoming damage")
	_check(owner.fury - fury_before_hit > owner.FURY_PER_HIT, "taking damage did not grant more Fury than landing a hit")
	_check(game.slashes.any(func(event): return event.get("kind", "") == "henry_colossus_impact"), "melee contact did not emit impact")
	var far_target := _spawn_target(game.player_pos + Vector2(160.0, 0.0))
	var far_hp := float(far_target["hp"])
	owner.fire_auto_attack()
	_check(is_equal_approx(float(far_target["hp"]), far_hp), "normal melee exceeded its range")
	game.enemies.clear()
	game.boss_active = true
	game.boss_hp = 5000.0
	game.boss_hp_max = 5000.0
	game.boss_pos = game.player_pos + Vector2(80.0, 0.0)
	var boss_position_before: Vector2 = game.boss_pos
	owner.combo_stage = 2
	owner.fire_auto_attack()
	owner.update(0.08)
	_check(game.boss_pos == boss_position_before, "third hit pushed a boss")
	game.boss_active = false

	owner.impact_armor = 0.0
	owner.fury = owner.FLASK_FURY_COST
	game.player_hp = int(game.player_hp_max * 0.4)
	var hp_before_flask: int = int(game.player_hp)
	_check(owner.begin_skill(game.player_pos + Vector2.RIGHT * 100.0), "normal flask did not begin")
	_check(game.player_hp > hp_before_flask and owner.fury < owner.FLASK_FURY_COST, "flask did not heal or consume significant Fury")
	owner.update(owner.FLASK_DURATION + 0.01)
	_check(not owner.flask_active and not game.henry_skill_cast_active, "flask cast did not finish")
	_check(owner.activate_reinforcement() and owner.reinforced_hit_ready, "normal reinforcement did not arm the next hit")
	var reinforced_target := _spawn_target(game.player_pos + Vector2(70.0, 0.0))
	var reinforced_hp := float(reinforced_target["hp"])
	owner.combo_stage = 0
	owner.fire_auto_attack()
	_check(reinforced_hp - float(reinforced_target["hp"]) >= game.player_damage * 2.0 and not owner.reinforced_hit_ready, "reinforced next hit was not huge or was not consumed")

	game.enemies.clear()
	owner.fury = owner.FURY_MAX
	owner.update(0.01)
	_check(owner.transforming and owner.fury <= 0.01, "full Fury did not automatically begin and pay for the ultimate")
	_check(game.henry_ultimate_cast_active and game._local_player_controls_locked(), "growth did not lock controls")
	owner.update(owner.TRANSFORM_DURATION + 0.01)
	_check(owner.giant_active and not game.henry_ultimate_cast_active, "growth did not release into giant form")
	_check(owner.giant_temp_hp > 0.0 and owner.giant_armor > 0.0 and owner.visual_height_multiplier() > 1.7, "giant form lost armor, temporary protection, or visual scale")
	owner.reinforcement_cooldown = 0.0
	_check(owner.activate_reinforcement() and owner.retaliation_timer >= owner.REINFORCEMENT_DURATION, "giant reinforcement did not arm retaliation")
	game.enemies.clear()
	var retaliation_target := _spawn_target(game.player_pos + Vector2(72.0, 0.0))
	var retaliation_hp := float(retaliation_target["hp"])
	owner.modify_incoming_damage(100.0, "enemy_contact")
	_check(retaliation_hp - float(retaliation_target["hp"]) >= 69.0, "retaliation did not return 70 percent damage")
	game.enemies.clear()
	var giant_target := _spawn_target(game.player_pos + Vector2(150.0, 0.0))
	var cleave_target := _spawn_target(game.player_pos + Vector2(245.0, 0.0))
	var side_target := _spawn_target(game.player_pos + Vector2(245.0, 100.0))
	var giant_hp := float(giant_target["hp"])
	var cleave_hp := float(cleave_target["hp"])
	var side_hp := float(side_target["hp"])
	owner.fire_auto_attack()
	_check(float(giant_target["hp"]) < giant_hp, "giant melee did not gain reach")
	_check(float(cleave_target["hp"]) < cleave_hp, "giant punch did not cleave the enemy behind its primary target")
	_check(is_equal_approx(float(side_target["hp"]), side_hp), "giant cleave escaped its forward corridor")
	_check(owner.begin_skill(game.player_pos + Vector2.RIGHT * 400.0), "giant charge did not begin")
	owner.update(owner.CHARGE_DURATION + 0.01)
	_check(not owner.charge_active and game.player_pos.x > 800.0, "giant charge did not move and finish")
	var leap_origin: Vector2 = Vector2(game.player_pos)
	game._execute_teleport(game.player_pos + Vector2.RIGHT * 500.0)
	_check(owner.leap_active, "giant leap did not replace teleport")
	_check(owner.is_leap_invulnerable(), "giant leap did not grant immunity")
	var leap_hp: int = int(game.player_hp)
	game._damage_player(999, "boss1_wave")
	game._rpc_apply_hostile_status("stun", 2.0)
	_check(game.player_hp == leap_hp and game.player_stun_timer <= 0.0, "boss ultimate damage or hostile control pierced airborne immunity")
	owner.update(owner.LEAP_DURATION * 0.5)
	_check(owner.leap_visual_height() > owner.LEAP_HEIGHT * 0.9 and game.player_pos.x > leap_origin.x, "leap did not visibly rise and travel")
	owner.update(owner.LEAP_DURATION * 0.55)
	_check(not owner.leap_active and owner.leap_visual_height() == 0.0, "leap did not land and release immunity")
	owner.update(owner.GIANT_DURATION + 0.01)
	_check(owner.shrinking and game.henry_ultimate_cast_active, "30 second giant duration did not enter reverse growth")
	owner.update(owner.TRANSFORM_DURATION + 0.01)
	_check(not owner.giant_active and not owner.shrinking and is_equal_approx(owner.visual_height_multiplier(), 1.0), "reverse growth did not restore normal form")
	var normal_teleport_target: Vector2 = game.player_pos + Vector2(0.0, 80.0)
	game._execute_teleport(normal_teleport_target)
	_check(not owner.leap_active and game.player_pos.distance_to(normal_teleport_target) <= 0.1, "normal Colosso no longer uses the regular teleport")

	game.enemies.clear()
	var lastro_target := _spawn_target(game.player_pos + Vector2(80.0, 0.0))
	for hit in range(owner.LASTRO_REQUIRED):
		game.time_alive += owner.LASTRO_HIT_THROTTLE + 0.01
		owner.on_damage_confirmed_enemy(lastro_target, 10.0, 0)
	_check(float(lastro_target.get("stun", 0.0)) >= owner.LASTRO_ENEMY_ANCHOR and int(lastro_target.get("henry_lastro_stacks", -1)) == 0, "Lastro did not anchor on the fifth confirmed damage event")
	game.boss_active = true
	game.boss_hp = 5000.0
	game.boss_hp_max = 5000.0
	game.boss_pos = game.player_pos + Vector2(80.0, 0.0)
	for hit in range(owner.LASTRO_REQUIRED):
		owner.on_damage_confirmed_boss(10.0, 0)
	_check(owner.boss_lastro_slow_timer >= owner.LASTRO_BOSS_DURATION and owner.boss_move_multiplier() < 1.0, "Lastro did not apply the boss-safe slow")
	game.boss_active = false
	game.mutation_key = "barometrico"
	game.effect_key = "lastro"
	var cross_target := _spawn_target(game.player_pos + Vector2(84.0, 0.0))
	game.time_alive += 1.0
	owner.on_damage_confirmed_enemy(cross_target, 10.0, 0)
	_check(int(cross_target.get("henry_lastro_stacks", 0)) == 1, "Lastro stopped working with another mutation")
	game.effect_key = "nimbo"
	game.time_alive += 1.0
	owner.on_damage_confirmed_enemy(cross_target, 10.0, 0)
	_check(int(cross_target.get("henry_lastro_stacks", 0)) == 1, "Lastro stacked while another effect was selected")

	game.mutation_key = "colosso"
	game.effect_key = "lastro"
	owner.giant_active = true
	var visual: PackedFloat32Array = game._network_player_visual_snapshot()
	var unpacked: Dictionary = game.RTVisualSyncContractScript.unpack_player_visual(visual)
	_check((int(unpacked.get("visual_flags", 0)) & 4) != 0, "giant bit was not packed in the visual snapshot")
	var remote_giant := game._net_player_texture_for_state(game.NET_ANIM_RIGHT, 0, game.HENRY_SELECTION_INDEX, "colosso", true) as AtlasTexture
	var remote_normal := game._net_player_texture_for_state(game.NET_ANIM_FIRE, 0, game.HENRY_SELECTION_INDEX, "colosso", false) as AtlasTexture
	_check(remote_giant != null and remote_giant == Array(game.textures.get("henry_colossus_right", []))[0], "remote giant did not use the giant walk frame pool")
	_check(remote_normal != null and remote_normal == Array(game.textures.get("henry_colossus_normal_fire_network", []))[0], "remote normal melee did not use the normal attack frame pool")
	owner.reset()
	_check(not owner.giant_active and owner.giant_temp_hp == 0.0 and owner.giant_armor == 0.0 and owner.fury == 0.0, "reset persisted giant combat state")
	game.slashes.clear()
	owner._emit_impact(game.player_pos, Vector2.RIGHT, 26.0)
	game._update_effects(0.31)
	_check(game.slashes.is_empty(), "cosmetic impact outlived its expiry")
	for index in range(80):
		owner._emit_impact(game.player_pos, Vector2.RIGHT, 26.0)
	_check(game.slashes.size() <= 32, "impact budget is unbounded")
	game.slashes.append({"kind": "other_visual", "life": 1.0})
	owner.reset()
	_check(game.slashes.size() == 1 and game.slashes[0].get("kind") == "other_visual", "reset removed another effect or kept Colosso impacts")
	game.slashes.clear()
	game.enemies.clear()
	owner.fire_auto_attack()
	_check(game.slashes.is_empty(), "miss generated a contact impact")

	print("HENRY_COLOSSUS_SMOKE_OK mutation=colosso effect=lastro fury_auto_ultimate=true hit_knockback=true third_hit_push=true flask_heal=true reinforcement=true retaliation_70=true giant_armor=true giant_cleave=true giant_duration=30 giant_charge=true giant_leap=true leap_immunity=true collision_unchanged=true reverse_growth=true lastro_cross_combo=true save_selection=true network_flag=true sprites=6 impact_expiry_budget_reset=true")
	_cleanup(0)


func _cleanup(code: int) -> void:
	if game != null and is_instance_valid(game):
		game._cleanup_runtime_resources()
		game.queue_free()
	quit(code)
