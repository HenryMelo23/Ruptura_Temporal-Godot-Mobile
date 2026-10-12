extends SceneTree

var game: Node


func _expect(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("BOSS2_NEVASCA_DEATH_AUDIO_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.mode = "game"
	game.current_phase = 2
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 6000.0
	game.boss_hp = 1.0
	game._start_boss2_ultimate()
	_expect(game.nevasca_audio_player.playing, "audio_did_not_start_before_authority_kill")

	game._damage_boss(100000.0, "nevasca_death_audio_smoke", false, false)
	_expect(game.boss_dead, "authority_kill_did_not_finish_boss")
	_expect(is_zero_approx(game.boss2_ultimate_timer), "authority_cleanup_kept_ultimate_timer")
	_expect(not game.nevasca_audio_player.playing, "authority_cleanup_kept_audio_playing")

	game.boss_active = true
	game.boss_dead = false
	game.boss_hp = 1.0
	game._start_boss2_ultimate()
	_expect(game.nevasca_audio_player.playing, "audio_did_not_restart_before_replica_snapshot")
	game.is_multiplayer = true
	game.is_host = false
	game.online_room_owner = false
	var dead_boss_snapshot := PackedFloat32Array([
		game.boss_pos.x, game.boss_pos.y, 0.0, 1.0, 0.0, 2.0,
		game.boss_hp_max, game.boss_phase, -1.0, 0.0, 0.0, 0.0
	])
	game._apply_remote_boss_snapshot(dead_boss_snapshot, Time.get_ticks_msec())
	_expect(game.boss_dead and not game.boss_active, "replica_did_not_apply_dead_boss_snapshot")
	_expect(not game.nevasca_audio_player.playing, "replica_kept_audio_after_dead_boss_snapshot")

	print("BOSS2_NEVASCA_DEATH_AUDIO_OK authority=true replica=true timer_cleanup=true")
	game.is_multiplayer = false
	game._cleanup_runtime_resources()
	game.queue_free()
	game = null
	for _frame in range(4):
		await process_frame
	quit(0)
