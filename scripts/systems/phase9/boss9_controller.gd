class_name RTBoss9Controller
extends RefCounted

## Chefe da Cripta de Seda — MATRIARCA DOS OITO OLHOS.
## Ela caca pela visao, ao contrario da Geovana: OITO OLHOS varrem a arena e as
## PILASTRAS sao o esconderijo. A luz das lamparinas a queima (+25% de dano).
##
## Estagio 1 (100-60%):
##  - OLHAR: 2 feixes vermelhos giram a partir dela. Ficar 0,35 s dentro de um feixe
##    sem pilastra no meio = VISTA -> BOTE (salta onde voce estava, com aviso).
##  - REDE: leque de 5 teias (prendem e ferem).
##  - CHUVA DE OVOS: 4 bolsas caem do teto (sombra antes); viram 2 filhotes cada.
## 60% — APAGAO (1x): todas as lamparinas apagam por 8 s, a visao encurta, ela
##  sobe para o TETO e faz QUEDA DO TETO 3x (sombra persegue 1,2 s, trava 0,5 s,
##  cai; depois fica tonta 1,4 s e leva o dobro).
## 25% — MIL OLHOS (1x, depois volta ao saco): 6 Olhos-Vigia flutuam em volta.
##  Se algum enxergar a Geovana por 1,2 s, BOTE. Quebrou os 6: ela fica CEGA 3 s (x2).
##
## ESPREITA (qualquer estagio): quando ela sai do campo de visao do alvo, pode
##  sumir no escuro e RODEAR por fora do cone ate ficar atras dele. Se o alvo a
##  enxergar no caminho, ela desiste. Chegando atras: AVISO na direcao de onde
##  ela vem (AMBUSH_WARN) e entao o BOTE. Janela total para reagir = aviso +
##  voo (0,5 s + 0,5 s): o susto leva ~0,3-0,45 s para virar movimento, o resto e
##  para sair do circulo.
##
## Multiplayer: a autoridade roda tudo contra TODOS os jogadores (feixes, bote,
## quedas, olhos, contato). A replica recebe visual_snapshot() e so anima
## (update_replica).

const HIT_RADIUS := 96.0
const DRAW_SIZE := Vector2(360, 300)
const BEAM_RANGE := 900.0
const BEAM_HALF := deg_to_rad(9.0)
const BEAM_SPIN := 0.7
const SPOT_TIME := 0.35
const POUNCE_WARN := 0.75
const POUNCE_FLIGHT := 0.5
const POUNCE_RADIUS := 95.0
const POUNCE_DAMAGE := 0.09
const NET_DAMAGE := 0.03
const DROP_RADIUS := 95.0
const DROP_DAMAGE := 0.10
const DAZE_TIME := 1.4
const BLIND_TIME := 3.0
const BLACKOUT_TIME := 8.0
const CONTACT_DAMAGE := 0.05
const AMBUSH_CD := 9.0
const AMBUSH_FIRST_CD := 6.0
const AMBUSH_WARN := 0.5           # aviso antes do bote (pedido: 500 ms)
const AMBUSH_RADIUS := 330.0
const AMBUSH_SPEED := 250.0
const AMBUSH_STALK_MAX := 3.4
const AMBUSH_SPOTTED := 0.5        # visto por isso tudo no caminho = desiste

var game: Node
var mode := "entry"
var t := 0.0
var anim := "walk"
var anim_t := 0.0
var attack_cd := 1.6
var stage := 1
var bag: Array = []
var beam_angle := 0.0
var spot := 0.0
var pounce_from := Vector2.ZERO
var pounce_to := Vector2.ZERO
var drops_left := 0
var drop_target := Vector2.ZERO
var eggs: Array = []              # {pos, t, fall}
var blackout := 0.0
var blackout_done := false
var thousand_done := false
var eye_watch := 0.0
var daze := 0.0
var blind := 0.0
var contact_cd := 0.0
var height := 0.0
var death_t := -1.0
var moving := false
var ambush_cd := AMBUSH_FIRST_CD
var ambush_peer := 0
var ambush_seen := 0.0


func configure(p_game: Node) -> void:
	game = p_game


func cr() -> RTCriptaController:
	return game.cripta_controller


func reset() -> void:
	mode = "entry"
	t = 0.0
	anim = "walk"
	anim_t = 0.0
	attack_cd = 1.6
	stage = 1
	bag.clear()
	beam_angle = 0.0
	spot = 0.0
	eggs.clear()
	blackout = 0.0
	blackout_done = false
	thousand_done = false
	eye_watch = 0.0
	daze = 0.0
	blind = 0.0
	height = 0.0
	death_t = -1.0
	ambush_cd = AMBUSH_FIRST_CD
	ambush_peer = 0
	ambush_seen = 0.0


func pct() -> float:
	return float(game.boss_hp) / maxf(1.0, float(game.boss_hp_max))


func damage_taken_multiplier() -> float:
	if mode == "ceiling" or height > 40.0:
		return 0.15
	var m := 1.0
	if daze > 0.0 or blind > 0.0:
		m = 2.0
	if cr().lit_at(game.boss_pos):
		m *= 1.25
	return m


func _set_mode(m: String, a: String = "") -> void:
	mode = m
	t = 0.0
	if a != "":
		anim = a
		anim_t = 0.0


func update(delta: float) -> void:
	if game == null or not game.boss_active or game.boss_dead:
		return
	t += delta
	anim_t += delta
	contact_cd = maxf(0.0, contact_cd - delta)
	daze = maxf(0.0, daze - delta)
	blind = maxf(0.0, blind - delta)
	_update_eggs(delta)
	if blackout > 0.0:
		blackout -= delta
		for l in cr().lamps:
			l["on"] = false
			l["gap"] = 0.5
	if daze > 0.0 or blind > 0.0:
		anim = "daze"
		_update_contact()
		return
	_update_stage()
	match mode:
		"entry":
			anim = "walk"
			if t > 1.2:
				_set_mode("walk", "walk")
		"walk":
			_update_walk(delta)
		"olhar":
			_update_olhar(delta)
		"rede":
			_update_rede()
		"ovos":
			_update_ovos()
		"pounce_warn", "pounce":
			_update_pounce()
		"ceiling":
			_update_ceiling(delta)
		"mil_olhos":
			_update_mil_olhos(delta)
		"espreita":
			_update_espreita(delta)
		"ambush_warn":
			_update_ambush_warn()
	_update_contact()


func _update_stage() -> void:
	if not blackout_done and pct() <= 0.6 and mode in ["walk", "olhar", "rede", "ovos"]:
		blackout_done = true
		stage = 2
		blackout = BLACKOUT_TIME
		drops_left = 3
		game._add_text("APAGÃO", game.player_pos + Vector2(0, -120), Color(1.0, 0.3, 0.35), 2.0, 32)
		cr().trigger_scare("matriarca", game.boss_pos)
		_set_mode("ceiling", "climb")
		return
	if not thousand_done and pct() <= 0.25 and mode == "walk":
		thousand_done = true
		stage = 3
		_start_mil_olhos()


func _update_walk(delta: float) -> void:
	var to: Vector2 = game.player_pos - Vector2(game.boss_pos)
	var dist: float = to.length()
	var dir: Vector2 = to.normalized() if dist > 1.0 else Vector2.RIGHT
	var move: Vector2 = dir if dist > 380.0 else (-dir if dist < 240.0 else dir.orthogonal())
	move = cr()._avoid_light(game.boss_pos, move, 50.0)
	game.boss_pos = (Vector2(game.boss_pos) + move * 120.0 * delta).clamp(Vector2(90, 90), game.WORLD_SIZE - Vector2(90, 90))
	moving = true
	anim = "walk"
	ambush_cd -= delta
	if ambush_cd <= 0.0 and _try_start_ambush(dist):
		return
	attack_cd -= delta
	if attack_cd <= 0.0:
		if bag.is_empty():
			bag = ["olhar", "olhar", "rede", "ovos"]
			if stage >= 2:
				bag.append("teto")
			if stage >= 3:
				bag.append("mil_olhos")
			bag.shuffle()
		var pick: String = String(bag.pop_back())
		match pick:
			"olhar":
				beam_angle = dir.angle() - PI * 0.5
				spot = 0.0
				_set_mode("olhar", "gaze")
			"rede":
				_set_mode("rede", "cast")
			"ovos":
				_set_mode("ovos", "cast")
			"teto":
				drops_left = 2
				_set_mode("ceiling", "climb")
			"mil_olhos":
				_start_mil_olhos()


func _end(cd: float) -> void:
	attack_cd = cd
	_set_mode("walk", "walk")


# ---------------------------------------------------------------- Espreita
func _viewer_by_peer(peer: int) -> Dictionary:
	for v in cr().viewers():
		if int(v["peer_id"]) == peer:
			return v
	return {}


## Jogador que ela esta cacando (o alvo do chefe; sem alvo, o primeiro).
func _focus_viewer() -> Dictionary:
	var v: Dictionary = _viewer_by_peer(int(game.boss_target_peer_id))
	return v if not v.is_empty() else Dictionary(cr().viewers()[0])


func _seen_by(v: Dictionary) -> bool:
	return cr().lit_at(game.boss_pos) or cr().sees_from(Vector2(v["pos"]), Vector2(v["facing"]), game.boss_pos, true, float(v.get("boost", 0.0)))


func _try_start_ambush(dist: float) -> bool:
	if blackout > 0.0 or dist < 200.0 or dist > 780.0:
		return false
	var v: Dictionary = _focus_viewer()
	if _seen_by(v):
		return false
	ambush_peer = int(v["peer_id"])
	ambush_seen = 0.0
	_set_mode("espreita", "walk")
	return true


func _update_espreita(delta: float) -> void:
	var v: Dictionary = _viewer_by_peer(ambush_peer)
	if v.is_empty():
		ambush_cd = AMBUSH_CD
		_end(0.8)
		return
	var center: Vector2 = v["pos"]
	var rel: Vector2 = Vector2(game.boss_pos) - center
	var behind: float = (-Vector2(v["facing"])).angle()
	var da: float = wrapf(behind - rel.angle(), -PI, PI)
	# Visto no caminho: desiste (o escuro era a vantagem dela).
	ambush_seen = ambush_seen + delta if _seen_by(v) else maxf(0.0, ambush_seen - delta * 0.5)
	if ambush_seen >= AMBUSH_SPOTTED:
		ambush_cd = AMBUSH_CD * 0.6
		_end(1.0)
		return
	if absf(da) < 0.45 or t >= AMBUSH_STALK_MAX:
		_set_mode("ambush_warn", "crouch")
		if int(ambush_peer) == int(game._mp_unique_id()) or not game.is_multiplayer:
			_warn_local()
		return
	# Gira por fora do cone, puxando para o raio da espreita.
	var step: float = AMBUSH_SPEED * delta
	var a: float = rel.angle() + clampf(da, -step / AMBUSH_RADIUS, step / AMBUSH_RADIUS)
	var r: float = move_toward(rel.length(), AMBUSH_RADIUS, step * 0.8)
	var want: Vector2 = center + Vector2.from_angle(a) * r
	var dir: Vector2 = (want - Vector2(game.boss_pos)).normalized()
	dir = cr()._avoid_light(game.boss_pos, dir, 50.0)
	game.boss_pos = (Vector2(game.boss_pos) + dir * minf(step * 1.4, Vector2(game.boss_pos).distance_to(want) + 1.0)).clamp(Vector2(90, 90), game.WORLD_SIZE - Vector2(90, 90))
	moving = true
	anim = "walk"


func _update_ambush_warn() -> void:
	moving = false
	if t < AMBUSH_WARN:
		return
	var v: Dictionary = _viewer_by_peer(ambush_peer)
	ambush_cd = AMBUSH_CD
	if v.is_empty():
		_end(0.8)
		return
	# Trava onde o alvo esta AGORA; o voo (0,5 s) e a ultima chance de sair.
	pounce_from = game.boss_pos
	pounce_to = v["pos"]
	_set_mode("pounce", "leap")


## Som/vibracao do aviso para quem joga aqui (o desenho mostra a direcao).
func _warn_local() -> void:
	game._vibrate(120, 0.6)
	game._play_sfx("boss_impact", 0.05, 0.55, 1.8)


## Direcao (normalizada, a partir de "pos") de onde ela vem durante o aviso.
func ambush_dir_from(pos: Vector2) -> Vector2:
	return (Vector2(game.boss_pos) - pos).normalized()


# ---------------------------------------------------------------- Olhar
func beam_dirs() -> Array:
	return [Vector2.from_angle(beam_angle), Vector2.from_angle(beam_angle + PI)]


func eye_pos() -> Vector2:
	return Vector2(game.boss_pos) + Vector2(0, -60)


func pos_in_beam(pos: Vector2) -> bool:
	var to: Vector2 = pos - eye_pos()
	if to.length() > BEAM_RANGE:
		return false
	for d in beam_dirs():
		if absf(wrapf(to.angle() - Vector2(d).angle(), -PI, PI)) <= BEAM_HALF + atan2(16.0, maxf(1.0, to.length())):
			if not cr().occluded(eye_pos(), pos):
				return true
	return false


func player_in_beam() -> bool:
	return pos_in_beam(game.player_pos)


## Primeiro jogador pego por um feixe ({} se nenhum).
func _viewer_in_beam() -> Dictionary:
	for v in cr().viewers():
		if pos_in_beam(Vector2(v["pos"])):
			return v
	return {}


func _update_olhar(delta: float) -> void:
	moving = false
	beam_angle += BEAM_SPIN * delta * (1.4 if stage >= 2 else 1.0)
	var caught: Dictionary = _viewer_in_beam()
	if not caught.is_empty():
		spot += delta
		if spot >= SPOT_TIME:
			if bool(caught["local"]):
				game._add_text("VISTA!", game.player_pos + Vector2(0, -80), Color(1.0, 0.25, 0.3), 1.0, 24)
			_start_pounce(Vector2(caught["pos"]))
			return
	else:
		spot = maxf(0.0, spot - delta * 0.5)
	if t >= 4.2:
		_end(1.2)


func _start_pounce(target: Vector2) -> void:
	pounce_from = game.boss_pos
	pounce_to = target
	_set_mode("pounce_warn", "crouch")


func _update_pounce() -> void:
	moving = false
	if mode == "pounce_warn":
		if t >= POUNCE_WARN:
			_set_mode("pounce", "leap")
		return
	var u: float = clampf(t / POUNCE_FLIGHT, 0.0, 1.0)
	game.boss_pos = pounce_from.lerp(pounce_to, u)
	height = sin(u * PI) * 160.0
	if u >= 1.0:
		height = 0.0
		_land(pounce_to, POUNCE_RADIUS, POUNCE_DAMAGE)
		daze = 0.9
		_end(1.4)


func _land(pos: Vector2, radius: float, dmg: float) -> void:
	game.screen_shake_timer = maxf(float(game.screen_shake_timer), 0.3)
	game.screen_shake_strength = maxf(float(game.screen_shake_strength), 8.0)
	game._spawn_radial_particles(pos, Color(0.55, 0.5, 0.48), 26)
	game.shockwaves.append({"pos": pos, "radius": 10.0, "max": radius, "life": 0.3, "hit": {}, "visual_only": true, "max_life": 0.3, "color": Color(0.85, 0.2, 0.3)})
	for v in cr()._viewers_in_circle(pos, radius):
		cr()._hurt_peer(int(v["peer_id"]), dmg, "matriarca")


# ---------------------------------------------------------------- Rede e ovos
func _update_rede() -> void:
	moving = false
	if t >= 0.6:
		var dir: Vector2 = (game._boss_target_pos(false, 0.0) - Vector2(game.boss_pos)).normalized()
		for k in range(5):
			var a: float = dir.angle() + deg_to_rad(-30.0 + 15.0 * float(k))
			cr().webs.append({"p": Vector2(game.boss_pos), "v": Vector2.from_angle(a) * 300.0, "r": 16.0, "life": 2.8, "kind": "teia", "dmg": NET_DAMAGE})
		_end(1.6)


func _update_ovos() -> void:
	moving = false
	if t >= 0.7:
		for k in range(4):
			var p: Vector2 = cr()._dark_spot(160.0, 520.0)
			if p == Vector2.INF:
				p = game.player_pos + Vector2.from_angle(TAU * float(k) / 4.0) * 260.0
			eggs.append({"pos": p, "t": 0.0, "fall": 1.0})
		_end(1.8)


func _update_eggs(delta: float) -> void:
	var kept: Array = []
	for e in eggs:
		e["t"] = float(e["t"]) + delta
		if float(e["t"]) >= float(e["fall"]):
			for k in range(2):
				game._spawn_enemy(RTCriptaController.FILHOTE, Vector2(e["pos"]) + Vector2(k * 30 - 15, 0))
			game._spawn_radial_particles(Vector2(e["pos"]), Color(0.92, 0.9, 0.82), 10)
			continue
		kept.append(e)
	eggs = kept


# ---------------------------------------------------------------- Teto
func _update_ceiling(delta: float) -> void:
	moving = false
	# 0-0.8 sobe; depois a sombra persegue 1,2 s, trava 0,5 s e ela cai.
	if t < 0.8:
		height = lerpf(0.0, 600.0, t / 0.8)
		drop_target = game._boss_target_pos(t < 0.05, 0.0)
		return
	height = 600.0
	var hunt: float = t - 0.8
	if hunt < 1.2:
		drop_target = drop_target.lerp(game._boss_target_pos(false, 0.0), clampf(delta * 6.0, 0.0, 1.0))
		anim = "climb"
	elif hunt < 1.7:
		anim = "drop"
	else:
		game.boss_pos = drop_target
		height = 0.0
		_land(drop_target, DROP_RADIUS, DROP_DAMAGE)
		daze = DAZE_TIME
		drops_left -= 1
		if drops_left > 0:
			_set_mode("ceiling", "climb")
			t = 0.0
		else:
			_end(1.6)


func ceiling_shadow() -> Dictionary:
	if mode != "ceiling" or t < 0.8:
		return {}
	var hunt: float = t - 0.8
	return {"pos": drop_target, "lock": hunt >= 1.2, "u": clampf(hunt / 1.7, 0.0, 1.0)}


# ---------------------------------------------------------------- Mil Olhos
func _start_mil_olhos() -> void:
	for k in range(6):
		var p: Vector2 = game._boss_target_pos(false, 0.0) + Vector2.from_angle(TAU * float(k) / 6.0) * 330.0
		game._spawn_enemy(RTCriptaController.OLHO, p.clamp(Vector2(80, 80), game.WORLD_SIZE - Vector2(80, 80)))
	eye_watch = 0.0
	game._add_text("MIL OLHOS", game.player_pos + Vector2(0, -120), Color(1.0, 0.3, 0.35), 2.0, 30)
	_set_mode("mil_olhos", "gaze")


func watchers() -> Array:
	return game.enemies.filter(func(e): return String(e.get("type", "")) == RTCriptaController.OLHO and float(e.get("hp", 0.0)) > 0.0)


## O olho ve ESTE jogador (desenho da linha vermelha).
func watcher_sees(e: Dictionary) -> bool:
	return _eye_sees(e, game.player_pos)


func _eye_sees(e: Dictionary, pos: Vector2) -> bool:
	var p: Vector2 = e["pos"]
	return p.distance_to(pos) < 420.0 and not cr().occluded(p, pos)


## Primeiro jogador visto por algum olho ({} se nenhum).
func _viewer_seen_by_eyes(eyes: Array) -> Dictionary:
	for v in cr().viewers():
		for e in eyes:
			if _eye_sees(e, Vector2(v["pos"])):
				return v
	return {}


func _update_mil_olhos(delta: float) -> void:
	moving = false
	var eyes: Array = watchers()
	if eyes.is_empty():
		blind = BLIND_TIME
		game._add_text("CEGA!", game.boss_pos + Vector2(0, -140), Color(1.0, 0.9, 0.4), 1.6, 28)
		_end(1.0)
		return
	var found: Dictionary = _viewer_seen_by_eyes(eyes)
	eye_watch = eye_watch + delta if not found.is_empty() else maxf(0.0, eye_watch - delta * 0.6)
	if eye_watch >= 1.2 and not found.is_empty():
		eye_watch = 0.0
		if bool(found["local"]):
			game._add_text("OS OLHOS TE ACHARAM", game.player_pos + Vector2(0, -80), Color(1.0, 0.25, 0.3), 1.0, 20)
		_start_pounce(Vector2(found["pos"]))
	elif t > 14.0:
		for e in eyes:
			e["hp"] = -1.0
		_end(1.4)


func _update_contact() -> void:
	if height > 20.0 or contact_cd > 0.0:
		return
	for v in cr().viewers():
		if RTUmbraHitbox.umbra_touches_body(game.boss_pos, Vector2(v["pos"])):
			contact_cd = 1.0
			cr()._hurt_peer(int(v["peer_id"]), CONTACT_DAMAGE, "matriarca")


func on_death() -> void:
	death_t = 0.0
	blackout = 0.0
	eggs.clear()
	for e in watchers():
		e["hp"] = -1.0
	game._spawn_radial_particles(game.boss_pos, Color(0.85, 0.2, 0.3), 70)


func update_death(delta: float) -> void:
	if death_t >= 0.0:
		death_t += delta
		if death_t > 3.0:
			death_t = -1.0


func frame_info() -> Array:
	if death_t >= 0.0:
		return ["boss9_death", mini(3, int(death_t * 2.5))]
	match anim:
		"walk":
			return ["boss9_walk", int(anim_t * (6.0 if moving else 2.0))]
		"gaze":
			return ["boss9_gaze", int(anim_t * 5.0)]
		"cast":
			return ["boss9_cast", mini(3, int(anim_t / 0.16))]
		"crouch":
			return ["boss9_leap", 0]
		"leap":
			return ["boss9_leap", 1 + int(anim_t * 8.0) % 2]
		"climb", "drop":
			return ["boss9_leap", 3]
		"daze":
			return ["boss9_daze", int(anim_t * 4.0)]
	return ["boss9_walk", 0]


# ---------------------------------------------------------------- multiplayer
func visual_snapshot() -> Dictionary:
	var egg_pack := PackedFloat32Array()
	for e in eggs:
		egg_pack.append_array([Vector2(e["pos"]).x, Vector2(e["pos"]).y, float(e["t"]), float(e["fall"])])
	return {
		"mode": mode, "anim": anim, "t": t, "at": anim_t, "stage": stage, "beam": beam_angle, "spot": spot,
		"pf": pounce_from, "pt": pounce_to, "drop": drop_target, "eggs": egg_pack, "bo": blackout,
		"bod": blackout_done, "td": thousand_done, "daze": daze, "blind": blind, "h": height,
		"death": death_t, "watch": eye_watch, "mv": moving, "ap": ambush_peer,
	}


func apply_remote_visual_snapshot(data: Dictionary) -> void:
	var prev_mode: String = mode
	mode = String(data.get("mode", mode))
	ambush_peer = int(data.get("ap", ambush_peer))
	if mode == "ambush_warn" and prev_mode != "ambush_warn" and ambush_peer == int(game._mp_unique_id()):
		_warn_local()
	var next_anim: String = String(data.get("anim", anim))
	anim = next_anim
	t = float(data.get("t", t))
	anim_t = float(data.get("at", anim_t))
	stage = int(data.get("stage", stage))
	beam_angle = float(data.get("beam", beam_angle))
	spot = float(data.get("spot", spot))
	pounce_from = Vector2(data.get("pf", pounce_from))
	pounce_to = Vector2(data.get("pt", pounce_to))
	drop_target = Vector2(data.get("drop", drop_target))
	blackout = float(data.get("bo", blackout))
	blackout_done = bool(data.get("bod", blackout_done))
	thousand_done = bool(data.get("td", thousand_done))
	daze = float(data.get("daze", daze))
	blind = float(data.get("blind", blind))
	height = float(data.get("h", height))
	death_t = float(data.get("death", death_t))
	eye_watch = float(data.get("watch", eye_watch))
	moving = bool(data.get("mv", moving))
	var ep = data.get("eggs", PackedFloat32Array())
	if ep is PackedFloat32Array:
		eggs.clear()
		for o in range(0, ep.size() - 3, 4):
			eggs.append({"pos": Vector2(ep[o], ep[o + 1]), "t": ep[o + 2], "fall": ep[o + 3]})


## Replica: so anima entre um pacote e outro (nada de dano nem decisao).
func update_replica(delta: float) -> void:
	t += delta
	anim_t += delta
	daze = maxf(0.0, daze - delta)
	blind = maxf(0.0, blind - delta)
	blackout = maxf(0.0, blackout - delta)
	if mode == "olhar":
		beam_angle += BEAM_SPIN * delta * (1.4 if stage >= 2 else 1.0)
	for e in eggs:
		e["t"] = float(e["t"]) + delta
