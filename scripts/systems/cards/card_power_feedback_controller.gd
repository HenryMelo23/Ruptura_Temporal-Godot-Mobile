extends RefCounted

const MAX_PENDING_ACQUISITIONS := 6
const MAX_ACTIVE_FEEDBACK_EFFECTS := 14
const ACQUISITION_INTERVAL := 0.32
const POWER_HIT_INTERVAL := 0.14
const LIFESTEAL_INTERVAL := 0.10
const SPEED_TRAIL_INTERVAL := 0.16
const THREAT_INTERVAL := 0.85

var core
var pending_acquisitions: Array = []
var acquisition_timer := 0.0
var power_hit_timer := 0.0
var lifesteal_timer := 0.0
var speed_trail_timer := 0.0
var threat_timer := 0.0
var last_player_pos := Vector2.ZERO


func configure(runtime_core) -> void:
	core = runtime_core
	last_player_pos = core.player_pos


func reset() -> void:
	pending_acquisitions.clear()
	acquisition_timer = 0.0
	power_hit_timer = 0.0
	lifesteal_timer = 0.0
	speed_trail_timer = 0.0
	threat_timer = 0.0
	last_player_pos = core.player_pos if core != null else Vector2.ZERO


func on_card_acquired(card: Dictionary, from_archive: bool) -> void:
	if core == null or card.is_empty():
		return
	var card_id: String = core._card_id(card)
	for entry in pending_acquisitions:
		if String(entry.get("card_id", "")) == card_id:
			entry["copies"] = int(entry.get("copies", 1)) + 1
			entry["stack"] = core._card_count(card)
			return
	pending_acquisitions.append({
		"card_id": card_id,
		"name": String(card.get("name", card_id)),
		"rarity": core._card_rarity_key(card),
		"color": core._card_rarity_color(card),
		"stack": core._card_count(card),
		"copies": 1,
		"archive": from_archive,
	})
	while pending_acquisitions.size() > MAX_PENDING_ACQUISITIONS:
		pending_acquisitions.pop_front()


func update(delta: float) -> void:
	acquisition_timer = maxf(0.0, acquisition_timer - delta)
	power_hit_timer = maxf(0.0, power_hit_timer - delta)
	lifesteal_timer = maxf(0.0, lifesteal_timer - delta)
	speed_trail_timer = maxf(0.0, speed_trail_timer - delta)
	threat_timer = maxf(0.0, threat_timer - delta)
	if core == null:
		return
	var movement: Vector2 = core.player_pos - last_player_pos
	last_player_pos = core.player_pos
	if core.mode != "game" or core.is_dead:
		return
	if not pending_acquisitions.is_empty() and acquisition_timer <= 0.0:
		_emit_acquisition(Dictionary(pending_acquisitions.pop_front()))
		acquisition_timer = ACQUISITION_INTERVAL
	var speed_stacks: int = core._card_count_by_id("Speed Boost")
	if speed_stacks > 0 and movement.length_squared() >= 36.0 and speed_trail_timer <= 0.0:
		_emit_effect({
			"kind": "card_speed_trail",
			"pos": core.player_pos,
			"from": core.player_pos - movement.normalized() * (30.0 + minf(42.0, float(speed_stacks) * 3.0)),
			"life": 0.28,
			"max": 0.28,
			"radius": 34.0 + minf(22.0, float(speed_stacks) * 2.0),
			"stacks": speed_stacks,
			"color": Color(0.0, 1.0, 0.78),
		})
		speed_trail_timer = SPEED_TRAIL_INTERVAL * (1.55 if core._memory_saver_active() else 1.0)


func on_damage_confirmed(enemy: Dictionary, actual_damage: float, critical_hit: bool, source_category: String) -> void:
	if core == null or actual_damage <= 0.0 or source_category not in ["basic_attack", "manifestation_secondary"]:
		return
	var pos: Vector2 = Vector2(enemy.get("pos", core.player_pos))
	var max_hp: float = maxf(1.0, float(enemy.get("max_hp", actual_damage)))
	var tempestade_stacks: int = core._card_count_by_id("Tempestade")
	if critical_hit and tempestade_stacks > 0:
		_emit_effect({
			"kind": "card_critical_hit",
			"pos": pos,
			"life": 0.42,
			"max": 0.42,
			"radius": 42.0 + minf(26.0, float(tempestade_stacks) * 2.0),
			"stacks": tempestade_stacks,
			"color": Color(1.0, 0.82, 0.18),
		})
		core.screen_shake_timer = maxf(core.screen_shake_timer, 0.10)
		core.screen_shake_strength = maxf(core.screen_shake_strength, minf(7.0, 3.0 + float(tempestade_stacks) * 0.3))
	var damage_stacks: int = core._card_count_by_id("Disparo crescente")
	if damage_stacks > 0 and power_hit_timer <= 0.0 and actual_damage >= maxf(18.0, max_hp * 0.12):
		_emit_effect({
			"kind": "card_power_hit",
			"pos": pos,
			"origin": core.player_pos,
			"life": 0.34,
			"max": 0.34,
			"radius": 34.0 + minf(24.0, float(damage_stacks) * 2.0),
			"stacks": damage_stacks,
			"color": Color(1.0, 0.3, 0.22),
		})
		power_hit_timer = POWER_HIT_INTERVAL
	var overkill: float = maxf(0.0, float(enemy.get("overkill_damage", 0.0)))
	if float(enemy.get("hp", 1.0)) <= 0.0 and (critical_hit or overkill >= max_hp * 0.12):
		_emit_effect({
			"kind": "card_overkill",
			"pos": pos,
			"life": 0.48,
			"max": 0.48,
			"radius": 54.0 + minf(34.0, overkill / max_hp * 36.0),
			"power": clampf(overkill / max_hp, 0.0, 1.5),
			"color": Color(1.0, 0.48, 0.18),
		})


func on_lifesteal(source_pos: Vector2, heal: int) -> void:
	if core == null or heal <= 0 or lifesteal_timer > 0.0 or core._card_count_by_id("Roubo de Vida") <= 0:
		return
	_emit_effect({
		"kind": "card_lifesteal",
		"pos": source_pos,
		"target": core.player_pos,
		"life": 0.36,
		"max": 0.36,
		"radius": 34.0,
		"heal": heal,
		"color": Color(0.95, 0.1, 0.34),
	})
	lifesteal_timer = LIFESTEAL_INTERVAL


func on_player_hit(incoming_damage: float, actual_damage: float, source: String) -> void:
	if core == null or actual_damage <= 0.0:
		return
	var defense_stacks: int = core._card_count_by_id("Defesa")
	var prevented: float = maxf(0.0, incoming_damage - actual_damage)
	if defense_stacks > 0 and prevented >= 1.0:
		_emit_effect({
			"kind": "card_defense_block",
			"pos": core.player_pos,
			"life": 0.38,
			"max": 0.38,
			"radius": 48.0 + minf(22.0, float(defense_stacks) * 1.6),
			"blocked": prevented,
			"color": Color(0.58, 0.86, 1.0),
		})
	if threat_timer <= 0.0 and actual_damage >= maxf(12.0, float(core.player_hp_max) * 0.08):
		_emit_effect({
			"kind": "enemy_threat_impact",
			"pos": core.player_pos,
			"life": 0.55,
			"max": 0.55,
			"radius": 68.0,
			"source": source,
			"color": Color(1.0, 0.16, 0.12),
		})
		core._add_text("AMEACA", core.player_pos + Vector2(0, -112), Color(1.0, 0.36, 0.18), 0.62, 17)
		threat_timer = THREAT_INTERVAL


func _emit_acquisition(entry: Dictionary) -> void:
	var rarity: String = String(entry.get("rarity", "common"))
	var rarity_power: float = float({"common": 1.0, "uncommon": 1.3, "rare": 1.65, "legendary": 2.0}.get(rarity, 1.0))
	var color: Color = Color(entry.get("color", Color.WHITE))
	_emit_effect({
		"kind": "card_power_acquired",
		"pos": core.player_pos,
		"life": 0.92,
		"max": 0.92,
		"radius": 76.0 + 18.0 * float(rarity_power),
		"power": rarity_power,
		"color": color,
	})
	var copies: int = int(entry.get("copies", 1))
	var copy_text: String = " +%d" % copies if copies > 1 else ""
	core._add_text("PODER%s  %s x%d" % [copy_text, String(entry.get("name", "CARTA")), int(entry.get("stack", 1))], core.player_pos + Vector2(0, -108), color, 1.05, 20)
	core.screen_shake_timer = maxf(core.screen_shake_timer, 0.12)
	core.screen_shake_strength = maxf(core.screen_shake_strength, 2.8 + 1.6 * float(rarity_power))
	core._vibrate(34 + int(18.0 * float(rarity_power)), 0.18 + 0.08 * float(rarity_power))


func _emit_effect(data: Dictionary) -> void:
	var active_feedback := 0
	var oldest_index := -1
	for index in range(core.common_card_effects.size()):
		var effect: Dictionary = Dictionary(core.common_card_effects[index])
		if String(effect.get("kind", "")).begins_with("card_") or String(effect.get("kind", "")) == "enemy_threat_impact":
			active_feedback += 1
			if oldest_index < 0:
				oldest_index = index
	if active_feedback >= MAX_ACTIVE_FEEDBACK_EFFECTS and oldest_index >= 0:
		core.common_card_effects.remove_at(oldest_index)
	core.common_card_effects.append(data)
