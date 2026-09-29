class_name RTRuntimeEventCatalog

const SCHEMA: String = "ruptura.runtime_event"
const SCHEMA_VERSION: int = 1

const CONFIG: Dictionary = {
	"min_start_time": 240.0,
	"base_cooldown": 86.0,
	"late_cooldown": 52.0,
	"base_threshold": 13.0,
	"late_threshold": 8.0,
	"intensity_full_time": 1080.0,
	"enemy_charge": {
		"default": 1.0,
		"common": 1.0,
		"stalker": 1.05,
		"projector": 1.25,
		"crystal": 1.35,
		"curater": 1.45,
		"agglomerator": 1.7,
		"larapio": 2.25
	}
}

const EVENTS: Array = [
	{
		"id": "damage_surge",
		"label": "Ruptura Ofensiva",
		"stat": "damage",
		"duration_base": 22.0,
		"duration_late": 34.0,
		"multiplier_base": 1.16,
		"multiplier_late": 1.34,
		"weight": 1.0
	},
	{
		"id": "movement_surge",
		"label": "Passo Cronal",
		"stat": "move_speed",
		"duration_base": 20.0,
		"duration_late": 32.0,
		"multiplier_base": 1.12,
		"multiplier_late": 1.26,
		"weight": 0.95
	},
	{
		"id": "attack_surge",
		"label": "Cadencia Instavel",
		"stat": "attack_interval",
		"duration_base": 18.0,
		"duration_late": 30.0,
		"multiplier_base": 0.9,
		"multiplier_late": 0.78,
		"weight": 0.9
	},
	{
		"id": "double_points",
		"label": "Eco de Recompensa",
		"stat": "points",
		"duration_base": 18.0,
		"duration_late": 28.0,
		"multiplier_base": 2.0,
		"multiplier_late": 2.0,
		"weight": 0.85
	}
]


static func intensity_at(run_time: float) -> float:
	var min_start: float = float(CONFIG.get("min_start_time", 240.0))
	var full_time: float = float(CONFIG.get("intensity_full_time", 1080.0))
	return clampf((run_time - min_start) / maxf(1.0, full_time - min_start), 0.0, 1.0)


static func cooldown_for(run_time: float) -> float:
	var intensity: float = intensity_at(run_time)
	return lerpf(float(CONFIG.get("base_cooldown", 86.0)), float(CONFIG.get("late_cooldown", 52.0)), intensity)


static func threshold_for(run_time: float) -> float:
	var intensity: float = intensity_at(run_time)
	return lerpf(float(CONFIG.get("base_threshold", 13.0)), float(CONFIG.get("late_threshold", 8.0)), intensity)


static func enemy_charge(enemy_type: String) -> float:
	var charge: Dictionary = CONFIG.get("enemy_charge", {})
	return float(charge.get(enemy_type, charge.get("default", 1.0)))


static func event_by_index(index: int) -> Dictionary:
	if EVENTS.is_empty():
		return {}
	return Dictionary(EVENTS[posmod(index, EVENTS.size())]).duplicate(true)


static func event_count() -> int:
	return EVENTS.size()


static func event_duration(event: Dictionary, run_time: float) -> float:
	var intensity: float = intensity_at(run_time)
	return lerpf(float(event.get("duration_base", 20.0)), float(event.get("duration_late", 30.0)), intensity)


static func event_multiplier(event: Dictionary, run_time: float) -> float:
	var intensity: float = intensity_at(run_time)
	return lerpf(float(event.get("multiplier_base", 1.0)), float(event.get("multiplier_late", 1.0)), intensity)
