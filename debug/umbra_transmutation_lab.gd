extends Node2D

signal case_finished(case_key: String)
signal sequence_finished

const MAIN_SCENE: PackedScene = preload("res://scenes/Main.tscn")

const CASES := [
	{
		"key": "vortice",
		"label": "VORTICE",
		"action": "TRANSMUTAR_VORTICE",
		"dimension": "vortice",
		"skill": "VORTICE",
		"seconds": 6.0,
	},
	{
		"key": "gravidade",
		"label": "GRAVIDADE",
		"action": "TRANSMUTAR_GRAVIDADE",
		"dimension": "gravidade",
		"skill": "PRISAO",
		"seconds": 4.4,
	},
	{
		"key": "necrose",
		"label": "NECROSE",
		"action": "TRANSMUTAR_NECROSE",
		"dimension": "necrose",
		"skill": "MIASMA",
		"seconds": 6.0,
	},
	{
		"key": "ressonancia",
		"label": "RESSONANCIA",
		"action": "TRANSMUTAR_RESSONANCIA",
		"dimension": "ressonancia",
		"skill": "DESCARGA_ELETRICA",
		"seconds": 4.0,
	},
	{
		"key": "hemorragia",
		"label": "HEMORRAGIA",
		"action": "TRANSMUTAR_HEMORRAGIA",
		"dimension": "hemorragia",
		"skill": "CAMINHO_ESPINHOS",
		"seconds": 5.0,
	},
	{
		"key": "atrito",
		"label": "ATRITO",
		"action": "TRANSMUTAR_ATRITO",
		"dimension": "atrito",
		"skill": "LASER_SOBRECARGA",
		"seconds": 7.0,
	},
	{
		"key": "rastro",
		"label": "RASTRO",
		"action": "TRANSMUTAR_RASTRO",
		"dimension": "rastro",
		"skill": "PRAGA_RATOS",
		"seconds": 7.0,
	},
]

@export var autoplay_on_ready := true
@export var loop_enabled := false
@export var transition_preview_seconds := 2.2
@export var hold_after_case_seconds := 0.45

var game: Node
var selected_case_index := 0
var sequence_enabled := true
var _playback_active := false
var _run_sequence_active := false
var _bootstrap_done := false
var _current_stage := "preparando"
var _status_refresh := 0.0
var _skill_preview_override := -1.0
var _pending_playback := false
var _pending_index := 0
var _pending_sequence := false
var _stage_remaining := 0.0

@onready var label_status: Label = $CanvasLayer/UI/LabelStatus
@onready var sequence_button: Button = $CanvasLayer/UI/GridButtons/BtnSequence
@onready var loop_button: Button = $CanvasLayer/UI/GridButtons/BtnLoop


func _ready() -> void:
	_apply_command_line_args()
	call_deferred("_bootstrap")


func _exit_tree() -> void:
	_cleanup_game()


func _process(delta: float) -> void:
	_status_refresh -= delta
	if game != null:
		_keep_lab_arena_stable()
		_advance_playback(delta)
		if game.has_method("queue_redraw"):
			game.queue_redraw()
	if _status_refresh <= 0.0:
		_status_refresh = 0.12
		_update_status()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_1:
			play_case_by_key("vortice")
		KEY_2:
			play_case_by_key("gravidade")
		KEY_3:
			play_case_by_key("necrose")
		KEY_4:
			play_case_by_key("ressonancia")
		KEY_5:
			play_case_by_key("hemorragia")
		KEY_6:
			play_case_by_key("atrito")
		KEY_7:
			play_case_by_key("rastro")
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			play_next_case()
		KEY_R:
			replay_current()
		KEY_A:
			play_sequence()
		KEY_L:
			toggle_loop()


func set_preview_timing(transition_seconds: float, skill_seconds: float, hold_seconds: float) -> void:
	transition_preview_seconds = maxf(0.0, transition_seconds)
	hold_after_case_seconds = maxf(0.0, hold_seconds)
	_skill_preview_override = maxf(0.0, skill_seconds)


func play_sequence() -> void:
	sequence_enabled = true
	_start_playback(selected_case_index, true)


func replay_current() -> void:
	sequence_enabled = false
	_start_playback(selected_case_index, false)


func play_next_case() -> void:
	var next_index := (selected_case_index + 1) % CASES.size()
	sequence_enabled = false
	_start_playback(next_index, false)


func play_case_by_key(identifier: String, run_sequence := false) -> bool:
	var index := _find_case_index(identifier)
	if index < 0:
		push_warning("UMBRA_TRANSMUTATION_LAB unknown case: " + identifier)
		return false
	sequence_enabled = run_sequence
	_start_playback(index, run_sequence)
	return true


func select_vortice() -> void:
	play_case_by_key("vortice")


func select_gravidade() -> void:
	play_case_by_key("gravidade")


func select_necrose() -> void:
	play_case_by_key("necrose")


func select_ressonancia() -> void:
	play_case_by_key("ressonancia")


func select_hemorragia() -> void:
	play_case_by_key("hemorragia")


func select_atrito() -> void:
	play_case_by_key("atrito")


func select_rastro() -> void:
	play_case_by_key("rastro")


func toggle_loop() -> void:
	loop_enabled = not loop_enabled
	_update_status()


func _bootstrap() -> void:
	game = MAIN_SCENE.instantiate()
	game.name = "UmbraGameHarness"
	add_child(game)
	move_child(game, 1)
	await get_tree().process_frame
	await get_tree().process_frame
	_setup_boss5_arena()
	_bootstrap_done = true
	_update_status()
	if _pending_playback:
		_pending_playback = false
		_start_playback(_pending_index, _pending_sequence)
	elif autoplay_on_ready:
		_start_playback(selected_case_index, sequence_enabled)


func _apply_command_line_args() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--umbra-case="):
			_apply_case_argument(argument.trim_prefix("--umbra-case="))
		elif argument.begins_with("--case="):
			_apply_case_argument(argument.trim_prefix("--case="))
		elif argument == "--umbra-sequence" or argument == "--sequence":
			sequence_enabled = true
		elif argument == "--umbra-loop" or argument == "--loop":
			loop_enabled = true
		elif argument == "--umbra-autoplay=false" or argument == "--autoplay=false":
			autoplay_on_ready = false
		elif argument.begins_with("--umbra-transition="):
			transition_preview_seconds = maxf(0.0, float(argument.trim_prefix("--umbra-transition=")))
		elif argument.begins_with("--umbra-hold="):
			hold_after_case_seconds = maxf(0.0, float(argument.trim_prefix("--umbra-hold=")))


func _apply_case_argument(identifier: String) -> void:
	var normalized := identifier.strip_edges().to_lower()
	if normalized == "all" or normalized == "sequencia" or normalized == "sequence":
		selected_case_index = 0
		sequence_enabled = true
		return
	var index := _find_case_index(normalized)
	if index >= 0:
		selected_case_index = index
		sequence_enabled = false


func _start_playback(index: int, run_sequence: bool) -> void:
	if not _bootstrap_done:
		selected_case_index = clampi(index, 0, CASES.size() - 1)
		sequence_enabled = run_sequence
		_pending_playback = true
		_pending_index = selected_case_index
		_pending_sequence = run_sequence
		return
	_playback_active = true
	_run_sequence_active = run_sequence
	selected_case_index = clampi(index, 0, CASES.size() - 1)
	_begin_case(selected_case_index)


func _begin_case(index: int) -> void:
	selected_case_index = clampi(index, 0, CASES.size() - 1)
	var case := Dictionary(CASES[selected_case_index])
	var action := String(case["action"])

	_setup_boss5_arena()
	_reset_case_state()
	_current_stage = "transmutacao"
	_stage_remaining = transition_preview_seconds
	_update_status()
	game._spawn_umbra_action(action)


func _advance_playback(delta: float) -> void:
	if not _playback_active:
		return
	var frame_delta := maxf(delta, 1.0 / 90.0)
	_stage_remaining -= frame_delta
	if _stage_remaining > 0.0:
		return
	if _current_stage == "transmutacao":
		_start_skill_stage()
	elif _current_stage == "habilidade":
		_current_stage = "retencao"
		_stage_remaining = hold_after_case_seconds
		_update_status()
	elif _current_stage == "retencao":
		_finish_current_case()


func _start_skill_stage() -> void:
	var case := Dictionary(CASES[selected_case_index])
	var skill := String(case["skill"])
	_ready_skill_cooldowns()
	_current_stage = "habilidade"
	_stage_remaining = _skill_preview_override if _skill_preview_override >= 0.0 else float(case.get("seconds", 5.0))
	_update_status()
	if game != null:
		game._spawn_umbra_action(skill)


func _finish_current_case() -> void:
	var case := Dictionary(CASES[selected_case_index])
	case_finished.emit(String(case["key"]))
	if _run_sequence_active:
		var next_index := selected_case_index + 1
		if next_index >= CASES.size():
			if loop_enabled:
				next_index = 0
			else:
				_finish_playback()
				return
		_begin_case(next_index)
		return
	_finish_playback()


func _finish_playback() -> void:
	_playback_active = false
	_run_sequence_active = false
	_current_stage = "parado"
	_stage_remaining = 0.0
	_update_status()
	sequence_finished.emit()


func _setup_boss5_arena() -> void:
	if game == null:
		return
	if game.has_method("_start_game"):
		game._start_game()
	if game.has_method("_finish_startup_thanks"):
		game._finish_startup_thanks()
	if game.has_method("_advance_to_phase"):
		game._advance_to_phase(5)
	game.mode = "game"
	game.current_phase = 5
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_name = "UMBRA"
	game.boss_hp_max = 22000.0
	game.boss_hp = game.boss_hp_max
	game.player_hp_max = 9999
	game.player_hp = game.player_hp_max
	game.player_defense = 0.0
	game.screen_shake_timer = 0.0
	game.screen_shake_strength = 0.0
	game.time_alive = 180.0
	_keep_lab_arena_stable()
	if game.has_method("_load_umbra_mobile_memory"):
		game._load_umbra_mobile_memory()


func _keep_lab_arena_stable() -> void:
	if game == null:
		return
	var center: Vector2 = game.WORLD_SIZE * 0.5
	game.player_pos = center + Vector2(-210.0, 112.0)
	game.boss_pos = center + Vector2(210.0, -84.0)
	game.boss5_target = game.boss_pos
	game.boss5_velocity = Vector2.ZERO
	game.boss5_action_timer = 999.0
	game.boss5_decision_timer = 999.0
	game.boss5_siphon_timer = 0.0
	game.boss5_siphon_cooldown = 999.0
	game.boss5_teleport_cooldown = 999.0
	game.player_hp = game.player_hp_max
	if "enemies" in game:
		game.enemies.clear()
	if "enemy_spawn_timer" in game:
		game.enemy_spawn_timer = 999.0
	if "phase5_player_history" in game and game.phase5_player_history.is_empty():
		for i in range(8):
			game.phase5_player_history.append(game.player_pos + Vector2(i * 14.0, sin(float(i)) * 22.0))


func _reset_case_state() -> void:
	if game == null:
		return
	game.phase5_hazards.clear()
	game.phase5_rats.clear()
	game.phase5_telegraphs.clear()
	game.enemy_bullets.clear()
	game.effects.clear()
	game.boss5_dimension = "base"
	game.boss5_last_dimension = ""
	game.boss5_dimension_timer = 0.0
	game.boss5_transmute_cooldown = 0.0
	game.boss5_transmute_hangover = 0.0
	_ready_skill_cooldowns()


func _ready_skill_cooldowns() -> void:
	if game == null:
		return
	game.boss5_transmute_cooldown = 0.0
	game.boss5_action_timer = 999.0
	game.boss5_decision_timer = 999.0
	for key in game.boss5_ability_cooldowns.keys():
		game.boss5_ability_cooldowns[key] = 0.0


func _find_case_index(identifier: String) -> int:
	var normalized := identifier.strip_edges().to_lower()
	for i in range(CASES.size()):
		var case := Dictionary(CASES[i])
		if normalized == String(case["key"]).to_lower():
			return i
		if normalized == String(case["dimension"]).to_lower():
			return i
		if normalized == String(case["action"]).to_lower():
			return i
		if normalized == String(case["skill"]).to_lower():
			return i
	return -1


func _update_status() -> void:
	if label_status == null:
		return
	var case := Dictionary(CASES[selected_case_index])
	var dimension := String(case["dimension"])
	var skill := String(case["skill"])
	var mode := "sequencia" if sequence_enabled else "isolado"
	var active_text := "rodando" if _playback_active else "pronto"
	label_status.text = "UMBRA TRANSMUTATION LAB\n%s | %s | %s\nDimensao: %s | Habilidade: %s" % [
		String(case["label"]),
		mode,
		active_text + "/" + _current_stage,
		dimension,
		skill,
	]
	if sequence_button != null:
		sequence_button.text = "SEQUENCIA: %s" % ("ON" if sequence_enabled else "PLAY ALL")
	if loop_button != null:
		loop_button.text = "LOOP: %s" % ("ON" if loop_enabled else "OFF")


func _cleanup_game() -> void:
	if game == null:
		return
	if game.has_method("_cleanup_runtime_resources"):
		game._cleanup_runtime_resources()
	if "music_player" in game and game.music_player != null:
		game.music_player.stop()
		game.music_player.stream = null
	if "rain_audio_player" in game and game.rain_audio_player != null:
		game.rain_audio_player.stop()
		game.rain_audio_player.stream = null
	if "sfx_players" in game:
		for player in game.sfx_players:
			if player != null:
				player.stop()
				player.stream = null
	if "textures" in game:
		game.textures.clear()
	if "audio_streams" in game:
		game.audio_streams.clear()
	if game.get_parent() == self:
		remove_child(game)
	game.free()
	game = null
