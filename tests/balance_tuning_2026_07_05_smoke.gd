extends SceneTree

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
	for i in range(4):
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


func _collectable_larapio_loot_total() -> int:
	var total := 0
	for coin in game.larapio_coin_drops:
		if bool(coin.get("collectable", false)):
			total += int(coin.get("value", 0))
	return total


func _run() -> void:
	game._start_game()

	game.score = 1000
	game.score_total = 1000
	game._spawn_enemy(game.ENEMY_LARAPIO, game.player_pos + Vector2(42, 0))
	var larapio: Dictionary = game.enemies.back()
	game._larapio_steal(larapio, game.LARAPIO_STEAL_RATIO)
	_check(game.score == 400, "Larapio did not steal 60 percent of current score")
	_check(int(larapio.get("stolen", 0)) == 600, "Larapio stolen stash mismatch")
	game.larapio_coin_drops.clear()
	game._kill_enemy(larapio)
	_check(_collectable_larapio_loot_total() == 630, "Larapio should return 90 percent plus 15 percent bonus of stolen points")

	game.enemy_bullets.clear()
	game.score = 0
	game.enemy_far_damage = 20.0
	game._spawn_enemy(game.ENEMY_LARAPIO, game.player_pos + Vector2(700, 0))
	var desperate_larapio: Dictionary = game.enemies.back()
	desperate_larapio["spawned_at"] = game.time_alive - game.LARAPIO_DESPERATE_AFTER - 1.0
	desperate_larapio["hp"] = float(desperate_larapio["max_hp"]) * 0.25
	desperate_larapio["throw_cd"] = 0.0
	game._update_larapio(desperate_larapio, 0.02)
	_check(is_equal_approx(float(desperate_larapio.get("throw_cd", 0.0)), game.LARAPIO_DESPERATE_THROW_INTERVAL), "desperate Larapio should throw every 2 seconds")
	var desperate_stone: Dictionary = game.enemy_bullets.back()
	_check(float(desperate_stone.get("speed_mult", 0.0)) >= 1.36 * game.LARAPIO_DESPERATE_STONE_SPEED_MULT, "desperate Larapio stone speed was not boosted")
	_check(float(desperate_stone.get("damage", 0.0)) > game.player_hp_max * 0.015, "desperate Larapio stone damage was not boosted")

	game.cards_bought.clear()
	game.luck = 0.03
	game.cards_bought["Sorte"] = 10
	_check(abs(game._chance_carta_rara() - 0.0666) < 0.0001, "Sorte rare chance should follow the harder rarity curve")

	game.enemy_bullets.clear()
	game.enemy_far_damage = 0.0
	game.player_hp_max = 1000.0
	game.player_pos = Vector2(760, 450)
	game.arauto = {"active": true, "pos": Vector2(480, 450), "hp": 1000.0, "max_hp": 1000.0, "facing": 1.0}
	game._fire_arauto_shot(false)
	_check(int(game.enemy_bullets.back().get("damage", 0)) == 78, "Arauto projectile damage was not increased by 50 percent")
	game.enemy_bullets.clear()
	game.player_hp = 1000
	game.enemies.clear()
	game.arauto["gaze_target"] = game.player_pos
	game._resolve_arauto_gaze(false)
	_check(game.player_hp == 790, "Arauto gaze damage was not increased by 50 percent")

	game._start_game()
	game.enemy_base_hp = 92.0
	game.enemy_speed_base = 166.0
	game.score_total = 0
	game.enemies_killed = 0
	game._advance_to_phase(2)
	_check(is_equal_approx(game.enemy_base_hp, 92.0), "phase 2 reset enemy HP scaling instead of carrying phase 1 growth")
	_check(is_equal_approx(game.enemy_speed_base, 166.0), "phase 2 reset enemy speed scaling instead of carrying phase 1 growth")
	var pyro = game.enemies.filter(func(enemy): return String(enemy.get("type", "")) == game.ENEMY_PYRO_PENGUIN)[0]
	_check(float(pyro.get("max_hp", 0.0)) > game.ENEMY_BASE_HP * 1.85 * 1.85, "pyro penguin did not inherit carried enemy scaling")
	_check(is_equal_approx(game.boss_hp_max, 6600.0), "Boss 2 base HP was not increased")
	game.current_phase = 2
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 1000.0
	game.boss_hp = 1000.0
	game._damage_boss(100.0, "smoke")
	_check(abs(game.boss_hp - 949.5) < 0.05, "Boss 2 armor was not increased progressively")

	game._start_game()
	game.score_total = 0
	game.enemies_killed = 0
	game._advance_to_phase(3)
	_check(is_equal_approx(game.boss_hp_max, 12800.0), "Boss 3 base HP was not increased progressively")
	game.current_phase = 3
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 1000.0
	game.boss_hp = 1000.0
	game._damage_boss(100.0, "smoke")
	_check(abs(game.boss_hp - 952.5) < 0.05, "Boss 3 armor was not increased progressively")

	game._start_game()
	game.score_total = 0
	game.enemies_killed = 0
	game._advance_to_phase(4)
	_check(is_equal_approx(game.boss_hp_max, 18800.0), "Boss 4 base HP was not increased progressively")
	game.current_phase = 4
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 1000.0
	game.boss_hp = 1000.0
	game._damage_boss(100.0, "smoke")
	_check(abs(game.boss_hp - 955.5) < 0.05, "Boss 4 armor was not increased progressively")

	await _finish_ok("BALANCE_TUNING_2026_07_05_SMOKE_OK larapio=60/105 desperate=true rarity_harder=true arauto=1.5x phase_scaling=true bosses=progressive")
