extends SceneTree

## Cordao umbilical da Pustula Fossil (2026-11-18): o acerto arrasta o jogador
## ao longo do tempo (sem teleporte), outros inimigos nao acertam durante o
## puxao, a pustula estoura na chegada e o cordao arrebenta se ela morrer.

var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("FOSSIL_CORD_FAIL " + message)


func _pustule(pos: Vector2) -> Dictionary:
	game._spawn_enemy(game.ENEMY_FOSSIL_PUSTULE, pos)
	var p: Dictionary = game.enemies[-1]
	p["pos"] = pos
	p["speed"] = 0.0
	p["pustule_mature_time"] = 99.0
	return p


func _hit(pustule: Dictionary) -> void:
	game.enemy_bullets.clear()
	game._fire_fossil_pustule_spit(pustule, game.player_pos)
	game.enemy_bullets.back()["pos"] = game.player_pos
	game._update_enemy_bullets(0.0)


func _run() -> void:
	game.startup_thanks_done = true
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.enemies.clear()
	game.phase6_pustule_pools.clear()
	game.player_hp_max = 1000.0
	game.player_hp = 1000.0
	game.player_pos = Vector2(900, 500)
	var tether: RTFossilPustuleTether = game.fossil_pustule_tether
	var pustule := _pustule(Vector2(600, 500))
	var hooked_from: Vector2 = game.player_pos
	_hit(pustule)
	_check(tether.is_pulling(), "cordao nao comecou a puxar")
	_check(game.player_pos.distance_to(hooked_from) < 1.0, "cordao teleportou")
	_check(game._local_player_movement_locked(), "jogador anda durante o puxao")
	var hp_before: float = float(game.player_hp)
	game._damage_player(80, "common")
	_check(is_equal_approx(float(game.player_hp), hp_before), "outro inimigo acertou durante o puxao")
	var mid_seen := false
	for i in range(90):
		tether.update(1.0 / 60.0)
		if tether.is_pulling() and game.player_pos.distance_to(hooked_from) > 4.0 and game.player_pos.distance_to(Vector2(pustule["pos"])) > 4.0:
			mid_seen = true
		if not tether.is_pulling():
			break
	_check(mid_seen, "nao passou por posicoes intermediarias")
	_check(game.player_pos.distance_to(Vector2(pustule["pos"])) < 1.0, "nao chegou na pustula")
	_check(bool(pustule.get("pustule_exploded", false)), "pustula nao estourou na chegada")
	_check(game.phase6_pustule_pools.size() == 1, "estouro nao criou a poca")
	_check(not tether.blocks_damage("common"), "imunidade continuou depois do puxao")
	# Pustula morre no meio do caminho: o cordao arrebenta e o jogador fica.
	game.enemies.clear()
	game.player_pos = Vector2(900, 500)
	var second := _pustule(Vector2(500, 500))
	_hit(second)
	for i in range(5):
		tether.update(1.0 / 60.0)
	second["hp"] = 0.0
	tether.update(1.0 / 60.0)
	_check(not tether.is_pulling(), "cordao nao arrebentou com a pustula morta")
	_check(game.player_pos.distance_to(Vector2(500, 500)) > 100.0, "jogador foi arrastado mesmo com o cordao arrebentado")
	if not failed:
		print("FOSSIL_CORD_OK duration=%.2f" % tether.duration)
	quit(1 if failed else 0)
