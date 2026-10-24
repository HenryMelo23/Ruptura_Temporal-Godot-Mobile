extends SceneTree

const Quimera = preload("res://scripts/presentation/henry_quimera_presentation.gd")

var failed := false


class MockGame extends Node2D:
	const CHARACTER_HENRY := "henry"
	const NET_ANIM_IDLE := 0
	const NET_ANIM_UP := 1
	const NET_ANIM_DOWN := 2
	const NET_ANIM_RIGHT := 3
	const NET_ANIM_FIRE := 4
	const NET_ANIM_DAMAGE := 5
	const NET_ANIM_LACERANTE := 6
	const NET_ANIM_FROZEN := 7

	var active_character_key := CHARACTER_HENRY
	var is_dead := false
	var player_freeze_visual_timer := 0.0
	var henry_ultimate_cast_active := false
	var henry_skill_cast_active := false
	var henry_skill_cast_direction := Vector2.RIGHT
	var player_attack_visual_dir := Vector2.RIGHT
	var time_alive := 20.0
	var last_damage_time := -100.0
	var last_facing := Vector2.RIGHT
	var move := Vector2.ZERO
	var attack_active := false

	func _read_move() -> Vector2:
		return move

	func _player_attack_pose_active() -> bool:
		return attack_active


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	printerr("HENRY_QUIMERA_PRESENTATION_FAIL " + message)


func _placeholder_texture(color: Color) -> ImageTexture:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _frames(count: int, base_color: Color) -> Array:
	var result: Array = []
	result.resize(count)
	for index in range(count):
		var factor := 0.6 + float(index + 1) / float(count + 1) * 0.4
		result[index] = _placeholder_texture(Color(base_color.r * factor, base_color.g * factor, base_color.b * factor, 1.0))
	return result


func _initialize() -> void:
	var five_frame_indices: Array[int] = []
	for frame in range(5):
		var plan := Quimera.resolve_overlay(Quimera.FAMILY_PREDATORY, 1, Vector2.DOWN, frame, Quimera.STATE_WALK)
		five_frame_indices.append(int(plan["frame_index"]))
	_check(five_frame_indices == [0, 1, 0, 1, 0], "predatory two-phase walk mapping drifted")

	var front := Quimera.resolve_overlay(Quimera.FAMILY_PREDATORY, 1, Vector2(-1.0, 1.0), 1, Quimera.STATE_ATTACK)
	var side := Quimera.resolve_overlay(Quimera.FAMILY_STRUCTURAL, 3, Vector2.LEFT, 4, Quimera.STATE_CAST)
	var back := Quimera.resolve_overlay(Quimera.FAMILY_ANOMALOUS, 2, Vector2(1.0, -1.0), 3, Quimera.STATE_WALK)
	_check(front["bucket"] == &"frente" and bool(front["flip_h"]), "southwest attack did not use mirrored front bucket")
	_check(side["bucket"] == &"lado" and bool(side["flip_h"]), "west cast did not use mirrored side bucket")
	_check(back["bucket"] == &"costas" and not bool(back["flip_h"]), "northeast walk did not use back bucket")
	_check(int(side["frame_index"]) == 4 and int(side["source_stage"]) == 2 and bool(side["procedural_accent"]), "stage 3 did not reuse structural stage 2 plus accent")
	_check(int(back["frame_index"]) == 5, "anomalous stage-2 back frame index drifted")
	_check(Quimera.family_layer(Quimera.FAMILY_STRUCTURAL) < Quimera.family_layer(Quimera.FAMILY_PREDATORY), "structural layer lost priority")
	_check(Quimera.family_layer(Quimera.FAMILY_PREDATORY) < Quimera.family_layer(Quimera.FAMILY_ANOMALOUS), "anomalous layer is no longer last")

	for visible_state in [Quimera.STATE_IDLE, Quimera.STATE_WALK, Quimera.STATE_ATTACK, Quimera.STATE_CAST, Quimera.STATE_ULTIMATE, Quimera.STATE_DAMAGE]:
		var plan := Quimera.resolve_overlay(Quimera.FAMILY_STRUCTURAL, 1, Vector2.RIGHT, 0, visible_state)
		_check(bool(plan["visible"]), "visible state was hidden: " + String(visible_state))
		_check(Vector2(plan["offset"]) == Vector2.ZERO, "initial state offset is not contract zero: " + String(visible_state))
	for hidden_state in [Quimera.STATE_FROZEN, Quimera.STATE_DEATH]:
		_check(not bool(Quimera.resolve_overlay(Quimera.FAMILY_STRUCTURAL, 1, Vector2.RIGHT, 0, hidden_state)["visible"]), "hidden state rendered: " + String(hidden_state))
	_check(Quimera.socket_for(Quimera.FAMILY_STRUCTURAL, Quimera.BUCKET_FRONT) != Quimera.socket_for(Quimera.FAMILY_ANOMALOUS, Quimera.BUCKET_FRONT), "family sockets collapsed to one point")

	var mock := MockGame.new()
	_check(Quimera._local_state(mock) == Quimera.STATE_IDLE, "local idle mapping failed")
	mock.move = Vector2.RIGHT
	_check(Quimera._local_state(mock) == Quimera.STATE_WALK, "local walk mapping failed")
	mock.last_damage_time = mock.time_alive
	_check(Quimera._local_state(mock) == Quimera.STATE_DAMAGE, "damage did not override walk")
	mock.attack_active = true
	_check(Quimera._local_state(mock) == Quimera.STATE_ATTACK, "attack did not override damage")
	mock.henry_skill_cast_active = true
	_check(Quimera._local_state(mock) == Quimera.STATE_CAST, "cast did not override attack")
	mock.henry_ultimate_cast_active = true
	_check(Quimera._local_state(mock) == Quimera.STATE_ULTIMATE, "ultimate did not override cast")
	mock.player_freeze_visual_timer = 1.0
	_check(Quimera._local_state(mock) == Quimera.STATE_FROZEN, "frozen did not override ultimate")
	mock.is_dead = true
	_check(Quimera._local_state(mock) == Quimera.STATE_DEATH, "death did not override frozen")

	_check(Quimera._remote_state(mock, {"anim_state": mock.NET_ANIM_IDLE}) == Quimera.STATE_IDLE, "remote idle mapping failed")
	_check(Quimera._remote_state(mock, {"anim_state": mock.NET_ANIM_RIGHT}) == Quimera.STATE_WALK, "remote walk mapping failed")
	_check(Quimera._remote_state(mock, {"anim_state": mock.NET_ANIM_FIRE}) == Quimera.STATE_ATTACK, "remote attack mapping failed")
	_check(Quimera._remote_state(mock, {"anim_state": mock.NET_ANIM_LACERANTE, "frame_idx": 12}) == Quimera.STATE_CAST, "remote cast mapping failed")
	_check(Quimera._remote_state(mock, {"anim_state": mock.NET_ANIM_LACERANTE, "frame_idx": 42}) == Quimera.STATE_ULTIMATE, "remote ultimate mapping failed")
	_check(Quimera._remote_state(mock, {"anim_state": mock.NET_ANIM_DAMAGE}) == Quimera.STATE_DAMAGE, "remote damage mapping failed")
	_check(Quimera._remote_state(mock, {"anim_state": mock.NET_ANIM_FROZEN}) == Quimera.STATE_FROZEN, "remote frozen mapping failed")
	_check(Quimera._remote_state(mock, {"dead": true, "anim_state": mock.NET_ANIM_IDLE}) == Quimera.STATE_DEATH, "remote death mapping failed")

	var body := _placeholder_texture(Color.WHITE)
	var local_rect := Quimera.local_body_rect(body, Vector2(300.0, 200.0), {"preserve_height": true, "height": 88.0, "offset": Vector2.ZERO}, Vector2(54.0, 80.0))
	_check(local_rect.size == Vector2(88.0, 88.0) and is_equal_approx(local_rect.end.y, 240.0), "local body Rect2 lost Henry ground anchor")
	var remote_rect := Quimera.centered_fit_rect(body, Vector2(500.0, 300.0), Vector2(54.0, 80.0))
	_check(remote_rect.size == Vector2(54.0, 54.0) and remote_rect.get_center() == Vector2(500.0, 300.0), "remote body Rect2 no longer matches fitted body")

	var textures := {
		Quimera.STRUCTURAL_TEXTURE_KEY: _frames(6, Color(0.9, 0.7, 0.2)),
		Quimera.PREDATORY_TEXTURE_KEY: _frames(12, Color(0.9, 0.15, 0.08)),
		Quimera.ANOMALOUS_TEXTURE_KEY: _frames(6, Color(0.1, 0.9, 0.72)),
	}
	var sizes_before := [Array(textures[Quimera.STRUCTURAL_TEXTURE_KEY]).size(), Array(textures[Quimera.PREDATORY_TEXTURE_KEY]).size(), Array(textures[Quimera.ANOMALOUS_TEXTURE_KEY]).size()]
	var expected_texture: Texture2D = Array(textures[Quimera.PREDATORY_TEXTURE_KEY])[9]
	var expected_rid := expected_texture.get_rid()
	for iteration in range(2000):
		var resolved := Quimera.texture_for(textures, Quimera.FAMILY_PREDATORY, 3, Quimera.BUCKET_SIDE, iteration * 5 + 1)
		_check(resolved == expected_texture and resolved.get_rid() == expected_rid, "hot resource lookup created or changed a texture")
	_check(sizes_before == [Array(textures[Quimera.STRUCTURAL_TEXTURE_KEY]).size(), Array(textures[Quimera.PREDATORY_TEXTURE_KEY]).size(), Array(textures[Quimera.ANOMALOUS_TEXTURE_KEY]).size()], "resource arrays changed during repeated lookup")
	var source := FileAccess.get_file_as_string("res://scripts/presentation/henry_quimera_presentation.gd")
	_check(source.find("SubViewport") < 0 and source.find("ViewportTexture") < 0 and source.find("Shader.new") < 0 and source.find("ImageTexture.create") < 0, "compositor introduced a viewport, screen shader or runtime texture allocation")

	mock.free()
	if not failed:
		print("HENRY_QUIMERA_PRESENTATION_OK mapping=5frame buckets=front_side_back flip=left stage3=reuse2_accent order=structural_predatory_anomalous states=8 local_remote=true resources=stable")
	quit(1 if failed else 0)
