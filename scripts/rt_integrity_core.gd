extends RefCounted
class_name RTIntegrityCore

const STATUS_VALID: = "valid"
const STATUS_INVALID: = "invalid"

const EVENT_RUN_STARTED: = "RUN_STARTED"
const EVENT_PHASE_STARTED: = "PHASE_STARTED"
const EVENT_ENEMY_SPAWNED: = "ENEMY_SPAWNED"
const EVENT_ENEMY_DAMAGED: = "ENEMY_DAMAGED"
const EVENT_ENEMY_KILLED: = "ENEMY_KILLED"
const EVENT_BOSS_DAMAGED: = "BOSS_DAMAGED"
const EVENT_BOSS_KILLED: = "BOSS_KILLED"
const EVENT_CARD_ACQUIRED: = "CARD_ACQUIRED"
const EVENT_CARD_REMOVED: = "CARD_REMOVED"
const EVENT_CARD_CONSUMED: = "CARD_CONSUMED"
const EVENT_MONEY_GAINED: = "MONEY_GAINED"
const EVENT_PURCHASE_CONFIRMED: = "PURCHASE_CONFIRMED"
const EVENT_SCORE_REWARD_CONFIRMED: = "SCORE_REWARD_CONFIRMED"
const EVENT_ENEMY_SCALING_UNLOCKED: = "ENEMY_SCALING_UNLOCKED"
const EVENT_ENEMY_LIMIT_INCREASED: = "ENEMY_LIMIT_INCREASED"
const EVENT_PHASE_CHANGED: = "PHASE_CHANGED"
const EVENT_STATE_ADOPTED: = "STATE_ADOPTED"
const EVENT_SPECTRAL_COIN_DROPPED: = "SPECTRAL_COIN_DROPPED"
const EVENT_SPECTRAL_COIN_COLLECTED: = "SPECTRAL_COIN_COLLECTED"
const EVENT_SPECTRAL_COIN_SPENT: = "SPECTRAL_COIN_SPENT"
const EVENT_SPECTER_UPGRADED: = "SPECTER_UPGRADED"
const EVENT_SPECTER_MILESTONE_REACHED: = "SPECTER_MILESTONE_REACHED"
const EVENT_SPECTER_ASCENDED: = "SPECTER_ASCENDED"
const EVENT_RUN_FINISHED: = "RUN_FINISHED"
const EVENT_RUN_INVALIDATED: = "RUN_INVALIDATED"

const INSTALL_SECRET_PATH: = "user://rt_integrity_install.dat"
const REPORT_DIR: = "user://integrity_reports"
const HASH_NOTE: = "sha256_chain_local_corruption_check"


class ProtectedInt64:
	var _name: = ""
	var _mask: = 0
	var _seed: = 0
	var _encoded: = 0
	var _shadow: = 0
	var _complement: = 0
	var _tag: = ""

	func configure(name: String, initial_value: int, mask: int, seed: int) -> void :
		_name = name
		_mask = mask
		_seed = seed
		set_value(initial_value)

	func set_value(value: int) -> void :
		_encoded = int(value) ^ _mask
		_shadow = _shadow_for(value)
		_complement = ~ int(value)
		_tag = _tag_for(value)

	func get_value() -> int:
		var value: = int(_encoded) ^ _mask
		if not is_valid():
			return value
		return value

	func add(delta: int) -> void :
		set_value(get_value() + delta)

	func is_valid() -> bool:
		var value: = int(_encoded) ^ _mask
		return _shadow == _shadow_for(value) and _complement == ~ value and _tag == _tag_for(value)

	func _shadow_for(value: int) -> int:
		return int(value * 1315423911 + _seed * 2654435761) ^ int(_mask >> 1)

	func _tag_for(value: int) -> String:
		return _sha256_text("%s|%s|%s|%s|%s" % [_name, str(value), str(_mask), str(_seed), str(_shadow_for(value))])

	func _sha256_text(text: String) -> String:
		var hashing: = HashingContext.new()
		if hashing.start(HashingContext.HASH_SHA256) != OK:
			return ""
		hashing.update(text.to_utf8_buffer())
		return hashing.finish().hex_encode().to_lower()


var run_id: = ""
var run_nonce: = ""
var build_version: = ""
var status: = STATUS_INVALID
var invalid_reason: = ""
var invalid_context: Dictionary = {}
var sequence_id: = 0
var previous_tag: = "genesis"
var ledger: Array = []
var run_mask: = 0
var shadow_seed: = 0
var run_key: = ""
var install_secret: = ""

var protected_values: Dictionary = {}
var spawned_entities: Dictionary = {}
var killed_entities: Dictionary = {}
var boss_deaths: Dictionary = {}
var card_counts: Dictionary = {}

var current_phase: = 1
var scaling_unlocked: = false
var scaling_unlock_reason: = ""
var scaling_unlock_tick: = 0
var scaling_unlock_kill_anchor: = 0
var scaling_thresholds_applied: = 0
var enemy_limit_bonus: = 0
var finished: = false


static func sha256_text(text: String) -> String:
	var hashing: = HashingContext.new()
	if hashing.start(HashingContext.HASH_SHA256) != OK:
		return ""
	hashing.update(text.to_utf8_buffer())
	return hashing.finish().hex_encode().to_lower()


func start_run(version: String, phase: int, tick: int, base_enemy_limit: int) -> void :
	install_secret = _load_or_create_install_secret()
	var rng: = RandomNumberGenerator.new()
	rng.randomize()
	run_id = "%s-%08x" % [str(Time.get_ticks_msec()), rng.randi()]
	run_nonce = "%08x%08x" % [rng.randi(), rng.randi()]
	run_mask = int(rng.randi()) | 1
	shadow_seed = int(rng.randi()) | 1
	run_key = sha256_text("%s|%s|%s|%s" % [install_secret, run_id, run_nonce, str(tick)])
	build_version = version
	status = STATUS_VALID
	invalid_reason = ""
	invalid_context.clear()
	sequence_id = 0
	previous_tag = "genesis"
	ledger.clear()
	spawned_entities.clear()
	killed_entities.clear()
	boss_deaths.clear()
	card_counts.clear()
	finished = false
	_init_counter("score_current", 0)
	_init_counter("score_total", 0)
	_init_counter("points_earned", 0)
	_init_counter("points_spent", 0)
	_init_counter("enemy_kills", 0)
	_init_counter("cards_total", 0)
	_init_counter("boss_damage_total", 0)
	_init_counter("enemy_damage_total", 0)
	_init_counter("active_time_ms", 0)
	_init_counter("enemy_limit_bonus", 0)
	_init_counter("spectral_coins_current", 0)
	_init_counter("spectral_coins_collected", 0)
	_init_counter("spectral_coins_spent", 0)
	_init_counter("specter_level", 1)
	register_phase_started(phase, tick, base_enemy_limit)
	_append_event(EVENT_RUN_STARTED, tick, phase, {"run_id": run_id, "version": version, "nonce": run_nonce, "hash_note": HASH_NOTE})


func register_phase_started(phase: int, tick: int, base_enemy_limit: int) -> void :
	if not _can_append():
		return
	current_phase = phase
	scaling_unlocked = false
	scaling_unlock_reason = ""
	scaling_unlock_tick = 0
	scaling_unlock_kill_anchor = int(_counter("enemy_kills"))
	scaling_thresholds_applied = 0
	enemy_limit_bonus = 0
	protected_values["enemy_limit_bonus"].set_value(0)
	boss_deaths.clear()
	_append_event(EVENT_PHASE_STARTED, tick, phase, {"base_enemy_limit": base_enemy_limit, "kill_anchor": scaling_unlock_kill_anchor})


func update_active_time(delta: float) -> void :
	if status != STATUS_VALID or finished:
		return
	var add_ms: = maxi(0, int(round(delta * 1000.0)))
	protected_values["active_time_ms"].add(add_ms)


func adopt_current_state(context: Dictionary, active_enemies: Array, cards: Dictionary, phase: int, tick: int, reason: String) -> void :
	if not _can_append():
		return
	for name in protected_values.keys():
		var counter: ProtectedInt64 = protected_values[name]
		counter.set_value(int(context.get(name, counter.get_value())))
	card_counts.clear()
	for key in cards.keys():
		var amount: = int(cards[key])
		if amount > 0:
			card_counts[String(key)] = amount
	spawned_entities.clear()
	killed_entities.clear()
	for item in active_enemies:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var enemy: Dictionary = item
		var entity_id: = int(enemy.get("uid", 0))
		if entity_id == 0:
			continue
		spawned_entities[str(entity_id)] = {
			"type": String(enemy.get("type", "")), 
			"phase": int(enemy.get("phase_id", phase)), 
			"tick": tick
		}
	scaling_unlocked = bool(context.get("scaling_unlocked", scaling_unlocked))
	scaling_unlock_reason = String(context.get("scaling_unlock_reason", scaling_unlock_reason))
	scaling_unlock_tick = int(context.get("scaling_unlock_tick", scaling_unlock_tick))
	scaling_unlock_kill_anchor = int(context.get("scaling_unlock_kill_anchor", scaling_unlock_kill_anchor))
	scaling_thresholds_applied = int(context.get("scaling_thresholds_applied", scaling_thresholds_applied))
	enemy_limit_bonus = int(context.get("enemy_limit_bonus", enemy_limit_bonus))
	_append_event(EVENT_STATE_ADOPTED, tick, phase, {
		"reason": reason, 
		"active_enemies": spawned_entities.size(), 
		"cards_total": int(context.get("cards_total", 0))
	})


func register_enemy_spawn(entity_id: int, entity_type: String, phase: int, tick: int) -> void :
	if not _can_append():
		return
	var key: = str(entity_id)
	if spawned_entities.has(key):
		invalidate("duplicate_enemy_spawn", {"entity_id": entity_id, "type": entity_type, "phase": phase})
		return
	spawned_entities[key] = {"type": entity_type, "phase": phase, "tick": tick}
	_append_event(EVENT_ENEMY_SPAWNED, tick, phase, {"entity_instance_id": entity_id, "entity_type_id": entity_type})


func register_enemy_damage(entity_id: int, entity_type: String, amount: float, phase: int, tick: int, source: String) -> void :
	if not _can_append() or amount <= 0.0:
		return
	protected_values["enemy_damage_total"].add(int(round(amount)))
	_append_event(EVENT_ENEMY_DAMAGED, tick, phase, {"entity_instance_id": entity_id, "entity_type_id": entity_type, "amount": int(round(amount)), "source_id": source})


func register_enemy_killed(entity_id: int, entity_type: String, phase: int, tick: int) -> bool:
	if not _can_append():
		return false
	var key: = str(entity_id)
	if killed_entities.has(key):
		invalidate("duplicate_enemy_kill", {"entity_id": entity_id, "type": entity_type, "phase": phase})
		return false
	if not spawned_entities.has(key):
		invalidate("enemy_killed_without_spawn", {"entity_id": entity_id, "type": entity_type, "phase": phase})
		return false
	killed_entities[key] = {"type": entity_type, "phase": phase, "tick": tick}
	protected_values["enemy_kills"].add(1)
	_append_event(EVENT_ENEMY_KILLED, tick, phase, {"entity_instance_id": entity_id, "entity_type_id": entity_type})
	return true


func register_boss_damage(amount: float, phase: int, tick: int, source: String) -> void :
	if not _can_append() or amount <= 0.0:
		return
	protected_values["boss_damage_total"].add(int(round(amount)))
	_append_event(EVENT_BOSS_DAMAGED, tick, phase, {"amount": int(round(amount)), "source_id": source})


func register_boss_killed(boss_id: String, phase: int, tick: int) -> bool:
	if not _can_append():
		return false
	if boss_deaths.has(boss_id):
		return false
	boss_deaths[boss_id] = {"phase": phase, "tick": tick}
	_append_event(EVENT_BOSS_KILLED, tick, phase, {"entity_instance_id": boss_id})
	return true


func register_score_delta(amount: int, phase: int, tick: int, reason: String, counts_as_spent: = false) -> void :
	if not _can_append() or amount == 0:
		return
	if amount > 0:
		protected_values["score_current"].add(amount)
		protected_values["score_total"].add(amount)
		protected_values["points_earned"].add(amount)
		_append_event(EVENT_SCORE_REWARD_CONFIRMED, tick, phase, {"amount": amount, "reason": reason})
	else:
		var spend: int = abs(amount)
		protected_values["score_current"].add( - spend)
		if counts_as_spent:
			protected_values["points_spent"].add(spend)
		else:
			protected_values["score_total"].add( - spend)
		_append_event(EVENT_PURCHASE_CONFIRMED, tick, phase, {"amount": spend, "reason": reason, "counts_as_spent": counts_as_spent})


func register_card_acquired(card_id: String, phase: int, tick: int) -> void :
	if not _can_append():
		return
	card_counts[card_id] = int(card_counts.get(card_id, 0)) + 1
	protected_values["cards_total"].add(1)
	_append_event(EVENT_CARD_ACQUIRED, tick, phase, {"entity_type_id": card_id, "count": int(card_counts[card_id])})


func register_card_consumed(card_id: String, amount: int, phase: int, tick: int) -> void :
	if not _can_append() or amount <= 0:
		return
	var current: = int(card_counts.get(card_id, 0))
	if current < amount:
		invalidate("card_consumed_below_ledger", {"card_id": card_id, "amount": amount, "ledger_count": current})
		return
	card_counts[card_id] = current - amount
	protected_values["cards_total"].add( - amount)
	_append_event(EVENT_CARD_CONSUMED, tick, phase, {"entity_type_id": card_id, "amount": amount, "count": int(card_counts[card_id])})


func register_card_removed(card_id: String, amount: int, phase: int, tick: int) -> void :
	if not _can_append() or amount <= 0:
		return
	var current: = int(card_counts.get(card_id, 0))
	if current < amount:
		invalidate("card_removed_below_ledger", {"card_id": card_id, "amount": amount, "ledger_count": current})
		return
	card_counts[card_id] = current - amount
	protected_values["cards_total"].add( - amount)
	_append_event(EVENT_CARD_REMOVED, tick, phase, {"entity_type_id": card_id, "amount": amount, "count": int(card_counts[card_id])})


func register_spectral_coin_dropped(coin_id: int, source_entity_id: int, source_type: String, phase: int, tick: int) -> void :
	if not _can_append():
		return
	_append_event(EVENT_SPECTRAL_COIN_DROPPED, tick, phase, {"coin_id": coin_id, "source_entity_id": source_entity_id, "source_type": source_type})


func register_spectral_coin_collected(coin_id: int, amount: int, phase: int, tick: int) -> void :
	if not _can_append() or amount <= 0:
		return
	protected_values["spectral_coins_current"].add(amount)
	protected_values["spectral_coins_collected"].add(amount)
	_append_event(EVENT_SPECTRAL_COIN_COLLECTED, tick, phase, {"coin_id": coin_id, "amount": amount, "balance": int(_counter("spectral_coins_current"))})


func register_specter_upgraded(specter_id: String, previous_level: int, new_level: int, cost: int, phase: int, tick: int) -> void :
	if not _can_append():
		return
	if new_level != previous_level + 1 or new_level < 2 or new_level > 10:
		invalidate("invalid_specter_level_jump", {"specter_id": specter_id, "previous": previous_level, "new": new_level})
		return
	if cost <= 0 or int(_counter("spectral_coins_current")) < cost:
		invalidate("specter_upgrade_without_valid_cost", {"specter_id": specter_id, "cost": cost, "balance": int(_counter("spectral_coins_current"))})
		return
	protected_values["spectral_coins_current"].add( - cost)
	protected_values["spectral_coins_spent"].add(cost)
	protected_values["specter_level"].set_value(new_level)
	_append_event(EVENT_SPECTRAL_COIN_SPENT, tick, phase, {"specter_id": specter_id, "amount": cost, "balance": int(_counter("spectral_coins_current"))})
	_append_event(EVENT_SPECTER_UPGRADED, tick, phase, {"specter_id": specter_id, "previous_level": previous_level, "new_level": new_level, "cost": cost})
	if new_level == 5 or new_level == 9:
		_append_event(EVENT_SPECTER_MILESTONE_REACHED, tick, phase, {"specter_id": specter_id, "level": new_level})
	if new_level == 10:
		_append_event(EVENT_SPECTER_ASCENDED, tick, phase, {"specter_id": specter_id, "level": new_level})


func register_scaling_unlocked(reason: String, phase: int, tick: int, total_kills: int) -> void :
	if not _can_append() or scaling_unlocked:
		return
	scaling_unlocked = true
	scaling_unlock_reason = reason
	scaling_unlock_tick = tick
	scaling_unlock_kill_anchor = total_kills
	scaling_thresholds_applied = 0
	enemy_limit_bonus = 0
	protected_values["enemy_limit_bonus"].set_value(0)
	_append_event(EVENT_ENEMY_SCALING_UNLOCKED, tick, phase, {"reason": reason, "total_kills": total_kills, "anchor": scaling_unlock_kill_anchor})


func register_enemy_limit_increased(phase: int, threshold: int, kills_since_unlock: int, previous_limit: int, new_limit: int, tick: int) -> void :
	if not _can_append():
		return
	scaling_thresholds_applied = threshold
	enemy_limit_bonus = max(0, new_limit - previous_limit + enemy_limit_bonus)
	protected_values["enemy_limit_bonus"].set_value(enemy_limit_bonus)
	_append_event(EVENT_ENEMY_LIMIT_INCREASED, tick, phase, {
		"threshold": threshold, 
		"kills_since_unlock": kills_since_unlock, 
		"previous_limit": previous_limit, 
		"new_limit": new_limit
	})


func finish_run(result: String, phase: int, tick: int) -> Dictionary:
	if status == STATUS_VALID and not finished:
		_append_event(EVENT_RUN_FINISHED, tick, phase, {"result": result})
	finished = true
	return make_certificate(result, phase, tick)


func validate_state(context: Dictionary) -> bool:
	if status != STATUS_VALID:
		return false
	for name in protected_values.keys():
		var counter: ProtectedInt64 = protected_values[name]
		if not counter.is_valid():
			invalidate("protected_value_diverged", {"counter": name})
			return false
	var expected: = {
		"score_current": int(context.get("score_current", 0)), 
		"score_total": int(context.get("score_total", 0)), 
		"points_earned": int(context.get("points_earned", 0)), 
		"points_spent": int(context.get("points_spent", 0)), 
		"enemy_kills": int(context.get("enemy_kills", 0)), 
		"cards_total": int(context.get("cards_total", 0)), 
		"enemy_limit_bonus": int(context.get("enemy_limit_bonus", 0)), 
		"spectral_coins_current": int(context.get("spectral_coins_current", 0)), 
		"spectral_coins_collected": int(context.get("spectral_coins_collected", 0)), 
		"spectral_coins_spent": int(context.get("spectral_coins_spent", 0)), 
		"specter_level": int(context.get("specter_level", 1))
	}
	for key in expected.keys():
		if int(_counter(key)) != int(expected[key]):
			invalidate("ledger_state_mismatch", {"field": key, "ledger": int(_counter(key)), "game": int(expected[key])})
			return false
	var expected_bonus: = int(context.get("expected_enemy_limit_bonus", int(expected["enemy_limit_bonus"])))
	if int(_counter("enemy_limit_bonus")) != expected_bonus:
		invalidate("enemy_limit_bonus_mismatch", {"ledger": int(_counter("enemy_limit_bonus")), "expected": expected_bonus})
		return false
	return _validate_ledger_chain()


func make_certificate(result: String, phase: int, tick: int) -> Dictionary:
	var data: = {
		"run_id": run_id, 
		"build_version": build_version, 
		"status": status, 
		"result": result if status == STATUS_VALID else "Invalidada", 
		"phase": phase, 
		"tick": tick, 
		"active_time_ms": int(_counter("active_time_ms")), 
		"score_current": int(_counter("score_current")), 
		"score_total": int(_counter("score_total")), 
		"points_earned": int(_counter("points_earned")), 
		"points_spent": int(_counter("points_spent")), 
		"kills": int(_counter("enemy_kills")), 
		"cards_total": int(_counter("cards_total")), 
		"boss_damage_total": int(_counter("boss_damage_total")), 
		"enemy_damage_total": int(_counter("enemy_damage_total")), 
		"enemy_limit_bonus": int(_counter("enemy_limit_bonus")), 
		"spectral_coins_current": int(_counter("spectral_coins_current")), 
		"spectral_coins_collected": int(_counter("spectral_coins_collected")), 
		"spectral_coins_spent": int(_counter("spectral_coins_spent")), 
		"specter_level": int(_counter("specter_level")), 
		"scaling_unlocked": scaling_unlocked, 
		"scaling_unlock_reason": scaling_unlock_reason, 
		"scaling_unlock_tick": scaling_unlock_tick, 
		"scaling_unlock_kill_anchor": scaling_unlock_kill_anchor, 
		"scaling_thresholds_applied": scaling_thresholds_applied, 
		"ledger_events": ledger.size(), 
		"ledger_final_tag": previous_tag, 
		"hash_note": HASH_NOTE
	}
	data["certificate_tag"] = sha256_text(_stable_dict_text(data) + "|key=" + run_key)
	return data


func invalidate(reason: String, context: Dictionary = {}) -> void :
	if status == STATUS_INVALID:
		return
	status = STATUS_INVALID
	invalid_reason = reason
	invalid_context = context.duplicate(true)
	_append_event(EVENT_RUN_INVALIDATED, int(context.get("tick", 0)), int(context.get("phase", current_phase)), {"reason": reason, "context": _stable_dict_text(context)}, true)
	_write_tamper_report()


func _init_counter(name: String, initial_value: int) -> void :
	var counter: = ProtectedInt64.new()
	counter.configure(name, initial_value, run_mask ^ name.hash(), shadow_seed ^ (name.hash() << 1))
	protected_values[name] = counter


func _counter(name: String) -> int:
	if not protected_values.has(name):
		return 0
	var counter: ProtectedInt64 = protected_values[name]
	return counter.get_value()


func _can_append() -> bool:
	return status == STATUS_VALID and not finished


func _append_event(event_type: String, tick: int, phase: int, data: Dictionary = {}, allow_invalid_event: = false) -> void :
	if finished and not allow_invalid_event:
		return
	if status != STATUS_VALID and not allow_invalid_event:
		return
	sequence_id += 1
	var event: = {
		"sequence_id": sequence_id, 
		"simulation_tick": tick, 
		"event_type": event_type, 
		"phase_id": phase, 
		"previous_tag": previous_tag, 
		"data": data.duplicate(true)
	}
	event["tag"] = sha256_text(_stable_dict_text(event) + "|key=" + run_key)
	previous_tag = String(event["tag"])
	ledger.append(event)


func _validate_ledger_chain() -> bool:
	var prev: = "genesis"
	var expected_seq: = 1
	for event in ledger:
		if int(event.get("sequence_id", 0)) != expected_seq:
			invalidate("ledger_sequence_gap", {"expected": expected_seq, "found": int(event.get("sequence_id", 0))})
			return false
		if String(event.get("previous_tag", "")) != prev:
			invalidate("ledger_chain_broken", {"sequence_id": expected_seq})
			return false
		var tag: = String(event.get("tag", ""))
		var event_copy: Dictionary = event.duplicate(true)
		event_copy.erase("tag")
		var expected_tag: = sha256_text(_stable_dict_text(event_copy) + "|key=" + run_key)
		if tag != expected_tag:
			invalidate("ledger_event_tag_mismatch", {"sequence_id": expected_seq})
			return false
		prev = tag
		expected_seq += 1
	return prev == previous_tag


func _load_or_create_install_secret() -> String:
	if FileAccess.file_exists(INSTALL_SECRET_PATH):
		var file: = FileAccess.open(INSTALL_SECRET_PATH, FileAccess.READ)
		if file != null:
			var stored: = file.get_as_text().strip_edges()
			file.close()
			if stored.length() >= 32:
				return stored
	var rng: = RandomNumberGenerator.new()
	rng.randomize()
	var secret: = sha256_text("%s|%s|%s" % [str(Time.get_ticks_usec()), str(rng.randi()), OS.get_unique_id()])
	var out: = FileAccess.open(INSTALL_SECRET_PATH, FileAccess.WRITE)
	if out != null:
		out.store_string(secret)
		out.close()
	return secret


func _write_tamper_report() -> void :
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
	var path: = "%s/report_%s.json" % [REPORT_DIR, run_id]
	var report: = {
		"run_id": run_id, 
		"version": build_version, 
		"reason": invalid_reason, 
		"context": invalid_context, 
		"sequence_id": sequence_id, 
		"phase": current_phase, 
		"ledger_events": ledger.size(), 
		"final_tag": previous_tag, 
		"created_unix": int(Time.get_unix_time_from_system())
	}
	var file: = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()


static func _stable_dict_text(value) -> String:
	if typeof(value) == TYPE_DICTIONARY:
		var keys: Array = value.keys()
		keys.sort_custom( func(a, b): return str(a) < str(b))
		var parts: Array[String] = []
		for key in keys:
			parts.append("%s:%s" % [str(key), _stable_dict_text(value[key])])
		return "{" + ",".join(parts) + "}"
	if typeof(value) == TYPE_ARRAY:
		var parts: Array[String] = []
		for item in value:
			parts.append(_stable_dict_text(item))
		return "[" + ",".join(parts) + "]"
	return str(value)
