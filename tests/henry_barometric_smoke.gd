extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("HENRY_BAROMETRIC_SMOKE_FAIL " + message)
	_cleanup(1)


func _spawn_target(pos: Vector2, hp := 5000.0) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var enemy: Dictionary = game.enemies[-1]
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	enemy["stun"] = 999.0
	return enemy


func _rear_tie_blue_count(image: Image, row: int) -> int:
	var total := 0
	for y in range(row * 256, (row + 1) * 256):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a > 0.12 and color.b > 0.68 and color.b > color.r + 0.25 and color.b > color.g + 0.2:
				total += 1
	return total


func _cell_data(image: Image, index: int) -> PackedByteArray:
	return image.get_region(Rect2i(index * 256, 0, 256, 256)).get_data()


func _run() -> void:
	game.active_character_key = game.CHARACTER_HENRY
	game.selected_mutation = 1
	game.selected_effect = 1
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
	game.player_attack_visual_dir = Vector2.RIGHT
	game.player_damage = 100.0
	game.player_defense = 0.0
	game.enemies.clear()
	game.bullets.clear()
	game.enemy_bullets.clear()
	var owner = game.henry_barometric_ability_controller

	_check(game.mutation_key == "barometrico", "selected Mutation did not reach runtime")
	_check(game.effect_key == "nimbo", "selected Effect did not reach runtime")
	_check(owner.core == game, "ability owner was not bound")
	_check(String(game._selection_manifest_item(game.HENRY_SELECTION_INDEX).get("name", "")) == "Barométrico", "HUD/save selection still reports the first Mutation")
	_check(String(game._selection_aura_item(game.HENRY_SELECTION_INDEX).get("name", "")) == "Nimbo", "HUD/save selection still reports the first Effect")
	_check(game._manifestation_index_for_key("barometrico", 0) == game.HENRY_SELECTION_INDEX, "network key did not resolve to Henry")
	_check(game._known_manifestation_key("barometrico"), "Barometric key is rejected by the known-key contract")
	var saved_fields: Dictionary = game._build_interrupted_run_snapshot().get("fields", {})
	_check(int(saved_fields.get("selected_mutation", -1)) == 1 and String(saved_fields.get("mutation_key", "")) == "barometrico", "interrupted-run save lost the selected Mutation")
	_check(int(saved_fields.get("selected_effect", -1)) == 1 and String(saved_fields.get("effect_key", "")) == "nimbo", "interrupted-run save lost the selected Effect")

	var barometric_walk_sheet := load("res://assets/sprites/player/player_2_suit/henry_barometric_walk_sheet_v1.png") as Texture2D
	var barometric_attack_sheet := load("res://assets/sprites/player/player_2_suit/henry_barometric_attack_sheet_v1.png") as Texture2D
	var barometric_cast_sheet := load("res://assets/sprites/player/player_2_suit/henry_barometric_cast_sheet_v1.png") as Texture2D
	var old_barometric_ultimate_sheet := load("res://assets/sprites/player/player_2_suit/henry_barometric_ultimate_sheet_v1.png") as Texture2D
	var barometric_ultimate_sheet := load("res://assets/sprites/player/player_2_suit/henry_barometric_ultimate_sheet_v2.png") as Texture2D
	_check(barometric_walk_sheet != null and barometric_walk_sheet.get_size() == Vector2(1280, 768), "Barometric walk atlas dimensions changed")
	_check(barometric_attack_sheet != null and barometric_attack_sheet.get_size() == Vector2(1280, 2048), "Barometric attack atlas dimensions changed")
	_check(barometric_cast_sheet != null and barometric_cast_sheet.get_size() == Vector2(1280, 2048), "Barometric HAB1 atlas dimensions changed")
	_check(barometric_ultimate_sheet != null and barometric_ultimate_sheet.get_size() == Vector2(2048, 256), "Barometric ultimate atlas dimensions changed")
	var new_ultimate_image := barometric_ultimate_sheet.get_image()
	var old_ultimate_image := old_barometric_ultimate_sheet.get_image()
	for new_index in range(8):
		for old_index in range(8):
			_check(_cell_data(new_ultimate_image, new_index) != _cell_data(old_ultimate_image, old_index), "Barometric ultimate frame %d reused an old pose" % new_index)
		for other_new_index in range(new_index):
			_check(_cell_data(new_ultimate_image, new_index) != _cell_data(new_ultimate_image, other_new_index), "Barometric ultimate contains duplicate new poses")
	_check(Array(game.textures.get("henry_barometric_down", [])).size() == 5 and Array(game.textures.get("henry_barometric_right", [])).size() == 5 and Array(game.textures.get("henry_barometric_up", [])).size() == 5, "Barometric movement atlas is incomplete")
	_check(Array(game.textures.get("henry_barometric_fire_network", [])).size() == 40, "Barometric attack network atlas is incomplete")
	_check(Array(game.textures.get("henry_barometric_cast_network", [])).size() == 48, "Barometric HAB1/ultimate network atlas is incomplete")
	_check(Array(game.textures.get("henry_intro", [])).size() == game.HENRY_ENTRY_FRAME_COUNT and not game.textures.has("henry_barometric_intro"), "Barometric mutation replaced Henry's approved entrance")
	_check(_rear_tie_blue_count(barometric_walk_sheet.get_image(), 2) == 0, "pure back Barometric walk invented a rear tie")
	_check(_rear_tie_blue_count(barometric_attack_sheet.get_image(), 6) == 0, "pure back Barometric attack invented a rear tie")
	_check(_rear_tie_blue_count(barometric_cast_sheet.get_image(), 6) == 0, "pure back Barometric HAB1 invented a rear tie")
	var remote_attack := game._net_player_texture_for_state(game.NET_ANIM_FIRE, 4, game.HENRY_SELECTION_INDEX, "barometrico") as AtlasTexture
	var remote_ultimate := game._net_player_texture_for_state(game.NET_ANIM_LACERANTE, 47, game.HENRY_SELECTION_INDEX, "barometrico") as AtlasTexture
	_check(remote_attack != null and "henry_barometric_attack_sheet_v1" in remote_attack.atlas.resource_path, "remote Barometric attack reused the Incendiary atlas")
	_check(remote_ultimate != null and "henry_barometric_ultimate_sheet_v2" in remote_ultimate.atlas.resource_path, "remote Barometric ultimate did not use the new atlas")
	game.henry_ultimate_cast_elapsed = owner.STORM_WINDUP * 0.99
	_check(game._henry_ultimate_frame() == 7, "Barometric windup did not play all eight new ultimate frames")
	game.henry_ultimate_cast_elapsed = 0.0

	var target_a := _spawn_target(game.player_pos + Vector2(190.0, 0.0))
	var target_b := _spawn_target(game.player_pos + Vector2(250.0, 90.0))
	for expected_stage in range(3):
		_check(owner.fire_auto_attack(), "pressure auto failed at stage %d" % expected_stage)
		owner.on_henry_auto_fired()
		var blade: Dictionary = game.bullets[-1] if expected_stage < 2 else game.bullets[game.bullets.size() - 2]
		_check(String(blade.get("kind", "")) == "henry_pressure", "auto did not create a pressure blade")
		_check(int(blade.get("henry_combo_stage", -1)) == expected_stage, "pressure combo order changed")
		if expected_stage == 2:
			_check(bool(blade.get("barometric_third", false)) and float(blade.get("visual_scale", 1.0)) > 1.3, "third pressure blade is not wider")
	_check(game.bullets.size() == 4, "Nimbo did not add exactly one copy on the third auto")
	var nimbo_bullet: Dictionary = game.bullets[-1]
	_check(String(nimbo_bullet.get("kind", "")) == "henry_nimbo_pressure" and bool(nimbo_bullet.get("nimbo_shot", false)), "Nimbo copy has the wrong projectile contract")
	_check(Vector2(nimbo_bullet.get("origin", game.player_pos)).distance_to(game.player_pos) > 30.0, "Nimbo fired from Henry instead of the cloud")

	var curving: Dictionary = game.bullets[0]
	owner.on_projectile_hit(curving, Vector2(target_a["pos"]), str(target_a["uid"]))
	_check(int(curving.get("barometric_hits", 0)) == 1 and curving.has("barometric_curve_target"), "first hit did not select a curve target")
	_check(Vector2(curving["barometric_curve_target"]).distance_to(Vector2(target_b["pos"])) < 1.0, "pressure blade curved to the wrong target")
	owner.on_projectile_hit(curving, Vector2(target_b["pos"]), str(target_b["uid"]))
	_check(float(curving.get("life", 1.0)) <= 0.0, "pressure blade exceeded its two-hit limit")

	game.bullets.clear()
	game.enemy_bullets = [{"pos": game.player_pos + Vector2(160.0, 60.0), "dir": Vector2.LEFT, "life": 3.0, "phase": 0.0, "radius": 8.0, "damage": 5.0, "type": "test", "speed_mult": 1.0}]
	game.enemies.clear()
	var corridor_target := _spawn_target(game.player_pos + Vector2(170.0, 72.0))
	var outside_target := _spawn_target(game.player_pos + Vector2(170.0, 132.0))
	var corridor_start := Vector2(corridor_target["pos"])
	var corridor_hp := float(corridor_target["hp"])
	var outside_hp := float(outside_target["hp"])
	_check(owner.fire_auto_attack(), "could not prepare a corridor projectile")
	var speed_before := float(game.bullets[-1]["speed"])
	_check(owner.begin_skill(game.player_pos + Vector2.RIGHT * 500.0), "corridor did not begin")
	_check(game._local_player_controls_locked(), "corridor windup did not use Henry's cast pose/lock")
	owner.update(owner.CORRIDOR_WINDUP + 0.02)
	_check(not game.henry_skill_cast_active and not game._local_player_controls_locked(), "corridor kept Henry locked after the short windup")
	_check(float(corridor_target["hp"]) < corridor_hp and Vector2(corridor_target["pos"]).distance_to(corridor_start) > 1.0, "corridor did not damage and displace its target")
	_check(is_equal_approx(float(outside_target["hp"]), outside_hp), "corridor damaged a target outside its width")
	_check(float(game.bullets[-1]["speed"]) > speed_before, "corridor did not accelerate Henry's pressure blade")
	_check(Vector2(game.enemy_bullets[0]["dir"]).distance_to(Vector2.LEFT) > 0.1, "corridor did not divert an enemy projectile")
	owner.update(owner.CORRIDOR_DURATION)
	_check(not owner.corridor_active, "corridor exceeded its duration")

	game.enemies.clear()
	var storm_target := _spawn_target(game.player_pos + Vector2(190.0, 0.0))
	var storm_start := Vector2(storm_target["pos"])
	var storm_hp := float(storm_target["hp"])
	game.boss_active = true
	game.boss_hp = 5000.0
	game.boss_hp_max = 5000.0
	game.boss_pos = game.player_pos + Vector2(220.0, 0.0)
	var boss_pos_before: Vector2 = game.boss_pos
	var boss_hp_before: float = game.boss_hp
	_check(owner.cast_ultimate(), "Eye of the Storm did not begin")
	_check(game.henry_ultimate_cast_active and game._local_player_controls_locked(), "ultimate windup did not use Henry's ultimate pose")
	owner.update(owner.STORM_WINDUP + 0.02)
	_check(owner.storm_active and not game.henry_ultimate_cast_active, "storm did not release after its windup")
	_check(not game._local_player_controls_locked(), "mobile storm incorrectly kept Henry locked")
	owner.update(owner.STORM_TICK + 0.02)
	_check(float(storm_target["hp"]) < storm_hp and Vector2(storm_target["pos"]).distance_to(storm_start) > 1.0, "storm did not cut and orbit a regular enemy")
	_check(game.boss_hp < boss_hp_before and game.boss_pos.is_equal_approx(boss_pos_before), "boss storm rule must damage without displacement")
	game.boss_active = false
	owner.update(owner.STORM_DURATION)
	_check(not owner.storm_active, "Eye of the Storm exceeded its duration")

	# Mutation and Effect are independent axes, not a hard-coded pair.
	game.mutation_key = "barometrico"
	game.effect_key = "incandescencia"
	game.player_hp_max = 400.0
	game.henry_incendiary_ability_controller.on_player_damaged(40)
	_check(is_equal_approx(game.henry_friction, 10.0), "Incandescence stopped working with Barometric")
	game.henry_incendiary_ability_controller.reset()
	owner.reset()
	game.mutation_key = "incendiario"
	game.effect_key = "nimbo"
	game.bullets.clear()
	for index in range(3):
		_check(game.henry_incendiary_ability_controller.fire_auto_attack(), "Incendiary auto failed in cross-combination")
		owner.on_henry_auto_fired()
	_check(game.bullets.any(func(b): return String(b.get("kind", "")) == "henry_nimbo_pressure"), "Nimbo stopped working with Incendiary")
	game.henry_incendiary_ability_controller.on_player_damaged(40)
	_check(is_equal_approx(game.henry_friction, 0.0), "Incandescence charged while Nimbo was selected")

	game.mutation_key = "barometrico"
	game.effect_key = "nimbo"
	owner.reset()
	_check(owner.begin_skill(game.player_pos + Vector2.RIGHT * 500.0), "could not build network skill state")
	var payload: Dictionary = game._network_ability_payload(game.NET_ABILITY_SKILL, game.player_pos, game.player_pos + Vector2.RIGHT * 390.0)
	_check(String(payload.get("manifestation_key", "")) == "barometrico", "network payload lost the stable Mutation key")
	var canonical: Dictionary = payload.get("canonical_state", {})
	_check(canonical.get("barometric", null) is Dictionary and bool(Dictionary(canonical["barometric"]).get("corridor_active", false)), "network payload lost live corridor presentation state")
	game.net_ability_visuals.clear()
	game._rpc_ability_visual(22, 1, game.NET_ABILITY_SKILL, game.HENRY_SELECTION_INDEX, game.player_pos, game.player_pos + Vector2.RIGHT * 390.0, owner.CORRIDOR_DURATION, 0.0, payload, 0)
	_check(game.net_ability_visuals.size() == 1, "remote Barometric visual event was rejected")
	_check(int(game.net_ability_visuals[0].get("manifestation", -1)) == game.HENRY_SELECTION_INDEX and String(game.net_ability_visuals[0].get("manifestation_key", "")) == "barometrico", "remote Barometric event lost Henry identity")

	print("HENRY_BAROMETRIC_SMOKE_OK mutation=barometrico effect=nimbo combo=3 curve_hits=2 corridor=mobile_pull_push_deflect storm=mobile_orbit_boss_safe authored_sprites=walk_attack_hab1_ultimate_v2 ultimate_frames=8 rear_tie=false entrance_reused=true cross_combinations=true save_selection=true network_snapshot=true remote_identity=true")
	_cleanup(0)


func _cleanup(code: int) -> void:
	if game != null and is_instance_valid(game):
		game._cleanup_runtime_resources()
		game.queue_free()
	quit(code)
