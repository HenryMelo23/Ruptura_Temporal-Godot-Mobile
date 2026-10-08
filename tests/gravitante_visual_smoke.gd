extends SceneTree

const Gravity = preload("res://scripts/presentation/gravitante_vfx_presentation.gd")
const OUT := "res://.codex/gravitante_vfx/"
var game: Node2D
var captions: Array[String] = []
var images: Array[Image] = []
var paths: Array[String] = []
var title: Label
var center := Vector2(800, 440)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("GRAVITANTE_VISUAL requires a real renderer; use Mobile/Vulkan, not --headless")
		quit(1)
		return
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game.current_phase = 1
	game.show_fps_counter = false # Frozen, PNG-saving gallery is not an FPS benchmark.
	game.set_process(false)
	game.set_physics_process(false)
	game.startup_thanks_done = true
	game.manifestation_key = "gravitante"
	for i in range(game.MANIFESTATIONS.size()):
		if game.MANIFESTATIONS[i]["key"] == "gravitante":
			game.selected_manifestation = i
	game.mode = "game"
	game.gfx_screen_shake = false
	game.player_pos = Vector2(800, 450)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.time_alive = 16.0
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var layer := CanvasLayer.new()
	root.add_child(layer)
	title = Label.new()
	title.position = Vector2(26, 672)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(title)
	if "--previews-only" in OS.get_cmdline_user_args():
		await _previews()
		game._cleanup_runtime_resources()
		game.textures.clear()
		game.audio_streams.clear()
		game.free()
		layer.queue_free()
		for frame in range(4):
			await process_frame
		quit()
		return
	for index in range(26):
		_setup_base(index)
		await _capture("%02d_base" % index, _caption(index))
	for stage in ["ev1", "ev2"]:
		for entry in game._manifest_evolution_entries("gravitante", stage):
			_setup_evolution(String(entry["id"]))
			await _capture(String(entry["id"]), stage.to_upper() + "  /  " + String(entry["name"]))
	await _sheet("01_atk_orbitais_q_tp", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14])
	await _sheet("02_ultimate_lod", [15, 16, 17, 18, 19, 20, 23, 24, 25])
	await _sheet("03_evolucoes", [26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37])
	var compared := await _comparison()
	_setup_base(24)
	title.text = "Ultimate / LOW / 960x540"
	root.size = Vector2i(960, 540)
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var mobile := root.get_texture().get_image()
	if mobile == null or mobile.get_size() != Vector2i(960, 540):
		push_error("GRAVITANTE_VISUAL invalid landscape mobile capture")
		quit(1)
		return
	mobile.save_png(OUT + "mobile_landscape_960x540.png")
	var report := FileAccess.open(OUT + "screenshots.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"renderer": RenderingServer.get_current_rendering_method(), "paths": paths, "captions": captions}, "\t"))
	report.close()
	print("GRAVITANTE_VISUAL_OK captures=%d sheets=%d mobile=960x540 renderer=%s" % [paths.size() + 1, 4 if compared else 3, RenderingServer.get_current_rendering_method()])
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	game.free()
	layer.queue_free()
	for i in range(4):
		await process_frame
	quit()

func _clear() -> void:
	game._start_game(false)
	game.current_phase = 1
	game.manifestation_key = "gravitante"
	for i in range(game.MANIFESTATIONS.size()):
		if game.MANIFESTATIONS[i]["key"] == "gravitante":
			game.selected_manifestation = i
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.aura_state.clear()
	game.net_effects.clear()
	if game.vfx_director:
		for property in ["hit_flashes", "squash_stretch", "impact_sparks", "impact_rings", "floor_cracks", "card_burns", "ground_scorches", "sky_lightning_bolts"]:
			game.vfx_director.get(property).clear()
	game.rng.seed = 9107
	game.enemies.clear()
	game.orbitals.clear()
	game.bullets.clear()
	game.effects.clear()
	game.tp_effects.clear()
	game.gravitante_vfx_events.clear()
	game.slashes.clear()
	game.shockwaves.clear()
	game.manifestation_secondaries.clear()
	game._reset_manifest_evolution_state()
	game.boss_active = false
	game.boss_dead = true
	game.gfx_low_resource = false
	game.gfx_memory_saver = false
	game.mobile_adaptive_visual_budget = false
	game.gfx_particles = true
	game.player_pos = Vector2(800, 450)
	game.is_dead = false
	game.time_alive = 16.0

func _host(pos: Vector2, count: int = 1, angle: float = 0.8) -> void:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var enemy: Dictionary = game.enemies.back()
	enemy["hp"] = 5000.0
	enemy["max_hp"] = 5000.0
	for i in range(count):
		game.orbitals.append({"target_kind": "enemy", "enemy_uid": enemy["uid"], "origin_pos": pos,
			"angle": angle + i * 2.399, "life": 2.0, "tick": 0.61, "damage": 0.0})

func _ultimate(life: float, captured: int = 4) -> void:
	game.player_pos = center + Vector2(0, 150)
	game.manifestation_secondaries.append({"kind": "gravitante", "center": center,
		"life": life, "max": 8.0, "captured": captured, "orbital_bonus": 3,
		"capture_power": 0.8, "spin_speed": 420.0, "pulse_tick": 0.28})

func _setup_base(index: int) -> void:
	_clear()
	if index <= 1:
		for i in range(1 if index == 0 else 5):
			game.bullets.append({"kind": "gravitante", "pos": center + Vector2(-150 + i * 70, -65),
				"dir": Vector2(1, -0.12).normalized(), "age": i * 0.12, "life": 1.0})
	elif index <= 9:
		_host(center + Vector2(90, -50), 9 if index == 6 else 1, -1.3 if index == 4 else 1.3)
		var orbital: Dictionary = game.orbitals[0]
		if index in [2, 3, 8, 9]:
			Gravity.capture(orbital, {"pos": center + Vector2(-90, -80), "dir": Vector2.RIGHT})
			orbital["vfx_start_life"] = 2.0 + (0.04 if index == 2 else 0.18)
			orbital["vfx_transfer"] = index >= 8
			Gravity.push_event(game, {"kind": "gravity_impact", "pos": center + Vector2(90, -50), "life": 0.12, "max": 0.18})
		if index == 9:
			game.manifest_evolution_state = {"choices": [{"id": "gravitante_ev1_slingshot"}]}
		orbital["tick"] = 0.61 if index == 7 else 0.3
	elif index <= 12:
		for offset in [Vector2(-130, -90), Vector2(160, -55), Vector2(110, 100)]:
			_host(center + offset)
		game._trigger_gravitante_mark_collision()
		game.gravitante_vfx_events[0]["life"] = [0.5, 0.35, 0.12][index - 10]
	elif index <= 14:
		game._start_manifestation_teleport_effect(center - Vector2(145, 0), center + Vector2(145, 0))
		for effect in game.tp_effects:
			effect["life"] = 0.56 if index == 13 else 0.27
	elif index <= 20:
		for offset in [Vector2(-165, -70), Vector2(180, -30), Vector2(140, 140)]:
			_host(center + offset, 1)
		game.orbitals.clear()
		_ultimate([7.75, 6.0, 4.0, 3.0, 4.0, 0.25][index - 15], 18 if index == 18 else 4)
		if index == 19:
			game.boss_active = true
			game.boss_dead = false
			game.boss_hp = 5000.0
			game.boss_hp_max = 5000.0
			game.boss_pos = center + Vector2(180, -30)
	elif index in [21, 22]:
		_setup_evolution("gravitante_ev1_roche" if index == 21 else "gravitante_ev2_tidal_event")
	elif index == 23:
		_setup_evolution("gravitante_ev1_roche")
		game.manifest_evolution_state["choices"].append({"id": "gravitante_ev2_chaotic_orbit"})
	else:
		game.gfx_low_resource = index == 24
		game.gfx_memory_saver = index == 25
		_ultimate(4.0, 12)

func _setup_evolution(id: String) -> void:
	_clear()
	game.manifest_evolution_state = {"choices": [{"id": id}]}
	_host(center + Vector2(-105, -65), 3)
	_host(center + Vector2(110, -50), 2)
	if id.ends_with("tidal_step"):
		game._start_manifestation_teleport_effect(center - Vector2(170, 0), center + Vector2(170, 0))
		game.tp_effects.back()["life"] = 0.36
	elif id.ends_with("shared_singularity"):
		game._trigger_gravitante_mark_collision()
		game.gravitante_vfx_events.back()["life"] = 0.3
	elif id.ends_with("tidal_event") or id.ends_with("rupture_horizon"):
		_ultimate(4.0, 18)
	elif id.ends_with("mass_collapse"):
		Gravity.push_event(game, {"kind": "gravity_residue", "pos": center + Vector2(0, -110), "life": 0.3, "max": 0.45})
	elif id.ends_with("slingshot"):
		var orbital: Dictionary = game.orbitals[0]
		Gravity.capture(orbital, {"pos": center + Vector2(-180, 30), "dir": Vector2(0.9, -0.4)})
		orbital["vfx_transfer"] = true
		orbital["vfx_start_life"] = 2.17

func _caption(index: int) -> String:
	return ["ATK / massa escura", "ATK / arrasto curvo", "Impacto / compressao", "Captura / continuidade",
		"Orbital / atras", "Orbital / frente", "Sistema orbital / cap visual", "Tick / periastro",
		"Transferencia / curva", "Slingshot / tangente", "Q / convergencia inicial", "Q / ponto de massa",
		"Q / onda de choque", "TP / compressao na origem", "TP / reabertura no destino",
		"Ultimate / nascimento", "Ultimate / 25%", "Ultimate / 50%", "Ultimate / 18 capturados",
		"Ultimate / resistencia do boss", "Ultimate / colapso", "EV1 / Roche", "EV2 / mare",
		"EV1 + EV2 / Roche e orbita caotica", "LOW / identidade preservada", "MEMORY SAVER / minimo legivel"][index]

func _capture(name: String, caption: String) -> void:
	title.text = caption
	# Let temporal rendering history converge after discontinuous fixture/camera changes.
	for frame in range(20):
		game.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	var capture := root.get_texture().get_image()
	if capture == null or capture.get_size() != Vector2i(1280, 720):
		push_error("GRAVITANTE_VISUAL invalid capture " + name)
		quit(1)
		return
	var path := OUT + name + ".png"
	if capture.save_png(path) != OK:
		push_error("GRAVITANTE_VISUAL cannot save " + path)
		quit(1)
		return
	paths.append(path)
	captions.append(caption)
	images.append(capture)

func _previews() -> void:
	for kind in ["atk", "skill", "ultimate"]:
		game._open_manifest_select()
		game.manifest_preview_open = true
		game.manifest_details_open = false
		game.manifest_preview_kind = kind
		game.manifest_preview_time = 8.5 / game.MANIFEST_PREVIEW_FPS
		await _capture("preview_" + kind, "Catalogo / " + kind)
	print("GRAVITANTE_PREVIEWS_OK captures=3")

func _comparison() -> bool:
	var original_size := images.size()
	var indices: Array = []
	for item in [["before_fixed_HIGH_3", "ANTES / Ultimate HIGH"],
		["after_fixed_HIGH_3", "DEPOIS / Ultimate HIGH"], ["after_fixed_LOW_3", "DEPOIS / Ultimate LOW"],
		["before_fixed_HIGH_5", "ANTES / cenario extremo"], ["after_fixed_HIGH_5", "DEPOIS / cenario extremo"],
		["after_fixed_MEMORY_3", "DEPOIS / Ultimate MEMORY"]]:
		var path: String = OUT + item[0] + ".png"
		if not FileAccess.file_exists(path):
			images.resize(original_size)
			captions.resize(original_size)
			return false # Requires the separately recorded before/after benchmark.
		indices.append(images.size())
		images.append(Image.load_from_file(ProjectSettings.globalize_path(path)))
		captions.append(item[1])
	await _sheet("04_antes_depois", indices)
	images.resize(original_size)
	captions.resize(original_size)
	return true

func _sheet(name: String, indices: Array) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1536, ceili(indices.size() / 3.0) * 344)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var painter := Node2D.new()
	viewport.add_child(painter)
	var thumbs: Array[Texture2D] = []
	for index in indices:
		# Actual renderer captures, cropped only to the central action for this contact sheet.
		var close_up: bool = index < 15 or (index >= 26 and index < 38 and index not in [34, 37])
		var crop := Rect2i(430, 210, 440, 260) if close_up else Rect2i(190, 90, 900, 550)
		thumbs.append(ImageTexture.create_from_image(images[index].get_region(crop)))
	painter.draw.connect(func():
		painter.draw_rect(Rect2(Vector2.ZERO, viewport.size), Color(0.015, 0.025, 0.04))
		for i in range(indices.size()):
			var pos := Vector2((i % 3) * 512, (i / 3) * 344)
			painter.draw_texture_rect(thumbs[i], Rect2(pos + Vector2(6, 6), Vector2(500, 302)), false)
			painter.draw_string(ThemeDB.fallback_font, pos + Vector2(14, 332), captions[indices[i]], HORIZONTAL_ALIGNMENT_LEFT, 486, 17, Color(0.8, 0.93, 0.97))
	)
	painter.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(OUT + name + ".png")
	viewport.queue_free()
	await process_frame
