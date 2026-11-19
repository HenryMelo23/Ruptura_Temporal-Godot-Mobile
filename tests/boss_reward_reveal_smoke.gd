extends SceneTree

const BossRewardPresentation = preload("res://scripts/presentation/boss_reward_presentation.gd")

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("BOSS_REWARD_REVEAL_SMOKE_FAIL " + message)
	quit(1)


func _deck_count() -> int:
	var total: int = 0
	for count in game.cards_bought.values():
		total += int(count)
	return total


func _run() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.current_phase = 5
	game.player_pos = Vector2(740.0, 520.0)
	game.boss_pos = Vector2(860.0, 380.0)
	game.boss_reward_reveal.clear()

	var before_deck: int = _deck_count()
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 1000.0
	game.boss_hp = 1.0
	game._damage_boss(99999.0, "boss_reward_reveal_test")
	# 2026-11: chefe nao concede mais cartas (vira escolha de pacto/evolucao).
	_check(game.boss_reward_reveal.is_empty(), "boss_kill_still_reveals_cards")
	_check(_deck_count() == before_deck, "boss_kill_still_grants_cards")
	_check(game._run_choice().pending_kind == "pact" or String(game.run_finalized_result) != "", "boss_kill_did_not_queue_pact")
	# A apresentacao continua funcionando para outras fontes de carta.
	var card_ids: Array = [String(game._card_id(Dictionary(game.CARDS[0])))]
	var before_presentation_only: int = _deck_count()
	game._present_boss_reward_cards([String(card_ids[0])], game.boss_pos)
	_check(_deck_count() == before_presentation_only, "presentation_created_or_applied_loot")
	_check(BossRewardPresentation.total_duration(game, game.boss_reward_reveal) > game.BOSS_REWARD_REVEAL_SHAKE_TIME, "sequence_duration_missing")

	game.boss_reward_reveal["recipient_peer_id"] = game._mp_unique_id() + 1
	game._update_boss_reward_reveal(0.01)
	_check(game.boss_reward_reveal.is_empty(), "foreign_peer_received_phantom_reveal")

	game._present_boss_reward_cards([String(card_ids[0])], game.boss_pos)
	game._update_boss_reward_reveal(BossRewardPresentation.total_duration(game, game.boss_reward_reveal) + 0.01)
	_check(game.boss_reward_reveal.is_empty(), "completed_reveal_not_cleaned")

	game._present_boss_reward_cards([String(card_ids[0])], game.boss_pos)
	game._start_phase_transition(2)
	_check(game.boss_reward_reveal.is_empty(), "phase_transition_did_not_cleanup_reveal")

	game.online_local_spectator = true
	game._present_boss_reward_cards([String(card_ids[0])], game.boss_pos)
	_check(game.boss_reward_reveal.is_empty(), "spectator_received_reward_card")
	game.online_local_spectator = false

	print("BOSS_REWARD_REVEAL_SMOKE_OK cards=%d exact_snapshot=true presentation_only=true recipient_guard=true cleanup=true" % card_ids.size())
	quit(0)
