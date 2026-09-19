class_name EnemyManager
extends Node

var game: Node

func _init(p_game: Node) -> void:
	game = p_game

func update(delta: float) -> void:
	if not game._is_world_authority() or game.spawn_timer > 0.0 or game.boss_active or game._tutorial_blocks_normal_spawn():
		return
	spawn_wave()

func spawn_wave() -> void:
	# TODO: Mover a logica de _spawn_wave do main.gd para ca
	game.spawn_timer = get_enemy_spawn_interval()
	if game._arauto_active():
		return
	var limit = get_enemy_limit()
	if game.enemies.size() >= limit:
		return
	
	# Precisaremos extrair as funcoes de escolha de tipo e posicao
	# var kind = game._choose_enemy_type()
	# game._spawn_enemy(kind, game._spawn_point_for_type(kind))

func get_enemy_spawn_interval() -> float:
	return game._enemy_spawn_interval()

func get_enemy_limit() -> int:
	return game._enemy_limit()
