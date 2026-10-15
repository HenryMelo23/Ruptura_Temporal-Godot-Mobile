extends SceneTree

const Boss3AnimationPresentation = preload("res://scripts/presentation/boss3_animation_presentation.gd")

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _prepare_boss() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.current_phase = 3
	game._prepare_phase_texture_assets(3)
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 9000.0
	game.boss_hp = 9000.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(360.0, 0.0)
	game.boss_attacks.clear()
	game._reset_phase3_state()


func _expect_state(expected: String) -> void:
	assert(Boss3AnimationPresentation.visual_state(game) == expected)
	assert(Boss3AnimationPresentation.active_texture(game) != null)


func _run() -> void:
	_prepare_boss()
	var expected_counts := {
		"idle": 6, "walk": 8, "entry": 8, "rat_spit": 6,
		"rat_tail": 6, "rat_rain": 6, "cheese_ritual": 8,
		"consume": 6, "faith": 7, "sector_ritual": 8,
		"miasma": 7, "hit": 3, "stun": 5, "death": 10
	}
	for animation_name in expected_counts:
		var frames: Array = game.textures.get("boss3_anim_" + animation_name, [])
		assert(frames.size() == int(expected_counts[animation_name]))
		assert(frames.all(func(frame): return frame != null))

	_expect_state("idle")
	game.boss3_is_moving = true
	_expect_state("walk")
	game.boss3_is_moving = false
	game.boss_entry_timer = game.BOSS3_ENTRY_TIME * 0.5
	_expect_state("entry")
	game.boss_entry_timer = 0.0
	game.boss3_stun_timer = 1.0
	_expect_state("stun")
	game.boss3_stun_timer = 0.0
	game.boss3_consume_uid = 77
	game.boss3_consume_timer = 0.5
	_expect_state("consume")
	game.boss3_consume_uid = -1
	game.boss3_consume_timer = 0.0
	game.boss3_ritual_timer = 1.0
	_expect_state("cheese_ritual")
	game.boss3_ritual_timer = 0.0
	game.boss_attacks = [{"kind": "boss3_sector_ritual", "age": 0.4, "duration": 3.0}]
	_expect_state("sector_ritual")
	game.boss_attacks.clear()
	game.boss3_miasma_variant = 2
	game.boss3_miasma_timer = 2.0
	_expect_state("miasma")
	game.boss3_miasma_variant = 0
	game.boss3_miasma_timer = 0.0
	game.boss3_faith_test_active = true
	_expect_state("faith")
	game.boss3_faith_test_active = false
	for attack_case in [
		["rat_tail", "rat_tail"],
		["rat_spit", "rat_spit"],
		["rat_rain", "rat_rain"]
	]:
		game.boss_attacks = [{"kind": attack_case[0], "age": 0.2, "duration": 0.65}]
		_expect_state(attack_case[1])
	game.boss_attacks.clear()

	# Optional action sets may be released on low-memory devices and must load
	# on first use without falling back to a missing sprite.
	game.textures.erase("boss3_anim_hit")
	var hp_before: float = game.boss_hp
	game._damage_boss(220.0, "boss3_animation_smoke", false, false)
	assert(game.boss_hp < hp_before)
	_expect_state("hit")
	assert(game.textures.get("boss3_anim_hit", []).size() == 3)
	var first_hit_timer: float = game.boss3_hit_animation_timer
	game._damage_boss(25.0, "veneno", false, false)
	assert(is_equal_approx(game.boss3_hit_animation_timer, first_hit_timer))

	game.boss3_hit_animation_timer = 0.0
	game.boss3_consume_uid = 99
	game.boss3_consume_timer = 0.3
	var packet: Dictionary = game._pack_net_boss_visuals()
	assert(int(packet.get("boss3_consume_uid", -1)) == 99)
	assert(is_equal_approx(float(packet.get("boss3_consume_timer", 0.0)), 0.3))
	game.boss3_consume_uid = -1
	game.boss3_consume_timer = 0.0
	game._apply_remote_boss_visual_snapshot(packet)
	assert(game.boss3_consume_uid == 99)
	assert(is_equal_approx(game.boss3_consume_timer, 0.3))

	game.boss3_consume_uid = -1
	game.boss3_consume_timer = 0.0
	game.boss_hp = 10.0
	game._damage_boss(999999.0, "boss3_animation_smoke", false, false)
	assert(game.boss_dead and not game.boss_active)
	assert(Boss3AnimationPresentation.death_active(game))
	assert(Boss3AnimationPresentation.visual_state(game) == "death")
	assert(game.boss3_death_animation_pos == game.boss_pos)

	print("BOSS3_ANIMATION_SMOKE_OK states=14 frames=94 active_map=res://assets/maps/calm/phase_3.png network_consume=true")
	if game.has_method("_cleanup_runtime_resources"):
		game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	await process_frame
	quit(0)
