class_name EnemyManager
extends Node

const PHASE_DENSITY_CARRY_RATIO := 0.70

# Cadencia de especiais pertence ao owner de spawn. Os valores experientes sao
# destinos explicitos, nao multiplicadores aplicados em cima do baseline.
const SPECIAL_SPAWN_PACING: Dictionary = {
	2: {
		"first_unlock": 60.0,
		"experienced_first_unlock": 45.0,
		"repeat_gap": 52.0,
		"experienced_repeat_gap": 42.0,
		"kamikaze_unlock": 60.0,
		"experienced_kamikaze_unlock": 45.0,
		"pyro_unlock": 240.0,
		"experienced_pyro_unlock": 180.0
	},
	3: {
		"first_unlock": 120.0,
		"experienced_first_unlock": 90.0,
		"repeat_gap": 54.0,
		"experienced_repeat_gap": 43.0,
		"incensario_unlock": 240.0,
		"experienced_incensario_unlock": 180.0,
		"guardiao_unlock": 360.0,
		"experienced_guardiao_unlock": 270.0
	},
	4: {
		"first_unlock": 0.0,
		"experienced_first_unlock": 0.0,
		"repeat_gap": 72.0,
		"experienced_repeat_gap": 58.0
	},
	5: {
		"first_unlock": 0.0,
		"experienced_first_unlock": 0.0,
		"repeat_gap": 72.0,
		"experienced_repeat_gap": 58.0
	},
	6: {
		"first_unlock": 120.0,
		"experienced_first_unlock": 90.0,
		"repeat_gap": 66.0,
		"experienced_repeat_gap": 52.0,
		"leech_unlock": 120.0,
		"experienced_leech_unlock": 90.0,
		"eel_unlock": 210.0,
		"experienced_eel_unlock": 158.0,
		"pustule_unlock": 300.0,
		"experienced_pustule_unlock": 225.0
	},
	7: {
		"first_unlock": 45.0,
		"experienced_first_unlock": 45.0,
		"repeat_gap": 60.0,
		"experienced_repeat_gap": 60.0
	}
}

var game: Node = null
var phase_density_carry_cap: int = 0
var phase_density_native_entry_cap: int = 0
var special_last_spawn_phase_time: float = -1.0
var special_spawn_history: Array[Dictionary] = []


func bind_game(p_game: Node) -> void:
	game = p_game
	reset_special_pacing(true)


func reset_special_pacing(clear_history: bool = false) -> void:
	special_last_spawn_phase_time = -1.0
	if clear_history:
		special_spawn_history.clear()


func prepare_phase_special_pacing() -> void:
	reset_special_pacing(false)


func _special_phase_profile(phase: int) -> Dictionary:
	return Dictionary(SPECIAL_SPAWN_PACING.get(phase, {}))


func _profile_time(profile: Dictionary, onboarding_key: String, experienced_key: String) -> float:
	if game != null and game._pacing_experienced_active():
		return float(profile.get(experienced_key, profile.get(onboarding_key, 0.0)))
	return float(profile.get(onboarding_key, 0.0))


func special_first_unlock_time(phase: int) -> float:
	var profile := _special_phase_profile(phase)
	return _profile_time(profile, "first_unlock", "experienced_first_unlock")


func special_repeat_gap(phase: int) -> float:
	var profile := _special_phase_profile(phase)
	return _profile_time(profile, "repeat_gap", "experienced_repeat_gap")


func special_kind_unlock_time(phase: int, kind: String) -> float:
	var profile := _special_phase_profile(phase)
	var onboarding_key := ""
	var experienced_key := ""
	if phase == 2:
		if kind == game.ENEMY_KAMIKAZE:
			onboarding_key = "kamikaze_unlock"
			experienced_key = "experienced_kamikaze_unlock"
		elif kind == game.ENEMY_PYRO_PENGUIN:
			onboarding_key = "pyro_unlock"
			experienced_key = "experienced_pyro_unlock"
	elif phase == 3:
		if kind == game.ENEMY_INCENSARIO:
			onboarding_key = "incensario_unlock"
			experienced_key = "experienced_incensario_unlock"
		elif kind == game.ENEMY_GUARDIAO:
			onboarding_key = "guardiao_unlock"
			experienced_key = "experienced_guardiao_unlock"
	elif phase == 6:
		if kind == game.ENEMY_CHRONAL_LEECH:
			onboarding_key = "leech_unlock"
			experienced_key = "experienced_leech_unlock"
		elif kind == game.ENEMY_MIASMA_EEL:
			onboarding_key = "eel_unlock"
			experienced_key = "experienced_eel_unlock"
		elif kind == game.ENEMY_FOSSIL_PUSTULE:
			onboarding_key = "pustule_unlock"
			experienced_key = "experienced_pustule_unlock"
	if onboarding_key == "":
		return special_first_unlock_time(phase)
	return _profile_time(profile, onboarding_key, experienced_key)


func is_phase_special_kind(phase: int, kind: String) -> bool:
	match phase:
		2:
			return kind == game.ENEMY_KAMIKAZE or kind == game.ENEMY_PYRO_PENGUIN
		3:
			return kind == game.ENEMY_DEVOTO or kind == game.ENEMY_INCENSARIO or kind == game.ENEMY_GUARDIAO
		4, 5:
			return kind in [game.ENEMY_NEXUS_CARTOGRAPHER, game.ENEMY_NEXUS_CHRONOPHAGE, game.ENEMY_NEXUS_REFRACTOR, game.ENEMY_NEXUS_WEAVER, game.ENEMY_NEXUS_ECHO]
		6:
			return kind == game.ENEMY_CHRONAL_LEECH or kind == game.ENEMY_MIASMA_EEL or kind == game.ENEMY_FOSSIL_PUSTULE
		7:
			return kind == game.ENEMY_PANGOLIRO or kind == game.ENEMY_CORVOL
	return false


func _special_spawn_due() -> bool:
	if game == null or game.current_phase < 2 or game.current_phase > 7:
		return false
	var elapsed: float = game._phase_elapsed_time()
	if elapsed < special_first_unlock_time(game.current_phase):
		return false
	if special_last_spawn_phase_time < 0.0:
		return true
	return elapsed - special_last_spawn_phase_time >= special_repeat_gap(game.current_phase)


func paced_special_type() -> String:
	if not _special_spawn_due():
		return ""
	var phase: int = game.current_phase
	var elapsed: float = game._phase_elapsed_time()
	match phase:
		2:
			if elapsed >= special_kind_unlock_time(phase, game.ENEMY_PYRO_PENGUIN) and game._enemy_type_count(game.ENEMY_PYRO_PENGUIN) < game.PHASE2_PYRO_LIMIT:
				return game.ENEMY_PYRO_PENGUIN
			if elapsed >= special_kind_unlock_time(phase, game.ENEMY_KAMIKAZE) and game._enemy_type_count(game.ENEMY_KAMIKAZE) < game.PHASE2_KAMIKAZE_LIMIT:
				return game.ENEMY_KAMIKAZE
		3:
			var candidates: Array[String] = []
			if elapsed >= special_first_unlock_time(phase) and game._enemy_type_count(game.ENEMY_DEVOTO) < 3:
				candidates.append(game.ENEMY_DEVOTO)
			if elapsed >= special_kind_unlock_time(phase, game.ENEMY_INCENSARIO) and game._enemy_type_count(game.ENEMY_INCENSARIO) < 2:
				candidates.append(game.ENEMY_INCENSARIO)
			if elapsed >= special_kind_unlock_time(phase, game.ENEMY_GUARDIAO) and game._enemy_type_count(game.ENEMY_GUARDIAO) < 1:
				candidates.append(game.ENEMY_GUARDIAO)
			if not candidates.is_empty():
				return candidates[game.rng.randi_range(0, candidates.size() - 1)]
		4, 5:
			var phase4_kind: String = game._choose_phase4_enemy_type()
			return phase4_kind if is_phase_special_kind(phase, phase4_kind) else ""
		6:
			var phase6_candidates: Array[String] = []
			if elapsed >= special_kind_unlock_time(phase, game.ENEMY_CHRONAL_LEECH) and game._enemy_type_count(game.ENEMY_CHRONAL_LEECH) < 2:
				phase6_candidates.append(game.ENEMY_CHRONAL_LEECH)
			if elapsed >= special_kind_unlock_time(phase, game.ENEMY_MIASMA_EEL) and game._phase6_miasma_eel_count() < game._phase6_miasma_eel_cap():
				phase6_candidates.append(game.ENEMY_MIASMA_EEL)
			if elapsed >= special_kind_unlock_time(phase, game.ENEMY_FOSSIL_PUSTULE) and not game._has_enemy_type(game.ENEMY_FOSSIL_PUSTULE):
				phase6_candidates.append(game.ENEMY_FOSSIL_PUSTULE)
			if not phase6_candidates.is_empty():
				return phase6_candidates[game.rng.randi_range(0, phase6_candidates.size() - 1)]
		7:
			if game._enemy_type_count(game.ENEMY_PANGOLIRO) < game.PHASE7_PANGOLIRO_LIMIT:
				return game.ENEMY_PANGOLIRO
			if game._enemy_type_count(game.ENEMY_CORVOL) < game.PHASE7_CORVOL_LIMIT:
				return game.ENEMY_CORVOL
	return ""


func record_special_spawn(kind: String) -> void:
	if game == null or not is_phase_special_kind(game.current_phase, kind):
		return
	var phase_time: float = game._phase_elapsed_time()
	special_last_spawn_phase_time = phase_time
	special_spawn_history.append({
		"phase": game.current_phase,
		"phase_time": phase_time,
		"run_time": game.time_alive,
		"kind": kind
	})


func special_spawn_report() -> Dictionary:
	var by_phase: Dictionary = {}
	for entry in special_spawn_history:
		var phase_key := str(int(entry.get("phase", 0)))
		if not by_phase.has(phase_key):
			by_phase[phase_key] = {"count": 0, "intervals": [], "kinds": {}}
		var phase_report: Dictionary = by_phase[phase_key]
		phase_report["count"] = int(phase_report.get("count", 0)) + 1
		var kind := String(entry.get("kind", ""))
		var kinds: Dictionary = phase_report.get("kinds", {})
		kinds[kind] = int(kinds.get(kind, 0)) + 1
		phase_report["kinds"] = kinds
		var phase_entries: Array = special_spawn_history.filter(func(item): return int(item.get("phase", 0)) == int(entry.get("phase", 0)))
		if phase_entries.size() >= 2 and phase_entries[-1] == entry:
			var previous: Dictionary = phase_entries[-2]
			var intervals: Array = phase_report.get("intervals", [])
			intervals.append(maxf(0.0, float(entry.get("phase_time", 0.0)) - float(previous.get("phase_time", 0.0))))
			phase_report["intervals"] = intervals
		by_phase[phase_key] = phase_report
	return {"total": special_spawn_history.size(), "by_phase": by_phase}


func update(delta: float) -> void:
	if game == null:
		return
	if not game._is_world_authority() or game.spawn_timer > 0.0 or game.boss_active or game._tutorial_blocks_normal_spawn():
		return
	spawn_wave()


func update_enemies(delta: float) -> void:
	if game == null or not game._is_world_authority():
		return
	var dead: Array = []
	var lacerante_storm: bool = not game._active_lacerante_secondary().is_empty()
	var phase1_boss_freeze: bool = game._phase1_boss_freezes_enemies()
	for enemy in game.enemies:
		if String(enemy.get("type", "")) == game.ENEMY_FOSSIL_PUSTULE:
			enemy["phase"] = float(enemy.get("phase", 0.0)) + delta * 2.0
		else:
			enemy["phase"] = float(enemy.get("phase", 0.0)) + delta * 7.0
		enemy["hit_cd"] = max(0.0, float(enemy.get("hit_cd", 0.0)) - delta)
		enemy["contact_grace"] = maxf(0.0, float(enemy.get("contact_grace", 0.0)) - delta)
		enemy["stun"] = max(0.0, float(enemy.get("stun", 0.0)) - delta)
		enemy["tesla_shock"] = maxf(0.0, float(enemy.get("tesla_shock", 0.0)) - delta)
		if float(enemy.get("eletrica_static_timer", 0.0)) > 0.0:
			enemy["eletrica_static_timer"] = maxf(0.0, float(enemy.get("eletrica_static_timer", 0.0)) - delta)
			if float(enemy["eletrica_static_timer"]) <= 0.0:
				enemy["eletrica_static_stacks"] = 0
				enemy["eletrica_static_last_source"] = ""
		enemy["ferrolho_root"] = max(0.0, float(enemy.get("ferrolho_root", 0.0)) - delta)
		enemy["blind_confusion"] = max(0.0, float(enemy.get("blind_confusion", 0.0)) - delta)
		enemy["resonant_stun_notes"] = max(0.0, float(enemy.get("resonant_stun_notes", 0.0)) - delta)
		enemy["shield_flash"] = max(0.0, float(enemy.get("shield_flash", 0.0)) - delta)
		enemy["reconstitute_time"] = max(0.0, float(enemy.get("reconstitute_time", 0.0)) - delta)
		enemy["reconstitute_immunity"] = max(0.0, float(enemy.get("reconstitute_immunity", 0.0)) - delta)
		enemy["evolution_slow"] = max(0.0, float(enemy.get("evolution_slow", 0.0)) - delta)
		if float(enemy["evolution_slow"]) <= 0.0:
			enemy["evolution_slow_mult"] = 1.0
		enemy["fragilidade_cronal"] = max(0.0, float(enemy.get("fragilidade_cronal", 0.0)) - delta)
		if float(enemy["fragilidade_cronal"]) <= 0.0:
			enemy["fragilidade_cronal_bonus"] = 0.0
		game._update_shield_reflector(enemy, delta)
		game._update_enemy_dots(enemy, delta)
		if float(enemy.get("hp", 0.0)) <= 0.0:
			dead.append(enemy)
			continue
		if phase1_boss_freeze:
			continue
		if enemy["type"] == game.ENEMY_CURATER:
			game._update_curater(enemy, delta)
		if enemy["type"] == game.ENEMY_STALKER:
			game._update_stalker(enemy, delta)
		if enemy["type"] == game.ENEMY_PROJECTOR:
			game._update_projector(enemy, delta)
		if enemy["type"] == game.ENEMY_ATIRADOR:
			game._update_atirador(enemy, delta)
		if enemy["type"] == game.ENEMY_KAMIKAZE:
			game._update_kamikaze(enemy, delta)
		if enemy["type"] == game.ENEMY_LARAPIO:
			game._update_larapio(enemy, delta)
		if enemy["type"] == game.ENEMY_FOSSIL_PUSTULE and game._update_fossil_pustule(enemy, delta):
			dead.append(enemy)
			continue
		if enemy["type"] == game.ENEMY_LODARIO:
			game._update_lodario(enemy, delta)
		if enemy["type"] == game.ENEMY_MIASMA_EEL:
			game._update_miasma_eel(enemy, delta)
		if enemy["type"] == game.ENEMY_CHRONAL_LEECH:
			if game._update_sanguessuga_cronal(enemy, delta):
				dead.append(enemy)
				continue
		if enemy["type"] == game.ENEMY_CINERIDO:
			game._update_cinerido(enemy, delta)
		if enemy["type"] == game.ENEMY_PANGOLIRO:
			game._update_pangoliro(enemy, delta)
		if enemy["type"] == game.ENEMY_CORVOL:
			game._update_corvol(enemy, delta)
		if enemy["type"] == game.ENEMY_COUT_ATTACK_SPEED:
			game._update_cout_attack_speed(enemy, delta)
		if enemy["type"] == game.ENEMY_PYRO_PENGUIN:
			game._update_pyro_penguin(enemy, delta)
		if game.current_phase == 2 and enemy["type"] == game.ENEMY_COMMON:
			game._update_phase2_common_penguin(enemy, delta)
		if game.current_phase == 3:
			game._update_phase3_enemy(enemy, delta)
		elif game.current_phase == 4:
			game._update_phase4_enemy(enemy, delta)
		var is_disco: bool = not game._active_prismatica_secondary().is_empty()
		var custom_phase6_move: bool = String(enemy.get("type", "")) == game.ENEMY_LODARIO or String(enemy.get("type", "")) == game.ENEMY_MIASMA_EEL or String(enemy.get("type", "")) == game.ENEMY_CHRONAL_LEECH
		var custom_phase7_move: bool = String(enemy.get("type", "")) == game.ENEMY_CINERIDO or String(enemy.get("type", "")) == game.ENEMY_PANGOLIRO or String(enemy.get("type", "")) == game.ENEMY_CORVOL
		if not custom_phase6_move and not custom_phase7_move and float(enemy.get("stun", 0.0)) <= 0.0 and float(enemy.get("ferrolho_root", 0.0)) <= 0.0 and (not bool(enemy.get("parado", false)) or is_disco):
			game._move_enemy(enemy, delta)

		var t_pos: Vector2 = game._get_nearest_player_pos(Vector2(enemy["pos"]))
		if not lacerante_storm and enemy["type"] == game.ENEMY_KAMIKAZE and Vector2(enemy["pos"]).distance_to(t_pos) < 60.0:
			if game._target_pos_is_local_player(t_pos):
				game._damage_player(game.player_hp_max * 0.15, game.ENEMY_KAMIKAZE)
				if not game._player_invulnerable():
					game.player_stun_timer = game._hostile_control_duration(1.0)
					game._add_text("CONGELADO!", game.player_pos + Vector2(0, -40), Color(0.0, 0.88, 1.0), 1.5, 20)
					game._spawn_radial_particles(Vector2(enemy["pos"]), Color(0.6, 0.9, 1.0), 16)
			else:
				var kamikaze_peer: int = game._peer_id_at_target_pos(t_pos)
				if kamikaze_peer != 0:
					game._send_peer_damage(kamikaze_peer, int(game.player_hp_max * 0.15), game.ENEMY_KAMIKAZE)
			enemy["hp"] = -1.0
			continue

		var contact_blocked: bool = String(enemy.get("type", "")) == game.ENEMY_CHRONAL_LEECH
		if not lacerante_storm and not contact_blocked and not bool(enemy.get("invisible", false)) and float(enemy.get("hit_cd", 0.0)) <= 0.0:
			var remnant_hit: Dictionary = game._necronada_remnant_at_pos(Vector2(enemy.get("pos", game.player_pos)), 48.0)
			if not remnant_hit.is_empty():
				enemy["hit_cd"] = 0.55
				game._damage_necronada_remnant(remnant_hit, game._enemy_damage(enemy))
			elif game._local_player_damageable_by_contact() and Vector2(enemy["pos"]).distance_to(game.player_pos) < 46.0:
				enemy["hit_cd"] = 0.55
				game._damage_player(game._enemy_damage(enemy), enemy["type"])
			else:
				for peer_id in game._targetable_remote_peer_ids():
					var remote_state: Dictionary = game.net_players_by_peer.get(peer_id, {})
					if Vector2(enemy["pos"]).distance_to(Vector2(remote_state.get("pos", Vector2(-10000, -10000)))) < 46.0:
						enemy["hit_cd"] = 0.55
						game._send_peer_damage(peer_id, game._enemy_damage(enemy), enemy["type"])
						break

	for enemy in dead:
		game._kill_enemy(enemy)


func spawn_wave() -> void:
	if game == null or not game._is_world_authority():
		return
	game.spawn_timer = get_enemy_spawn_interval()
	if game.boss_active or game._arauto_active():
		return
	var limit = get_enemy_limit()
	if game.enemies.size() >= limit:
		return
	var kind = game._choose_enemy_type()
	game._spawn_enemy(kind, game._spawn_point_for_type(kind))


func get_enemy_limit(native_only: bool = false) -> int:
	var mp_bonus: int = game._multiplayer_enemy_limit_bonus()
	var native_limit: int = 0
	if game.current_phase == 7:
		native_limit = _phase7_enemy_limit() + mp_bonus
	elif game.current_phase == 6:
		native_limit = _phase6_enemy_limit() + mp_bonus
	elif game.current_phase == 5:
		native_limit = 5 + mp_bonus
	elif game.current_phase == 4:
		native_limit = (game.PHASE4_LIMIT_EARLY if game._phase_elapsed_time() < game._phase4_adapt_time() else game.PHASE4_LIMIT_FULL) + mp_bonus
	elif game.current_phase == 3:
		var elapsed3: float = game._phase_elapsed_time()
		native_limit = (game.PHASE3_LIMIT_EARLY if elapsed3 < game._phase3_common_only_time() else (game.PHASE3_LIMIT_MID if elapsed3 < game._phase3_guardiao_unlock_time() else game.PHASE3_LIMIT_FULL)) + mp_bonus
	elif game.current_phase == 2:
		var elapsed: float = game._phase_elapsed_time()
		native_limit = game.PHASE2_COMMON_LIMIT + (game.PHASE2_KAMIKAZE_LIMIT if elapsed >= game._phase2_kamikaze_unlock_time() else 0) + (game.PHASE2_PYRO_LIMIT if elapsed >= game._phase2_pyro_unlock_time() else 0) + mp_bonus
	else:
		var elapsed1: float = game._phase_elapsed_time()
		if elapsed1 >= game.PHASE1_LIMIT_BREAK_TIME:
			if game.phase1_limit_break_kills_start < 0:
				game.phase1_limit_break_kills_start = game.enemies_killed
			var kills_after_break = max(0, game.enemies_killed - game.phase1_limit_break_kills_start)
			native_limit = game.ENEMY_MAX_BASE + int(floor(float(kills_after_break) / float(game.PHASE1_LIMIT_KILLS_PER_EXTRA))) + mp_bonus
		else:
			game.phase1_limit_break_kills_start = -1
			native_limit = game.ENEMY_MAX_BASE + mp_bonus
	native_limit += game._long_run_enemy_limit_bonus()
	if native_only or game.current_phase <= 1 or phase_density_carry_cap <= 0:
		return native_limit
	var growth_after_entry: int = maxi(0, native_limit - phase_density_native_entry_cap)
	return phase_density_carry_cap + growth_after_entry


func prepare_phase_density_carry(previous_effective_cap: int) -> void:
	if game == null or game.current_phase <= 1:
		phase_density_carry_cap = 0
		phase_density_native_entry_cap = 0
		return
	phase_density_carry_cap = maxi(1, int(floor(float(maxi(1, previous_effective_cap)) * PHASE_DENSITY_CARRY_RATIO)))
	phase_density_native_entry_cap = get_enemy_limit(true)


func get_enemy_spawn_interval() -> float:
	if game.current_phase == 7:
		return _phase7_spawn_interval()
	if game.current_phase == 6:
		return _phase6_spawn_interval()
	if game.current_phase == 5:
		return _long_run_spawn_interval(1.1)
	if game.current_phase == 4:
		return _long_run_spawn_interval(1.42 if game._phase_elapsed_time() < game._phase4_adapt_time() else 1.24)
	var interval = game.ENEMY_SPAWN_INTERVAL
	if game.current_phase == 3:
		var elapsed3: float = game._phase_elapsed_time()
		interval = 1.3 if elapsed3 < game._phase3_common_only_time() else (1.16 if elapsed3 < game._phase3_guardiao_unlock_time() else 1.02)
		interval = _long_run_spawn_interval(interval)
		if not game._active_prismatica_secondary().is_empty():
			interval *= 0.5
		return interval
	if game.current_phase == 2:
		var elapsed: float = game._phase_elapsed_time()
		interval = 1.32 if elapsed < game._phase2_kamikaze_unlock_time() else (1.12 if elapsed < game._phase2_pyro_unlock_time() else 0.98)
		interval = _long_run_spawn_interval(interval)
		if not game._active_prismatica_secondary().is_empty():
			interval *= 0.5
		return interval
	if game.current_phase != 2:
		var ramp_window = max(1.0, game.ENEMY_RAMP_PEAK_TIME - game.ENEMY_RAMP_START_TIME)
		var progress = clamp((game._phase_elapsed_time() - game.ENEMY_RAMP_START_TIME) / ramp_window, 0.0, 1.0)
		interval = lerp(game.ENEMY_SPAWN_INTERVAL_EARLY, game.ENEMY_SPAWN_INTERVAL_LATE, progress)
	interval = _long_run_spawn_interval(interval)
	if not game._active_prismatica_secondary().is_empty():
		interval *= 0.5
	return interval


func _long_run_spawn_interval(interval: float) -> float:
	return maxf(0.36, interval * game._long_run_spawn_interval_multiplier())


func get_curater_limit() -> int:
	return 3 if game._phase_elapsed_time() < 1500.0 else 5


func _phase6_enemy_limit() -> int:
	var elapsed: float = game._phase_elapsed_time()
	if elapsed >= game.PHASE1_LIMIT_BREAK_TIME:
		if game.phase1_limit_break_kills_start < 0:
			game.phase1_limit_break_kills_start = game.enemies_killed
		var kills_after_break = max(0, game.enemies_killed - game.phase1_limit_break_kills_start)
		return game.ENEMY_MAX_BASE + int(floor(float(kills_after_break) / float(game.PHASE1_LIMIT_KILLS_PER_EXTRA)))
	game.phase1_limit_break_kills_start = -1
	return game.ENEMY_MAX_BASE


func _phase7_enemy_limit() -> int:
	var elapsed: float = game._phase_elapsed_time()
	if elapsed >= game.PHASE7_LIMIT_BREAK_TIME:
		if game.phase1_limit_break_kills_start < 0:
			game.phase1_limit_break_kills_start = game.enemies_killed
		var kills_after_break = max(0, game.enemies_killed - game.phase1_limit_break_kills_start)
		return game.PHASE7_ENEMY_LIMIT_BASE + int(floor(float(kills_after_break) / float(game.PHASE7_LIMIT_KILLS_PER_EXTRA)))
	game.phase1_limit_break_kills_start = -1
	return game.PHASE7_ENEMY_LIMIT_BASE


func _phase6_spawn_interval() -> float:
	var ramp_window = max(1.0, game.ENEMY_RAMP_PEAK_TIME - game.ENEMY_RAMP_START_TIME)
	var progress = clamp((game._phase_elapsed_time() - game.ENEMY_RAMP_START_TIME) / ramp_window, 0.0, 1.0)
	var interval = _long_run_spawn_interval(lerp(game.ENEMY_SPAWN_INTERVAL_EARLY, game.ENEMY_SPAWN_INTERVAL_LATE, progress))
	if not game._active_prismatica_secondary().is_empty():
		interval *= 0.5
	return interval


func _phase7_spawn_interval() -> float:
	var progress: float = clampf(game._phase_elapsed_time() / 300.0, 0.0, 1.0)
	var interval: float = _long_run_spawn_interval(lerpf(1.22, 0.92, progress))
	if not game._active_prismatica_secondary().is_empty():
		interval *= 0.5
	return interval
