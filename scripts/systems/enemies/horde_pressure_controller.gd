class_name RTHordePressureController
extends RefCounted

## Pressao infinita da horda (roguelike): a quantidade DESEJADA de inimigos cresce sem fim com o
## tempo de run, mas a quantidade VIVA nunca passa do orcamento que o aparelho aguenta. O
## orcamento e aprendido em tempo real pelo FPS (cresce enquanto sobra folga, encolhe quando cai).
## O que passa do orcamento vira "enxame condensado": cada inimigo nasce mais forte e vale mais
## pontos, entao a dificuldade continua subindo sem custar quadros.

# Crescimento desejado (inimigos extras sobre o limite da fase), por minuto de run.
const GROWTH_DELAY_MINUTES := 3.0
const GROWTH_LINEAR := 0.9
const GROWTH_QUADRATIC := 0.011
## Fases com inimigos mais caros/complexos crescem mais devagar (nexo da fase 4, lacaios da fase 5).
const PHASE_GROWTH_WEIGHT := {4: 0.5, 5: 0.6, 7: 0.85}

# Orcamento de inimigos vivos.
const BUDGET_START_DESKTOP := 90
const BUDGET_START_MOBILE := 48
const BUDGET_CAP_DESKTOP := 220
const BUDGET_CAP_MOBILE := 120
const BUDGET_MIN := 18
const PROBE_STEP := 4
const PROBE_HEALTHY_SECONDS := 4.0
const HEALTHY_FPS_RATIO := 0.95
const REDUCED_SHRINK := 0.85
const EMERGENCY_SHRINK := 0.65
const SHRINK_HOLD_SECONDS := 6.0

# Ritmo de spawn para sustentar hordas maiores sem picos num unico quadro.
const SPAWN_INTERVAL_FLOOR := 0.22
const MAX_SPAWNS_PER_TICK := 4

# Enxame condensado (excesso acima do orcamento).
const OVERFLOW_HP_WEIGHT := 0.55
const OVERFLOW_DAMAGE_WEIGHT := 0.3
const OVERFLOW_POINTS_WEIGHT := 1.0
const OVERFLOW_RATIO_CAP := 6.0

# LOD de IA: inimigos longe de todos os alvos atualizam em quadros alternados.
const AI_LOD_MIN_CROWD := 24
const AI_LOD_FAR_DISTANCE := 1100.0
## Com horda grande, o LOD alcanca tambem a borda da tela (movimento a 30 Hz quase nao se nota la).
const AI_LOD_CROWDED_COUNT := 80
const AI_LOD_CROWDED_DISTANCE := 760.0
## So culpa a horda pela queda de FPS quando ela pesa no quadro: se a IA + desenho dos inimigos
## custam pouco (GPU, vsync, outro sistema), o orcamento so para de crescer em vez de encolher.
const ENEMY_COST_SIGNIFICANT_SHARE := 0.25
const COST_SMOOTHING := 0.1
## Teto aprendido: depois de uma queda, a sondagem para abaixo do ponto onde caiu e so relaxa devagar.
const CEILING_RELAX_SECONDS := 20.0

var game: Node
var budget: int = BUDGET_START_DESKTOP
var healthy_seconds: float = 0.0
var shrink_hold: float = 0.0
var last_stage: int = 0
var frame_parity: int = 0
var ceiling: int = 1 << 20
var update_cost_us: float = 0.0
var draw_cost_us: float = 0.0
var ceiling_relax: float = 0.0


func configure(p_game: Node) -> void:
	game = p_game
	reset_run()


func reset_run() -> void:
	budget = start_budget()
	healthy_seconds = 0.0
	shrink_hold = 0.0
	last_stage = 0
	frame_parity = 0
	ceiling = 1 << 20
	ceiling_relax = 0.0
	update_cost_us = 0.0
	draw_cost_us = 0.0


func is_mobile() -> bool:
	if game == null or not game.has_method("_is_mobile_runtime"):
		return false
	return game._is_mobile_runtime() or bool(game.gfx_low_resource) or bool(game._memory_saver_active())


func start_budget() -> int:
	return BUDGET_START_MOBILE if is_mobile() else BUDGET_START_DESKTOP


func budget_cap() -> int:
	return BUDGET_CAP_MOBILE if is_mobile() else BUDGET_CAP_DESKTOP


## Inimigos extras desejados: cresce para sempre, devagar no comeco e acelerando.
static func growth_for_minutes(minutes: float) -> int:
	var m: float = maxf(0.0, minutes - GROWTH_DELAY_MINUTES)
	return int(floor(m * GROWTH_LINEAR + m * m * GROWTH_QUADRATIC))


func extra_enemies() -> int:
	if game == null or not ("time_alive" in game):
		return 0
	var weight: float = float(PHASE_GROWTH_WEIGHT.get(int(game.current_phase), 1.0)) if "current_phase" in game else 1.0
	return int(floor(float(growth_for_minutes(float(game.time_alive) / 60.0)) * weight))


func live_budget() -> int:
	return clampi(budget, BUDGET_MIN, budget_cap())


func clamp_limit(desired: int) -> int:
	return mini(desired, live_budget())


func overflow_ratio(desired: int) -> float:
	var live: int = maxi(1, clamp_limit(desired))
	return clampf(float(desired) / float(live), 1.0, OVERFLOW_RATIO_CAP)


## Ajusta o orcamento pelo FPS medido (chamado todo quadro pelo enemy_manager).
func update(delta: float) -> void:
	if game == null or not ("runtime_performance_controller" in game) or game.mode != "game":
		return
	frame_parity += 1
	var perf = game.runtime_performance_controller
	var stage: int = int(perf.stage)
	var live: int = game.enemies.size()
	shrink_hold = maxf(0.0, shrink_hold - delta)
	if stage > 0 and not enemies_are_costly():
		healthy_seconds = 0.0
	elif stage > 0 and (stage > last_stage or shrink_hold <= 0.0):
		var factor: float = EMERGENCY_SHRINK if stage >= 2 else REDUCED_SHRINK
		ceiling = maxi(BUDGET_MIN, mini(ceiling, live))
		budget = maxi(BUDGET_MIN, mini(budget, int(floor(float(maxi(live, BUDGET_MIN)) * factor))))
		shrink_hold = SHRINK_HOLD_SECONDS
		healthy_seconds = 0.0
	elif stage == 0:
		var target: float = float(perf.target_fps(game))
		var smoothed: float = float(perf.smoothed_fps)
		if smoothed <= 0.0 or smoothed >= target * HEALTHY_FPS_RATIO:
			healthy_seconds += delta
		else:
			healthy_seconds = 0.0
		# So sonda para cima quando a horda ja encosta no orcamento (folga comprovada sob carga).
		ceiling_relax += delta
		if ceiling_relax >= CEILING_RELAX_SECONDS:
			ceiling_relax = 0.0
			ceiling += PROBE_STEP
		var probe_limit: int = mini(budget_cap(), ceiling - 2)
		if healthy_seconds >= PROBE_HEALTHY_SECONDS and shrink_hold <= 0.0 and live >= budget - PROBE_STEP and budget < probe_limit:
			budget = mini(probe_limit, budget + PROBE_STEP)
			healthy_seconds = 0.0
	last_stage = stage


func note_update_cost(usec: int) -> void:
	update_cost_us = lerpf(update_cost_us, float(usec), COST_SMOOTHING)


func note_draw_cost(usec: int) -> void:
	draw_cost_us = lerpf(draw_cost_us, float(usec), COST_SMOOTHING)


func enemy_cost_ms() -> float:
	return (update_cost_us + draw_cost_us) / 1000.0


func enemies_are_costly() -> bool:
	var fps: float = float(game.runtime_performance_controller.smoothed_fps)
	if fps <= 0.0:
		fps = float(game.runtime_performance_controller.target_fps(game))
	return enemy_cost_ms() / (1000.0 / maxf(1.0, fps)) >= ENEMY_COST_SIGNIFICANT_SHARE


func spawn_interval(base_interval: float) -> float:
	var extra: float = float(extra_enemies())
	return maxf(SPAWN_INTERVAL_FLOOR, base_interval / (1.0 + extra / 40.0))


## Quantos inimigos nascer neste tick: repoe mais rapido quando a horda esta muito abaixo do limite.
func spawns_this_tick(limit: int, live: int) -> int:
	var missing: int = limit - live
	if missing <= 0:
		return 0
	var extra: int = extra_enemies()
	var batch: int = 1 + int(floor(float(extra) / 25.0))
	if float(live) < float(limit) * 0.6:
		batch += 1
	return clampi(batch, 1, mini(MAX_SPAWNS_PER_TICK, missing))


## Aplica o enxame condensado ao inimigo recem-nascido.
func apply_overflow(enemy: Dictionary, ratio: float) -> void:
	if ratio <= 1.001:
		return
	var over: float = ratio - 1.0
	var hp_mult: float = 1.0 + over * OVERFLOW_HP_WEIGHT
	enemy["max_hp"] = float(enemy.get("max_hp", 1.0)) * hp_mult
	enemy["hp"] = float(enemy.get("hp", 1.0)) * hp_mult
	if enemy.has("damage"):
		enemy["damage"] = float(enemy.get("damage", 10.0)) * (1.0 + over * OVERFLOW_DAMAGE_WEIGHT)
	enemy["horde_points"] = 1.0 + over * OVERFLOW_POINTS_WEIGHT
	enemy["horde_condensed"] = ratio


## LOD de IA: true quando este inimigo pode pular a atualizacao deste quadro.
func ai_lod_skip(enemy: Dictionary, index: int, target_positions: Array) -> bool:
	if target_positions.is_empty():
		return false
	if (index + frame_parity) % 2 == 0:
		return false
	var pos: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO))
	var far: float = AI_LOD_CROWDED_DISTANCE if game.enemies.size() >= AI_LOD_CROWDED_COUNT else AI_LOD_FAR_DISTANCE
	var far_sq: float = far * far
	for target_pos in target_positions:
		if pos.distance_squared_to(target_pos) < far_sq:
			return false
	return true
