extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("REACTIVE_SURVIVAL_CARDS_SMOKE_FAIL " + message)
	_cleanup(1)


func _spawn_target(position: Vector2) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, position)
	var enemy: Dictionary = game.enemies[-1]
	enemy["hp"] = 1000.0
	enemy["max_hp"] = 1000.0
	return enemy


func _reset_fixture() -> void:
	game._reset_card_counts()
	game._reset_card_proc_state()
	game.reactive_survival_card_controller.reset()
	game.enemies.clear()
	game.player_pos = Vector2(640, 360)
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.player_defense = 0.0
	game.player_damage = 100.0
	game.mode = "game"
	game.time_alive = 60.0
	game.is_dead = false
	game.is_multiplayer = false
	game.boss_active = false
	game.current_phase = 1
	game.aura_state = {}
	game.contractual_order = {}
	game.contractual_order_penalties.clear()


func _run() -> void:
	await process_frame
	game._start_game()
	game.set_process(false)
	_reset_fixture()
	var owner = game.reactive_survival_card_controller
	var fragment_card: Dictionary = game._find_card_by_id(game.CARD_FRAGMENTACAO_REATIVA_ID)
	var bastion_card: Dictionary = game._find_card_by_id(game.CARD_BASTIAO_INERCIAL_ID)
	for card in [fragment_card, bastion_card]:
		_check(not card.is_empty(), "new uncommon card is missing")
		_check(String(card.get("rarity", "")) == game.CARD_RARITY_UNCOMMON, "new card is not uncommon")
		_check(game._card_max_count(card) >= game.CARD_UNLIMITED_COUNT, "new uncommon card is not unlimited")
		_check(game._card_texture(card) != null, "new card frame 1 is missing")
		_check(game._get_texture("card_" + String(card["name"]) + "_2") != null, "new card frame 2 is missing")

	game._apply_card(fragment_card)
	_check(is_equal_approx(owner.fragment_radius(), 150.0), "fragment initial radius is not 150px")
	var targets: Array[Dictionary] = [
		_spawn_target(game.player_pos + Vector2(70, 0)),
		_spawn_target(game.player_pos + Vector2(-95, 0)),
		_spawn_target(game.player_pos + Vector2(0, 125)),
		_spawn_target(game.player_pos + Vector2(0, -145)),
	]
	var outside := _spawn_target(game.player_pos + Vector2(180, 0))
	game._damage_player(100, "test_hit", true)
	_check(owner.fragments.size() == 4, "damage did not launch four traveling fragments")
	owner.update(0.5)
	for target in targets:
		_check(float(target["hp"]) < 1000.0, "fragment did not damage an in-range target")
	_check(is_equal_approx(float(outside["hp"]), 1000.0), "fragment hit a target outside 150px")
	var damage_one: float = float(owner.fragment_damage_ratio())
	game._apply_card(fragment_card)
	_check(is_equal_approx(owner.fragment_radius(), 180.0), "second copy did not add 30px radius")
	_check(owner.fragment_damage_ratio() > damage_one, "second copy did not increase fragment damage")

	_reset_fixture()
	game._apply_card(bastion_card)
	owner.update(owner.BASTION_SETTLE_TIME + 0.01)
	_check(is_equal_approx(owner.stationary_armor(), 6.0), "stationary bastion did not grant six armor")
	_check(is_equal_approx(owner.movement_speed_multiplier(), 1.015), "bastion did not grant 1.5 percent movement speed")
	game.player_hp = 1000
	game._damage_player(20, "test_hit", true)
	_check(game.player_hp == 986, "stationary bastion armor was not included in incoming damage")
	var armor_before_move: float = float(owner.stationary_armor())
	game.player_pos += Vector2(12, 0)
	owner.update(0.2)
	_check(owner.stationary_armor() < armor_before_move, "bastion armor did not break when moving")
	game._apply_card(bastion_card)
	owner.update(owner.BASTION_SETTLE_TIME + 0.01)
	_check(owner.stationary_armor() > 6.0 and is_equal_approx(owner.movement_speed_multiplier(), 1.03), "bastion copies did not scale armor and speed")

	_reset_fixture()
	for card in [fragment_card, bastion_card]:
		for _index in range(32):
			game._apply_card(card)
		_check(game._card_count_by_id(String(card["id"])) == 32, "unlimited stack failed for %s" % String(card["id"]))

	print("REACTIVE_SURVIVAL_CARDS_SMOKE_OK fragments=traveling targets=4 radius=150 scaling=unlimited bastion_armor=6 bastion_speed=1.5pct")
	_cleanup(0)


func _cleanup(code: int) -> void:
	if game != null and is_instance_valid(game):
		game._cleanup_runtime_resources()
		game.queue_free()
	quit(code)
