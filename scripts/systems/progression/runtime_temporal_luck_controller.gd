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


## Rebalanceamento 2026-11: a carta Sorte rende cada vez menos por copia (curva
## 1 - e^(-n/4)) e as raras/lendarias crescem com o tempo de run, para que a
## primeira rara nao saia nos primeiros minutos. A sorte oculta (temporal) segue
## subindo sozinha, garantindo que a sorte nunca fique parada.
const SORTE_CURVE_COPIES := 4.0


func sorte_curve(copies: int = -1) -> float:
	var n: float = float(core._sorte_card_count()) if copies < 0 else float(copies)
	return 1.0 - exp(-maxf(0.0, n) / SORTE_CURVE_COPIES)


## 0..1: quanto da chance de rara ja esta liberada pelo tempo de run.
func rare_time_ramp(min_value: float = 0.35) -> float:
	return clampf((float(core.time_alive) - 120.0) / 720.0, min_value, 1.0)


func uncommon_card_chance() -> float:
	var chance := 0.22 + effective_luck() * 0.24 + 0.08 * (1.0 - exp(-float(core._sorte_card_count()) / 5.0))
	return clampf(chance, 0.0, 0.45)


func rare_card_chance() -> float:
	if not core._rare_cards_unlocked():
		return 0.0
	var chance := (0.016 + effective_luck() * 0.09 + 0.02 * sorte_curve()) * rare_time_ramp()
	return clampf(chance, 0.0, 0.11)


func legendary_card_chance() -> float:
	if not core._legendary_cards_unlocked():
		return 0.0
	var ramp := clampf((float(core.time_alive) - 300.0) / 900.0, 0.3, 1.0)
	var chance := (0.003 + effective_luck() * 0.016 + 0.004 * sorte_curve()) * ramp
	return clampf(chance, 0.0, 0.025)


func card_drop_chance() -> float:
	var progress := clampf(float(core.time_alive) / (120.0 * 60.0), 0.0, 1.0)
	return clampf(0.045 + (0.4 - 0.045) * progress + effective_luck() * 0.25, 0.0, 0.7)


func drop_mode_rarity_weights() -> Array:
	var current_luck := effective_luck()
	# Modo drop: raras/lendarias comecam em zero e entram aos poucos (3 -> 15 min).
	var ramp := clampf((float(core.time_alive) - 180.0) / 720.0, 0.0, 1.0)
	var sorte := sorte_curve()
	return [
		[core.CARD_RARITY_COMMON, 74.0],
		[core.CARD_RARITY_UNCOMMON, 20.0 + 22.0 * current_luck],
		[core.CARD_RARITY_RARE, (1.6 + 7.0 * current_luck + 1.5 * sorte) * ramp],
		[core.CARD_RARITY_LEGENDARY, (0.15 + 1.2 * current_luck) * ramp],
	]
