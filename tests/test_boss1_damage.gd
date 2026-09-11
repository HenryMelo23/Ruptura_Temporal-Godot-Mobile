extends SceneTree

var game: Node

func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")

func _run() -> void:
	game._start_game()
	game.current_phase = 1
	game.boss_active = true
	game.boss_dead = false
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos
	game.player_hp_max = 500.0
	game.player_hp = 500.0

	print("[TEST] Testing Boss 1 Wave Damage...")
	var initial_hp = game.player_hp
	var wave = {
		"idx": 0,
		"pos": game.boss_pos,
		"radius": 100.0,
		"speed": 230.0,
		"width": 20.0,
		"kind": "dupla_abertura",
		"open_angle": 0.0,
		"open_size": PI * 0.38,
		"age": 1.0,
		"warning": 0.78,
		"hit": false,
		"enraged": false
	}
	game.boss_transition_waves = [wave]
	# Position player on the wave ring (radius 100) away from openings (angle 0 and PI)
	game.player_pos = game.boss_pos + Vector2(0, 100.0) # Angle PI/2 (90 deg) -> NOT in opening
	game._update_boss_transition_waves(0.0)
	print("  - Wave hit: %s | Player HP before: %.1f | after: %.1f" % [str(wave.get("hit", false)), initial_hp, game.player_hp])
	assert(bool(wave.get("hit", false)), "Wave hit flag was not set!")
	assert(game.player_hp < initial_hp, "Wave damage was not applied!")

	print("[TEST] Testing Boss 1 Bubble Damage...")
	game.player_hp = 500.0
	initial_hp = game.player_hp
	var bubble_attack = {
		"kind": "bubble",
		"target": game.player_pos,
		"age": 2.7, # 2.7 / 3.2 = 0.84 (between 0.75 and 0.92)
		"duration": 3.2,
		"hit": false
	}
	game.boss_attacks = [bubble_attack]
	game._update_boss_attacks(0.0)
	print("  - Bubble hit: %s | Player HP before: %.1f | after: %.1f" % [str(bubble_attack.get("hit", false)), initial_hp, game.player_hp])
	assert(bool(bubble_attack.get("hit", false)), "Bubble hit flag was not set!")
	assert(game.player_hp < initial_hp, "Bubble damage was not applied!")

	print("[TEST] Testing Boss 1 Tide Damage...")
	game.player_hp = 500.0
	initial_hp = game.player_hp
	var tide_attack = {
		"kind": "tide",
		"age": 2.0,
		"duration": 4.2,
		"horizontal": true,
		"positive": true,
		"hit": false
	}
	var tide_y = game._boss_tide_line(tide_attack)
	game.player_pos = Vector2(game.WORLD_SIZE.x * 0.5, tide_y)
	game.boss_attacks = [tide_attack]
	game._update_boss_attacks(0.0)
	print("  - Tide hit: %s | Player HP before: %.1f | after: %.1f" % [str(tide_attack.get("hit", false)), initial_hp, game.player_hp])
	assert(bool(tide_attack.get("hit", false)), "Tide hit flag was not set!")
	assert(game.player_hp < initial_hp, "Tide damage was not applied!")

	print("[TEST] Testing Boss 1 Pressure Bubble Bullet Damage...")
	game.player_hp = 500.0
	initial_hp = game.player_hp
	game.enemy_bullets.clear()
	game._spawn_boss_pressure_bubble(game.player_pos, Vector2.RIGHT, 45.0)
	game._update_enemy_bullets(0.05)
	print("  - Bullets count: %d | Player HP before: %.1f | after: %.1f" % [game.enemy_bullets.size(), initial_hp, game.player_hp])

	print("ALL_BOSS1_DAMAGE_TESTS_OK")
	quit(0)
