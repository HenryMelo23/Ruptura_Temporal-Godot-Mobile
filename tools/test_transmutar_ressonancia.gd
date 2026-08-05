extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	if main_scene == null:
		push_error("TEST_RESSONANCIA: Failed to load Main scene")
		quit(1)
		return

	var game: Node = main_scene.instantiate()
	root.add_child(game)
	current_scene = game

	for f in range(5):
		await process_frame

	if not ("current_phase" in game):
		push_error("TEST_RESSONANCIA: Could not find main game node with current_phase")
		quit(1)
		return

	print("--- STARTING TRANSMUTAR_RESSONANCIA & DESCARGA_ELETRICA SMOKE TEST ---")

	# 1. Force Phase 5 & Transmutar Ressonancia
	game.set("current_phase", 5)
	game.set("boss_active", true)
	game.set("boss_pos", Vector2(1000.0, 1000.0))

	game.call("_transmute_umbra_dimension", "TRANSMUTAR_RESSONANCIA")

	var current_dim: String = String(game.get("boss5_dimension"))
	var map_key: String = String(game.call("_boss5_dimension_map_key", current_dim))
	print("[TEST LOG] Transmuted to dimension: %s | Map Key: %s" % [current_dim, map_key])

	if map_key != "map_phase_4":
		push_error("TEST_RESSONANCIA FAIL: Expected map_key map_phase_4 for ressonancia, got %s" % map_key)
		quit(1)
		return

	# 2. Trigger DESCARGA_ELETRICA targeting direction (Vector2.RIGHT angle = 0.0)
	game.set("player_pos", Vector2(1200.0, 1000.0))
	game.call("_spawn_umbra_action", "DESCARGA_ELETRICA")

	var hazards: Array = game.get("phase5_hazards")
	var discharge_hazard: Dictionary = {}
	for h in hazards:
		if String(h.get("kind", "")) == "discharge":
			discharge_hazard = h
			break

	if discharge_hazard.is_empty():
		push_error("TEST_RESSONANCIA FAIL: Discharge hazard was not created!")
		quit(1)
		return

	var base_ang: float = Vector2(discharge_hazard.get("dir", Vector2.RIGHT)).angle()
	print("\n--- DESCARGA ELETRICA CRIADA ---")
	print("[TEST LOG] angulo_base: %.3f rad | raio_maximo: %.1f | abertura: %.2f rad" % [
		base_ang, float(discharge_hazard.get("radius", 0.0)), float(discharge_hazard.get("abertura", 0.0))
	])

	# Fast-forward past warning duration (0.6s warning)
	for step in range(30): # 30 * 0.02s = 0.60s
		game.call("_update_phase5_hazards", 0.02)
		await process_frame

	# TEST CASE 1: INSIDE THE CONE (dist 200px <= 380px, angle diff ~0.15 rad <= 0.45 rad)
	print("\n--- TEST CASE 1: JOGADOR DENTRO DO CONE ---")
	game.set("player_pos", Vector2(1000.0 + 200.0 * cos(0.15), 1000.0 + 200.0 * sin(0.15)))
	game.set("player_hp", 500)
	game.set("invulnerable_timer", 0.0)
	game.set("dodge_timer", 0.0)
	game.set("player_stun_timer", 0.0)
	game.set("is_dead", false)

	# Run until tick timer triggers
	var hp_before_in: int = int(game.get("player_hp"))
	var dmg_in := 0
	var stun_in := 0.0

	for s in range(15): # 15 * 0.02s = 0.30s
		game.call("_update_phase5_hazards", 0.02)
		await process_frame
		var hp_curr: int = int(game.get("player_hp"))
		if hp_curr < hp_before_in:
			dmg_in = hp_before_in - hp_curr
			stun_in = float(game.get("player_stun_timer"))
			break

	var origin: Vector2 = Vector2(game.get("boss_pos"))
	var p_pos_in: Vector2 = Vector2(game.get("player_pos"))
	var dist_in: float = p_pos_in.distance_to(origin)
	var diff_ang_in: float = abs(wrapf((p_pos_in - origin).angle() - base_ang, -PI, PI))

	print("[TEST LOG] INSIDE CONE: angulo_base: %.3f rad | diff angular: %.3f rad | distância: %.1f px | dano aplicado: %d | stun: %.2fs" % [
		base_ang, diff_ang_in, dist_in, dmg_in, stun_in
	])

	if dmg_in <= 0:
		push_error("TEST_RESSONANCIA FAIL: Expected damage inside discharge cone, got %d" % dmg_in)
		quit(1)
		return

	if stun_in <= 0.0:
		push_error("TEST_RESSONANCIA FAIL: Expected stun inside discharge cone, got %.2fs" % stun_in)
		quit(1)
		return

	# TEST CASE 2: OUTSIDE THE CONE (diff_ang ~0.80 rad > 0.45 rad)
	print("\n--- TEST CASE 2: JOGADOR FORA DO CONE (ANGULO LARGO) ---")
	game.set("player_pos", Vector2(1000.0 + 200.0 * cos(0.80), 1000.0 + 200.0 * sin(0.80)))
	game.set("player_hp", 500)
	game.set("invulnerable_timer", 0.0)
	game.set("dodge_timer", 0.0)
	game.set("player_stun_timer", 0.0)

	var hp_before_out: int = int(game.get("player_hp"))
	# Advance delta 0.25s so tick timer would trigger if inside
	for s in range(12):
		game.call("_update_phase5_hazards", 0.02)
		await process_frame

	var hp_after_out: int = int(game.get("player_hp"))
	var dmg_out: int = hp_before_out - hp_after_out
	var stun_out: float = float(game.get("player_stun_timer"))

	var p_pos_out: Vector2 = Vector2(game.get("player_pos"))
	var dist_out: float = p_pos_out.distance_to(origin)
	var diff_ang_out: float = abs(wrapf((p_pos_out - origin).angle() - base_ang, -PI, PI))

	print("[TEST LOG] OUTSIDE CONE: angulo_base: %.3f rad | diff angular: %.3f rad | distância: %.1f px | dano aplicado: %d | stun: %.2fs" % [
		base_ang, diff_ang_out, dist_out, dmg_out, stun_out
	])

	if dmg_out != 0 or stun_out != 0.0:
		push_error("TEST_RESSONANCIA FAIL: Expected 0 damage and 0 stun outside cone, got dmg=%d stun=%.2f" % [dmg_out, stun_out])
		quit(1)
		return

	print("\n--- ALL TRANSMUTAR_RESSONANCIA & DESCARGA_ELETRICA SMOKE TESTS PASSED CLEANLY ---")
	quit(0)
