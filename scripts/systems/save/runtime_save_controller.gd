extends RefCounted

var core: Node
var interrupted_run_available: bool = false
var interrupted_run_summary: Dictionary = {}
var interrupted_run_autosave_timer: float = 0.0
var retry_run_snapshot: Dictionary = {}
var retry_charges_used: int = 0
var run_retry_invulnerability_timer: float = 0.0
var retry_confirm_visible: bool = false
var retry_confirm_new_run: bool = false
var retry_return_timer: float = 0.0

func configure(p_core: Node) -> void:
	core = p_core

func _load_player_profile() -> void :
	core.player_nickname = ""
	core.player_profile_id = ""
	core.player_valid_runs_completed = 0
	if not FileAccess.file_exists(core.PLAYER_PROFILE_PATH):
		core._ensure_player_profile_id()
		return
	var file = FileAccess.open(core.PLAYER_PROFILE_PATH, FileAccess.READ)
	if file == null:
		core._ensure_player_profile_id()
		return
	for line in file.get_as_text().split("\n"):
		var parts = line.split("=", false, 1)
		if parts.size() != 2:
			continue
		var key: = parts[0].strip_edges()
		var value: = parts[1].strip_edges()
		if key == "nickname":
			core.player_nickname = core._sanitize_player_nickname(value)
		elif key == "profile_id":
			core.player_profile_id = core._sanitize_profile_id(value)
		elif key == "auth_token":
			core.player_identity_auth_token = core._sanitize_profile_secret(value)
		elif key == "recovery_code":
			core.player_identity_recovery_code = core._sanitize_profile_secret(value)
		elif key == "valid_runs_completed":
			core.player_valid_runs_completed = maxi(0, int(value))
	file.close()
	core._ensure_player_profile_id()

func _save_player_profile() -> void :
	core._ensure_player_profile_id()
	var file = FileAccess.open(core.PLAYER_PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string("nickname=" + core.player_nickname + "\n")
	file.store_string("profile_id=" + core.player_profile_id + "\n")
	file.store_string("auth_token=" + core.player_identity_auth_token + "\n")
	file.store_string("recovery_code=" + core.player_identity_recovery_code + "\n")
	file.store_string("valid_runs_completed=" + str(maxi(0, int(core.player_valid_runs_completed))) + "\n")
	file.close()

func _ensure_card_unlock_defaults() -> void :
	for card_id in core.CARD_UNLOCK_ALWAYS_AVAILABLE:
		core.unlocked_card_ids[String(card_id)] = true
	for card in core.CARDS:
		var card_id: String = core._card_id(card)
		if not core.CARD_UNLOCK_RULES.has(card_id) and not core.unlocked_card_ids.has(card_id):
			core.unlocked_card_ids[card_id] = true
	for key in core.MANIFESTATION_UNLOCK_ALWAYS_AVAILABLE:
		core.unlocked_manifestation_ids[String(key)] = true
	if core.retornante_unlocked:
		core.unlocked_manifestation_ids["retornante"] = true
	for key in core.SPECTRUM_UNLOCK_ALWAYS_AVAILABLE:
		core.unlocked_spectrum_ids[String(key)] = true
	for aura in core.AURAS:
		var spectrum_key: = String(aura.get("key", ""))
		if spectrum_key != "" and not core.specter_levels.has(spectrum_key):
			core.specter_levels[spectrum_key] = 1

func _load_card_unlocks() -> void :
	core.unlocked_card_ids.clear()
	core.unlocked_manifestation_ids.clear()
	core.unlocked_spectrum_ids.clear()
	core.specter_levels.clear()
	core.card_unlock_progress.clear()
	core.card_unlock_veteran_synced_version_code = 0
	core._ensure_card_unlock_defaults()
	core.player_progress_install_secret = core._load_or_create_player_progress_install_secret()
	core.player_progress_pending_events.clear()
	core.player_progress_event_sequence = 0
	core.player_progress_cache_trusted = false
	var cached: Dictionary = core._read_trusted_player_progress_cache()
	if not cached.is_empty():
		core.player_progress_cache_trusted = true
		core.player_progress_event_sequence = maxi(0, int(cached.get("event_sequence", 0)))
		var cached_events: Array = cached.get("pending_events", [])
		for event in cached_events:
			if event is Dictionary:
				core.player_progress_pending_events.append(event.duplicate(true))
		core._apply_player_progress_snapshot(cached.get("snapshot", {}), false)
	core.card_unlocks_dirty = false
	core.card_unlock_save_timer = 0.0

func _save_card_unlocks() -> void :
	core._ensure_card_unlock_defaults()
	var payload: Dictionary = core.RTPlayerProgressSync.build_cache_payload(
		core.player_profile_id,
		core.player_identity_auth_token,
		core.player_identity_recovery_code,
		core._card_unlock_snapshot(),
		core.player_progress_pending_events,
		core.player_progress_event_sequence
	)
	var signed_payload: Dictionary = core.RTPlayerProgressSync.signed_cache(payload, core._player_progress_install_secret())
	var file = FileAccess.open(core.PLAYER_PROGRESS_CACHE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(signed_payload, "\t"))
	file.close()
	core.card_unlocks_dirty = false
	core.card_unlock_save_timer = 0.0

func _mark_card_unlocks_dirty() -> void :
	core.card_unlocks_dirty = true
	if core.card_unlock_save_timer <= 0.0:
		core.card_unlock_save_timer = 3.0

func _flush_card_unlocks_if_dirty() -> void :
	if core.card_unlocks_dirty:
		_save_card_unlocks()

func _load_config() -> void :

	core.retornante_unlocked = false
	core.online_mode_unlocked = false
	core.qa_streaming_unlocked = false
	core.qa_streaming_enabled = false
	core.qa_streaming_status = ""
	if not FileAccess.file_exists("user://hud_config.save"):
		return
	var file = FileAccess.open("user://hud_config.save", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var lines = content.split("\n")
		for line in lines:
			var parts = line.split("=")
			if parts.size() == 2:
				var k = parts[0].strip_edges()
				var v = parts[1].strip_edges()
				var coords = v.split(",")
				if k == "joy_pos" and coords.size() == 2: core.hud_joy_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "joy_scale": core.hud_joy_scale = clamp(float(v), core.HUD_CONTROL_SCALE_MIN, core.HUD_CONTROL_SCALE_MAX)
				elif k == "attack_pos" and coords.size() == 2: core.hud_attack_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "attack_scale": core.hud_attack_scale = clamp(float(v), core.HUD_CONTROL_SCALE_MIN, core.HUD_ATTACK_SCALE_MAX)
				elif k == "skill_scale": core.hud_skill_scale = clamp(float(v), core.HUD_CONTROL_SCALE_MIN, core.HUD_CONTROL_SCALE_MAX)
				elif k == "secondary_pos" and coords.size() == 2: core.hud_secondary_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "secondary_scale": core.hud_secondary_scale = clamp(float(v), core.HUD_CONTROL_SCALE_MIN, core.HUD_CONTROL_SCALE_MAX)
				elif k == "dash_pos" and coords.size() == 2: core.hud_dash_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "dash_scale": core.hud_dash_scale = clamp(float(v), core.HUD_CONTROL_SCALE_MIN, core.HUD_CONTROL_SCALE_MAX)
				elif k == "lacerante_empower_pos" and coords.size() == 2: core.hud_lacerante_empower_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "lacerante_empower_scale": core.hud_lacerante_empower_scale = clamp(float(v), core.HUD_CONTROL_SCALE_MIN, core.HUD_CONTROL_SCALE_MAX)
				elif k == "hud_left_panel_pos" and coords.size() == 2: core.hud_left_panel_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "hud_right_panel_pos" and coords.size() == 2: core.hud_right_panel_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "hud_boss_panel_pos" and coords.size() == 2: core.hud_boss_panel_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "hud_skill_pos" and coords.size() == 2: core.hud_skill_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "hud_pause_pos" and coords.size() == 2: core.hud_pause_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "hud_boss_call_pos" and coords.size() == 2: core.hud_boss_call_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "hud_shop_pos" and coords.size() == 2: core.hud_shop_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "hud_aura_panel_pos" and coords.size() == 2: core.hud_aura_panel_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "hud_cards_panel_pos" and coords.size() == 2: core.hud_cards_panel_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "hud_coagulum_pos" and coords.size() == 2: core.hud_coagulum_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "hud_aura_panel_scale": core.hud_aura_panel_scale = clamp(float(v), core.HUD_PANEL_SCALE_MIN, core.HUD_PANEL_SCALE_MAX)
				elif k == "hud_cards_panel_scale": core.hud_cards_panel_scale = clamp(float(v), core.HUD_PANEL_SCALE_MIN, core.HUD_PANEL_SCALE_MAX)
				elif k == "hud_coagulum_scale": core.hud_coagulum_scale = clamp(float(v), core.HUD_PANEL_SCALE_MIN, core.HUD_PANEL_SCALE_MAX)
				elif k == "analog_fixed": core.analog_fixed = v != "false"
				elif k == "analog_mode": core.analog_fixed = v != "dinamico"
				elif k == "shop_auto_enabled": core.shop_auto_enabled = v != "false"
				elif k == "shop_auto_interval": core.shop_auto_interval = clamp(float(v), 180.0, 480.0)
				elif k == "auto_target_priority": core.auto_target_priority = core._sanitize_target_priority(v)
				elif k == "haptics_enabled": core.haptics_enabled = v != "false"
				elif k == "show_fps_counter": core.show_fps_counter = v == "true"
				elif k == "run_tutorial_enabled": core.run_tutorial_enabled = v == "true"
				elif k == "shop_tutorial_seen": core.shop_tutorial_seen = v == "true"
				elif k == "boss_call_tutorial_seen": core.boss_call_tutorial_seen = v == "true"
				elif k == "online_mode_unlocked": core.online_mode_unlocked = v == "true"
				elif k == "qa_streaming_enabled": core.qa_streaming_enabled = false
				elif k == "qa_streaming_unlocked": core.qa_streaming_unlocked = v == "true"
				elif k == "qa_streaming_quality": core.qa_streaming_quality_mode = core._sanitize_qa_stream_quality_mode(v)
				elif k == "qa_data_unlocked": core.qa_data_unlocked = v == "true"
				elif k == "force_phase6_start":
					core.force_phase6_start = v == "true"
					if core.force_phase6_start:
						core.forced_initial_phase = 6
				elif k == "forced_initial_phase": core.forced_initial_phase = core._sanitize_forced_initial_phase(int(v))
				elif k == "initial_phase_bias_target": core.initial_phase_bias_target = core._sanitize_initial_phase_bias_target(int(v))
				elif k == "initial_phase_bias_strength": core.initial_phase_bias_strength = clampf(float(v), 0.0, 1.0)
				elif k == "ui_platform_override": core.ui_platform_override = core._sanitize_ui_platform_override(v)
				elif k == "ui_platform_override_unlocked": core.ui_platform_override_unlocked = v == "true"
				elif k == "desktop_window_mode": core.desktop_window_mode = core._sanitize_desktop_window_mode(v)
				elif k == "desktop_aim_mode": core.desktop_aim_mode = core._sanitize_desktop_aim_mode(v)
				elif k == "desktop_teleport_mode": core.desktop_teleport_mode = core._sanitize_desktop_teleport_mode(v)
				elif k == "desktop_attack_aim_mode": core.desktop_attack_aim_mode = core._sanitize_desktop_attack_aim_mode(v)
				elif k == "desktop_hud_scale": core.desktop_hud_scale = core._sanitize_desktop_hud_scale(float(v))
				elif k == "gamepad_bindings":
					core._load_gamepad_bindings(coords)
				elif k == "keyboard_bindings":
					core._load_keyboard_bindings(coords)

				elif k == "vol_master": core.vol_master = float(v)

				elif k == "vol_music": core.vol_music = float(v)

				elif k == "vol_sfx": core.vol_sfx = float(v)
				elif k == "vol_shots": core.vol_shots = clamp(float(v), 0.0, 1.0)

				elif k == "gfx_particles": core.gfx_particles = v == "true"

				elif k == "gfx_shadows": core.gfx_shadows = v == "true"

				elif k == "gfx_screen_shake": core.gfx_screen_shake = v == "true"
				elif k == "gfx_health_warning_start": core.gfx_health_warning_start = clampf(float(v), 0.35, 0.7)
				elif k == "gfx_health_warning_strength": core.gfx_health_warning_strength = clampf(float(v), 0.0, 1.35)
				elif k == "gfx_low_resource": core.gfx_low_resource = v == "true"
				elif k == "gfx_memory_saver": core.gfx_memory_saver = v == "true"
				elif k == "damage_text_scale": core.damage_text_scale = clamp(float(v), 0.7, 1.8)
				elif k == "interface_text_scale": core.interface_text_scale = clamp(float(v), 0.9, 1.6)
				elif k == "vol_master": core.vol_master = float(v)
				elif k == "vol_music": core.vol_music = float(v)
				elif k == "vol_sfx": core.vol_sfx = float(v)
				elif k == "vol_shots": core.vol_shots = clamp(float(v), 0.0, 1.0)
				elif k == "gfx_particles": core.gfx_particles = v == "true"
				elif k == "gfx_shadows": core.gfx_shadows = v == "true"
				elif k == "gfx_screen_shake": core.gfx_screen_shake = v == "true"
				elif k == "gfx_low_resource": core.gfx_low_resource = v == "true"
				elif k == "gfx_memory_saver": core.gfx_memory_saver = v == "true"
				elif k == "damage_text_scale": core.damage_text_scale = clamp(float(v), 0.7, 1.8)
		file.close()
	core.ui_platform_override = core._sanitize_ui_platform_override(core.ui_platform_override)
	core.desktop_window_mode = core._sanitize_desktop_window_mode(core.desktop_window_mode)
	core.desktop_aim_mode = core._sanitize_desktop_aim_mode(core.desktop_aim_mode)
	core.desktop_teleport_mode = core._sanitize_desktop_teleport_mode(core.desktop_teleport_mode)
	core.desktop_attack_aim_mode = core._sanitize_desktop_attack_aim_mode(core.desktop_attack_aim_mode)
	core.desktop_hud_scale = core._sanitize_desktop_hud_scale(core.desktop_hud_scale)
	core.forced_initial_phase = core._sanitize_forced_initial_phase(core.forced_initial_phase)
	core.force_phase6_start = core.forced_initial_phase == 6
	core.forced_shop_enabled = core.shop_auto_enabled
	if core.gfx_memory_saver:
		core.gfx_low_resource = true
	core.qa_streaming_quality_mode = core._sanitize_qa_stream_quality_mode(core.qa_streaming_quality_mode)
	if not core.QA_STREAMING_FEATURE_ENABLED:
		core.qa_streaming_enabled = false
		core.qa_streaming_unlocked = false
		core.qa_streaming_status = ""
	else:
		core.qa_streaming_enabled = false

func _save_config() -> void :
	var file = FileAccess.open("user://hud_config.save", FileAccess.WRITE)
	if file:
		file.store_string("joy_pos=" + str(core.hud_joy_pos.x) + "," + str(core.hud_joy_pos.y) + "\n")
		file.store_string("joy_scale=" + str(core.hud_joy_scale) + "\n")
		file.store_string("attack_pos=" + str(core.hud_attack_pos.x) + "," + str(core.hud_attack_pos.y) + "\n")
		file.store_string("attack_scale=" + str(core.hud_attack_scale) + "\n")
		file.store_string("skill_scale=" + str(core.hud_skill_scale) + "\n")
		file.store_string("secondary_pos=" + str(core.hud_secondary_pos.x) + "," + str(core.hud_secondary_pos.y) + "\n")
		file.store_string("secondary_scale=" + str(core.hud_secondary_scale) + "\n")
		file.store_string("dash_pos=" + str(core.hud_dash_pos.x) + "," + str(core.hud_dash_pos.y) + "\n")
		file.store_string("dash_scale=" + str(core.hud_dash_scale) + "\n")
		file.store_string("lacerante_empower_pos=" + str(core.hud_lacerante_empower_pos.x) + "," + str(core.hud_lacerante_empower_pos.y) + "\n")
		file.store_string("lacerante_empower_scale=" + str(core.hud_lacerante_empower_scale) + "\n")
		file.store_string("hud_left_panel_pos=" + str(core.hud_left_panel_pos.x) + "," + str(core.hud_left_panel_pos.y) + "\n")
		file.store_string("hud_right_panel_pos=" + str(core.hud_right_panel_pos.x) + "," + str(core.hud_right_panel_pos.y) + "\n")
		file.store_string("hud_boss_panel_pos=" + str(core.hud_boss_panel_pos.x) + "," + str(core.hud_boss_panel_pos.y) + "\n")
		file.store_string("hud_skill_pos=" + str(core.hud_skill_pos.x) + "," + str(core.hud_skill_pos.y) + "\n")
		file.store_string("hud_pause_pos=" + str(core.hud_pause_pos.x) + "," + str(core.hud_pause_pos.y) + "\n")
		file.store_string("hud_boss_call_pos=" + str(core.hud_boss_call_pos.x) + "," + str(core.hud_boss_call_pos.y) + "\n")
		file.store_string("hud_shop_pos=" + str(core.hud_shop_pos.x) + "," + str(core.hud_shop_pos.y) + "\n")
		file.store_string("hud_aura_panel_pos=" + str(core.hud_aura_panel_pos.x) + "," + str(core.hud_aura_panel_pos.y) + "\n")
		file.store_string("hud_cards_panel_pos=" + str(core.hud_cards_panel_pos.x) + "," + str(core.hud_cards_panel_pos.y) + "\n")
		file.store_string("hud_coagulum_pos=" + str(core.hud_coagulum_pos.x) + "," + str(core.hud_coagulum_pos.y) + "\n")
		file.store_string("hud_aura_panel_scale=" + str(core.hud_aura_panel_scale) + "\n")
		file.store_string("hud_cards_panel_scale=" + str(core.hud_cards_panel_scale) + "\n")
		file.store_string("hud_coagulum_scale=" + str(core.hud_coagulum_scale) + "\n")
		file.store_string("analog_mode=" + ("fixo" if core.analog_fixed else "dinamico") + "\n")
		file.store_string("analog_fixed=" + ("true" if core.analog_fixed else "false") + "\n")
		file.store_string("shop_auto_enabled=" + ("true" if core.shop_auto_enabled else "false") + "\n")
		file.store_string("shop_auto_interval=" + str(core.shop_auto_interval) + "\n")
		file.store_string("auto_target_priority=" + core.auto_target_priority + "\n")
		file.store_string("haptics_enabled=" + ("true" if core.haptics_enabled else "false") + "\n")
		file.store_string("show_fps_counter=" + ("true" if core.show_fps_counter else "false") + "\n")
		file.store_string("run_tutorial_enabled=" + ("true" if core.run_tutorial_enabled else "false") + "\n")
		file.store_string("shop_tutorial_seen=" + ("true" if core.shop_tutorial_seen else "false") + "\n")
		file.store_string("boss_call_tutorial_seen=" + ("true" if core.boss_call_tutorial_seen else "false") + "\n")
		file.store_string("online_mode_unlocked=" + ("true" if core.online_mode_unlocked else "false") + "\n")
		file.store_string("qa_streaming_enabled=false\n")
		file.store_string("qa_streaming_unlocked=" + ("true" if core.qa_streaming_unlocked else "false") + "\n")
		file.store_string("qa_streaming_quality=" + core._sanitize_qa_stream_quality_mode(core.qa_streaming_quality_mode) + "\n")
		file.store_string("qa_data_unlocked=" + ("true" if core.qa_data_unlocked else "false") + "\n")
		file.store_string("force_phase6_start=" + ("true" if core.force_phase6_start else "false") + "\n")
		file.store_string("forced_initial_phase=" + str(core._sanitize_forced_initial_phase(core.forced_initial_phase)) + "\n")
		file.store_string("initial_phase_bias_target=" + str(core._sanitize_initial_phase_bias_target(core.initial_phase_bias_target)) + "\n")
		file.store_string("initial_phase_bias_strength=" + str(clampf(core.initial_phase_bias_strength, 0.0, 1.0)) + "\n")
		file.store_string("ui_platform_override=" + core._sanitize_ui_platform_override(core.ui_platform_override) + "\n")
		file.store_string("ui_platform_override_unlocked=" + ("true" if core.ui_platform_override_unlocked else "false") + "\n")
		file.store_string("desktop_window_mode=" + core._sanitize_desktop_window_mode(core.desktop_window_mode) + "\n")
		file.store_string("desktop_aim_mode=" + core._sanitize_desktop_aim_mode(core.desktop_aim_mode) + "\n")
		file.store_string("desktop_teleport_mode=" + core._sanitize_desktop_teleport_mode(core.desktop_teleport_mode) + "\n")
		file.store_string("desktop_attack_aim_mode=" + core._sanitize_desktop_attack_aim_mode(core.desktop_attack_aim_mode) + "\n")
		file.store_string("desktop_hud_scale=" + str(core._sanitize_desktop_hud_scale(core.desktop_hud_scale)) + "\n")
		file.store_string("gamepad_bindings=" + core._serialize_gamepad_bindings() + "\n")
		file.store_string("keyboard_bindings=" + core._serialize_keyboard_bindings() + "\n")

		file.store_string("vol_master=" + str(core.vol_master) + "\n")

		file.store_string("vol_music=" + str(core.vol_music) + "\n")

		file.store_string("vol_sfx=" + str(core.vol_sfx) + "\n")
		file.store_string("vol_shots=" + str(core.vol_shots) + "\n")

		file.store_string("gfx_particles=" + ("true" if core.gfx_particles else "false") + "\n")

		file.store_string("gfx_shadows=" + ("true" if core.gfx_shadows else "false") + "\n")

		file.store_string("gfx_screen_shake=" + ("true" if core.gfx_screen_shake else "false") + "\n")
		file.store_string("gfx_health_warning_start=" + str(core.gfx_health_warning_start) + "\n")
		file.store_string("gfx_health_warning_strength=" + str(core.gfx_health_warning_strength) + "\n")
		file.store_string("gfx_low_resource=" + ("true" if core.gfx_low_resource else "false") + "\n")
		file.store_string("gfx_memory_saver=" + ("true" if core.gfx_memory_saver else "false") + "\n")
		file.store_string("damage_text_scale=" + str(core.damage_text_scale) + "\n")
		file.store_string("interface_text_scale=" + str(core.interface_text_scale) + "\n")
		file.store_string("vol_master=" + str(core.vol_master) + "\n")
		file.store_string("vol_music=" + str(core.vol_music) + "\n")
		file.store_string("vol_sfx=" + str(core.vol_sfx) + "\n")
		file.store_string("vol_shots=" + str(core.vol_shots) + "\n")
		file.store_string("gfx_particles=" + ("true" if core.gfx_particles else "false") + "\n")
		file.store_string("gfx_shadows=" + ("true" if core.gfx_shadows else "false") + "\n")
		file.store_string("gfx_screen_shake=" + ("true" if core.gfx_screen_shake else "false") + "\n")
		file.store_string("gfx_low_resource=" + ("true" if core.gfx_low_resource else "false") + "\n")
		file.store_string("gfx_memory_saver=" + ("true" if core.gfx_memory_saver else "false") + "\n")
		file.store_string("damage_text_scale=" + str(core.damage_text_scale) + "\n")
		file.close()

func _interrupted_run_field_names() -> Array:
	return [
		"shop_paid_rerolls_this_visit", "manifest_evolution_fragment_claim_count", "cinzas_card_bonuses",
		"mode", "current_phase", "pending_phase", "phase_started_at", "game_time", "time_alive", "elapsed_unpaused", "run_initial_phase", "run_phase6_completed", "dimension_route_queue", "dimension_route_farm_cycles", "dimension_route_completed_count", "dimension_route_last_phase", "run_extracted",
		"run_pacing_profile", "run_pacing_valid_runs_at_start", "run_valid_duration_recorded", "run_pacing_larapio_first_time", "run_pacing_arauto_first_time", "run_pacing_first_special_enemy_time", "run_pacing_first_special_enemy_kind",
		"selected_manifestation", "selected_aura", "manifestation_key", "aura_state", "manifest_evolution_state",
		"player_pos", "player_hp", "player_hp_max", "player_speed", "player_damage", "player_attack_interval", "player_dash_cooldown", "player_defense", "player_crit_chance", "player_lifesteal",
		"score", "score_total", "run_points_earned", "run_points_spent", "card_cost", "cards_bought", "combo_kills", "enemies_killed", "enemy_base_hp", "enemy_speed_base", "enemy_close_damage", "enemy_far_damage", "spawn_timer",
		"last_attack_time", "last_dash_time", "last_skill_time", "last_secondary_time", "last_damage_time", "forced_shop_timer", "forced_shop_triggered", "next_forced_shop_time", "shop_auto_elapsed", "shop_opening_timer", "shop_opening_forced", "shop_opening_manual_already_tracked", "shop_return_timer",
		"shop_cards", "shop_selected", "shop_rerolls", "shop_purchase_anim_timer", "shop_purchase_pending_card", "shop_purchase_pending_can_continue", "shop_purchase_pending_price", "shop_reserved_card_id", "shop_locked_slots", "shop_recent_common_ids", "shop_slot_intents", "shop_generation_profile", "shop_generation_index", "shop_visit_index", "shop_reroll_index", "shop_recent_generation_ids", "shop_current_visit_eligible_cinzas", "shop_last_generation_telemetry", "shop_seed", "shop_endurance_discount", "bargain_capsule", "bargain_capsule_next_check_time", "bargain_capsule_event_sequence", "bargain_capsule_pending_discount", "bargain_capsule_last_result", "shop_bargain_discount_session", "shop_last_manual_open_time", "shop_recent_manual_open_count", "shop_purchases_this_visit", "shop_last_exit_had_purchase", "shop_last_exit_time", "shop_abuse_penalty_count", "shop_manual_cooldown_until", "shop_manual_grace_until", "shop_manual_grace_reopen_available", "shop_manual_visit_active", "shop_manual_visit_grace_on_close", "shop_manual_cooldown_pulse",
		"enemies", "bullets", "enemy_bullets", "larapio_coin_drops", "shockwaves", "effects", "heal_orbs", "slashes", "anchors", "prisms", "orbitals", "seed_links", "parasite_spit_zones", "return_bullets", "manifestation_secondaries",
		"trembo_charges", "trembo_pos", "trembo_side", "trembo_heal_timer", "trembo_anim_time", "trembo_facing", "trembo_invulnerability", "petro_active", "petro_pos", "petro_fire_timer", "petro_hp", "petro_hp_max", "petro_defense", "petro_damage", "petro_evolution", "petro_anim_time", "petro_facing",
		"boss_ready", "boss_call_timer", "boss_active", "boss_dead", "boss_hp", "boss_hp_max", "boss_pos", "boss_phase", "boss_attack_timer", "boss_entry_timer", "boss_stage_timer", "boss_stage_approaching", "boss_stage_60_done", "boss_stage_40_done", "boss_stage_30_done", "boss_stage_safe_angle", "boss_attacks", "boss_transition_waves", "boss_name", "boss_title_color", "boss_empurrou_player",
		"boss_poison_timer", "boss_poison_tick", "boss_parasite_seeds", "boss_parasite_mark_time", "miasma_eel_slow_timer", "miasma_eel_slow_stacks", "pustule_spit_slow_timer", "pustule_spit_slow_grace_timer", "boss_tp_stun_timer", "boss_wave_slow_timer", "player_stun_timer", "player_silence_timer", "revive_heal_penalty_timer", "player_freeze_visual_timer", "player_freeze_visual_duration",
		"boss1_rewind_cooldown", "boss1_rewind_history", "boss1_rewind_sample_timer", "boss1_rewind_sequence", "boss1_rewind_visual_projectiles", "boss1_rewind_vibration_timer", "boss1_rewind_clock_tick", "boss1_absorb_cooldown", "boss1_absorb_timer", "boss1_absorb_damage", "boss1_absorb_retaliate_timer", "boss1_absorb_bursts_fired", "boss1_time_wave",
		"arauto", "arauto_spawned", "arauto_rays", "arauto_echo_breaks", "arauto_card_drops", "arauto_evolution_fragment", "manifest_evolution_fragment_claimed_this_run", "manifest_evolution_fragment_claim_source",
		"boss2_ice_shards", "boss2_snow_zones", "boss2_frost_particles", "phase2_fire_walls", "phase2_fire_wall_hit_cd", "boss2_state", "boss2_action_timer", "boss2_target_position", "boss2_last_attack", "boss2_repeat_count", "boss2_facing_dir", "boss2_walk_speed", "boss2_anim_timer", "boss2_anim_frame", "boss2_breath_dir", "boss2_ultimate_cooldown", "boss2_ultimate_timer", "boss2_ultimate_center", "boss2_ultimate_orbit_angle", "boss2_ultimate_spit_timer", "boss2_ultimate_wind_timer", "boss2_ultimate_wind_active", "boss2_ultimate_wind_dir", "boss2_ultimate_hail_timer", "boss2_ultimate_fan_timer", "boss2_ultimate_blizzard_tick", "boss2_ultimate_blizzard_exposure", "boss2_ultimate_hit_gate", "boss2_ultimate_used", "boss2_hunt_sequence", "boss2_hunt_last_target_peer_id", "boss2_hunt_target_grace",
		"phase3_miasma_zones", "phase3_cheeses", "phase6_pustule_pools", "phase6_pustule_pheromone_timer", "boss6_lodarian_pools", "boss6_state", "boss6_current_ability", "boss6_state_timer", "boss6_wait_timer", "boss6_ability_cooldowns", "boss6_last_abilities", "boss6_carapace_plates", "boss6_carapace_timer", "boss6_vulnerability_timer", "boss6_core_exposed_timer", "boss6_core_permanent_bonus", "boss6_event_80_triggered", "boss6_event_60_triggered", "boss6_event_40_triggered", "boss6_event_30_triggered", "boss6_event_15_triggered", "boss6_special_event_id", "boss6_special_timer", "boss6_organs", "boss6_final_mutation", "boss6_final_birth_timer", "boss6_fossil_era_timer", "boss6_fossil_shield", "boss6_rib_prison", "boss6_tail_channels", "boss6_reflux_objects", "boss6_cracked_heart", "sanguessuga_parasite_timer", "sanguessuga_bleed_tick_timer", "boss6_shielded", "boss6_entry_particles", "boss6_relocating", "boss6_relocate_from", "boss6_relocate_to", "boss6_relocate_age", "boss6_relocate_duration", "boss6_miasma_ult_timer", "boss6_miasma_ult_cooldown", "boss6_miasma_ult_angle", "boss6_miasma_ult_pustule_timer", "boss6_miasma_slow_timer", "boss6_miasma_slow_stacks", "boss6_miasma_slow_tick", "boss6_carnage_slow_timer", "boss3_faith", "boss3_stage", "boss3_stun_timer", "boss3_rain_timer", "boss3_spit_timer", "boss3_tail_timer", "boss3_charge_timer", "boss3_cheese_timer", "boss3_dialogue_timer", "boss3_events", "boss3_consume_uid", "boss3_consume_timer", "boss3_ritual_timer", "boss3_ritual_destroyed", "boss3_is_moving", "boss3_miasma_cooldown", "boss3_miasma_timer", "boss3_miasma_variant", "boss3_miasma_clone_timer", "boss3_miasma_clone_positions", "boss3_miasma_spit_timer", "boss3_miasma_qte_required", "boss3_miasma_qte_taps", "boss3_miasma_qte_time_left", "boss3_miasma_qte_idle", "boss3_miasma_qte_tutorial", "boss3_miasma_qte_elapsed", "boss3_miasma_qte_lid_contacts", "boss3_miasma_qte_lids_touching", "boss3_miasma_qte_overtime_timer", "boss3_miasma_qte_overtime_stage", "boss3_miasma_tutorial_seen", "boss3_faith_test_cooldown", "boss3_faith_test_active", "boss3_faith_test_pulses_left", "boss3_faith_test_pulse_timer", "boss3_faith_link_timer", "boss3_faith_link_damage_done", "boss3_sector_ritual_cooldown", "boss3_sector_ritual_sequence",
		"phase4_planets", "phase4_null_zones", "phase4_enemy_hazards", "phase4_player_history", "phase4_history_sample_timer", "boss4_attack_timer", "boss4_attack_pose_timer", "boss4_anim_time", "boss4_entry_target", "boss4_instability", "boss4_stage", "boss4_no_hit_timer", "boss4_gravity_timer", "boss4_gravity_dir", "boss4_vampire_timer", "boss4_prison", "boss4_clone", "boss4_fragment_timer", "boss4_ultimate_active", "boss4_ultimate_timer", "boss4_ultimate_used", "boss4_ultimate_laser_timer", "boss4_ultimate_gravity_timer", "boss4_rupture_anchors", "boss4_ultimate_destroyed", "boss4_secondary_timer", "boss4_secondary_active", "boss4_secondary_elapsed", "boss4_ultimate_cooldown", "boss4_ultimate_ray_index", "boss4_strike_sequence", "boss4_meteorites", "boss4_meteor_event_timer", "boss4_meteor_event_started", "boss4_meteor_damage_bonus", "boss4_stun_timer", "boss4_vulnerable_timer", "boss4_column_barrage_timer", "boss4_drag_wave_timer", "boss4_sonic_used",
		"phase5_player_history", "phase5_history_sample_timer", "phase5_hazards", "phase5_rats", "phase5_telegraphs", "boss5_action_timer", "boss5_decision_timer", "boss5_current_action", "boss5_dimension", "boss5_last_dimension", "boss5_mental_state", "boss5_velocity", "boss5_target", "boss5_siphon_timer", "boss5_siphon_cooldown", "boss5_teleport_cooldown", "boss5_transmute_cooldown", "boss5_ability_cooldowns", "boss5_mobile_weights", "boss5_predatory_mods", "boss5_profile_confidence", "boss5_last_reward_action",
		"phase_transition_timer", "phase_fragment", "larapio_spawned", "next_larapio_spawn_time", "fusion_check_timer", "event_alert_text", "event_alert_timer", "alert_stalker_done", "alert_projector_done", "alert_crystal_done", "alert_agglomerator_done", "alert_curater_done",
		"weather_kind", "weather_rain_intro_timer", "boss1_rain_active", "raindrops", "puddles", "rain_splashes", "snowflakes",
		"fratura_cronal_cooldown", "fratura_cronal_armed", "pulso_desestabilizador_cooldown", "pulso_desestabilizador_armed", "boss_fragilidade_cronal_timer", "boss_fragilidade_cronal_bonus", "ferrolho_ruptura_cooldown", "ferrolho_ruptura_armed", "desvio_probabilidade_charges", "boss_ferrolho_slow_timer", "boss_ferrolho_slow_ratio", "boss_choque_source_category", "boss_choque_source_until", "boss_choque_cooldown_until", "boss_limiar_mask", "boss_limiar_phase", "common_card_effects", "rare_card_effects", "tregua_regenerativa_timer", "tregua_regenerativa_active", "tregua_regenerativa_pulse", "cinzas_burn_marks", "reserva_pulso_stored", "reserva_pulso_releasing", "reserva_pulso_pulse", "casulo_hit_times", "casulo_reativo_timer", "casulo_reativo_cooldown", "passagem_intangivel_timer", "ancora_vital_state", "estase_reparadora_timer", "estase_reparadora_tick", "estase_reparadora_pause", "estase_reparadora_anchor", "estase_reparadora_active", "estase_reparadora_pulse", "egide_hemofaga_shield", "egide_hemofaga_full_timer", "egide_hemofaga_pulse", "mandamento_skill_uses", "mandamento_empowered_until", "mandamento_empowered_scale", "mandamento_invulnerability", "mandamento_break_flash", "carta_zero_applied_multiplier", "rastro_vestiges", "rastro_spawn_timer", "rastro_last_spawn_pos", "rastro_speed_timer", "rastro_speed_bonus", "impulso_ready_times", "impulso_charges", "impulso_bonus", "impulso_timer", "impulso_size_bonus", "eco_counters", "zona_charge", "zona_cooldown", "zona_flash", "folego_target_key", "folego_charge", "folego_prev_distance", "folego_damage_window", "folego_damage_bonus", "folego_last_move_dir", "margem_window_timer", "margem_debt", "margem_debt_total", "margem_debt_timer", "margem_debt_duration", "margem_debt_tick", "margem_safety_timer", "ressonancia_symbols", "ressonancia_window_timer", "ressonancia_ready_timer", "ressonancia_ready_action", "ressonancia_speed_timer", "ressonancia_speed_bonus", "ressonancia_preresonance_used", "necro_kill_counter", "active_necro_specters", "antimatter_charge", "antimatter_armed", "antimatter_flash", "stored_excess", "excess_discharge_kind", "excess_discharge_uid", "excess_discharge_flash", "devorador_mark_timer", "devorador_mark_kind", "devorador_mark_uid", "devorador_marked_max_hp", "devorador_mark_pos", "devorador_boss_mark_start_hp", "devorador_boss_mark_max_hp", "devorador_destiny_shield", "devorador_shield_timer", "devorador_effects",
		"cartographic_coords", "cartographic_route_timer", "cartographic_boss_displacement", "mnesic_trick_timer", "mnesic_trick_origin", "mnesic_boss_vulnerability", "resonant_perfect_streak", "resonant_noise", "resonant_next_perfect", "resonant_speed_timer", "resonant_sinfonia_buff_timer", "resonant_note_index", "boss_resonant_notes", "boss_contract_clause", "boss_contract_infractions", "boss_contract_vulnerability", "contractual_notifications", "contractual_penalty_timer", "contractual_order", "contractual_order_rewards", "contractual_order_penalties",
		"lacerante_combo", "lacerante_combo_visual", "lacerante_preparing", "lacerante_prepare_stage", "lacerante_prepare_frame", "lacerante_prepare_timer", "lacerante_prepare_dir", "lacerante_coagula", "lacerante_empowered_ready", "last_lacerante_empower_time", "lacerante_coagulum_pulse", "lacerante_tp_charges", "lacerante_tp_chain_timer", "lacerante_tp_cooldown_until", "retornante_memoria_pending", "retornante_tp_origin", "retornante_tp_window", "eletrica_shot_counter", "tp_effects", "necronada_vestiges", "necronada_remnants", "necronada_requiem", "necronada_pente_history", "necronada_attack_counter", "necronada_empowered_ready", "necronada_empower_until", "necronada_empower_cooldown_until", "necronada_horde_progress",
		"acorrentada_combo_step", "acorrentada_combo_reset_timer", "acorrentada_tension", "acorrentada_last_hit_timer", "acorrentada_overcharge_ready", "acorrentada_force_next_attack_3", "acorrentada_links", "acorrentada_visuals", "acorrentada_worn_chains", "acorrentada_last_player_pos", "acorrentada_boss_elos", "acorrentada_boss_elo_timer", "acorrentada_boss_crack_timer", "acorrentada_boss_containment_charges"
	]

func _run_report_state_field_names() -> Array:
	return [
		"run_started_at", "run_started_unix", "run_start_damage",
		"run_damage_to_enemies", "run_damage_by_enemy", "run_damage_to_boss_by_phase",
		"run_boss_reached", "run_boss_started_at", "run_boss_duration",
		"run_damage_taken_total", "run_damage_taken_by_source", "run_damage_hits_by_source",
		"run_damage_source_meta", "run_damage_events", "run_heatmap_cells",
		"run_phase_seconds", "run_behavior_distance", "run_behavior_edge_seconds",
		"run_behavior_corner_seconds", "run_behavior_center_seconds", "run_behavior_dash_count",
		"run_behavior_shots_fired", "run_behavior_hits", "run_behavior_boss_hits",
		"run_behavior_player_last_pos", "run_behavior_player_last_sample_pos",
		"run_behavior_move_samples", "run_behavior_stationary_samples"
	]

func _snapshot_field_value(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value

func _run_can_be_saved() -> bool:
	if core.is_multiplayer or core.dedicated_server_mode or core.online_connected:
		return false
	if core.is_dead or core.player_hp <= 0:
		return false
	return _interrupted_run_saved_mode() != ""

func _interrupted_run_saved_mode() -> String:
	if core.mode in ["game", "paused", "shop", "shop_opening", "shop_countdown", "boss_call", "phase_transition", "manifest_evolution", "manifest_evolution_waiting"]:
		return core.mode
	if core.mode == "pause_deck":
		return "paused"
	if core.mode in ["settings", "settings_gamepad", "settings_keys", "settings_gameplay", "settings_audio", "settings_graphics", "settings_data"] and core.settings_previous_mode != "menu":
		return "paused" if core.settings_previous_mode == "paused" else "game"
	return ""

func _build_interrupted_run_snapshot() -> Dictionary:
	var fields: = {}
	for field in _interrupted_run_field_names() + _run_report_state_field_names():
		fields[String(field)] = _snapshot_field_value(core.get(String(field)))
	fields["mode"] = _interrupted_run_saved_mode()
	return {
		"schema": 1,
		"game_version": core.GAME_VERSION,
		"saved_at": core._datetime_text(),
		"saved_unix": int(Time.get_unix_time_from_system()),
		"fields": fields
	}

func _save_interrupted_run(force: = false) -> void :
	if not _run_can_be_saved():
		return
	if not force:
		interrupted_run_autosave_timer -= core.get_process_delta_time()
		if interrupted_run_autosave_timer > 0.0:
			return
	interrupted_run_autosave_timer = core.INTERRUPTED_RUN_AUTOSAVE_INTERVAL
	var snapshot: = _build_interrupted_run_snapshot()
	var file: = FileAccess.open(core.INTERRUPTED_RUN_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(var_to_str(snapshot))
	file.close()
	interrupted_run_available = true
	interrupted_run_summary = _interrupted_run_summary_from_snapshot(snapshot)

func _clear_interrupted_run_save() -> void :
	interrupted_run_available = false
	interrupted_run_summary.clear()
	interrupted_run_autosave_timer = core.INTERRUPTED_RUN_AUTOSAVE_INTERVAL
	if FileAccess.file_exists(core.INTERRUPTED_RUN_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(core.INTERRUPTED_RUN_SAVE_PATH))

func _load_interrupted_run_snapshot() -> Dictionary:
	if not FileAccess.file_exists(core.INTERRUPTED_RUN_SAVE_PATH):
		return {}
	var file: = FileAccess.open(core.INTERRUPTED_RUN_SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var raw: = file.get_as_text()
	file.close()
	var parsed = str_to_var(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var snapshot: Dictionary = parsed
	if int(snapshot.get("schema", 0)) != 1 or typeof(snapshot.get("fields", {})) != TYPE_DICTIONARY:
		return {}
	return snapshot

func _load_interrupted_run_summary() -> void :
	var snapshot: = _load_interrupted_run_snapshot()
	interrupted_run_available = not snapshot.is_empty()
	interrupted_run_summary = _interrupted_run_summary_from_snapshot(snapshot) if interrupted_run_available else {}

func _interrupted_run_summary_from_snapshot(snapshot: Dictionary) -> Dictionary:
	if snapshot.is_empty():
		return {}
	var fields: Dictionary = snapshot.get("fields", {})
	var phase: = int(fields.get("current_phase", 1))
	var total_seconds: = int(max(0.0, float(fields.get("time_alive", 0.0))))
	var manifestation_index: = clampi(int(fields.get("selected_manifestation", 0)), 0, core.MANIFESTATIONS.size() - 1)
	var aura_index: = clampi(int(fields.get("selected_aura", 0)), 0, core.AURAS.size() - 1)

	var date_str: = ""
	var saved_unix: = int(snapshot.get("saved_unix", 0))
	if saved_unix > 0:
		var dt: = Time.get_datetime_dict_from_unix_time(saved_unix)
		date_str = "%02d/%02d/%04d" % [int(dt["day"]), int(dt["month"]), int(dt["year"])]
	else:
		var raw_saved: = String(snapshot.get("saved_at", ""))
		if raw_saved.length() >= 10:
			var parts: = raw_saved.split(" ")[0].split("-")
			if parts.size() == 3:
				date_str = "%02d/%02d/%04d" % [int(parts[2]), int(parts[1]), int(parts[0])]
	if date_str == "":
		var dt_now: = Time.get_datetime_dict_from_system()
		date_str = "%02d/%02d/%04d" % [int(dt_now["day"]), int(dt_now["month"]), int(dt_now["year"])]

	return {
		"phase": phase,
		"time": "%02d:%02d" % [int(total_seconds / 60), total_seconds % 60],
		"date": date_str,
		"manifestation": String(core.MANIFESTATIONS[manifestation_index].get("name", "Manifestacao")),
		"aura": String(core.AURAS[aura_index].get("name", "Aura")).to_upper(),
		"saved_at": String(snapshot.get("saved_at", ""))
	}

func _interrupted_run_detail_text() -> String:
	if not interrupted_run_available:
		return "SEM RUN SALVA"
	var t_str: = String(interrupted_run_summary.get("time", "00:00"))
	var d_str: = String(interrupted_run_summary.get("date", "01/08/2026"))
	return "%s  |  %s" % [t_str, d_str]

func _resume_interrupted_run() -> bool:
	var snapshot: = _load_interrupted_run_snapshot()
	if snapshot.is_empty():
		_clear_interrupted_run_save()
		return false
	var fields: Dictionary = snapshot.get("fields", {})
	core.selected_manifestation = clampi(int(fields.get("selected_manifestation", core.selected_manifestation)), 0, core.MANIFESTATIONS.size() - 1)
	core.selected_aura = clampi(int(fields.get("selected_aura", core.selected_aura)), 0, core.AURAS.size() - 1)
	core._start_game(false)
	for field in _interrupted_run_field_names() + _run_report_state_field_names():
		var key: = String(field)
		if fields.has(key):
			core.set(key, fields[key])
	_post_resume_interrupted_run()
	return true

func _post_resume_interrupted_run() -> void :
	core.mode = _interrupted_run_saved_mode() if _interrupted_run_saved_mode() != "" else "game"
	if core.mode in ["settings", "settings_gamepad", "settings_keys", "settings_gameplay", "settings_audio", "settings_graphics", "settings_data", "pause_deck"]:
		core.mode = "paused"
	core.is_dead = false
	core.partner_is_dead = false
	core.player_hp = max(1.0, min(float(core.player_hp), float(core.player_hp_max)))
	core.touch_move = Vector2.ZERO
	core.pointer_down = false
	core.active_screen_touches.clear()
	core.move_touch_index = -1
	core.attack_touch_index = -1
	core.attack_dragging = false
	core.attack_holding = false
	core.attack_touch_pos = Vector2.ZERO
	core.attack_lock_selecting = false
	core.skill_touch_index = -1
	core.secondary_touch_index = -1
	core.dash_touch_index = -1
	core.teleport_dragging = false
	core.manifest_preview_open = false
	interrupted_run_available = true
	interrupted_run_summary = _interrupted_run_summary_from_snapshot(_build_interrupted_run_snapshot())
	interrupted_run_autosave_timer = core.INTERRUPTED_RUN_AUTOSAVE_INTERVAL
	core._play_phase_music()
	core._update_audio_volumes()
	core._add_text("RUN RESTAURADA", core.player_pos + Vector2(0, -84), Color(0.0, 1.0, 0.82), 1.8, 26)
	core._block_ui_input()

func _capture_retry_run_snapshot() -> void:
	if core.is_multiplayer or core.dedicated_server_mode:
		return
	var saved_mode: String = core.mode
	core.mode = "game"
	retry_run_snapshot = _build_interrupted_run_snapshot()
	core.mode = saved_mode

func _retry_available() -> bool:
	return not core.is_multiplayer and not core.dedicated_server_mode and not retry_run_snapshot.is_empty() and retry_charges_used < core.RUN_RETRY_MAX_CHARGES

func _retry_penalty_cost(attempt: int) -> int:
	if attempt <= 1:
		return core.score
	if attempt == 2:
		return core.card_cost * 2
	return core.card_cost * 5

func _use_run_retry() -> bool:
	if not _retry_available():
		return false
	var fields: Dictionary = retry_run_snapshot.get("fields", {})
	if fields.is_empty():
		return false
	retry_charges_used += 1
	core.selected_manifestation = clampi(int(fields.get("selected_manifestation", core.selected_manifestation)), 0, core.MANIFESTATIONS.size() - 1)
	core.selected_aura = clampi(int(fields.get("selected_aura", core.selected_aura)), 0, core.AURAS.size() - 1)
	core._start_game(false)
	for field in _interrupted_run_field_names() + _run_report_state_field_names():
		var key: = String(field)
		if fields.has(key):
			core.set(key, fields[key])
	core.is_dead = false
	core.partner_is_dead = false
	retry_confirm_visible = false
	retry_confirm_new_run = false
	retry_return_timer = 0.0
	core.death_screen_delay_timer = 0.0
	core.death_screen_pending_result = ""
	core.death_screen_pending_specter_upgrade = false
	core.mode = "game"
	var ratio: float = float(core.RUN_RETRY_HP_RATIOS[clampi(retry_charges_used - 1, 0, core.RUN_RETRY_HP_RATIOS.size() - 1)])
	core.player_hp = max(1.0, core.player_hp_max * ratio)
	run_retry_invulnerability_timer = core.RUN_RETRY_INVULNERABILITY
	var penalty: = _retry_penalty_cost(retry_charges_used)
	if penalty > 0:
		core.score = max(0, core.score - penalty)
		core.run_points_spent += penalty
		if retry_charges_used == 1:
			core._add_text("RETORNO: PONTOS ZERADOS", core.player_pos + Vector2(0, -104), Color(0.0, 1.0, 0.82), 1.8, 22)
		else:
			core._add_text("RETORNO: MULTA %d" % penalty, core.player_pos + Vector2(0, -104), Color(1.0, 0.72, 0.18), 1.8, 22)
	if core.boss_dead:
		core._clear_boss_runtime_hazards()
		core.spawn_timer = 0.0
	core.touch_move = Vector2.ZERO
	core.pointer_down = false
	core.active_screen_touches.clear()
	core.move_touch_index = -1
	core.attack_touch_index = -1
	core.attack_dragging = false
	core.attack_holding = false
	core.skill_touch_index = -1
	core.secondary_touch_index = -1
	core.dash_touch_index = -1
	core.teleport_dragging = false
	core._play_phase_music()
	core._update_audio_volumes()
	core._add_text("TENTE NOVAMENTE %d/%d" % [retry_charges_used, core.RUN_RETRY_MAX_CHARGES], core.player_pos + Vector2(0, -72), Color(0.48, 1.0, 1.0), 1.8, 24)
	core._block_ui_input()
	return true

func _open_retry_confirm_popup() -> void:
	retry_confirm_visible = true
	retry_confirm_new_run = not _retry_available()
	core._block_ui_input()

func _confirm_retry_choice() -> void:
	if retry_confirm_new_run or not _retry_available():
		retry_confirm_visible = false
		retry_confirm_new_run = false
		core._reset_multiplayer_session_for_solo()
		core._start_game()
		return
	core._start_retry_return_animation()

func _cancel_retry_choice() -> void:
	retry_confirm_visible = false
	retry_confirm_new_run = false
	core._block_ui_input()

func _retry_confirm_lines() -> Array[String]:
	if retry_confirm_new_run or not _retry_available():
		return [
			"A run atual foi encerrada.",
			"Uma nova jornada reinicia mapa, pontos, cartas e progressao da partida."
		]
	var attempt: int = retry_charges_used + 1
	var hp_ratio: float = float(core.RUN_RETRY_HP_RATIOS[clampi(attempt - 1, 0, core.RUN_RETRY_HP_RATIOS.size() - 1)])
	var penalty: int = _retry_penalty_cost(attempt)
	var cost_text: String = "pontos atuais zerados" if attempt == 1 else "multa de %d pontos" % penalty
	return [
		"Geovana retorna ao ponto salvo antes da ruptura final.",
		"Vida de retorno: %d%%. Janela segura: %.0fs." % [int(round(hp_ratio * 100.0)), core.RUN_RETRY_INVULNERABILITY],
		"Custo deste retorno: %s." % cost_text
	]

func _update_interrupted_run_autosave(delta: float) -> void :
	if _run_can_be_saved():
		interrupted_run_autosave_timer -= delta
		if interrupted_run_autosave_timer <= 0.0:
			_save_interrupted_run(true)
	else:
		interrupted_run_autosave_timer = min(interrupted_run_autosave_timer, core.INTERRUPTED_RUN_AUTOSAVE_INTERVAL)
