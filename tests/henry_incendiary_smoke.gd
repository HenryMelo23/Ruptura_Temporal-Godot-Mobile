extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("HENRY_INCENDIARY_SMOKE_FAIL " + message)
	_cleanup(1)


func _henry_sprite_metrics(image: Image, row: int, column: int) -> Dictionary:
	var origin := Vector2i(column * 256, row * 256)
	var min_y := 256
	var max_y := -1
	for y in range(256):
		for x in range(256):
			if image.get_pixel(origin.x + x, origin.y + y).a > 8.0 / 255.0:
				min_y = mini(min_y, y)
				max_y = maxi(max_y, y)
	var head_min_x := 256
	var head_max_x := -1
	var head_min_y := 256
	var head_max_y := -1
	var skin_sum := Vector3.ZERO
	var skin_count := 0
	for y in range(256):
		for x in range(256):
			var color := image.get_pixel(origin.x + x, origin.y + y)
			if color.a <= 8.0 / 255.0:
				continue
			var is_skin := color.r > 90.0 / 255.0 and color.r > color.g * 1.2 and color.g > color.b * 1.15 and color.g < 123.0 / 255.0
			if not is_skin:
				continue
			skin_sum += Vector3(color.r, color.g, color.b)
			skin_count += 1
			if y <= min_y + 80 and x >= 48 and x <= 208:
				head_min_x = mini(head_min_x, x)
				head_max_x = maxi(head_max_x, x)
				head_min_y = mini(head_min_y, y)
				head_max_y = maxi(head_max_y, y)
	return {
		"height": max_y - min_y + 1,
		"bottom": max_y,
		"head_width": head_max_x - head_min_x + 1,
		"head_height": head_max_y - head_min_y + 1,
		"skin": skin_sum / maxf(1.0, float(skin_count)),
	}


func _spawn_target(pos: Vector2, hp := 1200.0) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var enemy: Dictionary = game.enemies[-1]
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	return enemy


func _run() -> void:
	game.active_character_key = game.CHARACTER_HENRY
	game.selected_mutation = 0
	game.selected_effect = 0
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.player_pos = Vector2(700.0, 450.0)
	game.last_facing = Vector2.RIGHT
	game.player_damage = 100.0
	game.enemies.clear()
	game.bullets.clear()

	_check(game.active_character_key == game.CHARACTER_HENRY, "new run did not preserve Henry")
	_check(game.selected_manifestation == game.HENRY_SELECTION_INDEX, "mutation sentinel was not selected")
	_check(game.manifestation_key == "incendiario", "Incendiario mutation key missing")
	_check(game.effect_key == "incandescencia", "Incandescencia effect key missing")
	_check(game.henry_incendiary_ability_controller.core == game, "ability owner was not bound")

	game.card_unlock_progress["umbra_victories"] = 0.0
	game.henry_cheat_unlocked = false
	_check(not game._henry_unlocked(), "Henry unlocked before an UMBRA victory")
	_check(game._try_unlock_henry_cheat(" HENRY-P ", false), "HENRYP cheat was not normalized or accepted")
	_check(game._henry_unlocked(), "HENRYP did not unlock Henry locally")
	_check(game._try_unlock_henry_cheat("HENRYP", false), "HENRYP was not idempotent")
	game.henry_cheat_unlocked = false
	game.card_unlock_progress["umbra_victories"] = 1.0
	_check(game._henry_unlocked(), "Henry did not unlock after an UMBRA victory")
	game._open_character_select("solo")
	_check(game.mode == "character_select", "post-UMBRA new run did not open character selection")
	game._select_character(game.CHARACTER_HENRY)
	_check(game.mode == "mutation_select" and game.selected_manifestation == game.HENRY_SELECTION_INDEX, "Henry selection did not continue to Mutations")
	game.mode = "game"
	_check(Array(game.textures.get("henry_intro", [])).size() == game.HENRY_ENTRY_FRAME_COUNT, "dedicated Henry entrance atlas is incomplete")
	_check(Array(game.textures.get("henry_shop_entry", [])).size() == game.HENRY_SHOP_ENTRY_FRAME_COUNT, "dedicated Henry shop entrance atlas is incomplete")
	_check(Array(game.textures.get("henry_idle_pocket", [])).size() == game.HENRY_IDLE_POCKET_FRAME_COUNT, "Henry pocket/tap idle atlas is incomplete")
	_check(Array(game.textures.get("henry_idle", [])).size() == 13, "Henry network idle pool lost pocket or beard frames")
	for frame_idx in range(game.HENRY_ENTRY_FRAME_COUNT):
		var draw_height: float = game.EntitiesPresentation._henry_entry_draw_height(game, frame_idx)
		var intro_visible_height: float = float(game.HENRY_ENTRY_VISIBLE_HEIGHTS[frame_idx]) * draw_height / 256.0
		var idle_visible_height: float = game.HENRY_IDLE_VISIBLE_HEIGHT * game.HENRY_IDLE_DRAW_HEIGHT / 256.0
		_check(absf(intro_visible_height - idle_visible_height) < 0.01, "entrance frame %d changes Henry's visible height" % frame_idx)
	game.mode = "shop_opening"
	game.shop_opening_timer = game.SHOP_OPENING_ANIM_TIME
	_check(game._henry_shop_entry_frame() == 0, "shop entrance did not begin on its first frame")
	game.shop_opening_timer = game.SHOP_OPENING_ANIM_TIME * 0.49
	_check(game._henry_shop_entry_frame() == 4, "shop entrance did not reach its recovery frames")
	game.shop_opening_timer = 0.001
	_check(game._henry_shop_entry_frame() == game.HENRY_SHOP_ENTRY_FRAME_COUNT - 1, "shop entrance did not finish on its composed frame")
	var shop_entry_frames: Array = game.textures["henry_shop_entry"]
	_check(game._henry_player_texture(Vector2.ZERO) == shop_entry_frames[shop_entry_frames.size() - 1], "shop opening did not select Henry's dedicated animation")
	game.mode = "game"
	game._begin_player_start_down_intro()
	_check(game.henry_entry_timer == game.HENRY_ENTRY_DURATION and game._player_start_down_controls_locked(), "Henry entrance did not own its timer/control lock")
	game.henry_incendiary_ability_controller.cancel_entrance()
	game.henry_entry_timer = 0.0
	game.last_attack_time = -99.0
	game.henry_skill_cast_active = false
	game._reset_henry_idle_animation()
	game._update_henry_idle_animation(6.99)
	_check(game.henry_idle_beard_timer <= 0.0, "beard gesture started before seven seconds")
	game._update_henry_idle_animation(0.02)
	_check(game.henry_idle_beard_timer > 0.0 and game.henry_idle_beard_side in [0, 1], "seven-second beard gesture did not choose one side")
	_check(game._henry_idle_frame_index() >= game.HENRY_IDLE_POCKET_FRAME_COUNT, "beard gesture did not select its dedicated frame range")
	game.henry_idle_beard_timer = 0.0
	game.henry_idle_elapsed = 1.70
	_check(game._henry_idle_frame_index() == 2, "foot-tap idle did not reach its raised-foot frame")
	game.geovana_bark_controller.active_text = "NAO DEVE APARECER"
	game.geovana_bark_controller.active_timer = 2.0
	game.geovana_bark_controller.update(game, 0.01)
	_check(game.geovana_bark_controller.active_text == "" and not game.geovana_bark_controller.request(game, "ambient"), "Henry retained Geovana's dialogue box")

	game.player_hp_max = 400
	game.player_hp = 400
	game.player_defense = 0.0
	game.henry_incendiary_ability_controller.reset()
	game.qa_streaming_permission_pending = true
	game._damage_player(40, "test_blocked_hit", true)
	_check(is_equal_approx(game.henry_friction, 0.0), "blocked damage charged friction")
	game.qa_streaming_permission_pending = false
	game._damage_player(40, "test_real_hit", true)
	_check(is_equal_approx(game.henry_friction, 10.0), "actual damage did not charge friction proportionally")
	game.enemies.clear()
	var friction_target := _spawn_target(game.player_pos + Vector2(82.0, 0.0), 5000.0)
	var outside_friction := _spawn_target(game.player_pos + Vector2(game.HENRY_INCANDESCENCE_RADIUS + 40.0, 0.0), 5000.0)
	game.henry_incendiary_ability_controller.update(game.HENRY_FRICTION_RELEASE_INTERVAL + 0.01)
	_check(game.henry_incandescence_active_timer > 0.0 and game.henry_incandescence_zones.size() == 1, "friction did not release into one Incandescence zone")
	_check(is_equal_approx(game.henry_friction, 0.0), "released friction was not consumed")
	var target_hp_before := float(friction_target["hp"])
	var outside_hp_before := float(outside_friction["hp"])
	game.henry_incendiary_ability_controller.update(0.02)
	var early_burn_damage := target_hp_before - float(friction_target["hp"])
	var hp_before_late_tick := float(friction_target["hp"])
	game.henry_incendiary_ability_controller.update(1.25)
	var late_burn_damage := hp_before_late_tick - float(friction_target["hp"])
	_check(early_burn_damage > 0.0 and late_burn_damage > early_burn_damage, "Incandescence burn did not scale with continuous dwell time")
	_check(is_equal_approx(float(outside_friction["hp"]), outside_hp_before), "Incandescence damaged a target outside its radius")
	_check(float(friction_target.get("henry_incandescence_heat", 0.0)) > 0.0, "Incandescence did not expose target burn feedback")
	game.henry_incendiary_ability_controller.reset()
	game.henry_incendiary_ability_controller.on_player_damaged(1)
	game.henry_incendiary_ability_controller.update(game.HENRY_FRICTION_RELEASE_INTERVAL + 0.1)
	_check(game.henry_incandescence_zones.is_empty(), "sub-threshold friction released a noisy aura")

	for expected_stage in range(3):
		_check(game.henry_incendiary_ability_controller.fire_auto_attack(), "auto attack failed at combo stage %d" % expected_stage)
		var bullet: Dictionary = game.bullets[-1]
		_check(String(bullet.get("kind", "")) == "henry_spark", "auto attack did not create a spark")
		_check(int(bullet.get("henry_combo_stage", -1)) == expected_stage, "combo stage order changed")
	_check(game.henry_attack_combo == 0, "combo did not reset after 1-2-3")

	var reset_target := _spawn_target(game.player_pos + Vector2(80.0, 0.0))
	reset_target["henry_burn_time"] = 0.12
	for stack_index in range(7):
		game._damage_enemy(reset_target, 12.0, "henry_spark", false, false, game.player_pos, "basic_attack")
	_check(is_equal_approx(float(reset_target.get("henry_burn_time", 0.0)), game.HENRY_BURN_DURATION), "spark did not refresh the six-second burn window")
	_check(int(reset_target.get("henry_burn_stacks", 0)) == game.HENRY_BURN_STACK_MAX, "spark burn stacks did not cap at five")
	_check(float(reset_target.get("henry_burn_damage", 0.0)) >= 1.0, "burn damage was not derived from attack damage")
	var true_damage_expected: float = float(reset_target["max_hp"]) * game.HENRY_TRUE_DAMAGE_RATE_PER_STACK * game.HENRY_BURN_STACK_MAX
	var true_hp_before := float(reset_target["hp"])
	var true_damage_applied: float = game.henry_incendiary_ability_controller.consume_breach_enemy(reset_target)
	_check(is_equal_approx(true_damage_applied, true_damage_expected), "true damage was not based on target maximum life and five stacks")
	_check(is_equal_approx(true_hp_before - float(reset_target["hp"]), true_damage_expected), "true damage did not bypass the target mitigation path")
	_check(int(reset_target.get("henry_burn_stacks", 0)) == 0, "ability breach did not consume burn stacks")
	game.boss_active = true
	game.current_phase = 5
	game.boss_hp_max = 10000.0
	game.boss_hp = game.boss_hp_max
	game.boss_pos = game.player_pos + Vector2(150.0, 0.0)
	game.enemies_killed = 5000
	for stack_index in range(5):
		game.henry_incendiary_ability_controller.apply_burn_to_boss(10.0, 0, true)
	var boss_true_expected: float = game.boss_hp_max * game.HENRY_TRUE_DAMAGE_BOSS_RATE_PER_STACK * game.HENRY_BURN_STACK_MAX
	var boss_hp_before_true: float = game.boss_hp
	game.henry_incendiary_ability_controller.consume_breach_boss()
	_check(absf((boss_hp_before_true - game.boss_hp) - boss_true_expected) < 0.01, "true damage did not bypass high boss armor")
	game.boss_active = false
	game.current_phase = 1
	game.enemies_killed = 0

	game.enemies.clear()
	var near_target := _spawn_target(game.player_pos + Vector2(70.0, 0.0))
	var far_target := _spawn_target(game.player_pos + Vector2(320.0, 0.0))
	var outside_cone := _spawn_target(game.player_pos + Vector2(0.0, 180.0))
	var guard_target := _spawn_target(game.player_pos + Vector2(-90.0, 0.0), 2000.0)
	for stack_index in range(5):
		game._damage_enemy(near_target, 10.0, "henry_spark", false, false, game.player_pos, "basic_attack")
	near_target["henry_burn_tick"] = 99.0
	var near_hp := float(near_target["hp"])
	var far_hp := float(far_target["hp"])
	var outside_hp := float(outside_cone["hp"])
	var guard_hp := float(guard_target["hp"])
	var guard_pos := Vector2(guard_target["pos"])
	_check(game.henry_incendiary_ability_controller.begin_skill(game.player_pos + Vector2.RIGHT * 400.0), "cone cast did not begin")
	_check(game._local_player_controls_locked(), "basic skill did not lock movement and other actions")
	game.henry_incendiary_ability_controller.update(game.HENRY_SKILL_IMPACT_TIME - 0.01)
	_check(is_equal_approx(float(near_target["hp"]), near_hp), "cone dealt damage before its animation impact")
	game.henry_incendiary_ability_controller.update(0.02)
	var near_damage := near_hp - float(near_target["hp"])
	var far_damage := far_hp - float(far_target["hp"])
	_check(near_damage > far_damage and far_damage > 0.0, "cone did not scale damage from near to far")
	_check(is_equal_approx(float(outside_cone["hp"]), outside_hp), "cone damaged a target outside its angle")
	_check(int(near_target.get("henry_burn_stacks", 0)) == 0 and near_damage > game.player_damage * 2.0, "cone did not consume stacks into bonus true damage")
	_check(float(guard_target["hp"]) < guard_hp, "HAB1 defensive explosions did not damage a target behind Henry")
	_check(Vector2(guard_target.get("henry_knockback_velocity", Vector2.ZERO)).length() > 0.0, "HAB1 defensive explosions did not start progressive knockback")
	_check(Vector2(guard_target["pos"]).distance_to(guard_pos) < 10.0, "HAB1 knockback snapped its target instead of advancing by frame time")
	game.henry_incendiary_ability_controller.update(0.08)
	_check(Vector2(guard_target["pos"]).distance_to(guard_pos) > 2.0, "HAB1 knockback did not move naturally over time")
	game.henry_incendiary_ability_controller.update(game.HENRY_SKILL_CAST_DURATION)
	_check(not game.henry_skill_cast_active, "one-second cast did not finish")

	game.enemies.clear()
	var burning_target := _spawn_target(game.player_pos + Vector2(90.0, 0.0))
	var fresh_target := _spawn_target(game.player_pos + Vector2(-110.0, 0.0))
	var outside_wave := _spawn_target(game.player_pos + Vector2(game.HENRY_ULTIMATE_RADIUS + 25.0, 0.0))
	for stack_index in range(5):
		game._damage_enemy(burning_target, 10.0, "henry_spark", false, false, game.player_pos, "basic_attack")
	var burning_pos := Vector2(burning_target["pos"])
	var fresh_pos := Vector2(fresh_target["pos"])
	var fresh_hp := float(fresh_target["hp"])
	var outside_wave_hp := float(outside_wave["hp"])
	_check(game.henry_incendiary_ability_controller.cast_ultimate(), "heat wave did not cast")
	_check(game.henry_ultimate_cast_active, "three-pulse ultimate did not become active")
	_check(not game.henry_incendiary_ability_controller.cast_ultimate(), "duplicate ultimate input restarted the active charge")
	_check(game._local_player_controls_locked(), "Henry could move during the ultimate crouch")
	_check(game.henry_heat_waves.is_empty(), "heat wave appeared before the charge animation")
	game.henry_incendiary_ability_controller.update(game.HENRY_ULTIMATE_CAST_DURATION - 0.01)
	_check(is_equal_approx(float(fresh_target["hp"]), fresh_hp), "ultimate hit a fresh target during charge")
	_check(Vector2(burning_target["pos"]).is_equal_approx(burning_pos), "ultimate pushed a target during charge")
	_check(float(burning_target.get("henry_burn_overdrive", 0.0)) <= 0.0, "ultimate intensified burn before the release frame")
	game.henry_incendiary_ability_controller.update(0.02)
	_check(game.henry_ultimate_cast_active, "ultimate stopped before repeating all three animations")
	_check(game.henry_heat_waves.size() == 1, "heat wave was not created after the release frame")
	_check(Vector2(burning_target["pos"]).distance_to(burning_pos) < 10.0, "heat wave snapped a burning target instead of applying force")
	_check(Vector2(fresh_target["pos"]).distance_to(fresh_pos) < 10.0, "heat wave snapped a fresh target instead of applying force")
	_check(Vector2(burning_target.get("henry_knockback_velocity", Vector2.ZERO)).length() > 0.0, "heat wave did not apply progressive force")
	_check(int(burning_target.get("henry_burn_stacks", 0)) == 0, "first ultimate pulse did not consume five stacks")
	game.henry_incendiary_ability_controller.update(0.10)
	_check(Vector2(burning_target["pos"]).distance_to(burning_pos) > 4.0, "heat wave force did not advance naturally")
	_check(is_equal_approx(float(outside_wave["hp"]), outside_wave_hp), "heat wave exceeded its 280px radius")
	game.henry_incendiary_ability_controller.update(game.HENRY_ULTIMATE_CAST_DURATION * 2.0)
	_check(not game.henry_ultimate_cast_active, "ultimate did not finish after three 800ms animation cycles")
	_check(game.henry_ultimate_pulses_released == game.HENRY_ULTIMATE_PULSE_COUNT, "ultimate did not release exactly three explosions")
	game.enemies.clear()
	var remote_target := _spawn_target(game.player_pos + Vector2(96.0, 0.0))
	var remote_start := Vector2(remote_target["pos"])
	for stack_index in range(5):
		game._damage_enemy(remote_target, 10.0, "henry_spark", false, false, game.player_pos, "basic_attack", 22, "incendiario")
	_check(int(remote_target.get("henry_burn_source_peer", 0)) == 22 and int(remote_target.get("henry_burn_stacks", 0)) == 5, "authority lost remote Henry's burn stack owner")
	var remote_hp_before_wave := float(remote_target["hp"])
	game._damage_enemy(remote_target, 25.0, "henry_heat_wave", false, false, game.player_pos, "skill_e", 22, "incendiario")
	_check(int(remote_target.get("henry_burn_stacks", 0)) == 0 and remote_hp_before_wave - float(remote_target["hp"]) > 25.0, "authority did not consume remote Henry's stacks into true damage")
	_check(Vector2(remote_target.get("henry_knockback_velocity", Vector2.ZERO)).length() > 0.0, "authority did not create remote Henry's progressive push")
	game.henry_incendiary_ability_controller.update(0.1)
	_check(Vector2(remote_target["pos"]).distance_to(remote_start) > 4.0, "remote Henry heat wave force did not advance")

	game.enemies.clear()
	var spin_target := _spawn_target(game.player_pos + Vector2(400.0, 0.0), 4000.0)
	for stack_index in range(5):
		game._damage_enemy(spin_target, 10.0, "henry_spark", false, false, game.player_pos, "basic_attack")
	var spin_origin: Vector2 = game.player_pos
	var spin_hp_before := float(spin_target["hp"])
	game.last_dash_time = -99.0
	game._execute_teleport(game.player_pos + Vector2.RIGHT * 400.0)
	_check(game.henry_spin_active and game._local_player_controls_locked(), "Incendiario dash did not enter the protected spin")
	_check(game._local_player_movement_locked(), "Incendiario dash allowed movement before reaching its destination")
	_check(game.player_pos.is_equal_approx(spin_origin), "Incendiario dash teleported on the first frame")
	game.henry_incendiary_ability_controller.update(game.HENRY_SPIN_DASH_DURATION)
	var expected_spin_target: Vector2 = game._clamp_player_world(spin_origin + Vector2.RIGHT * 400.0)
	_check(game.player_pos.distance_to(expected_spin_target) < 0.1, "Incendiario spin did not travel to the teleport destination")
	_check(not game._local_player_movement_locked() and game._local_player_controls_locked(), "Incendiario spin did not release movement-only control at the destination")
	var spin_viewport := Vector2(1280.0, 720.0)
	var spin_move_touch: Vector2 = game._joy_center(spin_viewport) + Vector2(48.0, 0.0)
	_check(game.player_control_controller.try_start_move_touch(991, spin_move_touch, spin_viewport), "Incendiario spin did not accept mobile movement after reaching the destination")
	game.player_control_controller.stop_move_touch()
	var protected_hp: int = game.player_hp
	game._damage_player(999, "boss1_wave", true)
	game._rpc_apply_hostile_status("stun", 5.0)
	game._apply_temporal_rewind_result(game.player_pos + Vector2(300.0, 0.0), 1.0)
	_check(game.player_hp == protected_hp and game.player_stun_timer <= 0.0, "spin did not block boss damage or hostile status")
	_check(game.player_pos.distance_to(expected_spin_target) < 0.1, "Boss 1 rewind moved Henry during the spin")
	for spin_step in range(46):
		game.henry_incendiary_ability_controller.update(0.05)
	game.henry_incendiary_ability_controller.update(0.04)
	_check(not game.henry_spin_active, "spin did not finish after 2.45 seconds")
	_check(float(spin_target["hp"]) < spin_hp_before and int(spin_target.get("henry_burn_stacks", 0)) == 0, "spin final explosion did not consume stacks and damage the target")
	_check(Vector2(spin_target.get("henry_knockback_velocity", Vector2.ZERO)).length() > 0.0, "spin final explosion did not apply progressive knockback")

	var sheet := load("res://assets/sprites/player/player_2_suit/player_2_suit_sheet_v3.png") as Texture2D
	_check(sheet != null and sheet.get_width() == 1280 and sheet.get_height() == 5120, "Henry sprite sheet dimensions changed")
	var fire_sheet := load("res://assets/sprites/player/player_2_suit/henry_fire_sheet_v2.png") as Texture2D
	_check(fire_sheet != null and fire_sheet.get_width() == 1280 and fire_sheet.get_height() == 2048, "Henry dedicated firing atlas dimensions changed")
	var walk_sheet := load("res://assets/sprites/player/player_2_suit/henry_walk_sheet_v2.png") as Texture2D
	_check(walk_sheet != null and walk_sheet.get_width() == 1280 and walk_sheet.get_height() == 768, "Henry dedicated walking atlas dimensions changed")
	var basic_cast_sheet := load("res://assets/sprites/player/player_2_suit/henry_basic_cast_sheet_v2.png") as Texture2D
	_check(basic_cast_sheet != null and basic_cast_sheet.get_width() == 1280 and basic_cast_sheet.get_height() == 2048, "Henry corrected basic-skill atlas dimensions changed")
	var ultimate_sheet := load("res://assets/sprites/player/player_2_suit/henry_ultimate_sheet_v1.png") as Texture2D
	_check(ultimate_sheet != null and ultimate_sheet.get_width() == 2048 and ultimate_sheet.get_height() == 256, "Henry ultimate atlas dimensions changed")
	var spin_sheet := load("res://assets/sprites/player/player_2_suit/henry_incendiary_spin_sheet_v1.png") as Texture2D
	_check(spin_sheet != null and spin_sheet.get_width() == 2048 and spin_sheet.get_height() == 256, "Henry spin atlas is not eight normalized frames")
	var idle_image := (load("res://assets/sprites/player/player_2_suit/henry_idle_pocket_sheet_v1.png") as Texture2D).get_image()
	var beard_sheet := load("res://assets/sprites/player/player_2_suit/henry_idle_beard_sheet_v2.png") as Texture2D
	_check(beard_sheet != null and beard_sheet.get_width() == 512 and beard_sheet.get_height() == 256, "Henry corrected beard atlas dimensions changed")
	var shop_entry_sheet := load("res://assets/sprites/player/player_2_suit/henry_shop_entry_sheet_v1.png") as Texture2D
	_check(shop_entry_sheet != null and shop_entry_sheet.get_width() == 2048 and shop_entry_sheet.get_height() == 256, "Henry shop entrance atlas dimensions changed")
	var beard_image := beard_sheet.get_image()
	var shop_entry_image := shop_entry_sheet.get_image()
	var fire_image := fire_sheet.get_image()
	var walk_image := walk_sheet.get_image()
	var basic_cast_image := basic_cast_sheet.get_image()
	var ultimate_image := ultimate_sheet.get_image()
	for frame_idx in range(5):
		var idle_metrics := _henry_sprite_metrics(idle_image, 0, frame_idx)
		var fire_metrics := _henry_sprite_metrics(fire_image, 2, frame_idx)
		_check(absi(int(fire_metrics["height"]) - int(idle_metrics["height"])) <= 1, "front firing frame %d changed Henry's visible height" % frame_idx)
		# Imported PNG filtering may shift the warm-skin edge by a few pixels, but
		# the old mismatched firing head exceeded this guard by a wide margin.
		_check(absi(int(fire_metrics["head_width"]) - int(idle_metrics["head_width"])) <= 8, "front firing frame %d changed Henry's head width" % frame_idx)
		_check(absi(int(fire_metrics["head_height"]) - int(idle_metrics["head_height"])) <= 8, "front firing frame %d changed Henry's head height" % frame_idx)
		var fire_skin: Vector3 = fire_metrics["skin"]
		var idle_skin: Vector3 = idle_metrics["skin"]
		_check(fire_skin.distance_to(idle_skin) <= 0.06, "front firing frame %d changed Henry's skin palette" % frame_idx)
	var idle_reference := _henry_sprite_metrics(idle_image, 0, 0)
	for frame_idx in range(2):
		var beard_metrics := _henry_sprite_metrics(beard_image, 0, frame_idx)
		_check(int(beard_metrics["height"]) == int(idle_reference["height"]), "beard frame %d changed Henry's visible height" % frame_idx)
		_check(absi(int(beard_metrics["head_width"]) - int(idle_reference["head_width"])) <= 8, "beard frame %d changed Henry's head width" % frame_idx)
		_check(absi(int(beard_metrics["head_height"]) - int(idle_reference["head_height"])) <= 8, "beard frame %d changed Henry's head height" % frame_idx)
		var beard_skin: Vector3 = beard_metrics["skin"]
		var idle_skin: Vector3 = idle_reference["skin"]
		_check(beard_skin.distance_to(idle_skin) <= 0.06, "beard frame %d changed Henry's skin palette" % frame_idx)
	for frame_idx in range(game.HENRY_SHOP_ENTRY_FRAME_COUNT):
		var shop_metrics := _henry_sprite_metrics(shop_entry_image, 0, frame_idx)
		_check(int(shop_metrics["bottom"]) >= 245, "shop entrance frame %d lost the common ground anchor" % frame_idx)
		_check(int(shop_metrics["height"]) >= 195 and int(shop_metrics["height"]) <= 237, "shop entrance frame %d escaped its impact-to-idle scale envelope" % frame_idx)
		var shop_skin: Vector3 = shop_metrics["skin"]
		var idle_skin: Vector3 = idle_reference["skin"]
		_check(shop_skin.distance_to(idle_skin) <= 0.08, "shop entrance frame %d changed Henry's skin palette" % frame_idx)
	var shop_final_metrics := _henry_sprite_metrics(shop_entry_image, 0, game.HENRY_SHOP_ENTRY_FRAME_COUNT - 1)
	_check(absi(int(shop_final_metrics["head_width"]) - int(idle_reference["head_width"])) <= 10, "shop entrance final frame changed Henry's head width")
	_check(absi(int(shop_final_metrics["head_height"]) - int(idle_reference["head_height"])) <= 10, "shop entrance final frame changed Henry's head height")
	for direction_row in range(8):
		for frame_idx in range(5):
			var metrics := _henry_sprite_metrics(fire_image, direction_row, frame_idx)
			_check(int(metrics["height"]) >= 235 and int(metrics["height"]) <= 237, "direction %d frame %d changed Henry's anchored height" % [direction_row, frame_idx])
	for direction_row in range(3):
		for frame_idx in range(5):
			var walk_metrics := _henry_sprite_metrics(walk_image, direction_row, frame_idx)
			var idle_metrics := _henry_sprite_metrics(idle_image, 0, frame_idx)
			_check(int(walk_metrics["height"]) >= 234 and int(walk_metrics["height"]) <= 237, "walk direction %d frame %d changed Henry's anchored height" % [direction_row, frame_idx])
			var walk_skin: Vector3 = walk_metrics["skin"]
			var idle_skin: Vector3 = idle_metrics["skin"]
			_check(walk_skin.distance_to(idle_skin) <= 0.06, "walk direction %d frame %d changed Henry's skin palette" % [direction_row, frame_idx])
	for direction_row in range(8):
		for frame_idx in range(5):
			var cast_metrics := _henry_sprite_metrics(basic_cast_image, direction_row, frame_idx)
			var idle_metrics := _henry_sprite_metrics(idle_image, 0, frame_idx)
			var cast_skin: Vector3 = cast_metrics["skin"]
			var idle_skin: Vector3 = idle_metrics["skin"]
			_check(cast_skin.distance_to(idle_skin) <= 0.06, "basic skill direction %d frame %d changed Henry's skin palette" % [direction_row, frame_idx])
			_check(int(cast_metrics["height"]) >= 170 and int(cast_metrics["height"]) <= 214, "basic skill direction %d frame %d escaped its corrected crouch proportions" % [direction_row, frame_idx])
	for frame_idx in range(game.HENRY_ULTIMATE_FRAME_COUNT):
		var ultimate_metrics := _henry_sprite_metrics(ultimate_image, 0, frame_idx)
		_check(int(ultimate_metrics["height"]) >= 155 and int(ultimate_metrics["height"]) <= 248, "ultimate frame %d escaped its crouch-to-release scale envelope" % frame_idx)
	_check(Array(game.textures.get("henry_down", [])).size() == 5, "Henry down walk does not contain five frames")
	_check(Array(game.textures.get("henry_right", [])).size() == 5, "Henry right walk does not contain five frames")
	_check(Array(game.textures.get("henry_up", [])).size() == 5, "Henry up walk does not contain five frames")
	_check(game._net_player_texture_for_state(game.NET_ANIM_DOWN, 4, game.HENRY_SELECTION_INDEX, "incendiario") != null, "remote Henry down walk frame was not resolvable")
	_check(game._net_player_texture_for_state(game.NET_ANIM_RIGHT, 4, game.HENRY_SELECTION_INDEX, "incendiario") != null, "remote Henry side walk frame was not resolvable")
	_check(game._net_player_texture_for_state(game.NET_ANIM_UP, 4, game.HENRY_SELECTION_INDEX, "incendiario") != null, "remote Henry up walk frame was not resolvable")
	_check(Array(game.textures.get("henry_fire_network", [])).size() == 40, "8-direction firing atlas does not contain 40 frames")
	_check(Array(game.textures.get("henry_cast_network", [])).size() == 56, "basic, ultimate and spin cast atlas does not contain 56 frames")
	_check(Array(game.textures.get("henry_ultimate", [])).size() == game.HENRY_ULTIMATE_FRAME_COUNT, "ultimate does not contain eight 100ms frames")
	_check(Array(game.textures.get("henry_incendiary_spin", [])).size() == game.HENRY_SPIN_FRAME_COUNT, "spin does not contain eight authored orientations")
	for direction in ["east", "southeast", "south", "southwest", "west", "northwest", "north", "northeast"]:
		_check(Array(game.textures.get("henry_fire_" + direction, [])).size() == 5, "missing five firing frames for " + direction)
		_check(Array(game.textures.get("henry_cast_" + direction, [])).size() == 5, "missing five cast frames for " + direction)
	game._store_remote_player_state(22, {
		"pos": game.player_pos + Vector2(80.0, 0.0), "hp": 450, "hp_max": 450,
		"dead": false, "manifestation": game.HENRY_SELECTION_INDEX,
		"manifestation_key": "incendiario", "aura": game.HENRY_SELECTION_INDEX,
		"anim_state": game.NET_ANIM_LACERANTE, "frame_idx": 7, "flip_h": false,
	})
	_check(int(Dictionary(game.net_players_by_peer.get(22, {})).get("manifestation", -1)) == game.HENRY_SELECTION_INDEX, "remote Henry sentinel was clamped")
	_check(game._net_player_texture_for_state(game.NET_ANIM_FIRE, 39, game.HENRY_SELECTION_INDEX, "incendiario") != null, "remote Henry final directional firing frame was not resolvable")
	_check(game._net_player_texture_for_state(game.NET_ANIM_LACERANTE, 7, game.HENRY_SELECTION_INDEX, "incendiario") != null, "remote Henry cast frame was not resolvable")
	_check(game._net_player_texture_for_state(game.NET_ANIM_LACERANTE, 47, game.HENRY_SELECTION_INDEX, "incendiario") != null, "remote Henry final ultimate frame was not resolvable")
	_check(game._net_player_texture_for_state(game.NET_ANIM_LACERANTE, 55, game.HENRY_SELECTION_INDEX, "incendiario") != null, "remote Henry final spin frame was not resolvable")
	var visual_count_before: int = game.net_ability_visuals.size()
	game._rpc_ability_visual(22, 1, game.NET_ABILITY_SKILL, game.HENRY_SELECTION_INDEX, game.player_pos, game.player_pos + Vector2.RIGHT * 360.0, 1.0, 0.0, {
		"schema": 1, "event_id": "22:1", "manifestation_key": "incendiario", "seed": 2201,
	}, 40)
	_check(game.net_ability_visuals.size() == visual_count_before + 1, "remote Incendiario VFX event was not accepted")
	_check(int(Dictionary(game.net_ability_visuals[-1]).get("manifestation", -1)) == game.HENRY_SELECTION_INDEX, "remote Incendiario VFX lost its character identity")
	game._rpc_ability_visual(22, 1, game.NET_ABILITY_SKILL, game.HENRY_SELECTION_INDEX, game.player_pos, game.player_pos + Vector2.RIGHT * 360.0, 1.0, 0.0, {
		"schema": 1, "event_id": "22:1", "manifestation_key": "incendiario", "seed": 2201,
	}, 40)
	_check(game.net_ability_visuals.size() == visual_count_before + 1, "duplicate remote VFX event was applied twice")
	var ultimate_visual_before: int = game.net_ability_visuals.size()
	game._rpc_ability_visual(22, 2, game.NET_ABILITY_SECONDARY, game.HENRY_SELECTION_INDEX, game.player_pos, game.player_pos, game.HENRY_ULTIMATE_CAST_DURATION * game.HENRY_ULTIMATE_PULSE_COUNT + game.HENRY_ULTIMATE_WAVE_DURATION, game.HENRY_ULTIMATE_CAST_DURATION, {
		"schema": 1, "event_id": "22:2", "manifestation_key": "incendiario", "seed": 2202,
	}, 40)
	_check(game.net_ability_visuals.size() == ultimate_visual_before + 1, "remote ultimate charge/release VFX event was not accepted")
	var ultimate_visual: Dictionary = game.net_ability_visuals[-1]
	_check(is_equal_approx(float(ultimate_visual.get("extra", 0.0)), game.HENRY_ULTIMATE_CAST_DURATION), "remote ultimate lost its 800ms charge split")
	_check(is_equal_approx(float(ultimate_visual.get("max", 0.0)), game.HENRY_ULTIMATE_CAST_DURATION * game.HENRY_ULTIMATE_PULSE_COUNT + game.HENRY_ULTIMATE_WAVE_DURATION), "remote ultimate lost its three-pulse visual timeline")
	var passive_visual_before: int = game.net_ability_visuals.size()
	game._rpc_ability_visual(23, 1, game.NET_ABILITY_ATTACK, game.HENRY_SELECTION_INDEX, game.player_pos, game.player_pos, game.HENRY_INCANDESCENCE_DURATION, game.HENRY_INCANDESCENCE_NET_SENTINEL + 0.5, {
		"schema": 1, "event_id": "23:1", "manifestation_key": "incendiario", "seed": 2301,
	}, 35)
	_check(game.net_ability_visuals.size() == passive_visual_before + 1, "remote Incandescence release VFX was not accepted")
	game._rpc_ability_visual(23, 1, game.NET_ABILITY_ATTACK, game.HENRY_SELECTION_INDEX, game.player_pos, game.player_pos, game.HENRY_INCANDESCENCE_DURATION, game.HENRY_INCANDESCENCE_NET_SENTINEL + 0.5, {
		"schema": 1, "event_id": "23:1", "manifestation_key": "incendiario", "seed": 2301,
	}, 35)
	_check(game.net_ability_visuals.size() == passive_visual_before + 1, "duplicate remote Incandescence VFX was applied twice")
	var spin_visual_before: int = game.net_ability_visuals.size()
	game._rpc_ability_visual(22, 3, game.NET_ABILITY_TELEPORT, game.HENRY_SELECTION_INDEX, game.player_pos, game.player_pos + Vector2.RIGHT * 400.0, game.HENRY_SPIN_DURATION + game.HENRY_ULTIMATE_WAVE_DURATION, game.HENRY_SPIN_DURATION, {
		"schema": 1, "event_id": "22:3", "manifestation_key": "incendiario", "seed": 2203,
	}, 40)
	_check(game.net_ability_visuals.size() == spin_visual_before + 1, "remote Incendiario spin VFX event was not accepted")
	game._rpc_ability_visual(22, 3, game.NET_ABILITY_TELEPORT, game.HENRY_SELECTION_INDEX, game.player_pos, game.player_pos + Vector2.RIGHT * 400.0, game.HENRY_SPIN_DURATION + game.HENRY_ULTIMATE_WAVE_DURATION, game.HENRY_SPIN_DURATION, {
		"schema": 1, "event_id": "22:3", "manifestation_key": "incendiario", "seed": 2203,
	}, 40)
	_check(game.net_ability_visuals.size() == spin_visual_before + 1, "duplicate remote spin VFX event was applied twice")

	game.henry_friction = 37.5
	game.henry_friction_release_timer = 2.25
	game._capture_retry_run_snapshot()
	var saved_fields: Dictionary = game.retry_run_snapshot.get("fields", {})
	_check(String(saved_fields.get("active_character_key", "")) == game.CHARACTER_HENRY, "retry snapshot lost character identity")
	_check(String(saved_fields.get("mutation_key", "")) == "incendiario", "retry snapshot lost mutation")
	_check(is_equal_approx(float(saved_fields.get("henry_friction", 0.0)), 37.5), "retry snapshot lost Incandescence friction")
	game.active_character_key = game.CHARACTER_GEOVANA
	game.manifestation_key = "eletrica"
	game.is_dead = true
	game.player_hp = 0.0
	_check(game._use_run_retry(), "Henry retry snapshot did not restore")
	_check(game.active_character_key == game.CHARACTER_HENRY and game.manifestation_key == "incendiario", "retry restored the wrong character kit")
	_check(is_equal_approx(game.henry_friction, 37.5) and is_equal_approx(game.henry_friction_release_timer, 2.25), "retry did not restore Incandescence cadence")
	game._open_specter_upgrade("victory", true)
	_check(game.mode == "victory", "Henry was incorrectly routed into Geovana's Specter upgrade")

	print("HENRY_INCENDIARY_SMOKE_OK cheat=HENRYP intro=12_scaled idle=pocket_tap beard=7s_random_side dialogue=off friction=actual_damage aura=dwell_scaled combo=1-2-3 burn=5_stacks true=max_hp_armor_bypass hab1=guard_bursts_progressive_push ultimate=3_pulses spin=destination_2.45s_move_after_arrival_full_immunity multiplayer_identity=true vfx_idempotent=true retry=true")
	_cleanup(0)


func _cleanup(code: int) -> void:
	if game != null:
		game.mode = "menu"
		game.visible = false
		game._cleanup_runtime_resources()
		root.remove_child(game)
		game.free()
		game = null
	quit(code)
