extends SceneTree

var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("FIVE_NEW_CARDS_FAIL " + message)
	print("FIVE_NEW_CARDS_FAIL %s" % message)
	quit(1)


func _spawn_test_enemy(pos: Vector2, hp := 1000.0) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var enemy: Dictionary = game.enemies[game.enemies.size() - 1]
	enemy["pos"] = pos
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	enemy["facing_dir"] = Vector2.RIGHT
	enemy["last_move_dir"] = Vector2.RIGHT
	return enemy


func _reset_fixture() -> void:
	game._reset_card_counts()
	game._reset_card_proc_state()
	game.enemies.clear()
	game.heal_orbs.clear()
	game.common_card_effects.clear()
	game.rare_card_effects.clear()
	game.player_pos = Vector2(640, 360)
	game.last_facing = Vector2.RIGHT
	game.player_damage = 100.0
	game.player_defense = 0
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.time_alive = 60.0
	game.mode = "game"
	game.is_dead = false
	game.boss_active = false
	game.boss_dead = false
	game.boss_hp = 0.0
	game.boss_hp_max = 1000.0
	game.boss_pos = Vector2(760, 360)
	game.arauto.clear()
	game.current_phase = 1
	game.manifestation_key = "eletrica"


func _run() -> void:
	await process_frame
	game._start_game()
	_reset_fixture()

	var common_ids: Array[String] = [
		game.CARD_INTERVALO_ID,
		game.CARD_NUCLEO_ID,
		game.CARD_LIMIAR_RUINA_ID,
		game.CARD_ESTASE_ID
	]
	for id in common_ids:
		var card: Dictionary = game._find_card_by_id(id)
		_check(not card.is_empty(), "missing_common_%s" % id)
		if failed: return
		_check(not game._is_rare_card(card), "not_common_%s" % id)
		if failed: return
		_check(game._card_max_count(card) >= 999999, "limited_common_%s" % id)
		if failed: return
		_check(game._card_texture(card) != null, "missing_frame_1_%s" % id)
		if failed: return
		_check(game._get_texture("card_" + String(card["name"]) + "_2") != null, "missing_frame_2_%s" % id)
		if failed: return
		for i in range(12):
			game._apply_card(card)
		_check(game._card_count_by_id(id) == 12, "common_not_unlimited_%s" % id)
		if failed: return
	_reset_fixture()

	var egide: Dictionary = game._find_card_by_id(game.CARD_EGIDE_ID)
	_check(not egide.is_empty(), "missing_egide")
	_check(game._is_rare_card(egide), "egide_not_rare")
	_check(game._card_max_count(egide) >= 999999, "egide_limited")
	_check(game._card_texture(egide) != null, "egide_frame_1_missing")
	_check(game._get_texture("card_" + String(egide["name"]) + "_2") != null, "egide_frame_2_missing")
	for i in range(10):
		game._apply_card(egide)
	_check(game._card_count_by_id(game.CARD_EGIDE_ID) == 10, "egide_not_unlimited")
	_reset_fixture()

	var hab1_base: float = game._skill_cooldown_base()
	var ult_base: float = game._secondary_skill_cooldown_base()
	game._apply_card(game._find_card_by_id(game.CARD_INTERVALO_ID))
	_check(game._skill_cooldown() < hab1_base, "intervalo_hab1_not_reduced")
	_check(game._secondary_skill_cooldown() < ult_base, "intervalo_ult_not_reduced")
	var one_copy_hab1: float = game._skill_cooldown()
	for i in range(4):
		game._apply_card(game._find_card_by_id(game.CARD_INTERVALO_ID))
	_check(game._skill_cooldown() < one_copy_hab1, "intervalo_does_not_scale")
	_check(game._skill_cooldown() > hab1_base * 0.69, "intervalo_hab1_floor_broken")
	_check(game._secondary_skill_cooldown() > ult_base * 0.81, "intervalo_ult_floor_broken")
	_reset_fixture()

	game.player_hp = 500
	game._spawn_heal_orb(game.player_pos, 0.10)
	game._update_heal_orbs(0.016)
	_check(game.player_hp == 550, "baseline_orb_changed")
	_reset_fixture()
	game._apply_card(game._find_card_by_id(game.CARD_NUCLEO_ID))
	game.player_hp = 500
	game._spawn_heal_orb(game.player_pos, 0.10)
	game._update_heal_orbs(0.016)
	_check(game.player_hp == 560, "nucleo_orb_bonus_bad")
	_reset_fixture()

	game._apply_card(game._find_card_by_id(game.CARD_LIMIAR_RUINA_ID))
	var fresh_enemy := _spawn_test_enemy(Vector2(700, 360), 1000.0)
	game._damage_enemy(fresh_enemy, 100.0, "atk", false, false, game.player_pos, "basic_attack")
	_check(float(fresh_enemy["hp"]) < 900.0, "limiar_no_bonus_at_full_hp")
	var exact_enemy := _spawn_test_enemy(Vector2(760, 360), 1000.0)
	exact_enemy["hp"] = 900.0
	game._damage_enemy(exact_enemy, 100.0, "atk", false, false, game.player_pos, "basic_attack")
	_check(is_equal_approx(float(exact_enemy["hp"]), 800.0), "limiar_triggered_at_exact_90")
	var dot_enemy := _spawn_test_enemy(Vector2(820, 360), 1000.0)
	game._damage_enemy(dot_enemy, 100.0, "veneno", false, false, game.player_pos, "damage_over_time")
	_check(is_equal_approx(float(dot_enemy["hp"]), 900.0), "limiar_triggered_on_dot")
	var boss_no_card_hp: float = 1000.0
	game.cards_bought[game.CARD_LIMIAR_RUINA_ID] = 0
	game.boss_active = true
	game.boss_hp = boss_no_card_hp
	game.boss_hp_max = 1000.0
	game._damage_boss(100.0, "atk", false, false, "basic_attack", game.player_pos)
	var boss_damage_without_limiar: float = boss_no_card_hp - game.boss_hp
	game.cards_bought[game.CARD_LIMIAR_RUINA_ID] = 1
	game.boss_hp = 1000.0
	game.boss_hp_max = 1000.0
	game._damage_boss(100.0, "atk", false, false, "basic_attack", game.player_pos)
	var boss_damage_with_limiar: float = 1000.0 - game.boss_hp
	_check(boss_damage_with_limiar > boss_damage_without_limiar * 1.15, "limiar_no_boss_bonus")
	game.arauto = {"active": true, "pos": Vector2(720, 360), "hp": 1000.0, "max_hp": 1000.0, "entry_timer": 0.0, "variant": game.ARAUTO_VARIANT_CONDUTOR}
	game._damage_arauto(100.0, "atk", false, false, "basic_attack", game.player_pos)
	_check(float(game.arauto["hp"]) < 900.0, "limiar_no_arauto_bonus")
	_reset_fixture()

	game._apply_card(game._find_card_by_id(game.CARD_ESTASE_ID))
	game.player_hp = 500
	for i in range(21):
		game._update_estase_reparadora(0.25)
	_check(game.estase_reparadora_active, "estase_not_active_after_delay")
	var hp_before_estase: int = game.player_hp
	for i in range(4):
		game._update_estase_reparadora(0.25)
	_check(game.player_hp > hp_before_estase, "estase_no_heal")
	game.player_pos += Vector2(12, 0)
	game._update_estase_reparadora(0.25)
	_check(not game.estase_reparadora_active and game.estase_reparadora_timer == 0.0, "estase_not_reset_on_move")
	_reset_fixture()

	game._apply_card(game._find_card_by_id(game.CARD_EGIDE_ID))
	game.player_hp = game.player_hp_max
	game._heal_player(100.0, "heal_orb", false)
	_check(game.egide_hemofaga_shield == 0.0, "egide_accepted_orb_overheal")
	game._heal_player(100.0, "lifesteal", false)
	_check(game.egide_hemofaga_shield > 0.0, "egide_no_lifesteal_overheal")
	_check(game.egide_hemofaga_shield <= game._egide_shield_limit() + 0.01, "egide_over_limit")
	var shield_before: float = game.egide_hemofaga_shield
	var remainder: int = game._absorb_egide_hemofaga_shield(10)
	_check(remainder == 0 and game.egide_hemofaga_shield < shield_before, "egide_did_not_absorb")
	game.egide_hemofaga_full_timer = 0.0
	shield_before = game.egide_hemofaga_shield
	game._update_egide_hemofaga(1.0)
	_check(game.egide_hemofaga_shield < shield_before, "egide_no_decay")
	_reset_fixture()

	for id in common_ids:
		_check(game._card_count_by_id(id) == 0, "reset_common_count_%s" % id)
	_check(game._card_count_by_id(game.CARD_EGIDE_ID) == 0, "reset_egide_count")
	_check(game.estase_reparadora_timer == 0.0 and not game.estase_reparadora_active, "reset_estase_state")
	_check(game.egide_hemofaga_shield == 0.0 and game.egide_hemofaga_full_timer == 0.0, "reset_egide_state")

	print("FIVE_NEW_CARDS_SMOKE_OK registered=5 sprites=true unlimited=true intervalo=true nucleo=true limiar_enemy_boss_arauto=true estase=true egide=true reset=true")
	quit(0)
