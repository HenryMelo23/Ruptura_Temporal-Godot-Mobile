extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("PLAYER_ATTACK_ANIMATION_MOVEMENT_FAIL " + message)
	quit(1)


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


func _expect_fire_pose(direction: Vector2, expected_flip: bool, label: String) -> void:
	_set_stationary_attack("eletrica")
	game._set_player_attack_visual_dir(direction)
	var info: Dictionary = game._player_fire_animation_info()
	var frames: Array = game.textures.get("player_fire", [])
	var tex: Texture2D = game._player_texture()
	var profile: Dictionary = game._player_draw_profile()
	var draw_size: Vector2 = Vector2(profile.get("size", Vector2.ZERO))
	var rendered_size := draw_size
	if bool(profile.get("fit_aspect", false)) and tex != null:
		var tex_size: Vector2 = tex.get_size()
		var fit_scale: float = min(draw_size.x / tex_size.x, draw_size.y / tex_size.y)
		rendered_size = tex_size * fit_scale
	_check(String(info.get("key", "")) == "player_fire", label + " selected a non-basic fire pose key")
	_check(bool(info.get("flip_h", false)) == expected_flip, label + " selected wrong fire pose flip")
	_check(not frames.is_empty(), label + " fire pose frames missing")
	_check(frames.has(tex), label + " did not use expected fire pose texture")
	_check(rendered_size.y <= game.PLAYER_DRAW_STOP_SIZE.y, label + " fire pose rendered taller than stop frame")
	_check(not bool(profile.get("fit_aspect", false)), label + " basic fire pose should preserve legacy size")


func _run() -> void:
	var fire_frames: Array = game.textures.get("player_fire", [])
	var lacerante_frames: Array = game.textures.get("player_lacerar", [])
	var right_frames: Array = game.textures.get("player_right", [])
	_check(not fire_frames.is_empty(), "player_fire frames missing")
	_check(game.textures.get("player_fire_back_diag", []) == fire_frames, "legacy diagonal key stopped aliasing basic fire frames")
	_check(game.textures.get("player_fire_up", []) == fire_frames, "legacy up key stopped aliasing basic fire frames")
	_check(game.textures.get("player_fire_down", []) == fire_frames, "legacy down key stopped aliasing basic fire frames")
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
	_expect_fire_pose(Vector2.RIGHT, false, "east")
	_expect_fire_pose(Vector2.LEFT, true, "west")
	_expect_fire_pose(Vector2(0.0, -1.0), false, "north")
	_expect_fire_pose(Vector2(-0.24, -1.0), true, "northwest shallow")
	_expect_fire_pose(Vector2(0.72, -1.0), false, "northeast diagonal")
	_expect_fire_pose(Vector2(-0.72, -1.0), true, "northwest diagonal")
	_expect_fire_pose(Vector2(0.35, 1.0), false, "southeast")
	_expect_fire_pose(Vector2(-0.35, 1.0), true, "southwest")

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

	print("PLAYER_ATTACK_ANIMATION_MOVEMENT_SMOKE_OK moving_keeps_walk=true stationary_uses_attack=true")
	quit(0)
