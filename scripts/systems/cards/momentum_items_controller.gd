class_name RTMomentumItemsController
extends RefCounted

## Dono de quatro itens comuns (lote de 26/11):
## - Retorno Voluntario: +1 uso guardado da HAB1 por copia; a recarga nao muda
##   (os usos extras recarregam um de cada vez, no tempo normal da HAB1).
## - Estoque da Ganancia: abate da +3,5% de dano (+1% por copia), ate 10
##   acumulos (+5 por copia), por 7 s; causar dano renova o tempo.
## - Espectro Eletrico: orbe de energia perto dela a cada 10 s (-10% por
##   copia); pegar da +12% de velocidade, ate 3 acumulos (+3 por copia), 12 s.
## - Eco da Ruina: o proximo dano cai 10% e chega em 3 golpes (+1 por copia);
##   so o ultimo pode matar. Recarga de 15 s.
## Numeros por copia usam a contagem efetiva (Cinzas somam) e a Carta Zero
## amplifica as porcentagens.

const RETORNO_ID := "retorno_voluntario"
const GANANCIA_ID := "estoque_ganancia"
const ESPECTRO_ID := "espectro_eletrico"
const ECO_ID := "eco_ruina"
const ECO_SOURCE := "card_eco_ruina"

const GANANCIA_BASE := 0.035
const GANANCIA_PER_COPY := 0.01
const GANANCIA_MAX_BASE := 10
const GANANCIA_MAX_PER_COPY := 5
const GANANCIA_DURATION := 7.0

const ESPECTRO_INTERVAL := 10.0
const ESPECTRO_INTERVAL_STEP := 0.9
const ESPECTRO_MIN_INTERVAL := 3.0
const ESPECTRO_SPEED := 0.12
const ESPECTRO_MAX_BASE := 3
const ESPECTRO_MAX_PER_COPY := 3
const ESPECTRO_DURATION := 12.0
const ESPECTRO_ORB_LIFE := 14.0
const ESPECTRO_ORB_LIMIT := 3
const ESPECTRO_PICKUP_RADIUS := 46.0
const ESPECTRO_SPAWN_MIN := 140.0
const ESPECTRO_SPAWN_MAX := 260.0

const ECO_REDUCTION := 0.10
const ECO_HITS := 3
const ECO_INTERVAL := 0.45
const ECO_COOLDOWN := 15.0

var core: Node = null
## Retorno Voluntario.
var hab1_charges := 0
var hab1_recharge := 0.0
## Estoque da Ganancia.
var ganancia_stacks := 0
var ganancia_timer := 0.0
## Espectro Eletrico.
var orbs: Array = []
var orb_timer := 0.0
var speed_stacks := 0
var speed_timer := 0.0
## Eco da Ruina.
var eco_cooldown := 0.0
var eco_hits: Array = []
var flashes: Array = []


func configure(runtime_core: Node) -> void:
	core = runtime_core


func reset() -> void:
	hab1_charges = 0
	hab1_recharge = 0.0
	ganancia_stacks = 0
	ganancia_timer = 0.0
	orbs.clear()
	orb_timer = 0.0
	speed_stacks = 0
	speed_timer = 0.0
	eco_cooldown = 0.0
	eco_hits.clear()
	flashes.clear()


func count(card_id: String) -> float:
	return float(core._new_common_card_count(card_id)) if core != null else 0.0


func copies(card_id: String) -> int:
	var n := count(card_id)
	return maxi(1, int(floor(n))) if n > 0.0 else 0


func _power(card_id: String, value: float) -> float:
	return float(core._apply_carta_zero_to_common_value(card_id, "power", value))


func update(delta: float) -> void:
	if core == null:
		return
	_update_retorno(delta)
	_update_ganancia(delta)
	_update_espectro(delta)
	_update_eco(delta)
	for i in range(flashes.size() - 1, -1, -1):
		flashes[i]["life"] = float(flashes[i]["life"]) - delta
		if float(flashes[i]["life"]) <= 0.0:
			flashes.remove_at(i)


# ================================================================ Retorno
func hab1_max_charges() -> int:
	return copies(RETORNO_ID)


## Os usos extras so recarregam com a HAB1 pronta, um de cada vez, no tempo
## normal da HAB1: a recarga da habilidade nao muda.
func _update_retorno(delta: float) -> void:
	var cap := hab1_max_charges()
	if hab1_charges > cap:
		hab1_charges = cap
	if cap <= 0 or hab1_charges >= cap:
		hab1_recharge = 0.0
		return
	var cooldown: float = float(core._skill_cooldown())
	if float(core.time_alive) - float(core.last_skill_time) < cooldown:
		return
	hab1_recharge += delta
	if hab1_recharge >= cooldown:
		hab1_recharge = 0.0
		hab1_charges += 1


## HAB1 em recarga: gasta um uso guardado (true) ou nao ha nenhum (false).
func use_stored_hab1() -> bool:
	if hab1_charges <= 0:
		return false
	hab1_charges -= 1
	flashes.append({"kind": "retorno", "life": 0.45, "max": 0.45})
	return true


# ================================================================ Ganancia
func ganancia_max_stacks() -> int:
	var n := copies(GANANCIA_ID)
	return 0 if n <= 0 else GANANCIA_MAX_BASE + GANANCIA_MAX_PER_COPY * (n - 1)


func ganancia_per_stack() -> float:
	var n := count(GANANCIA_ID)
	if n <= 0.0:
		return 0.0
	return _power(GANANCIA_ID, GANANCIA_BASE + GANANCIA_PER_COPY * maxf(0.0, n - 1.0))


func damage_multiplier() -> float:
	if ganancia_stacks <= 0 or ganancia_timer <= 0.0:
		return 1.0
	return 1.0 + float(ganancia_stacks) * ganancia_per_stack()


func on_enemy_killed(enemy: Dictionary) -> void:
	var cap := ganancia_max_stacks()
	if cap <= 0:
		return
	var killer := int(enemy.get("killed_by_peer_id", core._mp_unique_id()))
	if killer != int(core._mp_unique_id()):
		return
	ganancia_stacks = mini(cap, ganancia_stacks + 1)
	ganancia_timer = GANANCIA_DURATION


## Dano direto da Geovana: aplica o bonus e renova o tempo dos acumulos.
func apply_outgoing(amount: float, source: String) -> float:
	if ganancia_stacks <= 0 or amount <= 0.0 or not core._card_damage_can_receive_bonus(source):
		return amount
	ganancia_timer = GANANCIA_DURATION
	return amount * damage_multiplier()


func _update_ganancia(delta: float) -> void:
	if ganancia_stacks <= 0:
		return
	if ganancia_max_stacks() <= 0:
		ganancia_stacks = 0
		return
	ganancia_timer = maxf(0.0, ganancia_timer - delta)
	if ganancia_timer <= 0.0:
		ganancia_stacks = 0


# ================================================================ Espectro
func espectro_interval() -> float:
	var n := copies(ESPECTRO_ID)
	return maxf(ESPECTRO_MIN_INTERVAL, ESPECTRO_INTERVAL * pow(ESPECTRO_INTERVAL_STEP, float(maxi(0, n - 1))))


func speed_max_stacks() -> int:
	var n := copies(ESPECTRO_ID)
	return 0 if n <= 0 else ESPECTRO_MAX_BASE + ESPECTRO_MAX_PER_COPY * (n - 1)


func movement_speed_bonus() -> float:
	if speed_stacks <= 0 or speed_timer <= 0.0:
		return 0.0
	return float(speed_stacks) * _power(ESPECTRO_ID, ESPECTRO_SPEED)


func _update_espectro(delta: float) -> void:
	if speed_stacks > 0:
		speed_timer = maxf(0.0, speed_timer - delta)
		if speed_timer <= 0.0:
			speed_stacks = 0
	if copies(ESPECTRO_ID) <= 0:
		orbs.clear()
		return
	orb_timer += delta
	if orb_timer >= espectro_interval():
		orb_timer = 0.0
		if orbs.size() < ESPECTRO_ORB_LIMIT:
			_spawn_orb()
	var me: Vector2 = core.player_pos
	for i in range(orbs.size() - 1, -1, -1):
		var orb: Dictionary = orbs[i]
		orb["life"] = float(orb["life"]) - delta
		if Vector2(orb["pos"]).distance_to(me) <= ESPECTRO_PICKUP_RADIUS:
			speed_stacks = mini(speed_max_stacks(), speed_stacks + 1)
			speed_timer = ESPECTRO_DURATION
			flashes.append({"kind": "espectro", "pos": orb["pos"], "life": 0.5, "max": 0.5})
			orbs.remove_at(i)
		elif float(orb["life"]) <= 0.0:
			orbs.remove_at(i)


func _spawn_orb() -> void:
	var rng: RandomNumberGenerator = core.rng
	var at: Vector2 = Vector2(core.player_pos) + Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(ESPECTRO_SPAWN_MIN, ESPECTRO_SPAWN_MAX)
	var world: Vector2 = Vector2(core.WORLD_SIZE)
	at = at.clamp(Vector2(60, 60), world - Vector2(60, 60))
	orbs.append({"pos": at, "life": ESPECTRO_ORB_LIFE, "max": ESPECTRO_ORB_LIFE, "phase": rng.randf_range(0.0, TAU)})


# ================================================================ Eco
func eco_hit_count() -> int:
	var n := copies(ECO_ID)
	return 0 if n <= 0 else ECO_HITS + (n - 1)


func eco_ready() -> bool:
	return eco_hit_count() > 0 and eco_cooldown <= 0.0 and eco_hits.is_empty()


## Chamado com o dano final do golpe (ja mitigado). Quando pronto, devolve 0 e
## parcela o dano reduzido em golpes; senao devolve o dano intacto.
func on_player_hit(final: int) -> int:
	if final <= 0 or not eco_ready():
		return final
	var total: float = float(final) * (1.0 - _power(ECO_ID, ECO_REDUCTION))
	var hits := eco_hit_count()
	var each: float = total / float(hits)
	for k in range(hits):
		eco_hits.append({"amount": each, "delay": ECO_INTERVAL * float(k + 1), "last": k == hits - 1})
	eco_cooldown = ECO_COOLDOWN
	flashes.append({"kind": "eco", "life": 0.6, "max": 0.6})
	core._add_text("ECO DA RUÍNA", Vector2(core.player_pos) + Vector2(-70, -112), Color(1.0, 0.4, 0.32), 0.9, 18)
	return 0


func _update_eco(delta: float) -> void:
	if eco_cooldown > 0.0 and eco_hits.is_empty():
		eco_cooldown = maxf(0.0, eco_cooldown - delta)
	if eco_hits.is_empty():
		return
	if bool(core.is_dead) or core._merchant_dimension().seals_phase_world():
		eco_hits.clear()
		return
	for hit in eco_hits:
		hit["delay"] = float(hit["delay"]) - delta
	while not eco_hits.is_empty() and float(eco_hits[0]["delay"]) <= 0.0:
		var hit: Dictionary = eco_hits.pop_front()
		var dmg: int = int(ceil(float(hit["amount"])))
		if not bool(hit["last"]):
			# Golpes do meio nunca matam: deixam ao menos 1 de vida.
			dmg = mini(dmg, maxi(0, int(core.player_hp) - 1))
		if dmg <= 0:
			continue
		core.player_hp -= dmg
		core._track_player_damage(dmg, ECO_SOURCE)
		flashes.append({"kind": "eco_hit", "life": 0.3, "max": 0.3})
		core._add_text("-%d" % dmg, Vector2(core.player_pos) + Vector2(-12, -86), Color(1.0, 0.45, 0.35), 0.6, 16)


func pending_eco_hits() -> int:
	return eco_hits.size()
