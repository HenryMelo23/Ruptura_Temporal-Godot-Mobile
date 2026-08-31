class_name RTTeamRevivalState
extends RefCounted

var active: bool = false
var dead_peers: Array = []
var dead_names: Dictionary = {}
var dead_positions: Dictionary = {}
var fragments: Array = []
var fragments_collected: int = 0
var timer: float = 0.0
var total_time: float = 0.0
var altars_active: bool = false
var altar_life_pos: Vector2 = Vector2.ZERO
var altar_points_pos: Vector2 = Vector2.ZERO
var notice: String = ""
var fragments_suspended: bool = false
var fragment_respawn_timer: float = 0.0
var state_sync_timer: float = 0.0


func clear() -> void:
	active = false
	dead_peers.clear()
	dead_names.clear()
	dead_positions.clear()
	fragments.clear()
	fragments_collected = 0
	timer = 0.0
	total_time = 0.0
	altars_active = false
	altar_life_pos = Vector2.ZERO
	altar_points_pos = Vector2.ZERO
	notice = ""
	fragments_suspended = false
	fragment_respawn_timer = 0.0
	state_sync_timer = 0.0


func load_legacy_state(
	p_active: bool,
	p_dead_peers: Array,
	p_dead_names: Dictionary,
	p_dead_positions: Dictionary,
	p_fragments: Array,
	p_fragments_collected: int,
	p_timer: float,
	p_total_time: float,
	p_altars_active: bool,
	p_altar_life_pos: Vector2,
	p_altar_points_pos: Vector2,
	p_notice: String,
	p_fragments_suspended: bool,
	p_fragment_respawn_timer: float,
	p_state_sync_timer: float
) -> void:
	active = p_active
	dead_peers = p_dead_peers.duplicate()
	dead_names = p_dead_names.duplicate()
	dead_positions = p_dead_positions.duplicate()
	fragments = p_fragments.duplicate(true)
	fragments_collected = p_fragments_collected
	timer = maxf(0.0, p_timer)
	total_time = maxf(0.0, p_total_time)
	altars_active = p_altars_active
	altar_life_pos = p_altar_life_pos
	altar_points_pos = p_altar_points_pos
	notice = p_notice
	fragments_suspended = p_fragments_suspended
	fragment_respawn_timer = maxf(0.0, p_fragment_respawn_timer)
	state_sync_timer = maxf(0.0, p_state_sync_timer)


func export_legacy_state() -> Dictionary:
	return {
		"active": active,
		"dead_peers": dead_peers.duplicate(),
		"dead_names": dead_names.duplicate(),
		"dead_positions": dead_positions.duplicate(),
		"fragments": fragments.duplicate(true),
		"fragments_collected": fragments_collected,
		"timer": timer,
		"total_time": total_time,
		"altars_active": altars_active,
		"altar_life_pos": altar_life_pos,
		"altar_points_pos": altar_points_pos,
		"notice": notice,
		"fragments_suspended": fragments_suspended,
		"fragment_respawn_timer": fragment_respawn_timer,
		"state_sync_timer": state_sync_timer
	}


func rpc_snapshot() -> Dictionary:
	return {
		"dead_ids": dead_peers.duplicate(),
		"names": dead_names.duplicate(),
		"positions": dead_positions.duplicate(),
		"fragments": fragments.duplicate(true),
		"timer": timer,
		"altars_active": altars_active,
		"notice": notice,
		"suspended": fragments_suspended,
		"respawn_timer": fragment_respawn_timer
	}


func register_dead(dead_peer_id: int, dead_pos: Vector2, dead_name: String, world_size: Vector2, single_time: float, multi_time: float) -> void:
	if not dead_peers.has(dead_peer_id):
		dead_peers.append(dead_peer_id)
	dead_names[dead_peer_id] = dead_name if dead_name.strip_edges() != "" else "ALIADO"
	dead_positions[dead_peer_id] = dead_pos.clamp(Vector2(72.0, 72.0), world_size - Vector2(72.0, 72.0))
	active = true
	fragments_suspended = false
	fragment_respawn_timer = 0.0
	total_time = multi_time if dead_peers.size() > 1 else single_time
	timer = maxf(timer, total_time)
	notice = "RECONSTITUICAO: colete os fragmentos"


func has_fragments_for_dead(dead_peer_id: int) -> bool:
	for fragment in fragments:
		if int(Dictionary(fragment).get("dead_peer", 0)) == dead_peer_id:
			return true
	return false


func generate_fragments_for_dead(dead_peer_id: int, dead_pos: Vector2, world_size: Vector2, count: int, time_alive: float, rng: RandomNumberGenerator) -> void:
	var base_angle: float = float(dead_peer_id % 13) * 0.37 + time_alive * 0.11
	for i in range(count):
		var id: int = dead_peer_id * 1000 + i
		var angle: float = base_angle + TAU * float(i) / float(count)
		var ring: float = 170.0 + 72.0 * float(i % 3)
		var jitter := Vector2(rng.randf_range(-58.0, 58.0), rng.randf_range(-58.0, 58.0))
		var pos: Vector2 = (dead_pos + Vector2.from_angle(angle) * ring + jitter).clamp(Vector2(58.0, 58.0), world_size - Vector2(58.0, 58.0))
		fragments.append({
			"id": id,
			"dead_peer": dead_peer_id,
			"origin": dead_pos,
			"pos": pos,
			"home": pos,
			"collected": false,
			"phase": rng.randf() * TAU,
			"wander": rng.randf() * TAU,
			"drift_dir": Vector2.from_angle(rng.randf() * TAU)
		})


func reset_fragments_for_active_dead(world_size: Vector2, count: int, single_time: float, multi_time: float, time_alive: float, rng: RandomNumberGenerator) -> void:
	fragments.clear()
	fragments_collected = 0
	altars_active = false
	for dead_peer_id in dead_peers.duplicate():
		var peer_id: int = int(dead_peer_id)
		var dead_pos: Vector2 = Vector2(dead_positions.get(peer_id, world_size * 0.5))
		generate_fragments_for_dead(peer_id, dead_pos, world_size, count, time_alive, rng)
	fragments_suspended = false
	fragment_respawn_timer = 0.0
	total_time = multi_time if dead_peers.size() > 1 else single_time
	timer = total_time
	notice = "FRAGMENTOS REFORMADOS: colete novamente"


func suspend_fragments(respawn_time: float) -> void:
	fragments.clear()
	fragments_collected = 0
	altars_active = false
	fragments_suspended = true
	fragment_respawn_timer = respawn_time
	state_sync_timer = 0.0
	timer = 0.0
	notice = "FRAGMENTOS DISSIPADOS: retornam em 3 min"
	altar_life_pos = Vector2.ZERO
	altar_points_pos = Vector2.ZERO


func update_fragment_drift(delta: float, world_size: Vector2, speed: float, rng: RandomNumberGenerator) -> void:
	if fragments_suspended or altars_active:
		return
	for i in range(fragments.size()):
		var fragment: Dictionary = fragments[i]
		if bool(fragment.get("collected", false)):
			continue
		var pos: Vector2 = Vector2(fragment.get("pos", Vector2.ZERO))
		var home: Vector2 = Vector2(fragment.get("home", pos))
		var phase: float = float(fragment.get("phase", 0.0)) + delta * 1.65
		var wander: float = float(fragment.get("wander", 0.0)) + delta * rng.randf_range(0.35, 0.72)
		var drift_dir: Vector2 = Vector2(fragment.get("drift_dir", Vector2.RIGHT))
		var drift: Vector2 = drift_dir.rotated(sin(wander) * 0.62) * speed * delta
		var anchor_pull: Vector2 = (home - pos) * clampf(delta * 0.08, 0.0, 1.0)
		pos = (pos + drift + anchor_pull).clamp(Vector2(48.0, 48.0), world_size - Vector2(48.0, 48.0))
		if pos.distance_to(home) > 220.0:
			drift_dir = (home - pos).normalized()
		elif rng.randf() < delta * 0.18:
			drift_dir = Vector2.from_angle(rng.randf() * TAU)
		fragment["pos"] = pos
		fragment["phase"] = phase
		fragment["wander"] = wander
		fragment["drift_dir"] = drift_dir
		fragments[i] = fragment


func refresh_collection_state(world_size: Vector2, altar_spacing: float) -> void:
	fragments_collected = 0
	for fragment in fragments:
		if bool(Dictionary(fragment).get("collected", false)):
			fragments_collected += 1
	if active and not fragments_suspended and fragments.size() > 0 and fragments_collected >= fragments.size():
		activate_altars(world_size, altar_spacing)


func activate_altars(world_size: Vector2, altar_spacing: float) -> void:
	altars_active = true
	var center: Vector2 = (world_size * 0.5).clamp(Vector2(140.0, 140.0), world_size - Vector2(140.0, 140.0))
	altar_life_pos = center + Vector2(-altar_spacing, 0.0)
	altar_points_pos = center + Vector2(altar_spacing, 0.0)
	notice = "FRAGMENTOS COMPLETOS: escolha um altar"


func dead_count() -> int:
	return maxi(1, dead_peers.size())


func life_sacrifice_rate(single_rate: float, multi_rate: float, reduction: float) -> float:
	var base_rate: float = multi_rate if dead_count() > 1 else single_rate
	return base_rate * (1.0 - reduction)


func points_cost(base_cost: int) -> int:
	return max(1, base_cost * dead_count())


func altar_method(player_pos: Vector2, is_dead: bool, spectator: bool, radius: float, life_method: String, points_method: String) -> String:
	if not active or not altars_active or is_dead or spectator:
		return ""
	var life_distance: float = player_pos.distance_to(altar_life_pos)
	var points_distance: float = player_pos.distance_to(altar_points_pos)
	if life_distance <= radius and (life_distance <= points_distance or points_distance > radius):
		return life_method
	if points_distance <= radius:
		return points_method
	return ""


func try_collect_fragment(fragment_id: int, collector_pos: Vector2, pickup_radius: float, grace: float) -> Dictionary:
	if not active or altars_active or fragments_suspended:
		return {"collected": false}
	for i in range(fragments.size()):
		var fragment: Dictionary = fragments[i]
		if int(fragment.get("id", 0)) != fragment_id or bool(fragment.get("collected", false)):
			continue
		var fragment_pos: Vector2 = Vector2(fragment.get("pos", Vector2.ZERO))
		if collector_pos.distance_to(fragment_pos) > pickup_radius + grace:
			return {"collected": false, "out_of_range": true}
		var next_count: int = fragments_collected + 1
		fragment["collected"] = true
		fragments[i] = fragment
		notice = "FRAGMENTO %d/%d" % [next_count, fragments.size()]
		return {"collected": true, "pos": fragment_pos}
	return {"collected": false}


func apply_network_state(dead_ids: Array, names: Dictionary, positions: Dictionary, p_fragments: Array, p_timer: float, p_altars_active: bool, p_notice: String, suspended: bool, respawn_timer: float, single_time: float, multi_time: float, world_size: Vector2, altar_spacing: float) -> void:
	active = dead_ids.size() > 0
	dead_peers = dead_ids.duplicate()
	dead_names = names.duplicate()
	dead_positions = positions.duplicate()
	fragments = p_fragments.duplicate(true)
	timer = maxf(0.0, p_timer)
	total_time = multi_time if dead_ids.size() > 1 else single_time
	altars_active = p_altars_active
	notice = p_notice
	fragments_suspended = suspended
	fragment_respawn_timer = maxf(0.0, respawn_timer)
	if altars_active and not fragments_suspended:
		activate_altars(world_size, altar_spacing)
	refresh_collection_state(world_size, altar_spacing)
