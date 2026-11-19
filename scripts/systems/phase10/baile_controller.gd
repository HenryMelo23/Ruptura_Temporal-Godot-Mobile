class_name RTBaileController
extends RefCounted

## Dimensao 10 — BAILAO DA DONA BOLETA (eletrofunk). Faz parte do ciclo de farm.
## Ficha: docs/phases/10_bailao_dona_boleta.md
##
## Regra central — A BATIDA: RTBaileBeatClock dita o combate. As borboletas andam
## em impulsos de passinho na sincope do tamborzao, CONGELAM na batida 15 de cada
## 16 (aviso) e ARRANCAM na 16 (drop). Arremessos e ondas saem sempre na batida.
## Ninguem para de dancar para lutar.
##
## TEOR: cada garrafa que acerta a Geovana soma Teor (0-100). Efeitos sao SO
## visuais (balanco, visao dupla, ilusoes, apagao); avisos de ataque nunca sao
## distorcidos e o controle nunca e invertido.
##
## Elenco (1 + 4 + miniboss + boss):
## - Monarca do Passinho (comum): persegue no passinho; arranca no drop.
## - Garrafeira: guarda distancia e arremessa garrafa "no 4" (marcador no chao).
## - Sombrinha: guarda-chuva bloqueia tiros de frente; no drop devolve um.
## - Paredinha: se planta e solta aneis de grave que empurram.
## - Hype: aura de Embalo (aliados mais rapidos, Garrafeiras 2x); ao morrer,
##   quem estava no embalo fica atordoado um compasso.
## - Miniboss: Lagartona do Paredao (RTBaileLagartona).
## - Boss: Dona Boleta (RTBoss10Controller), no palco desde o inicio.
##
## Multiplayer: a AUTORIDADE roda IA, garrafas, aneis e Teor de todos os
## jogadores. A REPLICA recebe visual_snapshot() e so anima; empurroes de anel,
## colisao do palco e limites da Roda sao aplicados localmente por cada jogador.

const PHASE := 10
const MONARCA := "borboleta_monarca"
const GARRAFEIRA := "borboleta_garrafeira"
const SOMBRINHA := "borboleta_sombrinha"
const PAREDINHA := "borboleta_paredinha"
const HYPE := "borboleta_hype"
const LAGARTONA := "lagartona_paredao"
const KINDS := [MONARCA, GARRAFEIRA, SOMBRINHA, PAREDINHA, HYPE, LAGARTONA]
const SPECIALS := [GARRAFEIRA, SOMBRINHA, PAREDINHA, HYPE]
const BOTTLE_KINDS := ["whisky", "gin", "vodka"]

# Liberacao dos especiais (s de fase), teto simultaneo e intervalo minimo.
const UNLOCK := {GARRAFEIRA: 35.0, SOMBRINHA: 70.0, PAREDINHA: 110.0, HYPE: 150.0}
const CAP := {GARRAFEIRA: 4, SOMBRINHA: 3, PAREDINHA: 2, HYPE: 2}
const MIN_GAP := {GARRAFEIRA: 9.0, SOMBRINHA: 14.0, PAREDINHA: 18.0, HYPE: 20.0}
const WEIGHT := {GARRAFEIRA: 0.16, SOMBRINHA: 0.11, PAREDINHA: 0.08, HYPE: 0.07}
# Populacao
const ENEMY_LIMIT_BASE := 9
const SPAWN_INTERVAL := 1.35
const SPAWN_INTERVAL_EARLY := 1.8
# Monarca
const MONARCA_SPEED := 118.0
const SWAY_STRENGTH := 0.32
# Garrafeira
const GARRAFEIRA_NEAR := 240.0
const GARRAFEIRA_FAR := 380.0
const BOTTLE_FLIGHT_BEATS := 2.0
const BOTTLE_RADIUS := 46.0
const BOTTLE_ARC := 120.0
const BOTTLE_PROFILE := {
	"whisky": {"dmg": 0.05, "teor": 14.0},
	"gin": {"dmg": 0.03, "teor": 8.0},
	"vodka": {"dmg": 0.025, "teor": 24.0},
}
const GIN_PUDDLE_RADIUS := 70.0
const GIN_PUDDLE_LIFE := 5.0
const GIN_SLOW := 0.75
const GIN_SLOW_TIME := 0.35
# Sombrinha
const SOMBRINHA_TURN := 1.4
const SOMBRINHA_BLOCK_HALF := deg_to_rad(50.0)
const SOMBRINHA_BLOCK_MULT := 0.15
const SOMBRINHA_SHOT_SPEED := 340.0
const SOMBRINHA_SHOT_DAMAGE := 0.04
# Paredinha
const PAREDINHA_PLANT_DIST := 300.0
const PAREDINHA_PLANT_BARS := 8
const RING_MAX := 220.0
const RING_BEATS := 2.0
const RING_BAND := 16.0
const RING_PUSH := 140.0
const RING_DAMAGE := 0.02
# Hype
const HYPE_RADIUS := 200.0
const HYPE_FLEE := 420.0
const HYPE_SPEED_MULT := 1.2
# Teor
const TEOR_MAX := 100.0
const TEOR_DECAY := 6.0
const TEOR_DECAY_DELAY := 2.0
const TEOR_BLACKOUT_RESET := 60.0
const BLACKOUT_TIME := 1.0
# Palco (o altar e o proprio palco; o microfone fica no ponto do altar)
const STAGE_SIZE := Vector2(480.0, 200.0)
const STAGE_BACK := 250.0          # do microfone ate o fundo do palco
const SINGER_OFFSET := Vector2(0.0, -175.0)
const FIGHT_OFFSET := Vector2(0.0, 230.0)
# Miniboss
const LAGARTONA_SPAWN_TIME := 200.0
const LAGARTONA_REWARD_CORES := 2

var core: Node
var beat: RTBaileBeatClock = RTBaileBeatClock.new()
var lagartona: RTBaileLagartona = RTBaileLagartona.new()
var bottles: Array = []        # {from, to, t, dur, kind, owner}
var puddles: Array = []        # {pos, r, life, t}
var rings: Array = []          # {pos, t, life, hit:{peer:true}}
var shots: Array = []          # {p, v, life, r, dmg}
var teor_by_peer: Dictionary = {}     # peer -> Teor (autoridade)
var teor_idle_by_peer: Dictionary = {}
var teor := 0.0                # Teor do jogador desta maquina (apresentacao)
var blackout := 0.0
var player_slow := 0.0
var miniboss_spawned := false
var miniboss_defeated := false
var stage_hit_cd := 0.0
var _last_spawn_time: Dictionary = {}
var _remote_enemy_visual_by_uid: Dictionary = {}


func configure(p_core: Node) -> void:
	core = p_core
	lagartona.configure(self, p_core)


func active() -> bool:
	return core != null and int(core.current_phase) == PHASE


func owns_kind(kind: String) -> bool:
	return KINDS.has(kind)


func reset() -> void:
	beat.reset()
	lagartona.reset()
	bottles.clear()
	puddles.clear()
	rings.clear()
	shots.clear()
	teor_by_peer.clear()
	teor_idle_by_peer.clear()
	teor = 0.0
	blackout = 0.0
	player_slow = 0.0
	miniboss_spawned = false
	miniboss_defeated = false
	stage_hit_cd = 0.0
	_last_spawn_time.clear()
	_remote_enemy_visual_by_uid.clear()


# ================================================================ palco
func mic_pos() -> Vector2:
	return Vector2(core.experimental_boss_altar_pos)


func stage_rect() -> Rect2:
	var m := mic_pos()
	return Rect2(m + Vector2(-STAGE_SIZE.x * 0.5, -STAGE_BACK), STAGE_SIZE)


func singer_pos() -> Vector2:
	return mic_pos() + SINGER_OFFSET


func fight_anchor() -> Vector2:
	return mic_pos() + FIGHT_OFFSET


## Empurra um ponto (pes) para fora do palco pelo menor eixo.
func push_out_of_stage(p: Vector2, radius: float) -> Vector2:
	var r: Rect2 = stage_rect().grow(radius)
	if not r.has_point(p):
		return p
	var left: float = p.x - r.position.x
	var right: float = r.end.x - p.x
	var top: float = p.y - r.position.y
	var bottom: float = r.end.y - p.y
	var best: float = minf(minf(left, right), minf(top, bottom))
	if best == left:
		return Vector2(r.position.x, p.y)
	if best == right:
		return Vector2(r.end.x, p.y)
	if best == top:
		return Vector2(p.x, r.position.y)
	return Vector2(p.x, r.end.y)


func _push_player_out_of_stage() -> void:
	var feet: Vector2 = core.player_pos + Vector2(0, 26)
	var pushed: Vector2 = push_out_of_stage(feet, 14.0)
	if pushed != feet:
		core.player_pos += pushed - feet


func _push_enemies_out_of_stage() -> void:
	for e in core.enemies:
		if not owns_kind(String(e.get("type", ""))):
			continue
		e["pos"] = push_out_of_stage(Vector2(e["pos"]), 22.0)


## O palco absorve tiros (ela nao para o show para levar hit).
func bullet_hit(pos: Vector2) -> bool:
	if not stage_rect().has_point(pos):
		return false
	if stage_hit_cd <= 0.0 and not core.boss_active:
		stage_hit_cd = 6.0
		core._add_text("NAO ATRAPALHA O SHOW!", singer_pos() + Vector2(0, -150), Color(1.0, 0.45, 0.8), 1.2, 20)
	return true


# ================================================================ alvos
func viewers() -> Array:
	var out: Array = []
	for t in core._combat_targets():
		out.append({
			"peer_id": int(t.get("peer_id", 0)), "pos": Vector2(t.get("pos", core.player_pos)),
			"local": bool(t.get("local", false)), "hp_max": float(t.get("hp_max", core.player_hp_max)),
		})
	if out.is_empty():
		out.append({"peer_id": core._mp_unique_id(), "pos": core.player_pos, "local": true, "hp_max": float(core.player_hp_max)})
	return out


func _viewers_in_circle(center: Vector2, radius: float) -> Array:
	var out: Array = []
	for v in viewers():
		if RTUmbraHitbox.body_hits_circle(Vector2(v["pos"]), center, radius):
			out.append(v)
	return out


func _target_entry(enemy: Dictionary) -> Dictionary:
	var want: int = int(enemy.get("target_peer_id", 0))
	var vs: Array = viewers()
	for v in vs:
		if int(v["peer_id"]) == want:
			return v
	return vs[0]


func _is_local_peer(peer_id: int) -> bool:
	return peer_id == 0 or peer_id == core._mp_unique_id() or not core.is_multiplayer


## Dano em fracao da vida maxima de um jogador (local ou remoto).
func hurt_peer(peer_id: int, frac: float, source: String) -> void:
	if _is_local_peer(peer_id):
		if core._player_invulnerable():
			return
		core._damage_player(maxi(1, int(round(float(core.player_hp_max) * frac))), source)
		return
	var hp_max: float = float(core.player_hp_max)
	for v in viewers():
		if int(v["peer_id"]) == peer_id:
			hp_max = float(v["hp_max"])
	core._send_peer_damage(peer_id, maxi(1, int(round(hp_max * frac))), source)


func add_teor(peer_id: int, amount: float) -> void:
	var key: int = core._mp_unique_id() if _is_local_peer(peer_id) else peer_id
	if _is_local_peer(peer_id) and core._player_invulnerable():
		return
	var v: float = float(teor_by_peer.get(key, 0.0)) + amount
	if v >= TEOR_MAX:
		v = TEOR_BLACKOUT_RESET
		if _is_local_peer(peer_id):
			blackout = BLACKOUT_TIME
			core._add_text("APAGOU...", core.player_pos + Vector2(0, -70), Color(1.0, 0.6, 0.9), 1.0, 20)
	teor_by_peer[key] = v
	teor_idle_by_peer[key] = 0.0


func _update_teor(delta: float) -> void:
	for key in teor_by_peer.keys():
		var idle: float = float(teor_idle_by_peer.get(key, 0.0)) + delta
		teor_idle_by_peer[key] = idle
		if idle > TEOR_DECAY_DELAY:
			teor_by_peer[key] = maxf(0.0, float(teor_by_peer[key]) - TEOR_DECAY * delta)
	teor = float(teor_by_peer.get(core._mp_unique_id(), 0.0))


# ================================================================ atualizacao
func update(delta: float) -> void:
	if not active():
		return
	beat.update(delta)
	stage_hit_cd = maxf(0.0, stage_hit_cd - delta)
	blackout = maxf(0.0, blackout - delta)
	player_slow = maxf(0.0, player_slow - delta)
	if beat.beat_event:
		_refresh_embalo()
	_update_bottles(delta)
	_update_puddles(delta)
	_update_rings(delta, true)
	_update_shots(delta)
	_update_teor(delta)
	_push_player_out_of_stage()
	_push_enemies_out_of_stage()
	_update_miniboss_schedule()


func enemy_limit() -> int:
	var elapsed: float = core._phase_elapsed_time()
	return ENEMY_LIMIT_BASE + (1 if elapsed > 180.0 else 0) + (1 if elapsed > 360.0 else 0)


func spawn_interval() -> float:
	return SPAWN_INTERVAL if core._phase_elapsed_time() > 30.0 else SPAWN_INTERVAL_EARLY


func choose_enemy_type() -> String:
	var elapsed: float = core._phase_elapsed_time()
	var roll: float = core.rng.randf()
	var acc := 0.0
	for kind in SPECIALS:
		acc += float(WEIGHT[kind])
		if roll >= acc:
			continue
		if special_available(kind, elapsed):
			_last_spawn_time[kind] = elapsed
			return kind
		break
	return MONARCA


## Liberado, abaixo do teto e respeitando o intervalo minimo desde o ultimo.
func special_available(kind: String, elapsed: float) -> bool:
	if elapsed < float(UNLOCK.get(kind, INF)):
		return false
	if core._enemy_type_count(kind) >= int(CAP.get(kind, 0)):
		return false
	return elapsed - float(_last_spawn_time.get(kind, -INF)) >= float(MIN_GAP.get(kind, 0.0))


func spawn_stats(kind: String, speed: float, damage: float) -> Dictionary:
	match kind:
		MONARCA:
			return {"hp_mult": 1.0, "speed": MONARCA_SPEED, "damage": damage * 0.8, "points": 70}
		GARRAFEIRA:
			return {"hp_mult": 1.1, "speed": 105.0, "damage": damage * 0.6, "points": 120}
		SOMBRINHA:
			return {"hp_mult": 1.6, "speed": 92.0, "damage": damage * 0.8, "points": 150}
		PAREDINHA:
			return {"hp_mult": 1.8, "speed": 96.0, "damage": damage * 0.7, "points": 150}
		HYPE:
			return {"hp_mult": 1.3, "speed": 150.0, "damage": damage * 0.5, "points": 180}
		LAGARTONA:
			return lagartona.spawn_stats(damage)
	return {"hp_mult": 1.0, "speed": speed, "damage": damage, "points": 60}


func on_spawned(enemy: Dictionary) -> void:
	var kind := String(enemy.get("type", ""))
	enemy["shoot_cd"] = 999.0
	enemy["parado"] = true
	enemy["facing_dir"] = Vector2.LEFT
	enemy["b10_state"] = "dance"
	enemy["b10_t"] = 0.0
	enemy["b10_anim"] = "idle"
	enemy["b10_offset"] = core.rng.randf_range(0.0, 0.5)
	enemy["b10_side"] = -1.0 if core.rng.randf() < 0.5 else 1.0
	enemy["b10_embalo"] = false
	match kind:
		GARRAFEIRA:
			enemy["b10_throw_parity"] = core.rng.randi_range(0, 1)
		SOMBRINHA:
			enemy["b10_guard"] = (core.player_pos - Vector2(enemy["pos"])).normalized()
			enemy["b10_blocked"] = 0
		PAREDINHA:
			enemy["b10_state"] = "walk"
			enemy["b10_bars"] = 0
		LAGARTONA:
			lagartona.on_spawned(enemy)


# ================================================================ inimigos
func update_enemy(enemy: Dictionary, delta: float) -> void:
	enemy["parado"] = true
	enemy["shoot_cd"] = 999.0
	if float(enemy.get("stun", 0.0)) > 0.0 or float(enemy.get("ferrolho_root", 0.0)) > 0.0:
		enemy["b10_anim"] = "drop"
		return
	enemy["b10_t"] = float(enemy.get("b10_t", 0.0)) + delta
	match String(enemy.get("type", "")):
		MONARCA:
			_update_monarca(enemy, delta)
		GARRAFEIRA:
			_update_garrafeira(enemy, delta)
		SOMBRINHA:
			_update_sombrinha(enemy, delta)
		PAREDINHA:
			_update_paredinha(enemy, delta)
		HYPE:
			_update_hype(enemy, delta)
		LAGARTONA:
			lagartona.update_enemy(enemy, delta)


func _info(enemy: Dictionary) -> Dictionary:
	var pos: Vector2 = enemy["pos"]
	var target: Vector2 = core._get_enemy_target_pos(enemy)
	var to: Vector2 = target - pos
	var dist: float = to.length()
	var dir: Vector2 = to / dist if dist > 0.01 else Vector2(enemy.get("facing_dir", Vector2.LEFT)).normalized()
	return {"pos": pos, "target": target, "dist": dist, "dir": dir}


## Passo de passinho: direcao + balanco lateral, velocidade no envelope da batida.
func dance_step(enemy: Dictionary, dir: Vector2, speed: float, delta: float, sway_k: float = SWAY_STRENGTH) -> void:
	var off: float = float(enemy.get("b10_offset", 0.0))
	var mult: float = beat.step_multiplier(off)
	if bool(enemy.get("b10_embalo", false)):
		mult *= HYPE_SPEED_MULT
	var lateral: Vector2 = dir.orthogonal() * float(enemy.get("b10_side", 1.0)) * beat.sway(off) * sway_k
	var step_dir: Vector2 = (dir + lateral).normalized()
	enemy["b10_anim"] = "drop" if beat.is_freeze() else ("attack" if beat.is_drop() else "idle")
	if mult <= 0.0:
		return
	core._phase7_apply_enemy_move(enemy, step_dir, speed * mult, delta)
	enemy["facing_dir"] = dir


func _update_monarca(enemy: Dictionary, delta: float) -> void:
	var info := _info(enemy)
	dance_step(enemy, info["dir"], float(enemy.get("speed", MONARCA_SPEED)), delta)


func _update_garrafeira(enemy: Dictionary, delta: float) -> void:
	var info := _info(enemy)
	var dist: float = info["dist"]
	var dir: Vector2 = info["dir"]
	var move: Vector2 = dir if dist > GARRAFEIRA_FAR else (-dir if dist < GARRAFEIRA_NEAR else dir.orthogonal() * float(enemy.get("b10_side", 1.0)))
	dance_step(enemy, move, float(enemy.get("speed", 105.0)) * 0.7, delta, 0.15)
	enemy["facing_dir"] = dir
	var throws_this_bar: bool = bool(enemy.get("b10_embalo", false)) or posmod(floori(beat.beat_index / float(RTBaileBeatClock.BEATS_PER_BAR)), 2) == int(enemy.get("b10_throw_parity", 0))
	if not throws_this_bar or dist > 720.0:
		return
	# Prepara no 3 (aviso de 1 batida), arremessa no 4.
	if beat.bar_beat() == 2:
		enemy["b10_anim"] = "attack"
	if beat.beat_event and beat.bar_beat() == 3:
		var kind: String = BOTTLE_KINDS[core.rng.randi_range(0, BOTTLE_KINDS.size() - 1)]
		throw_bottle(Vector2(enemy["pos"]), Vector2(info["target"]), kind, int(enemy.get("uid", 0)))
		enemy["b10_anim"] = "attack"


func _update_sombrinha(enemy: Dictionary, delta: float) -> void:
	var info := _info(enemy)
	var dir: Vector2 = info["dir"]
	# Escolta: fica entre o alvo e a Garrafeira mais proxima, se houver.
	var escort := _nearest_kind(Vector2(enemy["pos"]), GARRAFEIRA, 520.0)
	var goal: Vector2 = info["target"]
	if not escort.is_empty():
		goal = Vector2(escort["pos"]).lerp(Vector2(info["target"]), 0.35)
	var to_goal: Vector2 = goal - Vector2(enemy["pos"])
	if to_goal.length() > 30.0:
		dance_step(enemy, to_goal.normalized(), float(enemy.get("speed", 92.0)), delta, 0.12)
	enemy["facing_dir"] = dir
	# A sombrinha gira devagar: rodear o bicho e a resposta.
	var guard: Vector2 = Vector2(enemy.get("b10_guard", dir))
	var ang: float = guard.angle()
	var want: float = dir.angle()
	var diff: float = wrapf(want - ang, -PI, PI)
	ang += clampf(diff, -SOMBRINHA_TURN * delta, SOMBRINHA_TURN * delta)
	enemy["b10_guard"] = Vector2.from_angle(ang)
	if beat.beat_event and beat.is_drop() and int(enemy.get("b10_blocked", 0)) > 0:
		enemy["b10_blocked"] = 0
		enemy["b10_anim"] = "attack"
		var aim: Vector2 = (Vector2(info["target"]) - Vector2(enemy["pos"])).normalized()
		shots.append({"p": Vector2(enemy["pos"]), "v": aim * SOMBRINHA_SHOT_SPEED, "life": 2.4, "r": 18.0, "dmg": SOMBRINHA_SHOT_DAMAGE})


func sombrinha_blocks(enemy: Dictionary, from_pos: Vector2) -> bool:
	var to_src: Vector2 = from_pos - Vector2(enemy["pos"])
	if to_src.length() < 1.0:
		return false
	var guard: Vector2 = Vector2(enemy.get("b10_guard", Vector2.RIGHT))
	return absf(wrapf(to_src.angle() - guard.angle(), -PI, PI)) <= SOMBRINHA_BLOCK_HALF


func _update_paredinha(enemy: Dictionary, delta: float) -> void:
	var info := _info(enemy)
	var dir: Vector2 = info["dir"]
	enemy["facing_dir"] = dir
	if String(enemy["b10_state"]) == "walk":
		var dist: float = info["dist"]
		if absf(dist - PAREDINHA_PLANT_DIST) > 60.0:
			dance_step(enemy, dir if dist > PAREDINHA_PLANT_DIST else -dir, float(enemy.get("speed", 96.0)), delta, 0.2)
		elif beat.is_downbeat_event():
			enemy["b10_state"] = "plant"
			enemy["b10_bars"] = 0
		return
	# Plantada: anel de grave a cada 2 batidas; realoca depois de N compassos.
	enemy["b10_anim"] = "attack" if beat.beat_phase() < 0.3 else "idle"
	if beat.beat_event:
		if posmod(beat.beat_index, 2) == 0:
			rings.append({"pos": Vector2(enemy["pos"]), "t": 0.0, "life": RING_BEATS * beat.beat_len(), "hit": {}})
		if beat.bar_beat() == 0:
			enemy["b10_bars"] = int(enemy.get("b10_bars", 0)) + 1
			if int(enemy["b10_bars"]) >= PAREDINHA_PLANT_BARS:
				enemy["b10_state"] = "walk"


func _update_hype(enemy: Dictionary, delta: float) -> void:
	var info := _info(enemy)
	var dist: float = info["dist"]
	var dir: Vector2 = info["dir"]
	var move: Vector2 = -dir if dist < HYPE_FLEE else dir.orthogonal() * float(enemy.get("b10_side", 1.0))
	dance_step(enemy, move, float(enemy.get("speed", 150.0)), delta, 0.4)
	enemy["facing_dir"] = dir


func _nearest_kind(pos: Vector2, kind: String, max_dist: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d := max_dist
	for e in core.enemies:
		if String(e.get("type", "")) != kind or float(e.get("hp", 0.0)) <= 0.0:
			continue
		var d: float = pos.distance_to(Vector2(e["pos"]))
		if d < best_d:
			best_d = d
			best = e
	return best


func _refresh_embalo() -> void:
	var hypes: Array = []
	for e in core.enemies:
		if String(e.get("type", "")) == HYPE and float(e.get("hp", 0.0)) > 0.0:
			hypes.append(Vector2(e["pos"]))
	for e in core.enemies:
		if not owns_kind(String(e.get("type", ""))) or String(e.get("type", "")) in [HYPE, LAGARTONA]:
			continue
		var on := false
		for h in hypes:
			if Vector2(e["pos"]).distance_to(h) <= HYPE_RADIUS:
				on = true
				break
		e["b10_embalo"] = on


func damage_taken_multiplier(enemy: Dictionary) -> float:
	match String(enemy.get("type", "")):
		SOMBRINHA:
			if sombrinha_blocks(enemy, core.player_pos):
				enemy["b10_blocked"] = int(enemy.get("b10_blocked", 0)) + 1
				return SOMBRINHA_BLOCK_MULT
		LAGARTONA:
			return lagartona.damage_taken_multiplier(enemy)
	return 1.0


func contact_blocked(enemy: Dictionary) -> bool:
	if String(enemy.get("type", "")) == LAGARTONA:
		return lagartona.contact_blocked(enemy)
	return false


# ================================================================ projeteis e areas
func throw_bottle(from: Vector2, to: Vector2, kind: String, owner: int = 0) -> void:
	bottles.append({"from": from, "to": to, "t": 0.0, "dur": BOTTLE_FLIGHT_BEATS * beat.beat_len(), "kind": kind, "owner": owner})


func _update_bottles(delta: float) -> void:
	var kept: Array = []
	for b in bottles:
		b["t"] = float(b["t"]) + delta
		if float(b["t"]) < float(b["dur"]):
			kept.append(b)
			continue
		var to: Vector2 = b["to"]
		var kind: String = String(b["kind"])
		var prof: Dictionary = BOTTLE_PROFILE.get(kind, BOTTLE_PROFILE["whisky"])
		core._spawn_radial_particles(to, Color(0.95, 0.75, 0.4) if kind == "whisky" else Color(0.8, 0.95, 1.0), 10)
		for v in _viewers_in_circle(to, BOTTLE_RADIUS):
			hurt_peer(int(v["peer_id"]), float(prof["dmg"]), "baile_" + kind)
			add_teor(int(v["peer_id"]), float(prof["teor"]))
		if kind == "gin":
			puddles.append({"pos": to, "r": GIN_PUDDLE_RADIUS, "life": GIN_PUDDLE_LIFE, "t": 0.0})
	bottles = kept


func _update_puddles(delta: float) -> void:
	var kept: Array = []
	for p in puddles:
		p["t"] = float(p["t"]) + delta
		if float(p["t"]) >= float(p["life"]):
			continue
		kept.append(p)
		if RTUmbraHitbox.feet_in_circle(core.player_pos, Vector2(p["pos"]), float(p["r"])):
			player_slow = maxf(player_slow, GIN_SLOW_TIME)
	puddles = kept


## authority=true aplica dano; o empurrao e sempre do jogador local.
func _update_rings(delta: float, authority: bool) -> void:
	var kept: Array = []
	for r in rings:
		r["t"] = float(r["t"]) + delta
		var life: float = float(r["life"])
		if float(r["t"]) >= life:
			continue
		kept.append(r)
		var radius: float = ring_radius(r)
		var center: Vector2 = r["pos"]
		var feet: Vector2 = RTUmbraHitbox.feet(core.player_pos)
		var d: float = feet.distance_to(center)
		if absf(d - radius) <= RING_BAND and d > 1.0:
			core.player_pos += (feet - center).normalized() * RING_PUSH * delta
		if not authority:
			continue
		var hit: Dictionary = r["hit"]
		for v in viewers():
			var peer: int = int(v["peer_id"])
			if hit.has(peer):
				continue
			var dv: float = RTUmbraHitbox.feet(Vector2(v["pos"])).distance_to(center)
			if absf(dv - radius) <= RING_BAND * 0.6:
				hit[peer] = true
				hurt_peer(peer, RING_DAMAGE, "baile_grave")
	rings = kept


static func ring_radius(r: Dictionary) -> float:
	return RING_MAX * clampf(float(r["t"]) / maxf(0.01, float(r["life"])), 0.0, 1.0)


func _update_shots(delta: float) -> void:
	var kept: Array = []
	for s in shots:
		s["life"] = float(s["life"]) - delta
		s["p"] = Vector2(s["p"]) + Vector2(s["v"]) * delta
		if float(s["life"]) <= 0.0:
			continue
		var hits: Array = _viewers_in_circle(Vector2(s["p"]), float(s["r"]))
		if not hits.is_empty():
			for v in hits:
				hurt_peer(int(v["peer_id"]), float(s["dmg"]), "baile_sombrinha")
			continue
		kept.append(s)
	shots = kept


func move_multiplier() -> float:
	return GIN_SLOW if player_slow > 0.0 else 1.0


# ================================================================ miniboss
func _update_miniboss_schedule() -> void:
	# Chamar o boss antes cancela a Lagartona nesta visita.
	if miniboss_spawned or core.boss_active or core.boss_dead or core._phase_elapsed_time() < LAGARTONA_SPAWN_TIME:
		return
	miniboss_spawned = true
	var pos: Vector2 = core._spawn_point_on_edge()
	core._spawn_enemy(LAGARTONA, pos)
	core._add_text("A LAGARTONA DO PAREDAO CHEGOU", core.player_pos + Vector2(0, -120), Color(0.6, 1.0, 0.4), 2.4, 26)


func miniboss() -> Dictionary:
	for e in core.enemies:
		if String(e.get("type", "")) == LAGARTONA and float(e.get("hp", 0.0)) > 0.0:
			return e
	return {}


func miniboss_alive() -> bool:
	return not miniboss().is_empty()


func on_enemy_defeated(enemy: Dictionary) -> void:
	var kind := String(enemy.get("type", ""))
	if kind == HYPE:
		# Cortou o embalo: quem estava na aura perde o ritmo por um compasso.
		var pos: Vector2 = enemy.get("pos", core.player_pos)
		for e in core.enemies:
			if e == enemy or not owns_kind(String(e.get("type", ""))) or String(e.get("type", "")) == LAGARTONA:
				continue
			if Vector2(e["pos"]).distance_to(pos) <= HYPE_RADIUS:
				e["stun"] = maxf(float(e.get("stun", 0.0)), beat.bar_len())
				e["b10_embalo"] = false
		core._add_text("PERDEU O EMBALO", pos + Vector2(0, -60), Color(0.5, 0.8, 1.0), 1.0, 18)
		return
	if kind != LAGARTONA:
		return
	miniboss_defeated = true
	var mpos: Vector2 = enemy.get("pos", core.player_pos)
	lagartona.on_defeated(enemy)
	core._grant_spectral_core(LAGARTONA_REWARD_CORES, mpos, "miniboss_phase_10")
	core._add_text("A LAGARTONA SAIU DO BAILE", mpos + Vector2(0, -120), Color(0.6, 1.0, 0.4), 2.4, 26)
	core._spawn_radial_particles(mpos, Color(0.6, 1.0, 0.4), 40)


## Chamar o boss limpa o que pertence as ondas da fase.
func clear_for_boss_call() -> void:
	bottles.clear()
	puddles.clear()
	rings.clear()
	shots.clear()
	lagartona.clear()


# ================================================================ multiplayer
func visual_snapshot() -> Dictionary:
	var bottle_pack := PackedFloat32Array()
	for b in bottles:
		bottle_pack.append_array([Vector2(b["from"]).x, Vector2(b["from"]).y, Vector2(b["to"]).x, Vector2(b["to"]).y, float(b["t"]), float(b["dur"]), float(BOTTLE_KINDS.find(String(b["kind"])))])
	var puddle_pack := PackedFloat32Array()
	for p in puddles:
		puddle_pack.append_array([Vector2(p["pos"]).x, Vector2(p["pos"]).y, float(p["r"]), float(p["t"]), float(p["life"])])
	var ring_pack := PackedFloat32Array()
	for r in rings:
		ring_pack.append_array([Vector2(r["pos"]).x, Vector2(r["pos"]).y, float(r["t"]), float(r["life"])])
	var shot_pack := PackedFloat32Array()
	for s in shots:
		shot_pack.append_array([Vector2(s["p"]).x, Vector2(s["p"]).y, Vector2(s["v"]).x, Vector2(s["v"]).y, float(s["life"])])
	var teor_pack: Dictionary = {}
	for key in teor_by_peer.keys():
		teor_pack[int(key)] = snappedf(float(teor_by_peer[key]), 0.1)
	var enemy_visuals: Array = []
	for enemy_value in core.enemies:
		if not enemy_value is Dictionary:
			continue
		var enemy: Dictionary = enemy_value
		if not owns_kind(String(enemy.get("type", ""))):
			continue
		enemy_visuals.append({
			"uid": int(enemy.get("uid", 0)), "s": String(enemy.get("b10_state", "dance")), "a": String(enemy.get("b10_anim", "idle")),
			"g": Vector2(enemy.get("b10_guard", Vector2.RIGHT)), "e": bool(enemy.get("b10_embalo", false)),
		})
	return {
		"bp": beat.beat_pos, "bpm": beat.bpm, "bottles": bottle_pack, "puddles": puddle_pack, "rings": ring_pack,
		"shots": shot_pack, "teor": teor_pack, "mb": [miniboss_spawned, miniboss_defeated], "enemies": enemy_visuals,
		"lag": lagartona.visual_snapshot(),
	}


func apply_remote_visual_snapshot(data: Dictionary) -> void:
	beat.sync(float(data.get("bp", beat.beat_pos)), float(data.get("bpm", beat.bpm)))
	var bp = data.get("bottles", PackedFloat32Array())
	if bp is PackedFloat32Array:
		bottles.clear()
		for o in range(0, bp.size() - 6, 7):
			bottles.append({"from": Vector2(bp[o], bp[o + 1]), "to": Vector2(bp[o + 2], bp[o + 3]), "t": bp[o + 4], "dur": bp[o + 5], "kind": BOTTLE_KINDS[clampi(int(bp[o + 6]), 0, 2)], "owner": 0})
	var pp = data.get("puddles", PackedFloat32Array())
	if pp is PackedFloat32Array:
		puddles.clear()
		for o in range(0, pp.size() - 4, 5):
			puddles.append({"pos": Vector2(pp[o], pp[o + 1]), "r": pp[o + 2], "t": pp[o + 3], "life": pp[o + 4]})
	var rp = data.get("rings", PackedFloat32Array())
	if rp is PackedFloat32Array:
		rings.clear()
		for o in range(0, rp.size() - 3, 4):
			rings.append({"pos": Vector2(rp[o], rp[o + 1]), "t": rp[o + 2], "life": rp[o + 3], "hit": {}})
	var sp = data.get("shots", PackedFloat32Array())
	if sp is PackedFloat32Array:
		shots.clear()
		for o in range(0, sp.size() - 4, 5):
			shots.append({"p": Vector2(sp[o], sp[o + 1]), "v": Vector2(sp[o + 2], sp[o + 3]), "life": sp[o + 4], "r": 18.0, "dmg": 0.0})
	var tp = data.get("teor", {})
	if tp is Dictionary:
		var prev := teor
		teor = float(tp.get(int(core._mp_unique_id()), 0.0))
		if prev > 85.0 and teor <= TEOR_BLACKOUT_RESET + 0.5 and teor < prev:
			blackout = BLACKOUT_TIME
	var mb = data.get("mb", [])
	if mb is Array and mb.size() >= 2:
		miniboss_spawned = bool(mb[0])
		miniboss_defeated = bool(mb[1])
	_remote_enemy_visual_by_uid.clear()
	for v in Array(data.get("enemies", [])):
		if v is Dictionary:
			_remote_enemy_visual_by_uid[int(v.get("uid", 0))] = v
	lagartona.apply_remote_visual_snapshot(Dictionary(data.get("lag", {})))


func _apply_remote_enemy_visuals() -> void:
	for e in core.enemies:
		var v: Dictionary = _remote_enemy_visual_by_uid.get(int(e.get("uid", 0)), {})
		if v.is_empty():
			continue
		e["b10_state"] = String(v.get("s", "dance"))
		e["b10_anim"] = String(v.get("a", "idle"))
		e["b10_guard"] = Vector2(v.get("g", Vector2.RIGHT))
		e["b10_embalo"] = bool(v.get("e", false))


## Replica: anima entre pacotes; empurroes e colisao do palco sao locais.
func update_replica(delta: float) -> void:
	if not active():
		return
	beat.update(delta)
	blackout = maxf(0.0, blackout - delta)
	player_slow = maxf(0.0, player_slow - delta)
	_apply_remote_enemy_visuals()
	for b in bottles:
		b["t"] = minf(float(b["dur"]), float(b["t"]) + delta)
	for s in shots:
		s["p"] = Vector2(s["p"]) + Vector2(s["v"]) * delta
	var kept: Array = []
	for p in puddles:
		p["t"] = float(p["t"]) + delta
		if float(p["t"]) < float(p["life"]):
			kept.append(p)
			if RTUmbraHitbox.feet_in_circle(core.player_pos, Vector2(p["pos"]), float(p["r"])):
				player_slow = maxf(player_slow, GIN_SLOW_TIME)
	puddles = kept
	_update_rings(delta, false)
	_push_player_out_of_stage()
	lagartona.update_replica(delta)
