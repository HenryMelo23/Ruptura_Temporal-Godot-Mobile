extends SceneTree

const Gravity = preload("res://scripts/presentation/gravitante_vfx_presentation.gd")
var game: Node2D
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, reason: String) -> void:
	if not ok:
		failures += 1
		push_error("GRAVITANTE_VFX_CONTRACT " + reason)

func _run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game.set_process(false)
	game.set_physics_process(false)
	game.manifestation_key = "gravitante"
	game.enemies.clear()
	game.orbitals.clear()
	game.player_damage = 100.0
	game.time_alive = 100.0
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(650, 350))
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(790, 350))
	for enemy in game.enemies:
		enemy["hp"] = 5000.0
		enemy["max_hp"] = 5000.0
		game.orbitals.append({"target_kind": "enemy", "enemy_uid": enemy["uid"], "origin_pos": enemy["pos"], "life": 4.0, "angle": 0.4, "tick": 0.1, "damage": 18.0})
	var orbit: Dictionary = game.orbitals[0]
	var original := orbit.duplicate(true)
	Gravity.capture(orbit, {"pos": Vector2(620, 350), "dir": Vector2.RIGHT})
	Gravity.transfer(orbit, 100.0)
	for key in original:
		check(orbit[key] == original[key], "visual capture/transfer changed gameplay: " + key)
	game._trigger_gravitante_mark_collision()
	check(game.gravitante_vfx_events.size() == 1, "Q must emit one collective event")
	check(Vector2(game.gravitante_vfx_events[0]["pos"]).is_equal_approx(Vector2(720, 350)), "Q did not use actual center of mass")
	check(game.orbitals.all(func(o): return o["life"] == 0.0), "Q orbital consumption changed")
	check(game.tp_effects.is_empty(), "cosmetic Q entered teleport lifecycle")
	var expected_hp := 5000.0 - 100.0 * (1.1 + 2 * 0.22)
	for enemy in game.enemies:
		check(is_equal_approx(float(enemy["hp"]), expected_hp), "Q damage changed")
	for i in range(120):
		Gravity.push_event(game, {"kind": "gravity_impact", "pos": Vector2.ZERO, "life": 0.18, "max": 0.18})
	check(game.gravitante_vfx_events.size() <= 24, "impact event cap grew")
	check(game.gravitante_vfx_events.any(func(e): return e["kind"] == "gravity_q"), "decoration evicted critical Q")
	game.tp_cooldown_pending = true
	game.tp_cooldown_release_time = -1.0
	game._update_teleport_effects(0.01)
	check(not game.tp_cooldown_pending, "VFX delayed teleport cooldown")
	Gravity.update(game, 1.0)
	check(game.gravitante_vfx_events.is_empty(), "expired VFX leaked")
	game.gfx_low_resource = false
	game.gfx_memory_saver = false
	game.mobile_adaptive_visual_budget = false
	check(Gravity.lod(game) == (1 if game._is_mobile_runtime() else 3), "HIGH/mobile budget mapping")
	game.mobile_adaptive_visual_budget = true
	check(Gravity.lod(game) == (1 if game._is_mobile_runtime() else 2), "adaptive budget ignored")
	game.gfx_low_resource = true
	check(Gravity.lod(game) == 1, "LOW budget ignored")
	game.gfx_memory_saver = true
	check(Gravity.lod(game) == 0, "MEMORY budget ignored")
	for ev1 in game._manifest_evolution_entries("gravitante", "ev1"):
		for ev2 in game._manifest_evolution_entries("gravitante", "ev2"):
			game.manifest_evolution_state = {"choices": [ev1, ev2]}
			check(Gravity.evolved(game, String(ev1["id"]).trim_prefix("gravitante_")), "missing EV1 presentation")
			check(Gravity.evolved(game, String(ev2["id"]).trim_prefix("gravitante_")), "missing EV2 presentation")
	Gravity.push_event(game, {"kind": "gravity_q", "pos": Vector2.ZERO, "life": 0.5, "max": 0.5})
	game._start_game()
	check(game.gravitante_vfx_events.is_empty(), "run restart retained VFX")
	print("GRAVITANTE_VFX_CONTRACT_OK failures=%d pairs=36 lifecycle=true damage=true budget=true" % failures)
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	game.free()
	for i in range(4):
		await process_frame
	quit(0 if failures == 0 else 1)
