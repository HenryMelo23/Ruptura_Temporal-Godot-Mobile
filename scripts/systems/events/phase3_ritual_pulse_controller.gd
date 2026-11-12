class_name RTPhase3RitualPulseController
extends Node

## Ritual da Catedral (Fase 3) — evento jogavel.
##
## Cada circulo recebe um Oficiante (Devoto) e ate dois Fieis. Enquanto o
## Oficiante dança dentro do circulo ele fica SELADO (imune). Para quebrar o
## selo o jogador precisa PROFANAR o circulo: ficar dentro dele, e a cada
## compasso pisar na runa acesa (ou atravessar o pulso com o TP). Pulsos fora
## da runa ferem, empurram e desfazem parte da profanacao.
## Profanado, o Oficiante ajoelha atordoado e recebe dano extra; mata-lo
## dissolve o circulo. Fieis dançando aceleram o ritual; inimigos mortos
## DENTRO de um circulo alimentam o ritual (sacrificio). Cada circulo que se
## completa gera miasma e enche os inimigos proximos de fervor.
## O estado de jogo e autoritativo aqui; a apresentacao consome snapshots.

const SCHEMA_VERSION: int = 2
const FIRST_START_PHASE_TIME: float = 135.0
const CADENCE_SECONDS: float = 150.0
const RITUAL_DURATION: float = 32.0
const CHANNEL_DURATION: float = 14.0
const CHANNEL_RADIUS: float = 54.0
const CIRCLE_RADIUS: float = 96.0
const PROGRESS_DECAY_PER_SECOND: float = 0.08
const BEAT: float = 1.3
const WEDGES: int = 4
const PROFANE_TIME: float = 3.2
const PROFANE_DECAY: float = 0.22
const PULSE_DAMAGE_RATIO: float = 0.05
const PULSE_PROFANE_LOSS: float = 0.3
const PULSE_PUSH: float = 70.0
const DASH_DODGE_WINDOW: float = 0.32
const FIEIS_PER_CIRCLE: int = 2
const FIEL_RECRUIT_RANGE: float = 760.0
const FIEL_CHANNEL_BONUS: float = 0.22
const SACRIFICE_PROGRESS: float = 0.12
const BROKEN_STUN: float = 3.2
const BROKEN_DAMAGE_MULT: float = 1.5
const REWARD_POINTS_PER_CIRCLE: int = 90
const PERFECT_PROFANE_BONUS: int = 70
const FAILURE_MIASMA_RADIUS: float = 96.0
const FAILURE_MIASMA_DURATION: float = 7.0
const FAILURE_MIASMA_DAMAGE_RATIO: float = 0.01
const FAILURE_FERVOR_RANGE: float = 900.0
const FAILURE_FERVOR_TIME: float = 9.0
const RESULT_DISPLAY_TIME: float = 2.2
const FERVOR_POSE_TIME: float = 1.6

var game: Node = null
var _active: Dictionary = {}
var _next_start_phase_time: float = FIRST_START_PHASE_TIME
var _sequence: int = 0
var _rewarded_events: Dictionary = {}
var _remote_feedback_stage_by_event: Dictionary = {}
var _seal_feedback_cd: float = 0.0
var _sacrifice_feedback_cd: float = 0.0


func bind_game(owner: Node) -> void:
	game = owner


func reset() -> void:
	_unmark_all_devotees()
	_active.clear()
	_next_start_phase_time = FIRST_START_PHASE_TIME
	_sequence = 0
	_rewarded_events.clear()
	_remote_feedback_stage_by_event.clear()


func cleanup(_reason: String) -> void:
	_unmark_all_devotees()
	_active.clear()


func is_active() -> bool:
	return not _active.is_empty() and bool(_active.get("active", false))


func elapsed() -> float:
	return float(_active.get("elapsed", 0.0))


func beat_phase() -> float:
	return fposmod(elapsed(), BEAT) / BEAT


func beat_index() -> int:
	return int(floor(elapsed() / BEAT))


# ================================================================ ciclo
func update(delta: float, authority: bool) -> void:
	if game == null or delta <= 0.0:
		return
	_seal_feedback_cd = maxf(0.0, _seal_feedback_cd - delta)
	_sacrifice_feedback_cd = maxf(0.0, _sacrifice_feedback_cd - delta)
	if int(game.current_phase) != 3:
		if authority and is_active():
			cleanup("phase_changed")
		return
	if not authority:
		if is_active():
			_active["elapsed"] = elapsed() + delta
		return
	if is_active() and (bool(game.boss_active) or float(game.boss_call_timer) >= 0.0 or String(game.mode) not in ["game", "shop", "settings"]):
		cleanup("incompatible_state")
		return
	if is_active() and game._combat_targets().is_empty():
		cleanup("no_living_players")
		return
	if not is_active():
		_try_start_from_cadence()
		return
	if String(_active.get("state", "ritual")) == "result":
		_active["result_remaining"] = maxf(0.0, float(_active.get("result_remaining", 0.0)) - delta)
		_active["elapsed"] = elapsed() + delta
		if float(_active.get("result_remaining", 0.0)) <= 0.0:
			_unmark_all_devotees()
			_active.clear()
			_next_start_phase_time = float(game._phase_elapsed_time()) + CADENCE_SECONDS
		return

	var previous_beat: int = beat_index()
	_active["elapsed"] = elapsed() + delta
	_active["remaining"] = maxf(0.0, float(_active.get("remaining", RITUAL_DURATION)) - delta)
	_refresh_missing_devotees()
	_update_profanation(delta)
	if beat_index() != previous_beat:
		_resolve_beat()
	_check_consummations()
	if _all_circles_resolved():
		_finish()
	elif float(_active.get("remaining", 0.0)) <= 0.0:
		_finish()


func force_start_for_test() -> bool:
	if game == null or not game._is_world_authority():
		return false
	return _start_ritual()


# ================================================================ inimigos
## Chamado pelo controlador da fase 3 para qualquer inimigo marcado.
func update_devotee(enemy: Dictionary, delta: float) -> bool:
	if game == null or not game._is_world_authority() or not is_active():
		return false
	if String(enemy.get("phase3_ritual_event_id", "")) != String(_active.get("event_id", "")):
		return false
	var circles: Array = Array(_active.get("circles", []))
	var circle_index: int = _circle_index(circles, int(enemy.get("phase3_ritual_circle_id", -1)))
	if circle_index < 0:
		_clear_devotee_mark(enemy)
		return false
	var circle: Dictionary = Dictionary(circles[circle_index])
	var role: String = String(enemy.get("phase3_ritual_role", "officiant"))
	if String(_active.get("state", "")) == "result":
		# Comemoracao ou desespero ate o resultado sumir.
		enemy["parado"] = true
		enemy["phase3_ritual_pose"] = "fervor" if String(circle.get("outcome", "")) == "consummated" else "kneel"
		return true
	if bool(circle.get("disrupted", false)) or (role == "fiel" and (bool(circle.get("profaned", false)) or String(circle.get("outcome", "")) != "")):
		_clear_devotee_mark(enemy)
		return false
	if role == "fiel":
		_update_fiel(enemy, circle, delta)
		return true
	return _update_officiant(enemy, circles, circle_index, circle, delta)


func _update_officiant(enemy: Dictionary, circles: Array, circle_index: int, circle: Dictionary, delta: float) -> bool:
	if String(circle.get("outcome", "")) == "consummated":
		enemy["parado"] = true
		enemy["phase3_ritual_pose"] = "fervor"
		return true
	enemy["parado"] = true
	enemy["state"] = "ritual_move"
	var position: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO))
	var destination: Vector2 = Vector2(circle.get("pos", position))
	var distance: float = position.distance_to(destination)
	var stunned: bool = float(enemy.get("stun", 0.0)) > 0.0
	var rooted: bool = float(enemy.get("ferrolho_root", 0.0)) > 0.0
	var in_circle: bool = distance <= CHANNEL_RADIUS
	var channeling: bool = in_circle and not stunned
	# O circulo protege quem esta dentro dele, mesmo atordoado: so a profanacao abre o selo.
	circle["sealed"] = in_circle and not bool(circle.get("profaned", false))
	if channeling:
		enemy["state"] = "ritual_channel"
		enemy["phase3_ritual_pose"] = "dance"
		# Vira de lado a cada compasso: a dança troca de pe.
		enemy["facing_dir"] = Vector2.RIGHT if beat_index() % 2 == 0 else Vector2.LEFT
		circle["occupied"] = true
		var speed: float = 1.0 + FIEL_CHANNEL_BONUS * float(_dancing_fieis(circle))
		circle["progress"] = minf(1.0, float(circle.get("progress", 0.0)) + delta * speed / CHANNEL_DURATION)
	else:
		circle["occupied"] = false
		enemy["phase3_ritual_pose"] = "kneel" if stunned else "procession"
		circle["progress"] = maxf(0.0, float(circle.get("progress", 0.0)) - delta * PROGRESS_DECAY_PER_SECOND)
		if not stunned and not rooted and distance > 1.0:
			var direction: Vector2 = (destination - position).normalized()
			direction = game._steer_entity_with_avoidance(enemy, position, direction, delta)
			var ritual_speed: float = float(enemy.get("speed", 100.0)) * 0.82
			enemy["pos"] = (position + direction * ritual_speed * delta).clamp(Vector2(40.0, 40.0), game.WORLD_SIZE - Vector2(40.0, 40.0))
			enemy["last_move_dir"] = direction
			enemy["facing_dir"] = direction
	circles[circle_index] = circle
	_active["circles"] = circles
	return true


func _update_fiel(enemy: Dictionary, circle: Dictionary, delta: float) -> void:
	enemy["parado"] = true
	var slot: int = int(enemy.get("phase3_ritual_slot", 0))
	var center: Vector2 = Vector2(circle.get("pos", enemy.get("pos", Vector2.ZERO)))
	var angle: float = float(circle.get("phase", 0.0)) + float(slot) * PI + elapsed() * 0.45
	var spot: Vector2 = center + Vector2.from_angle(angle) * CIRCLE_RADIUS * 0.74
	var position: Vector2 = Vector2(enemy.get("pos", spot))
	var distance: float = position.distance_to(spot)
	if float(enemy.get("stun", 0.0)) > 0.0:
		enemy["phase3_ritual_pose"] = "kneel"
		enemy["phase3_ritual_dancing"] = false
		return
	if distance > 26.0:
		enemy["phase3_ritual_pose"] = "procession"
		enemy["phase3_ritual_dancing"] = false
		var direction: Vector2 = (spot - position).normalized()
		direction = game._steer_entity_with_avoidance(enemy, position, direction, delta)
		var speed: float = float(enemy.get("speed", 100.0)) * (0.9 if distance > 120.0 else 0.6)
		enemy["pos"] = (position + direction * speed * delta).clamp(Vector2(40.0, 40.0), game.WORLD_SIZE - Vector2(40.0, 40.0))
		enemy["facing_dir"] = direction
	else:
		# Gira em volta do circulo, de frente para o centro, reverenciando no compasso.
		enemy["pos"] = position.move_toward(spot, 90.0 * delta)
		enemy["phase3_ritual_pose"] = "worship"
		enemy["phase3_ritual_dancing"] = true
		enemy["facing_dir"] = (center - position).normalized()


## O Oficiante dançando dentro do circulo nao recebe dano ate o selo quebrar.
func blocks_damage(enemy: Dictionary, show_feedback: bool = true) -> bool:
	if not is_active() or String(enemy.get("phase3_ritual_role", "")) != "officiant":
		return false
	var circle: Dictionary = _circle_for_enemy(enemy)
	if circle.is_empty() or not bool(circle.get("sealed", false)):
		return false
	if show_feedback and _seal_feedback_cd <= 0.0 and game != null:
		_seal_feedback_cd = 0.9
		game._add_text("SELADO: ENTRE NO CIRCULO", Vector2(enemy.get("pos", game.player_pos)) + Vector2(-96, -58), Color(0.9, 0.46, 1.0), 0.85, 16)
	return true


func damage_taken_multiplier(enemy: Dictionary) -> float:
	if not is_active() or String(enemy.get("phase3_ritual_role", "")) != "officiant":
		return 1.0
	var circle: Dictionary = _circle_for_enemy(enemy)
	return BROKEN_DAMAGE_MULT if bool(circle.get("profaned", false)) else 1.0


func on_enemy_defeated(enemy: Dictionary) -> void:
	if not is_active() or String(_active.get("state", "")) != "ritual":
		return
	var circles: Array = Array(_active.get("circles", []))
	var is_officiant: bool = String(enemy.get("phase3_ritual_event_id", "")) == String(_active.get("event_id", "")) and String(enemy.get("phase3_ritual_role", "officiant")) == "officiant"
	if is_officiant:
		var circle_index: int = _circle_index(circles, int(enemy.get("phase3_ritual_circle_id", -1)))
		if circle_index >= 0:
			var circle: Dictionary = Dictionary(circles[circle_index])
			if String(circle.get("outcome", "")) == "":
				circle["disrupted"] = true
				circle["outcome"] = "disrupted"
				circle["occupied"] = false
				circle["sealed"] = false
				circle["progress"] = 0.0
				circles[circle_index] = circle
				_active["circles"] = circles
				game._spawn_radial_particles(Vector2(enemy.get("pos", game.player_pos)), Color(0.58, 1.0, 0.36), 16)
				game._add_text("CIRCULO DISSOLVIDO", Vector2(circle.get("pos", game.player_pos)) + Vector2(-86, -112), Color(0.62, 1.0, 0.42), 1.1, 19)
		_clear_devotee_mark(enemy)
		if _all_circles_resolved():
			_finish()
		return
	# Sacrificio: qualquer outro inimigo morto dentro de um circulo ativo alimenta o ritual.
	var pos: Vector2 = Vector2(enemy.get("pos", Vector2.INF))
	for i in range(circles.size()):
		var circle: Dictionary = Dictionary(circles[i])
		if String(circle.get("outcome", "")) != "" or bool(circle.get("disrupted", false)):
			continue
		if pos.distance_to(Vector2(circle.get("pos", Vector2.ZERO))) > float(circle.get("radius", CIRCLE_RADIUS)):
			continue
		circle["progress"] = minf(1.0, float(circle.get("progress", 0.0)) + SACRIFICE_PROGRESS)
		circle["sacrifices"] = int(circle.get("sacrifices", 0)) + 1
		circles[i] = circle
		if _sacrifice_feedback_cd <= 0.0:
			_sacrifice_feedback_cd = 1.2
			game._add_text("O SANGUE ALIMENTA O RITUAL", pos + Vector2(-120, -70), Color(0.95, 0.3, 0.55), 1.0, 17)
		game._spawn_radial_particles(pos, Color(0.85, 0.16, 0.42), 8)
		break
	_active["circles"] = circles
	_clear_devotee_mark(enemy)


# ================================================================ profanacao
func _update_profanation(delta: float) -> void:
	var circles: Array = Array(_active.get("circles", []))
	var targets: Array = game._combat_targets()
	for i in range(circles.size()):
		var circle: Dictionary = Dictionary(circles[i])
		if String(circle.get("outcome", "")) != "" or bool(circle.get("profaned", false)):
			circle["intruder"] = false
			circles[i] = circle
			continue
		var center: Vector2 = Vector2(circle.get("pos", Vector2.ZERO))
		var inside := false
		for value in targets:
			if Vector2(Dictionary(value).get("pos", Vector2.INF)).distance_to(center) <= float(circle.get("radius", CIRCLE_RADIUS)):
				inside = true
				break
		circle["intruder"] = inside
		var profane: float = float(circle.get("profane", 0.0))
		if inside and bool(circle.get("sealed", false)):
			profane = minf(1.0, profane + delta / PROFANE_TIME)
		elif not inside:
			profane = maxf(0.0, profane - delta * PROFANE_DECAY)
		circle["profane"] = profane
		if profane >= 1.0:
			circle = _break_seal(circle)
		circles[i] = circle
	_active["circles"] = circles


func _break_seal(circle: Dictionary) -> Dictionary:
	circle["profaned"] = true
	circle["broken_at"] = elapsed()
	circle["sealed"] = false
	circle["perfect"] = int(circle.get("hits_taken", 0)) == 0
	var center: Vector2 = Vector2(circle.get("pos", game.player_pos))
	var officiant: Dictionary = _enemy_by_uid(int(circle.get("devotee_uid", -1)))
	if not officiant.is_empty():
		officiant["stun"] = maxf(float(officiant.get("stun", 0.0)), BROKEN_STUN)
		officiant["phase3_ritual_pose"] = "kneel"
	game._add_text("SELO QUEBRADO" + (" · DANÇA PERFEITA" if bool(circle["perfect"]) else ""), center + Vector2(-120, -118), Color(1.0, 0.86, 0.4), 1.4, 22)
	game._spawn_radial_particles(center, Color(1.0, 0.82, 0.36), 22)
	game._play_sfx("boss_impact", 0.02, 0.32, 1.4)
	return circle


## Pulso do compasso: fere quem esta dentro de um circulo selado fora da runa
## acesa. O TP recente atravessa o pulso sem dano.
func _resolve_beat() -> void:
	var circles: Array = Array(_active.get("circles", []))
	for i in range(circles.size()):
		var circle: Dictionary = Dictionary(circles[i])
		if String(circle.get("outcome", "")) != "" or bool(circle.get("profaned", false)) or not bool(circle.get("sealed", false)):
			circle["safe_wedge"] = _next_wedge(int(circle.get("safe_wedge", 0)))
			circles[i] = circle
			continue
		circle["pulse_beat"] = beat_index()
		var center: Vector2 = Vector2(circle.get("pos", Vector2.ZERO))
		var radius: float = float(circle.get("radius", CIRCLE_RADIUS))
		var safe: int = int(circle.get("safe_wedge", 0))
		# Jogador local.
		if game._local_player_targetable() and game.player_pos.distance_to(center) <= radius:
			if wedge_of(game.player_pos - center) == safe:
				circle["profane"] = minf(1.0, float(circle.get("profane", 0.0)) + 0.08)
				game._add_text("NO COMPASSO", game.player_pos + Vector2(-50, -86), Color(1.0, 0.9, 0.5), 0.55, 15)
			elif float(game.time_alive) - float(game.last_dash_time) <= DASH_DODGE_WINDOW:
				game._add_text("ATRAVESSOU O PULSO", game.player_pos + Vector2(-80, -86), Color(0.6, 1.0, 0.9), 0.6, 15)
			else:
				var amount: int = maxi(1, int(round(float(game.player_hp_max) * PULSE_DAMAGE_RATIO)))
				game._damage_player(amount, "phase3_ritual_pulse")
				var push_dir: Vector2 = (game.player_pos - center).normalized()
				if push_dir.length() < 0.1:
					push_dir = Vector2.RIGHT
				game.player_pos = game._clamp_player_world(game.player_pos + push_dir * PULSE_PUSH)
				circle["profane"] = maxf(0.0, float(circle.get("profane", 0.0)) - PULSE_PROFANE_LOSS)
				circle["hits_taken"] = int(circle.get("hits_taken", 0)) + 1
		# Jogadores remotos (so dano; a profanacao e compartilhada pelo circulo).
		if bool(game.is_multiplayer):
			for peer_id in game._targetable_remote_peer_ids():
				var state: Dictionary = game.net_players_by_peer.get(peer_id, {})
				var remote_pos: Vector2 = Vector2(state.get("pos", Vector2.INF))
				if remote_pos.distance_to(center) > radius or wedge_of(remote_pos - center) == safe:
					continue
				game._send_peer_damage(peer_id, maxi(1, int(round(float(state.get("hp_max", 450.0)) * PULSE_DAMAGE_RATIO))), "phase3_ritual_pulse")
		circle["safe_wedge"] = _next_wedge(safe)
		circles[i] = circle
	_active["circles"] = circles
	game._play_sfx("Portal.mp3", 0.05, 0.16, 1.5)


static func wedge_of(offset: Vector2) -> int:
	return int(floor(fposmod(offset.angle(), TAU) / (TAU / float(WEDGES)))) % WEDGES


func _next_wedge(current: int) -> int:
	return (current + 1 + game.rng.randi_range(0, WEDGES - 2)) % WEDGES


# ================================================================ resultado
func _check_consummations() -> void:
	var circles: Array = Array(_active.get("circles", []))
	for i in range(circles.size()):
		var circle: Dictionary = Dictionary(circles[i])
		if String(circle.get("outcome", "")) != "" or float(circle.get("progress", 0.0)) < 1.0:
			continue
		circle["outcome"] = "consummated"
		circle["outcome_at"] = elapsed()
		circle["sealed"] = false
		circle["occupied"] = false
		circles[i] = circle
		var position: Vector2 = Vector2(circle.get("pos", game.player_pos))
		game._add_phase3_miasma(position, FAILURE_MIASMA_RADIUS, FAILURE_MIASMA_DURATION, FAILURE_MIASMA_DAMAGE_RATIO)
		game._spawn_radial_particles(position, Color(0.76, 0.16, 0.56), 20)
		game._add_text("CIRCULO CONSUMADO: FERVOR", position + Vector2(-110, -118), Color(0.94, 0.34, 0.62), 1.4, 20)
		for enemy_value in game.enemies:
			var enemy: Dictionary = enemy_value
			if Vector2(enemy.get("pos", Vector2.INF)).distance_to(position) <= FAILURE_FERVOR_RANGE:
				enemy["phase3_fervor_timer"] = maxf(float(enemy.get("phase3_fervor_timer", 0.0)), FAILURE_FERVOR_TIME)
		game._play_sfx("boss_impact", 0.024, 0.42, 0.82)
	_active["circles"] = circles


func _all_circles_resolved() -> bool:
	var circles: Array = Array(_active.get("circles", []))
	return not circles.is_empty() and circles.all(func(value): return String(Dictionary(value).get("outcome", "")) != "" or bool(Dictionary(value).get("disrupted", false)))


func _finish() -> void:
	if String(_active.get("state", "")) != "ritual":
		return
	var circles: Array = Array(_active.get("circles", []))
	var disrupted := 0
	var consummated := 0
	var held := 0
	var perfect := 0
	for value in circles:
		var circle: Dictionary = value
		if String(circle.get("outcome", "")) == "consummated":
			consummated += 1
			continue
		if bool(circle.get("disrupted", false)):
			disrupted += 1
		else:
			held += 1
		if bool(circle.get("perfect", false)) and bool(circle.get("profaned", false)):
			perfect += 1
	var event_id: String = String(_active.get("event_id", ""))
	# Dissolvido = pontuacao cheia; contido ate o fim do tempo = metade.
	var reward: int = disrupted * REWARD_POINTS_PER_CIRCLE + held * (REWARD_POINTS_PER_CIRCLE / 2) + perfect * PERFECT_PROFANE_BONUS
	if reward > 0 and not _rewarded_events.has(event_id):
		_rewarded_events[event_id] = true
		game._apply_score_delta(reward, true, event_id + ":reward")
	var result: String = "success" if consummated == 0 else ("failure" if disrupted + held == 0 else "partial")
	var reason: String = "all_devotees_defeated" if circles.all(func(v): return bool(Dictionary(v).get("disrupted", false))) else ("ritual_timeout" if float(_active.get("remaining", 0.0)) <= 0.0 else "resolved")
	_active["state"] = "result"
	_active["result"] = result
	_active["result_reason"] = reason
	_active["reward"] = reward
	_active["perfect"] = perfect
	_active["result_remaining"] = RESULT_DISPLAY_TIME
	match result:
		"success":
			game._add_text("RITUAL INTERROMPIDO  +%d" % reward, game.player_pos + Vector2(-110, -112), Color(0.62, 1.0, 0.38), 1.6, 23)
			game._spawn_radial_particles(game.player_pos, Color(0.58, 1.0, 0.34), 18)
			game._play_sfx("boss_impact", 0.018, 0.36, 1.28)
		"partial":
			game._add_text("RITUAL PARCIAL  +%d" % reward, game.player_pos + Vector2(-90, -112), Color(1.0, 0.8, 0.4), 1.5, 22)
		_:
			game._add_text("RITUAL CONCLUIDO: FERVOR", game.player_pos + Vector2(-110, -112), Color(0.92, 0.34, 0.62), 1.6, 23)
			game._play_sfx("boss_impact", 0.024, 0.48, 0.82)


# ================================================================ inicio
func _try_start_from_cadence() -> void:
	if String(game.mode) != "game" or bool(game.boss_active) or float(game.boss_call_timer) >= 0.0:
		return
	if float(game._phase_elapsed_time()) < _next_start_phase_time:
		return
	if game.runtime_event_director != null and game.runtime_event_director.is_active():
		return
	_start_ritual()


func _start_ritual() -> bool:
	if int(game.current_phase) != 3 or bool(game.boss_active) or is_active():
		return false
	var party_size: int = clampi(game._active_run_player_count(), 1, game.ONLINE_MAX_PLAYERS) if bool(game.is_multiplayer) else 1
	var circle_count: int = 3 if party_size >= 3 else 2
	_sequence += 1
	var started_ms: int = Time.get_ticks_msec()
	var event_id: String = "phase3_ritual_%d_%d" % [_sequence, started_ms]
	var circles: Array = _build_circles(circle_count)
	_active = {
		"schema_version": SCHEMA_VERSION,
		"active": true,
		"event_id": event_id,
		"seed": game.rng.randi(),
		"started_ms": started_ms,
		"started_at": snappedf(float(game._phase_elapsed_time()), 0.1),
		"state": "ritual",
		"result": "active",
		"duration": RITUAL_DURATION,
		"remaining": RITUAL_DURATION,
		"elapsed": 0.0,
		"party_size": party_size,
		"circles": circles
	}
	_assign_devotees()
	_recruit_fieis()
	game._add_text("RITUAL DA CATEDRAL", game.player_pos + Vector2(-90, -132), Color(0.76, 1.0, 0.34), 1.6, 24)
	game._add_text("Entre no circulo e pise na runa dourada no compasso", game.player_pos + Vector2(-190, -104), Color(1.0, 0.9, 0.6), 2.4, 16)
	game._play_sfx("Portal.mp3", 0.03, 0.38, 0.82)
	for circle_value in Array(_active.get("circles", [])):
		game._spawn_radial_particles(Vector2(Dictionary(circle_value).get("pos", game.player_pos)), Color(0.52, 0.9, 0.28), 10)
	return true


func _build_circles(count: int) -> Array:
	var anchor: Vector2 = _living_players_center()
	var start_angle: float = game.rng.randf_range(0.0, TAU)
	var circles: Array = []
	for index in range(count):
		var angle: float = start_angle + TAU * float(index) / float(count) + game.rng.randf_range(-0.18, 0.18)
		var distance: float = game.rng.randf_range(230.0, 320.0)
		var position: Vector2 = (anchor + Vector2.from_angle(angle) * distance).clamp(Vector2(135.0, 125.0), game.WORLD_SIZE - Vector2(135.0, 125.0))
		circles.append({
			"id": index,
			"pos": position,
			"radius": CIRCLE_RADIUS,
			"progress": 0.0,
			"occupied": false,
			"sealed": false,
			"disrupted": false,
			"profane": 0.0,
			"profaned": false,
			"perfect": false,
			"hits_taken": 0,
			"sacrifices": 0,
			"outcome": "",
			"safe_wedge": game.rng.randi_range(0, WEDGES - 1),
			"pulse_beat": -1,
			"intruder": false,
			"devotee_uid": -1,
			"fiel_uids": [],
			"phase": game.rng.randf_range(0.0, TAU)
		})
	return circles


func _assign_devotees() -> void:
	var available: Array = []
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if String(enemy.get("type", "")) == game.ENEMY_DEVOTO and float(enemy.get("hp", 0.0)) > 0.0 and not bool(enemy.get("phase3_ritual_marked", false)):
			available.append(enemy)
	var circles: Array = Array(_active.get("circles", []))
	for circle_index in range(circles.size()):
		var circle: Dictionary = Dictionary(circles[circle_index])
		var devotee: Dictionary = _nearest_available(available, Vector2(circle.get("pos", game.player_pos)), INF)
		if devotee.is_empty():
			var spawn_angle: float = game.rng.randf_range(0.0, TAU)
			var spawn_pos: Vector2 = (Vector2(circle.get("pos", game.player_pos)) + Vector2.from_angle(spawn_angle) * 190.0).clamp(Vector2(55.0, 55.0), game.WORLD_SIZE - Vector2(55.0, 55.0))
			var previous_size: int = game.enemies.size()
			game._spawn_enemy(game.ENEMY_DEVOTO, spawn_pos)
			if game.enemies.size() > previous_size:
				devotee = Dictionary(game.enemies[-1])
		if devotee.is_empty():
			circle["disrupted"] = true
			circle["outcome"] = "disrupted"
			circles[circle_index] = circle
			continue
		available.erase(devotee)
		_mark(devotee, circle, "officiant", 0)
		circle["devotee_uid"] = int(devotee.get("uid", -1))
		circles[circle_index] = circle
	_active["circles"] = circles


func _recruit_fieis() -> void:
	var available: Array = []
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if String(enemy.get("type", "")) == game.ENEMY_COMMON and float(enemy.get("hp", 0.0)) > 0.0 and not bool(enemy.get("phase3_ritual_marked", false)) and not bool(enemy.get("tutorial", false)):
			available.append(enemy)
	var circles: Array = Array(_active.get("circles", []))
	for circle_index in range(circles.size()):
		var circle: Dictionary = Dictionary(circles[circle_index])
		if bool(circle.get("disrupted", false)):
			continue
		var uids: Array = []
		for slot in range(FIEIS_PER_CIRCLE):
			var fiel: Dictionary = _nearest_available(available, Vector2(circle.get("pos", game.player_pos)), FIEL_RECRUIT_RANGE)
			if fiel.is_empty():
				break
			available.erase(fiel)
			_mark(fiel, circle, "fiel", slot)
			uids.append(int(fiel.get("uid", -1)))
		circle["fiel_uids"] = uids
		circles[circle_index] = circle
	_active["circles"] = circles


func _mark(enemy: Dictionary, circle: Dictionary, role: String, slot: int) -> void:
	enemy["phase3_ritual_marked"] = true
	enemy["phase3_ritual_event_id"] = String(_active.get("event_id", ""))
	enemy["phase3_ritual_circle_id"] = int(circle.get("id", 0))
	enemy["phase3_ritual_role"] = role
	enemy["phase3_ritual_slot"] = slot
	enemy["phase3_ritual_pose"] = "procession"


func _nearest_available(available: Array, position: Vector2, max_range: float) -> Dictionary:
	var best: Dictionary = {}
	var best_distance: float = max_range * max_range if max_range < INF else INF
	for value in available:
		var enemy: Dictionary = value
		var distance: float = Vector2(enemy.get("pos", position)).distance_squared_to(position)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


func _living_players_center() -> Vector2:
	var targets: Array = game._combat_targets()
	if targets.is_empty():
		return Vector2(game.player_pos)
	var sum: Vector2 = Vector2.ZERO
	for value in targets:
		sum += Vector2(Dictionary(value).get("pos", game.player_pos))
	return (sum / float(targets.size())).clamp(Vector2(340.0, 260.0), game.WORLD_SIZE - Vector2(340.0, 260.0))


# ================================================================ util
func _refresh_missing_devotees() -> void:
	var circles: Array = Array(_active.get("circles", []))
	for circle_index in range(circles.size()):
		var circle: Dictionary = Dictionary(circles[circle_index])
		if bool(circle.get("disrupted", false)) or String(circle.get("outcome", "")) != "":
			continue
		var devotee: Dictionary = _enemy_by_uid(int(circle.get("devotee_uid", -1)))
		if devotee.is_empty() or float(devotee.get("hp", 0.0)) <= 0.0:
			circle["disrupted"] = true
			circle["outcome"] = "disrupted"
			circle["occupied"] = false
			circle["sealed"] = false
			circle["progress"] = 0.0
			circles[circle_index] = circle
	_active["circles"] = circles


func _dancing_fieis(circle: Dictionary) -> int:
	var n := 0
	for uid in Array(circle.get("fiel_uids", [])):
		var fiel: Dictionary = _enemy_by_uid(int(uid))
		if not fiel.is_empty() and bool(fiel.get("phase3_ritual_dancing", false)) and float(fiel.get("hp", 0.0)) > 0.0:
			n += 1
	return n


func _circle_for_enemy(enemy: Dictionary) -> Dictionary:
	if String(enemy.get("phase3_ritual_event_id", "")) != String(_active.get("event_id", "")):
		return {}
	var circles: Array = Array(_active.get("circles", []))
	var index: int = _circle_index(circles, int(enemy.get("phase3_ritual_circle_id", -1)))
	return Dictionary(circles[index]) if index >= 0 else {}


func _enemy_by_uid(uid: int) -> Dictionary:
	if uid < 0:
		return {}
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if int(enemy.get("uid", -2)) == uid:
			return enemy
	return {}


func _circle_index(circles: Array, circle_id: int) -> int:
	for index in range(circles.size()):
		if int(Dictionary(circles[index]).get("id", -1)) == circle_id:
			return index
	return -1


func _overall_progress() -> float:
	var circles: Array = Array(_active.get("circles", []))
	if circles.is_empty():
		return 0.0
	var progress: float = 0.0
	for value in circles:
		progress += float(Dictionary(value).get("progress", 0.0))
	return clampf(progress / float(circles.size()), 0.0, 1.0)


func _unmark_all_devotees() -> void:
	if game == null:
		return
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if bool(enemy.get("phase3_ritual_marked", false)):
			_clear_devotee_mark(enemy)


func _clear_devotee_mark(enemy: Dictionary) -> void:
	for key in ["phase3_ritual_marked", "phase3_ritual_event_id", "phase3_ritual_circle_id", "phase3_ritual_role", "phase3_ritual_slot", "phase3_ritual_pose", "phase3_ritual_dancing"]:
		enemy.erase(key)
	if String(enemy.get("state", "")).begins_with("ritual_") or bool(enemy.get("parado", false)):
		enemy["state"] = "hunting"
		enemy["parado"] = false


func _marked_devotee_visuals() -> Array:
	var result: Array = []
	if game == null:
		return result
	var event_id: String = String(_active.get("event_id", ""))
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if String(enemy.get("phase3_ritual_event_id", "")) != event_id:
			continue
		result.append({
			"uid": int(enemy.get("uid", -1)),
			"circle_id": int(enemy.get("phase3_ritual_circle_id", -1)),
			"pos": Vector2(enemy.get("pos", Vector2.ZERO)),
			"role": String(enemy.get("phase3_ritual_role", "officiant")),
			"pose": String(enemy.get("phase3_ritual_pose", "procession")),
			"channeling": String(enemy.get("state", "")) == "ritual_channel"
		})
	return result


# ================================================================ rede
func active_snapshot() -> Dictionary:
	if not is_active():
		return {
			"schema_version": SCHEMA_VERSION,
			"active": false,
			"next_start_phase_time": snappedf(_next_start_phase_time, 0.1)
		}
	var snapshot: Dictionary = _active.duplicate(true)
	snapshot["schema_version"] = SCHEMA_VERSION
	if game != null and game._is_world_authority():
		snapshot["devotees"] = _marked_devotee_visuals()
		snapshot["overall_progress"] = snappedf(_overall_progress(), 0.001)
	else:
		snapshot["devotees"] = Array(_active.get("devotees", [])).duplicate(true)
		snapshot["overall_progress"] = float(_active.get("overall_progress", 0.0))
	return snapshot


func apply_remote_snapshot(snapshot: Dictionary) -> void:
	if int(snapshot.get("schema_version", SCHEMA_VERSION)) != SCHEMA_VERSION or not bool(snapshot.get("active", false)):
		_active.clear()
		return
	var event_id: String = String(snapshot.get("event_id", ""))
	var stage: String = String(snapshot.get("result", "active"))
	var previous_stage: String = String(_remote_feedback_stage_by_event.get(event_id, ""))
	_active = snapshot.duplicate(true)
	if event_id.is_empty() or previous_stage == stage:
		return
	_remote_feedback_stage_by_event[event_id] = stage
	if stage == "active":
		game._play_sfx("Portal.mp3", 0.03, 0.38, 0.82)
	elif stage == "success" or stage == "partial":
		game._add_text("RITUAL INTERROMPIDO", game.player_pos + Vector2(0, -108), Color(0.62, 1.0, 0.38), 1.2, 22)
		game._play_sfx("boss_impact", 0.018, 0.36, 1.28)
	elif stage == "failure":
		game._add_text("RITUAL CONCLUIDO: FERVOR", game.player_pos + Vector2(0, -108), Color(0.92, 0.34, 0.62), 1.35, 22)
		game._play_sfx("boss_impact", 0.024, 0.48, 0.82)
