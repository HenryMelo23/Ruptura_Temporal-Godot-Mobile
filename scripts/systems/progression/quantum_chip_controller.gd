class_name RTQuantumChipController
extends RefCounted

## Chips quanticos: modificadores de run escolhidos antes da partida.
## Varios podem ficar ativos juntos. O modo ALEATORIO sorteia mais um chip no
## inicio de cada run (alem dos escolhidos a mao).

const CORRUPTOR := "corruptor"
const SEDENTA := "sedenta"
const MULTIDAO := "multidao"
const GANANCIA := "ganancia"
const RANDOM := "random"
const SAVE_PATH := "user://quantum_chips.cfg"

const CHIPS: Array = [
	{
		"id": CORRUPTOR, "name": "Corruptor Mercantil", "short": "CORRUPTOR",
		"buff": "Cada carta dropada vira um ? da cor da raridade. Na Fenda do Mercador voce escolhe QUALQUER carta daquela raridade.",
		"debuff": "Voce nao ve a carta ao coletar; so troca o ? quando a fenda abrir.",
		"color": Color(0.74, 0.4, 1.0), "glyph": "?",
	},
	{
		"id": SEDENTA, "name": "Sedenta por Sangue", "short": "SEDENTA",
		"buff": "+500% de dano.",
		"debuff": "Vida maxima reduzida a 10%.",
		"color": Color(1.0, 0.2, 0.26), "glyph": "+",
	},
	{
		"id": MULTIDAO, "name": "Multidao Caotica", "short": "MULTIDAO",
		"buff": "Inimigos com metade da vida.",
		"debuff": "O dobro de inimigos.",
		"color": Color(1.0, 0.62, 0.16), "glyph": "x2",
	},
	{
		"id": GANANCIA, "name": "Ganancia Corrosiva", "short": "GANANCIA",
		"buff": "O dobro de pontos por abate.",
		"debuff": "Cada golpe recebido custa o triplo do valor de um abate. Se faltar ponto, o que falta vira dano extra (ate +50% do golpe).",
		"color": Color(1.0, 0.86, 0.24), "glyph": "$",
	},
]

const SEDENTA_DAMAGE_MULT := 6.0
const SEDENTA_HP_MULT := 0.1
const MULTIDAO_COUNT_MULT := 2.0
const MULTIDAO_HP_MULT := 0.5
const GANANCIA_POINTS_MULT := 2.0
const GANANCIA_HIT_COST_KILLS := 3.0
const GANANCIA_MAX_EXTRA_DAMAGE := 0.5

const RARITY_ORDER: Array = ["common", "uncommon", "rare", "legendary"]

var core: Node = null
var persist := true
## Escolha do jogador na tela de selecao (persistida).
var selected: Dictionary = {}
var random_mode := false
## Chips efetivamente ativos na run atual.
var active: Dictionary = {}
var random_rolled := ""
## Corruptor: fichas ? pendentes por raridade e ultima carta escolhida por raridade.
var tokens: Dictionary = {}
var last_pick_id: Dictionary = {}
var remote_tokens_by_peer: Dictionary = {}
var confirmed_drop_ids: Dictionary = {}


func configure(runtime_core: Node) -> void:
	core = runtime_core
	var loop = Engine.get_main_loop()
	if loop != null and loop.get_script() != null:
		persist = false
	_load()


func _load() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for chip in CHIPS:
		selected[chip["id"]] = bool(cfg.get_value("selected", String(chip["id"]), false))
	random_mode = bool(cfg.get_value("selected", RANDOM, false))
	for rarity in RARITY_ORDER:
		last_pick_id[rarity] = String(cfg.get_value("corruptor_last", rarity, ""))


func save() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	for chip in CHIPS:
		cfg.set_value("selected", String(chip["id"]), bool(selected.get(chip["id"], false)))
	cfg.set_value("selected", RANDOM, random_mode)
	for rarity in RARITY_ORDER:
		cfg.set_value("corruptor_last", rarity, String(last_pick_id.get(rarity, "")))
	cfg.save(SAVE_PATH)


static func chip_def(id: String) -> Dictionary:
	for chip in CHIPS:
		if String(chip["id"]) == id:
			return chip
	return {}


func is_selected(id: String) -> bool:
	return random_mode if id == RANDOM else bool(selected.get(id, false))


func toggle(id: String) -> void:
	if id == RANDOM:
		random_mode = not random_mode
	else:
		selected[id] = not bool(selected.get(id, false))
	save()


func clear_selection() -> void:
	selected.clear()
	random_mode = false
	save()


func selected_count() -> int:
	var n := 0
	for chip in CHIPS:
		if bool(selected.get(chip["id"], false)):
			n += 1
	return n + (1 if random_mode else 0)


func is_active(id: String) -> bool:
	return bool(active.get(id, false))


## O host fecha a configuração da equipe antes do RPC que inicia a partida.
## O sorteio é feito uma vez; clientes recebem o resultado já decidido.
func prepare_team_config() -> Dictionary:
	var ids: Array[String] = []
	for chip in CHIPS:
		if bool(selected.get(chip["id"], false)):
			ids.append(String(chip["id"]))
	var rolled := ""
	if random_mode:
		var pool: Array[String] = []
		for chip in CHIPS:
			var id := String(chip["id"])
			if not ids.has(id):
				pool.append(id)
		if not pool.is_empty():
			rolled = pool[core.rng.randi_range(0, pool.size() - 1)]
			ids.append(rolled)
	return {"active": ids, "random_rolled": rolled}


static func validated_team_config(data: Dictionary) -> Dictionary:
	var ids: Array[String] = []
	var incoming = data.get("active", [])
	if not incoming is Array or incoming.size() > CHIPS.size():
		return {"active": [], "random_rolled": ""}
	for raw_id in incoming:
		var id := String(raw_id)
		if chip_def(id).is_empty() or ids.has(id):
			return {"active": [], "random_rolled": ""}
		ids.append(id)
	var rolled := String(data.get("random_rolled", ""))
	if rolled != "" and not ids.has(rolled):
		return {"active": [], "random_rolled": ""}
	return {"active": ids, "random_rolled": rolled}


## Chamado no inicio de cada run, antes de o jogador ganhar vida/dano base.
func on_run_started(team_config: Dictionary = {}) -> void:
	active.clear()
	tokens.clear()
	remote_tokens_by_peer.clear()
	confirmed_drop_ids.clear()
	random_rolled = ""
	if core == null:
		return
	if bool(core.is_multiplayer):
		var checked := validated_team_config(team_config)
		for id in checked["active"]:
			active[String(id)] = true
		random_rolled = String(checked["random_rolled"])
	else:
		for chip in CHIPS:
			if bool(selected.get(chip["id"], false)):
				active[chip["id"]] = true
	if not bool(core.is_multiplayer) and random_mode:
		var pool: Array = []
		for chip in CHIPS:
			if not bool(active.get(chip["id"], false)):
				pool.append(String(chip["id"]))
		if not pool.is_empty():
			random_rolled = String(pool[core.rng.randi_range(0, pool.size() - 1)])
			active[random_rolled] = true
	if not active.is_empty():
		var names: Array = []
		for id in active.keys():
			names.append(String(chip_def(id).get("short", id)))
		core._add_text("CHIPS: " + ", ".join(names), core.player_pos + Vector2(-140, -150), Color(0.78, 0.6, 1.0), 2.6, 18)


# ================================================================ efeitos
func damage_multiplier() -> float:
	return SEDENTA_DAMAGE_MULT if is_active(SEDENTA) else 1.0


func apply_hp_max(base_hp: int) -> int:
	return maxi(1, int(round(float(base_hp) * SEDENTA_HP_MULT))) if is_active(SEDENTA) else base_hp


func enemy_count_multiplier() -> float:
	return MULTIDAO_COUNT_MULT if is_active(MULTIDAO) else 1.0


func wave_enemy_hp_multiplier() -> float:
	return MULTIDAO_HP_MULT if is_active(MULTIDAO) else 1.0


func points_multiplier() -> float:
	return GANANCIA_POINTS_MULT if is_active(GANANCIA) else 1.0


## Ganancia: cobra pontos por golpe; o que faltar vira dano extra. Retorna o dano extra.
func on_player_hit(final_damage: int) -> int:
	if not is_active(GANANCIA) or final_damage <= 0:
		return 0
	var kill_value: float = float(core._points_for_enemy({"points": 75}))
	var cost: int = maxi(1, int(round(kill_value * GANANCIA_HIT_COST_KILLS)))
	var paid: int = mini(cost, maxi(0, int(core.score)))
	if paid > 0:
		core._apply_score_delta(-paid, true, "ganancia_hit")
	var missing: int = cost - paid
	core._add_text("-%d PTS" % cost, core.player_pos + Vector2(-34, -70), Color(1.0, 0.82, 0.2), 0.7, 16)
	if missing <= 0:
		return 0
	var extra: int = int(round(float(final_damage) * GANANCIA_MAX_EXTRA_DAMAGE * float(missing) / float(cost)))
	if extra > 0:
		core._add_text("DIVIDA +%d" % extra, core.player_pos + Vector2(-40, -92), Color(1.0, 0.4, 0.2), 0.8, 16)
	return extra


# ================================================================ corruptor
func corruptor_active() -> bool:
	return is_active(CORRUPTOR)


func add_token(rarity: String) -> void:
	var r: String = rarity if rarity in RARITY_ORDER else "common"
	tokens[r] = int(tokens.get(r, 0)) + 1


func token_total() -> int:
	var n := 0
	for r in RARITY_ORDER:
		n += int(tokens.get(r, 0))
	return n


## A autoridade usa a soma so para decidir se abre a Fenda. Cada jogador
## resgata apenas as proprias fichas dentro da mesma oficina.
func team_token_total() -> int:
	var total := token_total()
	if core != null and bool(core.is_multiplayer) and core._is_world_authority():
		for peer_id in core._living_run_player_peer_ids():
			if peer_id != core._mp_unique_id():
				total += int(remote_tokens_by_peer.get(peer_id, 0))
	return total


func confirm_remote_token(peer_id: int, drop_id: String) -> bool:
	if peer_id <= 0 or drop_id == "" or confirmed_drop_ids.has(drop_id):
		return false
	confirmed_drop_ids[drop_id] = true
	remote_tokens_by_peer[peer_id] = int(remote_tokens_by_peer.get(peer_id, 0)) + 1
	return true


func confirm_local_token(drop_id: String, rarity: String) -> bool:
	if drop_id == "" or confirmed_drop_ids.has(drop_id):
		return false
	confirmed_drop_ids[drop_id] = true
	add_token(rarity)
	return true


func redeem_remote_tokens(peer_id: int, count: int) -> void:
	if peer_id <= 0 or count <= 0:
		return
	remote_tokens_by_peer[peer_id] = maxi(0, int(remote_tokens_by_peer.get(peer_id, 0)) - count)


## Proxima raridade a resgatar: comuns, incomuns, raras e lendarias, nessa ordem.
func next_token_rarity() -> String:
	for r in RARITY_ORDER:
		if int(tokens.get(r, 0)) > 0:
			return r
	return ""


func consume_token(rarity: String) -> void:
	tokens[rarity] = maxi(0, int(tokens.get(rarity, 0)) - 1)


func remember_pick(rarity: String, card_id: String) -> void:
	last_pick_id[rarity] = card_id
	save()


# ================================================================ save
func save_state() -> Dictionary:
	return {"active": active.duplicate(), "tokens": tokens.duplicate(), "random_rolled": random_rolled}


func load_state(data: Dictionary) -> void:
	active = Dictionary(data.get("active", {})).duplicate()
	tokens = Dictionary(data.get("tokens", {})).duplicate()
	random_rolled = String(data.get("random_rolled", ""))
