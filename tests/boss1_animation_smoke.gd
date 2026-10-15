extends SceneTree

const Boss1AnimationPresentation = preload("res://scripts/presentation/boss1_animation_presentation.gd")

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _prepare_boss() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.current_phase = 1
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 6000.0
	game.boss_hp = 6000.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(380.0, 0.0)
	game.boss_stage_timer = 0.0
	game.boss1_hit_animation_timer = 0.0
	game.boss1_death_animation_timer = 0.0


func _run() -> void:
	_prepare_boss()
	assert(game.textures.get("boss1_hit", []).size() == 5)
	assert(game.textures.get("boss1_jump", []).size() == 5)
	assert(game.textures.get("boss1_death", []).size() == 6)
	game.time_alive = 0.0
	var idle_size_a: Vector2 = game._boss_draw_size()
	game.time_alive = PI / 6.4
	var idle_size_b: Vector2 = game._boss_draw_size()
	assert(not idle_size_a.is_equal_approx(idle_size_b))

	var hp_before: float = game.boss_hp
	game._damage_boss(180.0, "boss1_animation_smoke", false, false)
	assert(game.boss_hp < hp_before)
	assert(game.boss1_hit_animation_timer > 0.0)
	assert(Boss1AnimationPresentation.active_texture(game) != null)
	var first_hit_duration: float = game.boss1_hit_animation_duration
	game._damage_boss(180.0, "boss1_animation_smoke", false, false)
	assert(game.boss1_hit_animation_timer <= game.boss1_hit_animation_duration)
	assert(game.boss1_hit_animation_duration >= first_hit_duration)

	game.boss1_hit_animation_timer = 0.0
	game.boss_stage_duration = game.BOSS_STAGE_JUMP_TIME
	game.boss_stage_timer = game.boss_stage_duration - game.BOSS_STAGE_SLAM_TIME * 0.55
	var jump_frames: Array = game.textures["boss1_jump"]
	assert(Boss1AnimationPresentation.active_texture(game) == jump_frames[2])
	game.boss_stage_timer = game.boss_stage_duration - game.BOSS_STAGE_SLAM_TIME - 0.1
	assert(Boss1AnimationPresentation.active_texture(game) == jump_frames[4])
	game.boss_stage_timer = game.boss_stage_duration - game.BOSS_STAGE_SLAM_TIME - 0.5
	assert(Boss1AnimationPresentation.active_texture(game) == null)

	game.boss_stage_timer = 0.0
	game.boss_hp = 10.0
	game._damage_boss(999999.0, "boss1_animation_smoke", false, false)
	assert(game.boss_dead)
	assert(not game.boss_active)
	assert(game.boss1_death_animation_timer > 0.0)
	assert(Boss1AnimationPresentation.death_active(game))
	assert(game.boss1_death_animation_pos == game.boss_pos)
	game.boss1_death_animation_timer = 0.0
	assert(not Boss1AnimationPresentation.death_active(game))

	print("BOSS1_ANIMATION_SMOKE_OK hit_frames=5 jump_frames=5 death_frames=6 death_persists_after_inactive=true")
	if game.has_method("_cleanup_runtime_resources"):
		game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	await process_frame
	quit(0)
