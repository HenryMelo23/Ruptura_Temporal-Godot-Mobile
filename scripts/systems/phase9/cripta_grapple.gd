class_name RTCriptaGrapple
extends RefCounted

## Cripta de Seda — CONTROLE em vez de dano. As aranhas daqui batem pouco e
## prendem muito: a fase e perigosa pela mecanica, nao pelo hit-kill.
##
## BOLEADEIRA (Mastophora): espreita, gira uma bola de seda pegajosa (o brilho
##   verde aparece no escuro = aviso) e arremessa. Se acertar, LACA a Geovana e
##   sai arrastando para lugares aleatorios enquanto as outras batem.
## ARMADEIRA (Phoneutria): empina (aviso), da o bote com VENENO; as vezes rodeia
##   a Geovana tecendo (anel de seda se fechando) e a ENROLA NUM CASULO, ficando de
##   guarda e injetando veneno.
## Nos dois casos: APERTAR o disparo varias vezes solta (cada toque conta; segurar
##   nao conta). Dano na aranha que prende tambem solta. Depois de soltar: 0,8 s
##   de invencibilidade e 2,5 s sem poder ser presa de novo.
## VENENO: ate 3 cargas, 6 s cada (renova), tira pouco mas sem parar e ENCOLHE a
##   visao; a luz das lamparinas purga 3x mais rapido.
##
## Rede: a autoridade decide quem prende quem (eventos "grab"/"cocoon"/"release"/
## "poison" pelo canal da fase 9). O jogador preso move/prende a si mesmo e conta
## os proprios toques; ao se soltar avisa a autoridade com "escape".

const BOLEADEIRA := "aranha_boleadeira"
const ARMADEIRA := "aranha_armadeira"
const KINDS := [BOLEADEIRA, ARMADEIRA]

# Boleadeira / arrasto
const BOLA_SPIN := 0.7
const BOLA_SPEED := 380.0
const BOLA_RADIUS := 14.0
const BOLA_RANGE := 470.0
const BOLA_CD := 5.5
const STALK_NEAR := 300.0
const STALK_FAR := 430.0
const DRAG_LEN := 70.0
const DRAG_SPEED := 150.0
const DRAG_MAX := 4.5
const DRAG_PRESSES := 7
const RECOVER_TIME := 1.2
# Armadeira / casulo
const ARMA_SPEED := 175.0
const REAR_TIME := 0.45
const LUNGE_TIME := 0.22
const BITE_RANGE := 74.0
const BITE_DAMAGE := 0.04
const ARMA_CD := 1.6
const WEAVE_TIME := 0.9
const WEAVE_RADIUS := 95.0
const WEAVE_CD := 7.0
const COCOON_MAX := 5.0
const COCOON_PRESSES := 10
const GUARD_POISON_EVERY := 1.5
# Comum
const BREAK_DAMAGE := 0.18          # fracao da vida da aranha que, perdida, solta
const RELEASE_IFRAMES := 0.8
const GRAB_IMMUNE := 2.5
# Veneno
const POISON_MAX := 3
const POISON_TIME := 6.0
const POISON_DPS := 0.005           # fracao da vida por segundo, por carga
const POISON_VISION := 0.08         # o cone encolhe 8% por carga
const POISON_LIGHT_PURGE := 3.0

var core: Node
## Controlador da Cripta lido do nucleo (guardar a referencia aqui faria um ciclo
## RefCounted <-> RefCounted que nunca e liberado).
var cr: RTCriptaController:
	get:
		return core.cripta_controller if core != null else null
# ---- estado DESTE jogador (local)
var grab: Dictionary = {}           # {kind, uid, t, progress, lost}
var grab_immune := 0.0
var poison_stacks := 0
var poison_t := 0.0
var press_flash := 0.0
var burst := 0.0                    # fios estourando ao se soltar (so visual)
var _poison_tick := 0.0
var _last_press_frame := -10
# ---- autoridade: quem esta preso por quem
var _held: Dictionary = {}          # peer -> uid
var _immune_until: Dictionary = {}  # peer -> core.time_alive


func configure(_p_cr, p_core: Node) -> void:
	core = p_core


func reset() -> void:
	grab.clear()
	grab_immune = 0.0
	poison_stacks = 0
	poison_t = 0.0
	press_flash = 0.0
	_held.clear()
	_immune_until.clear()


func owns_kind(kind: String) -> bool:
	return KINDS.has(kind)


func held() -> bool:
	return not grab.is_empty()


func vision_mult() -> float:
	return 1.0 - POISON_VISION * float(poison_stacks)


# ================================================================ populacao
func spawn_stats(kind: String, damage: float) -> Dictionary:
	if kind == BOLEADEIRA:
		return {"hp_mult": 1.6, "speed": 120.0, "damage": damage * 0.5, "points": 210}
	return {"hp_mult": 2.0, "speed": ARMA_SPEED, "damage": damage * 0.55, "points": 230}


func on_spawned(enemy: Dictionary) -> void:
	enemy["cr_state"] = "stalk" if String(enemy.get("type", "")) == BOLEADEIRA else "hunt"
	enemy["cr_cd"] = core.rng.randf_range(1.5, 3.0)
	enemy["cr_casulo_cd"] = core.rng.randf_range(2.0, 4.0)
	enemy["gp"] = 0


# ================================================================ autoridade: quem pode ser preso
func can_hold(peer: int) -> bool:
	if _held.has(peer):
		return false
	return float(core.time_alive) >= float(_immune_until.get(peer, -1.0))


func _hold(enemy: Dictionary, peer: int, kind: String) -> bool:
	if not can_hold(peer):
		return false
	var uid: int = int(enemy.get("uid", 0))
	_held[peer] = uid
	enemy["gp"] = peer
	enemy["cr_hold_hp"] = float(enemy.get("hp", 0.0))
	cr._peer_event(peer, kind, float(uid), Vector2(enemy["pos"]))
	return true


## Solta quem esta preso por essa aranha (fim de tempo, dano, morte ou fuga).
func release_by(enemy: Dictionary, escaped: bool = false) -> void:
	var peer: int = int(enemy.get("gp", 0))
	if peer != 0:
		if int(_held.get(peer, -1)) == int(enemy.get("uid", 0)):
			_held.erase(peer)
		_immune_until[peer] = float(core.time_alive) + GRAB_IMMUNE
		if not escaped:
			cr._peer_event(peer, "release", float(enemy.get("uid", 0)), Vector2(enemy["pos"]))
	enemy["gp"] = 0
	if float(enemy.get("hp", 0.0)) > 0.0 and String(enemy.get("cr_state", "")) in ["drag", "guard"]:
		cr._state(enemy, "recover")
		enemy["cr_anim"] = "recover"


## Pedido "escape" de um jogador (ele se soltou apertando o disparo).
func on_escape(peer: int, uid: int) -> void:
	for e in core.enemies:
		if int(e.get("uid", -1)) == uid and int(e.get("gp", 0)) == peer:
			release_by(e, true)
			return
	_held.erase(peer)
	_immune_until[peer] = float(core.time_alive) + GRAB_IMMUNE


func on_enemy_defeated(enemy: Dictionary) -> void:
	if owns_kind(String(enemy.get("type", ""))) and int(enemy.get("gp", 0)) != 0:
		release_by(enemy)


## Autoridade: preso que morreu/saiu solta a aranha; aranha sumida solta o preso.
func update_authority() -> void:
	if _held.is_empty():
		return
	var alive_peers: Dictionary = {}
	for v in cr.viewers():
		alive_peers[int(v["peer_id"])] = true
	for peer in _held.keys():
		var uid: int = int(_held[peer])
		var holder: Dictionary = {}
		for e in core.enemies:
			if int(e.get("uid", -1)) == uid:
				holder = e
				break
		if holder.is_empty() or float(holder.get("hp", 0.0)) <= 0.0:
			_held.erase(peer)
			_immune_until[peer] = float(core.time_alive) + GRAB_IMMUNE
			cr._peer_event(int(peer), "release", float(uid), core.player_pos)
		elif not alive_peers.has(int(peer)):
			release_by(holder)


func _broke_free_by_damage(enemy: Dictionary) -> bool:
	var start: float = float(enemy.get("cr_hold_hp", enemy.get("hp", 0.0)))
	return float(enemy.get("hp", 0.0)) <= start - float(enemy.get("max_hp", 1.0)) * BREAK_DAMAGE


# ================================================================ autoridade: IA
func update_enemy(enemy: Dictionary, delta: float) -> void:
	if String(enemy.get("type", "")) == BOLEADEIRA:
		_update_boleadeira(enemy, delta)
	else:
		_update_armadeira(enemy, delta)


func _update_boleadeira(enemy: Dictionary, delta: float) -> void:
	var info: Dictionary = cr._info(enemy)
	var tgt: Dictionary = cr._target_entry(enemy)
	enemy["facing_dir"] = info["dir"]
	match String(enemy["cr_state"]):
		"stalk":
			enemy["cr_anim"] = "walk"
			var dist: float = info["dist"]
			var dir: Vector2 = Vector2(info["dir"])
			if dist < STALK_NEAR:
				dir = -dir
			elif dist < STALK_FAR:
				dir = dir.orthogonal() * float(enemy["strafe"])
			cr._move(enemy, cr._avoid_light(info["pos"], dir, 40.0), float(enemy.get("speed", 120.0)), delta)
			if float(enemy["cr_cd"]) <= 0.0 and dist < BOLA_RANGE and can_hold(int(tgt["peer_id"])) and not cr.occluded(info["pos"], Vector2(tgt["pos"])):
				cr._state(enemy, "spin")
				enemy["gp"] = int(tgt["peer_id"])
		"spin":
			# Gira a bola: o brilho verde e o aviso (aparece mesmo no breu).
			enemy["cr_anim"] = "attack"
			if float(enemy["cr_t"]) >= BOLA_SPIN:
				var aim_at: Vector2 = Vector2(tgt["pos"]) + cr._target_velocity(tgt).limit_length(220.0) * 0.25
				var v: Vector2 = (aim_at - Vector2(info["pos"])).normalized() * BOLA_SPEED
				cr.webs.append({"p": Vector2(info["pos"]), "v": v, "r": BOLA_RADIUS, "life": BOLA_RANGE / BOLA_SPEED + 0.25, "kind": "bola", "dmg": 0.0, "owner": int(enemy.get("uid", 0))})
				enemy["gp"] = 0
				cr._state(enemy, "wait")
		"wait":
			enemy["cr_anim"] = "walk"
			if float(enemy["cr_t"]) > BOLA_RANGE / BOLA_SPEED + 0.4:
				cr._state(enemy, "stalk")
				enemy["cr_cd"] = BOLA_CD
		"drag":
			enemy["cr_anim"] = "walk"
			# Anda em direcoes aleatorias puxando a presa pela linha.
			if float(enemy.get("drag_turn", 0.0)) <= 0.0:
				enemy["drag_turn"] = core.rng.randf_range(0.5, 0.9)
				enemy["drag_dir"] = Vector2.from_angle(core.rng.randf_range(0.0, TAU))
			enemy["drag_turn"] = float(enemy["drag_turn"]) - delta
			var ddir: Vector2 = cr._avoid_light(info["pos"], Vector2(enemy["drag_dir"]), 50.0)
			cr._move(enemy, ddir, DRAG_SPEED, delta)
			enemy["facing_dir"] = ddir
			if float(enemy["cr_t"]) >= DRAG_MAX or _broke_free_by_damage(enemy):
				release_by(enemy)
		"recover":
			enemy["cr_anim"] = "recover"
			if float(enemy["cr_t"]) >= RECOVER_TIME:
				cr._state(enemy, "stalk")
				enemy["cr_cd"] = BOLA_CD


## Bola de seda: acertou alguem que pode ser preso -> laca. True = consumida.
func bola_hit(w: Dictionary, victim: Dictionary) -> bool:
	var owner: Dictionary = {}
	for e in core.enemies:
		if int(e.get("uid", -1)) == int(w.get("owner", -2)) and float(e.get("hp", 0.0)) > 0.0:
			owner = e
			break
	if owner.is_empty():
		return true
	var peer: int = int(victim["peer_id"])
	if _hold(owner, peer, "grab"):
		cr._state(owner, "drag")
		owner["drag_turn"] = 0.0
	else:
		cr._state(owner, "stalk")
		owner["cr_cd"] = BOLA_CD * 0.5
	return true


func _update_armadeira(enemy: Dictionary, delta: float) -> void:
	var info: Dictionary = cr._info(enemy)
	var tgt: Dictionary = cr._target_entry(enemy)
	enemy["cr_casulo_cd"] = maxf(0.0, float(enemy.get("cr_casulo_cd", 0.0)) - delta)
	match String(enemy["cr_state"]):
		"hunt":
			enemy["cr_anim"] = "walk"
			enemy["facing_dir"] = info["dir"]
			var dist: float = info["dist"]
			var dir: Vector2 = Vector2(info["dir"]) if dist > 90.0 else Vector2(info["dir"]).orthogonal() * float(enemy["strafe"])
			cr._move(enemy, cr._avoid_light(info["pos"], dir, 40.0), float(enemy.get("speed", ARMA_SPEED)), delta)
			if dist < 125.0 and float(enemy["cr_cd"]) <= 0.0:
				if float(enemy["cr_casulo_cd"]) <= 0.0 and can_hold(int(tgt["peer_id"])) and core.rng.randf() < 0.5:
					cr._state(enemy, "weave")
					enemy["gp"] = int(tgt["peer_id"])
					enemy["weave_a"] = (Vector2(info["pos"]) - Vector2(tgt["pos"])).angle()
				else:
					cr._state(enemy, "rear")
		"rear":
			# Empina com as patas da frente erguidas: o aviso do bote.
			enemy["cr_anim"] = "crouch"
			enemy["facing_dir"] = info["dir"]
			if float(enemy["cr_t"]) >= REAR_TIME:
				cr._state(enemy, "lunge")
				enemy["lunge_dir"] = info["dir"]
		"lunge":
			enemy["cr_anim"] = "attack"
			cr._move(enemy, Vector2(enemy["lunge_dir"]), 300.0, delta)
			if float(enemy["cr_t"]) >= LUNGE_TIME:
				var hit: Array = cr._viewers_in_circle(Vector2(enemy["pos"]), BITE_RANGE * 0.6)
				for v in hit:
					cr._hurt_peer(int(v["peer_id"]), BITE_DAMAGE, ARMADEIRA)
					cr._peer_event(int(v["peer_id"]), "poison", 1.0, Vector2(enemy["pos"]))
				cr._state(enemy, "hunt")
				enemy["cr_cd"] = ARMA_CD
		"weave":
			# Rodeia a presa tecendo; o anel de seda se fecha (aviso de 0,9 s).
			enemy["cr_anim"] = "attack"
			var a: float = float(enemy.get("weave_a", 0.0)) + delta * 7.0
			enemy["weave_a"] = a
			var center: Vector2 = tgt["pos"]
			var want: Vector2 = center + Vector2.from_angle(a) * 62.0
			enemy["pos"] = Vector2(enemy["pos"]).move_toward(want, 520.0 * delta)
			enemy["facing_dir"] = (center - Vector2(enemy["pos"])).normalized()
			if float(enemy["cr_t"]) >= WEAVE_TIME:
				var peer: int = int(enemy.get("gp", 0))
				enemy["gp"] = 0
				enemy["cr_casulo_cd"] = WEAVE_CD
				if int(tgt["peer_id"]) == peer and Vector2(enemy["pos"]).distance_to(center) <= WEAVE_RADIUS and _hold(enemy, peer, "cocoon"):
					cr._state(enemy, "guard")
					enemy["guard_tick"] = GUARD_POISON_EVERY
				else:
					cr._state(enemy, "hunt")
					enemy["cr_cd"] = ARMA_CD
		"guard":
			# Fica junto do casulo injetando veneno ate soltarem.
			enemy["cr_anim"] = "walk"
			var held_v: Dictionary = {}
			for v in cr.viewers():
				if int(v["peer_id"]) == int(enemy.get("gp", 0)):
					held_v = v
			if held_v.is_empty():
				release_by(enemy)
				return
			var a2: float = float(enemy.get("weave_a", 0.0)) + delta * 1.4
			enemy["weave_a"] = a2
			enemy["pos"] = Vector2(enemy["pos"]).move_toward(Vector2(held_v["pos"]) + Vector2.from_angle(a2) * 58.0, 200.0 * delta)
			enemy["guard_tick"] = float(enemy.get("guard_tick", 0.0)) - delta
			if float(enemy["guard_tick"]) <= 0.0:
				enemy["guard_tick"] = GUARD_POISON_EVERY
				cr._peer_event(int(held_v["peer_id"]), "poison", 1.0, Vector2(enemy["pos"]))
			if float(enemy["cr_t"]) >= COCOON_MAX or _broke_free_by_damage(enemy):
				release_by(enemy)
		"recover":
			enemy["cr_anim"] = "recover"
			if float(enemy["cr_t"]) >= RECOVER_TIME:
				cr._state(enemy, "hunt")
				enemy["cr_cd"] = ARMA_CD


func damage_taken_multiplier(enemy: Dictionary) -> float:
	match String(enemy.get("cr_state", "")):
		"recover":
			return 1.5
		"rear", "spin":
			return 1.25
	return 1.0


func contact_blocked(enemy: Dictionary) -> bool:
	return String(enemy.get("cr_state", "")) in ["spin", "drag", "weave", "guard", "lunge"]


# ================================================================ jogador local
## Evento que chegou para ESTE jogador.
func apply_event(kind: String, amount: float, pos: Vector2) -> void:
	match kind:
		"grab", "cocoon":
			grab = {"kind": "drag" if kind == "grab" else "cocoon", "uid": int(amount), "t": 0.0, "progress": 0.0, "lost": 0.0}
			_last_press_frame = -10
			core._vibrate(160, 0.8)
			if kind == "grab":
				cr.trigger_scare(BOLEADEIRA, pos)
				core._add_text("LACADA!", core.player_pos + Vector2(0, -80), Color(0.7, 1.0, 0.6), 1.0, 22)
			else:
				cr.trigger_scare(ARMADEIRA, pos)
				core._add_text("CASULO!", core.player_pos + Vector2(0, -80), Color(0.95, 0.95, 1.0), 1.0, 22)
		"release":
			if not grab.is_empty() and int(grab.get("uid", -1)) == int(amount):
				_free(false)
		"poison":
			add_poison(int(round(amount)))


func add_poison(stacks: int = 1) -> void:
	var before: int = poison_stacks
	poison_stacks = mini(POISON_MAX, poison_stacks + maxi(1, stacks))
	poison_t = POISON_TIME
	if poison_stacks > before:
		core._add_text("ENVENENADA x%d" % poison_stacks, core.player_pos + Vector2(0, -64), Color(0.55, 1.0, 0.4), 0.9, 16)


## Toque no disparo enquanto presa. True = o toque foi para a luta (nao atira).
func struggle_press() -> bool:
	if grab.is_empty():
		return false
	var frame: int = int(Engine.get_process_frames())
	var fresh: bool = frame - _last_press_frame > 1  # segurar o botao nao conta
	_last_press_frame = frame
	if not fresh:
		return true
	var need: int = DRAG_PRESSES if String(grab["kind"]) == "drag" else COCOON_PRESSES
	grab["progress"] = float(grab["progress"]) + 1.0 / float(need)
	press_flash = 1.0
	if float(grab["progress"]) >= 0.999:
		var uid: int = int(grab["uid"])
		_free(true)
		if core.is_multiplayer and not core._is_world_authority():
			core._send_authority_phase9_event("escape", float(uid), core.player_pos)
		else:
			on_escape(int(core._mp_unique_id()), uid)
	return true


func _free(escaped: bool) -> void:
	var was: String = String(grab.get("kind", ""))
	grab.clear()
	grab_immune = GRAB_IMMUNE
	core.player_stun_timer = 0.0
	core.run_retry_invulnerability_timer = maxf(float(core.run_retry_invulnerability_timer), RELEASE_IFRAMES)
	if escaped:
		burst = 0.45
		core._add_text("LIVRE!", core.player_pos + Vector2(0, -80), Color(1.0, 0.95, 0.6), 0.9, 22)
		core._spawn_radial_particles(core.player_pos, Color(0.95, 0.95, 1.0), 22 if was == "cocoon" else 12)
		core.screen_shake_timer = maxf(float(core.screen_shake_timer), 0.15)


func update_local(delta: float) -> void:
	press_flash = maxf(0.0, press_flash - delta * 4.0)
	burst = maxf(0.0, burst - delta)
	grab_immune = maxf(0.0, grab_immune - delta)
	_update_poison(delta)
	if grab.is_empty():
		return
	grab["t"] = float(grab["t"]) + delta
	# Presa: nao anda e nao atira (o disparo vira "lutar").
	core.player_stun_timer = maxf(float(core.player_stun_timer), 0.12)
	var holder: Dictionary = {}
	for e in core.enemies:
		if int(e.get("uid", -1)) == int(grab["uid"]) and float(e.get("hp", 0.0)) > 0.0:
			holder = e
			break
	if holder.is_empty():
		grab["lost"] = float(grab["lost"]) + delta
	else:
		grab["lost"] = 0.0
	var limit: float = DRAG_MAX if String(grab["kind"]) == "drag" else COCOON_MAX
	if float(grab["lost"]) > 0.6 or float(grab["t"]) > limit + 1.0:
		_free(false)
		return
	if String(grab["kind"]) == "drag" and not holder.is_empty():
		var sp: Vector2 = holder["pos"]
		var away: Vector2 = core.player_pos - sp
		if away.length() < 1.0:
			away = Vector2.DOWN
		var want: Vector2 = sp + away.normalized() * DRAG_LEN
		core.player_pos = core.player_pos.move_toward(want, 520.0 * delta).clamp(Vector2(40, 40), core.WORLD_SIZE - Vector2(40, 40))


func _update_poison(delta: float) -> void:
	if poison_stacks <= 0:
		return
	poison_t -= delta * (POISON_LIGHT_PURGE if cr.player_in_light() else 1.0)
	if poison_t <= 0.0:
		poison_stacks = 0
		return
	_poison_tick -= delta
	if _poison_tick <= 0.0:
		_poison_tick = 0.5
		var amount: int = maxi(1, int(round(float(core.player_hp_max) * POISON_DPS * float(poison_stacks) * 0.5)))
		core._damage_player(amount, "cripta_veneno", true)
