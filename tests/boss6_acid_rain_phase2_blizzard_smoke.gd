extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("BOSS6_ACID_RAIN_PHASE2_BLIZZARD_FAIL " + message)
	_cleanup()
	quit(1)


func _cleanup() -> void:
	if game == null:
		return
	if game.has_method("_cleanup_runtime_resources"):
		game._cleanup_runtime_resources()
	if "music_player" in game and game.music_player != null:
		game.music_player.stop()
		game.music_player.stream = null
	if "rain_audio_player" in game and game.rain_audio_player != null:
		game.rain_audio_player.stop()
		game.rain_audio_player.stream = null
	if "sfx_players" in game:
		for player in game.sfx_players:
			if player != null:
				player.stop()
				player.stream = null
	if "textures" in game:
		game.textures.clear()
	if "audio_streams" in game:
		game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null


func _run() -> void:
	await process_frame
	game._start_game()
	game.mode = "game"
	game.player_pos = game.WORLD_SIZE * 0.5
	game.player_hp_max = 1000
	game.player_hp = 1000

	game.current_phase = 6
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 1000.0
	game.boss_hp = 890.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.boss_attacks.clear()
	game.boss6_acid_poison_timer = 0.0
	game._update_boss6_acid_rain(0.05)
	_check(game.boss6_acid_rain_unlocked, "acid rain did not unlock below 90 percent")
	_check(game.boss_attacks.size() >= game.BOSS6_ACID_RAIN_DROP_COUNT, "acid rain did not spawn 35 drops")
	var rain_attack: Dictionary = game.boss_attacks[0]
	rain_attack["target"] = game.player_pos
	rain_attack["age"] = game.BOSS6_ACID_RAIN_WARNING
	game.boss_attacks[0] = rain_attack
	game._update_boss_attacks(0.02)
	_check(game.boss6_acid_poison_timer > 0.0, "acid rain impact did not apply poison")
	var hp_before_poison := int(game.player_hp)
	game._update_boss6_acid_poison(1.05)
	_check(game.player_hp < hp_before_poison, "acid poison did not tick damage")

	game.current_phase = 2
	game._reset_boss2_state()
	game.phase2_ambient_blizzard_timer = 0.0
	game._update_phase2_ambient_blizzard(0.02)
	_check(game.phase2_ambient_blizzard_active > 0.0, "ambient phase 2 blizzard did not start")
	_check(game._environment_player_slow_mult() <= game.PHASE2_AMBIENT_BLIZZARD_SLOW_MULT + 0.001, "ambient blizzard slow is not applied")
	game._update_phase2_ambient_blizzard(0.12)
	_check(not game.phase2_ambient_snowflakes.is_empty(), "ambient blizzard did not emit snowflakes")

	game.manifestation_key = "necronada"
	game.necronada_remnants.clear()
	game.necronada_remnants.append({
		"id": 101,
		"enemy_type": game.ENEMY_COMMON,
		"pos": game.player_pos + Vector2(80, 0),
		"hp": 200.0,
		"max_hp": 200.0,
		"summon": 0.0,
		"profile": game._necronada_profile(game.ENEMY_COMMON)
	})
	var bullet := {
		"pos": Vector2(game.necronada_remnants[0].get("pos", game.player_pos)),
		"dir": Vector2.RIGHT,
		"life": 1.0,
		"damage": 90.0,
		"type": "phase2_penguin_common"
	}
	var remnant_hp_before := float(game.necronada_remnants[0].get("hp", 0.0))
	var hit_remnant: bool = game._damage_remnant_from_enemy_bullet(bullet, 28.0)
	_check(hit_remnant, "penguin common projectile did not hit necro-ally")
	_check(float(game.necronada_remnants[0].get("hp", 0.0)) < remnant_hp_before, "penguin projectile did not damage necro-ally")
	_check(float(bullet.get("life", 0.0)) > 0.0, "penguin common projectile disappeared on necro-ally")

	game.current_phase = 1
	game.mode = "game"
	game.boss_attacks = [{"kind": game.BOSS6_ABILITY_ACID_RAIN, "age": 0.0, "duration": 2.0}]
	game.boss_transition_waves = [{"pos": game.player_pos, "life": 1.0}]
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 100.0
	game.boss_hp = 1.0
	game.player_damage = 10.0
	game._damage_boss(10.0, "smoke")
	_check(game.boss_dead, "boss did not die in smoke")
	_check(game.boss_attacks.is_empty(), "boss attacks were not cleared on death")
	_check(game.boss_transition_waves.is_empty(), "boss transition waves were not cleared on death")
	_check(not game.phase_fragment.is_empty(), "phase fragment was not spawned after boss death")
	var next_phase := int(game.phase_fragment.get("next_phase", 0))
	game._start_phase_transition(next_phase)
	game._advance_to_phase(next_phase)
	_check(not game.boss_dead and not game.boss_active, "phase advance did not reset boss death state")
	_check(game.spawn_timer <= 0.0, "phase advance did not reopen enemy spawn timer")
	var enemies_before: int = game.enemies.size()
	game._spawn_wave()
	_check(game.enemies.size() > enemies_before, "enemy spawning did not resume after phase advance")

	print("BOSS6_ACID_RAIN_PHASE2_BLIZZARD_SMOKE_OK acid=true phase2_blizzard=true penguin_pass=true boss_cleanup=true")
	_cleanup()
	for _i in range(4):
		await process_frame
	quit(0)
