extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	for sfx in ["Risada-Loop.mp3", "Risada-Moeda.mp3", "Risada-Pedra.mp3", "Risada-Dinheiro.mp3", "Larapio-Dead.mp3"]:
		assert(game.audio_streams.has(sfx), "missing larapio sfx: " + sfx)

	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_LARAPIO, Vector2(520, 460))
	assert(game.enemies.size() == 1)
	var larapio: Dictionary = game.enemies[0]
	larapio["larapio_idle_laugh_cd"] = 0.0
	game._update_larapio_laughs(larapio, 0.1, false)
	assert(float(larapio["larapio_idle_laugh_cd"]) > 1.0)

	larapio["larapio_laugh_gate"] = 0.0
	larapio["larapio_money_laugh_cd"] = 0.0
	game._update_larapio_laughs(larapio, 0.1, true)
	assert(float(larapio["larapio_money_laugh_cd"]) > 1.0)

	game.player_hp = game.player_hp_max
	game._apply_larapio_projectile_hit({"type": "larapio_coin", "owner_uid": larapio["uid"]})
	assert(game.player_stun_timer >= game.LARAPIO_STUN_TIME)

	game._kill_enemy(larapio)
	assert(not game.enemies.has(larapio))
	print("LARAPIO_SFX_SMOKE_OK loaded=5 idle=true money=true hit=true dead=true")
	quit()
