class_name RTMerchantMissionController
extends RefCounted

## Encomendas do Bussola. So existem depois que a fenda foi estabilizada NESTA
## run, e sao a unica fonte da carta Moeda Estavel.
##
## Tres tipos:
## - ZONA:     eliminar inimigos dentro de uma marca no mapa da fase;
## - ENTREGA:  juntar engrenagens que os inimigos derrubam e levar ao balcao;
## - DOACAO:   doar ao Bussola uma carta que ele quer (ela sai do deck).
##
## Uma encomenda por vez; a recompensa sai no balcao. Tudo vive so na run
## (entra no snapshot da oficina) e roda so no solo: a sala multiplayer nao tem
## o menu narrativo do balcao.

const KIND_ZONE := "zone"
const KIND_DELIVER := "deliver"
const KIND_DONATE := "donate"
const REWARD_CARD_ID := "moeda_estavel"

const ZONE_KILLS := 25
const ZONE_RADIUS := 300.0
const ZONE_MIN_DISTANCE := 520.0
const ZONE_MAX_DISTANCE := 980.0
const DELIVER_GEARS := 6
const GEAR_DROP_CHANCE := 0.08
const GEAR_LIFE := 22.0
const GEAR_PICKUP_RADIUS := 52.0
const MAX_GEARS_ON_FLOOR := 12

var core: Node = null
## {"kind", "target", "progress", "card_id", "card_name", "zone_pos", "zone_phase"}
var mission: Dictionary = {}
var completed := 0
var gears: Array[Dictionary] = []


func configure(runtime_core: Node) -> void:
	core = runtime_core


func reset_run() -> void:
	mission.clear()
	completed = 0
	gears.clear()


func active() -> bool:
	return not mission.is_empty()


func kind() -> String:
	return String(mission.get("kind", ""))


func ready_to_turn_in() -> bool:
	return active() and int(mission.get("progress", 0)) >= int(mission.get("target", 1))


func reward_card() -> Dictionary:
	return core._find_card_by_id(REWARD_CARD_ID) if core != null else {}


## O Bussola so tem Moeda para dar enquanto ela nao estiver no maximo.
func reward_available() -> bool:
	var card: Dictionary = reward_card()
	return not card.is_empty() and not core._card_at_max(card)


# ================================================================ oferta
## Sorteia uma encomenda. `saved_world` e `saved_pos` sao o mapa/posicao da
## fase guardados pela oficina (a marca nasce la fora, nao na oficina).
func offer(saved_world: Vector2, saved_pos: Vector2) -> Dictionary:
	var kinds: Array[String] = [KIND_ZONE, KIND_DELIVER]
	if not _donation_candidates().is_empty():
		kinds.append(KIND_DONATE)
	var pick: String = kinds[core.rng.randi_range(0, kinds.size() - 1)]
	var offered: Dictionary = {"kind": pick, "progress": 0, "target": 1}
	match pick:
		KIND_ZONE:
			offered["target"] = ZONE_KILLS
			offered["zone_pos"] = _zone_position(saved_world, saved_pos)
			offered["zone_phase"] = int(core.current_phase)
		KIND_DELIVER:
			offered["target"] = DELIVER_GEARS
		KIND_DONATE:
			var candidates: Array = _donation_candidates()
			var card: Dictionary = candidates[core.rng.randi_range(0, candidates.size() - 1)]
			offered["card_id"] = String(core._card_id(card))
			offered["card_name"] = String(card.get("nick", card.get("name", "")))
	return offered


func accept(offered: Dictionary) -> void:
	mission = offered.duplicate(true)
	gears.clear()


func _zone_position(world: Vector2, origin: Vector2) -> Vector2:
	var margin := Vector2(ZONE_RADIUS + 60.0, ZONE_RADIUS + 60.0)
	if world.x <= margin.x * 2.0 or world.y <= margin.y * 2.0:
		return world * 0.5
	for attempt in range(12):
		var angle: float = core.rng.randf_range(0.0, TAU)
		var dist: float = core.rng.randf_range(ZONE_MIN_DISTANCE, ZONE_MAX_DISTANCE)
		var pos: Vector2 = origin + Vector2.from_angle(angle) * dist
		if pos.x >= margin.x and pos.y >= margin.y and pos.x <= world.x - margin.x and pos.y <= world.y - margin.y:
			return pos
	return (origin + Vector2(ZONE_MIN_DISTANCE, 0.0)).clamp(margin, world - margin)


## Cartas que ele aceita: comuns/incomuns que ela tem, menos as fontes raras.
func _donation_candidates() -> Array:
	var out: Array = []
	for card in core.CARDS:
		var card_id: String = String(core._card_id(card))
		if card_id == REWARD_CARD_ID or card_id == String(core.CARD_CINZAS_ID):
			continue
		if not (core._is_common_card(card) or core._is_uncommon_card(card)):
			continue
		if int(core._card_count(card)) <= 0:
			continue
		out.append(card)
	return out


# ================================================================ progresso
func on_enemy_killed(enemy: Dictionary, pos: Vector2) -> void:
	if not active() or core._merchant_dimension().active:
		return
	match kind():
		KIND_ZONE:
			if int(mission.get("zone_phase", -1)) != int(core.current_phase):
				return
			if pos.distance_to(Vector2(mission.get("zone_pos", Vector2.INF))) > ZONE_RADIUS:
				return
			_advance(1, pos)
		KIND_DELIVER:
			if ready_to_turn_in() or gears.size() >= MAX_GEARS_ON_FLOOR:
				return
			var supreme: bool = bool(enemy.get("elite", false)) or core._is_boss_or_mini_boss_or_larapio(enemy)
			if supreme or core.rng.randf() < GEAR_DROP_CHANCE:
				gears.append({"pos": pos, "life": GEAR_LIFE, "spin": core.rng.randf_range(0.0, TAU)})


func update(delta: float) -> void:
	if gears.is_empty() or core._merchant_dimension().active:
		return
	var player: Vector2 = Vector2(core.player_pos)
	var radius: float = float(core._neutral_pickup_radius(GEAR_PICKUP_RADIUS))
	for gear in gears:
		gear["life"] = float(gear["life"]) - delta
		gear["spin"] = float(gear["spin"]) + delta * 3.0
		if float(gear["life"]) > 0.0 and Vector2(gear["pos"]).distance_to(player) <= radius:
			gear["life"] = 0.0
			if active() and kind() == KIND_DELIVER and not ready_to_turn_in():
				_advance(1, Vector2(gear["pos"]))
	gears = gears.filter(func(g: Dictionary) -> bool: return float(g["life"]) > 0.0)


func _advance(amount: int, pos: Vector2) -> void:
	var target: int = int(mission.get("target", 1))
	mission["progress"] = mini(target, int(mission.get("progress", 0)) + amount)
	var done: bool = int(mission["progress"]) >= target
	var label: String = "MARCA" if kind() == KIND_ZONE else "ENGRENAGENS"
	core._add_text("%s %d/%d" % [label, int(mission["progress"]), target], pos + Vector2(-70, -96), Color(1.0, 0.84, 0.32), 0.9 if not done else 2.0, 18 if not done else 22)
	if done:
		core._add_text("ENCOMENDA PRONTA: VOLTE AO BÚSSOLA", core.player_pos + Vector2(-190, -150), Color(1.0, 0.86, 0.36), 2.4, 20)
		core._play_sfx("ui_manifest_switch", 0.01, 0.5, 1.3)


# ================================================================ entrega
## Doacao: tira 1 copia da carta pedida do deck. Retorna false se ela nao tem.
func donate() -> bool:
	if not active() or kind() != KIND_DONATE:
		return false
	var card_id: String = String(mission.get("card_id", ""))
	if card_id == "" or not core._consume_card_count(card_id):
		return false
	mission["progress"] = int(mission.get("target", 1))
	return true


## Fecha a encomenda pronta e entrega a Moeda Estavel.
func turn_in() -> bool:
	if not ready_to_turn_in():
		return false
	var card: Dictionary = reward_card()
	if card.is_empty():
		return false
	mission.clear()
	gears.clear()
	completed += 1
	core._apply_card(card)
	core._add_text("ITEM: MOEDA ESTÁVEL", core.player_pos + Vector2(-110, -120), Color(1.0, 0.72, 0.18), 2.2, 22)
	core._spawn_radial_particles(core.player_pos, Color(1.0, 0.72, 0.18), 28)
	return true


## Linha curta do objetivo para o HUD da run.
func objective_text() -> String:
	if not active():
		return ""
	var progress: int = int(mission.get("progress", 0))
	var target: int = int(mission.get("target", 1))
	if ready_to_turn_in():
		return "ENCOMENDA PRONTA: VOLTE AO BÚSSOLA"
	match kind():
		KIND_ZONE:
			return "ELIMINE NA MARCA DO BÚSSOLA %d/%d" % [progress, target]
		KIND_DELIVER:
			return "JUNTE ENGRENAGENS DOS INIMIGOS %d/%d" % [progress, target]
		KIND_DONATE:
			return "DOE %s AO BÚSSOLA" % String(mission.get("card_name", "")).to_upper()
	return ""


func save_state() -> Dictionary:
	return {"mission": mission.duplicate(true), "completed": completed}


func load_state(data: Dictionary) -> void:
	mission = Dictionary(data.get("mission", {})).duplicate(true)
	completed = int(data.get("completed", 0))
	gears.clear()
