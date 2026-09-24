class_name EnemyManager
extends Node

var game: Node = null


func bind_game(p_game: Node) -> void:
	game = p_game


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


func get_enemy_limit() -> int:
	var mp_bonus: int = game._multiplayer_enemy_limit_bonus()
	if game.current_phase == 7:
		return _phase7_enemy_limit() + mp_bonus
	if game.current_phase == 6:
		return _phase6_enemy_limit() + mp_bonus
	if game.current_phase == 5:
		return 5 + mp_bonus
	if game.current_phase == 4:
		return (game.PHASE4_LIMIT_EARLY if game._phase_elapsed_time() < game.PHASE4_ADAPT_TIME else game.PHASE4_LIMIT_FULL) + mp_bonus
	if game.current_phase == 3:
		var elapsed3: float = game._phase_elapsed_time()
		if elapsed3 < game.PHASE3_COMMON_ONLY_TIME:
			return game.PHASE3_LIMIT_EARLY + mp_bonus
		if elapsed3 < game.PHASE3_GUARDIAO_UNLOCK_TIME:
			return game.PHASE3_LIMIT_MID + mp_bonus
		return game.PHASE3_LIMIT_FULL + mp_bonus
	if game.current_phase == 2:
		var elapsed: float = game._phase_elapsed_time()
		if elapsed >= game.PHASE2_PYRO_UNLOCK_TIME:
			return game.PHASE2_COMMON_LIMIT + game.PHASE2_KAMIKAZE_LIMIT + game.PHASE2_PYRO_LIMIT + mp_bonus
		if elapsed >= game.PHASE2_KAMIKAZE_UNLOCK_TIME:
			return game.PHASE2_COMMON_LIMIT + game.PHASE2_KAMIKAZE_LIMIT + mp_bonus
		return game.PHASE2_COMMON_LIMIT + mp_bonus
	var elapsed1: float = game._phase_elapsed_time()
	if elapsed1 >= game.PHASE1_LIMIT_BREAK_TIME:
		if game.phase1_limit_break_kills_start < 0:
			game.phase1_limit_break_kills_start = game.enemies_killed
		var kills_after_break = max(0, game.enemies_killed - game.phase1_limit_break_kills_start)
		return game.ENEMY_MAX_BASE + int(floor(float(kills_after_break) / float(game.PHASE1_LIMIT_KILLS_PER_EXTRA))) + mp_bonus
	game.phase1_limit_break_kills_start = -1
	return game.ENEMY_MAX_BASE + mp_bonus


func get_enemy_spawn_interval() -> float:
	if game.current_phase == 7:
		return _phase7_spawn_interval()
	if game.current_phase == 6:
		return _phase6_spawn_interval()
	if game.current_phase == 5:
		return 1.1
	if game.current_phase == 4:
		return 1.42 if game._phase_elapsed_time() < game.PHASE4_ADAPT_TIME else 1.24
	var interval = game.ENEMY_SPAWN_INTERVAL
	if game.current_phase == 3:
		var elapsed3: float = game._phase_elapsed_time()
		interval = 1.3 if elapsed3 < game.PHASE3_COMMON_ONLY_TIME else (1.16 if elapsed3 < game.PHASE3_GUARDIAO_UNLOCK_TIME else 1.02)
		if not game._active_prismatica_secondary().is_empty():
			interval *= 0.5
		return interval
	if game.current_phase == 2:
		var elapsed: float = game._phase_elapsed_time()
		interval = 1.32 if elapsed < game.PHASE2_KAMIKAZE_UNLOCK_TIME else (1.12 if elapsed < game.PHASE2_PYRO_UNLOCK_TIME else 0.98)
		if not game._active_prismatica_secondary().is_empty():
			interval *= 0.5
		return interval
	if game.current_phase != 2:
		var ramp_window = max(1.0, game.ENEMY_RAMP_PEAK_TIME - game.ENEMY_RAMP_START_TIME)
		var progress = clamp((game._phase_elapsed_time() - game.ENEMY_RAMP_START_TIME) / ramp_window, 0.0, 1.0)
		interval = lerp(game.ENEMY_SPAWN_INTERVAL_EARLY, game.ENEMY_SPAWN_INTERVAL_LATE, progress)
	if not game._active_prismatica_secondary().is_empty():
		interval *= 0.5
	return interval


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
	var interval = lerp(game.ENEMY_SPAWN_INTERVAL_EARLY, game.ENEMY_SPAWN_INTERVAL_LATE, progress)
	if not game._active_prismatica_secondary().is_empty():
		interval *= 0.5
	return interval


func _phase7_spawn_interval() -> float:
	var progress: float = clampf(game._phase_elapsed_time() / 300.0, 0.0, 1.0)
	var interval: float = lerpf(1.22, 0.92, progress)
	if not game._active_prismatica_secondary().is_empty():
		interval *= 0.5
	return interval
