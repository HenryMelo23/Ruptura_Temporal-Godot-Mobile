extends SceneTree

const AuraSystem = preload("res://scripts/aura_system.gd")

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _finish_ok(message: String) -> void:
	print(message)
	if is_instance_valid(game):
		_cleanup_audio_resources()
		root.remove_child(game)
		game.free()
		game = null
	await process_frame
	quit(0)


func _cleanup_audio_resources() -> void:
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
	game.audio_streams.clear()
	game.textures.clear()


func _run() -> void:
	game._start_game()

	var old_interval: float = game.player_attack_interval
	game._apply_card({"name": "Speed Atack", "color": Color.WHITE})
	_check(is_equal_approx(game.player_attack_interval, old_interval - 0.014), "Speed Atack nerf did not apply the smaller interval reduction")

	var insane := AuraSystem.create("Insana", 1)
	insane["insane_ready"] = 0.0
	for i in range(12):
		AuraSystem.on_attack(insane, {"pos": Vector2.ZERO, "dir": Vector2.RIGHT, "kind": "eletrica"})
	_check(int(insane.get("insane_echoes", 0)) == 0, "Insana echoes should be spent after the first burst")
	_check(Array(insane.get("insane_queue", [])).size() == 4, "Insana spam should not create a second burst while the first queue is pending")
	_check(float(insane.get("insane_ready", 0.0)) > 0.0, "Insana cooldown should start as soon as the burst begins")

	game.enemies.clear()
	game.enemy_bullets.clear()
	game.current_phase = 1
	game.time_alive = game.COUT_AS_SPAWN_TIME + 5.0
	game.player_pos = Vector2(420, 500)
	game.player_attack_interval = 0.30
	game.last_attack_time = 10.0
	game._spawn_enemy(game.ENEMY_COUT_ATTACK_SPEED, game.player_pos + Vector2(120, 0))
	var counter: Dictionary = game.enemies.back()
	counter["as_last_attack_seen"] = 9.68
	counter["as_player_pos_seen"] = game.player_pos + Vector2(4, 0)
	counter["as_punish_cd"] = 0.0
	game._update_cout_attack_speed(counter, 0.02)
	game.last_attack_time = 10.30
	game._update_cout_attack_speed(counter, 0.02)
	_check(game.enemy_bullets.any(func(b): return String(b.get("type", "")) == "cout_attack_speed"), "Attack-speed counter did not punish rapid stationary fire")

	game.enemy_bullets.clear()
	game._spawn_enemy(game.ENEMY_SHIELD_REFLECTOR, game.player_pos + Vector2(160, 0))
	var shield: Dictionary = game.enemies.back()
	shield["facing_dir"] = Vector2.LEFT
	var reflected: bool = game._try_reflect_shield_enemy_bullet(shield, {"dir": Vector2.RIGHT, "damage": 80.0})
	_check(reflected, "Shield reflector did not reflect a frontal shot")
	_check(game.enemy_bullets.any(func(b): return String(b.get("type", "")) == "reflected_player"), "Shield reflector did not spawn a reflected projectile")

	game.current_phase = 1
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 1000.0
	game.boss_hp = 1000.0
	game.boss1_absorb_timer = game.BOSS1_ABSORB_DURATION
	game.boss1_absorb_damage = 0.0
	game._damage_boss(100.0, "smoke")
	_check(game.boss1_absorb_damage > 0.0, "Boss 1 did not store absorbed damage")
	_check(game.boss_hp > 960.0, "Boss 1 absorb should let only 40 percent of final damage through")

	await _finish_ok("ATTACK_SPEED_COUNTER_ABSORB_SMOKE_OK speed_atack_nerfed=true insana_locked=true phase1_counters=true boss_absorb=true")
