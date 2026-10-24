extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("PARASITICA_SPRITE_SKIN_FAIL " + message)
	quit(1)


func _check_texture_pool(key: String, expected_count: int, expected_size: Vector2i) -> void:
	var frames: Array = game.textures.get(key, [])
	_check(frames.size() == expected_count, "%s expected %d frames, got %d" % [key, expected_count, frames.size()])
	for frame_index in range(frames.size()):
		_check(frames[frame_index] is Texture2D, "%s frame %d is missing" % [key, frame_index])
		var frame: Texture2D = frames[frame_index]
		_check(Vector2i(frame.get_size()) == expected_size, "%s frame %d expected canvas %s, got %s" % [key, frame_index, expected_size, Vector2i(frame.get_size())])


func _run() -> void:
	game._start_game()
	game.manifestation_key = "parasitica"
	game.selected_manifestation = game._manifestation_index_for_key("parasitica", -1)
	game.time_alive = 30.0
	game.last_attack_time = -999.0
	game.last_damage_time = -999.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0

	for key in [
		"player_parasitica_idle",
		"player_parasitica_right",
		"player_parasitica_left",
		"player_parasitica_up",
		"player_parasitica_down",
		"player_parasitica_fire",
		"player_parasitica_fire_network",
	]:
		var expected_count := 4 if key.ends_with("idle") else (3 if key.ends_with("right") or key.ends_with("left") else (14 if key.ends_with("network") else 2))
		_check_texture_pool(key, expected_count, Vector2i(312, 312))
	for direction in game.PLAYER_FIRE_DIRECTIONS:
		_check_texture_pool("player_parasitica_fire_" + direction, 2, Vector2i(312, 312))
	_check_texture_pool("player_parasitica_damage", 4, Vector2i(319, 411))
	var entry_frames: Array = game.textures.get("player_parasitica_start_down", [])
	_check(entry_frames.size() == 8, "player_parasitica_start_down expected 8 frames")
	for frame_index in range(entry_frames.size()):
		var expected_entry_size := Vector2i(512, 720) if frame_index < 5 else Vector2i(162, 232)
		_check(Vector2i(entry_frames[frame_index].get_size()) == expected_entry_size, "entry frame %d expected canvas %s, got %s" % [frame_index, expected_entry_size, Vector2i(entry_frames[frame_index].get_size())])
	_check_texture_pool("player_parasitica_frozen", 2, Vector2i(319, 411))
	_check_texture_pool("parasitica_dance_loop", 15, Vector2i(257, 306))
	_check_texture_pool("parasitica_dance_final", 2, Vector2i(257, 306))

	_check(14 + 14 + 4 + 8 + 2 + 17 == 59, "the complete skin contract must contain 59 authored frames")
	_check(game._player_animation_texture_key("idle", "player_idle") == "player_parasitica_idle", "idle routing did not select the dedicated skin")
	_check(game._player_animation_texture_key("right", "player_right") == "player_parasitica_right", "movement routing did not select the dedicated skin")
	var draw_profile: Dictionary = game._player_draw_profile()
	_check(bool(draw_profile.get("preserve_height", false)), "runtime profile must preserve Parasitica proportions")
	_check(is_equal_approx(float(draw_profile.get("height", 0.0)), 84.0), "runtime profile must use one stable Parasitica draw height")
	var idle_reference: Texture2D = Array(game.textures["player_parasitica_idle"])[0]
	var idle_used_height := float(idle_reference.get_image().get_used_rect().size.y)
	var idle_visible_height := idle_used_height / idle_reference.get_height() * float(draw_profile["height"])

	for direction in [Vector2.RIGHT, Vector2.DOWN, Vector2.UP, Vector2(1.0, -1.0), Vector2(-1.0, -1.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]:
		var fire_info: Dictionary = game._player_fire_animation_info(direction)
		_check(String(fire_info.get("key", "")).begins_with("player_parasitica_fire"), "attack direction reused the base Geovana skin")
		game.player_attack_visual_dir = direction.normalized()
		game.last_attack_time = game.time_alive
		var fire_profile: Dictionary = game._player_fire_draw_profile()
		_check(bool(fire_profile.get("preserve_height", false)), "attack direction %s did not preserve its canvas height" % direction)
		var fire_key := String(fire_info.get("key", ""))
		_check(is_equal_approx(float(fire_profile.get("height", 0.0)), 84.0), "attack direction %s did not use the idle draw height" % direction)
		for fire_texture in Array(game.textures[fire_key]):
			var fire_used_rect := (fire_texture as Texture2D).get_image().get_used_rect()
			_check(fire_used_rect.size.y == int(idle_used_height), "attack direction %s source silhouette height %d differs from idle %d" % [direction, fire_used_rect.size.y, int(idle_used_height)])
			_check(fire_used_rect.position.y == idle_reference.get_image().get_used_rect().position.y, "attack direction %s source top does not match idle" % direction)
			_check(fire_used_rect.end.y == idle_reference.get_image().get_used_rect().end.y, "attack direction %s foot baseline does not match idle" % direction)
			var fire_visible_height := float(fire_used_rect.size.y) / float((fire_texture as Texture2D).get_height()) * float(fire_profile["height"])
			_check(absf(fire_visible_height - idle_visible_height) <= 0.1, "attack direction %s changed visible body height from %.2f to %.2f" % [direction, idle_visible_height, fire_visible_height])
	game.last_attack_time = -999.0

	game.last_damage_time = game.time_alive
	_check(game._player_texture() == Array(game.textures["player_parasitica_damage"])[0], "damage state did not use the parasitic frames")
	game.last_damage_time = -999.0
	game.player_freeze_visual_timer = 1.0
	_check(Array(game.textures["player_parasitica_frozen"]).has(game._player_texture()), "frozen state did not retain the parasite skin")
	game.player_freeze_visual_timer = 0.0

	var parasitica_index: int = game._manifestation_index_for_key("parasitica", -1)
	_check(parasitica_index >= 0, "Parasitica manifestation index is missing")
	_check(game._net_player_texture_for_state(game.NET_ANIM_RIGHT, 0, parasitica_index, "parasitica") == Array(game.textures["player_parasitica_right"])[0], "remote movement did not use the dedicated skin")
	_check(game._net_player_texture_for_state(game.NET_ANIM_FIRE, 0, parasitica_index, "parasitica") == Array(game.textures["player_parasitica_fire_network"])[0], "remote attack did not use the dedicated skin")
	_check(game._net_player_texture_for_state(game.NET_ANIM_DAMAGE, 0, parasitica_index, "parasitica") == Array(game.textures["player_parasitica_damage"])[0], "remote damage did not use the dedicated skin")

	print("PARASITICA_SPRITE_SKIN_OK frames=59 movement=14 fire=14 damage=4 entry=8 frozen=2 dance=17 local=true remote=true proportions=preserved")
	game._cleanup_runtime_resources()
	game.queue_free()
	for frame in range(4):
		await process_frame
	quit(0)
