class_name RTDimensionRuptureController
extends RefCounted
## Fragmento Instável, Impulso de Ruptura e Colapso Dimensional.
##
## Owner único dos tempos, faixas de recompensa, token de qualidade, Impulso,
## colapso, emergência, ejeção e Desorientação Temporal. O runtime só chama os
## ganchos (`update`, `activate`, `on_transition_started`,
## `on_group_transfer_committed`, `on_phase_entered`, `apply_quality_token`,
## `move_speed_multiplier`) e a apresentação deriva tudo de `public_snapshot()`.
##
## Autoridade: só o mundo autoritativo (solo ou host) muda estado econômico.
## Réplicas aplicam o snapshot compacto e apenas interpolam a barra. Todo efeito
## econômico é registrado por `event_id` em ledgers: pacotes repetidos,
## reconnect e save/retomada não reaplicam nada.

const FAST_WINDOW_SECONDS := 60.0
const STANDARD_WINDOW_SECONDS := 120.0
const COLLAPSE_START_SECONDS := 120.0
const COLLAPSE_TOTAL_SECONDS := 180.0
const EMERGENCY_ESCAPE_SECONDS := 18.0
const MAX_MOMENTUM_STACKS := 4

const DISORIENTATION_SECONDS := 20.0
## Penalidade leve e legível: -15% de velocidade de movimento.
const DISORIENTATION_MOVE_MULT := 0.85
const EJECTION_MIN_HP_RATIO := 0.5
## Token perfeito: 1 tentativa base + 1 por nível de Impulso (2..5).
const PERFECT_TOKEN_BASE_ATTEMPTS := 1
const STABLE_TOKEN_ATTEMPTS := 1
## Retomar uma run em emergência nunca deixa menos que isso para reagir.
const RESUME_EMERGENCY_MIN_SECONDS := 6.0
const LEDGER_LIMIT := 24
const STATE_VERSION := 1

const STATE_INACTIVE := "inactive"
const STATE_UNSTABLE := "unstable"
const STATE_COLLAPSE := "collapse"
const STATE_EMERGENCY := "emergency"
const STATE_TRANSITIONING := "transitioning"
const ACTIVE_STATES: Array[String] = [STATE_UNSTABLE, STATE_COLLAPSE, STATE_EMERGENCY]

const BAND_NONE := ""
const BAND_PERFECT := "perfect"
const BAND_STABLE := "stable"
const BAND_WEAKENED := "weakened"
const BAND_EJECTED := "ejected"

const SOURCE_OBJECTIVE := "objective"
const SOURCE_MINIBOSS := "miniboss"
const SOURCE_PHASE_EVENT := "phase_event"
const ALLOWED_SOURCES: Array[String] = [SOURCE_OBJECTIVE, SOURCE_MINIBOSS, SOURCE_PHASE_EVENT]

const SUSPEND_NONE := ""
const SUSPEND_PORTAL_LOCKED := "portal_locked"
const SUSPEND_TRANSITION := "transition"
const SUSPEND_MENU := "menu"
const SUSPEND_MERCHANT := "merchant"
const SUSPEND_BOSS_INTRO := "boss_intro"

## Ação de transferência de grupo usada pela ejeção. Clientes antigos tratam
## qualquer ação desconhecida como travessia normal para `target_phase`.
const EJECT_ACTION := "rupture_eject"

const MSG_ACTIVATED := "FRAGMENTO INSTÁVEL — ATRAVESSE PARA ESTABILIZAR"
const MSG_CONTAINED := "FRAGMENTO INSTÁVEL — A RUPTURA AINDA ESTÁ FECHADA"
const MSG_COLLAPSE := "COLAPSO DIMENSIONAL — O FRAGMENTO ENFRAQUECE"
const MSG_EMERGENCY := "COLAPSO IMINENTE — ENCONTRE UMA RUPTURA"
const MSG_EJECTED := "EJETADO PELO COLAPSO — DESORIENTAÇÃO TEMPORAL"

## Modos em que nenhum relógio avança, nem em multiplayer.
const GLOBAL_SUSPEND_MODES: Array[String] = [
	"phase_transition", "loading", "boss_call", "shop_countdown", "shop_opening", "shop",
	"shop_return", "shop_mp_waiting", "multiplayer_syncing", "multiplayer_preload",
	"game_over", "victory", "story_comic", "retry_return",
]

var core: Node = null
var state: Dictionary = {}
## Ledger local de correção de vida por evento de ejeção (por peer).
var _arrival_applied: Dictionary = {}
## Ledger local de banners já apresentados (não vai para a rede).
var _presented: Dictionary = {}
var _cue_key: String = ""
## Banner de chegada adiado até o fim da transição (o setup da fase nova
## sobrescreveria o alerta).
var _pending_arrival: Dictionary = {}
## Banner local (texto da mensagem). Nunca vai para a rede.
var banner_text: String = ""
var banner_timer: float = 0.0
var banner_duration: float = 1.0
var _emergency_pulse_timer: float = 0.0
## Réplica: relógio exibido, reancorado a cada snapshot.
var _display_elapsed: float = 0.0
var _display_emergency: float = 0.0
var _replica_pending_eject_event: String = ""
## Réplica: ejeções já comitadas localmente (RPC e snapshot não duplicam).
var _replica_committed_ejects: Dictionary = {}
## Miniboss só ativa o fragmento se foi visto vivo neste epoch (estado de
## miniboss que persiste entre visitas não reativa ao entrar na fase).
var _miniboss_armed_epoch: int = -1


func _init() -> void:
	state = default_state("")


func configure(p_core: Node) -> void:
	core = p_core


# ---------------------------------------------------------------- estado puro

static func default_state(run_id: String) -> Dictionary:
	return {
		"v": STATE_VERSION,
		"run_id": run_id,
		"epoch": 1,
		"event_id": "",
		"origin_phase": 0,
		"state": STATE_INACTIVE,
		"source": "",
		"started_at": 0.0,
		"elapsed": 0.0,
		"emergency_elapsed": 0.0,
		"suspend_reason": SUSPEND_NONE,
		"momentum": 0,
		"token": {},
		"eject_target": 0,
		"eject_action": "",
		"granted": {},
		"consumed_tokens": {},
		"activated_epochs": {},
		"disorientation": 0.0,
		"disorientation_event": "",
		"last_resolution": {},
		"last_token_result": {},
		"rev": 0,
	}


static func band_for_elapsed(elapsed: float) -> String:
	if elapsed <= FAST_WINDOW_SECONDS:
		return BAND_PERFECT
	if elapsed <= STANDARD_WINDOW_SECONDS:
		return BAND_STABLE
	return BAND_WEAKENED


static func state_for_elapsed(elapsed: float) -> String:
	if elapsed >= COLLAPSE_TOTAL_SECONDS:
		return STATE_EMERGENCY
	if elapsed >= COLLAPSE_START_SECONDS:
		return STATE_COLLAPSE
	return STATE_UNSTABLE


static func make_event_id(run_id: String, epoch: int, origin_phase: int) -> String:
	return "rupt:%s:%d:%d" % [run_id, epoch, origin_phase]


## Destinos válidos para a ejeção: o próximo do fluxo normal e a fila da rota,
## sem a dimensão atual, a final (UMBRA), fases bloqueadas ou repetidas.
static func eligible_ejection_targets(current_phase: int, normal_next: int, queue: Array, final_phase: int, blocked: Array = []) -> Array[int]:
	var out: Array[int] = []
	var raw: Array = [normal_next]
	raw.append_array(queue)
	for value in raw:
		var phase := int(value)
		if phase < 1 or phase > 10:
			continue
		if phase == current_phase or phase == final_phase or phase in blocked or out.has(phase):
			continue
		out.append(phase)
	return out


## Candidatos da ejeção: prefere destinos alternativos ao próximo do fluxo
## normal; só sem alternativa válida cai no próximo normal.
static func ejection_candidates(current_phase: int, normal_next: int, queue: Array, final_phase: int) -> Array[int]:
	var all := eligible_ejection_targets(current_phase, normal_next, queue, final_phase)
	var alternatives: Array[int] = []
	for phase in all:
		if phase != normal_next:
			alternatives.append(phase)
	return alternatives if not alternatives.is_empty() else all


static func pick_deterministic(candidates: Array[int], event_id: String, run_id: String) -> int:
	if candidates.is_empty():
		return 0
	var digest := absi(hash("%s|%s" % [event_id, run_id]))
	return candidates[digest % candidates.size()]


## Fila da rota depois da ejeção: o destino escolhido sai da fila e o próximo
## do fluxo normal (já retirado quando o portal nasceu) volta para a frente.
static func route_after_ejection(queue: Array, target: int, normal_next: int) -> Array[int]:
	var out: Array[int] = []
	for value in queue:
		var phase := int(value)
		if phase != target and not out.has(phase):
			out.append(phase)
	if normal_next > 0 and normal_next != target and not out.has(normal_next):
		out.push_front(normal_next)
	return out


## Grupo na travessia: vivos se movem, derrubados são carregados pelo contrato
## de revive, espectadores continuam espectadores, desconectados saem do
## conjunto esperado. Só vivos conectados precisam confirmar.
static func group_transfer_roster(peers: Array) -> Dictionary:
	var moving: Array[int] = []
	var carried: Array[int] = []
	var spectators: Array[int] = []
	var expected: Array[int] = []
	for value in peers:
		if not value is Dictionary:
			continue
		var peer: Dictionary = value
		var peer_id := int(peer.get("peer_id", 0))
		if peer_id <= 0 or not bool(peer.get("connected", true)):
			continue
		if bool(peer.get("spectator", false)):
			spectators.append(peer_id)
		elif bool(peer.get("downed", false)) or not bool(peer.get("alive", true)):
			carried.append(peer_id)
		else:
			moving.append(peer_id)
			expected.append(peer_id)
	return {"moving": moving, "carried": carried, "spectators": spectators, "expected": expected}


## Melhora a qualidade de uma carta sem criar cartas novas: cada tentativa
## sorteia uma raridade com os pesos atuais (que já embutem as travas de
## tempo/sorte) e só aceita cartas do pool permitido. A melhor raridade vence;
## empate mantém a carta original.
static func pick_upgraded_card(card: Dictionary, pool_by_rarity: Dictionary, weights: Array, attempts: int, seed_value: int, rarity_order: Array, rarity_of: Callable) -> Dictionary:
	var best: Dictionary = card
	var best_rank: int = rarity_order.find(String(rarity_of.call(card)))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for _attempt in range(maxi(0, attempts)):
		var available_weight := 0.0
		for entry in weights:
			if not Array(pool_by_rarity.get(String(entry[0]), [])).is_empty():
				available_weight += maxf(0.0, float(entry[1]))
		if available_weight <= 0.0:
			break
		var roll := rng.randf_range(0.0, available_weight)
		var chosen := ""
		for entry in weights:
			var rarity_pool: Array = pool_by_rarity.get(String(entry[0]), [])
			if rarity_pool.is_empty() or float(entry[1]) <= 0.0:
				continue
			roll -= float(entry[1])
			chosen = String(entry[0])
			if roll <= 0.0:
				break
		if chosen == "":
			continue
		var rank := rarity_order.find(chosen)
		if rank <= best_rank:
			continue
		var candidates: Array = pool_by_rarity[chosen]
		best = Dictionary(candidates[rng.randi_range(0, candidates.size() - 1)])
		best_rank = rank
	return best


# ---------------------------------------------------------------- consultas

func is_active() -> bool:
	return String(state.get("state", STATE_INACTIVE)) in ACTIVE_STATES


func current_state() -> String:
	return String(state.get("state", STATE_INACTIVE))


func momentum() -> int:
	return int(state.get("momentum", 0))


func pending_token() -> Dictionary:
	return Dictionary(state.get("token", {}))


func current_band() -> String:
	var s := current_state()
	if s == STATE_EMERGENCY:
		return BAND_WEAKENED
	if s in ACTIVE_STATES:
		return band_for_elapsed(_effective_elapsed())
	return BAND_NONE


func remaining_seconds() -> float:
	var s := current_state()
	if s == STATE_EMERGENCY:
		return maxf(0.0, EMERGENCY_ESCAPE_SECONDS - _effective_emergency())
	if s in ACTIVE_STATES:
		return maxf(0.0, COLLAPSE_TOTAL_SECONDS - _effective_elapsed())
	return 0.0


## Segundos até a faixa atual acabar (perfeita -> estável -> enfraquecida).
func band_remaining_seconds() -> float:
	var s := current_state()
	if s == STATE_EMERGENCY:
		return remaining_seconds()
	if not s in ACTIVE_STATES:
		return 0.0
	var elapsed := _effective_elapsed()
	if elapsed < FAST_WINDOW_SECONDS:
		return FAST_WINDOW_SECONDS - elapsed
	if elapsed < STANDARD_WINDOW_SECONDS:
		return STANDARD_WINDOW_SECONDS - elapsed
	return maxf(0.0, COLLAPSE_TOTAL_SECONDS - elapsed)


## 0 = estável, 1 = fim do colapso. Base de toda a pressão visual.
func collapse_intensity() -> float:
	var s := current_state()
	if s == STATE_EMERGENCY:
		return 1.0
	if s != STATE_COLLAPSE:
		return 0.0
	return clampf((_effective_elapsed() - COLLAPSE_START_SECONDS) / (COLLAPSE_TOTAL_SECONDS - COLLAPSE_START_SECONDS), 0.0, 1.0)


func disorientation_remaining() -> float:
	return maxf(0.0, float(state.get("disorientation", 0.0)))


func move_speed_multiplier() -> float:
	return DISORIENTATION_MOVE_MULT if disorientation_remaining() > 0.0 else 1.0


func _effective_elapsed() -> float:
	return _display_elapsed if _is_replica() else float(state.get("elapsed", 0.0))


func _effective_emergency() -> float:
	return _display_emergency if _is_replica() else float(state.get("emergency_elapsed", 0.0))


func _is_authority() -> bool:
	return core == null or bool(core._is_world_authority())


func _is_replica() -> bool:
	return core != null and bool(core._is_world_replica())


func is_enabled() -> bool:
	if core == null:
		return true
	if bool(core.experimental_phase_active):
		return false
	if core._tutorial_active():
		return false
	return int(core.current_phase) != int(core.DIMENSION_FINAL_PHASE)


# ---------------------------------------------------------------- ciclo de run

func reset_for_new_run() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	state = default_state("%08x" % (rng.randi() & 0x7fffffff))
	_arrival_applied.clear()
	_presented.clear()
	_cue_key = ""
	_display_elapsed = 0.0
	_display_emergency = 0.0
	_replica_pending_eject_event = ""
	_replica_committed_ejects.clear()
	_miniboss_armed_epoch = -1
	_pending_arrival = {}
	banner_text = ""
	banner_timer = 0.0


func save_state() -> Dictionary:
	var out := state.duplicate(true)
	out["arrival_applied"] = _arrival_applied.duplicate()
	return out


## Saves antigos chegam sem o campo e nunca passam por aqui. Saves de outra
## dimensão (fragmento cuja origem não é a fase atual) descartam o fragmento,
## mas preservam Impulso e token. O tempo salvo é o relógio ativo, então o
## tempo com o jogo fechado nunca conta.
func load_state(value) -> void:
	if not value is Dictionary or Dictionary(value).is_empty():
		return
	var incoming: Dictionary = value
	var clean := default_state(String(incoming.get("run_id", state.get("run_id", ""))))
	for key in clean.keys():
		if incoming.has(key):
			clean[key] = incoming[key]
	clean["v"] = STATE_VERSION
	clean["momentum"] = clampi(int(clean["momentum"]), 0, MAX_MOMENTUM_STACKS)
	clean["elapsed"] = clampf(float(clean["elapsed"]), 0.0, COLLAPSE_TOTAL_SECONDS)
	clean["emergency_elapsed"] = clampf(float(clean["emergency_elapsed"]), 0.0, EMERGENCY_ESCAPE_SECONDS - RESUME_EMERGENCY_MIN_SECONDS)
	clean["disorientation"] = clampf(float(clean["disorientation"]), 0.0, DISORIENTATION_SECONDS)
	for dict_key in ["token", "granted", "consumed_tokens", "activated_epochs", "last_resolution", "last_token_result"]:
		if not clean[dict_key] is Dictionary:
			clean[dict_key] = {}
	var s := String(clean["state"])
	if not s in ACTIVE_STATES and s != STATE_TRANSITIONING:
		clean["state"] = STATE_INACTIVE
	if String(clean["state"]) == STATE_TRANSITIONING:
		_clear_fragment_fields(clean)
	elif core != null and String(clean["state"]) != STATE_INACTIVE and int(clean["origin_phase"]) != int(core.current_phase):
		_clear_fragment_fields(clean)
	clean["suspend_reason"] = SUSPEND_NONE
	state = clean
	_arrival_applied = Dictionary(incoming.get("arrival_applied", {})).duplicate()
	_cue_key = _cue_key_for_state()
	_display_elapsed = float(state["elapsed"])
	_display_emergency = float(state["emergency_elapsed"])


static func _clear_fragment_fields(target: Dictionary) -> void:
	target["state"] = STATE_INACTIVE
	target["event_id"] = ""
	target["origin_phase"] = 0
	target["source"] = ""
	target["elapsed"] = 0.0
	target["emergency_elapsed"] = 0.0
	target["eject_target"] = 0
	target["eject_action"] = ""
	target["suspend_reason"] = SUSPEND_NONE


# ---------------------------------------------------------------- ativação

## Só o mundo autoritativo cria o evento. Um mesmo ciclo (epoch) de uma
## dimensão nunca cria dois Fragmentos Instáveis.
func activate(source: String, origin_phase: int) -> bool:
	if not _is_authority() or not is_enabled():
		return false
	if not source in ALLOWED_SOURCES:
		return false
	if core != null and origin_phase != int(core.current_phase):
		return false
	if current_state() != STATE_INACTIVE:
		return false
	var epoch_key := str(int(state.get("epoch", 1)))
	var activated: Dictionary = state["activated_epochs"]
	if activated.has(epoch_key):
		return false
	var event_id := make_event_id(String(state.get("run_id", "")), int(state.get("epoch", 1)), origin_phase)
	activated[epoch_key] = event_id
	_trim(activated)
	state["event_id"] = event_id
	state["origin_phase"] = origin_phase
	state["source"] = source
	state["state"] = STATE_UNSTABLE
	state["started_at"] = float(core.time_alive) if core != null else 0.0
	state["elapsed"] = 0.0
	state["emergency_elapsed"] = 0.0
	state["eject_target"] = 0
	state["eject_action"] = ""
	state["suspend_reason"] = SUSPEND_NONE
	_bump()
	return true


func suspend_reason_now() -> String:
	if core == null:
		return SUSPEND_NONE
	var mode := String(core.mode)
	if mode == "phase_transition" or mode == "loading":
		return SUSPEND_TRANSITION
	if mode in GLOBAL_SUSPEND_MODES or mode == RTUmbraIntro.MODE:
		return SUSPEND_BOSS_INTRO
	if not bool(core.is_multiplayer) and mode != "game":
		return SUSPEND_MENU
	if core._merchant_dimension().active:
		return SUSPEND_MERCHANT
	if bool(core.boss_active) and float(core.boss_entry_timer) > 0.0:
		return SUSPEND_BOSS_INTRO
	if Dictionary(core.phase_fragment).is_empty():
		return SUSPEND_PORTAL_LOCKED
	return SUSPEND_NONE


# ---------------------------------------------------------------- tick

func update(delta: float) -> void:
	if core == null or delta <= 0.0:
		return
	if not _is_authority() and not _is_replica():
		return
	if _is_replica():
		_update_replica(delta)
		_update_cues(delta)
		return
	_tick_disorientation(delta)
	if current_state() == STATE_INACTIVE:
		_poll_miniboss_sources()
	if is_active():
		if not is_enabled():
			_clear_fragment_fields(state)
			_bump()
		else:
			var reason := suspend_reason_now()
			if reason != String(state.get("suspend_reason", "")):
				state["suspend_reason"] = reason
				_bump()
			if reason == SUSPEND_NONE:
				advance_clock(delta)
	_update_cues(delta)


## Avança o relógio autoritativo. Público para testes de faixa.
func advance_clock(delta: float) -> void:
	if not _is_authority() or not is_active():
		return
	if current_state() == STATE_EMERGENCY:
		state["emergency_elapsed"] = float(state["emergency_elapsed"]) + delta
		if float(state["emergency_elapsed"]) >= EMERGENCY_ESCAPE_SECONDS:
			eject()
		return
	state["elapsed"] = minf(COLLAPSE_TOTAL_SECONDS, float(state["elapsed"]) + delta)
	var next_state := state_for_elapsed(float(state["elapsed"]))
	if next_state != current_state():
		state["state"] = next_state
		if next_state == STATE_EMERGENCY:
			state["emergency_elapsed"] = 0.0
			_prepare_ejection_plan()
		_bump()


func _tick_disorientation(delta: float) -> void:
	var remaining := disorientation_remaining()
	if remaining <= 0.0:
		return
	var mode := String(core.mode) if core != null else "game"
	if core != null and not bool(core.is_multiplayer) and mode != "game":
		return
	if mode in GLOBAL_SUSPEND_MODES:
		return
	state["disorientation"] = maxf(0.0, remaining - delta)
	if float(state["disorientation"]) <= 0.0:
		state["disorientation_event"] = ""
		_bump()


func _poll_miniboss_sources() -> void:
	if core == null or not is_enabled():
		return
	var phase := int(core.current_phase)
	var defeated := false
	match phase:
		8:
			defeated = bool(core.sertao_controller.miniboss_defeated)
		9:
			defeated = bool(core.cripta_controller.miniboss_defeated)
		10:
			defeated = bool(core.baile_controller.miniboss_defeated)
		6:
			defeated = String(Dictionary(core.amber_suturer_state).get("cleanup_reason", "")) == "defeated"
		_:
			return
	var epoch := int(state.get("epoch", 1))
	if not defeated:
		_miniboss_armed_epoch = epoch
		return
	if _miniboss_armed_epoch == epoch:
		activate(SOURCE_MINIBOSS, phase)


# ---------------------------------------------------------------- travessia

## Chamado pelo owner de fase quando uma travessia começa (solo ou commit de
## grupo). Resolve a faixa uma única vez por `event_id`.
func on_transition_started(_next_phase: int) -> void:
	if not is_active():
		return
	if _is_replica():
		state["state"] = STATE_TRANSITIONING
		return
	resolve_crossing()


func resolve_crossing() -> String:
	if not _is_authority() or not is_active():
		return BAND_NONE
	var event_id := String(state.get("event_id", ""))
	var granted: Dictionary = state["granted"]
	if granted.has(event_id):
		return String(granted[event_id])
	var band := BAND_WEAKENED if current_state() == STATE_EMERGENCY else band_for_elapsed(float(state["elapsed"]))
	var token := {}
	match band:
		BAND_PERFECT:
			state["momentum"] = mini(MAX_MOMENTUM_STACKS, momentum() + 1)
			token = {"event_id": event_id, "tier": BAND_PERFECT, "attempts": PERFECT_TOKEN_BASE_ATTEMPTS + momentum()}
		BAND_STABLE:
			token = {"event_id": event_id, "tier": BAND_STABLE, "attempts": STABLE_TOKEN_ATTEMPTS}
		_:
			state["momentum"] = 0
	# Um token não consumido expira na travessia seguinte.
	state["token"] = token
	granted[event_id] = band
	_trim(granted)
	state["last_resolution"] = {"event_id": event_id, "band": band, "momentum": momentum(), "attempts": int(token.get("attempts", 0)), "origin": int(state.get("origin_phase", 0))}
	state["state"] = STATE_TRANSITIONING
	_bump()
	return band


func _prepare_ejection_plan() -> void:
	if String(state.get("eject_action", "")) != "":
		return
	var plan := ejection_plan()
	state["eject_target"] = int(plan.get("target", 0))
	state["eject_action"] = String(plan.get("action", EJECT_ACTION))


## Destino determinístico a partir do `event_id` e da seed da run. Nunca a
## dimensão atual, nunca UMBRA, nunca fora da rota desbloqueada.
func ejection_plan() -> Dictionary:
	if core == null:
		return {"target": 0, "action": EJECT_ACTION}
	var fragment: Dictionary = core.phase_fragment
	var choices: Array = Array(fragment.get("choices", []))
	if not choices.is_empty():
		# Fim de ciclo: segue para o farm (Cinzas); nunca empurra para a UMBRA.
		return {"target": int(core.DIMENSION_FARM_ENTRY_PHASE), "action": String(core._phase_flow()._farm_action_with_route())}
	var normal_next := int(fragment.get("next_phase", 0))
	var candidates := ejection_candidates(int(core.current_phase), normal_next, Array(core.dimension_route_queue), int(core.DIMENSION_FINAL_PHASE))
	var target := pick_deterministic(candidates, String(state.get("event_id", "")), String(state.get("run_id", "")))
	if target <= 0:
		target = normal_next
	return {"target": target, "action": EJECT_ACTION}


## Fim da emergência: o host ejeta o grupo inteiro junto.
func eject() -> bool:
	if not _is_authority() or not is_active():
		return false
	var event_id := String(state.get("event_id", ""))
	var granted: Dictionary = state["granted"]
	if granted.has(event_id):
		return false
	_prepare_ejection_plan()
	var target := int(state.get("eject_target", 0))
	var action := String(state.get("eject_action", EJECT_ACTION))
	granted[event_id] = BAND_EJECTED
	_trim(granted)
	state["momentum"] = 0
	state["token"] = {}
	state["disorientation"] = DISORIENTATION_SECONDS
	state["disorientation_event"] = event_id
	state["last_resolution"] = {"event_id": event_id, "band": BAND_EJECTED, "momentum": 0, "attempts": 0, "origin": int(state.get("origin_phase", 0)), "target": target, "action": action}
	state["state"] = STATE_TRANSITIONING
	_bump()
	if core == null:
		return true
	if bool(core.is_multiplayer) and core._shop_rpc_available() and core.multiplayer.is_server():
		core.rpc("_rpc_commit_phase_transfer", target, action)
	core._commit_phase_mp_transfer(target, action)
	return true


## Gancho no commit de grupo (antes de o fragmento ser limpo). Retorna false
## quando a mesma ejeção já foi comitada (RPC repetido ou snapshot + RPC): o
## owner de fase então não inicia uma segunda transição. Na réplica, a ejeção
## ajusta a própria fila com a mesma regra e arma a correção de vida.
func on_group_transfer_committed(target: int, action: String) -> bool:
	if core == null or not _is_eject_action(action):
		return true
	if _is_replica():
		var event_id := String(state.get("event_id", ""))
		var key := event_id if event_id != "" else "eject:%d:%d" % [int(state.get("epoch", 0)), target]
		if _replica_committed_ejects.has(key) or String(core.mode) == "phase_transition":
			return false
		_replica_committed_ejects[key] = true
		_trim(_replica_committed_ejects)
		_replica_pending_eject_event = key
		state["state"] = STATE_TRANSITIONING
	if action == EJECT_ACTION:
		var normal_next := int(Dictionary(core.phase_fragment).get("next_phase", 0))
		core.dimension_route_queue = route_after_ejection(Array(core.dimension_route_queue), target, normal_next)
	return true


func _is_eject_action(action: String) -> bool:
	if action == EJECT_ACTION:
		return true
	var planned := String(state.get("eject_action", ""))
	return planned != "" and action == planned and current_state() in [STATE_EMERGENCY, STATE_TRANSITIONING]


## Chamado quando a nova dimensão foi montada. Abre um novo epoch e aplica a
## chegada (vida mínima após ejeção) uma única vez por evento e por peer.
func on_phase_entered(_phase: int) -> void:
	var resolution: Dictionary = state.get("last_resolution", {})
	if _is_authority():
		state["epoch"] = int(state.get("epoch", 1)) + 1
		_clear_fragment_fields(state)
		_bump()
		if String(resolution.get("band", "")) == BAND_EJECTED:
			apply_arrival_hp_floor(String(resolution.get("event_id", "")))
	else:
		state["state"] = STATE_INACTIVE
		_display_elapsed = 0.0
		_display_emergency = 0.0
		if _replica_pending_eject_event != "":
			apply_arrival_hp_floor(_replica_pending_eject_event)
			_replica_pending_eject_event = ""
	_pending_arrival = resolution.duplicate()


## Começa a dimensão de destino com pelo menos 50% da vida máxima, sem reviver
## nem matar ninguém e no máximo uma vez por evento.
func apply_arrival_hp_floor(event_id: String) -> bool:
	if core == null or event_id == "" or _arrival_applied.has(event_id):
		return false
	_arrival_applied[event_id] = true
	_trim(_arrival_applied)
	if bool(core.is_dead) or float(core.player_hp) <= 0.0:
		return false
	var floor_hp := ceilf(float(core.player_hp_max) * EJECTION_MIN_HP_RATIO)
	if float(core.player_hp) < floor_hp:
		core.player_hp = minf(float(core.player_hp_max), floor_hp)
		return true
	return false


# ---------------------------------------------------------------- token

## Melhora a primeira carta natural elegível da dimensão. Cartas devolvidas
## (Suturador), loja, tutorial, debug e save restaurado nunca chegam aqui ou
## são recusados pelo metadata.
func apply_quality_token(card: Dictionary, owner_peer: int, metadata: Dictionary = {}) -> Dictionary:
	if card.is_empty() or not _is_authority():
		return card
	if bool(metadata.get("suturer_returned", false)) or bool(metadata.get("no_rupture_token", false)):
		return card
	if core != null and (core._tutorial_active() or String(core.mode) == "phase_transition"):
		return card
	var token := pending_token()
	if token.is_empty():
		return card
	var token_id := String(token.get("event_id", ""))
	var consumed: Dictionary = state["consumed_tokens"]
	if token_id == "" or consumed.has(token_id):
		state["token"] = {}
		return card
	var upgraded := card
	if core != null:
		var pool_by_rarity := _quality_pool(owner_peer, bool(metadata.get("drop_mode", false)))
		var weights: Array = core._progression().temporal_luck_controller.drop_mode_rarity_weights()
		var order: Array = [core.CARD_RARITY_COMMON, core.CARD_RARITY_UNCOMMON, core.CARD_RARITY_RARE, core.CARD_RARITY_LEGENDARY]
		upgraded = pick_upgraded_card(card, pool_by_rarity, weights, int(token.get("attempts", 1)), hash("%s|%s" % [token_id, String(state.get("run_id", ""))]), order, Callable(core, "_card_rarity_key"))
	consumed[token_id] = true
	_trim(consumed)
	state["token"] = {}
	state["last_token_result"] = {
		"event_id": token_id,
		"tier": String(token.get("tier", "")),
		"from": String(card.get("id", card.get("name", ""))),
		"to": String(upgraded.get("id", upgraded.get("name", ""))),
		"improved": upgraded != card,
	}
	_bump()
	if core != null and upgraded != card:
		core._add_text("RUPTURA: QUALIDADE ELEVADA", core.player_pos + Vector2(-120, -122), Color(0.62, 0.95, 1.0), 1.6, 18)
	return upgraded


func _quality_pool(owner_peer: int, drop_mode: bool) -> Dictionary:
	var pools := {
		String(core.CARD_RARITY_COMMON): [],
		String(core.CARD_RARITY_UNCOMMON): [],
		String(core.CARD_RARITY_RARE): [],
		String(core.CARD_RARITY_LEGENDARY): [],
	}
	for value in core.CARDS:
		var candidate: Dictionary = value
		if not core._card_available_for_reward(candidate, true, true):
			continue
		if drop_mode and not core._drop_mode()._card_available_for_owner(candidate, owner_peer):
			continue
		var key := String(core._card_rarity_key(candidate))
		if pools.has(key):
			pools[key].append(candidate)
	return pools


# ---------------------------------------------------------------- rede

## Estado compacto. Nada de partículas, rachaduras ou pulsos: clientes derivam
## toda a apresentação destes escalares.
func public_snapshot() -> Dictionary:
	var token := pending_token()
	return {
		"v": STATE_VERSION,
		"run": String(state.get("run_id", "")),
		"ep": int(state.get("epoch", 1)),
		"rev": int(state.get("rev", 0)),
		"id": String(state.get("event_id", "")),
		"o": int(state.get("origin_phase", 0)),
		"s": current_state(),
		"t0": float(state.get("started_at", 0.0)),
		"el": float(state.get("elapsed", 0.0)),
		"em": float(state.get("emergency_elapsed", 0.0)),
		"rem": remaining_seconds(),
		"band": current_band(),
		"mo": momentum(),
		"tok": [String(token.get("tier", "")), int(token.get("attempts", 0)), String(token.get("event_id", ""))] if not token.is_empty() else [],
		"dst": int(state.get("eject_target", 0)),
		"dsa": String(state.get("eject_action", "")),
		"g": Dictionary(state.get("granted", {})).duplicate(),
		"sus": String(state.get("suspend_reason", "")),
		"dis": disorientation_remaining(),
		"dev": String(state.get("disorientation_event", "")),
		"lr": Dictionary(state.get("last_resolution", {})).duplicate(),
	}


## Réplica: aceita apenas snapshots novos. Mesma run com epoch ou revisão
## anterior é pacote atrasado e é ignorado; reconnect (run desconhecida) adota.
## Na mesma revisão só o relógio pode avançar (monotônico): repetido ou
## atrasado nunca volta o tempo.
func apply_remote_snapshot(snapshot: Dictionary) -> bool:
	if snapshot.is_empty() or _is_authority():
		return false
	var run_id := String(snapshot.get("run", ""))
	var epoch := int(snapshot.get("ep", 0))
	var rev := int(snapshot.get("rev", 0))
	if run_id == String(state.get("run_id", "")):
		var local_epoch := int(state.get("epoch", 0))
		if epoch < local_epoch:
			return false
		if epoch == local_epoch and rev < int(state.get("rev", -1)):
			return false
		if epoch == local_epoch and rev == int(state.get("rev", -1)):
			return _advance_remote_clock(snapshot)
	state["run_id"] = run_id
	state["epoch"] = epoch
	state["rev"] = rev
	state["event_id"] = String(snapshot.get("id", ""))
	state["origin_phase"] = int(snapshot.get("o", 0))
	state["state"] = String(snapshot.get("s", STATE_INACTIVE))
	state["started_at"] = float(snapshot.get("t0", 0.0))
	state["elapsed"] = float(snapshot.get("el", 0.0))
	state["emergency_elapsed"] = float(snapshot.get("em", 0.0))
	state["momentum"] = clampi(int(snapshot.get("mo", 0)), 0, MAX_MOMENTUM_STACKS)
	var tok: Array = Array(snapshot.get("tok", []))
	state["token"] = {"tier": String(tok[0]), "attempts": int(tok[1]), "event_id": String(tok[2])} if tok.size() >= 3 else {}
	state["eject_target"] = int(snapshot.get("dst", 0))
	state["eject_action"] = String(snapshot.get("dsa", ""))
	state["granted"] = Dictionary(snapshot.get("g", {})).duplicate()
	state["suspend_reason"] = String(snapshot.get("sus", ""))
	state["disorientation"] = float(snapshot.get("dis", 0.0))
	state["disorientation_event"] = String(snapshot.get("dev", ""))
	state["last_resolution"] = Dictionary(snapshot.get("lr", {})).duplicate()
	_display_elapsed = float(state["elapsed"])
	_display_emergency = float(state["emergency_elapsed"])
	var resolution: Dictionary = state["last_resolution"]
	if String(resolution.get("band", "")) == BAND_EJECTED and _replica_pending_eject_event.begins_with("eject:"):
		_replica_pending_eject_event = String(resolution.get("event_id", _replica_pending_eject_event))
	_follow_remote_ejection(resolution)
	return true


func _advance_remote_clock(snapshot: Dictionary) -> bool:
	var el := float(snapshot.get("el", 0.0))
	var em := float(snapshot.get("em", 0.0))
	var changed := false
	if el > float(state.get("elapsed", 0.0)):
		state["elapsed"] = el
		_display_elapsed = el
		changed = true
	if em > float(state.get("emergency_elapsed", 0.0)):
		state["emergency_elapsed"] = em
		_display_emergency = em
		changed = true
	if changed:
		state["disorientation"] = float(snapshot.get("dis", 0.0))
	return changed


## Réplica sem RPC de commit (sala dedicada ou RPC perdido): segue a ejeção
## anunciada pelo snapshot, uma única vez por evento, para o mesmo destino.
func _follow_remote_ejection(resolution: Dictionary) -> void:
	if core == null or String(resolution.get("band", "")) != BAND_EJECTED:
		return
	var event_id := String(resolution.get("event_id", ""))
	if event_id == "" or _replica_committed_ejects.has(event_id):
		return
	if int(resolution.get("origin", 0)) != int(core.current_phase) or String(core.mode) != "game":
		return
	var target := int(resolution.get("target", 0))
	if target <= 0:
		return
	core._commit_phase_mp_transfer(target, String(resolution.get("action", EJECT_ACTION)))


func _update_replica(delta: float) -> void:
	if float(state.get("disorientation", 0.0)) > 0.0 and not String(core.mode) in GLOBAL_SUSPEND_MODES:
		state["disorientation"] = maxf(0.0, float(state["disorientation"]) - delta)
	if not is_active() or String(state.get("suspend_reason", "")) != SUSPEND_NONE:
		return
	if String(core.mode) in GLOBAL_SUSPEND_MODES:
		return
	if current_state() == STATE_EMERGENCY:
		_display_emergency = minf(EMERGENCY_ESCAPE_SECONDS, _display_emergency + delta)
	else:
		_display_elapsed = minf(COLLAPSE_TOTAL_SECONDS, _display_elapsed + delta)


# ---------------------------------------------------------------- sinais locais

func _cue_key_for_state() -> String:
	var s := current_state()
	if not s in ACTIVE_STATES:
		return ""
	var running := String(state.get("suspend_reason", "")) != SUSPEND_PORTAL_LOCKED
	return "%s|%s|%s" % [String(state.get("event_id", "")), s, "run" if running else "locked"]


func _update_cues(delta: float) -> void:
	if core == null:
		return
	banner_timer = maxf(0.0, banner_timer - delta)
	if not _pending_arrival.is_empty() and String(core.mode) == "game":
		_present_arrival(_pending_arrival)
		_pending_arrival = {}
	var key := _cue_key_for_state()
	if key != _cue_key:
		_cue_key = key
		if key != "" and not _presented.has(key):
			_presented[key] = true
			_trim(_presented)
			_on_cue(current_state(), key.ends_with("|locked"))
	if current_state() == STATE_EMERGENCY and String(state.get("suspend_reason", "")) == SUSPEND_NONE:
		_emergency_pulse_timer -= delta
		if _emergency_pulse_timer <= 0.0:
			_emergency_pulse_timer = 3.0
			_shake(0.12, 3.0)
	else:
		_emergency_pulse_timer = 0.0


func _on_cue(cue_state: String, locked: bool) -> void:
	match cue_state:
		STATE_UNSTABLE:
			_alert(MSG_CONTAINED if locked else MSG_ACTIVATED, 3.2)
			if not locked:
				var portal := portal_position()
				if portal != Vector2.INF:
					core._spawn_radial_particles(portal, Color(0.62, 0.9, 1.0), 26)
		STATE_COLLAPSE:
			_alert(MSG_COLLAPSE, 2.6)
			_shake(0.22, 4.0)
		STATE_EMERGENCY:
			_alert(MSG_EMERGENCY, 3.4)
			_shake(0.3, 6.0)


func _present_arrival(resolution: Dictionary) -> void:
	if core == null or resolution.is_empty():
		return
	var key := "arrival|" + String(resolution.get("event_id", ""))
	if _presented.has(key):
		return
	_presented[key] = true
	_trim(_presented)
	match String(resolution.get("band", "")):
		BAND_PERFECT:
			_alert("TRAVESSIA PERFEITA — IMPULSO %s" % roman(int(resolution.get("momentum", 0))), 2.8)
		BAND_STABLE:
			_alert("TRAVESSIA ESTÁVEL — IMPULSO MANTIDO", 2.6)
		BAND_WEAKENED:
			_alert("FRAGMENTO ENFRAQUECIDO — IMPULSO PERDIDO", 2.6)
		BAND_EJECTED:
			_alert(MSG_EJECTED, 3.2)


## Reaproveita os anéis do alerta de evento existente e mostra o texto no HUD
## da Ruptura (o alerta de evento do runtime não desenha texto).
func _alert(text: String, duration: float) -> void:
	banner_text = text
	banner_timer = duration
	banner_duration = duration
	var color := Color(0.62, 0.9, 1.0)
	match current_state():
		STATE_COLLAPSE:
			color = Color(1.0, 0.62, 0.22)
		STATE_EMERGENCY:
			color = Color(1.0, 0.2, 0.26)
	if core.has_method("_show_event_alert"):
		core._show_event_alert(text, color)
	else:
		core.event_alert_text = text
		core.event_alert_timer = duration


func _shake(duration: float, strength: float) -> void:
	if core == null or not bool(core.gfx_screen_shake):
		return
	core.screen_shake_timer = maxf(float(core.screen_shake_timer), duration)
	core.screen_shake_strength = maxf(float(core.screen_shake_strength), strength)


func portal_position() -> Vector2:
	if core == null:
		return Vector2.INF
	var fragment: Dictionary = core.phase_fragment
	if fragment.is_empty():
		return Vector2.INF
	return Vector2(fragment.get("pos", core.player_pos))


static func roman(value: int) -> String:
	return ["", "I", "II", "III", "IV"][clampi(value, 0, MAX_MOMENTUM_STACKS)]


func _bump() -> void:
	state["rev"] = int(state.get("rev", 0)) + 1


static func _trim(ledger: Dictionary) -> void:
	while ledger.size() > LEDGER_LIMIT:
		ledger.erase(ledger.keys()[0])
