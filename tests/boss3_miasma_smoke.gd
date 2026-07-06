extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("BOSS3_MIASMA_FAIL " + message)
	quit(1)


func _prepare_boss() -> void:
	game._start_game()
	game._advance_to_phase(3)
	game.mode = "game"
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 8000.0
	game.boss_hp = 8000.0
	game.boss_pos = Vector2(900, 430)
	game.player_pos = Vector2(700, 430)
	game.boss_attacks.clear()
	game.enemy_bullets.clear()
	game.phase3_cheeses.clear()


func _run() -> void:
	_prepare_boss()
	game._start_boss3_miasma(1)
	_check(game.boss3_miasma_variant == 1, "yellow clone symptom did not start")
	_check(is_equal_approx(game.boss3_miasma_timer, 15.0), "ultimate duration is not 15 seconds")
	_check(game.boss3_miasma_clone_positions.size() == 4, "clone symptom did not create four decoys")
	_check(game._boss3_miasma_hides_boss_bar(), "clone symptom did not hide boss health bar")
	var old_boss_pos: Vector2 = game.boss_pos
	game.boss3_miasma_clone_timer = 0.0
	game._update_boss3_miasma(0.01)
	_check(game.boss_pos != old_boss_pos, "boss did not swap places with a clone")
	game._update_boss3_miasma(15.1)
	_check(not game._boss3_miasma_active(), "clone symptom exceeded 15 seconds")
	_check(is_equal_approx(game.boss3_miasma_cooldown, game.BOSS3_MIASMA_COOLDOWN), "cooldown did not begin after ending")

	game._start_boss3_miasma(2)
	game.boss3_miasma_spit_timer = 0.0
	game.boss3_cheese_timer = 0.0
	game._update_boss_phase3(0.01)
	_check(game.phase3_cheeses.is_empty(), "darkness symptom generated cheese")
	_check(game.boss_attacks.size() == 1 and String(game.boss_attacks[0].get("kind", "")) == "miasma_cheese_spit", "darkness symptom used a non-cheese attack")
	_check(is_equal_approx(float(game.boss_attacks[0].get("warn", 0.0)), 0.8), "cheese spit warning is not 800ms")
	game._update_boss3_attacks(0.81)
	var spit = game.enemy_bullets.filter(func(b): return String(b.get("type", "")) == "miasma_cheese_spit")
	_check(spit.size() == 1, "telegraphed cheese spit did not fire")
	game.player_hp = game.player_hp_max
	spit[0]["pos"] = game.player_pos
	spit[0]["dir"] = Vector2.ZERO
	game._update_enemy_bullets(0.01)
	_check(game.player_stun_timer >= 0.89, "cheese spit did not lock player for 900ms")
	_check(game.player_hp < game.player_hp_max, "cheese spit caused no damage")
	game._end_boss3_miasma(true)

	game.player_hp = game.player_hp_max
	game._start_boss3_miasma(3)
	_check(game.boss3_miasma_qte_required >= 20 and game.boss3_miasma_qte_required <= 40, "QTE requirement is outside 20 to 40")
	_check(game.boss3_miasma_qte_tutorial > 0.0, "first QTE did not show tutorial")
	var protected_hp: int = game.player_hp
	game._damage_player(999, "test")
	_check(game.player_hp == protected_hp, "player was not invulnerable during QTE")
	game._handle_boss3_miasma_qte_tap(Vector2(640, 360), Vector2(1280, 720))
	_check(game.boss3_miasma_qte_taps == 1, "center tap was not counted")
	game._update_boss3_miasma_qte(1.01)
	_check(game.boss3_miasma_qte_taps == 1, "infinite-time QTE should not remove taps by inactivity")
	game.player_hp = game.player_hp_max
	for i in range(10):
		game._update_boss3_miasma_qte(0.20)
	_check(game.player_hp < game.player_hp_max, "closing eyelids did not damage after the first free touch")
	var hp_after_lid_damage: int = game.player_hp
	game._update_boss3_miasma_qte(8.5)
	_check(game._boss3_miasma_active(), "QTE ended after old max time instead of staying infinite")
	_check(game.player_hp < hp_after_lid_damage, "overtime faith drain did not apply after max time")
	for i in range(game.boss3_miasma_qte_required):
		game._handle_boss3_miasma_qte_tap(Vector2(640, 360), Vector2(1280, 720))
	_check(not game._boss3_miasma_active(), "successful QTE did not end symptom")
	_check(is_equal_approx(game.boss3_miasma_cooldown, game.BOSS3_MIASMA_COOLDOWN), "successful QTE did not start cooldown")

	game._start_boss3_miasma(3)
	_check(game.boss3_miasma_qte_tutorial <= 0.0, "tutorial repeated after first QTE")
	game.player_hp = game.player_hp_max
	game._update_boss3_miasma_qte(7.1)
	_check(game._boss3_miasma_active(), "QTE should not fail automatically at seven seconds")
	game._end_boss3_miasma(false)

	game.boss3_miasma_cooldown = game.BOSS3_MIASMA_COOLDOWN
	game._update_boss3_miasma(game.BOSS3_MIASMA_COOLDOWN - 1.0)
	_check(not game._boss3_miasma_active(), "ultimate returned before post-use cooldown")
	game._update_boss3_miasma(1.1)
	_check(game._boss3_miasma_active(), "ultimate did not return after 30-second cooldown")

	print("BOSS3_MIASMA_SMOKE_OK duration=15 cooldown=%ds clones=true darkness=250 warning=800ms stun=900ms qte=infinite-link" % int(game.BOSS3_MIASMA_COOLDOWN))
	quit(0)
