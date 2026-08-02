extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var game: Node
var booted := false

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _initialize() -> void:
	if booted:
		return
	booted = true
	game = MainScene.new()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame

	game._start_game()
	game.manifestation_key = "lacerante"
	game.player_hp = 300
	game.player_hp_max = 450
	game.player_damage = 100.0
	game.lacerante_coagula = 40
	var points: Array = game._lacerante_stage_points(game.player_pos, Vector2.RIGHT, 0)
	_check(Vector2(points[-1]).distance_to(game.player_pos) > 148.0, "lacerante reach did not scale with coagula")
	_check(game._lacerante_ultimate_extra_cuts() == 4, "lacerante ultimate extra cuts not scaling by 20 coagula")
	_check(is_equal_approx(game._lacerante_q_rotations(), 9.0), "lacerante Q rotations not scaling by 10 coagula")
	var before_damage := 100
	game._damage_player(before_damage, "smoke")
	_check(game.player_hp == 222, "lacerante damage reduction did not apply")
	game.lacerante_tp_cooldown_until = 0.0
	game.time_alive = 12.0
	game.tp_cooldown_pending = true
	game._consume_lacerante_tp_charge()
	_check(game.lacerante_tp_charges == 1 and is_equal_approx(game.lacerante_tp_chain_timer, game.LACERANTE_TP_CHAIN_WINDOW), "lacerante TP chain did not open for the configured window")
	game._consume_lacerante_tp_charge()
	_check(game.lacerante_tp_charges == 0 and game.lacerante_tp_chain_timer <= 0.0, "lacerante TP did not spend its second charge")
	game.tp_effects.clear()
	game._finish_teleport_effect_cooldown()
	_check(game.lacerante_tp_cooldown_until == game.time_alive + 2.0, "lacerante TP did not enter absolute 2s cooldown")

	game.time_alive = 900.0
	for i in range(4):
		game._spawn_enemy(game.ENEMY_CURATER, game.player_pos + Vector2(80 + i * 8, 0))
	_check(game._enemy_type_count(game.ENEMY_CURATER) == 3, "curater limit before 25 minutes failed")

	game.score = 1000
	game._spawn_enemy(game.ENEMY_LARAPIO, game.player_pos + Vector2(260, 0))
	var larapio: Dictionary = game.enemies.filter(func(e): return String(e.get("type", "")) == game.ENEMY_LARAPIO)[0]
	larapio["spawned_at"] = game.time_alive - game.LARAPIO_AGGRESSIVE_AFTER - 1.0
	larapio["alerted"] = true
	larapio["throw_cd"] = 0.0
	game._update_larapio(larapio, 0.01)
	_check(is_equal_approx(float(larapio.get("throw_cd", 0.0)), game.LARAPIO_AGGRESSIVE_THROW_INTERVAL), "aggressive larapio throw interval failed")
	var thrown: Dictionary = game.enemy_bullets.back()
	_check(float(thrown.get("speed_mult", 0.0)) > 1.36, "aggressive larapio stone speed failed")

	game.cards_bought = {"Speed Boost": 1, "Damage Up": 1, "Porcao": 1}
	game.deck_scroll_pos = 2.8
	game._clamp_deck_selection(3)
	_check(game.deck_selected == 0, "deck carousel did not wrap forward")
	game.deck_scroll_pos = -0.2
	game._clamp_deck_selection(3)
	_check(game.deck_selected == 0 or game.deck_selected == 2, "deck carousel did not wrap backward")

	_check(game.BOSS2_ULTIMATE_DURATION == 28.0, "boss2 ultimate duration not reduced to 28s")
	game.current_phase = 2
	game.boss_active = true
	game.boss_hp = 1000.0
	game.boss_hp_max = 4000.0
	game.boss_attacks.clear()
	game._add_boss2_shield()
	_check(game._boss2_shield_active(), "boss2 shield did not activate")
	var hp_before: float = game.boss_hp
	game._damage_boss(999.0, "smoke")
	_check(is_equal_approx(game.boss_hp, hp_before), "boss2 shield is not immune")
	var shield: Dictionary = game.boss_attacks[0]
	_check(int(shield.get("pillar_count", 0)) >= game.BOSS2_SHIELD_PILLAR_MIN and int(shield.get("pillar_count", 0)) <= game.BOSS2_SHIELD_PILLAR_MAX, "boss2 shield pillar count outside range")
	game._update_boss2_attacks(0.50)
	_check(game.boss_attacks.any(func(a): return String(a.get("kind", "")) == "ice_pillar"), "boss2 shield did not schedule ice pillars")

	_check(game.BOSS3_MIASMA_COOLDOWN == 24.0, "boss3 miasma cooldown was not tightened")
	print("BALANCE_PACK_LACERANTE_BOSSES_SMOKE_OK lacerante=true larapio=true curater=true boss2=true boss3=true deck=true")
	game._cleanup_runtime_resources()
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
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
	for i in range(2):
		await process_frame
	quit(0)
