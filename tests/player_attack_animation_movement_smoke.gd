extends SceneTree

var game: Node
var failed: bool = false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PLAYER_ATTACK_ANIMATION_MOVEMENT_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _set_moving_attack(manifestation: String) -> void:
	game.manifestation_key = manifestation
	game.time_alive = 20.0
	game.last_attack_time = game.time_alive
	game.last_damage_time = -10.0
	game.last_dash_time = -10.0
	game.player_freeze_visual_timer = 0.0
	game.lacerante_preparing = false
	game.move_touch_index = 0
	game.touch_move = Vector2.RIGHT


func _set_stationary_attack(manifestation: String) -> void:
	_set_moving_attack(manifestation)
	game.move_touch_index = -1
	game.touch_move = Vector2.ZERO


func _expect_fire_pose(direction: Vector2, expected_key: String, expected_flip: bool) -> void:
	_set_stationary_attack("eletrica")
	game._set_player_attack_visual_dir(direction)
	var info: Dictionary = game._player_fire_animation_info()
	var frames: Array = game.textures.get(expected_key, [])
	_check(String(info.get("key", "")) == expected_key, expected_key + " wrong direction")
	_check(bool(info.get("flip_h", false)) == expected_flip, expected_key + " wrong flip")
	_check(frames.size() == 2 and frames[0] != frames[1], expected_key + " needs two distinct frames")
	for frame in range(2):
		game.time_alive = game.last_attack_time + frame * game.PLAYER_FIRE_FRAME_SECONDS + 0.005
		var tex: Texture2D = game._player_texture()
		_check(tex == frames[frame], expected_key + " wrong frame")
		var snapshot: Vector2i = game._network_player_animation_snapshot(12345)
		_check(snapshot.x == game.NET_ANIM_FIRE, "missing fire snapshot")
		_check(game._net_player_texture_for_state(snapshot.x, snapshot.y) == tex, "remote direction/frame differs")
		game.net_player_anim_state = snapshot.x
		game.net_player_frame_idx = snapshot.y
		_check(game._net_player_texture() == tex, "legacy remote direction/frame differs")
		if expected_key != "player_fire":
			var image: Image = tex.get_image()
			_check(image.get_size() == Vector2i(256, 430), "direction canvas dimensions differ")
			_check(image.get_pixel(0, 0).a == 0.0, "background is opaque")
			_check(image.get_used_rect().end.y == 430, "feet are not anchored at canvas bottom")
			_check(bool(game._player_draw_profile().get("preserve_height", false)), "direction is stretched")
	game.time_alive = game.last_attack_time + 0.185
	_check(game.textures["player_idle"].has(game._player_texture()), "shot did not recover to idle")


func _run() -> void:
	var fire_frames: Array = game.textures.get("player_fire", [])
	var lacerante_frames: Array = game.textures.get("player_lacerar", [])
	var right_frames: Array = game.textures.get("player_right", [])
	_check(not fire_frames.is_empty(), "player_fire frames missing")
	_check(game.textures["player_fire_network"].size() == 14, "network direction table incomplete")
	_check(not lacerante_frames.is_empty(), "player_lacerar frames missing")
	_check(not right_frames.is_empty(), "player_right frames missing")

	_set_moving_attack("eletrica")
	var moving_fire_tex: Texture2D = game._player_texture()
	var moving_fire_snapshot: Vector2i = game._network_player_animation_snapshot(12345)
	_check(not fire_frames.has(moving_fire_tex), "moving eletrica used fire sprite")
	_check(right_frames.has(moving_fire_tex), "moving eletrica did not keep movement sprite")
	_check(moving_fire_snapshot.x == game.NET_ANIM_RIGHT, "moving eletrica network snapshot used attack anim")

	_set_stationary_attack("eletrica")
	var stationary_fire_tex: Texture2D = game._player_texture()
	var stationary_fire_snapshot: Vector2i = game._network_player_animation_snapshot(12345)
	_check(fire_frames.has(stationary_fire_tex), "stationary eletrica did not use fire sprite")
	_check(stationary_fire_snapshot.x == game.NET_ANIM_FIRE, "stationary eletrica network snapshot did not use fire anim")
	_expect_fire_pose(Vector2.RIGHT, "player_fire", false)
	_expect_fire_pose(Vector2.LEFT, "player_fire", true)
	_expect_fire_pose(Vector2.UP, "player_fire_north", false)
	_expect_fire_pose(Vector2.DOWN, "player_fire_south", false)
	_expect_fire_pose(Vector2(1, -1), "player_fire_northeast", false)
	_expect_fire_pose(Vector2(-1, -1), "player_fire_northwest", false)
	_expect_fire_pose(Vector2(1, 1), "player_fire_southeast", false)
	_expect_fire_pose(Vector2(-1, 1), "player_fire_southwest", false)
	_expect_fire_pose(Vector2(-0.24, -1), "player_fire_north", false)
	# Captured shot direction stays fixed when the aim moves after emission.
	_set_stationary_attack("eletrica")
	game._set_player_attack_visual_dir(Vector2.UP)
	game.last_facing = Vector2.DOWN
	_check(game._player_fire_animation_info()["key"] == "player_fire_north", "shot direction followed later aim")
	game.last_damage_time = game.time_alive
	_check(game.textures["player_damage"].has(game._player_texture()), "damage did not interrupt shot")
	game.player_freeze_visual_timer = 1.0
	_check(game.textures["player_frozen"].has(game._player_texture()), "freeze did not interrupt shot")


	_set_moving_attack("lacerante")
	var moving_lacerante_tex: Texture2D = game._player_texture()
	var moving_lacerante_snapshot: Vector2i = game._network_player_animation_snapshot(12345)
	_check(not lacerante_frames.has(moving_lacerante_tex), "moving lacerante used attack sprite")
	_check(right_frames.has(moving_lacerante_tex), "moving lacerante did not keep movement sprite")
	_check(moving_lacerante_snapshot.x == game.NET_ANIM_RIGHT, "moving lacerante network snapshot used attack anim")

	_set_stationary_attack("lacerante")
	var stationary_lacerante_tex: Texture2D = game._player_texture()
	var stationary_lacerante_snapshot: Vector2i = game._network_player_animation_snapshot(12345)
	_check(lacerante_frames.has(stationary_lacerante_tex), "stationary lacerante did not use attack sprite")
	_check(stationary_lacerante_snapshot.x == game.NET_ANIM_LACERANTE, "stationary lacerante network snapshot did not use attack anim")

	if not failed:
		print("PLAYER_ATTACK_ANIMATION_MOVEMENT_SMOKE_OK directions=8 frames=2 moving_keeps_walk=true recovery=true interrupts=true network=true")
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	quit(1 if failed else 0)
