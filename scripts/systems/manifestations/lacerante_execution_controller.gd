class_name RTLaceranteExecutionController
extends RefCounted

## Lacerante (rework 2026-11):
## - Laceracao: cada corte soma cargas no alvo (max. 5; o 3o corte soma 2) por 4 s.
##   Cada carga: +4% de dano dos cortes da Geovana e sangramento (5% do dano por carga
##   a cada 0,5 s, pelo pipeline normal de dano).
## - Barra de execucao: a barra de vida mostra quanto o ATK Reforcado tira. Vida dentro
##   da faixa = inimigo executavel.
## - Execucao: apertar Reforco (ou o ATK reforcado) com um executavel a ate 190 px inicia
##   uma execucao de 0,9 s: Geovana fica invulneravel, o alvo fica reservado (nenhum outro
##   dano conta) e morre no golpe final, gerando 1 Coagulo garantido e zerando a recarga
##   do Reforco. 5 variacoes de animacao (sprites do Codex quando existirem).

const MAX_STACKS := 5
const STACK_DURATION := 4.0
const STACK_DAMAGE_BONUS := 0.04
const BLEED_TICK := 0.5
const BLEED_RATIO_PER_STACK := 0.05
const EXECUTE_REACH := 190.0
const EXECUTION_TIME := 0.9
const FINISH_AT := 0.72
const FINISH_SPLASH_RADIUS := 110.0
const FINISH_SPLASH_RATIO := 0.6
const ANIMATIONS := 5
## Momentos dos cortes de cada animacao (s), so visual/feedback. Alinhados com os
## quadros de IMPACTO da folha (10 quadros de 0,09 s): t = quadro * 0,09 + 0,02.
const HIT_TIMES := [
	[0.2, 0.38, 0.74],                     # Cruz Carmesim: 2, 4, 8
	[0.11, 0.29, 0.47, 0.74],              # Espiral: 1, 3, 5, 8
	[0.2, 0.74],                           # Ascensao: 2, 8
	[0.11, 0.2, 0.29, 0.38, 0.47, 0.74],   # Rajada: 1-5, 8
	[0.47, 0.74],                          # Corte do Tempo: 5, 8
]
const NAMES := ["CRUZ CARMESIM", "ESPIRAL", "ASCENSAO", "RAJADA", "CORTE DO TEMPO"]
## Recarga do Reforco (comeca quando o golpe reforcado sai).
const REFORCO_COOLDOWN_EXECUTE := 10.0
const REFORCO_COOLDOWN_PLAIN := 15.0
## Cada ATK normal que acerta reduz a recarga em andamento.
const REFORCO_REFUND_PER_HIT := 0.3
## Piso: so com Intervalo Fraturado o Reforco pode voltar quase na hora.
## Sem a carta, velocidade de ataque nao derruba a recarga abaixo de 4 s.
const REFORCO_FLOOR := 4.0
const REFORCO_FLOOR_CARD_FULL := 0.3
## 3 execucoes em 6 s: as seguintes ficam rapidas (2x), sem foco de camera e sem
## imunidade extra, para nao irritar nem virar invulnerabilidade infinita.
const FAST_CHAIN_WINDOW := 6.0
const FAST_CHAIN_COUNT := 3
const FAST_SPEED := 2.0
## Imunidade depois da execucao (para nao ser punida ao sair do foco).
const POST_IMMUNITY := 0.9
## Duracao do foco de camera (execucao + volta ao normal).
const CINE_TOTAL := 1.15
const COAGULUM_FLY_TIME := 0.55

var core: Node
var active: Dictionary = {}
var last_animation := -1
var slash_events: Array = []
var post_immunity := 0.0
var reforco_ready_at := 0.0
var reforco_floor_at := 0.0
var reforco_total := REFORCO_COOLDOWN_EXECUTE
var exec_times: Array = []
var cine: Dictionary = {}
## Gotas de Coagulo voando do alvo ate o HUD (so visual).
var coagulum_fly: Array = []


func configure(owner: Node) -> void:
	core = owner


func reset() -> void:
	if not active.is_empty():
		_release_target()
	active = {}
	slash_events.clear()
	post_immunity = 0.0
	cine = {}
	reforco_ready_at = 0.0
	reforco_floor_at = 0.0
	reforco_total = REFORCO_COOLDOWN_EXECUTE
	exec_times.clear()
	coagulum_fly.clear()


func is_active() -> bool:
	return not active.is_empty()


## Execucao em curso ou janela de imunidade logo depois.
func is_protected() -> bool:
	return not active.is_empty() or post_immunity > 0.0


# --- recarga do Reforco -------------------------------------------------------------

func reforco_remaining() -> float:
	return maxf(0.0, reforco_ready_at - float(core.time_alive))


func reforco_elapsed() -> float:
	return reforco_total - reforco_remaining()


func reforco_floor_seconds() -> float:
	var reduction: float = float(core._intervalo_hab1_reduction())
	return REFORCO_FLOOR * maxf(0.0, 1.0 - reduction / REFORCO_FLOOR_CARD_FULL)


func start_reforco_cooldown(executed: bool) -> void:
	var now: float = float(core.time_alive)
	reforco_total = REFORCO_COOLDOWN_EXECUTE if executed else REFORCO_COOLDOWN_PLAIN
	reforco_ready_at = now + reforco_total
	reforco_floor_at = now + reforco_floor_seconds()
	core.last_lacerante_empower_time = now


## ATK normal que acertou alguem: adianta a recarga (nunca abaixo do piso).
func on_attack_hit() -> void:
	if reforco_ready_at <= float(core.time_alive):
		return
	reforco_ready_at = maxf(reforco_floor_at, reforco_ready_at - REFORCO_REFUND_PER_HIT)


func on_coagulum(at: Vector2) -> void:
	# Durante o foco de camera o HUD some; a gota sai quando a camera volta.
	var wait: float = maxf(0.0, CINE_TOTAL - float(cine.get("t", CINE_TOTAL))) if not cine.is_empty() else 0.0
	coagulum_fly.append({"from": at, "t": -wait})
	if coagulum_fly.size() > 6:
		coagulum_fly.pop_front()


func _enabled() -> bool:
	return core != null and String(core.manifestation_key) == "lacerante" and String(core.active_character_key) != String(core.CHARACTER_HENRY)


# --- laceracao ---------------------------------------------------------------------

func stacks(enemy: Dictionary) -> int:
	return clampi(int(enemy.get("laceracao", 0)), 0, MAX_STACKS) if float(enemy.get("bleed_timer", 0.0)) > 0.0 else 0


func damage_bonus(enemy: Dictionary) -> float:
	return 1.0 + STACK_DAMAGE_BONUS * float(stacks(enemy))


func apply_laceration(enemy: Dictionary, amount: int) -> void:
	enemy["laceracao"] = mini(MAX_STACKS, stacks(enemy) + amount)
	enemy["bleed_timer"] = STACK_DURATION


func update_bleed(enemy: Dictionary, delta: float) -> void:
	if int(enemy.get("laceracao", 0)) <= 0:
		return
	enemy["bleed_timer"] = maxf(0.0, float(enemy.get("bleed_timer", 0.0)) - delta)
	if float(enemy["bleed_timer"]) <= 0.0:
		enemy["laceracao"] = 0
		enemy["bleed_tick"] = 0.0
		return
	enemy["bleed_tick"] = float(enemy.get("bleed_tick", BLEED_TICK)) - delta
	if float(enemy["bleed_tick"]) > 0.0:
		return
	enemy["bleed_tick"] = BLEED_TICK
	var amount: float = float(core.player_damage) * BLEED_RATIO_PER_STACK * float(stacks(enemy))
	if amount > 0.0:
		core._damage_enemy(enemy, amount, "lacerante_bleed", false, false, Vector2(enemy.get("pos", core.player_pos)), "manifestation_secondary")


# --- barra de execucao ---------------------------------------------------------------

## Dano que o ATK Reforcado causaria agora neste inimigo (o que a barra mostra).
func threshold(enemy: Dictionary) -> float:
	var base: float = float(core.player_damage) * 1.12 * float(core._lacerante_coagulum_damage_multiplier()) * float(core.LACERANTE_EMPOWER_DAMAGE_MULT)
	return float(core._lacerante_damage_for_enemy(base, enemy)) * damage_bonus(enemy)


func can_be_executed(enemy: Dictionary) -> bool:
	if float(enemy.get("hp", 0.0)) <= 0.0 or bool(enemy.get("lacerante_exec", false)):
		return false
	var kind: String = String(enemy.get("type", ""))
	if kind == "boss" or kind == String(core.ENEMY_COUT_ATTACK_SPEED):
		return false
	return float(enemy.get("hp", 0.0)) <= threshold(enemy)


func bar_overlay(enemy: Dictionary) -> Dictionary:
	if not _enabled():
		return {}
	var max_hp: float = maxf(1.0, float(enemy.get("max_hp", 1.0)))
	return {"ratio": clampf(threshold(enemy) / max_hp, 0.0, 1.0), "executable": can_be_executed(enemy), "reserved": bool(enemy.get("lacerante_exec", false)), "stacks": stacks(enemy)}


# --- execucao --------------------------------------------------------------------

func find_target(aim: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_score := INF
	var origin: Vector2 = core.player_pos
	for enemy in core.enemies:
		if not can_be_executed(enemy):
			continue
		var offset: Vector2 = Vector2(enemy["pos"]) - origin
		var dist: float = offset.length()
		if dist > EXECUTE_REACH:
			continue
		var facing: float = 0.0 if aim.length() < 0.05 or dist < 1.0 else (1.0 - aim.normalized().dot(offset / dist)) * 60.0
		var score: float = dist + facing
		if score < best_score:
			best_score = score
			best = enemy
	return best


func try_start(aim: Vector2 = Vector2.ZERO) -> bool:
	if not _enabled() or is_active() or not core._is_world_authority():
		return false
	var target: Dictionary = find_target(aim)
	if target.is_empty():
		return false
	_start(target)
	return true


## Golpe reforcado: executa so se o corte acerta um inimigo executavel.
func try_start_on_slash(points: Array, width: float) -> bool:
	if not _enabled() or is_active() or not core._is_world_authority():
		return false
	var best: Dictionary = {}
	var best_dist := INF
	for enemy in core.enemies:
		if not can_be_executed(enemy):
			continue
		if float(core._distance_to_polyline(enemy["pos"], points)) > width:
			continue
		var d: float = core.player_pos.distance_to(Vector2(enemy["pos"]))
		if d < best_dist:
			best_dist = d
			best = enemy
	if best.is_empty():
		return false
	_start(best)
	return true


func _start(enemy: Dictionary) -> void:
	var now: float = float(core.time_alive)
	exec_times = exec_times.filter(func(x): return now - float(x) <= FAST_CHAIN_WINDOW)
	var fast: bool = exec_times.size() >= FAST_CHAIN_COUNT - 1
	exec_times.append(now)
	var anim: int = int(core.rng.randi_range(0, ANIMATIONS - 1))
	if anim == last_animation:
		anim = (anim + 1) % ANIMATIONS
	last_animation = anim
	var target_pos: Vector2 = Vector2(enemy["pos"])
	var side: float = -1.0 if core.player_pos.x > target_pos.x else 1.0
	enemy["lacerante_exec"] = true
	enemy["stun"] = maxf(float(enemy.get("stun", 0.0)), EXECUTION_TIME + 0.2)
	active = {
		"uid": int(enemy.get("uid", -1)),
		"anim": anim,
		"t": 0.0,
		"target_pos": target_pos,
		"from": core.player_pos,
		"side": side,
		"hits": 0,
		"finished": false,
		"fast": fast,
	}
	# Geovana aparece colada no alvo para executar.
	if not fast:
		cine = {"t": 0.0, "target": target_pos}
	core.player_pos = core._clamp_player_world(target_pos - Vector2(side * 58.0, 0.0))
	core.last_facing = Vector2(side, 0.0)
	core._set_player_attack_visual_dir(Vector2(side, 0.0))
	core.lacerante_empowered_ready = false
	core._play_sfx("atk_lacerante_3", 0.02, 0.7, 0.8)
	core._add_text(NAMES[anim], target_pos + Vector2(0, -104), Color(1.0, 0.24, 0.32), 0.9, 20)


func update(delta: float) -> void:
	post_immunity = maxf(0.0, post_immunity - delta)
	if not cine.is_empty():
		cine["t"] = float(cine["t"]) + delta
		if float(cine["t"]) >= CINE_TOTAL:
			cine = {}
	for fly in coagulum_fly:
		fly["t"] = float(fly["t"]) + delta
		if float(fly["t"]) >= COAGULUM_FLY_TIME:
			core.lacerante_coagulum_pulse = 1.0
	coagulum_fly = coagulum_fly.filter(func(f): return float(f["t"]) < COAGULUM_FLY_TIME)
	for ev in slash_events:
		ev["life"] = float(ev["life"]) - delta
	slash_events = slash_events.filter(func(e): return float(e["life"]) > 0.0)
	if active.is_empty():
		return
	var enemy = core._enemy_by_uid(int(active["uid"]))
	active["t"] = float(active["t"]) + delta * (FAST_SPEED if bool(active.get("fast", false)) else 1.0)
	var t: float = float(active["t"])
	if enemy == null and not bool(active["finished"]):
		active = {}
		return
	if enemy != null and not bool(active["finished"]):
		enemy["pos"] = active["target_pos"]
		enemy["stun"] = maxf(float(enemy.get("stun", 0.0)), 0.2)
	var times: Array = HIT_TIMES[int(active["anim"])]
	while int(active["hits"]) < times.size() and t >= float(times[int(active["hits"])]):
		var index: int = int(active["hits"])
		active["hits"] = index + 1
		var finisher: bool = index == times.size() - 1
		core.last_attack_time = core.time_alive
		core.lacerante_combo_visual = index % 3
		slash_events.append({"pos": active["target_pos"], "anim": int(active["anim"]), "index": index, "finisher": finisher, "side": float(active["side"]), "life": 0.32 if finisher else 0.2, "max": 0.32 if finisher else 0.2})
		core.screen_shake_timer = maxf(float(core.screen_shake_timer), 0.16 if finisher else 0.06)
		core.screen_shake_strength = maxf(float(core.screen_shake_strength), 9.0 if finisher else 3.0)
		core._vibrate(70 if finisher else 25, 0.4 if finisher else 0.15)
		if finisher and enemy != null:
			_finish(enemy)
	if t >= EXECUTION_TIME:
		var was_fast: bool = bool(active.get("fast", false))
		active = {}
		post_immunity = 0.0 if was_fast else POST_IMMUNITY


func _finish(enemy: Dictionary) -> void:
	active["finished"] = true
	var pos: Vector2 = Vector2(enemy["pos"])
	enemy.erase("lacerante_exec")
	var lethal: float = float(enemy.get("hp", 0.0)) + 1.0
	var killed: bool = core._damage_enemy(enemy, lethal, "lacerante_execution", true, false, core.player_pos, "basic_attack")
	if not killed and float(enemy.get("hp", 0.0)) > 0.0 and core.enemies.has(enemy):
		# Execucao e garantida: defesas/imunidades nao salvam o alvo reservado.
		enemy["hp"] = 0.0
		killed = true
	if killed and core.enemies.has(enemy):
		core._kill_enemy(enemy)
	core._add_text("EXECUTADO", pos + Vector2(0, -78), Color(1.0, 0.16, 0.24), 0.9, 22)
	core._grant_lacerante_coagulum(pos)
	core.LaceranteVfx.on_lacerate_applied(core, pos)
	for other in core.enemies:
		if other == enemy or float(other.get("hp", 0.0)) <= 0.0:
			continue
		if pos.distance_to(Vector2(other["pos"])) <= FINISH_SPLASH_RADIUS:
			apply_laceration(other, 1)
			core._damage_enemy(other, float(core.player_damage) * FINISH_SPLASH_RATIO, "lacerante", false, true, pos, "basic_attack")


func _release_target() -> void:
	var enemy = core._enemy_by_uid(int(active.get("uid", -1))) if core != null else null
	if enemy != null:
		enemy.erase("lacerante_exec")


## Reserva: enquanto a execucao corre, so o golpe final causa dano no alvo.
static func blocks_damage(enemy: Dictionary, source: String) -> bool:
	return bool(enemy.get("lacerante_exec", false)) and source != "lacerante_execution"
