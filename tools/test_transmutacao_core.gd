extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	if main_scene == null:
		push_error("TEST_CORE: Failed to load Main scene")
		quit(1)
		return

	var game: Node = main_scene.instantiate()
	root.add_child(game)
	current_scene = game

	for f in range(5):
		await process_frame

	if not ("current_phase" in game):
		push_error("TEST_CORE: Could not find main game node with current_phase")
		quit(1)
		return

	print("=========================================================")
	print("--- STARTING UMBRA TRANSMUTATION CORE SEQUENTIAL TEST ---")
	print("=========================================================\n")

	# Prepare Directory for screenshots
	DirAccess.make_dir_absolute("user://screenshots")

	# Force Phase 5 & active boss
	game.set("current_phase", 5)
	game.set("boss_active", true)
	game.set("boss_hp_max", 10000.0)
	game.set("boss_hp", 10000.0)

	var dimensions: Array[Dictionary] = [
		{"action": "TRANSMUTAR_VORTICE", "name": "vortice", "map": "map_phase_1", "ability": "VORTICE"},
		{"action": "TRANSMUTAR_GRAVIDADE", "name": "gravidade", "map": "map_phase_2", "ability": "PRISAO"},
		{"action": "TRANSMUTAR_NECROSE", "name": "necrose", "map": "map_phase_3", "ability": "MIASMA"},
		{"action": "TRANSMUTAR_RESSONANCIA", "name": "ressonancia", "map": "map_phase_4", "ability": "DESCARGA_ELETRICA"},
		{"action": "TRANSMUTAR_HEMORRAGIA", "name": "hemorragia", "map": "map_phase_6", "ability": "CAMINHO_ESPINHOS"},
		{"action": "TRANSMUTAR_ATRITO", "name": "atrito", "map": "map_phase_7", "ability": "LASER_SOBRECARGA"},
		{"action": "TRANSMUTAR_RASTRO", "name": "rastro", "map": "map_phase_9", "ability": "PRAGA_RATOS"}
	]

	var is_headless: bool = (DisplayServer.get_name() == "headless")

	var step_count := 0
	for dim_info in dimensions:
		step_count += 1
		var action_name: String = dim_info["action"]
		var dim_name: String = dim_info["name"]
		var expected_map: String = dim_info["map"]
		var ability_key: String = dim_info["ability"]

		print("---------------------------------------------------------")
		print("[%d/7] SEQUÊNCIA: base -> %s -> base" % [step_count, dim_name.to_upper()])
		print("---------------------------------------------------------")

		# 1. Start in Base
		game.call("_reset_phase5_state")
		var init_dim: String = String(game.get("boss5_dimension"))
		print("  [ESTADO INICIAL] Dimensão: %s" % init_dim)

		# 2. Transmute to target dimension
		game.call("_transmute_umbra_dimension", action_name)
		await process_frame
		await process_frame

		var cur_dim: String = String(game.get("boss5_dimension"))
		var map_key: String = String(game.call("_boss5_dimension_map_key", cur_dim))
		var cd_transmute: float = float(game.get("boss5_transmute_cooldown"))
		var dim_timer: float = float(game.get("boss5_dimension_timer"))
		var ability_cds: Dictionary = game.get("boss5_ability_cooldowns")
		var ability_cd: float = float(ability_cds.get(ability_key, 999.0))
		var hazards_count: int = (game.get("phase5_hazards") as Array).size()

		# Texture validation
		var tex: Texture2D = game.call("_current_map_texture") as Texture2D
		var tex_name: String = tex.resource_path.get_file() if (tex != null and not tex.resource_path.is_empty()) else ("ImageTexture" if tex != null else "NULL")

		print("  [TRANSMUTAÇÃO ATIVA]:")
		print("    - Dimensão: %s (esperado: %s)" % [cur_dim, dim_name])
		print("    - Map Key: %s | Textura Carregada: %s (%s)" % [map_key, tex_name, tex.resource_path if tex != null else "NONE"])
		print("    - Cooldown Transmutar: %.1fs (esperado: 18.0s)" % cd_transmute)
		print("    - Timer Dimensão: %.1fs (esperado: 30.0s)" % dim_timer)
		print("    - Habilidade Liberada (%s): Cooldown = %.1fs (esperado: 0.0s)" % [ability_key, ability_cd])
		print("    - Hazards Ativos: %d" % hazards_count)

		if cur_dim != dim_name:
			push_error("TEST_CORE FAIL: Incorrect dimension! Got %s, expected %s" % [cur_dim, dim_name])
			quit(1)
			return

		if map_key != expected_map:
			push_error("TEST_CORE FAIL: Incorrect map_key! Got %s, expected %s" % [map_key, expected_map])
			quit(1)
			return

		if tex == null:
			push_error("TEST_CORE FAIL: Map texture for %s failed to load!" % map_key)
			quit(1)
			return

		if absf(cd_transmute - 18.0) > 0.1:
			push_error("TEST_CORE FAIL: Transmute cooldown not set to 18.0s! Got %.1f" % cd_transmute)
			quit(1)
			return

		if absf(dim_timer - 30.0) > 0.1:
			push_error("TEST_CORE FAIL: Dimension timer not set to 30.0s! Got %.1f" % dim_timer)
			quit(1)
			return

		if ability_cd > 0.001:
			push_error("TEST_CORE FAIL: Ability %s cooldown not reset to 0.0! Got %.1f" % [ability_key, ability_cd])
			quit(1)
			return

		# Save screenshot if not in headless mode
		if not is_headless:
			var vp: Viewport = game.get_viewport()
			if vp != null and vp.get_texture() != null:
				var img: Image = vp.get_texture().get_image()
				if img != null:
					var ss_path: String = "user://screenshots/screenshot_%s.png" % dim_name
					img.save_png(ss_path)
					print("    - Screenshot Salvo: %s" % ss_path)

		# 3. Simulate dimension expiration and return to Base
		game.set("boss5_dimension_timer", 0.0)
		game.call("_update_boss_phase5", 0.01)
		await process_frame

		var base_dim: String = String(game.get("boss5_dimension"))
		var base_map_key: String = String(game.call("_boss5_dimension_map_key", base_dim))
		var base_tex: Texture2D = game.call("_current_map_texture") as Texture2D
		var base_tex_name: String = base_tex.resource_path.get_file() if (base_tex != null and not base_tex.resource_path.is_empty()) else ("ImageTexture" if base_tex != null else "NULL")

		print("  [RETORNO AO MAPA BASE]:")
		print("    - Dimensão Retornada: %s (esperado: base)" % base_dim)
		print("    - Map Key Retornado: %s | Textura Base: %s" % [base_map_key, base_tex_name])

		if base_dim != "base":
			push_error("TEST_CORE FAIL: Failed to return to base dimension! Got %s" % base_dim)
			quit(1)
			return

		if base_map_key != "map_phase_5":
			push_error("TEST_CORE FAIL: Base map key incorrect! Got %s" % base_map_key)
			quit(1)
			return

		if not is_headless:
			var vp: Viewport = game.get_viewport()
			if vp != null and vp.get_texture() != null:
				var img_base: Image = vp.get_texture().get_image()
				if img_base != null:
					var ss_base_path: String = "user://screenshots/screenshot_%s_retorno_base.png" % dim_name
					img_base.save_png(ss_base_path)
					print("    - Screenshot Retorno Salvo: %s" % ss_base_path)

		print("  ✓ Sequência base -> %s -> base CONCLUÍDA COM SUCESSO!\n" % dim_name)

	print("=========================================================")
	print("--- ALL 7 UMBRA TRANSMUTATION SEQUENCES PASSED CLEANLY ---")
	print("=========================================================")
	quit(0)
