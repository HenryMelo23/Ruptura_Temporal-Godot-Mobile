class_name RTBoss10Controller
extends RefCounted

## Chefe do Bailao — DONA BOLETA, "a Rainha do Bailao".
## Esta no PALCO desde a entrada na fase, cantando: o palco e solido, absorve
## tiros e ela nao leva dano. Invocada pelo microfone (fluxo do altar), DESCE do
## palco e a luta comeca. Ataques comecam no tempo forte (inicio do compasso).
##
## Estagio 1 (130 BPM):
##  - HOLOFOTE + ROJAO: holofote varre ate o alvo por 1 compasso, TRAVA 0,8 s
##    (o circulo nao segue mais) e o rojao cai ali. Sair do circulo resolve.
##  - CHUVA DE GARRAFA (longe): mira 1 batida; 4 garrafas, uma por batida, na
##    posicao do alvo naquele instante; depois pose 1 compasso (+25%).
##  - GRAVE DO MICROFONE (perto): inspira 1 batida; cone 60 x 380; 2 batidas de
##    costas (+30%).
##  - SARRADA (a cada 4 ataques): 3 dashes curtos, cada um marcado 1 batida antes.
## A RODA (~25 s; obrigatoria no Estagio 2): "ABRE A RODA!" (1 compasso de
##  aviso) e 24 borboletas fecham um circulo em volta dela e do alvo. Ninguem sai.
##  A roda cresce por 16 batidas; a cada compasso 3 dancarinas (marcadas antes)
##  arremessam garrafas para dentro. Depois ela AGRADECE a plateia (+25%).
## Estagio 2 — REMIX MANDELAO (<= 50%): BPM vai a 150, ela tira o casaco,
##  3 holofotes em sequencia, chuva de 6, a roda ja comeca maior.
##
## Multiplayer: autoridade decide e causa dano em todos; a replica so anima e
## aplica localmente o limite da roda no proprio jogador.

const HIT_RADIUS := 100.0
const DRAW_SIZE := Vector2(360, 300)
const ENTRY_TIME := 2.2
const ENTRY_HEIGHT := 180.0
const WALK_SPEED := 125.0
const KEEP_NEAR := 260.0
const KEEP_FAR := 380.0
const CONTACT_DAMAGE := 0.05
# Holofote + rojao
const SPOT_SWEEP_BEATS := 4.0
const SPOT_SPEED := 520.0
const SPOT_LOCK := 0.8
const SPOT_FALL := 0.35
const SPOT_RADIUS := 90.0
const SPOT_DAMAGE := 0.09
# Chuva
const CHUVA_COUNT := 4
const CHUVA_COUNT_REMIX := 6
# Grave
const GRAVE_HALF := deg_to_rad(30.0)
const GRAVE_RANGE := 380.0
const GRAVE_DAMAGE := 0.08
# Sarrada
const DASH_COUNT := 3
const DASH_LEN := 220.0
const DASH_TIME := 0.18
const DASH_DAMAGE := 0.06
# A Roda
const RODA_CD := 25.0
const RODA_FIRST_CD := 14.0
const RODA_DANCERS := 24
const RODA_MIN := 260.0
const RODA_MIN_REMIX := 320.0
const RODA_MAX := 520.0
const RODA_WARN_BEATS := 4.0
const RODA_ON_BEATS := 16.0
const RODA_OFF_BEATS := 4.0
const RODA_SPIN := 0.5
const RODA_EDGE := 26.0
const RODA_TOUCH_DAMAGE := 0.02
const RODA_THROWERS := 3
const RODA_ATTACK_SLOW := 1.3
const AGRADECE_TIME := 1.5
const REMIX_TIME := 1.6
const STAGE2_PCT := 0.5

var game: Node
var mode := "idle"
var t := 0.0
var anim := "sing"
var anim_t := 0.0
var stage := 1
var attack_cd := 1.0
var attack_count := 0
var roda_cd := RODA_FIRST_CD
var spots: Array = []          # {pos, peer, state, t, delay}
var roda: Dictionary = {}      # {center, r0, r, phase, t, angle, dir, marks:[{i, t}], touch_cd:{peer:cd}}
var chuva_left := 0
var grave_dir := Vector2.RIGHT
var grave_flash := 0.0
var dash_from := Vector2.ZERO
var dash_to := Vector2.ZERO
var dashes_left := 0
var height := 0.0
var contact_cd := 0.0
var death_t := -1.0
var moving := false


func configure(p_game: Node) -> void:
	game = p_game


func bl() -> RTBaileController:
	return game.baile_controller


func reset() -> void:
	mode = "entry"
	t = 0.0
	anim = "roda"
	anim_t = 0.0
	stage = 1
	attack_cd = 1.0
	attack_count = 0
	roda_cd = RODA_FIRST_CD
	spots.clear()
	roda.clear()
	chuva_left = 0
	grave_flash = 0.0
	dashes_left = 0
	height = 0.0
	contact_cd = 0.0
	death_t = -1.0
	moving = false


## Antes da invocacao ela canta no palco (desenho e colisao vem do palco).
func on_stage() -> bool:
	return not game.boss_active and not game.boss_dead


func pct() -> float:
	return float(game.boss_hp) / maxf(1.0, float(game.boss_hp_max))


func damage_taken_multiplier() -> float:
	match mode:
		"entry":
			return 0.0
		"remix":
			return 0.5
		"agradece", "pose":
			return 1.25
		"costas":
			return 1.3
	return 1.0


func _go(m: String, a: String = "") -> void:
	mode = m
	t = 0.0
	if a != "":
		anim = a
		anim_t = 0.0


func _beats(n: float) -> float:
	return n * bl().beat.beat_len()


func _focus() -> Dictionary:
	var vs: Array = bl().viewers()
	var want: int = int(game.boss_target_peer_id)
	for v in vs:
		if int(v["peer_id"]) == want:
			return v
	return vs[0]


func update(delta: float) -> void:
	if game == null or not game.boss_active or game.boss_dead:
		return
	t += delta
	anim_t += delta
	contact_cd = maxf(0.0, contact_cd - delta)
	grave_flash = maxf(0.0, grave_flash - delta)
	moving = false
	_update_spots(delta)
	_update_roda(delta)
	_update_stage_change()
	var beat: RTBaileBeatClock = bl().beat
	match mode:
		"entry":
			_update_entry()
		"walk":
			_update_walk(delta, beat)
		"grito":
			if t >= _beats(RODA_WARN_BEATS):
				_end(1.0)
		"holofote":
			if t >= _beats(4.0):
				_end(_beats(4.0))
		"chuva_aim":
			if beat.beat_event and t > 0.05:
				_go("chuva", "attack")
		"chuva":
			_update_chuva(beat)
		"pose":
			if t >= _beats(4.0):
				_end(_beats(2.0))
		"inhale":
			if t >= _beats(1.0):
				_fire_grave()
				_go("costas", "daze")
		"costas":
			if t >= _beats(2.0):
				_end(_beats(2.0))
		"dash_warn":
			if t >= _beats(1.0):
				_go("dash", "attack")
		"dash":
			_update_dash()
		"agradece":
			if t >= AGRADECE_TIME:
				_end(_beats(2.0))
		"remix":
			if t >= REMIX_TIME:
				_start_roda()
	if mode != "entry":
		_keep_in_arena()
		_update_contact()


func _update_entry() -> void:
	var u: float = clampf(t / ENTRY_TIME, 0.0, 1.0)
	game.boss_pos = bl().singer_pos().lerp(bl().fight_anchor(), u)
	height = sin(u * PI) * ENTRY_HEIGHT
	anim = "roda"
	if u >= 1.0:
		height = 0.0
		game.screen_shake_timer = maxf(float(game.screen_shake_timer), 0.35)
		game.screen_shake_strength = maxf(float(game.screen_shake_strength), 9.0)
		game._spawn_radial_particles(game.boss_pos, Color(1.0, 0.45, 0.8), 40)
		game._add_text("A RAINHA DESCEU DO PALCO", game.boss_pos + Vector2(0, -190), Color(1.0, 0.45, 0.8), 2.0, 28)
		_end(_beats(2.0))


func _update_stage_change() -> void:
	if stage == 1 and pct() <= STAGE2_PCT and mode in ["walk", "pose", "costas", "agradece"]:
		stage = 2
		bl().beat.bpm = RTBaileBeatClock.BPM_REMIX
		roda.clear()
		game._add_text("REMIX MANDELAO · 150 BPM", game.boss_pos + Vector2(0, -190), Color(1.0, 0.45, 0.8), 2.2, 30)
		_go("remix", "remix")


func _update_walk(delta: float, beat: RTBaileBeatClock) -> void:
	var focus := _focus()
	var to: Vector2 = Vector2(focus["pos"]) - Vector2(game.boss_pos)
	var dist: float = to.length()
	var dir: Vector2 = to / dist if dist > 1.0 else Vector2.RIGHT
	var move: Vector2 = dir if dist > KEEP_FAR else (-dir if dist < KEEP_NEAR else dir.orthogonal())
	var mult: float = beat.step_multiplier()
	game.boss_pos = Vector2(game.boss_pos) + move * WALK_SPEED * mult * delta
	moving = mult > 0.5
	anim = "remix" if stage >= 2 else "idle"
	attack_cd -= delta
	roda_cd -= delta
	if not beat.is_downbeat_event():
		return
	if roda.is_empty() and roda_cd <= 0.0:
		_start_roda()
		return
	if attack_cd > 0.0:
		return
	attack_count += 1
	if attack_count % 4 == 0:
		_start_sarrada(focus)
	elif dist > KEEP_NEAR:
		if attack_count % 2 == 1:
			_start_holofote()
		else:
			chuva_left = CHUVA_COUNT_REMIX if stage >= 2 else CHUVA_COUNT
			_go("chuva_aim", "attack")
	else:
		grave_dir = dir
		_go("inhale", "sing")


func _end(cd: float) -> void:
	attack_cd = cd * (RODA_ATTACK_SLOW if not roda.is_empty() else 1.0)
	_go("walk", "remix" if stage >= 2 else "idle")


# ---------------------------------------------------------------- holofote
func _start_holofote() -> void:
	var count: int = 3 if stage >= 2 else 1
	var vs: Array = bl().viewers()
	for i in range(count):
		var v: Dictionary = vs[i % vs.size()] if stage >= 2 else _focus()
		spots.append({"pos": bl().singer_pos() + Vector2(-160.0 + 160.0 * i, -40.0), "peer": int(v["peer_id"]), "state": "wait", "t": 0.0, "delay": _beats(2.0) * i})
	_go("holofote", "sing")


func _peer_pos(peer: int) -> Vector2:
	for v in bl().viewers():
		if int(v["peer_id"]) == peer:
			return v["pos"]
	return game.player_pos


func _update_spots(delta: float) -> void:
	var kept: Array = []
	for s in spots:
		s["t"] = float(s["t"]) + delta
		match String(s["state"]):
			"wait":
				if float(s["t"]) >= float(s["delay"]):
					s["state"] = "sweep"
					s["t"] = 0.0
			"sweep":
				var goal: Vector2 = RTUmbraHitbox.feet(_peer_pos(int(s["peer"])))
				s["pos"] = Vector2(s["pos"]).move_toward(goal, SPOT_SPEED * (1.2 if stage >= 2 else 1.0) * delta)
				if float(s["t"]) >= _beats(SPOT_SWEEP_BEATS):
					s["state"] = "lock"
					s["t"] = 0.0
			"lock":
				if float(s["t"]) >= SPOT_LOCK:
					s["state"] = "fall"
					s["t"] = 0.0
			"fall":
				if float(s["t"]) >= SPOT_FALL:
					var p: Vector2 = s["pos"]
					game._spawn_radial_particles(p, Color(1.0, 0.7, 0.25), 26)
					game.shockwaves.append({"pos": p, "radius": 10.0, "max": SPOT_RADIUS, "life": 0.3, "hit": {}, "visual_only": true, "max_life": 0.3, "color": Color(1.0, 0.55, 0.15)})
					game.screen_shake_timer = maxf(float(game.screen_shake_timer), 0.2)
					for v in bl().viewers():
						if RTUmbraHitbox.feet_in_circle(Vector2(v["pos"]), p, SPOT_RADIUS):
							bl().hurt_peer(int(v["peer_id"]), SPOT_DAMAGE, "boleta_rojao")
					continue
		kept.append(s)
	spots = kept


# ---------------------------------------------------------------- chuva / grave
func _update_chuva(beat: RTBaileBeatClock) -> void:
	if beat.beat_event:
		if chuva_left <= 0:
			_go("pose", "idle")
			return
		chuva_left -= 1
		var target: Vector2 = RTUmbraHitbox.feet(Vector2(_focus()["pos"]))
		bl().throw_bottle(Vector2(game.boss_pos) + Vector2(30, -80), target, RTBaileController.BOTTLE_KINDS[game.rng.randi_range(0, 2)])


func _fire_grave() -> void:
	grave_flash = 0.35
	game.screen_shake_timer = maxf(float(game.screen_shake_timer), 0.18)
	for v in bl().viewers():
		if RTUmbraHitbox.body_in_cone(Vector2(v["pos"]), game.boss_pos, grave_dir, GRAVE_RANGE, GRAVE_HALF):
			bl().hurt_peer(int(v["peer_id"]), GRAVE_DAMAGE, "boleta_grave")


# ---------------------------------------------------------------- sarrada
func _start_sarrada(focus: Dictionary) -> void:
	dashes_left = DASH_COUNT
	_prepare_dash(focus)


func _prepare_dash(focus: Dictionary) -> void:
	var to: Vector2 = Vector2(focus["pos"]) - Vector2(game.boss_pos)
	var side: float = 1.0 if dashes_left % 2 == 0 else -1.0
	var dir: Vector2 = to.normalized().rotated(deg_to_rad(35.0) * side) if to.length() > 1.0 else Vector2.RIGHT
	dash_from = game.boss_pos
	dash_to = bl().push_out_of_stage(dash_from + dir * DASH_LEN, 80.0)
	_go("dash_warn", "idle")


func _update_dash() -> void:
	var u: float = clampf(t / DASH_TIME, 0.0, 1.0)
	var prev: Vector2 = game.boss_pos
	game.boss_pos = dash_from.lerp(dash_to, u)
	moving = true
	if contact_cd <= 0.0:
		for v in bl().viewers():
			if RTUmbraHitbox.body_hits_swept(Vector2(v["pos"]), prev, game.boss_pos, HIT_RADIUS * 0.6):
				contact_cd = 0.6
				bl().hurt_peer(int(v["peer_id"]), DASH_DAMAGE, "boleta_sarrada")
				break
	if u >= 1.0:
		dashes_left -= 1
		if dashes_left > 0:
			_prepare_dash(_focus())
		else:
			_go("pose", "idle")


# ---------------------------------------------------------------- A Roda
func _start_roda() -> void:
	var focus: Vector2 = _focus()["pos"]
	var center: Vector2 = (focus + Vector2(game.boss_pos)) * 0.5
	var r0: float = maxf(RODA_MIN_REMIX if stage >= 2 else RODA_MIN, focus.distance_to(game.boss_pos) * 0.5 + 140.0)
	r0 = minf(r0, RODA_MAX - 40.0)
	center = center.clamp(Vector2(r0, r0) * 0.5, Vector2(game.WORLD_SIZE) - Vector2(r0, r0) * 0.5)
	roda = {"center": center, "r0": r0, "r": r0, "phase": "warn", "t": 0.0, "angle": 0.0, "dir": 1.0, "marks": [], "touch_cd": {}}
	roda_cd = RODA_CD
	game._add_text("ABRE A RODA!", game.boss_pos + Vector2(0, -190), Color(1.0, 0.45, 0.8), 1.8, 32)
	_go("grito", "roda")


func roda_active() -> bool:
	return not roda.is_empty() and String(roda.get("phase", "")) == "on"


func dancer_positions() -> Array:
	var out: Array = []
	if roda.is_empty():
		return out
	var c: Vector2 = roda["center"]
	var r: float = float(roda["r"])
	var a0: float = float(roda["angle"])
	for i in range(RODA_DANCERS):
		out.append(c + Vector2.from_angle(a0 + TAU * float(i) / float(RODA_DANCERS)) * r)
	return out


func _update_roda(delta: float) -> void:
	if roda.is_empty():
		return
	var beat: RTBaileBeatClock = bl().beat
	roda["t"] = float(roda["t"]) + delta
	roda["angle"] = float(roda["angle"]) + RODA_SPIN * float(roda["dir"]) * delta
	match String(roda["phase"]):
		"warn":
			if float(roda["t"]) >= _beats(RODA_WARN_BEATS):
				roda["phase"] = "on"
				roda["t"] = 0.0
		"on":
			var u: float = clampf(float(roda["t"]) / _beats(RODA_ON_BEATS), 0.0, 1.0)
			roda["r"] = lerpf(float(roda["r0"]), RODA_MAX, u)
			if beat.beat_event and posmod(beat.beat_index, 8) == 0:
				roda["dir"] = -float(roda["dir"])
			if beat.is_downbeat_event():
				var marks: Array = roda["marks"]
				for k in range(RODA_THROWERS):
					marks.append({"i": game.rng.randi_range(0, RODA_DANCERS - 1), "t": 0.0})
			_update_roda_marks(delta)
			_apply_roda_limits(delta, true)
			if u >= 1.0:
				roda["phase"] = "off"
				roda["t"] = 0.0
				roda["marks"] = []
				if mode == "walk":
					_go("agradece", "sing")
		"off":
			if float(roda["t"]) >= _beats(RODA_OFF_BEATS):
				roda.clear()


func _update_roda_marks(delta: float) -> void:
	var kept: Array = []
	var dancers: Array = dancer_positions()
	for m in Array(roda["marks"]):
		m["t"] = float(m["t"]) + delta
		if float(m["t"]) >= _beats(1.0):
			var from: Vector2 = dancers[int(m["i"]) % dancers.size()]
			bl().throw_bottle(from, RTUmbraHitbox.feet(Vector2(_focus()["pos"])), RTBaileController.BOTTLE_KINDS[game.rng.randi_range(0, 2)])
			continue
		kept.append(m)
	roda["marks"] = kept


## Ninguem sai da roda: o jogador local e o boss sao contidos; tocar nas
## dancarinas empurra para dentro e machuca (dano so na autoridade).
func _apply_roda_limits(delta: float, authority: bool) -> void:
	var c: Vector2 = roda["center"]
	var r: float = float(roda["r"])
	var feet: Vector2 = RTUmbraHitbox.feet(game.player_pos)
	var d: Vector2 = feet - c
	if d.length() > r - RODA_EDGE:
		var inside: Vector2 = c + d.normalized() * (r - RODA_EDGE - 2.0)
		game.player_pos += inside - feet
	if game.boss_active:
		var bd: Vector2 = Vector2(game.boss_pos) - c
		if bd.length() > r - 70.0:
			game.boss_pos = c + bd.normalized() * (r - 70.0)
	if not authority:
		return
	var cds: Dictionary = roda["touch_cd"]
	for key in cds.keys():
		cds[key] = maxf(0.0, float(cds[key]) - delta)
	for v in bl().viewers():
		var peer: int = int(v["peer_id"])
		if float(cds.get(peer, 0.0)) > 0.0:
			continue
		if RTUmbraHitbox.feet(Vector2(v["pos"])).distance_to(c) >= r - RODA_EDGE - 4.0:
			cds[peer] = 0.6
			bl().hurt_peer(peer, RODA_TOUCH_DAMAGE, "boleta_roda")


# ---------------------------------------------------------------- colisao
func _keep_in_arena() -> void:
	game.boss_pos = bl().push_out_of_stage(Vector2(game.boss_pos), 80.0)
	game.boss_pos = Vector2(game.boss_pos).clamp(Vector2(90, 90), Vector2(game.WORLD_SIZE) - Vector2(90, 90))


func _update_contact() -> void:
	if height > 20.0 or contact_cd > 0.0:
		return
	for v in bl().viewers():
		if RTUmbraHitbox.body_hits_circle(Vector2(v["pos"]), game.boss_pos, HIT_RADIUS * 0.7):
			contact_cd = 1.0
			bl().hurt_peer(int(v["peer_id"]), CONTACT_DAMAGE, "boleta")
			return


func on_death() -> void:
	death_t = 0.0
	spots.clear()
	roda.clear()
	bl().bottles.clear()
	bl().beat.bpm = RTBaileBeatClock.BPM_BASE
	game._spawn_radial_particles(game.boss_pos, Color(1.0, 0.45, 0.8), 70)
	game._add_text("A MUSICA PAROU", game.boss_pos + Vector2(0, -190), Color(1.0, 0.45, 0.8), 2.4, 28)


func update_death(delta: float) -> void:
	if death_t >= 0.0:
		death_t += delta
		if death_t > 3.0:
			death_t = -1.0


func frame_info() -> Array:
	if death_t >= 0.0:
		return ["boss10_death", mini(3, int(death_t * 2.0))]
	var beat_frame: int = int(bl().beat.beat_pos) % 4
	match anim:
		"sing":
			return ["boss10_sing", beat_frame]
		"attack":
			return ["boss10_attack", int(anim_t * 6.0) % 2]
		"roda":
			return ["boss10_roda", int(anim_t * 4.0) % 2]
		"daze":
			return ["boss10_daze", int(anim_t * 4.0) % 2]
		"remix":
			return ["boss10_remix", int(bl().beat.beat_pos) % 2]
	return ["boss10_idle", beat_frame]


# ---------------------------------------------------------------- multiplayer
func visual_snapshot() -> Dictionary:
	var spot_pack := PackedFloat32Array()
	for s in spots:
		spot_pack.append_array([Vector2(s["pos"]).x, Vector2(s["pos"]).y, float(["wait", "sweep", "lock", "fall"].find(String(s["state"]))), float(s["t"])])
	var roda_pack: Dictionary = {}
	if not roda.is_empty():
		var mk := PackedFloat32Array()
		for m in Array(roda["marks"]):
			mk.append_array([float(m["i"]), float(m["t"])])
		roda_pack = {"c": roda["center"], "r": roda["r"], "p": roda["phase"], "t": roda["t"], "a": roda["angle"], "d": roda["dir"], "m": mk, "r0": roda["r0"]}
	return {
		"mode": mode, "anim": anim, "t": t, "at": anim_t, "stage": stage, "spots": spot_pack, "roda": roda_pack,
		"gd": grave_dir, "gf": grave_flash, "df": dash_from, "dt": dash_to, "h": height, "death": death_t, "mv": moving,
	}


func apply_remote_visual_snapshot(data: Dictionary) -> void:
	mode = String(data.get("mode", mode))
	anim = String(data.get("anim", anim))
	t = float(data.get("t", t))
	anim_t = float(data.get("at", anim_t))
	stage = int(data.get("stage", stage))
	grave_dir = Vector2(data.get("gd", grave_dir))
	grave_flash = float(data.get("gf", grave_flash))
	dash_from = Vector2(data.get("df", dash_from))
	dash_to = Vector2(data.get("dt", dash_to))
	height = float(data.get("h", height))
	death_t = float(data.get("death", death_t))
	moving = bool(data.get("mv", moving))
	var sp = data.get("spots", PackedFloat32Array())
	if sp is PackedFloat32Array:
		spots.clear()
		for o in range(0, sp.size() - 3, 4):
			spots.append({"pos": Vector2(sp[o], sp[o + 1]), "state": ["wait", "sweep", "lock", "fall"][clampi(int(sp[o + 2]), 0, 3)], "t": sp[o + 3], "peer": 0, "delay": 0.0})
	var rp = data.get("roda", {})
	if rp is Dictionary and not rp.is_empty():
		var marks: Array = []
		var mk = rp.get("m", PackedFloat32Array())
		if mk is PackedFloat32Array:
			for o in range(0, mk.size() - 1, 2):
				marks.append({"i": int(mk[o]), "t": mk[o + 1]})
		roda = {"center": Vector2(rp.get("c", Vector2.ZERO)), "r": float(rp.get("r", RODA_MIN)), "r0": float(rp.get("r0", RODA_MIN)), "phase": String(rp.get("p", "on")), "t": float(rp.get("t", 0.0)), "angle": float(rp.get("a", 0.0)), "dir": float(rp.get("d", 1.0)), "marks": marks, "touch_cd": {}}
	else:
		roda.clear()


## Replica: anima e aplica a roda no proprio jogador (sem dano nem decisao).
func update_replica(delta: float) -> void:
	t += delta
	anim_t += delta
	grave_flash = maxf(0.0, grave_flash - delta)
	if not roda.is_empty():
		roda["angle"] = float(roda["angle"]) + RODA_SPIN * float(roda["dir"]) * delta
		if String(roda["phase"]) == "on":
			_apply_roda_limits(delta, false)
