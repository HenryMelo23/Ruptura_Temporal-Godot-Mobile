extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	if main_scene == null:
		push_error("TEST_ATRITO: Failed to load Main scene")
		quit(1)
		return

	var game: Node = main_scene.instantiate()
	root.add_child(game)
	current_scene = game

	for f in range(5):
		await process_frame

	if not ("current_phase" in game):
		push_error("TEST_ATRITO: Could not find main game node with current_phase")
		quit(1)
		return

	print("--- STARTING TRANSMUTAR_ATRITO & LASER_SOBRECARGA SMOKE TEST ---")

	# 1. Force Phase 5 & Transmutar Atrito
	game.set("current_phase", 5)
	game.set("boss_active", true)
	var boss_pos: Vector2 = Vector2(1000.0, 1000.0)
	game.set("boss_pos", boss_pos)

	game.call("_transmute_umbra_dimension", "TRANSMUTAR_ATRITO")

	var current_dim: String = String(game.get("boss5_dimension"))
	var map_key: String = String(game.call("_boss5_dimension_map_key", current_dim))
	print("[TEST LOG] Transmuted to dimension: %s | Map Key: %s" % [current_dim, map_key])

	if map_key != "map_phase_7":
		push_error("TEST_ATRITO FAIL: Expected map_key map_phase_7 for atrito, got %s" % map_key)
		quit(1)
		return

	# 2. Spawn LASER_SOBRECARGA
	game.call("_spawn_umbra_action", "LASER_SOBRECARGA")

	var hazards: Array = game.get("phase5_hazards")
	if hazards.is_empty():
		push_error("TEST_ATRITO FAIL: Laser hazard was not created!")
		quit(1)
		return

	var h: Dictionary = hazards[hazards.size() - 1]
	var kind: String = String(h.get("kind", ""))
	print("[TEST LOG] Created hazard kind: %s" % kind)

	if kind != "umbra_overload_laser":
		push_error("TEST_ATRITO FAIL: Expected hazard kind umbra_overload_laser, got %s" % kind)
		quit(1)
		return

	# ==========================================
	# 3. TEST CHARGING PHASE (carregando)
	# ==========================================
	print("\n--- TEST FASE: CARREGANDO ---")
	game.call("_update_phase5_hazards", 0.8) # 0.8s elapsed (< 1.5s)
	await process_frame

	var fase_carga: String = String(h.get("fase", ""))
	print("[TEST LOG] CARREGANDO: fase: %s | carga_timer: %.2fs" % [fase_carga, float(h.get("carga_timer", 0.0))])

	if fase_carga != "carregando":
		push_error("TEST_ATRITO FAIL: Expected fase carregando, got %s" % fase_carga)
		quit(1)
		return

	# Fast forward to end of charging (total elapsed = 1.5s)
	game.call("_update_phase5_hazards", 0.7)
	await process_frame

	# Setup player initial conditions
	game.set("player_hp", 500)
	game.set("invulnerable_timer", 0.0)
	game.set("dodge_timer", 0.0)

	# ==========================================
	# 4. TEST FIRING ROUNDS (disparando: 1 to 4)
	# ==========================================
	print("\n--- TEST FASE: DISPARANDO (RODADAS 1 A 4) ---")

	var rot_speeds: Array[float] = [PI, -PI, PI * 0.5, -PI * (2.0 / 3.0)]

	for r in range(1, 5):
		var rot_speed: float = rot_speeds[r - 1]

		# Step 0.3s into round r to register hit
		for step in range(3):
			# Predict next angle after 0.10s delta
			var curr_ang: float = float(h.get("angle", 0.0))
			var next_ang: float = curr_ang + rot_speed * 0.10
			game.set("player_pos", boss_pos + Vector2.from_angle(next_ang) * 50.0)

			game.call("_update_phase5_hazards", 0.10)
			await process_frame

		var current_r: int = int(h.get("rodada", 0))
		var num_beams: int = int(h.get("num_beams", 0))
		var laser_dist: float = float(h.get("last_laser_dist", -1.0))
		var hp_current: int = int(game.get("player_hp"))
		var direct_dmg: int = 500 - hp_current
		var burn_stacks: int = int(game.get("player_burn_stacks"))

		print("[TEST LOG] RODADA %d: rodada: %d | feixes: %d | dist ao laser: %.2fpx | dano direto acumulado: %d | cargas de fogo: %d" % [
			r, current_r, num_beams, laser_dist, direct_dmg, burn_stacks
		])

		if current_r != r:
			push_error("TEST_ATRITO FAIL: Expected rodada %d, got %d" % [r, current_r])
			quit(1)
			return

		# Move player away for the rest of round r
		game.set("player_pos", Vector2(3000.0, 3000.0))
		game.call("_update_phase5_hazards", 0.70)
		await process_frame

	# ==========================================
	# 5. TEST BURN DAMAGE TICK
	# ==========================================
	print("\n--- TEST INCINERAÇÃO / DANO DE FOGO ---")
	var burn_stacks_before: int = int(game.get("player_burn_stacks"))
	var hp_before_burn: int = int(game.get("player_hp"))

	# Move player away from laser path so burn damage is tested cleanly
	game.set("player_pos", Vector2(3000.0, 3000.0))
	game.set("player_burn_tick_timer", 0.0) # force tick readiness

	# Advance time by 0.1s to trigger burn tick
	game.call("_update_phase5_hazards", 0.10)
	await process_frame

	var hp_after_burn: int = int(game.get("player_hp"))
	var burn_dmg_dealt: int = hp_before_burn - hp_after_burn
	print("[TEST LOG] DANO DE FOGO TICK: cargas: %d | HP antes: %d | HP depois: %d | dano de fogo: %d" % [
		burn_stacks_before, hp_before_burn, hp_after_burn, burn_dmg_dealt
	])

	if burn_stacks_before <= 0 or burn_dmg_dealt <= 0:
		push_error("TEST_ATRITO FAIL: Burn tick failed to deal damage! Burn stacks: %d, burn dmg: %d" % [burn_stacks_before, burn_dmg_dealt])
		quit(1)
		return

	# ==========================================
	# 6. TEST CLEANUP ON RESET
	# ==========================================
	print("\n--- TEST CLEANUP DO HAZARD ---")
	game.call("_reset_phase5_state")
	var hazards_after_reset: Array = game.get("phase5_hazards")
	var burn_stacks_after_reset: int = int(game.get("player_burn_stacks"))

	print("[TEST LOG] CLEANUP: hazards restantes: %d | cargas de fogo: %d" % [hazards_after_reset.size(), burn_stacks_after_reset])

	if not hazards_after_reset.is_empty() or burn_stacks_after_reset != 0:
		push_error("TEST_ATRITO FAIL: Cleanup failed on reset!")
		quit(1)
		return

	print("\n--- ALL TRANSMUTAR_ATRITO & LASER_SOBRECARGA SMOKE TESTS PASSED CLEANLY ---")
	quit(0)
