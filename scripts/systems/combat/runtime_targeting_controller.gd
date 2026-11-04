class_name RTRuntimeTargetingController
extends RefCounted

var core: Node


func configure(runtime_core: Node) -> void:
	core = runtime_core


func auto_attack_target_position() -> Vector2:
	var locked_pos: Vector2 = core._locked_attack_target_pos()
	if locked_pos != Vector2.ZERO:
		return locked_pos
	var clone_target := boss_clone_target_position(true)
	var best_enemy := auto_target_enemy()
	if not best_enemy.is_empty():
		if clone_target != Vector2.ZERO and core.auto_target_priority == "nearest" and core.player_pos.distance_squared_to(clone_target) < core.player_pos.distance_squared_to(best_enemy["pos"]):
			return clone_target
		if core.auto_target_priority == "nearest" and core._boss_available_for_auto_target():
			var enemy_distance: float = core.player_pos.distance_squared_to(best_enemy["pos"])
			if core._pos_in_auto_attack_range(core.boss_pos) and core.player_pos.distance_squared_to(core.boss_pos) < enemy_distance:
				return core.boss_pos
		if core.auto_target_priority == "nearest" and core._arauto_active() and core._pos_in_auto_attack_range(Vector2(core.arauto["pos"])):
			var enemy_distance: float = core.player_pos.distance_squared_to(best_enemy["pos"])
			if core.player_pos.distance_squared_to(Vector2(core.arauto["pos"])) < enemy_distance:
				return Vector2(core.arauto["pos"])
		return Vector2(best_enemy["pos"])
	if clone_target != Vector2.ZERO:
		return clone_target
	if core._boss_available_for_auto_target() and core._pos_in_auto_attack_range(core.boss_pos):
		return core.boss_pos
	if core._arauto_active() and core._pos_in_auto_attack_range(Vector2(core.arauto["pos"])):
		return Vector2(core.arauto["pos"])
	return Vector2.ZERO


func ability_target_position() -> Vector2:
	var locked_pos: Vector2 = core._locked_attack_target_pos()
	if locked_pos != Vector2.ZERO:
		return locked_pos
	var candidates: Array[Dictionary] = []
	for enemy_value in core.enemies:
		var enemy: Dictionary = enemy_value
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var position := Vector2(enemy.get("pos", core.player_pos))
		candidates.append(_candidate(position, float(enemy.get("hp", INF)), float(enemy.get("max_hp", INF))))
	var clone_target := boss_clone_target_position(false)
	if clone_target != Vector2.ZERO:
		candidates.append(_candidate(clone_target, INF, INF))
	if core._boss_available_for_auto_target():
		candidates.append(_candidate(core.boss_pos, float(core.boss_hp), float(core.boss_hp_max)))
	if core._arauto_active():
		var arauto_pos := Vector2(core.arauto.get("pos", core.player_pos))
		candidates.append(_candidate(arauto_pos, float(core.arauto.get("hp", INF)), float(core.arauto.get("max_hp", INF))))
	if candidates.is_empty():
		return Vector2.ZERO
	var priority := String(core.auto_target_priority)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var metric_a: float = float(a["distance"])
		var metric_b: float = float(b["distance"])
		if priority in ["hp_low", "lowest_hp"]:
			metric_a = float(a["hp"])
			metric_b = float(b["hp"])
		elif priority in ["max_hp_low", "lowest_max_hp"]:
			metric_a = float(a["max_hp"])
			metric_b = float(b["max_hp"])
		if is_equal_approx(metric_a, metric_b):
			return float(a["distance"]) < float(b["distance"])
		return metric_a < metric_b
	)
	return Vector2(candidates[0]["pos"])


func auto_target_enemy() -> Dictionary:
	var best: Dictionary = {}
	var best_metric := INF
	var best_distance := INF
	for enemy_value in core.enemies:
		var enemy: Dictionary = enemy_value
		var distance: float = core.player_pos.distance_squared_to(enemy["pos"])
		if distance > core._auto_attack_range_squared():
			continue
		var metric := distance
		match core.auto_target_priority:
			"max_hp_low":
				metric = float(enemy.get("max_hp", INF)) + sqrt(distance) * 0.018
			"hp_low":
				metric = float(enemy.get("hp", INF)) + sqrt(distance) * 0.018
		if metric < best_metric or (is_equal_approx(metric, best_metric) and distance < best_distance):
			best_metric = metric
			best_distance = distance
			best = enemy
	return best


func boss_clone_target_position(respect_auto_attack_range: bool) -> Vector2:
	if core.current_phase != 3 or not core._boss3_miasma_active() or core.boss3_miasma_variant != 1 or core.boss3_miasma_clone_reveal_timer > 0.0 or core.boss3_miasma_clone_mislead_timer > 0.0:
		return Vector2.ZERO
	var nearest := Vector2.ZERO
	var nearest_distance := INF
	for clone_pos_data in core.boss3_miasma_clone_positions:
		var clone_pos := Vector2(clone_pos_data)
		if respect_auto_attack_range and not core._pos_in_auto_attack_range(clone_pos):
			continue
		var distance: float = core.player_pos.distance_squared_to(clone_pos)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = clone_pos
	return nearest


func _candidate(position: Vector2, hp: float, max_hp: float) -> Dictionary:
	return {
		"pos": position,
		"distance": core.player_pos.distance_squared_to(position),
		"hp": hp,
		"max_hp": max_hp,
	}
