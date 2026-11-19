class_name RTCriptaController
extends RefCounted

## Dimensao 9 — CRIPTA DE SEDA (terror). Faz parte do ciclo de farm (7 + 3 sorteadas
## de 1/2/3/8/9). Funciona no solo e no multiplayer:
## - AUTORIDADE (solo/host/dono da sala) roda toda a IA, lamparinas, ecos, fios e
##   teias contra TODOS os jogadores (_combat_targets). Cada jogador tem o proprio
##   cone (o dos remotos vem de aim_dir/input_move do sync de jogador).
## - REPLICA recebe visual_snapshot() pelo pacote de visuais do mundo e roda
##   update_replica(): breu, ondulacoes, sustos, aviso pelas costas, regeneracao na
##   luz e "nao e alvo" sao LOCAIS (cada um ve o proprio escuro).
## - Efeitos no jogador remoto (lento, preso, cura do eco, atordoar) vao por
##   core._send_peer_phase9_event; fio atingido pela replica volta para a
##   autoridade por core._send_authority_phase9_event.
##
## Sistemas:
## - VISAO EM CONE: a Geovana enxerga num cone para onde olha (andar/atirar) e
##   num halo curto em volta. Pilastras bloqueiam a visao (sombras). Fora disso
##   e breu; inimigos escondidos so aparecem como ONDULACOES quando se mexem.
##   O tiro automatico so mira no que ela ve.
## - PILASTRAS: colidem e escondem coisas atras delas.
## - LAMPARINAS: 8 pontos de luz; 2 a 3 acesos por vez, 7-11 s cada (pisca antes
##   de apagar). Na luz: visao livre e regeneracao leve. As aranhas evitam a luz
##   (nao entram por vontade), mas a Saltadora pula dentro.
## - ECOS DE LUAR: recompensas espalhadas no escuro (pontos, cura, nucleo a cada 5).
##   Algumas sao MIMICAS.
## - SUSTOS: aranha que aparece de repente perto dela dispara um susto (com recarga).
##
## Bichos: Aranha-Lobo (comum, bando, rajadas), Viuva-do-Silencio (so anda quando
## voce nao olha; ataca pelas costas), Alcapao (enterrada, sai quando voce chega
## perto), Saltadora (agacha com olhos acesos e pula, ate dentro da luz), Mimica
## (finge ser um Eco de Luar), Boleadeira (laca e arrasta) e Armadeira (veneno e
## casulo) — ver RTCriptaGrapple. Mini chefe: Noiva de Seda.
## BALANCO: dano baixo, controle alto. A fase mata por mecanica (presa, arrastada,
## envenenada, sem enxergar), nao por hit-kill. Em troca, rende mais pontos
## (POINT_MULT) — e quem conta isso a Geovana e o Mercador, nao um pop-up.

const PHASE := 9
const LOBO := "aranha_lobo"
const VIUVA := "viuva_silencio"
const ALCAPAO := "aranha_alcapao"
const SALTADORA := "aranha_saltadora"
const MIMICA := "aranha_mimica"
const NOIVA := "noiva_de_seda"
const FILHOTE := "filhote_aranha"
const OLHO := "olho_vigia"
const BOLEADEIRA := "aranha_boleadeira"
const ARMADEIRA := "aranha_armadeira"
const KINDS := [LOBO, VIUVA, ALCAPAO, SALTADORA, MIMICA, NOIVA, FILHOTE, OLHO, BOLEADEIRA, ARMADEIRA]
## Pontos de tudo que se ganha aqui (abates, ecos, chefe): a fase mais dificil paga mais.
const POINT_MULT := 1.75
const SPECIALS := [VIUVA, ALCAPAO, SALTADORA]

# Visao
const CONE_HALF := deg_to_rad(52.0)
const CONE_RANGE := 560.0
const AURA := 125.0
const TURN_SPEED := 9.0
# Mundo
const PILLAR_COUNT := 16
const LAMP_COUNT := 8
const LAMP_RADIUS := 175.0
const LAMP_ON_MIN := 7.0
const LAMP_ON_MAX := 11.0
const LAMP_WARN := 1.6
const LAMP_GAP := 0.8
const LAMP_REGEN := 0.006
const ECHO_MAX := 6
const ECHO_EVERY := 6.5
const ECHO_PICK := 46.0
const ECHO_HEAL := 0.03
const ECHO_POINTS := 120
const MIMIC_CHANCE := 0.28
## Eco de Luar = "diamante": cada um aumenta a visao por um tempo. Pegar outro
## antes de acabar SOMA e reinicia o tempo (quanto mais rapido, mais longe se ve).
## Mimica que morde apaga o bonus inteiro.
const SIGHT_TIME := 7.0
const SIGHT_MAX := 5
const SIGHT_RANGE_PER := 0.11       # +11% de alcance do cone por eco
const SIGHT_HALF_PER := deg_to_rad(5.0)
const SIGHT_AURA_PER := 18.0
# Sustos e ondulacoes
const SCARE_COOLDOWN := 11.0
const SCARE_RANGE := 230.0
const RIPPLE_EVERY := 0.55
const RIPPLE_LIFE := 1.1
# Populacao
const ENEMY_LIMIT_BASE := 8
const SPAWN_INTERVAL := 1.5
const SPECIAL_CAP := 2
# Bichos
const LOBO_BURST := 0.55
const LOBO_PAUSE := 0.35
const LOBO_SPEED := 205.0
const VIUVA_SPEED := 215.0
const VIUVA_BITE := 0.07
const VIUVA_BITE_RANGE := 50.0
const VIUVA_BITE_CD := 1.3
const VIUVA_SEEN_DAMAGE := 1.5
const ALCAPAO_TRIGGER := 105.0
const ALCAPAO_EMERGE := 0.32
const ALCAPAO_BITE := 0.06
const ALCAPAO_HUNT := 3.2
const SALTA_STALK_NEAR := 260.0
const SALTA_STALK_FAR := 420.0
const SALTA_CROUCH := 0.65
const SALTA_FLIGHT := 0.48
const SALTA_LAND_R := 58.0
const SALTA_DAMAGE := 0.05
const SALTA_STUN := 0.85
const SALTA_CD := 3.6
const MIMIC_TRIGGER := 118.0
const MIMIC_BITE := 0.06
# Mini chefe: Noiva de Seda
const NOIVA_SPAWN_TIME := 150.0
const NOIVA_HP_MULT := 26.0
const NOIVA_REWARD_CORES := 2
const NOIVA_ATTACKS := ["fios", "veu", "cantiga", "bolsa"]
const THREAD_SLOW := 0.45
const THREAD_ROOT := 0.6

var core: Node
var facing := Vector2.RIGHT
var pillars: Array = []          # {pos, r}
var lamps: Array = []            # {pos, on, t, life}
var echoes: Array = []           # {pos, t, uid}
var ripples: Array = []          # {pos, t, strength}
var threads: Array = []          # fios da Noiva {a, b, t, life, hp}
var webs: Array = []             # projeteis de teia/veneno {p, v, r, life, kind, dmg}
var scare: Dictionary = {}       # {t, kind, side}
var scare_cd := 0.0
var threat_side := Vector2.ZERO  # direcao do perigo pelas costas (vinheta)
var threat_level := 0.0
var echo_timer := 0.0
var echoes_taken := 0
var miniboss_spawned := false
var miniboss_defeated := false
var player_slow := 0.0
var sight_stacks := 0          # ecos acumulados (so deste jogador)
var sight_timer := 0.0
var sight_k := 0.0             # versao suave de sight_stacks (desenho e logica)
var _echo_uid := 0
var player_velocity := Vector2.ZERO
var _last_player_pos := Vector2.ZERO
var _regen_acc := 0.0
var _layout_seed := 0
var grapple: RTCriptaGrapple = RTCriptaGrapple.new()
# Multiplayer
var _peer_facing: Dictionary = {}            # peer_id -> Vector2 (autoridade)
var _remote_enemy_visual_by_uid: Dictionary = {}
var _replica_track: Dictionary = {}          # uid -> {pos, seen, state, rcd}
var _replica_fake_ripple_cd := 0.0
var _replica_blackout := false


func configure(p_core: Node) -> void:
	core = p_core
	grapple.configure(self, p_core)


func active() -> bool:
	return core != null and int(core.current_phase) == PHASE


func owns_kind(kind: String) -> bool:
	return KINDS.has(kind)


func reset() -> void:
	facing = Vector2.RIGHT
	ripples.clear()
	threads.clear()
	webs.clear()
	echoes.clear()
	scare.clear()
	scare_cd = 4.0
	threat_level = 0.0
	echo_timer = 2.0
	echoes_taken = 0
	miniboss_spawned = false
	miniboss_defeated = false
	player_slow = 0.0
	sight_stacks = 0
	sight_timer = 0.0
	sight_k = 0.0
	grapple.reset()
	_peer_facing.clear()
	_remote_enemy_visual_by_uid.clear()
	_replica_track.clear()
	_replica_blackout = false
	_layout_seed = core.rng.randi()
	_build_layout()


# ================================================================ layout
func _build_layout() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = _layout_seed
	var world: Vector2 = core.WORLD_SIZE
	var keep_clear: Array = [core.experimental_phase_controller.boss_encounter_center(), Vector2(core.experimental_boss_altar_pos), world * 0.5]
	pillars.clear()
	var tries := 0
	while pillars.size() < PILLAR_COUNT and tries < 600:
		tries += 1
		var p := Vector2(r.randf_range(220.0, world.x - 220.0), r.randf_range(220.0, world.y - 220.0))
		var ok := true
		for c in keep_clear:
			if p.distance_to(Vector2(c)) < 300.0:
				ok = false
		for q in pillars:
			if p.distance_to(Vector2(q["pos"])) < 330.0:
				ok = false
		if ok:
			pillars.append({"pos": p, "r": r.randf_range(32.0, 44.0)})
	lamps.clear()
	tries = 0
	while lamps.size() < LAMP_COUNT and tries < 600:
		tries += 1
		var p := Vector2(r.randf_range(300.0, world.x - 300.0), r.randf_range(300.0, world.y - 300.0))
		var ok := true
		for q in lamps:
			if p.distance_to(Vector2(q["pos"])) < 620.0:
				ok = false
		for q in pillars:
			if p.distance_to(Vector2(q["pos"])) < 110.0:
				ok = false
		if ok:
			lamps.append({"pos": p, "on": false, "t": 0.0, "life": 0.0, "gap": r.randf_range(0.0, 2.0)})
	# Comeca com 2 acesas, uma perto do inicio.
	var near := 0
	for i in range(lamps.size()):
		if Vector2(lamps[i]["pos"]).distance_to(core.player_pos) < Vector2(lamps[near]["pos"]).distance_to(core.player_pos):
			near = i
	_light(lamps[near], 9.0)
	_light(lamps[(near + 3) % lamps.size()], 8.0)


func _light(l: Dictionary, life: float) -> void:
	l["on"] = true
	l["t"] = 0.0
	l["life"] = life


# ================================================================ visao
func eye() -> Vector2:
	return core.player_pos + Vector2(0, -10)


func _update_facing(delta: float) -> void:
	var want: Vector2 = facing
	var attack_age: float = float(core.time_alive) - float(core.last_attack_time)
	var move: Vector2 = core._read_move()
	if attack_age < 0.45 and Vector2(core.player_attack_visual_dir).length() > 0.1:
		want = Vector2(core.player_attack_visual_dir).normalized()
	elif move.length() > 0.15:
		want = move.normalized()
	elif Vector2(core.last_facing).length() > 0.1:
		want = Vector2(core.last_facing).normalized()
	var a: float = lerp_angle(facing.angle(), want.angle(), clampf(delta * TURN_SPEED, 0.0, 1.0))
	facing = Vector2.from_angle(a)


func occluded(from: Vector2, to: Vector2) -> bool:
	var seg: Vector2 = to - from
	var len2: float = seg.length_squared()
	if len2 < 1.0:
		return false
	for p in pillars:
		var c: Vector2 = p["pos"]
		var t: float = clampf((c - from).dot(seg) / len2, 0.0, 1.0)
		if t <= 0.02 or t >= 0.98:
			continue
		if (from + seg * t).distance_to(c) < float(p["r"]) * 0.85:
			return true
	return false


## Visao de QUEM joga aqui (com o bonus dos ecos). boost = sight_k.
static func cone_half_for(boost: float) -> float:
	return CONE_HALF + SIGHT_HALF_PER * boost


static func cone_range_for(boost: float) -> float:
	return CONE_RANGE * (1.0 + SIGHT_RANGE_PER * boost)


static func aura_for(boost: float) -> float:
	return AURA + SIGHT_AURA_PER * boost


func cone_half() -> float:
	return cone_half_for(sight_k)


func cone_range() -> float:
	return cone_range_for(sight_k) * grapple.vision_mult()


func aura() -> float:
	return aura_for(sight_k) * grapple.vision_mult()


func add_sight() -> void:
	sight_stacks = mini(SIGHT_MAX, sight_stacks + 1)
	sight_timer = SIGHT_TIME


func lose_sight() -> void:
	sight_stacks = 0
	sight_timer = 0.0


func _update_sight(delta: float) -> void:
	if sight_stacks > 0:
		sight_timer -= delta
		if sight_timer <= 0.0:
			sight_stacks = 0
	# Cresce rapido e encolhe devagar (o escuro "volta" em vez de cair de uma vez).
	var rate: float = 6.0 if float(sight_stacks) > sight_k else 1.4
	sight_k = move_toward(sight_k, float(sight_stacks), rate * delta)


func in_cone(pos: Vector2) -> bool:
	var d: Vector2 = pos - eye()
	var dist: float = d.length()
	if dist <= aura():
		return true
	if dist > cone_range():
		return false
	return absf(wrapf(d.angle() - facing.angle(), -PI, PI)) <= cone_half()


func lit_at(pos: Vector2, margin: float = 0.0) -> bool:
	for l in lamps:
		if bool(l["on"]) and Vector2(l["pos"]).distance_to(pos) <= LAMP_RADIUS + margin:
			return true
	return false


## O que a Geovana enxerga de verdade (cone/halo sem pilastra no meio, ou luz).
func visible(pos: Vector2) -> bool:
	if lit_at(pos):
		return true
	return in_cone(pos) and not occluded(eye(), pos)


## Encarada de verdade: dentro do cone (o halo curto nao conta) ou na luz.
## A Viuva so congela assim; no halo, pelas costas, ela ainda morde.
func looked_at(pos: Vector2) -> bool:
	if lit_at(pos):
		return true
	var d: Vector2 = pos - eye()
	if d.length() > cone_range():
		return false
	return absf(wrapf(d.angle() - facing.angle(), -PI, PI)) <= cone_half() and not occluded(eye(), pos)


## Cone de um jogador qualquer (pos = pes/centro do jogador, dir = para onde olha).
func sees_from(origin: Vector2, dir: Vector2, pos: Vector2, with_aura: bool = true, boost: float = 0.0) -> bool:
	var e: Vector2 = origin + Vector2(0, -10)
	var d: Vector2 = pos - e
	var dist: float = d.length()
	if with_aura and dist <= aura_for(boost):
		return true
	if dist > cone_range_for(boost):
		return false
	if absf(wrapf(d.angle() - dir.angle(), -PI, PI)) > cone_half_for(boost):
		return false
	return not occluded(e, pos)


## Todos os jogadores vivos com o cone de cada um: {peer_id, pos, facing, local, hp_max}.
func viewers() -> Array:
	var out: Array = []
	for t in core._combat_targets():
		var peer: int = int(t.get("peer_id", 0))
		var local: bool = bool(t.get("local", false))
		out.append({
			"peer_id": peer, "pos": Vector2(t.get("pos", core.player_pos)), "local": local,
			"facing": facing if local else Vector2(_peer_facing.get(peer, Vector2.RIGHT)),
			"hp_max": float(t.get("hp_max", core.player_hp_max)),
			"boost": sight_k if local else 0.0,
		})
	if out.is_empty():
		out.append({"peer_id": core._mp_unique_id(), "pos": core.player_pos, "local": true, "facing": facing, "hp_max": float(core.player_hp_max), "boost": sight_k})
	return out


## Algum jogador enxerga (IA da autoridade).
func seen_by_any(pos: Vector2) -> bool:
	if lit_at(pos):
		return true
	for v in viewers():
		if sees_from(v["pos"], v["facing"], pos, true, float(v["boost"])):
			return true
	return false


## Algum jogador ENCARA (cone sem halo, ou luz) — a Viuva congela.
func looked_at_by_any(pos: Vector2) -> bool:
	if lit_at(pos):
		return true
	for v in viewers():
		if sees_from(v["pos"], v["facing"], pos, false, float(v["boost"])):
			return true
	return false


## Cone dos jogadores remotos (autoridade): ataque recente -> mira; andando ->
## direcao do analogico; parado -> ultima mira.
func _update_peer_facings(delta: float) -> void:
	if not core.is_multiplayer:
		return
	for peer_value in core.net_players_by_peer.keys():
		var peer: int = int(peer_value)
		var st: Dictionary = core.net_players_by_peer.get(peer_value, {})
		var aim: Vector2 = Vector2(st.get("aim_dir", Vector2.ZERO))
		var mv: Vector2 = Vector2(st.get("input_move", Vector2.ZERO))
		var want: Vector2 = Vector2(_peer_facing.get(peer, Vector2.RIGHT))
		var attacking: bool = int(st.get("visual_action", 0)) != 0 and float(st.get("visual_action_elapsed", 9.0)) < 0.45
		if attacking and aim.length() > 0.1:
			want = aim.normalized()
		elif bool(st.get("input_moving", false)) and mv.length() > 0.15:
			want = mv.normalized()
		elif mv.length() <= 0.15 and aim.length() > 0.1 and not _peer_facing.has(peer):
			want = aim.normalized()
		var cur: Vector2 = Vector2(_peer_facing.get(peer, want))
		_peer_facing[peer] = Vector2.from_angle(lerp_angle(cur.angle(), want.angle(), clampf(delta * TURN_SPEED, 0.0, 1.0)))


## Alvo (entrada de _combat_targets) que o inimigo esta cacando.
func _target_entry(enemy: Dictionary) -> Dictionary:
	var want: int = int(enemy.get("target_peer_id", 0))
	var vs: Array = viewers()
	for v in vs:
		if int(v["peer_id"]) == want:
			return v
	return vs[0]


func _target_velocity(entry: Dictionary) -> Vector2:
	if bool(entry.get("local", true)):
		return player_velocity
	var st: Dictionary = core.net_players_by_peer.get(int(entry.get("peer_id", 0)), {})
	return Vector2(st.get("velocity", Vector2.ZERO))


## Dano em fracao da vida maxima de um jogador (local ou remoto).
func _hurt_peer(peer_id: int, frac: float, source: String) -> void:
	if peer_id == 0 or peer_id == core._mp_unique_id() or not core.is_multiplayer:
		if core._player_invulnerable():
			return
		core._damage_player(maxi(1, int(round(float(core.player_hp_max) * frac))), source)
		return
	var hp_max: float = float(core.player_hp_max)
	for v in viewers():
		if int(v["peer_id"]) == peer_id:
			hp_max = float(v["hp_max"])
	core._send_peer_damage(peer_id, maxi(1, int(round(hp_max * frac))), source)


## Efeito de jogo num jogador (local aplica direto; remoto vai pela rede).
func _peer_event(peer_id: int, kind: String, amount: float, pos: Vector2) -> void:
	if peer_id == 0 or peer_id == core._mp_unique_id() or not core.is_multiplayer:
		apply_local_event(kind, amount, pos)
	else:
		core._send_peer_phase9_event(peer_id, kind, amount, pos)


## Jogadores cujo corpo encosta num circulo.
func _viewers_in_circle(center: Vector2, radius: float) -> Array:
	var out: Array = []
	for v in viewers():
		if RTUmbraHitbox.body_hits_circle(Vector2(v["pos"]), center, radius):
			out.append(v)
	return out


func player_in_light() -> bool:
	return lit_at(core.player_pos)


# ================================================================ atualizacao
func update(delta: float) -> void:
	if not active():
		return
	_update_facing(delta)
	_update_peer_facings(delta)
	_update_sight(delta)
	_update_lamps(delta)
	_update_echoes(delta)
	_update_webs(delta)
	_update_threads(delta)
	grapple.update_local(delta)
	grapple.update_authority()
	_push_out_of_pillars()
	scare_cd = maxf(0.0, scare_cd - delta)
	if not scare.is_empty():
		scare["t"] = float(scare["t"]) + delta
		if float(scare["t"]) > 0.9:
			scare.clear()
	player_slow = maxf(0.0, player_slow - delta)
	var kept: Array = []
	for rp in ripples:
		rp["t"] = float(rp["t"]) + delta
		if float(rp["t"]) < RIPPLE_LIFE:
			kept.append(rp)
	ripples = kept
	if delta > 0.0:
		player_velocity = player_velocity.lerp((core.player_pos - _last_player_pos) / delta, clampf(delta * 10.0, 0.0, 1.0))
	_last_player_pos = core.player_pos
	if player_in_light():
		_regen_acc += float(core.player_hp_max) * LAMP_REGEN * delta
		if _regen_acc >= 1.0:
			core._heal_player(floor(_regen_acc), "cripta_luz", false)
			_regen_acc -= floor(_regen_acc)
	_update_threat(delta)
	_update_miniboss_schedule()


func _update_lamps(delta: float) -> void:
	var lit := 0
	for l in lamps:
		if bool(l["on"]):
			l["t"] = float(l["t"]) + delta
			if float(l["t"]) >= float(l["life"]):
				l["on"] = false
				l["gap"] = LAMP_GAP + core.rng.randf_range(0.0, 1.2)
			else:
				lit += 1
		else:
			l["gap"] = maxf(0.0, float(l.get("gap", 0.0)) - delta)
	var want: int = 2 if core._phase_elapsed_time() > 200.0 else 3
	if lit < want:
		var options: Array = []
		for l in lamps:
			if not bool(l["on"]) and float(l["gap"]) <= 0.0:
				options.append(l)
		if not options.is_empty():
			var pick: Dictionary = options[core.rng.randi_range(0, options.size() - 1)]
			_light(pick, core.rng.randf_range(LAMP_ON_MIN, LAMP_ON_MAX))
			core._play_sfx("Conquista.mp3", 0.05, 0.25, 1.6)


## Lamparina prestes a apagar (pisca no ultimo trecho).
static func lamp_flicker(l: Dictionary) -> float:
	if not bool(l["on"]):
		return 0.0
	var left: float = float(l["life"]) - float(l["t"])
	if left > LAMP_WARN:
		return 1.0
	return 0.35 + 0.65 * absf(sin(left * 18.0))


func _update_echoes(delta: float) -> void:
	echo_timer -= delta
	var living: int = echoes.size() + core._enemy_type_count(MIMICA)
	if echo_timer <= 0.0 and living < ECHO_MAX:
		echo_timer = ECHO_EVERY
		var pos: Vector2 = _dark_spot(380.0, 900.0)
		if pos != Vector2.INF:
			if core.rng.randf() < MIMIC_CHANCE and core._phase_elapsed_time() > 45.0:
				core._spawn_enemy(MIMICA, pos)
			else:
				_echo_uid += 1
				echoes.append({"pos": pos, "t": 0.0, "uid": _echo_uid})
	var vs: Array = viewers()
	var kept: Array = []
	for e in echoes:
		e["t"] = float(e["t"]) + delta
		var picker := 0
		for v in vs:
			if (Vector2(v["pos"]) + Vector2(0, 30)).distance_to(Vector2(e["pos"])) <= ECHO_PICK:
				picker = int(v["peer_id"])
				break
		if picker != 0:
			_take_echo(Vector2(e["pos"]), picker)
		else:
			kept.append(e)
	echoes = kept


func _take_echo(pos: Vector2, peer_id: int = 0) -> void:
	echoes_taken += 1
	core._apply_score_delta(core._points_for_enemy({"points": ECHO_POINTS}))
	_peer_event(peer_id, "echo", ECHO_HEAL, pos)
	core._spawn_radial_particles(pos, Color(0.7, 0.9, 1.0), 14)
	if echoes_taken % 5 == 0:
		core._grant_spectral_core(1, pos, "cripta_ecos")


## Ponto escuro (fora da luz, longe de pilastra) a uma distancia da Geovana.
func _dark_spot(near: float, far: float, origin: Vector2 = Vector2.INF) -> Vector2:
	var world: Vector2 = core.WORLD_SIZE
	if origin == Vector2.INF:
		var vs: Array = viewers()
		origin = Vector2(vs[core.rng.randi_range(0, vs.size() - 1)]["pos"])
	for i in 24:
		var p: Vector2 = origin + Vector2.from_angle(core.rng.randf_range(0.0, TAU)) * core.rng.randf_range(near, far)
		if p.x < 120.0 or p.y < 120.0 or p.x > world.x - 120.0 or p.y > world.y - 120.0:
			continue
		if lit_at(p, 40.0):
			continue
		var bad := false
		for q in pillars:
			if p.distance_to(Vector2(q["pos"])) < float(q["r"]) + 50.0:
				bad = true
		if not bad:
			return p
	return Vector2.INF


func _push_player_out_of_pillars() -> void:
	var feet: Vector2 = core.player_pos + Vector2(0, 26)
	for p in pillars:
		var c: Vector2 = p["pos"]
		var rr: float = float(p["r"]) + 13.0
		var d: Vector2 = feet - c
		if d.length() < rr and d.length() > 0.01:
			core.player_pos += d.normalized() * (rr - d.length())
			feet = core.player_pos + Vector2(0, 26)


func _push_out_of_pillars() -> void:
	_push_player_out_of_pillars()
	for e in core.enemies:
		if not owns_kind(String(e.get("type", ""))) or String(e.get("cr_state", "")) == "air":
			continue
		for p in pillars:
			var c2: Vector2 = p["pos"]
			var rr2: float = float(p["r"]) + 18.0
			var d2: Vector2 = Vector2(e["pos"]) - c2
			if d2.length() < rr2 and d2.length() > 0.01:
				e["pos"] = c2 + d2.normalized() * rr2


func _update_threat(delta: float) -> void:
	var best := 0.0
	var side := Vector2.ZERO
	for e in core.enemies:
		var kind := String(e.get("type", ""))
		if kind != VIUVA and kind != SALTADORA and kind != LOBO:
			continue
		var pos: Vector2 = e["pos"]
		var dist: float = pos.distance_to(core.player_pos)
		if dist > 300.0 or visible(pos):
			continue
		var w: float = (1.0 - dist / 300.0) * (1.0 if kind == VIUVA else 0.6)
		if w > best:
			best = w
			side = (pos - core.player_pos).normalized()
	threat_level = lerpf(threat_level, best, clampf(delta * 6.0, 0.0, 1.0))
	if best > 0.0:
		threat_side = side


func trigger_scare(kind: String, pos: Vector2) -> void:
	if scare_cd > 0.0:
		return
	if kind != "matriarca" and pos.distance_to(core.player_pos) > SCARE_RANGE * 1.6:
		return
	scare_cd = SCARE_COOLDOWN
	scare = {"t": 0.0, "kind": kind, "side": (pos - core.player_pos).normalized()}
	core.screen_shake_timer = maxf(float(core.screen_shake_timer), 0.35)
	core.screen_shake_strength = maxf(float(core.screen_shake_strength), 9.0)
	core._vibrate(220, 0.9)
	core._play_sfx("boss_impact", 0.05, 0.9, 1.35)


func add_ripple(pos: Vector2, strength: float = 1.0) -> void:
	if ripples.size() < 60:
		ripples.append({"pos": pos, "t": 0.0, "s": strength})


# ================================================================ populacao
func enemy_limit() -> int:
	var elapsed: float = core._phase_elapsed_time()
	return ENEMY_LIMIT_BASE + (1 if elapsed > 200.0 else 0) + (1 if elapsed > 420.0 else 0)


func spawn_interval() -> float:
	return SPAWN_INTERVAL if core._phase_elapsed_time() > 50.0 else 1.9


func choose_enemy_type() -> String:
	var elapsed: float = core._phase_elapsed_time()
	var roll: float = core.rng.randf()
	if elapsed < 35.0:
		return LOBO
	if elapsed < 90.0:
		if roll < 0.2 and core._enemy_type_count(ALCAPAO) < 1:
			return ALCAPAO
		return LOBO
	var grab_cap: int = 1 if elapsed < 200.0 else SPECIAL_CAP
	if roll < 0.10 and core._enemy_type_count(ARMADEIRA) < grab_cap:
		return ARMADEIRA
	if roll < 0.19 and core._enemy_type_count(BOLEADEIRA) < grab_cap:
		return BOLEADEIRA
	if roll < 0.30 and core._enemy_type_count(VIUVA) < SPECIAL_CAP:
		return VIUVA
	if roll < 0.43 and core._enemy_type_count(SALTADORA) < SPECIAL_CAP:
		return SALTADORA
	if roll < 0.55 and core._enemy_type_count(ALCAPAO) < SPECIAL_CAP:
		return ALCAPAO
	return LOBO


func spawn_stats(kind: String, speed: float, damage: float) -> Dictionary:
	match kind:
		# Dano de contato baixo de proposito: quem prende nao precisa bater forte.
		LOBO:
			return {"hp_mult": 0.95, "speed": LOBO_SPEED, "damage": damage * 0.5, "points": 80}
		VIUVA:
			return {"hp_mult": 2.2, "speed": VIUVA_SPEED, "damage": damage * 0.6, "points": 170}
		ALCAPAO:
			return {"hp_mult": 1.7, "speed": 150.0, "damage": damage * 0.6, "points": 150}
		SALTADORA:
			return {"hp_mult": 1.4, "speed": 110.0, "damage": damage * 0.6, "points": 160}
		MIMICA:
			return {"hp_mult": 1.5, "speed": 190.0, "damage": damage * 0.6, "points": 200}
		NOIVA:
			return {"hp_mult": NOIVA_HP_MULT, "speed": 90.0, "damage": damage * 0.8, "points": 900}
		FILHOTE:
			return {"hp_mult": 0.35, "speed": 230.0, "damage": damage * 0.3, "points": 20}
		BOLEADEIRA, ARMADEIRA:
			return grapple.spawn_stats(kind, damage)
		OLHO:
			return {"hp_mult": 0.8, "speed": 60.0, "damage": 0.0, "points": 40}
	return {"hp_mult": 1.0, "speed": speed, "damage": damage, "points": 60}


func on_spawned(enemy: Dictionary) -> void:
	var kind := String(enemy.get("type", ""))
	enemy["shoot_cd"] = 999.0
	enemy["parado"] = true
	enemy["facing_dir"] = Vector2.LEFT
	enemy["cr_state"] = "hunt"
	enemy["cr_t"] = 0.0
	enemy["cr_cd"] = core.rng.randf_range(0.8, 2.2)
	enemy["cr_ripple"] = 0.0
	enemy["cr_seen"] = false
	enemy["strafe"] = -1.0 if core.rng.randf() < 0.5 else 1.0
	match kind:
		ALCAPAO:
			# Nasce enterrada num ponto escuro a frente do caminho dela.
			var p: Vector2 = _dark_spot(260.0, 620.0)
			if p != Vector2.INF:
				enemy["pos"] = p
			enemy["cr_state"] = "buried"
			enemy["contact_grace"] = 999.0
			enemy["untargetable"] = true
		MIMICA:
			enemy["cr_state"] = "disguise"
			enemy["cr_anim"] = "disguise"
			enemy["contact_grace"] = 999.0
			enemy["untargetable"] = true
		VIUVA:
			enemy["contact_grace"] = 999.0
		SALTADORA:
			enemy["cr_state"] = "stalk"
		NOIVA:
			enemy["is_mini_boss"] = true
			enemy["mini_boss"] = true
			enemy["cr_state"] = "entry"
			enemy["cr_cd"] = 1.4
			enemy["cr_last"] = ""
			enemy["contact_grace"] = 1.4
		OLHO:
			enemy["contact_grace"] = 999.0
		BOLEADEIRA, ARMADEIRA:
			grapple.on_spawned(enemy)


# ================================================================ inimigos
func update_enemy(enemy: Dictionary, delta: float) -> void:
	enemy["parado"] = true
	enemy["shoot_cd"] = 999.0
	var pos: Vector2 = enemy["pos"]
	var seen: bool = visible(pos)
	var was_seen: bool = bool(enemy.get("cr_seen", false))
	enemy["cr_seen"] = seen
	# So o que ela ve pode ser alvo do tiro automatico (e o disfarce nunca).
	var kind := String(enemy.get("type", ""))
	enemy["untargetable"] = _hidden_for_local(enemy, seen)
	if float(enemy.get("stun", 0.0)) > 0.0 or float(enemy.get("ferrolho_root", 0.0)) > 0.0:
		return
	enemy["cr_cd"] = maxf(0.0, float(enemy.get("cr_cd", 0.0)) - delta)
	enemy["cr_t"] = float(enemy.get("cr_t", 0.0)) + delta
	match kind:
		LOBO, FILHOTE:
			_update_lobo(enemy, delta)
		VIUVA:
			_update_viuva(enemy, delta, seen)
		ALCAPAO:
			_update_alcapao(enemy, delta)
		SALTADORA:
			_update_saltadora(enemy, delta)
		MIMICA:
			_update_mimica(enemy, delta)
		NOIVA:
			_update_noiva(enemy, delta, seen)
		OLHO:
			_update_olho(enemy, delta)
		BOLEADEIRA, ARMADEIRA:
			grapple.update_enemy(enemy, delta)
	# Ondulacao: algo se mexendo fora da vista.
	var moved: float = pos.distance_to(Vector2(enemy["pos"]))
	enemy["cr_ripple"] = float(enemy.get("cr_ripple", 0.0)) - delta
	if moved > 0.5 and not visible(Vector2(enemy["pos"])) and float(enemy["cr_ripple"]) <= 0.0 and String(enemy.get("cr_state", "")) != "disguise":
		enemy["cr_ripple"] = RIPPLE_EVERY * (0.6 if kind == LOBO else 1.0)
		add_ripple(Vector2(enemy["pos"]), 1.4 if kind == NOIVA else 1.0)
	# Susto: apareceu de repente bem perto.
	if seen and not was_seen and Vector2(enemy["pos"]).distance_to(core.player_pos) < SCARE_RANGE and kind in [VIUVA, SALTADORA, NOIVA, ARMADEIRA]:
		trigger_scare(kind, Vector2(enemy["pos"]))


## "Nao e alvo" do tiro automatico de QUEM esta jogando nesta maquina.
func _hidden_for_local(enemy: Dictionary, seen: bool) -> bool:
	var st: String = String(enemy.get("cr_state", ""))
	return not seen or st == "buried" or (String(enemy.get("type", "")) == MIMICA and st == "disguise")


func _info(enemy: Dictionary) -> Dictionary:
	var pos: Vector2 = enemy["pos"]
	var target: Vector2 = core._get_enemy_target_pos(enemy)
	var to: Vector2 = target - pos
	var dist: float = to.length()
	var dir: Vector2 = to / dist if dist > 0.01 else Vector2(enemy.get("facing_dir", Vector2.LEFT)).normalized()
	return {"pos": pos, "target": target, "dist": dist, "dir": dir}


func _state(enemy: Dictionary, s: String) -> void:
	enemy["cr_state"] = s
	enemy["cr_t"] = 0.0


func _move(enemy: Dictionary, dir: Vector2, speed: float, delta: float) -> void:
	core._phase7_apply_enemy_move(enemy, dir, speed, delta)


## Direcao que contorna a luz: as aranhas nao entram na luz por vontade propria.
func _avoid_light(pos: Vector2, dir: Vector2, step: float) -> Vector2:
	var next: Vector2 = pos + dir * step
	for l in lamps:
		if not bool(l["on"]):
			continue
		var c: Vector2 = l["pos"]
		var rr: float = LAMP_RADIUS + 24.0
		if pos.distance_to(c) < rr:
			return (pos - c).normalized()  # dentro: sai
		if next.distance_to(c) < rr:
			var tangent: Vector2 = (pos - c).normalized().orthogonal()
			if tangent.dot(dir) < 0.0:
				tangent = -tangent
			return tangent
	return dir


func _bite(enemy: Dictionary, frac: float, source: String) -> void:
	_hurt_peer(int(_target_entry(enemy)["peer_id"]), frac, source)


func _update_lobo(enemy: Dictionary, delta: float) -> void:
	var info := _info(enemy)
	var t: float = fmod(float(enemy["cr_t"]), LOBO_BURST + LOBO_PAUSE)
	var speed: float = float(enemy.get("speed", LOBO_SPEED)) if t < LOBO_BURST else 35.0
	var dir: Vector2 = (Vector2(info["dir"]) + Vector2(info["dir"]).orthogonal() * float(enemy["strafe"]) * 0.25).normalized()
	dir = _avoid_light(info["pos"], dir, 40.0)
	_move(enemy, dir, speed, delta)
	enemy["facing_dir"] = info["dir"]
	enemy["cr_anim"] = "attack" if float(info["dist"]) < 70.0 else "walk"


func _update_viuva(enemy: Dictionary, delta: float, _seen: bool) -> void:
	var info := _info(enemy)
	enemy["facing_dir"] = info["dir"]
	if looked_at_by_any(info["pos"]):
		# Alguem olhou para ela: vira estatua.
		enemy["cr_state"] = "estatua"
		enemy["cr_anim"] = "freeze"
		return
	enemy["cr_state"] = "hunt"
	enemy["cr_anim"] = "walk"
	if float(info["dist"]) <= VIUVA_BITE_RANGE:
		enemy["cr_anim"] = "attack"
		if float(enemy["cr_cd"]) <= 0.0:
			enemy["cr_cd"] = VIUVA_BITE_CD
			_bite(enemy, VIUVA_BITE, VIUVA)
			_peer_event(int(_target_entry(enemy)["peer_id"]), "poison", 1.0, info["pos"])
			core._add_text("PELAS COSTAS", core.player_pos + Vector2(0, -70), Color(1.0, 0.3, 0.35), 0.9, 18)
		return
	var dir: Vector2 = _avoid_light(info["pos"], info["dir"], 40.0)
	_move(enemy, dir, VIUVA_SPEED, delta)


func _update_alcapao(enemy: Dictionary, delta: float) -> void:
	var info := _info(enemy)
	match String(enemy["cr_state"]):
		"buried":
			enemy["cr_anim"] = "buried"
			if float(info["dist"]) < ALCAPAO_TRIGGER:
				_state(enemy, "emerge")
				enemy["untargetable"] = false
				core._spawn_radial_particles(info["pos"], Color(0.4, 0.35, 0.3), 14)
				trigger_scare(ALCAPAO, info["pos"])
		"emerge":
			enemy["cr_anim"] = "emerge"
			if float(enemy["cr_t"]) >= ALCAPAO_EMERGE:
				if float(info["dist"]) < ALCAPAO_TRIGGER + 30.0:
					_bite(enemy, ALCAPAO_BITE, ALCAPAO)
				_state(enemy, "hunt")
				enemy["contact_grace"] = 0.0
		"hunt":
			enemy["cr_anim"] = "walk"
			_move(enemy, _avoid_light(info["pos"], info["dir"], 40.0), float(enemy.get("speed", 150.0)), delta)
			enemy["facing_dir"] = info["dir"]
			if float(enemy["cr_t"]) > ALCAPAO_HUNT:
				_state(enemy, "dig")
		"dig":
			enemy["cr_anim"] = "emerge"
			if float(enemy["cr_t"]) > 0.5:
				var p: Vector2 = _dark_spot(220.0, 520.0)
				if p != Vector2.INF:
					# Anda por baixo da terra: deixa ondulacoes no caminho.
					var from: Vector2 = enemy["pos"]
					for k in range(4):
						add_ripple(from.lerp(p, float(k) / 3.0), 0.7)
					enemy["pos"] = p
				_state(enemy, "buried")
				enemy["contact_grace"] = 999.0
				enemy["untargetable"] = true


func _update_saltadora(enemy: Dictionary, delta: float) -> void:
	var info := _info(enemy)
	enemy["facing_dir"] = info["dir"]
	match String(enemy["cr_state"]):
		"stalk":
			enemy["cr_anim"] = "walk"
			var dist: float = info["dist"]
			var dir: Vector2 = Vector2(info["dir"])
			if dist < SALTA_STALK_NEAR:
				dir = -dir
			elif dist < SALTA_STALK_FAR:
				dir = dir.orthogonal() * float(enemy["strafe"])
			_move(enemy, _avoid_light(info["pos"], dir, 40.0), float(enemy.get("speed", 110.0)), delta)
			if float(enemy["cr_cd"]) <= 0.0 and dist < SALTA_STALK_FAR + 80.0:
				_state(enemy, "crouch")
				var tgt: Dictionary = _target_entry(enemy)
				enemy["leap_to"] = Vector2(tgt["pos"]) + _target_velocity(tgt).limit_length(260.0) * 0.35
		"crouch":
			# Olhos acendem (aparecem mesmo no escuro) — e o aviso.
			enemy["cr_anim"] = "crouch"
			if float(enemy["cr_t"]) >= SALTA_CROUCH:
				_state(enemy, "air")
				enemy["leap_from"] = enemy["pos"]
				enemy["contact_grace"] = 999.0
		"air":
			enemy["cr_anim"] = "leap"
			var u: float = clampf(float(enemy["cr_t"]) / SALTA_FLIGHT, 0.0, 1.0)
			enemy["pos"] = Vector2(enemy["leap_from"]).lerp(Vector2(enemy["leap_to"]), u)
			enemy["cr_height"] = sin(u * PI) * 120.0
			if u >= 1.0:
				enemy["cr_height"] = 0.0
				var landing: Vector2 = enemy["pos"]
				for v in _viewers_in_circle(landing, SALTA_LAND_R):
					_hurt_peer(int(v["peer_id"]), SALTA_DAMAGE, SALTADORA)
					_peer_event(int(v["peer_id"]), "stun", 0.35, landing)
				core._spawn_radial_particles(landing, Color(0.5, 0.45, 0.4), 10)
				_state(enemy, "recover")
				enemy["contact_grace"] = 0.0
		"recover":
			enemy["cr_anim"] = "recover"
			if float(enemy["cr_t"]) >= SALTA_STUN:
				_state(enemy, "stalk")
				enemy["cr_cd"] = SALTA_CD + core.rng.randf_range(0.0, 1.2)


func _update_mimica(enemy: Dictionary, delta: float) -> void:
	var info := _info(enemy)
	if String(enemy["cr_state"]) == "disguise":
		enemy["cr_anim"] = "disguise"
		if float(info["dist"]) < MIMIC_TRIGGER:
			_state(enemy, "reveal")
			enemy["untargetable"] = false
			trigger_scare(MIMICA, info["pos"])
		return
	if String(enemy["cr_state"]) == "reveal":
		enemy["cr_anim"] = "reveal"
		if float(enemy["cr_t"]) >= 0.3:
			if float(info["dist"]) < MIMIC_TRIGGER + 20.0:
				_bite(enemy, MIMIC_BITE, MIMICA)
				# A falsa luz cobra a luz verdadeira: o bonus de visao some.
				_peer_event(int(_target_entry(enemy)["peer_id"]), "dim", 0.0, info["pos"])
			_state(enemy, "hunt")
			enemy["contact_grace"] = 0.0
		return
	enemy["cr_anim"] = "walk"
	enemy["facing_dir"] = info["dir"]
	_move(enemy, _avoid_light(info["pos"], info["dir"], 40.0), float(enemy.get("speed", 190.0)), delta)


func _update_olho(enemy: Dictionary, delta: float) -> void:
	# Olho-vigia da Matriarca: flutua e olha para a Geovana (o chefe usa).
	var info := _info(enemy)
	enemy["cr_anim"] = "walk"
	var orbit: Vector2 = Vector2(info["dir"]).orthogonal() * float(enemy["strafe"])
	var want: Vector2 = orbit if float(info["dist"]) < 300.0 else Vector2(info["dir"])
	_move(enemy, want, 70.0, delta)
	enemy["facing_dir"] = info["dir"]


func damage_taken_multiplier(enemy: Dictionary) -> float:
	match String(enemy.get("type", "")):
		VIUVA:
			return VIUVA_SEEN_DAMAGE if String(enemy.get("cr_state", "")) == "estatua" else 1.0
		SALTADORA:
			return 1.6 if String(enemy.get("cr_state", "")) == "recover" else (0.3 if String(enemy.get("cr_state", "")) == "air" else 1.0)
		ALCAPAO:
			return 0.0 if String(enemy.get("cr_state", "")) == "buried" else 1.0
		MIMICA:
			return 0.0 if String(enemy.get("cr_state", "")) == "disguise" else 1.0
		NOIVA:
			return 0.25 if bool(enemy.get("veiled", false)) else 1.0
		BOLEADEIRA, ARMADEIRA:
			return grapple.damage_taken_multiplier(enemy)
	return 1.0


func contact_blocked(enemy: Dictionary) -> bool:
	var kind := String(enemy.get("type", ""))
	if kind == VIUVA or kind == OLHO:
		return true  # a Viuva morde por conta propria; o Olho so vigia
	if grapple.owns_kind(kind) and grapple.contact_blocked(enemy):
		return true
	return String(enemy.get("cr_state", "")) in ["buried", "disguise", "air", "emerge", "reveal", "entry"] or bool(enemy.get("veiled", false))


# ================================================================ Noiva de Seda (mini chefe)
func _update_miniboss_schedule() -> void:
	if miniboss_spawned or core.boss_active or core._phase_elapsed_time() < NOIVA_SPAWN_TIME:
		return
	miniboss_spawned = true
	var pos: Vector2 = _dark_spot(420.0, 640.0)
	if pos == Vector2.INF:
		pos = core._spawn_point_on_edge()
	core._spawn_enemy(NOIVA, pos)
	core._add_text("A NOIVA DE SEDA DESPERTOU", core.player_pos + Vector2(0, -120), Color(0.9, 0.85, 1.0), 2.4, 26)


func miniboss() -> Dictionary:
	for e in core.enemies:
		if String(e.get("type", "")) == NOIVA and float(e.get("hp", 0.0)) > 0.0:
			return e
	return {}


func miniboss_alive() -> bool:
	return not miniboss().is_empty()


func _update_noiva(enemy: Dictionary, delta: float, seen: bool) -> void:
	var info := _info(enemy)
	enemy["facing_dir"] = info["dir"]
	var low: bool = float(enemy.get("hp", 1.0)) < float(enemy.get("max_hp", 1.0)) * 0.5
	match String(enemy["cr_state"]):
		"entry":
			enemy["cr_anim"] = "walk"
			if float(enemy["cr_t"]) > 1.4:
				_state(enemy, "hunt")
		"hunt":
			enemy["cr_anim"] = "walk"
			enemy["veiled"] = false
			var dist: float = info["dist"]
			var dir: Vector2 = Vector2(info["dir"]) if dist > 260.0 else Vector2(info["dir"]).orthogonal() * float(enemy["strafe"])
			_move(enemy, _avoid_light(info["pos"], dir, 40.0), float(enemy.get("speed", 90.0)), delta)
			if float(enemy["cr_cd"]) <= 0.0:
				var bag: Array = enemy.get("cr_bag", [])
				if bag.is_empty():
					bag = NOIVA_ATTACKS.duplicate()
					bag.shuffle()
					if not low:
						bag.erase("bolsa")
				var pick: String = String(bag.pop_back())
				enemy["cr_bag"] = bag
				_state(enemy, pick)
		"fios":
			# Estende fios de seda entre as pilastras mais perto da Geovana.
			enemy["cr_anim"] = "cast"
			if float(enemy["cr_t"]) >= 0.7:
				_noiva_threads(enemy)
				_end_noiva(enemy, 2.2)
		"veu":
			# Some no veu (so o veu aparece, quase sem dano) e reaparece atras dela.
			enemy["cr_anim"] = "veil"
			enemy["veiled"] = true
			enemy["contact_grace"] = 999.0
			if float(enemy["cr_t"]) >= 1.6:
				var tgt: Dictionary = _target_entry(enemy)
				var behind: Vector2 = Vector2(tgt["pos"]) - Vector2(tgt["facing"]) * 170.0
				enemy["pos"] = behind.clamp(Vector2(80, 80), core.WORLD_SIZE - Vector2(80, 80))
				enemy["veiled"] = false
				enemy["contact_grace"] = 0.0
				scare_cd = 0.0
				trigger_scare(NOIVA, enemy["pos"])
				for k in range(10):
					var a: float = TAU * float(k) / 10.0
					webs.append({"p": Vector2(enemy["pos"]), "v": Vector2.from_angle(a) * 210.0, "r": 12.0, "life": 2.4, "kind": "teia", "dmg": 0.03})
				_end_noiva(enemy, 2.0)
		"cantiga":
			# Cantiga de ninar: ondulacoes falsas em volta (a de verdade e mais forte).
			enemy["cr_anim"] = "cast"
			if int(enemy.get("cr_echo", 0)) < int(float(enemy["cr_t"]) / 0.35):
				enemy["cr_echo"] = int(float(enemy["cr_t"]) / 0.35)
				for k in range(3):
					add_ripple(core.player_pos + Vector2.from_angle(core.rng.randf_range(0.0, TAU)) * core.rng.randf_range(200.0, 420.0), 1.2)
				webs.append({"p": Vector2(enemy["pos"]), "v": Vector2(info["dir"]) * 260.0, "r": 14.0, "life": 2.6, "kind": "veneno", "dmg": 0.03})
			if float(enemy["cr_t"]) >= 2.8:
				enemy["cr_echo"] = 0
				_end_noiva(enemy, 1.6)
		"bolsa":
			# Abaixo de 50%: rasga a bolsa de ovos e solta filhotes.
			enemy["cr_anim"] = "cast"
			if float(enemy["cr_t"]) >= 0.8:
				for k in range(5):
					core._spawn_enemy(FILHOTE, Vector2(enemy["pos"]) + Vector2.from_angle(TAU * float(k) / 5.0) * 40.0)
				_end_noiva(enemy, 2.4)


func _end_noiva(enemy: Dictionary, cd: float) -> void:
	_state(enemy, "hunt")
	enemy["cr_cd"] = cd


func _noiva_threads(enemy: Dictionary) -> void:
	var focus: Vector2 = Vector2(_target_entry(enemy)["pos"])
	var near: Array = pillars.duplicate()
	near.sort_custom(func(a, b): return Vector2(a["pos"]).distance_to(focus) < Vector2(b["pos"]).distance_to(focus))
	var count := 0
	for i in range(mini(4, near.size())):
		for j in range(i + 1, mini(4, near.size())):
			if count >= 4:
				break
			var a: Vector2 = near[i]["pos"]
			var b: Vector2 = near[j]["pos"]
			if a.distance_to(b) < 900.0:
				threads.append({"a": a, "b": b, "t": 0.0, "life": 9.0, "hp": 3})
				count += 1
	core._add_text("FIOS DE SEDA", core.player_pos + Vector2(0, -90), Color(0.9, 0.9, 1.0), 1.0, 18)


func _update_threads(delta: float) -> void:
	var kept: Array = []
	var vs: Array = viewers()
	for th in threads:
		th["t"] = float(th["t"]) + delta
		if float(th["t"]) >= float(th["life"]) or int(th["hp"]) <= 0:
			continue
		if float(th["t"]) > 0.6:
			var stuck: Dictionary = th.get("stuck", {})
			for v in vs:
				var peer: int = int(v["peer_id"])
				var feet: Vector2 = Vector2(v["pos"]) + Vector2(0, 30)
				if RTUmbraHitbox.segment_distance(feet, th["a"], th["b"]) < 16.0:
					# Prende uma vez por passada; enquanto encosta, so deixa lento.
					if float(stuck.get(peer, 0.0)) <= 0.0:
						_peer_event(peer, "root", THREAD_ROOT, feet)
					stuck[peer] = 1.5
					if bool(v["local"]):
						player_slow = 1.5
					elif int(Engine.get_process_frames()) % 10 == 0:
						_peer_event(peer, "slow", 1.5, feet)
				else:
					stuck[peer] = maxf(0.0, float(stuck.get(peer, 0.0)) - delta)
			th["stuck"] = stuck
		kept.append(th)
	threads = kept


## Tiro do jogador rompe fios (3 tiros) — chamado pelo nucleo.
func bullet_hit(pos: Vector2) -> bool:
	for th in threads:
		if RTUmbraHitbox.segment_distance(pos, th["a"], th["b"]) < 14.0:
			if core._is_world_authority():
				th["hp"] = int(th["hp"]) - 1
			else:
				core._send_authority_phase9_event("thread_hit", 1.0, pos)
			return true
	return false


func _update_webs(delta: float) -> void:
	var kept: Array = []
	for w in webs:
		w["life"] = float(w["life"]) - delta
		w["p"] = Vector2(w["p"]) + Vector2(w["v"]) * delta
		if float(w["life"]) <= 0.0:
			continue
		var hit := false
		for v in _viewers_in_circle(Vector2(w["p"]), float(w["r"])):
			hit = true
			if String(w["kind"]) == "bola":
				grapple.bola_hit(w, v)
				break
			_hurt_peer(int(v["peer_id"]), float(w["dmg"]), "cripta_" + String(w["kind"]))
			if String(w["kind"]) == "teia":
				_peer_event(int(v["peer_id"]), "slow", 1.2, Vector2(w["p"]))
			elif String(w["kind"]) == "veneno":
				_peer_event(int(v["peer_id"]), "poison", 1.0, Vector2(w["p"]))
		if hit:
			continue
		kept.append(w)
	webs = kept


## Velocidade da Geovana presa na seda.
func move_multiplier() -> float:
	return THREAD_SLOW if player_slow > 0.0 else 1.0


func on_enemy_defeated(enemy: Dictionary) -> void:
	grapple.on_enemy_defeated(enemy)
	if String(enemy.get("type", "")) != NOIVA:
		return
	miniboss_defeated = true
	var pos: Vector2 = enemy.get("pos", core.player_pos)
	threads.clear()
	webs.clear()
	core._grant_spectral_core(NOIVA_REWARD_CORES, pos, "miniboss_phase_9")
	core._add_text("A NOIVA SE DESFEZ EM SEDA", pos + Vector2(0, -120), Color(0.9, 0.85, 1.0), 2.4, 26)
	core._spawn_radial_particles(pos, Color(0.9, 0.9, 1.0), 40)


func clear_for_boss_call() -> void:
	threads.clear()
	webs.clear()
	echoes.clear()


# ================================================================ multiplayer
## Efeito que a autoridade mandou para ESTE jogador (ou que ele mesmo causou).
func apply_local_event(kind: String, amount: float, pos: Vector2) -> void:
	match kind:
		"slow":
			player_slow = maxf(player_slow, amount)
		"root":
			if player_slow <= 0.0:
				core.player_stun_timer = maxf(float(core.player_stun_timer), core._hostile_control_duration(amount))
				core._add_text("PRESA NA SEDA", core.player_pos + Vector2(0, -60), Color(0.9, 0.9, 1.0), 0.8, 16)
			player_slow = maxf(player_slow, 1.5)
		"stun":
			core.player_stun_timer = maxf(float(core.player_stun_timer), core._hostile_control_duration(amount))
		"echo":
			core._heal_player(float(core.player_hp_max) * amount, "cripta_eco")
			add_sight()
			core._add_text("ECO DE LUAR  ·  VISAO x%d" % sight_stacks, pos + Vector2(0, -40), Color(0.75, 0.9, 1.0), 0.9, 16)
		"grab", "cocoon", "release", "poison":
			grapple.apply_event(kind, amount, pos)
		"dim":
			if sight_stacks > 0:
				core._add_text("A LUZ SE APAGOU", core.player_pos + Vector2(0, -70), Color(1.0, 0.4, 0.45), 1.0, 18)
			lose_sight()


## Pedido de um jogador para a autoridade (peer_id = quem pediu).
func apply_authority_event(peer_id: int, kind: String, amount: float, pos: Vector2) -> void:
	match kind:
		"escape":
			grapple.on_escape(peer_id, int(amount))
		"thread_hit":
			for th in threads:
				if RTUmbraHitbox.segment_distance(pos, th["a"], th["b"]) < 20.0:
					th["hp"] = int(th["hp"]) - 1
					return


## Pacote visual (vai junto do pacote de visuais do mundo, ~10 Hz).
func visual_snapshot() -> Dictionary:
	var lamp_pack := PackedFloat32Array()
	for l in lamps:
		lamp_pack.append_array([1.0 if bool(l["on"]) else 0.0, float(l["t"]), float(l["life"])])
	var echo_pack := PackedFloat32Array()
	for e in echoes:
		echo_pack.append_array([Vector2(e["pos"]).x, Vector2(e["pos"]).y, float(e["t"]), float(e["uid"])])
	var thread_pack := PackedFloat32Array()
	for th in threads:
		thread_pack.append_array([Vector2(th["a"]).x, Vector2(th["a"]).y, Vector2(th["b"]).x, Vector2(th["b"]).y, float(th["t"]), float(th["life"]), float(th["hp"])])
	var web_pack := PackedFloat32Array()
	var web_owners := PackedInt64Array()
	for w in webs:
		var kind_id: float = 0.0 if String(w["kind"]) == "teia" else (2.0 if String(w["kind"]) == "bola" else 1.0)
		web_pack.append_array([Vector2(w["p"]).x, Vector2(w["p"]).y, Vector2(w["v"]).x, Vector2(w["v"]).y, float(w["r"]), float(w["life"]), kind_id, float(w["dmg"])])
		# uid nao cabe em float32: vai inteiro, a parte.
		web_owners.append(int(w.get("owner", 0)))
	var enemy_visuals: Array = []
	for enemy_value in core.enemies:
		if not enemy_value is Dictionary:
			continue
		var enemy: Dictionary = enemy_value
		if not owns_kind(String(enemy.get("type", ""))):
			continue
		enemy_visuals.append({
			"uid": int(enemy.get("uid", 0)),
			"s": String(enemy.get("cr_state", "hunt")),
			"a": String(enemy.get("cr_anim", "walk")),
			"t": float(enemy.get("cr_t", 0.0)),
			"h": float(enemy.get("cr_height", 0.0)),
			"to": Vector2(enemy.get("leap_to", enemy.get("pos", Vector2.ZERO))),
			"v": bool(enemy.get("veiled", false)),
			"gp": int(enemy.get("gp", 0)),
		})
	return {
		"seed": _layout_seed, "lamps": lamp_pack, "echoes": echo_pack, "threads": thread_pack, "webs": web_pack, "web_owners": web_owners,
		"mb": [miniboss_spawned, miniboss_defeated], "enemies": enemy_visuals,
	}


func apply_remote_visual_snapshot(data: Dictionary) -> void:
	var seed: int = int(data.get("seed", _layout_seed))
	if seed != _layout_seed or pillars.is_empty():
		_layout_seed = seed
		_build_layout()
	var lp = data.get("lamps", PackedFloat32Array())
	if lp is PackedFloat32Array and lp.size() == lamps.size() * 3:
		for i in range(lamps.size()):
			lamps[i]["on"] = lp[i * 3] > 0.5
			lamps[i]["t"] = lp[i * 3 + 1]
			lamps[i]["life"] = lp[i * 3 + 2]
	var ep = data.get("echoes", PackedFloat32Array())
	if ep is PackedFloat32Array:
		echoes.clear()
		for o in range(0, ep.size() - 3, 4):
			echoes.append({"pos": Vector2(ep[o], ep[o + 1]), "t": ep[o + 2], "uid": int(ep[o + 3])})
	var tp = data.get("threads", PackedFloat32Array())
	if tp is PackedFloat32Array:
		threads.clear()
		for o in range(0, tp.size() - 6, 7):
			threads.append({"a": Vector2(tp[o], tp[o + 1]), "b": Vector2(tp[o + 2], tp[o + 3]), "t": tp[o + 4], "life": tp[o + 5], "hp": int(tp[o + 6])})
	var wp = data.get("webs", PackedFloat32Array())
	if wp is PackedFloat32Array:
		webs.clear()
		var owners = data.get("web_owners", PackedInt64Array())
		for o in range(0, wp.size() - 7, 8):
			var kname: String = "teia" if wp[o + 6] < 0.5 else ("bola" if wp[o + 6] > 1.5 else "veneno")
			var idx: int = o / 8
			var owner: int = int(owners[idx]) if owners is PackedInt64Array and idx < owners.size() else 0
			webs.append({"p": Vector2(wp[o], wp[o + 1]), "v": Vector2(wp[o + 2], wp[o + 3]), "r": wp[o + 4], "life": wp[o + 5], "kind": kname, "dmg": wp[o + 7], "owner": owner})
	var mb: Array = data.get("mb", [])
	if mb.size() == 2:
		miniboss_spawned = bool(mb[0])
		miniboss_defeated = bool(mb[1])
	_remote_enemy_visual_by_uid.clear()
	for visual_value in Array(data.get("enemies", [])):
		if visual_value is Dictionary:
			_remote_enemy_visual_by_uid[int(Dictionary(visual_value).get("uid", 0))] = visual_value
	_apply_remote_enemy_visuals()


func _apply_remote_enemy_visuals() -> void:
	for enemy_value in core.enemies:
		if not enemy_value is Dictionary:
			continue
		var enemy: Dictionary = enemy_value
		var visual: Dictionary = _remote_enemy_visual_by_uid.get(int(enemy.get("uid", 0)), {})
		if visual.is_empty():
			continue
		enemy["cr_state"] = String(visual.get("s", "hunt"))
		enemy["cr_anim"] = String(visual.get("a", "walk"))
		enemy["cr_t"] = float(visual.get("t", 0.0))
		enemy["cr_height"] = float(visual.get("h", 0.0))
		enemy["leap_to"] = Vector2(visual.get("to", enemy.get("pos", Vector2.ZERO)))
		enemy["veiled"] = bool(visual.get("v", false))
		enemy["gp"] = int(visual.get("gp", 0))


## Replica: tudo que e da VISTA de quem joga aqui (o mundo vem da autoridade).
func update_replica(delta: float) -> void:
	if not active():
		return
	if pillars.is_empty():
		_build_layout()
	_update_facing(delta)
	_update_sight(delta)
	_apply_remote_enemy_visuals()
	grapple.update_local(delta)
	_push_player_out_of_pillars()
	scare_cd = maxf(0.0, scare_cd - delta)
	if not scare.is_empty():
		scare["t"] = float(scare["t"]) + delta
		if float(scare["t"]) > 0.9:
			scare.clear()
	player_slow = maxf(0.0, player_slow - delta)
	var kept: Array = []
	for rp in ripples:
		rp["t"] = float(rp["t"]) + delta
		if float(rp["t"]) < RIPPLE_LIFE:
			kept.append(rp)
	ripples = kept
	if delta > 0.0:
		player_velocity = player_velocity.lerp((core.player_pos - _last_player_pos) / delta, clampf(delta * 10.0, 0.0, 1.0))
	_last_player_pos = core.player_pos
	# Teias andam entre um pacote e outro (so visual; o acerto e da autoridade).
	for w in webs:
		w["p"] = Vector2(w["p"]) + Vector2(w["v"]) * delta
		w["life"] = float(w["life"]) - delta
	for th in threads:
		th["t"] = float(th["t"]) + delta
	for l in lamps:
		if bool(l["on"]):
			l["t"] = float(l["t"]) + delta
	for e in echoes:
		e["t"] = float(e["t"]) + delta
	if player_in_light():
		_regen_acc += float(core.player_hp_max) * LAMP_REGEN * delta
		if _regen_acc >= 1.0:
			core._heal_player(floor(_regen_acc), "cripta_luz", false)
			_regen_acc -= floor(_regen_acc)
	var alive: Dictionary = {}
	var cantiga := false
	for enemy_value in core.enemies:
		if not enemy_value is Dictionary:
			continue
		var enemy: Dictionary = enemy_value
		var kind := String(enemy.get("type", ""))
		if not owns_kind(kind):
			continue
		var uid: int = int(enemy.get("uid", 0))
		alive[uid] = true
		var pos: Vector2 = enemy.get("pos", Vector2.ZERO)
		var seen: bool = visible(pos)
		var st: String = String(enemy.get("cr_state", ""))
		enemy["untargetable"] = _hidden_for_local(enemy, seen)
		if kind == NOIVA and st == "cantiga":
			cantiga = true
		var tr: Dictionary = _replica_track.get(uid, {"pos": pos, "seen": seen, "state": st, "rcd": 0.0})
		var rcd: float = float(tr["rcd"]) - delta
		if Vector2(tr["pos"]).distance_to(pos) > 0.5 and not seen and rcd <= 0.0 and st != "disguise":
			rcd = RIPPLE_EVERY * (0.6 if kind == LOBO else 1.0)
			add_ripple(pos, 1.4 if kind == NOIVA else 1.0)
		var near: bool = pos.distance_to(core.player_pos) < SCARE_RANGE
		if near and seen and not bool(tr["seen"]) and kind in [VIUVA, SALTADORA, NOIVA]:
			trigger_scare(kind, pos)
		if near and st != String(tr["state"]) and ((kind == ALCAPAO and st == "emerge") or (kind == MIMICA and st == "reveal")):
			trigger_scare(kind, pos)
		_replica_track[uid] = {"pos": pos, "seen": seen, "state": st, "rcd": rcd}
	for uid in _replica_track.keys():
		if not alive.has(uid):
			_replica_track.erase(uid)
	if cantiga:
		_replica_fake_ripple_cd -= delta
		if _replica_fake_ripple_cd <= 0.0:
			_replica_fake_ripple_cd = 0.35
			for k in range(3):
				add_ripple(core.player_pos + Vector2.from_angle(core.rng.randf_range(0.0, TAU)) * core.rng.randf_range(200.0, 420.0), 1.2)
	var blackout_now: bool = float(core.boss9_controller.blackout) > 0.0
	if blackout_now and not _replica_blackout:
		trigger_scare("matriarca", core.boss_pos)
		core._add_text("APAGÃO", core.player_pos + Vector2(0, -120), Color(1.0, 0.3, 0.35), 2.0, 32)
	_replica_blackout = blackout_now
	_update_threat(delta)
	if core.boss_active:
		core.boss9_controller.update_replica(delta)
