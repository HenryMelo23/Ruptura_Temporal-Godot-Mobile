extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	if main_scene == null:
		push_error("TEST_NECROSE: Failed to load Main scene")
		quit(1)
		return

	var game: Node = main_scene.instantiate()
	root.add_child(game)
	current_scene = game

	for f in range(5):
		await process_frame

	if not ("current_phase" in game):
		push_error("TEST_NECROSE: Could not find main game node with current_phase")
		quit(1)
		return

	print("--- STARTING TRANSMUTAR_NECROSE & MIASMA SMOKE TEST ---")

	# 1. Force Phase 5 & Transmutar Necrose
	game.set("current_phase", 5)
	game.set("boss_active", true)
	game.set("boss_hp", 5000.0)
	game.set("boss_hp_max", 5000.0)

	game.call("_transmute_umbra_dimension", "TRANSMUTAR_NECROSE")

	var current_dim: String = String(game.get("boss5_dimension"))
	var map_key: String = String(game.call("_boss5_dimension_map_key", current_dim))
	print("[TEST LOG] Transmuted to dimension: %s | Map Key: %s" % [current_dim, map_key])

	if map_key != "map_phase_3":
		push_error("TEST_NECROSE FAIL: Expected map_key map_phase_3 for necrose, got %s" % map_key)
		quit(1)
		return

	# State 1: Capture Normal State (Before Miasma)
	var hp_initial: int = int(game.get("player_hp"))
	var hp_max: int = int(game.get("player_hp_max"))
	var miasma_active_normal: bool = bool(game.call("_is_umbra_miasma_active"))
	var boss_bar_hidden_normal: bool = bool(game.call("_umbra_miasma_hides_boss_bar"))

	print("\n--- STATE 1: TELA NORMAL (ANTES DO MIASMA) ---")
	print("[TEST LOG] Player HP Inicial: %d / %d" % [hp_initial, hp_max])
	print("[TEST LOG] Miasma Ativo: %s | Barra Boss Oculta: %s" % [str(miasma_active_normal), str(boss_bar_hidden_normal)])

	# 2. Trigger MIASMA action
	game.call("_spawn_umbra_action", "MIASMA")

	var hazards: Array = game.get("phase5_hazards")
	var miasma_hazard: Dictionary = {}
	for h in hazards:
		if String(h.get("kind", "")) == "miasma":
			miasma_hazard = h
			break

	if miasma_hazard.is_empty():
		push_error("TEST_NECROSE FAIL: Miasma hazard was not created!")
		quit(1)
		return

	print("\n--- STATE 2: TELA SOB MIASMA (HAZARD ATIVO) ---")
	var miasma_active: bool = bool(game.call("_is_umbra_miasma_active"))
	print("[TEST LOG] Miasma Ativo: %s | Raio: %.1f px" % [str(miasma_active), float(miasma_hazard.get("radius", 0.0))])

	# Simulate 4.5 seconds of game updates and observe tick damage (1% max HP per sec) & boss bar flickering
	var tick_count := 0
	var last_hp := hp_initial

	for step in range(250): # 250 * 0.02s = 5.0s
		var dt := 0.02
		game.set("time_alive", float(game.get("time_alive")) + dt)
		game.call("_update_phase5_hazards", dt)
		await process_frame

		var current_hp: int = int(game.get("player_hp"))
		var hazard_timer: float = 0.0
		var current_hazards: Array = game.get("phase5_hazards")
		for h in current_hazards:
			if String(h.get("kind", "")) == "miasma":
				hazard_timer = float(h.get("life", 0.0))
				break

		var boss_bar_hidden: bool = bool(game.call("_umbra_miasma_hides_boss_bar"))

		if current_hp != last_hp:
			tick_count += 1
			var dmg_taken := last_hp - current_hp
			print("[TEST LOG] Tick Necrose #%d | Vida Antes: %d -> Vida Depois: %d (-%d HP) | Timer Hazard: %.2fs | Barra Boss Oculta: %s" % [
				tick_count, last_hp, current_hp, dmg_taken, hazard_timer, str(boss_bar_hidden)
			])
			last_hp = current_hp

	# State 3: Capture End of Miasma / Cleanup
	print("\n--- STATE 3: FIM DO MIASMA (CLEANUP VERIFICADO) ---")
	var miasma_active_end: bool = bool(game.call("_is_umbra_miasma_active"))
	var boss_bar_hidden_end: bool = bool(game.call("_umbra_miasma_hides_boss_bar"))
	var final_hazards: Array = game.get("phase5_hazards")

	print("[TEST LOG] Miasma Ativo no Fim: %s" % str(miasma_active_end))
	print("[TEST LOG] Barra Boss Oculta no Fim: %s" % str(boss_bar_hidden_end))
	print("[TEST LOG] Ticks Totais de Necrose Processados: %d" % tick_count)
	print("[TEST LOG] Dano Total Acumulado: -%d HP" % (hp_initial - last_hp))

	if miasma_active_end or boss_bar_hidden_end:
		push_error("TEST_NECROSE FAIL: Miasma did not clean up properly after 4.5s!")
		quit(1)
		return

	if tick_count < 4:
		push_error("TEST_NECROSE FAIL: Expected at least 4 ticks of 1% HP damage during 4.5s, got %d" % tick_count)
		quit(1)
		return

	print("\n--- ALL TRANSMUTAR_NECROSE & MIASMA SMOKE TESTS PASSED CLEANLY ---")
	quit(0)
