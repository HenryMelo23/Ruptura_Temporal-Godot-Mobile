class_name RTNetContract
extends RefCounted

const PLAYER_SYNC_INTERVAL_MS: = 16
const WORLD_SYNC_INTERVAL_MS: = 25
const WORLD_VISUAL_SYNC_INTERVAL_MS: = 33
const PING_INTERVAL_MS: = 250
const CHANNEL_COUNT: = 5
const PLAYER_CHANNEL: = 1
const WORLD_CHANNEL: = 2
const CONTROL_CHANNEL: = 3
const VISUAL_CHANNEL: = 4
const DEDICATED_SERVER_NET_FPS: = 120
const INTERPOLATION_SHARPNESS: = 30.0
const EXTRAPOLATION_LIMIT: = 0.06
const SNAP_DISTANCE: = 360.0
const ENEMY_STRIDE: = 34
const UID_CHUNK_MASK: = 65535
const BULLET_STRIDE: = 11
const OWNER_CONNECT_TIMEOUT_MS: = 30000
const PRELOAD_TIMEOUT_MS: = 20000
const MANIFEST_SYNC_INTERVAL_MS: = 45
const REPORT_INTERVAL_MS: = 30000
const REPORT_EVENT_LIMIT: = 180
const ABILITY_ATTACK: = 0
const ABILITY_SKILL: = 1
const ABILITY_SECONDARY: = 2
const ABILITY_TELEPORT: = 3
const ABILITY_SECONDARY_END: = 4
const ABILITY_VISUAL_LIMIT: = 48
const REWIND_VISUAL_LIMIT: = 8
const ANIM_IDLE: = 0
const ANIM_UP: = 1
const ANIM_DOWN: = 2
const ANIM_RIGHT: = 3
const ANIM_FIRE: = 4
const ANIM_DAMAGE: = 5
const ANIM_LACERANTE: = 6
const ANIM_FROZEN: = 7
const DAMAGE_ENEMY: = 0
const DAMAGE_BOSS: = 1
const DAMAGE_ARAUTO: = 2


static func estimate_packed_bytes(value) -> int:
	if value is PackedFloat32Array:
		return value.size() * 4
	if value is PackedInt32Array:
		return value.size() * 4
	if value is PackedByteArray:
		return value.size()
	if value is Array:
		return value.size() * 96
	if value is Dictionary:
		return max(64, value.size() * 40)
	return 32


static func estimate_world_bytes(enemies_data, boss_data, bullets_data) -> int:
	return 32 + estimate_packed_bytes(enemies_data) + estimate_packed_bytes(boss_data) + estimate_packed_bytes(bullets_data)


static func pack_boss(pos: Vector2, hp: float, dead: bool, active: bool, phase_index: int, hp_max: float, boss_phase: float) -> PackedFloat32Array:
	return PackedFloat32Array([
		pos.x,
		pos.y,
		hp,
		1.0 if dead else 0.0,
		1.0 if active else 0.0,
		float(phase_index),
		hp_max,
		boss_phase
	])


static func unpack_boss_snapshot(
	snapshot_data,
	fallback_pos: Vector2,
	fallback_hp: float,
	fallback_dead: bool,
	fallback_active: bool,
	fallback_phase_index: int,
	fallback_hp_max: float,
	fallback_boss_phase: float,
	has_previous_snapshot: bool
) -> Dictionary:
	var result: = {
		"valid": false,
		"pos": fallback_pos,
		"hp": fallback_hp,
		"dead": fallback_dead,
		"active": fallback_active,
		"phase_index": fallback_phase_index,
		"hp_max": fallback_hp_max,
		"boss_phase": fallback_boss_phase
	}
	if snapshot_data is PackedFloat32Array:
		var packed: PackedFloat32Array = snapshot_data
		if packed.size() < 4:
			return result
		result["valid"] = true
		result["pos"] = Vector2(packed[0], packed[1])
		result["hp"] = packed[2]
		result["dead"] = packed[3] > 0.5
		if packed.size() >= 5:
			result["active"] = packed[4] > 0.5 and not bool(result["dead"])
		elif float(result["hp"]) > 0.0 and not bool(result["dead"]) and has_previous_snapshot:
			result["active"] = true
		if packed.size() >= 6:
			result["phase_index"] = clampi(int(packed[5]), 1, 6)
		if packed.size() >= 7:
			result["hp_max"] = max(1.0, packed[6])
		if packed.size() >= 8:
			result["boss_phase"] = packed[7]
	elif snapshot_data is Dictionary:
		var data: Dictionary = snapshot_data
		result["valid"] = true
		result["pos"] = Vector2(data.get("pos", fallback_pos))
		result["hp"] = data.get("hp", fallback_hp)
		result["dead"] = data.get("dead", fallback_dead)
		result["active"] = bool(data.get("active", fallback_active)) and not bool(result["dead"])
		result["phase_index"] = int(data.get("phase_index", fallback_phase_index))
		result["hp_max"] = max(1.0, float(data.get("hp_max", fallback_hp_max)))
	return result


static func pack_enemies(enemies: Array, enemy_types: Array, default_enemy_type: String, leech_states: Array, dormant_leech_state: String) -> PackedFloat32Array:
	var packed: = PackedFloat32Array()
	packed.resize(enemies.size() * ENEMY_STRIDE)
	var offset: = 0
	for enemy_value in enemies:
		if not enemy_value is Dictionary:
			offset += ENEMY_STRIDE
			continue
		var enemy: Dictionary = enemy_value
		var uid: = int(enemy.get("uid", 0))
		var pos: = Vector2(enemy.get("pos", Vector2.ZERO))
		var facing_value = enemy.get("facing_dir", Vector2.RIGHT)
		var facing: Vector2 = facing_value if facing_value is Vector2 else Vector2(float(facing_value), 0.0)
		var last_move: = Vector2(enemy.get("last_move_dir", Vector2.ZERO))
		packed[offset] = float(uid & UID_CHUNK_MASK)
		packed[offset + 1] = float((uid >> 16) & UID_CHUNK_MASK)
		packed[offset + 2] = float(maxi(0, enemy_types.find(String(enemy.get("type", default_enemy_type)))))
		packed[offset + 3] = pos.x
		packed[offset + 4] = pos.y
		packed[offset + 5] = float(enemy.get("hp", 0.0))
		packed[offset + 6] = float(enemy.get("max_hp", enemy.get("hp", 1.0)))
		packed[offset + 7] = float(enemy.get("phase", 0.0))
		packed[offset + 8] = float(enemy.get("shield_flash", 0.0))
		packed[offset + 9] = float(enemy.get("bit", 0))
		packed[offset + 10] = facing.x
		packed[offset + 11] = facing.y
		packed[offset + 12] = last_move.x
		packed[offset + 13] = last_move.y
		packed[offset + 14] = 1.0 if bool(enemy.get("invisible", false)) else 0.0
		packed[offset + 15] = float(enemy.get("alpha", 1.0))
		packed[offset + 16] = float(enemy.get("seeds", 0))
		packed[offset + 17] = float(enemy.get("parasite_mark_time", 0.0))
		packed[offset + 18] = float(enemy.get("tesla_shock", 0.0))
		packed[offset + 19] = 1.0 if bool(enemy.get("shield_active", true)) else 0.0
		packed[offset + 20] = float(enemy.get("reconstitute_time", 0.0))
		packed[offset + 21] = float(enemy.get("eel_relocating", 0.0))
		var eel_from: = Vector2(enemy.get("eel_relocate_from", pos))
		var eel_to: = Vector2(enemy.get("eel_relocate_to", pos))
		packed[offset + 22] = eel_from.x
		packed[offset + 23] = eel_from.y
		packed[offset + 24] = eel_to.x
		packed[offset + 25] = eel_to.y
		packed[offset + 26] = float(enemy.get("eel_relocate_bend", 0.0))
		packed[offset + 27] = float(maxi(0, leech_states.find(String(enemy.get("leech_state", dormant_leech_state)))))
		packed[offset + 28] = float(enemy.get("leech_timer", 0.0))
		packed[offset + 29] = float(enemy.get("leech_life", 0.0))
		var leech_to: = Vector2(enemy.get("leech_leap_to", pos))
		packed[offset + 30] = leech_to.x
		packed[offset + 31] = leech_to.y
		packed[offset + 32] = float(enemy.get("leech_target_peer", 0))
		packed[offset + 33] = 1.0 if bool(enemy.get("boss6_summoned", false)) else 0.0
		offset += ENEMY_STRIDE
	return packed


static func unpack_enemy_snapshot(snapshot_data, existing_by_uid: Dictionary, enemy_types: Array, default_enemy_type: String, leech_states: Array, chronal_leech_type: String, now_ms: int) -> Array:
	var next_enemies: Array = []
	if snapshot_data is PackedFloat32Array:
		var packed: PackedFloat32Array = snapshot_data
		for offset in range(0, packed.size() - ENEMY_STRIDE + 1, ENEMY_STRIDE):
			var uid: = int(packed[offset]) | (int(packed[offset + 1]) << 16)
			var incoming_pos: = Vector2(packed[offset + 3], packed[offset + 4])
			var enemy: Dictionary = existing_by_uid.get(uid, {})
			apply_entity_motion(enemy, incoming_pos, now_ms)
			enemy["uid"] = uid
			var type_index: = clampi(int(packed[offset + 2]), 0, enemy_types.size() - 1)
			enemy["type"] = enemy_types[type_index] if not enemy_types.is_empty() else default_enemy_type
			enemy["hp"] = packed[offset + 5]
			enemy["max_hp"] = packed[offset + 6]
			enemy["phase"] = packed[offset + 7]
			enemy["shield_flash"] = packed[offset + 8]
			enemy["bit"] = int(packed[offset + 9])
			enemy["facing_dir"] = Vector2(packed[offset + 10], packed[offset + 11])
			enemy["last_move_dir"] = Vector2(packed[offset + 12], packed[offset + 13])
			enemy["invisible"] = packed[offset + 14] > 0.5
			enemy["alpha"] = packed[offset + 15]
			enemy["seeds"] = int(packed[offset + 16])
			enemy["parasite_mark_time"] = packed[offset + 17]
			enemy["tesla_shock"] = packed[offset + 18]
			enemy["shield_active"] = packed[offset + 19] > 0.5
			enemy["reconstitute_time"] = packed[offset + 20]
			enemy["eel_relocating"] = packed[offset + 21]
			enemy["eel_relocate_from"] = Vector2(packed[offset + 22], packed[offset + 23])
			enemy["eel_relocate_to"] = Vector2(packed[offset + 24], packed[offset + 25])
			enemy["eel_relocate_bend"] = packed[offset + 26]
			if String(enemy["type"]) == chronal_leech_type:
				var leech_index: = clampi(int(packed[offset + 27]), 0, leech_states.size() - 1)
				var leech_state: String = String(leech_states[leech_index]) if not leech_states.is_empty() else ""
				enemy["leech_state"] = leech_state
				enemy["state"] = leech_state
				enemy["leech_timer"] = packed[offset + 28]
				enemy["leech_life"] = packed[offset + 29]
				enemy["leech_leap_to"] = Vector2(packed[offset + 30], packed[offset + 31])
				enemy["leech_target_peer"] = int(packed[offset + 32])
				enemy["boss6_summoned"] = packed[offset + 33] > 0.5
			next_enemies.append(enemy)
		return next_enemies
	if snapshot_data is Array:
		for item in snapshot_data:
			if not item is Dictionary:
				continue
			var incoming: Dictionary = item
			var uid: = int(incoming.get("uid", -1))
			var enemy: Dictionary = existing_by_uid.get(uid, {})
			apply_entity_motion(enemy, Vector2(incoming.get("pos", Vector2.ZERO)), now_ms)
			for key in incoming.keys():
				if key != "pos":
					enemy[key] = incoming[key]
			next_enemies.append(enemy)
	return next_enemies


static func apply_entity_motion(entity: Dictionary, incoming_pos: Vector2, now_ms: int) -> void:
	if entity.is_empty():
		entity["pos"] = incoming_pos
		entity["_net_velocity"] = Vector2.ZERO
	else:
		var previous_target: = Vector2(entity.get("_net_target_pos", entity.get("pos", incoming_pos)))
		var previous_ms: = int(entity.get("_net_snapshot_ms", now_ms))
		var elapsed: = maxf(float(PLAYER_SYNC_INTERVAL_MS) / 1000.0, float(now_ms - previous_ms) / 1000.0)
		if previous_target.distance_squared_to(incoming_pos) >= SNAP_DISTANCE * SNAP_DISTANCE:
			entity["pos"] = incoming_pos
			entity["_net_velocity"] = Vector2.ZERO
		else:
			entity["_net_velocity"] = (incoming_pos - previous_target) / elapsed
	entity["_net_target_pos"] = incoming_pos
	entity["_net_snapshot_ms"] = now_ms


static func pack_enemy_bullets(enemy_bullets: Array, bullet_types: Array, next_uid: int) -> Dictionary:
	var packed: = PackedFloat32Array()
	packed.resize(enemy_bullets.size() * BULLET_STRIDE)
	var offset: = 0
	for bullet_value in enemy_bullets:
		if not bullet_value is Dictionary:
			offset += BULLET_STRIDE
			continue
		var bullet: Dictionary = bullet_value
		if not bullet.has("_net_uid"):
			bullet["_net_uid"] = next_uid
			next_uid += 1
		var pos: = Vector2(bullet.get("pos", Vector2.ZERO))
		var direction: = Vector2(bullet.get("dir", Vector2.ZERO))
		packed[offset] = float(bullet.get("_net_uid", 0))
		packed[offset + 1] = pos.x
		packed[offset + 2] = pos.y
		packed[offset + 3] = direction.x
		packed[offset + 4] = direction.y
		packed[offset + 5] = float(bullet.get("life", 0.0))
		packed[offset + 6] = float(bullet.get("damage", 0.0))
		packed[offset + 7] = float(maxi(0, bullet_types.find(String(bullet.get("type", "")))))
		packed[offset + 8] = float(bullet.get("radius", 0.0))
		packed[offset + 9] = float(bullet.get("phase", 0.0))
		packed[offset + 10] = float(bullet.get("speed_mult", 1.0))
		offset += BULLET_STRIDE
	return {"packed": packed, "next_uid": next_uid}


static func unpack_bullet_snapshot(snapshot_data, existing_by_uid: Dictionary, bullet_types: Array, now_ms: int):
	if not snapshot_data is PackedFloat32Array:
		return snapshot_data
	var next_bullets: Array = []
	var packed: PackedFloat32Array = snapshot_data
	for offset in range(0, packed.size() - BULLET_STRIDE + 1, BULLET_STRIDE):
		var uid: = int(packed[offset])
		var incoming_pos: = Vector2(packed[offset + 1], packed[offset + 2])
		var bullet: Dictionary = existing_by_uid.get(uid, {})
		apply_entity_motion(bullet, incoming_pos, now_ms)
		bullet["_net_uid"] = uid
		bullet["dir"] = Vector2(packed[offset + 3], packed[offset + 4])
		bullet["life"] = packed[offset + 5]
		bullet["damage"] = packed[offset + 6]
		var type_index: = clampi(int(packed[offset + 7]), 0, bullet_types.size() - 1)
		bullet["type"] = bullet_types[type_index] if not bullet_types.is_empty() else ""
		bullet["radius"] = packed[offset + 8]
		bullet["phase"] = packed[offset + 9]
		bullet["speed_mult"] = packed[offset + 10]
		next_bullets.append(bullet)
	return next_bullets


static func merged_remote_player_state(current_state: Dictionary, incoming: Dictionary) -> Dictionary:
	var state: Dictionary = current_state.duplicate(true)
	for key in incoming.keys():
		state[key] = incoming[key]
	return state


static func legacy_remote_peer_id(players_by_peer: Dictionary, preferred_peer_id: int) -> int:
	if preferred_peer_id != 0 and players_by_peer.has(preferred_peer_id):
		return preferred_peer_id
	var keys: = players_by_peer.keys()
	if keys.is_empty():
		return 0
	keys.sort()
	return int(keys[0])
