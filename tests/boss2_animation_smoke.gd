extends SceneTree

const Boss2AnimationPresentation = preload("res://scripts/presentation/boss2_animation_presentation.gd")
const AssetController = preload("res://scripts/systems/assets/runtime_asset_controller.gd")

const FRAME_COUNTS := {
	"boss2_anim_idle": 4,
	"boss2_anim_walk": 4,
	"boss2_anim_breath": 4,
	"boss2_anim_spin": 2,
	"boss2_anim_stomp": 2,
	"boss2_anim_prison": 2,
	"boss2_anim_shield": 2,
	"boss2_anim_blizzard": 2,
	"boss2_anim_flash": 2,
	"boss2_anim_hunt": 2,
	"boss2_anim_hit": 4,
	"boss2_anim_death": 8,
}

const STATE_TEXTURE_KEYS := {
	"boss2_idle": "boss2_anim_idle",
	"boss2_reposition": "boss2_anim_walk",
	"boss2_freezing_breath": "boss2_anim_breath",
	"boss2_spin_spit_up": "boss2_anim_spin",
	"boss2_glacial_stomp": "boss2_anim_stomp",
	"boss2_ice_prison": "boss2_anim_prison",
	"boss2_crystal_shield": "boss2_anim_shield",
	"boss2_double_blizzard": "boss2_anim_blizzard",
	"boss2_flash_freeze": "boss2_anim_flash",
	"boss2_hunt_mark": "boss2_anim_hunt",
}

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _prepare_boss() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.current_phase = 2
	game._prepare_phase_texture_assets(2)
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 6000.0
	game.boss_hp = game.boss_hp_max
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(300.0, 0.0)
	game._reset_boss2_state()


func _cleanup_game() -> void:
	game._cleanup_runtime_resources()
	if game.music_player != null:
		game.music_player.stop()
		game.music_player.stream = null
	if game.rain_audio_player != null:
		game.rain_audio_player.stop()
		game.rain_audio_player.stream = null
	for player in game.sfx_players:
		if player != null:
			player.stop()
			player.stream = null
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null


func _assert_safe_frame(key: String, frame: Texture2D) -> void:
	assert(frame != null, "%s contains a missing frame" % key)
	var image := frame.get_image()
	assert(image != null and image.get_size() == Vector2i(256, 320), "%s must keep the canonical 256x320 canvas" % key)
	for corner in [Vector2i(0, 0), Vector2i(255, 0), Vector2i(0, 319), Vector2i(255, 319)]:
		assert(image.get_pixelv(corner).a <= 0.01, "%s has an opaque background/corner" % key)
	var visible := image.get_used_rect()
	assert(visible.size.x > 0 and visible.size.y > 0, "%s is visually empty" % key)
	assert(visible.position.x >= 8 and visible.end.x <= 248, "%s has an aggressive horizontal crop: %s" % [key, visible])
	assert(visible.position.y >= 40 and visible.end.y <= 300, "%s lost its vertical safety margin: %s" % [key, visible])


func _run() -> void:
	_prepare_boss()
	for key_value in FRAME_COUNTS:
		var key := String(key_value)
		var frames: Array = game.textures.get(key, [])
		assert(frames.size() == int(FRAME_COUNTS[key]), "%s frame count changed" % key)
		for frame_value in frames:
			_assert_safe_frame(key, frame_value as Texture2D)
		var compact := AssetController._compact_boss2_animation_spec(key, frames)
		assert(compact.size() <= frames.size() and not compact.is_empty(), "%s has no LOW fallback" % key)

	for state_value in STATE_TEXTURE_KEYS:
		var state := String(state_value)
		var key := String(STATE_TEXTURE_KEYS[state])
		game.boss2_state = state
		game.boss2_anim_frame = 1
		assert(Boss2AnimationPresentation.active_texture(game) in game.textures[key], "%s does not resolve its authored animation" % state)

	game.boss2_state = game.BOSS2_STATE_IDLE
	Boss2AnimationPresentation.trigger_hit(game, game.boss_hp_max * 0.03)
	assert(game.boss2_hit_animation_timer > 0.0)
	assert(Boss2AnimationPresentation.active_texture(game) in game.textures["boss2_anim_hit"])
	Boss2AnimationPresentation.update(game, game.boss2_hit_animation_duration + 0.01)
	assert(game.boss2_hit_animation_timer == 0.0)

	Boss2AnimationPresentation.trigger_death(game, game.boss_pos)
	assert(Boss2AnimationPresentation.death_active(game))
	assert(game.boss2_death_animation_pos.is_equal_approx(game.boss_pos))

	var draw_scale := minf(Boss2AnimationPresentation.DRAW_SIZE.x / 256.0, Boss2AnimationPresentation.DRAW_SIZE.y / Boss2AnimationPresentation.FRAME_HEIGHT)
	var visible_foot := Boss2AnimationPresentation.DRAW_CENTER_Y_OFFSET - Boss2AnimationPresentation.DRAW_SIZE.y * 0.5 + 300.0 * draw_scale
	assert(absf(visible_foot - Boss2AnimationPresentation.LEGACY_FOOT_OFFSET) <= 0.5, "remaster changed the boss ground anchor")
	assert(Boss2AnimationPresentation.draw_size().is_equal_approx(Vector2(184.0, 220.0)))

	print("BOSS2_ANIMATION_SMOKE_OK states=10 hit=true death=true canvas=256x320 alpha=true margin=8 ground_anchor=true")
	_cleanup_game()
	await process_frame
	await process_frame
	quit(0)
