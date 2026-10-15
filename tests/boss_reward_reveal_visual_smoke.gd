extends SceneTree

const CAPTURE_SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(960, 540)]

var game: Node


func _initialize() -> void:
	root.size = CAPTURE_SIZES[0]
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("BOSS_REWARD_REVEAL_VISUAL_FAIL " + message)
	quit(1)


func _capture(label: String, low_resource: bool) -> void:
	for size in CAPTURE_SIZES:
		root.size = size
		root.content_scale_size = size
		game.gfx_low_resource = low_resource
		var deck_before: Dictionary = game.cards_bought.duplicate(true)
		var reveal_before: Dictionary = game.boss_reward_reveal.duplicate(true)
		game.queue_redraw()
		await process_frame
		await process_frame
		var image: Image = root.get_texture().get_image()
		_check(image != null and image.get_size() == size, "invalid_capture_%s_%d" % [label, size.x])
		if image != null:
			var output: String = "res://.agent_logs/boss_reward_%s_%dx%d.png" % [label, size.x, size.y]
			_check(image.save_png(ProjectSettings.globalize_path(output)) == OK, "save_failed_" + output)
		_check(deck_before == game.cards_bought, "render_changed_deck_" + label)
		_check(reveal_before == game.boss_reward_reveal, "render_changed_snapshot_" + label)


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.agent_logs"))
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.boss_ready = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.current_phase = 1
	game.player_pos = Vector2(800.0, 540.0)
	game.boss_pos = Vector2(800.0, 350.0)
	game.boss_active = false
	game.boss_dead = true
	var ids: Array[String] = []
	for card in game.CARDS.slice(0, 4):
		ids.append(game._card_id(card))
	game._present_boss_reward_cards(ids, game.boss_pos)
	game.boss_reward_reveal["elapsed"] = game.BOSS_REWARD_REVEAL_SHAKE_TIME * 0.55
	await _capture("boss_shake", false)
	game.boss_reward_reveal["elapsed"] = game.BOSS_REWARD_REVEAL_SHAKE_TIME + game.BOSS_REWARD_REVEAL_EMERGE_TIME + game.BOSS_REWARD_REVEAL_HOVER_TIME * 0.45
	await _capture("cards_hover", false)
	await _capture("cards_hover_mobile_low", true)
	game._clear_boss_reward_reveal()
	print("BOSS_REWARD_REVEAL_VISUAL_OK captures=%d desktop_mobile=true" % (CAPTURE_SIZES.size() * 3))
	quit(0)
