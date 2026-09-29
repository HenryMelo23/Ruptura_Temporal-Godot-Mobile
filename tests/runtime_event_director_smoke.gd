extends SceneTree

const Catalog = preload("res://scripts/systems/events/runtime_event_catalog.gd")

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("RUNTIME_EVENT_DIRECTOR_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _feed_kills(count: int, enemy_type: String = "common", authority: bool = true) -> void:
	for i in range(count):
		game.runtime_event_director.on_enemy_killed({"type": enemy_type, "points": 20}, game.runtime_event_director.context_from_game(game), authority)


func _force_snapshot(event_id: String, stat: String, multiplier: float) -> Dictionary:
	return {
		"active": true,
		"schema": Catalog.SCHEMA,
		"schema_version": Catalog.SCHEMA_VERSION,
		"sequence": 900,
		"type": event_id,
		"label": event_id,
		"stat": stat,
		"started_at": game.time_alive,
		"duration": 20.0,
		"remaining": 20.0,
		"multiplier": multiplier,
		"intensity": 0.5,
		"context": {
			"phase": game.current_phase,
			"kills": game.enemies_killed,
			"boss_active": game.boss_active,
			"boss_name": game.boss_name,
			"umbra": game.current_phase == 5
		}
	}


func _run() -> void:
	await process_frame
	game._start_game()
	game.run_tutorial_enabled = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.mode = "game"
	game.current_phase = 5
	game.boss_active = true
	game.boss_name = "UMBRA"

	_check(Catalog.event_count() == 4, "initial event catalog size drifted")
	_check(Catalog.threshold_for(900.0) < Catalog.threshold_for(241.0), "late threshold did not become more intense")
	_check(Catalog.cooldown_for(900.0) < Catalog.cooldown_for(241.0), "late cooldown did not shrink")
	var damage_event: Dictionary = Catalog.event_by_index(0)
	_check(Catalog.event_duration(damage_event, 900.0) > Catalog.event_duration(damage_event, 241.0), "late duration did not grow")

	game.time_alive = 239.0
	_feed_kills(30, "agglomerator", true)
	_check(not game.runtime_event_director.is_active(), "event started before four minutes")

	game.time_alive = 260.0
	game.enemies_killed = 18
	_feed_kills(8, "agglomerator", true)
	_check(game.runtime_event_director.is_active(), "event did not start after charged threshold")
	var first_snapshot: Dictionary = game.runtime_event_director.active_snapshot()
	var first_type: String = String(first_snapshot.get("type", ""))
	var first_sequence: int = int(first_snapshot.get("sequence", 0))
	_feed_kills(30, "agglomerator", true)
	_check(game.runtime_event_director.is_active(), "active event ended while feeding extra kills")
	_check(int(game.runtime_event_director.active_snapshot().get("sequence", 0)) == first_sequence, "second event started while one was active")

	game.runtime_event_director.update(float(first_snapshot.get("duration", 1.0)) + 0.5, game.runtime_event_director.context_from_game(game), true)
	_check(not game.runtime_event_director.is_active(), "event did not expire")
	_check(float(game.runtime_event_director.active_snapshot().get("cooldown", 0.0)) > 0.0, "cooldown missing after event end")
	_feed_kills(40, "agglomerator", true)
	_check(not game.runtime_event_director.is_active(), "event started during cooldown")

	game.runtime_event_director.cleanup("test_cleanup", game.runtime_event_director.context_from_game(game))
	_check(not game.runtime_event_director.is_active(), "cleanup left event active")
	_check(float(game.runtime_event_director.active_snapshot().get("cooldown", 0.0)) == 0.0, "cleanup left cooldown active")

	game.runtime_event_director.apply_remote_snapshot(_force_snapshot("damage_surge", "damage", 1.25))
	_check(absf(game.runtime_event_director.damage_multiplier() - 1.25) < 0.001, "damage multiplier missing")
	game.runtime_event_director.apply_remote_snapshot(_force_snapshot("movement_surge", "move_speed", 1.2))
	_check(absf(game.runtime_event_director.move_speed_multiplier() - 1.2) < 0.001, "move speed multiplier missing")
	game.runtime_event_director.apply_remote_snapshot(_force_snapshot("attack_surge", "attack_interval", 0.8))
	_check(absf(game.runtime_event_director.attack_interval_multiplier() - 0.8) < 0.001, "attack interval multiplier missing")
	game.runtime_event_director.apply_remote_snapshot(_force_snapshot("double_points", "points", 2.0))
	_check(absf(game.runtime_event_director.point_multiplier() - 2.0) < 0.001, "point multiplier missing")

	game.runtime_event_director.reset()
	game.time_alive = 300.0
	game.is_multiplayer = true
	game.is_host = false
	game.online_room_owner = false
	_feed_kills(40, "agglomerator", game._is_world_authority())
	_check(not game.runtime_event_director.is_active(), "replica started event without authority")
	game._apply_remote_boss_visual_snapshot({"runtime_event": _force_snapshot("damage_surge", "damage", 1.3)})
	_check(game.runtime_event_director.is_active(), "replica did not apply authority snapshot")
	_check(absf(game.runtime_event_director.damage_multiplier() - 1.3) < 0.001, "replica snapshot multiplier missing")

	game.is_multiplayer = false
	game.is_host = true
	game.runtime_event_director.reset()
	game.time_alive = 300.0
	_feed_kills(12, "agglomerator", true)
	game.runtime_event_director.update(float(game.runtime_event_director.active_snapshot().get("duration", 1.0)) + 0.5, game.runtime_event_director.context_from_game(game), true)
	var payload: Dictionary = game._build_minimal_telemetry_payload("RuntimeEventSmoke")
	var temporary_event: Dictionary = Dictionary(payload.get("temporary_event", {}))
	var events: Array = temporary_event.get("events", [])
	_check(events.size() >= 2, "telemetry did not record start and end")
	_check(String(Dictionary(events[0]).get("type", "")) != "", "telemetry type missing")
	_check(typeof(Dictionary(events[0]).get("duration")) == TYPE_FLOAT, "telemetry duration type missing")
	_check(Dictionary(events[0]).has("context"), "telemetry context missing")
	var umbra_context: Dictionary = Dictionary(Dictionary(payload.get("umbra", {})).get("runtime_event_context", {}))
	_check(umbra_context.has("event_active"), "umbra observation context missing")

	print("RUNTIME_EVENT_DIRECTOR_SMOKE_OK first=%s telemetry=%d multiplayer=true cleanup=true" % [first_type, events.size()])
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	game = null
	await process_frame
	quit(0)
