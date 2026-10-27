extends RefCounted

const TEMPORAL_LUCK_MAX := 0.60
const TEMPORAL_LUCK_REFERENCE_SECONDS := 60.0 * 60.0
const TEMPORAL_LUCK_REFERENCE_VALUE := 0.35
# Solves max * (1 - exp(-reference / tau)) = reference value. Keeping the
# resolved constant explicit makes the live curve deterministic and auditable.
const TEMPORAL_LUCK_TIME_CONSTANT_SECONDS := 4112.082872177689

var core


func configure(runtime_core) -> void:
	core = runtime_core


func temporal_luck_at(elapsed_seconds: float) -> float:
	var elapsed := maxf(0.0, elapsed_seconds)
	return TEMPORAL_LUCK_MAX * (1.0 - exp(-elapsed / TEMPORAL_LUCK_TIME_CONSTANT_SECONDS))


func temporal_luck() -> float:
	return temporal_luck_at(float(core.time_alive))


func effective_luck() -> float:
	return maxf(0.0, float(core.luck)) + temporal_luck()


func uncommon_card_chance() -> float:
	var chance := 0.22 + effective_luck() * 0.26 + float(core._sorte_card_count()) * 0.012
	return clampf(chance, 0.0, 0.48)


func rare_card_chance() -> float:
	if not core._rare_cards_unlocked():
		return 0.0
	var chance := 0.025 + effective_luck() * 0.12 + float(core._sorte_card_count()) * 0.0038
	return clampf(chance, 0.0, 0.14)


func legendary_card_chance() -> float:
	if not core._legendary_cards_unlocked():
		return 0.0
	var chance := 0.005 + effective_luck() * 0.02 + float(core._sorte_card_count()) * 0.0008
	return clampf(chance, 0.0, 0.03)


func card_drop_chance() -> float:
	var progress := clampf(float(core.time_alive) / (120.0 * 60.0), 0.0, 1.0)
	return clampf(0.045 + (0.4 - 0.045) * progress + effective_luck() * 0.25, 0.0, 0.7)


func drop_mode_rarity_weights() -> Array:
	var current_luck := effective_luck()
	return [
		[core.CARD_RARITY_COMMON, 74.0],
		[core.CARD_RARITY_UNCOMMON, 20.0 + 22.0 * current_luck],
		[core.CARD_RARITY_RARE, 5.5 + 10.0 * current_luck],
		[core.CARD_RARITY_LEGENDARY, 0.5 + 2.0 * current_luck],
	]
