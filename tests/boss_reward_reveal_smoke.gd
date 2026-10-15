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
	var reveal: Dictionary = game.boss_reward_reveal.duplicate(true)
	var card_ids: Array = Array(reveal.get("card_ids", []))
	_check(game.BOSS_REWARD_CARD_COUNT == card_ids.size(), "snapshot_does_not_match_boss_grant_count")
	_check(_deck_count() == before_deck + card_ids.size(), "snapshot_cards_were_not_applied_to_deck")
	_check(int(reveal.get("recipient_peer_id", 0)) == game._mp_unique_id(), "recipient_is_not_local_grantee")
	_check(Vector2(reveal.get("origin", Vector2.ZERO)) == game.boss_pos, "reward_origin_drifted")
	for card_id in card_ids:
		_check(not game._find_card_by_id(String(card_id)).is_empty(), "snapshot_has_unknown_card_id")

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
