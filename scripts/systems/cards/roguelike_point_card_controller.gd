class_name RTRoguelikePointCardController
extends RefCounted

const CARD_PRISM_SHARD_ID := "estilhaco_prismatico"
const CARD_PAIN_TRIBUTE_ID := "tributo_da_dor"
const CARD_ABSOLUTE_CRIT_ID := "critico_absoluto"
const CARD_IMPOSSIBLE_ARCHIVE_ID := "arquivo_impossivel"

const PRISM_CHANCE_MISS_FACTOR := 0.86
const PRISM_BASE_POINTS := 35
const PRISM_VALUE_PER_EXTRA_COPY := 0.55
const PAIN_LINEAR_POINTS := 0.80
const PAIN_QUADRATIC_POINTS := 0.045

var core


func configure(runtime_core) -> void:
	core = runtime_core


func prism_shard_chance(copies: int = -1) -> float:
	var count := _raw_count(CARD_PRISM_SHARD_ID) if copies < 0 else maxi(0, copies)
	if count <= 0:
		return 0.0
	return 1.0 - pow(PRISM_CHANCE_MISS_FACTOR, float(count))


func prism_shard_value(copies: int = -1) -> int:
	var count := _raw_count(CARD_PRISM_SHARD_ID) if copies < 0 else maxi(0, copies)
	if count <= 0:
		return 0
	var timed_base := PRISM_BASE_POINTS
	if core != null:
		timed_base = core._points_for_enemy({"points": PRISM_BASE_POINTS})
	return maxi(PRISM_BASE_POINTS, int(round(float(timed_base) * (1.0 + PRISM_VALUE_PER_EXTRA_COPY * float(count - 1)))))


func pain_reward(copies: float = -1.0) -> int:
	var count := _effective_common_count(CARD_PAIN_TRIBUTE_ID) if copies < 0.0 else maxf(0.0, copies)
	if count <= 0.0:
		return 0
	return maxi(1, int(round(PAIN_LINEAR_POINTS * count + PAIN_QUADRATIC_POINTS * count * count)))


func critical_damage_multiplier(copies: int = -1) -> float:
	var count := _raw_count(CARD_ABSOLUTE_CRIT_ID) if copies < 0 else maxi(0, copies)
	return 1.0 + float(count)


func extra_card_copies(card: Dictionary, archive_copies: int = -1) -> int:
	if card.is_empty() or core == null:
		return 0
	if core._is_legendary_card(card):
		return 0
	var count := _raw_count(CARD_IMPOSSIBLE_ARCHIVE_ID) if archive_copies < 0 else maxi(0, archive_copies)
	return count


func on_enemy_defeated(enemy: Dictionary, pos: Vector2) -> Dictionary:
	var copies := _raw_count(CARD_PRISM_SHARD_ID)
	if copies <= 0 or core == null:
		return {}
	if core.is_multiplayer and not core._is_world_authority():
		return {}
	if core.rng.randf() >= prism_shard_chance(copies):
		return {}
	var value := prism_shard_value(copies)
	var orb: Dictionary = core._spawn_enemy_point_drop(pos, value, {
		"large_prism_shard": true,
		"large_prism_value": value,
		"large_prism_copies": copies,
		"stack_count": 4,
	})
	if orb.is_empty():
		return {}
	core._add_text("LASCA +%d" % value, pos + Vector2(0, -82), Color(0.38, 0.96, 1.0), 1.05, 20)
	core._spawn_radial_particles(pos, Color(0.48, 0.36, 1.0), 8 if core._memory_saver_active() else 15)
	core._play_sfx("Moeda.mp3", 0.045, 0.40, 1.42)
	return orb


func on_player_damaged(actual_hp_damage: float) -> int:
	if core == null or actual_hp_damage <= 0.0:
		return 0
	var reward := pain_reward()
	if reward <= 0:
		return 0
	core._apply_score_delta(reward)
	core._add_text("DOR +%d" % reward, core.player_pos + Vector2(0, -104), Color(1.0, 0.66, 0.18), 0.72, 17)
	core._spawn_radial_particles(core.player_pos, Color(1.0, 0.46, 0.14), 4 if core._memory_saver_active() else 7)
	return reward


func _raw_count(card_id: String) -> int:
	if core == null:
		return 0
	return maxi(0, int(core.cards_bought.get(card_id, 0)))


func _effective_common_count(card_id: String) -> float:
	if core == null:
		return 0.0
	return maxf(0.0, float(core._effective_card_count(card_id)))
