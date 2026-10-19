extends SceneTree

const Lightning = preload("res://scripts/presentation/lightning_presentation.gd")
const Director = preload("res://scripts/vfx_director.gd")
var game: Node2D
var sample_time := 0.0
var failed := false
var extra_sources := false
var director := Director.new(false)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("run")


func draw_fixtures() -> void:
	var camera: Vector2 = game._camera(game.get_viewport_rect().size) + game._screen_shake_offset()
	# Render an actual peer sprite through the production renderer; this is not
	# a network session test. Keeping simulation off makes screenshots repeatable.
	game._draw_remote_player_state(camera, 2, game.net_players_by_peer[2])
	Lightning.begin_frame(game, camera)
	if not game.get_meta(Lightning.CONTEXT).ellipses.is_empty():
		failed = true
		push_error("LIGHTNING_LAZY_INDEX_FAIL")
	var p: Vector2 = game.player_pos - camera
	if extra_sources:
		game._draw_phase4_enemy_hazards(camera)
		director.draw_world_vfx(game, camera)
		Lightning.end_frame(game)
		game._draw_shop_opening_upgrade(game.get_viewport_rect().size)
		return
	# All paths are deliberately rendered AFTER sprites, including a remote peer.
	game._draw_tesla_bolt(p + Vector2(-310, 0), p + Vector2(280, 0), 913, 0.95, 4.0)
	game._draw_prismatica_colored_bolt(p + Vector2(-310, 65), p + Vector2(300, 65), 456, Color(0.96, 0.32, 0.76), 0.85, 3.0)
	game._draw_boss4_lightning_link(game.player_pos + Vector2(-290, -150), game.player_pos + Vector2(280, -150), camera, Color(1, 0.78, 0.2), 3.0)
	var strike := {"seed": 197, "radius": 82.0, "warning": 1.2}
	game.Boss1VFX.lightning(game, strike, p + Vector2(170, 65), game.time_alive, 1.28 + sample_time, game.gfx_low_resource)
	game.Boss1VFX.lightning(game, strike, p + Vector2(-220, 90), game.time_alive, 0.8 + sample_time, game.gfx_low_resource)
	if game.get_meta(Lightning.CONTEXT).ellipses.size() != 4:
		failed = true
		push_error("LIGHTNING_ACTOR_INDEX_FAIL")
	Lightning.end_frame(game)


func capture(path: String, size: Vector2i) -> Image:
	root.mode = Window.MODE_WINDOWED
	root.borderless = true
	root.min_size = Vector2i.ZERO
	root.content_scale_size = size
	root.size = size
	for i in range(4):
		await process_frame
	game.queue_redraw()
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	if image.get_size() != size or image.save_png(path) != OK:
		failed = true
		push_error("LIGHTNING_VISUAL_CAPTURE_FAIL " + path)
	return image


func run() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.set_physics_process(false)
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.current_phase = 1
	game.player_pos = Vector2(800, 450)
	game.is_dead = false
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_pos = game.player_pos + Vector2(-270, -100)
	game.boss_hp_max = 10000
	game.boss_hp = 10000
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(270, 0))
	game.boss_attacks.clear()
	game.effects.clear()
	game.show_fps_counter = false
	game.net_players_by_peer[2] = {"has_snapshot": true, "hp": 450.0, "hp_max": 450.0, "pos": game.player_pos + Vector2(170, 65), "render_pos": game.player_pos + Vector2(170, 65), "alive": true, "dead": false, "eliminated": false, "name": "QA", "manifestation": 0}
	game.draw.connect(draw_fixtures)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.codex/lightning_vfx"))
	for tier in [Lightning.ULTRA, Lightning.PERFORMANCE]:
		game.gfx_memory_saver = tier == Lightning.PERFORMANCE
		game.gfx_low_resource = tier == Lightning.PERFORMANCE
		game.gfx_particles = tier == Lightning.ULTRA
		game.mobile_adaptive_visual_budget = false
		if Lightning.quality(game) != tier:
			failed = true
			push_error("LIGHTNING_QUALITY_FAIL")
		var label := "ultra" if tier == Lightning.ULTRA else "performance"
		var size := Vector2i(1280, 720) if tier == Lightning.ULTRA else Vector2i(960, 540)
		sample_time = 0.0
		game.time_alive = 12.0
		var first := await capture("res://.codex/lightning_vfx/%s_a.png" % label, size)
		sample_time = 0.09
		game.time_alive += sample_time
		var second := await capture("res://.codex/lightning_vfx/%s_b.png" % label, size)
		if first.get_data() == second.get_data():
			failed = true
			push_error("LIGHTNING_VISUAL_STATIC_FAIL")
		# Production paths for the remaining vertical strikes and late shop overlay.
		extra_sources = true
		game.phase4_enemy_hazards = [{"kind": "boss4_ultimate_ray", "pos": game.player_pos + Vector2(-150, 130), "age": 1.4, "warning": 1.2, "life": 0.4, "max": 0.6}]
		game.shop_opening_timer = game.SHOP_OPENING_ANIM_TIME * 0.6
		director.sky_lightning_bolts.clear()
		director.request_sky_lightning_strike(game.player_pos + Vector2(230, 60))
		await capture("res://.codex/lightning_vfx/%s_shop_sky_boss4.png" % label, size)
		game.phase4_enemy_hazards.clear()
		extra_sources = false
	if not failed:
		print("LIGHTNING_VISUAL_OK ultra=1280x720 performance=960x540 temporal_frames=4 extra_source_frames=2 local_remote_boss_enemy_overlap=true lazy_index=true network_session=false")
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failed else 0)
