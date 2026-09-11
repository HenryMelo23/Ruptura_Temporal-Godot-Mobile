extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	if main_scene == null:
		push_error("TEST_HEMORRAGIA: Failed to load Main scene")
		quit(1)
		return

	var game: Node = main_scene.instantiate()
	root.add_child(game)
	current_scene = game

	for f in range(5):
		await process_frame

	if not ("current_phase" in game):
		push_error("TEST_HEMORRAGIA: Could not find main game node with current_phase")
		quit(1)
		return

	print("--- STARTING TRANSMUTAR_HEMORRAGIA & CAMINHO_ESPINHOS SMOKE TEST ---")

	# 1. Force Phase 5 & Transmutar Hemorragia
	game.set("current_phase", 5)
	game.set("boss_active", true)
	game.set("boss_pos", Vector2(1000.0, 1000.0))

	game.call("_transmute_umbra_dimension", "TRANSMUTAR_HEMORRAGIA")

	var current_dim: String = String(game.get("boss5_dimension"))
	var map_key: String = String(game.call("_boss5_dimension_map_key", current_dim))
	print("[TEST LOG] Transmuted to dimension: %s | Map Key: %s" % [current_dim, map_key])

	if map_key != "map_phase_6":
		push_error("TEST_HEMORRAGIA FAIL: Expected map_key map_phase_6 for hemorragia, got %s" % map_key)
		quit(1)
		return

	# Set initial bonus shots
	game.set("boss5_bonus_shots", 0)
	game.set("boss5_thorns_pattern", "X")

	# ==========================================
	# EXECUTION 1: PATTERN X
	# ==========================================
	print("\n--- EXECUCAO 1: CAMINHO_ESPINHOS (PADRAO EXPECTED: X) ---")
	game.call("_spawn_umbra_action", "CAMINHO_ESPINHOS")

	var hazards: Array = game.get("phase5_hazards")
	if hazards.is_empty():
		push_error("TEST_HEMORRAGIA FAIL: Thorns hazard 1 was not created!")
		quit(1)
		return

	var h1: Dictionary = hazards[hazards.size() - 1]
	var pat1: String = String(h1.get("pattern", ""))
	var segs1: Array = h1.get("segments", [])
	print("[TEST LOG] EXEC 1: Padrão: %s | Qtd Segmentos: %d" % [pat1, segs1.size()])

	if pat1 != "X":
		push_error("TEST_HEMORRAGIA FAIL: Exec 1 expected pattern X, got %s" % pat1)
		quit(1)
		return

	if segs1.size() != 4:
		push_error("TEST_HEMORRAGIA FAIL: Exec 1 expected 4 diagonal segments, got %d" % segs1.size())
		quit(1)
		return

	# Place player directly on first diagonal segment (angle PI * 0.25 = (1000+100, 1000+100))
	var p_on_x: Vector2 = Vector2(1000.0 + 100.0 * cos(PI * 0.25), 1000.0 + 100.0 * sin(PI * 0.25))
	game.set("player_pos", p_on_x)
	game.set("player_hp", 500)
	game.set("invulnerable_timer", 0.0)
	game.set("dodge_timer", 0.0)
	game.set("player_stun_timer", 0.0)

	# Test Growth Phase (0s to 1.8s for X)
	print("\n-- FASE CRESCIMENTO (X) --")
	game.call("_update_phase5_hazards", 0.5)
	await process_frame

	var phase_g1: String = String(h1.get("phase", ""))
	var w_g1: float = float(h1.get("current_width", 0.0))
	var col_g1: bool = bool(h1.get("in_expansion", false))
	var hp_after_g1: int = int(game.get("player_hp"))
	var stun_g1: float = float(game.get("player_stun_timer"))
	var bonus_g1: int = int(game.get("boss5_bonus_shots"))

	print("[TEST LOG] CRESCIMENTO: padrão: %s | fase: %s | largura atual: %.1fpx | colisão: %s | dano: %d | stun: %.2fs | bônus de tiros: %d" % [
		pat1, phase_g1, w_g1, str(col_g1), 500 - hp_after_g1, stun_g1, bonus_g1
	])

	if phase_g1 != "crescimento" or col_g1 or hp_after_g1 != 500 or stun_g1 != 0.0:
		push_error("TEST_HEMORRAGIA FAIL: Growth phase should have 10px width and no collision")
		quit(1)
		return

	# Fast forward to Expansion Phase (elapsed = 1.8s + 0.4s = 2.2s)
	print("\n-- FASE EXPANSAO & HIT (X) --")
	for s in range(85): # 85 * 0.02s = 1.70s -> total elapsed = 2.2s
		game.call("_update_phase5_hazards", 0.02)
		await process_frame

	var phase_e1: String = String(h1.get("phase", ""))
	var w_e1: float = float(h1.get("current_width", 0.0))
	var col_e1: bool = bool(h1.get("in_expansion", false))
	var hp_after_e1: int = int(game.get("player_hp"))
	var dmg_e1: int = 500 - hp_after_e1
	var stun_e1: float = float(game.get("player_stun_timer"))
	var bonus_e1: int = int(game.get("boss5_bonus_shots"))

	print("[TEST LOG] EXPANSAO & HIT: padrão: %s | fase: %s | largura atual: %.1fpx | colisão: %s | dano: %d | stun: %.2fs | bônus de tiros: %d" % [
		pat1, phase_e1, w_e1, str(col_e1), dmg_e1, stun_e1, bonus_e1
	])

	if phase_e1 != "expansao" or not col_e1 or dmg_e1 != 50 or stun_e1 < 3.9 or bonus_e1 != 2:
		push_error("TEST_HEMORRAGIA FAIL: Exec 1 expansion hit failed. Expected dmg 50, stun 4s, bonus_shots 2. Got dmg=%d, stun=%.2f, bonus=%d" % [dmg_e1, stun_e1, bonus_e1])
		quit(1)
		return

	# Clear hazards
	game.set("phase5_hazards", [])

	# ==========================================
	# EXECUTION 2: PATTERN H3
	# ==========================================
	print("\n--- EXECUCAO 2: CAMINHO_ESPINHOS (PADRAO EXPECTED: H3) ---")
	game.call("_spawn_umbra_action", "CAMINHO_ESPINHOS")

	var hazards2: Array = game.get("phase5_hazards")
	if hazards2.is_empty():
		push_error("TEST_HEMORRAGIA FAIL: Thorns hazard 2 was not created!")
		quit(1)
		return

	var h2: Dictionary = hazards2[hazards2.size() - 1]
	var pat2: String = String(h2.get("pattern", ""))
	var segs2: Array = h2.get("segments", [])
	print("[TEST LOG] EXEC 2: Padrão: %s | Qtd Segmentos: %d" % [pat2, segs2.size()])

	if pat2 != "H3":
		push_error("TEST_HEMORRAGIA FAIL: Exec 2 expected pattern H3, got %s" % pat2)
		quit(1)
		return

	if segs2.size() != 3:
		push_error("TEST_HEMORRAGIA FAIL: Exec 2 expected 3 horizontal segments, got %d" % segs2.size())
		quit(1)
		return

	# Place player on middle horizontal line (y = WORLD_SIZE.y * 0.50)
	var world_size: Vector2 = Vector2(game.get("WORLD_SIZE"))
	var p_on_h3: Vector2 = Vector2(500.0, world_size.y * 0.50)
	game.set("player_pos", p_on_h3)
	game.set("player_hp", 500)
	game.set("invulnerable_timer", 0.0)
	game.set("dodge_timer", 0.0)
	game.set("player_stun_timer", 0.0)

	# Test Growth Phase (H3 growth duration = 1.4s)
	print("\n-- FASE CRESCIMENTO (H3) --")
	game.call("_update_phase5_hazards", 0.4)
	await process_frame

	var phase_g2: String = String(h2.get("phase", ""))
	var w_g2: float = float(h2.get("current_width", 0.0))
	var col_g2: bool = bool(h2.get("in_expansion", false))

	print("[TEST LOG] CRESCIMENTO: padrão: %s | fase: %s | largura atual: %.1fpx | colisão: %s" % [
		pat2, phase_g2, w_g2, str(col_g2)
	])

	# Fast forward to Expansion Phase (total elapsed = 1.4s + 0.4s = 1.8s)
	print("\n-- FASE EXPANSAO & HIT (H3) --")
	for s in range(70): # 70 * 0.02s = 1.40s -> total elapsed = 1.8s
		game.call("_update_phase5_hazards", 0.02)
		await process_frame

	var phase_e2: String = String(h2.get("phase", ""))
	var w_e2: float = float(h2.get("current_width", 0.0))
	var col_e2: bool = bool(h2.get("in_expansion", false))
	var hp_after_e2: int = int(game.get("player_hp"))
	var dmg_e2: int = 500 - hp_after_e2
	var stun_e2: float = float(game.get("player_stun_timer"))
	var bonus_e2: int = int(game.get("boss5_bonus_shots"))

	print("[TEST LOG] EXPANSAO & HIT: padrão: %s | fase: %s | largura atual: %.1fpx | colisão: %s | dano: %d | stun: %.2fs | bônus de tiros: %d" % [
		pat2, phase_e2, w_e2, str(col_e2), dmg_e2, stun_e2, bonus_e2
	])

	if phase_e2 != "expansao" or not col_e2 or dmg_e2 != 50 or stun_e2 < 3.9 or bonus_e2 != 4:
		push_error("TEST_HEMORRAGIA FAIL: Exec 2 expansion hit failed. Expected dmg 50, stun 4s, bonus_shots 4. Got dmg=%d, stun=%.2f, bonus=%d" % [dmg_e2, stun_e2, bonus_e2])
		quit(1)
		return

	print("\n--- ALL TRANSMUTAR_HEMORRAGIA & CAMINHO_ESPINHOS SMOKE TESTS PASSED CLEANLY ---")
	quit(0)
