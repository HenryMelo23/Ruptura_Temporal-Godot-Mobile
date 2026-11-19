extends SceneTree

var failed := false
var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("AGGLOMERATION_SPATIAL_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.mode = "game"
	game.set_process(false)
	game.set_physics_process(false)
	game.spawn_timer = 9999.0
	game.boss_active = false
	game.enemies.clear()
	# A fusao so existe depois da anomalia anunciada.
	game.time_alive = game.ANOMALIA_AGLOMERADOR_TIME + 1.0
	game.fusion_cooldown_timer = 0.0

	# Three live commons are eligible; a dead neighbor must not help or join the fusion.
	for offset in [Vector2.ZERO, Vector2(24.0, 0.0), Vector2(0.0, 24.0)]:
		game._spawn_enemy(game.ENEMY_COMMON, Vector2(500.0, 360.0) + offset)
		game.enemies[-1]["agglomerated_time"] = game.FUSION_TIME - game.FUSION_CHECK_INTERVAL
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(512.0, 372.0))
	game.enemies[-1]["hp"] = 0.0
	game.enemies[-1]["agglomerated_time"] = game.FUSION_TIME - game.FUSION_CHECK_INTERVAL
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(1200.0, 650.0))
	var distant_uid: int = int(game.enemies[-1]["uid"])

	game.fusion_check_timer = 0.0
	game._update_agglomeration(1.0 / 60.0)

	var agglomerators := 0
	var distant_survived := false
	var dead_survived := false
	for enemy in game.enemies:
		if String(enemy.get("type", "")) == game.ENEMY_AGGLOMERATOR:
			agglomerators += 1
		if int(enemy.get("uid", -1)) == distant_uid:
			distant_survived = true
		if float(enemy.get("hp", 1.0)) <= 0.0:
			dead_survived = true
	_check(agglomerators == 1, "eligible local cluster did not create exactly one agglomerator")
	_check(distant_survived, "spatial query consumed a common enemy outside the fusion radius")
	_check(dead_survived, "dead neighbor was incorrectly included in the live fusion cluster")
	_check(game.fusion_check_timer == game.FUSION_CHECK_INTERVAL, "fusion interval scheduling changed")

	# Regra nova: bolo CONTINUO de FUSION_TIME segundos funde; soltar zera.
	game.enemies.clear()
	game.fusion_cooldown_timer = 0.0
	for offset in [Vector2.ZERO, Vector2(30.0, 0.0), Vector2(0.0, 30.0)]:
		game._spawn_enemy(game.ENEMY_COMMON, Vector2(700.0, 500.0) + offset)
	for i in range(int(game.FUSION_TIME) - 1):
		game.fusion_check_timer = 0.0
		game._update_agglomeration(1.0 / 60.0)
	_check(game._enemy_type_count(game.ENEMY_AGGLOMERATOR) == 0, "fused before FUSION_TIME seconds")
	game.enemies[0]["pos"] = Vector2(1400.0, 900.0) # um Errante se solta
	game.fusion_check_timer = 0.0
	game._update_agglomeration(1.0 / 60.0)
	_check(float(game.enemies[1].get("agglomerated_time", -1.0)) == 0.0, "broken cluster did not reset its fusion clock")
	game.enemies[0]["pos"] = Vector2(700.0, 520.0)
	for i in range(int(game.FUSION_TIME)):
		game.fusion_check_timer = 0.0
		game._update_agglomeration(1.0 / 60.0)
	_check(game._enemy_type_count(game.ENEMY_AGGLOMERATOR) == 1, "continuous cluster did not fuse")
	_check(game.fusion_cooldown_timer > 0.0, "fusion cooldown not armed")
	# Antes da anomalia (5:30) nao ha fusao.
	game.enemies.clear()
	game.fusion_cooldown_timer = 0.0
	game.time_alive = game.ANOMALIA_AGLOMERADOR_TIME - 30.0
	for offset in [Vector2.ZERO, Vector2(30.0, 0.0), Vector2(0.0, 30.0)]:
		game._spawn_enemy(game.ENEMY_COMMON, Vector2(700.0, 500.0) + offset)
	for i in range(int(game.FUSION_TIME) + 2):
		game.fusion_check_timer = 0.0
		game._update_agglomeration(1.0 / 60.0)
	_check(game._enemy_type_count(game.ENEMY_AGGLOMERATOR) == 0, "fused before the announced anomaly time")

	print("AGGLOMERATION_SPATIAL_OK enemies_after=%d agglomerators=%d" % [game.enemies.size(), agglomerators])
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
