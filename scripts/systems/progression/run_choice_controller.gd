class_name RTRunChoiceController
extends RefCounted

## Escolha obrigatoria de fim de chefe (mode "run_choice"):
##  - kind "pact": chefes 1, 3, 4, 5 e 6 -> 1 de 3 pactos (buff + debuff caotico)
##  - kind "evolution": chefe 2 -> 1 de 3 evolucoes autorais da forma atual
## Sem rerrolar e sem pular. Toque seleciona, ESCOLHER confirma; teclado/controle
## usa setas + Enter.

const OPEN_DELAY := 2.2

var core
var kind := ""
var options: Array = []
var selected := 0
var previous_mode := "game"
var pending_kind := ""
var pending_timer := 0.0
var age := 0.0
var mp_epoch := 0
var mp_kind := ""
var mp_pending := false
var mp_offer_ids: Array[String] = []
var mp_votes: Dictionary = {}
var mp_local_voted := false


func configure(runtime_core) -> void:
	core = runtime_core


func reset() -> void:
	kind = ""
	options.clear()
	selected = 0
	pending_kind = ""
	pending_timer = 0.0
	mp_epoch = 0
	mp_kind = ""
	mp_pending = false
	mp_offer_ids.clear()
	mp_votes.clear()
	mp_local_voted = false


func is_open() -> bool:
	return core.mode == "run_choice"


## Agenda a escolha para depois da animacao de morte do chefe.
func queue(choice_kind: String, delay: float = OPEN_DELAY) -> void:
	pending_kind = choice_kind
	pending_timer = delay


## O anfitriao escolhe a oferta uma vez. Pactos sao uma decisao da equipe;
## evolucoes continuam individuais, pois dependem da forma de cada jogador.
func begin_multiplayer_boss(choice_kind: String) -> Dictionary:
	mp_epoch += 1
	mp_kind = choice_kind
	mp_pending = choice_kind != ""
	mp_local_voted = false
	mp_votes.clear()
	mp_offer_ids.clear()
	if choice_kind == "pact":
		for option in core._boss_pacts().roll_offer(3):
			mp_offer_ids.append(String(option.get("id", "")))
	if choice_kind != "":
		queue(choice_kind)
	return {"epoch": mp_epoch, "kind": choice_kind, "offer": mp_offer_ids.duplicate()}


func accept_multiplayer_boss(epoch: int, choice_kind: String, offer_ids: Array) -> bool:
	if epoch <= mp_epoch or not choice_kind in ["", "pact", "evolution"]:
		return false
	var checked: Array[String] = []
	if choice_kind == "pact":
		for raw_id in offer_ids:
			var id := String(raw_id)
			if RTBossPactCatalog.by_id(id).is_empty() or checked.has(id):
				return false
			checked.append(id)
		if checked.size() != 3:
			return false
	mp_epoch = epoch
	mp_kind = choice_kind
	mp_pending = choice_kind != ""
	mp_local_voted = false
	mp_votes.clear()
	mp_offer_ids = checked
	if choice_kind != "":
		queue(choice_kind)
	return true


func multiplayer_ready() -> bool:
	return not mp_pending


func record_vote(peer_id: int, epoch: int, option_id: String) -> bool:
	if not core._is_world_authority() or not mp_pending or epoch != mp_epoch:
		return false
	if not core._living_run_player_peer_ids().has(peer_id) or mp_votes.has(peer_id):
		return false
	if mp_kind == "pact" and not mp_offer_ids.has(option_id):
		return false
	if mp_kind == "evolution" and option_id != "done":
		return false
	mp_votes[peer_id] = option_id
	_try_finish_multiplayer_choice()
	return true


func _try_finish_multiplayer_choice() -> void:
	if not mp_pending or not core._is_world_authority():
		return
	var living: Array[int] = core._living_run_player_peer_ids()
	if living.is_empty():
		return
	for peer_id in living:
		if not mp_votes.has(peer_id):
			return
	var winner := ""
	if mp_kind == "pact":
		var counts := {}
		for peer_id in living:
			var id := String(mp_votes[peer_id])
			counts[id] = int(counts.get(id, 0)) + 1
		winner = String(mp_votes.get(core._mp_unique_id(), mp_offer_ids[0]))
		for id in mp_offer_ids:
			if int(counts.get(id, 0)) > int(counts.get(winner, 0)):
				winner = id
	accept_multiplayer_result(mp_epoch, winner)
	if core._shop_rpc_available():
		core.rpc("_rpc_run_choice_result", mp_epoch, winner)


func accept_multiplayer_result(epoch: int, option_id: String) -> bool:
	if not mp_pending or epoch != mp_epoch:
		return false
	if mp_kind == "pact":
		if not mp_offer_ids.has(option_id):
			return false
		var option: Dictionary = RTBossPactCatalog.by_id(option_id)
		core._boss_pacts().apply(option)
		core._add_text("PACTO DA EQUIPE: %s" % String(option.get("name", "")).to_upper(), core.player_pos + Vector2(0, -116), Color(1.0, 0.78, 0.36), 2.0, 20)
	elif option_id != "":
		return false
	mp_pending = false
	return true


func update(delta: float) -> void:
	if mp_pending and core._is_world_authority():
		_try_finish_multiplayer_choice()
	if pending_kind == "":
		return
	pending_timer -= delta
	if pending_timer > 0.0 or core.mode != "game" or core.is_dead:
		return
	var next_kind := pending_kind
	pending_kind = ""
	open(next_kind)


func open(choice_kind: String) -> bool:
	var rolled: Array = []
	if choice_kind == "pact":
		if core.is_multiplayer and mp_pending:
			for id in mp_offer_ids:
				var pact: Dictionary = RTBossPactCatalog.by_id(id).duplicate(true)
				pact["lore_text"] = RTBossPactCatalog.lore_for(pact, core._boss_pacts().hero_name())
				rolled.append(pact)
		else:
			rolled = core._boss_pacts().roll_offer(3)
	elif choice_kind == "evolution":
		rolled = core._form_evolutions().roll_offer(3)
	if rolled.is_empty():
		return false
	kind = choice_kind
	options = rolled
	selected = -1
	age = 0.0
	previous_mode = core.mode if core.mode != "run_choice" else "game"
	core.mode = "run_choice"
	core._block_ui_input(420)
	core._play_sfx("ui_spectrum_switch", 0.012, 0.5, 0.82)
	return true


func move_selection(step: int) -> void:
	if options.is_empty():
		return
	selected = (maxi(0, selected) + step + options.size()) % options.size() if selected >= 0 else (0 if step > 0 else options.size() - 1)
	core._play_sfx("ui_move", 0.0, 0.3, 1.0)


func select(index: int) -> void:
	if index < 0 or index >= options.size():
		return
	selected = index
	core._play_sfx("ui_move", 0.0, 0.3, 1.0)


func confirm() -> void:
	if selected < 0 or selected >= options.size():
		return
	var option: Dictionary = options[selected]
	if core.is_multiplayer and mp_pending:
		if not mp_local_voted:
			if kind == "evolution":
				core._form_evolutions().apply(option)
				core._add_text("EVOLUCAO: %s" % String(option.get("name", "")).to_upper(), core.player_pos + Vector2(0, -116), Color(option.get("color", Color(0.6, 1.0, 1.0))), 2.0, 24)
				core._submit_run_choice_vote(mp_epoch, "done")
			else:
				core._submit_run_choice_vote(mp_epoch, String(option.get("id", "")))
				core._add_text("VOTO REGISTRADO", core.player_pos + Vector2(0, -116), Color(1.0, 0.78, 0.36), 1.7, 20)
			mp_local_voted = true
	elif kind == "pact":
		core._boss_pacts().apply(option)
		core._add_text("PACTO: %s" % String(option.get("name", "")).to_upper(), core.player_pos + Vector2(0, -116), Color(1.0, 0.78, 0.36), 2.0, 24)
	elif kind == "evolution":
		core._form_evolutions().apply(option)
		core._add_text("EVOLUCAO: %s" % String(option.get("name", "")).to_upper(), core.player_pos + Vector2(0, -116), Color(option.get("color", Color(0.6, 1.0, 1.0))), 2.0, 24)
	core._spawn_radial_particles(core.player_pos, Color(1.0, 0.8, 0.4), 30)
	core._play_sfx("ui_spectrum_switch", 0.012, 0.62, 1.15)
	core._vibrate(95, 0.35)
	options.clear()
	kind = ""
	core.mode = previous_mode if previous_mode != "" else "game"
	core._block_ui_input(220)


func handle_key(keycode: int) -> void:
	if keycode in [KEY_LEFT, KEY_A, KEY_UP, KEY_W]:
		move_selection(-1)
	elif keycode in [KEY_RIGHT, KEY_D, KEY_DOWN, KEY_S]:
		move_selection(1)
	elif keycode in [KEY_ENTER, KEY_SPACE, KEY_KP_ENTER]:
		if selected < 0:
			selected = 0
		else:
			confirm()


func handle_tap(pos: Vector2) -> bool:
	if Rect2(core.buttons.get("run_choice_confirm", Rect2())).has_point(pos):
		confirm()
		return true
	for i in range(options.size()):
		if Rect2(core.buttons.get("run_choice_%d" % i, Rect2())).has_point(pos):
			if selected == i and core._uses_desktop_ui():
				confirm()
			else:
				select(i)
			return true
	return false
