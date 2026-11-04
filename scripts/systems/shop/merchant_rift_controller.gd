class_name RTMerchantRiftController
extends RefCounted

## Fenda do Mercador: substitui a contagem automatica da loja em partidas solo.
## A fenda surge no mundo por marcos de combate (abates) ou, como rede de
## seguranca, pelo intervalo configurado da loja automatica. O jogador entra
## nela andando; ignorar a fenda deixa um fragmento que melhora a proxima.

const STATE_OPENING := "opening"
const STATE_OPEN := "open"
const STATE_COLLAPSING := "collapsing"
const STATE_ENTERED := "entered"

const LIFETIME := 24.0
const OPEN_TIME := 1.15
const ENTER_ARM_TIME := 0.55
const UNSTABLE_TIME := 6.0
const COLLAPSE_TIME := 0.9
const ENTER_RADIUS := 76.0
const NEAR_RADIUS := 230.0

const KILL_MILESTONE_BASE := 36
const KILL_MILESTONE_PER_PHASE := 6
const KILL_MILESTONE_CAP := 80
const UNCOMMON_KILL_WEIGHT := 3
const MIN_GAP_AFTER_SHOP := 50.0
const RETRY_AFTER_COLLAPSE := 22.0
const FRAGMENT_RETRY_ELAPSED := 70.0

const EDGE_BONUS_DISCOUNT := 0.10
const FRAGMENT_DISCOUNT := 0.05
const FRAGMENT_REROLLS := 1
const FRAGMENT_MAX := 2
const DISCOUNT_CAP := 0.55

const SPAWN_DISTANCE_WORLD := Vector2(640.0, 920.0)
const SPAWN_DISTANCE_CLASSIC := Vector2(380.0, 600.0)
const SPAWN_MARGIN_WORLD := Vector2(180.0, 170.0)
const SPAWN_MARGIN_CLASSIC := Vector2(110.0, 110.0)
const ALTAR_CLEARANCE := 280.0

var core: Node = null
## Desligue em testes que cobrem a contagem automatica legada.
var allow_rift: bool = true
var sequence: int = 0
var entry_bonus: Dictionary = {}


func configure(root: Node) -> void:
	core = root


func reset_run() -> void:
	if core == null:
		return
	core.shop_rift = {}
	core.shop_rift_kills = 0
	core.shop_rift_fragments = 0
	sequence = 0
	core.shop_rift_next_allowed_time = 0.0
	entry_bonus = {}


func clear_active() -> void:
	if core == null:
		return
	core.shop_rift = {}


func enabled() -> bool:
	if core == null:
		return false
	if not allow_rift or not bool(core.shop_auto_enabled):
		return false
	if bool(core.is_multiplayer) or bool(core.dedicated_server_mode):
		return false
	return not core._is_drop_game_mode()


## Quando a fenda esta ativa, a contagem automatica antiga nao dispara.
func replaces_forced_countdown() -> bool:
	return enabled()


func active() -> bool:
	return core != null and not Dictionary(core.shop_rift).is_empty()


func rift() -> Dictionary:
	return core.shop_rift if active() else {}


func state() -> String:
	return String(rift().get("state", ""))


func remaining() -> float:
	var current: Dictionary = rift()
	if current.is_empty():
		return 0.0
	return maxf(0.0, float(current.get("life", LIFETIME)) - float(current.get("age", 0.0)))


func life_ratio() -> float:
	var current: Dictionary = rift()
	if current.is_empty():
		return 0.0
	return clampf(remaining() / maxf(0.01, float(current.get("life", LIFETIME))), 0.0, 1.0)


func unstable() -> bool:
	return active() and state() == STATE_OPEN and remaining() <= UNSTABLE_TIME


func guide_visible() -> bool:
	return active() and state() in [STATE_OPENING, STATE_OPEN]


func kill_milestone() -> int:
	var phase: int = maxi(1, int(core.current_phase))
	return mini(KILL_MILESTONE_CAP, KILL_MILESTONE_BASE + (phase - 1) * KILL_MILESTONE_PER_PHASE)


func kill_progress() -> float:
	return clampf(float(core.shop_rift_kills) / float(maxi(1, kill_milestone())), 0.0, 1.0)


func on_enemy_killed(enemy: Dictionary) -> void:
	if not enabled() or active():
		return
	var weight: int = UNCOMMON_KILL_WEIGHT if core._is_uncommon_enemy(enemy) else 1
	core.shop_rift_kills = mini(KILL_MILESTONE_CAP * 2, int(core.shop_rift_kills) + weight)


## Retorna true quando o jogador entrou na fenda e o jogo saiu do modo "game".
func update(delta: float) -> bool:
	if core == null:
		return false
	if not enabled():
		if active() and state() != STATE_ENTERED:
			clear_active()
		return false
	if active():
		_update_active(delta)
		return core.mode != "game"
	if _should_spawn():
		spawn("kills" if int(core.shop_rift_kills) >= kill_milestone() else "interval")
	return false


func _boss_blocks_rift() -> bool:
	return bool(core.boss_active) or float(core.boss_call_timer) >= 0.0 or core._arauto_active()


func _should_spawn() -> bool:
	if core.mode != "game" or _boss_blocks_rift():
		return false
	if core._tutorial_blocks_normal_spawn() or core._local_player_controls_locked():
		return false
	var now: float = float(core.time_alive)
	if now < float(core.shop_rift_next_allowed_time):
		return false
	if now - float(core.shop_last_exit_time) < MIN_GAP_AFTER_SHOP:
		return false
	var elapsed: float = float(core.shop_auto_elapsed)
	if elapsed >= float(core.shop_auto_interval):
		return true
	var affordable: bool = core._affordable_card_count() > 0
	if not affordable:
		return false
	if int(core.shop_rift_kills) >= kill_milestone():
		return true
	return int(core.shop_rift_fragments) > 0 and elapsed >= FRAGMENT_RETRY_ELAPSED


func spawn(reason: String, forced_pos: Variant = null) -> Dictionary:
	sequence += 1
	var pos: Vector2 = Vector2(forced_pos) if forced_pos is Vector2 else _roll_spawn_position()
	core.shop_rift = {
		"id": sequence,
		"pos": pos,
		"age": 0.0,
		"life": LIFETIME,
		"state": STATE_OPENING,
		"state_age": 0.0,
		"reason": reason,
		"seed": core.rng.randf_range(0.0, TAU),
		"near": false,
		"warned_unstable": false,
		"entered_msec": 0,
	}
	core._add_text("FENDA DO MERCADOR ABERTA", core.player_pos + Vector2(0.0, -118.0), Color(0.86, 0.6, 1.0), 1.7, 22)
	core._play_sfx("shop_countdown_tick", 0.0, 0.62, 0.58)
	core._vibrate(120, 0.42)
	return core.shop_rift


func _roll_spawn_position() -> Vector2:
	var definitive: bool = core.experimental_phase_controller.uses_definitive_world()
	var distance_range: Vector2 = SPAWN_DISTANCE_WORLD if definitive else SPAWN_DISTANCE_CLASSIC
	var margin: Vector2 = SPAWN_MARGIN_WORLD if definitive else SPAWN_MARGIN_CLASSIC
	var world_size: Vector2 = Vector2(core.WORLD_SIZE)
	var origin: Vector2 = Vector2(core.player_pos)
	var best: Vector2 = (world_size * 0.5).clamp(margin, world_size - margin)
	var best_score: float = -INF
	for _attempt in range(14):
		var angle: float = core.rng.randf_range(0.0, TAU)
		var distance: float = core.rng.randf_range(distance_range.x, distance_range.y)
		var candidate: Vector2 = (origin + Vector2.from_angle(angle) * distance).clamp(margin, world_size - margin)
		var actual: float = candidate.distance_to(origin)
		var score: float = -absf(actual - distance_range.x)
		if definitive and not bool(core.experimental_boss_altar_used):
			if candidate.distance_to(Vector2(core.experimental_boss_altar_pos)) < ALTAR_CLEARANCE:
				score -= 2000.0
		if score > best_score:
			best = candidate
			best_score = score
		if actual >= distance_range.x * 0.9 and score > -1000.0:
			return candidate
	return best


func _update_active(delta: float) -> void:
	var current: Dictionary = core.shop_rift
	var current_state: String = String(current.get("state", STATE_OPENING))
	if current_state == STATE_ENTERED:
		# Restauracao de partida interrompida ou loja fechada fora do fluxo normal.
		if core.mode == "game":
			clear_active()
		return
	current["state_age"] = float(current.get("state_age", 0.0)) + delta
	if current_state == STATE_COLLAPSING:
		if float(current["state_age"]) >= COLLAPSE_TIME:
			_finish_collapse(current)
		return
	if _boss_blocks_rift():
		collapse(true, "A FENDA RECUOU")
		return
	current["age"] = float(current.get("age", 0.0)) + delta
	if current_state == STATE_OPENING and float(current["state_age"]) >= OPEN_TIME:
		current["state"] = STATE_OPEN
		current["state_age"] = 0.0
	var distance: float = Vector2(core.player_pos).distance_to(Vector2(current.get("pos", Vector2.ZERO)))
	current["near"] = distance <= NEAR_RADIUS
	if remaining() <= UNSTABLE_TIME and not bool(current.get("warned_unstable", false)):
		current["warned_unstable"] = true
		core._add_text("FENDA INSTAVEL: -%d%% NO LIMITE" % int(round(EDGE_BONUS_DISCOUNT * 100.0)), core.player_pos + Vector2(0.0, -112.0), Color(1.0, 0.56, 0.34), 1.3, 18)
		core._vibrate(60, 0.3)
	var armed: bool = String(current.get("state", "")) == STATE_OPEN or float(current.get("state_age", 0.0)) >= ENTER_ARM_TIME
	if armed and distance <= ENTER_RADIUS and core.mode == "game" and not core._local_player_controls_locked():
		enter()
		return
	if remaining() <= 0.0:
		collapse(true, "A FENDA SE FECHOU")


func enter() -> bool:
	if not active() or state() in [STATE_COLLAPSING, STATE_ENTERED]:
		return false
	var current: Dictionary = core.shop_rift
	var edge: bool = remaining() <= UNSTABLE_TIME
	var fragments: int = int(core.shop_rift_fragments)
	entry_bonus = {"edge": edge, "fragments": fragments, "rift_id": int(current.get("id", 0))}
	core.shop_rift_fragments = 0
	core.shop_rift_kills = 0
	current["state"] = STATE_ENTERED
	current["state_age"] = 0.0
	current["entered_msec"] = Time.get_ticks_msec()
	core.screen_shake_timer = maxf(float(core.screen_shake_timer), 0.32)
	core.screen_shake_strength = maxf(float(core.screen_shake_strength), 12.0)
	core._play_sfx("shop_countdown_tick", 0.0, 0.8, 1.22)
	core._vibrate(260, 0.7)
	core.shop_controller.start_opening_animation(true)
	if core.mode != "shop_opening":
		# A abertura foi bloqueada (ex.: rewind do boss 1); a fenda volta a ficar aberta.
		current["state"] = STATE_OPEN
		entry_bonus = {}
		core.shop_rift_fragments = fragments
		return false
	return true


func collapse(grant_fragment: bool, message: String = "") -> void:
	if not active():
		return
	var current: Dictionary = core.shop_rift
	if String(current.get("state", "")) in [STATE_COLLAPSING, STATE_ENTERED]:
		return
	current["state"] = STATE_COLLAPSING
	current["state_age"] = 0.0
	current["grant_fragment"] = grant_fragment
	if message != "":
		current["collapse_message"] = message
	core._play_sfx("Retrocede.mp3", 0.04, 0.42, 1.18)


func _finish_collapse(current: Dictionary) -> void:
	var pos: Vector2 = Vector2(current.get("pos", core.player_pos))
	if bool(current.get("grant_fragment", false)):
		core.shop_rift_fragments = mini(FRAGMENT_MAX, int(core.shop_rift_fragments) + 1)
		var message: String = String(current.get("collapse_message", "A FENDA SE FECHOU"))
		core._add_text(message, pos + Vector2(0.0, -96.0), Color(0.84, 0.66, 1.0), 1.2, 18)
		core._add_text("FRAGMENTO GUARDADO (%d/%d)" % [int(core.shop_rift_fragments), FRAGMENT_MAX], core.player_pos + Vector2(0.0, -104.0), Color(1.0, 0.82, 0.36), 1.5, 18)
	core.shop_rift_next_allowed_time = float(core.time_alive) + RETRY_AFTER_COLLAPSE
	clear_active()


## Chamado por open_shop depois do desconto de resistencia ser calculado.
func apply_entry_bonus() -> bool:
	var bonus: Dictionary = entry_bonus
	if bonus.is_empty():
		return false
	entry_bonus = {}
	var extra_discount: float = 0.0
	if bool(bonus.get("edge", false)):
		extra_discount += EDGE_BONUS_DISCOUNT
	var fragments: int = int(bonus.get("fragments", 0))
	extra_discount += float(fragments) * FRAGMENT_DISCOUNT
	if extra_discount > 0.0:
		core.shop_endurance_discount = minf(DISCOUNT_CAP, float(core.shop_endurance_discount) + extra_discount)
	if fragments > 0:
		core.shop_rerolls = int(core.shop_rerolls) + fragments * FRAGMENT_REROLLS
	var label: String = "FENDA DO MERCADOR"
	if bool(bonus.get("edge", false)):
		label = "ENTRADA NO LIMITE"
	core._add_text(label, core.player_pos + Vector2(0.0, -92.0), Color(0.86, 0.6, 1.0), 1.4, 24)
	if fragments > 0:
		core._add_text("FRAGMENTOS: +%d REROLL" % (fragments * FRAGMENT_REROLLS), core.player_pos + Vector2(0.0, -186.0), Color(1.0, 0.82, 0.36), 1.6, 20)
	return true


func on_shop_closed() -> void:
	if core == null:
		return
	if active() and state() == STATE_ENTERED:
		clear_active()
	core.shop_rift_next_allowed_time = maxf(float(core.shop_rift_next_allowed_time), float(core.time_alive) + MIN_GAP_AFTER_SHOP)


func on_phase_changed() -> void:
	if active() and state() != STATE_ENTERED:
		clear_active()
	entry_bonus = {}


## Alvo atual para a nevoa-guia e o marcador de borda.
func guide_target() -> Dictionary:
	if not guide_visible():
		return {}
	var current: Dictionary = rift()
	return {
		"pos": Vector2(current.get("pos", Vector2.ZERO)),
		"kind": "rift",
		"life_ratio": life_ratio(),
		"unstable": unstable(),
		"seed": float(current.get("seed", 0.0)),
	}
