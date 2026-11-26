class_name RTSkirmishItemsController
extends RefCounted

## Dono dos 10 itens incomuns do lote de 26/11 (estado local do jogador):
## Fe Emaculada, Tornozeleira de Chumbo, Disparo Vital, Ultimo Impulso,
## Sangue Coagulado, Pulso da Conversao, Bobina Catalisadora, Espinhos do
## Vaghnor, Veu Entropico e Botas de Veludo.
## O nucleo so chama ganchos de uma linha: abate, acerto em inimigo/chefe,
## dano sofrido, uso da HAB1, velocidade, critico, recarga da HAB1 e o alvo que
## os inimigos enxergam (Veu).
## Escalas continuas usam a contagem efetiva (cada queima de Cinzas soma meia
## copia); o que e discreto (usos do Pulso, cargas da Bobina, alvos dos
## Espinhos) usa copias inteiras.

const FE_ID := "fe_emaculada"
const TORNOZELEIRA_ID := "tornozeleira_chumbo"
const DISPARO_ID := "disparo_vital"
const IMPULSO_ID := "ultimo_impulso"
const SANGUE_ID := "sangue_coagulado"
const PULSO_ID := "pulso_conversao"
const BOBINA_ID := "bobina_catalisadora"
const ESPINHOS_ID := "espinhos_vaghnor"
const VEU_ID := "veu_entropico"
const BOTAS_ID := "botas_veludo"
const BLEED_SOURCE := "card_espinhos_bleed"
const BOBINA_SOURCE := "card_bobina_raio"

const FE_CHANCE := 0.18
const FE_CHANCE_PER_COPY := 0.10

const TORNOZELEIRA_SLOW := 0.4  ## multiplicador de velocidade (60% mais lento)
const TORNOZELEIRA_BOSS_SLOW := 0.3  ## chefe: 30% mais lento
const TORNOZELEIRA_TIME := 2.0

const DISPARO_CRIT := 0.05
const DISPARO_HEAL := 8.0
const DISPARO_HEAL_PER_COPY := 4.0

const IMPULSO_SPEED := 1.25
const IMPULSO_TIME := 1.0
const IMPULSO_TIME_PER_COPY := 0.5

const SANGUE_PER_KILL := 1
const SANGUE_CAP := 100

const PULSO_HEAL := 0.5
const PULSO_INTERVAL := 20.0
const PULSO_INTERVAL_STEP := 0.9
const PULSO_RADIUS := 360.0

const BOBINA_MAX := 5
const BOBINA_COST := 3
const BOBINA_DAMAGE := 1.75
const BOBINA_DAMAGE_PER_COPY := 0.5
const BOBINA_RANGE := 360.0
const BOBINA_BOLTS := 3
const BOBINA_Q_COOLDOWN := 0.8

const ESPINHOS_CHANCE := 0.10
const ESPINHOS_BLEED_TIME := 3.0
const ESPINHOS_BLEED_TICK := 0.5
const ESPINHOS_BLEED_DPS := 0.8  ## por acumulo, em multiplos do dano base
const ESPINHOS_BLEED_MAX := 10
const ESPINHOS_SHARE := 0.33
const ESPINHOS_RANGE := 250.0
const ESPINHOS_RANGE_PER_COPY := 60.0

const VEU_HP_RATIO := 0.25
const VEU_TIME := 5.0
const VEU_SPEED := 0.40
const VEU_COOLDOWN := 30.0

const BOTAS_SPEED := 0.30
const BOTAS_OUT_OF_COMBAT := 1.5

var core: Node = null
var bolts: Array = []
var flashes: Array = []
var impulso_timer := 0.0
var impulso_duration := 1.0
var sangue_gained := 0
var pulso_left := 0
var pulso_timer := 0.0
var pulso_in_fight := false
var bobina_charges := 0
var veu_timer := 0.0
var veu_cooldown := 0.0
var veu_decoy := Vector2.ZERO
var combat_quiet := 0.0
var bleed_tick := 0.0


func configure(runtime_core: Node) -> void:
	core = runtime_core


func reset() -> void:
	bolts.clear()
	flashes.clear()
	impulso_timer = 0.0
	sangue_gained = 0
	pulso_left = 0
	pulso_timer = 0.0
	pulso_in_fight = false
	bobina_charges = 0
	veu_timer = 0.0
	veu_cooldown = 0.0
	combat_quiet = 0.0
	bleed_tick = 0.0


func count(card_id: String) -> float:
	return float(core._new_common_card_count(card_id)) if core != null else 0.0


func copies(card_id: String) -> int:
	var n := count(card_id)
	return maxi(1, int(floor(n))) if n > 0.0 else 0


func _local_source(peer_id: int) -> bool:
	return peer_id == 0 or peer_id == int(core._mp_unique_id())


func update(delta: float) -> void:
	if core == null:
		return
	combat_quiet += delta
	impulso_timer = maxf(0.0, impulso_timer - delta)
	veu_timer = maxf(0.0, veu_timer - delta)
	if veu_timer <= 0.0:
		veu_cooldown = maxf(0.0, veu_cooldown - delta)
	_update_pulso(delta)
	_update_bleed(delta)
	for list in [bolts, flashes]:
		for i in range(list.size() - 1, -1, -1):
			list[i]["life"] = float(list[i]["life"]) - delta
			if float(list[i]["life"]) <= 0.0:
				list.remove_at(i)


# ================================================================ ganchos
## Crítico extra do Disparo Vital (somado em _critical_damage).
func crit_bonus() -> float:
	return DISPARO_CRIT if copies(DISPARO_ID) > 0 else 0.0


## Recarga da HAB1 com a Bobina Catalisadora (-20%).
func hab1_cooldown_multiplier() -> float:
	return BOBINA_Q_COOLDOWN if copies(BOBINA_ID) > 0 else 1.0


func movement_speed_bonus() -> float:
	var bonus := 0.0
	if impulso_timer > 0.0:
		bonus += IMPULSO_SPEED * impulso_timer / maxf(0.01, impulso_duration)
	if veu_timer > 0.0:
		bonus += VEU_SPEED
	if copies(BOTAS_ID) > 0 and combat_quiet >= BOTAS_OUT_OF_COMBAT:
		bonus += BOTAS_SPEED * count(BOTAS_ID)
	return bonus


func veiled() -> bool:
	return veu_timer > 0.0


## Onde os inimigos acham que ela esta: com o Veu, o ponto onde ela sumiu.
func target_pos(real: Vector2) -> Vector2:
	return veu_decoy if veiled() else real


## Transparencia da Geovana (Veu ativo = translucida).
func player_alpha() -> float:
	return 0.35 + 0.1 * sin(float(core.time_alive) * 9.0) if veiled() else 1.0


## Golpe de contato nao acerta quem esta sob o Veu.
func veil_blocks(source: String) -> bool:
	if not veiled():
		return false
	return source in [
		core.ENEMY_COMMON, core.ENEMY_STALKER, core.ENEMY_PROJECTOR, core.ENEMY_CRYSTAL, core.ENEMY_AGGLOMERATOR,
		core.ENEMY_CURATER, core.ENEMY_LARAPIO, core.ENEMY_COUT_ATTACK_SPEED, core.ENEMY_SHIELD_REFLECTOR,
		core.ENEMY_DEVOTO, core.ENEMY_INCENSARIO, core.ENEMY_GUARDIAO, core.ENEMY_PYRO_PENGUIN,
		core.ENEMY_NEXUS_CARTOGRAPHER, core.ENEMY_NEXUS_CHRONOPHAGE, core.ENEMY_NEXUS_REFRACTOR,
		core.ENEMY_NEXUS_WEAVER, core.ENEMY_NEXUS_ECHO,
	]


func on_skill_used(skill_type: String) -> void:
	if skill_type != "skill_q" or copies(BOBINA_ID) <= 0:
		return
	bobina_charges = mini(BOBINA_MAX + copies(BOBINA_ID) - 1, bobina_charges + 1)


func on_player_damaged(_amount: float) -> void:
	combat_quiet = 0.0
	if copies(VEU_ID) <= 0 or veu_timer > 0.0 or veu_cooldown > 0.0:
		return
	if float(core.player_hp) <= 0.0 or float(core.player_hp) >= float(core.player_hp_max) * VEU_HP_RATIO:
		return
	veu_timer = VEU_TIME
	veu_cooldown = VEU_COOLDOWN * pow(0.5, maxf(0.0, count(VEU_ID) - 1.0))
	veu_decoy = core.player_pos
	flashes.append({"kind": "veu", "pos": core.player_pos, "life": 0.7, "max": 0.7})
	core._add_text("VÉU ENTRÓPICO", Vector2(core.player_pos) + Vector2(-70, -112), Color(0.7, 0.6, 1.0), 0.9, 18)


func on_enemy_hit(enemy: Dictionary, damage: float, critical: bool, source: String, category: String, peer_id: int) -> void:
	if damage <= 0.0 or not _local_source(peer_id) or not core._card_damage_can_trigger(source):
		return
	combat_quiet = 0.0
	if copies(TORNOZELEIRA_ID) > 0:
		enemy["evolution_slow"] = maxf(float(enemy.get("evolution_slow", 0.0)), TORNOZELEIRA_TIME * count(TORNOZELEIRA_ID))
		enemy["evolution_slow_mult"] = minf(float(enemy.get("evolution_slow_mult", 1.0)), TORNOZELEIRA_SLOW)
	if critical:
		_crit_heal()
	if copies(ESPINHOS_ID) > 0 and core.rng.randf() < ESPINHOS_CHANCE * count(ESPINHOS_ID):
		enemy["item_bleed"] = mini(ESPINHOS_BLEED_MAX, int(enemy.get("item_bleed", 0)) + 1)
		enemy["item_bleed_timer"] = ESPINHOS_BLEED_TIME
	if category == "basic_attack":
		_try_bobina(Vector2(enemy.get("pos", core.player_pos)), enemy)


func on_boss_hit(damage: float, critical: bool, source: String, category: String, peer_id: int) -> void:
	if damage <= 0.0 or not _local_source(peer_id) or not core._card_damage_can_trigger(source):
		return
	combat_quiet = 0.0
	if copies(TORNOZELEIRA_ID) > 0:
		core.boss_ferrolho_slow_timer = maxf(float(core.boss_ferrolho_slow_timer), TORNOZELEIRA_TIME * count(TORNOZELEIRA_ID))
		core.boss_ferrolho_slow_ratio = maxf(float(core.boss_ferrolho_slow_ratio), TORNOZELEIRA_BOSS_SLOW)
	if critical:
		_crit_heal()
	if category == "basic_attack":
		_try_bobina(Vector2(core.boss_pos), {})


func on_enemy_killed(enemy: Dictionary) -> void:
	var killer := int(enemy.get("killed_by_peer_id", core._mp_unique_id()))
	if killer != int(core._mp_unique_id()):
		return
	var at := Vector2(enemy.get("pos", core.player_pos))
	if copies(FE_ID) > 0 and core.rng.randf() < FE_CHANCE + FE_CHANCE_PER_COPY * (count(FE_ID) - 1.0):
		_reset_cooldowns()
		flashes.append({"kind": "fe", "pos": core.player_pos, "life": 0.6, "max": 0.6})
	if copies(IMPULSO_ID) > 0:
		impulso_duration = IMPULSO_TIME + IMPULSO_TIME_PER_COPY * (count(IMPULSO_ID) - 1.0)
		impulso_timer = impulso_duration
	var sangue := copies(SANGUE_ID)
	if sangue > 0:
		var gain: int = mini(SANGUE_PER_KILL * sangue, int(floor(float(SANGUE_CAP) * count(SANGUE_ID))) - sangue_gained)
		if gain > 0:
			sangue_gained += gain
			core.player_hp_max += gain
			core.player_hp = mini(int(core.player_hp_max), int(core.player_hp) + gain)
	if copies(ESPINHOS_ID) > 0:
		_spread_debuffs(enemy, at)


# ================================================================ efeitos
func _crit_heal() -> void:
	var n := copies(DISPARO_ID)
	if n <= 0:
		return
	var heal: float = DISPARO_HEAL + DISPARO_HEAL_PER_COPY * (count(DISPARO_ID) - 1.0)
	core._heal_player(heal, "card_disparo_vital", true)


func _try_bobina(at: Vector2, hit_enemy: Dictionary) -> void:
	var n := copies(BOBINA_ID)
	if n <= 0 or bobina_charges < BOBINA_COST:
		return
	bobina_charges -= BOBINA_COST
	var damage: float = float(core.player_damage) * (BOBINA_DAMAGE + BOBINA_DAMAGE_PER_COPY * (count(BOBINA_ID) - 1.0))
	var targets: Array = []
	for enemy in core.enemies:
		if enemy == hit_enemy or float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var d := Vector2(enemy.get("pos", at)).distance_to(at)
		if d <= BOBINA_RANGE:
			targets.append([d, enemy])
	targets.sort_custom(func(a, b): return a[0] < b[0])
	var origin := Vector2(core.player_pos)
	var hits := 0
	for pair in targets:
		if hits >= BOBINA_BOLTS:
			break
		var enemy: Dictionary = pair[1]
		bolts.append({"from": origin, "to": Vector2(enemy["pos"]), "life": 0.28, "max": 0.28, "seed": core.rng.randi()})
		core._damage_enemy(enemy, damage, BOBINA_SOURCE, true, true, origin, "card_proc")
		hits += 1
	if not hit_enemy.is_empty() and hits < BOBINA_BOLTS:
		bolts.append({"from": origin, "to": at, "life": 0.28, "max": 0.28, "seed": core.rng.randi()})
		core._damage_enemy(hit_enemy, damage, BOBINA_SOURCE, true, true, origin, "card_proc")
	elif hit_enemy.is_empty() and core.boss_active:
		bolts.append({"from": origin, "to": at, "life": 0.28, "max": 0.28, "seed": core.rng.randi()})
		core._damage_boss(damage, BOBINA_SOURCE, true, true, "card_proc")


## Fe Emaculada: HAB1, ULT e teleporte prontos na hora do abate.
func _reset_cooldowns() -> void:
	var now := float(core.time_alive)
	core.last_skill_time = now - float(core._skill_cooldown()) - 0.01
	core.last_secondary_time = now - float(core._secondary_skill_cooldown()) - 0.01
	core.last_dash_time = now - float(core._current_dash_cooldown()) - 0.01
	core.tp_cooldown_pending = false
	core.tp_cooldown_override = -1.0
	if String(core.manifestation_key) == "lacerante":
		core.lacerante_tp_charges = core.LACERANTE_TP_MAX_CHARGES
	core._add_text("RECARGAS ZERADAS", Vector2(core.player_pos) + Vector2(-82, -112), Color(1.0, 0.92, 0.6), 0.9, 18)


func pulso_interval() -> float:
	return PULSO_INTERVAL * pow(PULSO_INTERVAL_STEP, maxf(0.0, count(PULSO_ID) - 1.0))


## Luta de chefe: uma nova de cura por luta (+1 por copia), uma a cada 20 s.
func _update_pulso(delta: float) -> void:
	var n := copies(PULSO_ID)
	var fighting: bool = n > 0 and bool(core.boss_active) and float(core.boss_hp) > 0.0
	if not fighting:
		pulso_in_fight = false
		return
	if not pulso_in_fight:
		pulso_in_fight = true
		pulso_left = n
		pulso_timer = 0.0
	if pulso_left <= 0:
		return
	pulso_timer += delta
	if pulso_timer >= pulso_interval():
		pulso_timer = 0.0
		pulso_left -= 1
		core._heal_player(float(core.player_hp_max) * PULSO_HEAL, "card_pulso_conversao", true)
		flashes.append({"kind": "pulso", "pos": core.player_pos, "life": 0.9, "max": 0.9})
		core._add_text("PULSO DA CONVERSÃO", Vector2(core.player_pos) + Vector2(-90, -112), Color(0.5, 1.0, 0.7), 0.9, 18)


## Sangramento dos Espinhos: dano por tempo em todos os inimigos marcados.
func _update_bleed(delta: float) -> void:
	bleed_tick -= delta
	if bleed_tick > 0.0:
		return
	bleed_tick = ESPINHOS_BLEED_TICK
	var per_stack: float = float(core.player_damage) * ESPINHOS_BLEED_DPS * ESPINHOS_BLEED_TICK
	for enemy in core.enemies.duplicate():
		var stacks := int(enemy.get("item_bleed", 0))
		if stacks <= 0:
			continue
		enemy["item_bleed_timer"] = float(enemy.get("item_bleed_timer", 0.0)) - ESPINHOS_BLEED_TICK
		if float(enemy["item_bleed_timer"]) <= 0.0:
			enemy["item_bleed"] = 0
		if core._is_world_authority():
			core._damage_enemy(enemy, per_stack * float(stacks), BLEED_SOURCE, false, false, Vector2(enemy.get("pos", core.player_pos)), "card_proc")


## Ao matar, 33% de cada debuff vai para os inimigos mais perto.
func _spread_debuffs(dead: Dictionary, at: Vector2) -> void:
	var n := copies(ESPINHOS_ID)
	var debuffs := {
		"item_bleed": int(dead.get("item_bleed", 0)),
		"laceracao": int(dead.get("laceracao", 0)) if float(dead.get("bleed_timer", 0.0)) > 0.0 else 0,
		"poison": float(dead.get("poison", 0.0)),
		"aura_burn": float(dead.get("aura_burn", 0.0)),
	}
	var any := false
	for v in debuffs.values():
		if float(v) > 0.0:
			any = true
	if not any:
		return
	var reach: float = ESPINHOS_RANGE + ESPINHOS_RANGE_PER_COPY * (count(ESPINHOS_ID) - 1.0)
	var near: Array = []
	for enemy in core.enemies:
		if enemy == dead or float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var d := Vector2(enemy.get("pos", at)).distance_to(at)
		if d <= reach:
			near.append([d, enemy])
	near.sort_custom(func(a, b): return a[0] < b[0])
	for k in range(mini(n, near.size())):
		var target: Dictionary = near[k][1]
		var bleed: int = int(ceil(float(debuffs["item_bleed"]) * ESPINHOS_SHARE))
		if bleed > 0:
			target["item_bleed"] = mini(ESPINHOS_BLEED_MAX, int(target.get("item_bleed", 0)) + bleed)
			target["item_bleed_timer"] = ESPINHOS_BLEED_TIME
		var lac: int = int(ceil(float(debuffs["laceracao"]) * ESPINHOS_SHARE))
		if lac > 0:
			target["laceracao"] = int(target.get("laceracao", 0)) + lac
			target["bleed_timer"] = maxf(float(target.get("bleed_timer", 0.0)), 3.0)
		if float(debuffs["poison"]) > 0.0:
			target["poison"] = maxf(float(target.get("poison", 0.0)), float(debuffs["poison"]) * ESPINHOS_SHARE)
		if float(debuffs["aura_burn"]) > 0.0:
			target["aura_burn"] = maxf(float(target.get("aura_burn", 0.0)), float(debuffs["aura_burn"]) * ESPINHOS_SHARE)
		bolts.append({"from": at, "to": Vector2(target["pos"]), "life": 0.35, "max": 0.35, "seed": 7, "kind": "espinhos"})
