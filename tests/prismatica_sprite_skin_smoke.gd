extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("PRISMATICA_SPRITE_SKIN_FAIL " + message)
	quit(1)


func _check_texture_pool(key: String, expected_count: int) -> void:
	var frames: Array = game.textures.get(key, [])
	_check(frames.size() == expected_count, "%s expected %d frames, got %d" % [key, expected_count, frames.size()])
	for frame_index in range(frames.size()):
		_check(frames[frame_index] is Texture2D, "%s frame %d is missing" % [key, frame_index])


func _check_texture_pool_size(key: String, expected_size: Vector2i) -> void:
	var frames: Array = game.textures.get(key, [])
	for frame_index in range(frames.size()):
		var frame: Texture2D = frames[frame_index]
		_check(Vector2i(frame.get_size()) == expected_size, "%s frame %d expected canvas %s, got %s" % [key, frame_index, expected_size, Vector2i(frame.get_size())])


func _run() -> void:
	game._start_game()
	game.manifestation_key = "prismatica"
	game.selected_manifestation = game._manifestation_index_for_key("prismatica", -1)
	game.time_alive = 30.0
	game.last_attack_time = -999.0
	game.last_damage_time = -999.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0

	var expected_counts := {
		"player_prismatica_idle": 4,
		"player_prismatica_right": 3,
		"player_prismatica_left": 3,
		"player_prismatica_up": 2,
		"player_prismatica_down": 2,
		"player_prismatica_fire": 2,
		"player_prismatica_fire_network": 14,
		"player_prismatica_damage": 4,
		"player_prismatica_start_down": 6,
		"player_prismatica_frozen": 2,
		"prismatica_dance_loop": 15,
		"prismatica_dance_final": 2,
	}
	for key in expected_counts:
		_check_texture_pool(key, int(expected_counts[key]))
	for direction in game.PLAYER_FIRE_DIRECTIONS:
		_check_texture_pool("player_prismatica_fire_" + direction, 2)

	for key in [
		"player_prismatica_idle",
		"player_prismatica_right",
		"player_prismatica_left",
		"player_prismatica_up",
		"player_prismatica_down",
		"player_prismatica_fire",
		"player_prismatica_fire_network",
	]:
		_check_texture_pool_size(key, Vector2i(312, 312))
	for direction in game.PLAYER_FIRE_DIRECTIONS:
		_check_texture_pool_size("player_prismatica_fire_" + direction, Vector2i(312, 312))
	for key in ["player_prismatica_damage", "player_prismatica_start_down", "player_prismatica_frozen"]:
		_check_texture_pool_size(key, Vector2i(312, 412))
	for key in ["prismatica_dance_loop", "prismatica_dance_final"]:
		_check_texture_pool_size(key, Vector2i(250, 300))

	var authored_frame_total := 14 + 14 + 4 + 6 + 2 + 17
	_check(authored_frame_total == 57, "the complete skin contract must contain 57 authored frames")
	_check(game._player_animation_texture_key("idle", "player_idle") == "player_prismatica_idle", "idle routing did not select the dedicated skin")
	_check(game._player_animation_texture_key("right", "player_right") == "player_prismatica_right", "movement routing did not select the dedicated skin")
	var draw_profile: Dictionary = game._player_draw_profile()
	_check(bool(draw_profile.get("preserve_height", false)), "runtime profile must preserve the Prismatica frame proportions")
	_check(is_equal_approx(float(draw_profile.get("height", 0.0)), 84.0), "runtime profile must use one stable Prismatica draw height")

	var directions := [Vector2.RIGHT, Vector2.DOWN, Vector2.UP, Vector2(1.0, -1.0), Vector2(-1.0, -1.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]
	for direction in directions:
		var fire_info: Dictionary = game._player_fire_animation_info(direction)
		_check(String(fire_info.get("key", "")).begins_with("player_prismatica_fire"), "attack direction reused the electric skin")

	game.last_damage_time = game.time_alive
	_check(game._player_texture() == Array(game.textures["player_prismatica_damage"])[0], "damage state did not use the Prismatica damage frames")
	game.last_damage_time = -999.0
	game.player_freeze_visual_timer = 1.0
	_check(Array(game.textures["player_prismatica_frozen"]).has(game._player_texture()), "frozen state did not use the faceted Prismatica capsule")
	game.player_freeze_visual_timer = 0.0

	var prismatica_index: int = game._manifestation_index_for_key("prismatica", -1)
	_check(prismatica_index >= 0, "Prismatica manifestation index is missing")
	_check(game._net_player_texture_for_state(game.NET_ANIM_RIGHT, 0, prismatica_index, "prismatica") == Array(game.textures["player_prismatica_right"])[0], "remote movement did not use the dedicated skin")
	_check(game._net_player_texture_for_state(game.NET_ANIM_FIRE, 0, prismatica_index, "prismatica") == Array(game.textures["player_prismatica_fire_network"])[0], "remote attack did not use the dedicated skin")
	_check(game._net_player_texture_for_state(game.NET_ANIM_DAMAGE, 0, prismatica_index, "prismatica") == Array(game.textures["player_prismatica_damage"])[0], "remote damage did not use the dedicated skin")

	print("PRISMATICA_SPRITE_SKIN_OK frames=57 movement=14 fire=14 damage=4 entry=6 frozen=2 dance=17 local=true remote=true proportions=preserved")
	game._cleanup_runtime_resources()
	game.queue_free()
	for frame in range(4):
		await process_frame
	quit(0)
