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
	_check(Array(game.textures.get("henry_idle_pocket", [])).size() == game.HENRY_IDLE_POCKET_FRAME_COUNT, "Henry pocket/tap idle atlas is incomplete")
	_check(Array(game.textures.get("henry_idle", [])).size() == 13, "Henry network idle pool lost pocket or beard frames")
	for frame_idx in range(game.HENRY_ENTRY_FRAME_COUNT):
		var draw_height: float = game.EntitiesPresentation._henry_entry_draw_height(game, frame_idx)
		var intro_visible_height: float = float(game.HENRY_ENTRY_VISIBLE_HEIGHTS[frame_idx]) * draw_height / 256.0
		var idle_visible_height: float = game.HENRY_IDLE_VISIBLE_HEIGHT * game.HENRY_IDLE_DRAW_HEIGHT / 256.0
		_check(absf(intro_visible_height - idle_visible_height) < 0.01, "entrance frame %d changes Henry's visible height" % frame_idx)
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
	game._damage_enemy(reset_target, 12.0, "henry_spark", false, false, game.player_pos, "basic_attack")
	_check(is_equal_approx(float(reset_target.get("henry_burn_time", 0.0)), game.HENRY_BURN_DURATION), "spark did not reset burn to 1.5 seconds")
	_check(float(reset_target.get("henry_burn_damage", 0.0)) >= 1.0, "burn damage was not derived from attack damage")

	game.enemies.clear()
	var near_target := _spawn_target(game.player_pos + Vector2(70.0, 0.0))
	var far_target := _spawn_target(game.player_pos + Vector2(320.0, 0.0))
	var outside_cone := _spawn_target(game.player_pos + Vector2(0.0, 180.0))
	var near_hp := float(near_target["hp"])
	var far_hp := float(far_target["hp"])
	var outside_hp := float(outside_cone["hp"])
	_check(game.henry_incendiary_ability_controller.begin_skill(game.player_pos + Vector2.RIGHT * 400.0), "cone cast did not begin")
	_check(game._local_player_controls_locked(), "basic skill did not lock movement and other actions")
	game.henry_incendiary_ability_controller.update(game.HENRY_SKILL_IMPACT_TIME - 0.01)
	_check(is_equal_approx(float(near_target["hp"]), near_hp), "cone dealt damage before its animation impact")
	game.henry_incendiary_ability_controller.update(0.02)
	var near_damage := near_hp - float(near_target["hp"])
	var far_damage := far_hp - float(far_target["hp"])
	_check(near_damage > far_damage and far_damage > 0.0, "cone did not scale damage from near to far")
	_check(is_equal_approx(float(outside_cone["hp"]), outside_hp), "cone damaged a target outside its angle")
	_check(float(near_target.get("henry_burn_time", 0.0)) > 0.0, "cone did not apply burn")
	game.henry_incendiary_ability_controller.update(game.HENRY_SKILL_CAST_DURATION)
	_check(not game.henry_skill_cast_active, "one-second cast did not finish")

	game.enemies.clear()
	var burning_target := _spawn_target(game.player_pos + Vector2(90.0, 0.0))
	var fresh_target := _spawn_target(game.player_pos + Vector2(-110.0, 0.0))
	var outside_wave := _spawn_target(game.player_pos + Vector2(game.HENRY_ULTIMATE_RADIUS + 25.0, 0.0))
	game._damage_enemy(burning_target, 10.0, "henry_spark", false, false, game.player_pos, "basic_attack")
	var burning_pos := Vector2(burning_target["pos"])
	var fresh_pos := Vector2(fresh_target["pos"])
	var fresh_hp := float(fresh_target["hp"])
	var outside_wave_hp := float(outside_wave["hp"])
	_check(game.henry_incendiary_ability_controller.cast_ultimate(), "heat wave did not cast")
	_check(game.henry_ultimate_cast_active, "800ms ultimate charge did not become active")
	_check(not game.henry_incendiary_ability_controller.cast_ultimate(), "duplicate ultimate input restarted the active charge")
	_check(game._local_player_controls_locked(), "Henry could move during the ultimate crouch")
	_check(game.henry_heat_waves.is_empty(), "heat wave appeared before the charge animation")
	game.henry_incendiary_ability_controller.update(game.HENRY_ULTIMATE_CAST_DURATION - 0.01)
	_check(is_equal_approx(float(fresh_target["hp"]), fresh_hp), "ultimate hit a fresh target during charge")
	_check(Vector2(burning_target["pos"]).is_equal_approx(burning_pos), "ultimate pushed a target during charge")
	_check(float(burning_target.get("henry_burn_overdrive", 0.0)) <= 0.0, "ultimate intensified burn before the release frame")
	game.henry_incendiary_ability_controller.update(0.02)
	_check(not game.henry_ultimate_cast_active, "ultimate charge did not finish after 800ms")
	_check(game.henry_heat_waves.size() == 1, "heat wave was not created after the release frame")
	_check(Vector2(burning_target["pos"]).distance_to(burning_pos) > 40.0, "heat wave did not push a burning target")
	_check(Vector2(fresh_target["pos"]).distance_to(fresh_pos) > 40.0, "heat wave did not push a fresh target")
	_check(float(burning_target.get("henry_burn_overdrive", 0.0)) > game.HENRY_BURN_OVERDRIVE_DURATION - 0.1, "existing burn was not intensified for 3 seconds")
	_check(float(fresh_target.get("henry_burn_overdrive", 0.0)) <= 0.0, "fresh burn was incorrectly intensified")
	_check(is_equal_approx(float(outside_wave["hp"]), outside_wave_hp), "heat wave exceeded its 280px radius")
	game.enemies.clear()
	var remote_target := _spawn_target(game.player_pos + Vector2(96.0, 0.0))
	var remote_start := Vector2(remote_target["pos"])
	game._damage_enemy(remote_target, 25.0, "henry_heat_wave", false, false, game.player_pos, "skill_e", 22, "incendiario")
	_check(int(remote_target.get("henry_burn_source_peer", 0)) == 22, "authority lost the remote Henry owner")
	_check(Vector2(remote_target["pos"]).distance_to(remote_start) > 40.0, "remote Henry heat wave was validated without its push")

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
	var idle_image := (load("res://assets/sprites/player/player_2_suit/henry_idle_pocket_sheet_v1.png") as Texture2D).get_image()
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
	_check(Array(game.textures.get("henry_cast_network", [])).size() == 48, "basic and ultimate cast atlas does not contain 48 frames")
	_check(Array(game.textures.get("henry_ultimate", [])).size() == game.HENRY_ULTIMATE_FRAME_COUNT, "ultimate does not contain eight 100ms frames")
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
	game._rpc_ability_visual(22, 2, game.NET_ABILITY_SECONDARY, game.HENRY_SELECTION_INDEX, game.player_pos, game.player_pos, game.HENRY_ULTIMATE_CAST_DURATION + game.HENRY_ULTIMATE_WAVE_DURATION, game.HENRY_ULTIMATE_CAST_DURATION, {
		"schema": 1, "event_id": "22:2", "manifestation_key": "incendiario", "seed": 2202,
	}, 40)
	_check(game.net_ability_visuals.size() == ultimate_visual_before + 1, "remote ultimate charge/release VFX event was not accepted")
	var ultimate_visual: Dictionary = game.net_ability_visuals[-1]
	_check(is_equal_approx(float(ultimate_visual.get("extra", 0.0)), game.HENRY_ULTIMATE_CAST_DURATION), "remote ultimate lost its 800ms charge split")
	_check(is_equal_approx(float(ultimate_visual.get("max", 0.0)), game.HENRY_ULTIMATE_CAST_DURATION + game.HENRY_ULTIMATE_WAVE_DURATION), "remote ultimate lost its full visual timeline")
	var passive_visual_before: int = game.net_ability_visuals.size()
	game._rpc_ability_visual(23, 1, game.NET_ABILITY_ATTACK, game.HENRY_SELECTION_INDEX, game.player_pos, game.player_pos, game.HENRY_INCANDESCENCE_DURATION, game.HENRY_INCANDESCENCE_NET_SENTINEL + 0.5, {
		"schema": 1, "event_id": "23:1", "manifestation_key": "incendiario", "seed": 2301,
	}, 35)
	_check(game.net_ability_visuals.size() == passive_visual_before + 1, "remote Incandescence release VFX was not accepted")
	game._rpc_ability_visual(23, 1, game.NET_ABILITY_ATTACK, game.HENRY_SELECTION_INDEX, game.player_pos, game.player_pos, game.HENRY_INCANDESCENCE_DURATION, game.HENRY_INCANDESCENCE_NET_SENTINEL + 0.5, {
		"schema": 1, "event_id": "23:1", "manifestation_key": "incendiario", "seed": 2301,
	}, 35)
	_check(game.net_ability_visuals.size() == passive_visual_before + 1, "duplicate remote Incandescence VFX was applied twice")

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

	print("HENRY_INCENDIARY_SMOKE_OK cheat=HENRYP intro=12_scaled idle=pocket_tap beard=7s_random_side dialogue=off friction=actual_damage aura=dwell_scaled combo=1-2-3 burn=1.5 cone=near_far ultimate=280 multiplayer_identity=true vfx_idempotent=true retry=true")
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
