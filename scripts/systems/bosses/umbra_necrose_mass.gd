class_name RTUmbraNecroseMass
extends RefCounted

## MISSA DO NINHO — habilidade da dimensao NECROSE (acao "MIASMA" da UMBRA).
## Substitui o miasma antigo (nuvem que grudava no jogador e dava dano sempre).
## Referencia: a missa do Pai-Rato na fase 3 (turibulos, velas, coroinhas e o
## sino do toque de recolher; "o veneno do ninho desajusta a carne").
##
## Linha do tempo (s): 0-0.9 o arco dos turibulos aparece; 0.9-7.9 incenso;
## sinos em 6.6, 7.6 e 8.6 (o ultimo pune); fim em 9.2.
##
## - 2 TURIBULOS balancam em arcos fixos (pendulo) e soltam baforadas de
##   incenso que o vento arrasta. As baforadas sao deterministicas: saem de
##   head(te) e derivam com o vento, entao clientes recalculam sem receber listas.
## - O incenso NAO da dano: enche o DESAJUSTE (0..1). Com 0.5 os controles
##   invertem. Em 1.0 vem a COMUNHAO: dano, atordoamento curto, cura a UMBRA.
## - 4 VELAS acesas: a luz apaga o incenso que entra e limpa o desajuste.
## - COROINHAS (ratos) correm para apagar a vela acesa mais perto. Fogem da
##   Geovana quando ela chega perto e morrem com qualquer tiro. Vela apagada
##   reacende se ela ficar ao lado dela.
## - SINO: o ultimo toque fere quem estiver fora da luz, proporcional ao desajuste.

const KIND := "missa"
const DURATION := 9.2
const WARMUP := 0.9
const EMIT_END := 7.9
const TOLLS: Array[float] = [6.6, 7.6, 8.6]
const EMIT := 0.12
const PUFF_LIFE := 3.0
const PUFF_R0 := 24.0
const PUFF_R1 := 46.0
const CENSER_LEN := 235.0
const CENSER_AMP := 0.95
const CANDLE_COUNT := 4
const CANDLE_RING := 255.0
const CANDLE_RADIUS := 78.0
const RELIGHT_RADIUS := 62.0
const RELIGHT_TIME := 0.9
const RAT_FIRST := 1.2
const RAT_EVERY := 1.25
const RAT_SPEED := 150.0
const RAT_FLEE := 125.0
const RAT_HIT := 26.0
const FILL_PER_PUFF := 0.42
const FILL_MAX := 0.9
const CLEANSE := 0.9
const DECAY := 0.1
const INVERT_AT := 0.5
const COMMUNION_DAMAGE := 0.10
const COMMUNION_STUN := 0.5
const COMMUNION_HEAL := 0.015
const BELL_BASE := 0.04
const BELL_SCALE := 0.14


static func create(core: Node, target: Vector2, rng: RandomNumberGenerator) -> Dictionary:
	var world: Vector2 = core.WORLD_SIZE
	var center: Vector2 = target.clamp(Vector2(340, 340), world - Vector2(340, 340))
	var base: float = rng.randf_range(0.0, TAU)
	var censers: Array = []
	for i in range(2):
		var side: Vector2 = Vector2.from_angle(base + PI * float(i) + rng.randf_range(-0.35, 0.35))
		var pivot: Vector2 = center + side * 215.0
		censers.append({
			"pivot": pivot, "len": CENSER_LEN,
			"base": (center - pivot).angle(), "amp": CENSER_AMP,
			"w": 1.55 + 0.35 * float(i), "ph": rng.randf_range(0.0, TAU),
		})
	var candles: Array = []
	var c0: float = base + PI * 0.25
	for i in range(CANDLE_COUNT):
		var p: Vector2 = center + Vector2.from_angle(c0 + TAU * float(i) / float(CANDLE_COUNT)) * CANDLE_RING
		candles.append({"pos": p.clamp(Vector2(90, 90), world - Vector2(90, 90)), "lit": true, "relight": 0.0, "flicker": rng.randf_range(0.0, TAU)})
	return {
		"kind": KIND, "pos": center, "life": DURATION, "max": DURATION,
		"censers": censers, "candles": candles, "rats": [],
		"wind": Vector2.from_angle(rng.randf_range(0.0, TAU)) * 22.0,
		"rat_timer": RAT_FIRST, "rat_side": rng.randf_range(0.0, TAU),
		"desajuste": 0.0, "tolls": 0, "communions": 0, "bell_hit": -1.0,
		"inverted": false, "seed": rng.randi(),
	}


static func elapsed(h: Dictionary) -> float:
	return float(h.get("max", DURATION)) - float(h.get("life", 0.0))


static func censer_head(c: Dictionary, t: float) -> Vector2:
	var grow: float = 1.0 + 0.25 * clampf(t / EMIT_END, 0.0, 1.0)
	var ang: float = float(c["base"]) + float(c["amp"]) * grow * sin(float(c["w"]) * t + float(c["ph"]))
	return Vector2(c["pivot"]) + Vector2.from_angle(ang) * float(c["len"])


## Baforadas vivas no instante t: [{pos, r, age}] (antes das velas apagarem).
static func puffs(h: Dictionary, t: float) -> Array:
	var out: Array = []
	var wind: Vector2 = h.get("wind", Vector2.ZERO)
	var first: int = maxi(0, int(ceil((t - PUFF_LIFE - WARMUP) / EMIT)))
	var last: int = int(floor((minf(t, EMIT_END) - WARMUP) / EMIT))
	for c in Array(h.get("censers", [])):
		for k in range(first, last + 1):
			var te: float = WARMUP + float(k) * EMIT
			var age: float = t - te
			if age < 0.0 or age > PUFF_LIFE:
				continue
			var u: float = age / PUFF_LIFE
			out.append({"pos": censer_head(c, te) + wind * age, "r": lerpf(PUFF_R0, PUFF_R1, u), "age": u})
	return out


static func in_light(h: Dictionary, p: Vector2, extra: float = 0.0) -> bool:
	for c in Array(h.get("candles", [])):
		if bool(c["lit"]) and Vector2(c["pos"]).distance_to(p) <= CANDLE_RADIUS + extra:
			return true
	return false


## Baforadas que a luz das velas ainda nao apagou.
static func live_puffs(h: Dictionary, t: float) -> Array:
	return puffs(h, t).filter(func(p): return not in_light(h, Vector2(p["pos"])))


static func puffs_touching(h: Dictionary, t: float, feet: Vector2) -> int:
	var n := 0
	for p in live_puffs(h, t):
		if feet.distance_to(Vector2(p["pos"])) <= float(p["r"]) + RTUmbraHitbox.FEET_RADIUS:
			n += 1
	return n


# ================================================================ simulacao
static func update(core: Node, h: Dictionary, delta: float) -> void:
	var t: float = elapsed(h)
	var feet: Vector2 = RTUmbraHitbox.feet(core.player_pos)
	_update_candles(core, h, delta, feet)
	_update_rats(core, h, delta, t)
	# Desajuste do jogador local.
	var d: float = float(h.get("desajuste", 0.0))
	var lit: bool = in_light(h, feet)
	if lit:
		d -= CLEANSE * delta
	else:
		var n: int = puffs_touching(h, t, feet) if t >= WARMUP else 0
		d += minf(FILL_MAX, FILL_PER_PUFF * float(n)) * delta if n > 0 else -DECAY * delta
	d = clampf(d, 0.0, 1.0)
	var inverted: bool = d >= INVERT_AT and not core.is_dead
	if inverted:
		core.controls_inverted_timer = maxf(float(core.controls_inverted_timer), 0.15)
		if not bool(h.get("inverted", false)):
			core._add_text("CARNE DESAJUSTADA", core.player_pos + Vector2(0, -70), Color(0.62, 1.0, 0.3), 1.0, 18)
	h["inverted"] = inverted
	if d >= 1.0:
		_communion(core, h)
		d = 0.4
	h["desajuste"] = d
	# Sino do toque de recolher.
	var tolls: int = int(h.get("tolls", 0))
	while tolls < TOLLS.size() and t >= float(TOLLS[tolls]):
		tolls += 1
		_toll(core, h, tolls, feet)
	h["tolls"] = tolls


static func _update_candles(core: Node, h: Dictionary, delta: float, feet: Vector2) -> void:
	for c in Array(h.get("candles", [])):
		if bool(c["lit"]):
			c["relight"] = 0.0
			continue
		if feet.distance_to(Vector2(c["pos"])) <= RELIGHT_RADIUS:
			c["relight"] = float(c["relight"]) + delta / RELIGHT_TIME
			if float(c["relight"]) >= 1.0:
				c["lit"] = true
				c["relight"] = 0.0
				core._add_text("VELA ACESA", Vector2(c["pos"]) + Vector2(0, -60), Color(1.0, 0.86, 0.4), 0.8, 16)
		else:
			c["relight"] = maxf(0.0, float(c["relight"]) - delta)


static func _update_rats(core: Node, h: Dictionary, delta: float, t: float) -> void:
	var rats: Array = h.get("rats", [])
	var candles: Array = h.get("candles", [])
	h["rat_timer"] = float(h.get("rat_timer", RAT_FIRST)) - delta
	if float(h["rat_timer"]) <= 0.0 and t < float(TOLLS[TOLLS.size() - 1]) - 0.4:
		h["rat_timer"] = RAT_EVERY
		var ang: float = float(h.get("rat_side", 0.0)) + float(rats.size() + int(h.get("rats_spawned", 0))) * 2.39996
		h["rats_spawned"] = int(h.get("rats_spawned", 0)) + 1
		var spawn: Vector2 = (Vector2(h["pos"]) + Vector2.from_angle(ang) * 560.0).clamp(Vector2(40, 40), core.WORLD_SIZE - Vector2(40, 40))
		rats.append({"pos": spawn, "phase": ang, "flee": 0.0, "dead": 0.0})
	var feet: Vector2 = RTUmbraHitbox.feet(core.player_pos)
	for r in rats:
		if float(r["dead"]) > 0.0:
			r["dead"] = float(r["dead"]) + delta
			continue
		r["phase"] = float(r["phase"]) + delta * 10.0
		var pos: Vector2 = r["pos"]
		var target := Vector2.INF
		var best := INF
		for c in candles:
			if bool(c["lit"]):
				var dist: float = pos.distance_to(Vector2(c["pos"]))
				if dist < best:
					best = dist
					target = Vector2(c["pos"])
		var to_player: Vector2 = pos - feet
		var dir := Vector2.ZERO
		if to_player.length() < RAT_FLEE:
			dir = to_player.normalized()
			r["flee"] = 0.4
		elif float(r["flee"]) > 0.0:
			r["flee"] = float(r["flee"]) - delta
			dir = to_player.normalized()
		elif target != Vector2.INF:
			dir = (target - pos).normalized()
		pos += dir * RAT_SPEED * (1.25 if float(r["flee"]) > 0.0 else 1.0) * delta
		r["pos"] = pos.clamp(Vector2(20, 20), core.WORLD_SIZE - Vector2(20, 20))
		r["dir"] = dir
		if target != Vector2.INF and Vector2(r["pos"]).distance_to(target) < 18.0:
			for c in candles:
				if Vector2(c["pos"]) == target:
					c["lit"] = false
			r["dead"] = 0.01
			core._add_text("VELA APAGADA", target + Vector2(0, -60), Color(0.6, 0.9, 0.5), 0.8, 16)
	h["rats"] = rats.filter(func(r): return float(r["dead"]) < 0.45)


static func _communion(core: Node, h: Dictionary) -> void:
	h["communions"] = int(h.get("communions", 0)) + 1
	var dmg: int = maxi(1, int(round(float(core.player_hp_max) * COMMUNION_DAMAGE)))
	core._damage_player(dmg, "umbra_missa_comunhao")
	core.player_stun_timer = maxf(float(core.player_stun_timer), core._hostile_control_duration(COMMUNION_STUN))
	core.boss_hp = minf(float(core.boss_hp_max), float(core.boss_hp) + float(core.boss_hp_max) * COMMUNION_HEAL)
	core._add_text("COMUNHÃO", core.player_pos + Vector2(0, -80), Color(0.5, 1.0, 0.35), 1.1, 22)
	core._spawn_radial_particles(core.player_pos, Color(0.45, 1.0, 0.3), 26)
	core._umbra_learn("MIASMA", 0.35)


static func _toll(core: Node, h: Dictionary, n: int, feet: Vector2) -> void:
	core._play_sfx("boss_impact", 0.02, 0.45, 0.55)
	core.screen_shake_timer = maxf(float(core.screen_shake_timer), 0.18)
	core.screen_shake_strength = maxf(float(core.screen_shake_strength), 4.0 + 2.0 * float(n))
	if n < TOLLS.size():
		return
	# Ultimo toque: quem esta fora da luz paga o desajuste.
	if in_light(h, feet):
		h["bell_hit"] = 0.0
		core._add_text("PROTEGIDA PELA LUZ", core.player_pos + Vector2(0, -80), Color(1.0, 0.88, 0.45), 1.0, 18)
		core._umbra_learn("MIASMA", -0.1)
	else:
		var frac: float = BELL_BASE + BELL_SCALE * float(h.get("desajuste", 0.0))
		h["bell_hit"] = frac
		core._damage_player(maxi(1, int(round(float(core.player_hp_max) * frac))), "umbra_missa_sino")
		core._add_text("TOQUE DE RECOLHER", core.player_pos + Vector2(0, -80), Color(0.75, 1.0, 0.4), 1.1, 20)
		core._umbra_learn("MIASMA", 0.12 + 0.3 * float(h.get("desajuste", 0.0)))
	# Aliados remotos: so a luz das velas protege (desajuste deles e desconhecido).
	var net_pos: Vector2 = core.net_player_pos
	if not in_light(h, RTUmbraHitbox.feet(net_pos)):
		core._damage_remote_player_in_radius(net_pos, 4.0, maxi(1, int(round(float(core.player_hp_max) * (BELL_BASE + BELL_SCALE * 0.5)))), "umbra_missa_sino")


## Tiro do jogador: mata coroinhas. Devolve true se acertou algum.
static func bullet_hit(core: Node, pos: Vector2) -> bool:
	for h in core.phase5_hazards:
		if String(h.get("kind", "")) != KIND:
			continue
		for r in Array(h.get("rats", [])):
			if float(r["dead"]) <= 0.0 and Vector2(r["pos"]).distance_to(pos) <= RAT_HIT:
				r["dead"] = 0.01
				core._spawn_radial_particles(Vector2(r["pos"]), Color(0.7, 0.6, 0.5), 8)
				return true
	return false


## Perigo para o bot Apolo (e para quem treina a UMBRA contra ele).
static func danger_at(h: Dictionary, pos: Vector2, forecast: float) -> float:
	var t: float = elapsed(h) + forecast
	var feet: Vector2 = RTUmbraHitbox.feet(pos)
	if in_light(h, feet, -10.0):
		return 0.0
	var danger := 0.0
	for p in live_puffs(h, t):
		var dist: float = feet.distance_to(Vector2(p["pos"]))
		var r: float = float(p["r"]) + 30.0
		if dist < r:
			danger += (1.0 - dist / r) * 260.0
	var bell: float = float(TOLLS[TOLLS.size() - 1])
	if t > bell - 3.0 and t < bell + 0.2:
		danger += 420.0 * clampf((t - (bell - 3.0)) / 3.0, 0.0, 1.0)
	danger += 300.0 * float(h.get("desajuste", 0.0))
	return danger


static func active(core: Node) -> Dictionary:
	for h in core.phase5_hazards:
		if String(h.get("kind", "")) == KIND:
			return h
	return {}
