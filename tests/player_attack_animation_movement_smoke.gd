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


func _run() -> void:
	var fire_frames: Array = game.textures.get("player_fire", [])
	var lacerante_frames: Array = game.textures.get("player_lacerar", [])
	var right_frames: Array = game.textures.get("player_right", [])
	_check(not fire_frames.is_empty(), "player_fire frames missing")
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
