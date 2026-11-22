class_name RTBaileLagartona
extends RefCounted

## Miniboss da Fase 10 — LAGARTONA DO PAREDAO ("Bonde do Casulo").
## Uma lagarta gigante (a borboleta que ainda nao virou) puxando um trenzinho de
## caixas de som. Ela nao danca: ela E o paredao. So a cabeca leva dano; os
## segmentos sao corpo perigoso durante Trenzinho e Vira-Vira.
##
## Todo ataque: condicao -> aviso -> execucao -> recuperacao, tempos em batidas.
## - TRENZINHO (alvo > 300 px): luzes de chao tracam um S por 1 compasso; ela
##   investe pelo caminho; depois fica OFEGANTE 1 compasso (cabeca +30%).
## - GRAVE PESADO (alvo perto): cada segmento acende 1 batida e solta um cone de
##   grave na batida seguinte; 2 batidas de resfriamento.
## - VIRA-VIRA (a cada 3o ciclo): cauda pisca 1 batida; o corpo da uma volta em
##   circulo em volta de onde o alvo estava; depois fica TONTA 1,5 s (+50%).
## - CASULO (<= 35%, uma vez): 3 s de armadura (20%), segmentos arremessam
##   garrafas no 4; sai com 2 segmentos a menos e 15% mais rapida.

const HP_MULT := 28.0
const POINTS := 1000
const SEGMENTS := 6
const SPACING := 58.0
const SEGMENT_RADIUS := 34.0
const WALK_SPEED := 95.0
const TREM_SPEED := 520.0
const TREM_MIN_DIST := 300.0
const TREM_OVERSHOOT := 260.0
const TREM_SWAY := 90.0
const BODY_DAMAGE := 0.06
const BODY_CD := 0.8
const GRAVE_HALF := deg_to_rad(35.0)
const GRAVE_RANGE := 260.0
const GRAVE_DAMAGE := 0.04
const VIRA_RADIUS := 240.0
const VIRA_BEATS := 8.0
const DAZE_TIME := 1.5
const CASULO_PCT := 0.35
const CASULO_TIME := 3.0
const CASULO_LOST_SEGMENTS := 2
const FAST_FACTOR := 0.87

## O controller e dono desta Lagartona. A referencia forte de volta criava
## um ciclo entre RefCounted e mantinha scripts carregados ao encerrar.
var _baile_ref: WeakRef = null
var baile: RTBaileController:
	get:
		return _baile_ref.get_ref() as RTBaileController if _baile_ref != null else null
var core: Node
var trail: Array = []          # historico da cabeca (mais recente primeiro)
var segments: Array = []       # posicoes dos segmentos (calculadas do rastro)
var path: PackedVector2Array = PackedVector2Array()
var path_i := 0
var lit_seg := -1
var cones: Array = []          # {pos, dir, t}
var vira_center := Vector2.ZERO
var vira_angle := 0.0
var body_cd := 0.0
var state := ""
var seg_count := SEGMENTS


func configure(p_baile: RTBaileController, p_core: Node) -> void:
	_baile_ref = weakref(p_baile)
	core = p_core


func reset() -> void:
	clear()
	seg_count = SEGMENTS
	state = ""


func clear() -> void:
	trail.clear()
	segments.clear()
	path = PackedVector2Array()
	path_i = 0
	lit_seg = -1
	cones.clear()
	body_cd = 0.0


func spawn_stats(damage: float) -> Dictionary:
	return {"hp_mult": HP_MULT, "speed": WALK_SPEED, "damage": damage * 0.9, "points": POINTS}


func on_spawned(enemy: Dictionary) -> void:
	enemy["is_mini_boss"] = true
	enemy["mini_boss"] = true
	enemy["contact_grace"] = 2.0
	enemy["lg_cycle"] = 0
	enemy["lg_cd"] = 1.0
	enemy["lg_casulo_done"] = false
	enemy["lg_fast"] = false
	seg_count = SEGMENTS
	clear()
	var p: Vector2 = enemy["pos"]
	for i in range(SEGMENTS * 10):
		trail.append(p)
	_go(enemy, "entry")


func _go(enemy: Dictionary, s: String) -> void:
	enemy["b10_state"] = s
	enemy["b10_t"] = 0.0
	state = s


func _beats(n: float, enemy: Dictionary) -> float:
	return n * baile.beat.beat_len() * (FAST_FACTOR if bool(enemy.get("lg_fast", false)) else 1.0)


func pct(enemy: Dictionary) -> float:
	return float(enemy.get("hp", 0.0)) / maxf(1.0, float(enemy.get("max_hp", 1.0)))


func update_enemy(enemy: Dictionary, delta: float) -> void:
	body_cd = maxf(0.0, body_cd - delta)
	var t: float = float(enemy.get("b10_t", 0.0))
	var info: Dictionary = baile._info(enemy)
	var dir: Vector2 = info["dir"]
	enemy["facing_dir"] = dir
	if not bool(enemy.get("lg_casulo_done", false)) and pct(enemy) <= CASULO_PCT and state != "entry":
		enemy["lg_casulo_done"] = true
		_go(enemy, "casulo")
		core._add_text("CASULO!", Vector2(enemy["pos"]) + Vector2(0, -110), Color(0.9, 0.9, 0.8), 1.4, 24)
	match state:
		"entry":
			enemy["b10_anim"] = "attack"
			if t >= 2.0:
				_go(enemy, "walk")
		"walk":
			enemy["b10_anim"] = "idle"
			baile.dance_step(enemy, dir, WALK_SPEED * (1.15 if bool(enemy.get("lg_fast", false)) else 1.0), delta, 0.1)
			enemy["lg_cd"] = float(enemy.get("lg_cd", 0.0)) - delta
			if float(enemy["lg_cd"]) <= 0.0 and baile.beat.is_downbeat_event():
				_choose_attack(enemy, info)
		"trem_warn":
			enemy["b10_anim"] = "attack"
			if t >= _beats(4.0, enemy):
				_go(enemy, "trem")
		"trem":
			enemy["b10_anim"] = "attack"
			_update_trem(enemy, delta)
		"ofegante":
			enemy["b10_anim"] = "daze"
			if t >= _beats(4.0, enemy):
				_end(enemy, 1.0)
		"grave":
			enemy["b10_anim"] = "attack"
			_update_grave(enemy, info)
		"cool":
			enemy["b10_anim"] = "idle"
			if t >= _beats(2.0, enemy):
				_end(enemy, 0.8)
		"vira_warn":
			enemy["b10_anim"] = "attack"
			if t >= _beats(1.0, enemy):
				vira_angle = (Vector2(enemy["pos"]) - vira_center).angle()
				_go(enemy, "vira")
		"vira":
			enemy["b10_anim"] = "attack"
			_update_vira(enemy, delta)
		"tonta":
			enemy["b10_anim"] = "daze"
			if t >= DAZE_TIME:
				_end(enemy, 1.0)
		"casulo":
			enemy["b10_anim"] = "casulo"
			if baile.beat.beat_event and baile.beat.bar_beat() == 3 and not segments.is_empty():
				var from: Vector2 = segments[core.rng.randi_range(0, segments.size() - 1)]
				baile.throw_bottle(from, Vector2(info["target"]), RTBaileController.BOTTLE_KINDS[core.rng.randi_range(0, 2)], int(enemy.get("uid", 0)))
			if t >= CASULO_TIME:
				seg_count = maxi(2, seg_count - CASULO_LOST_SEGMENTS)
				enemy["lg_fast"] = true
				core._add_text("SAIU DO CASULO · 150 BPM", Vector2(enemy["pos"]) + Vector2(0, -110), Color(0.6, 1.0, 0.4), 1.6, 22)
				_end(enemy, 0.6)
	_record_trail(Vector2(enemy["pos"]))
	_update_segments()
	_update_body_contact(enemy)
	_update_cones(delta)


func _choose_attack(enemy: Dictionary, info: Dictionary) -> void:
	var cycle: int = int(enemy.get("lg_cycle", 0)) + 1
	enemy["lg_cycle"] = cycle
	if cycle % 3 == 0:
		vira_center = info["target"]
		_go(enemy, "vira_warn")
		return
	if float(info["dist"]) > TREM_MIN_DIST:
		_build_trem_path(Vector2(enemy["pos"]), Vector2(info["target"]))
		_go(enemy, "trem_warn")
		return
	lit_seg = 0
	_go(enemy, "grave")


func _end(enemy: Dictionary, cd: float) -> void:
	enemy["lg_cd"] = cd
	lit_seg = -1
	_go(enemy, "walk")


## Caminho em S (24 pontos) da cabeca ate alem do alvo. Visivel no aviso.
func _build_trem_path(from: Vector2, target: Vector2) -> void:
	var dir: Vector2 = (target - from).normalized()
	var end: Vector2 = target + dir * TREM_OVERSHOOT
	var side: Vector2 = dir.orthogonal()
	path = PackedVector2Array()
	var world: Vector2 = core.WORLD_SIZE
	for i in range(24):
		var u: float = float(i) / 23.0
		var p: Vector2 = from.lerp(end, u) + side * sin(u * TAU) * TREM_SWAY
		path.append(p.clamp(Vector2(60, 60), world - Vector2(60, 60)))
	path_i = 0


func _update_trem(enemy: Dictionary, delta: float) -> void:
	var speed: float = TREM_SPEED / (FAST_FACTOR if bool(enemy.get("lg_fast", false)) else 1.0)
	var step: float = speed * delta
	var pos: Vector2 = enemy["pos"]
	while step > 0.0 and path_i < path.size():
		var goal: Vector2 = path[path_i]
		var d: float = pos.distance_to(goal)
		if d <= step:
			pos = goal
			step -= d
			path_i += 1
		else:
			pos += (goal - pos) / d * step
			step = 0.0
	enemy["pos"] = pos
	if path_i >= path.size():
		path = PackedVector2Array()
		_go(enemy, "ofegante")


func _update_grave(enemy: Dictionary, info: Dictionary) -> void:
	if not baile.beat.beat_event:
		return
	if lit_seg < 0:
		return
	# O segmento aceso na batida anterior dispara agora; o proximo acende.
	if enemy.has("lg_armed"):
		var k: int = int(enemy["lg_armed"])
		if k < segments.size():
			var origin: Vector2 = segments[k]
			var cdir: Vector2 = (Vector2(info["target"]) - origin).normalized()
			cones.append({"pos": origin, "dir": cdir, "t": 0.0})
			for v in baile.viewers():
				if RTUmbraHitbox.body_in_cone(Vector2(v["pos"]), origin, cdir, GRAVE_RANGE, GRAVE_HALF):
					baile.hurt_peer(int(v["peer_id"]), GRAVE_DAMAGE, "lagartona_grave")
		enemy.erase("lg_armed")
	if lit_seg >= mini(seg_count, segments.size()):
		lit_seg = -1
		_go(enemy, "cool")
		return
	enemy["lg_armed"] = lit_seg
	lit_seg += 1


func _update_vira(enemy: Dictionary, delta: float) -> void:
	var omega: float = TAU / _beats(VIRA_BEATS, enemy)
	vira_angle += omega * delta
	var goal: Vector2 = vira_center + Vector2.from_angle(vira_angle) * VIRA_RADIUS
	var pos: Vector2 = Vector2(enemy["pos"]).lerp(goal, clampf(delta * 10.0, 0.0, 1.0))
	enemy["pos"] = pos.clamp(Vector2(60, 60), core.WORLD_SIZE - Vector2(60, 60))
	if float(enemy.get("b10_t", 0.0)) >= _beats(VIRA_BEATS, enemy):
		_go(enemy, "tonta")


func _record_trail(head: Vector2) -> void:
	if trail.is_empty() or head.distance_to(Vector2(trail[0])) > 6.0:
		trail.push_front(head)
		var keep: int = int(SEGMENTS * SPACING / 6.0) + 12
		while trail.size() > keep:
			trail.pop_back()


func _update_segments() -> void:
	segments.clear()
	if trail.is_empty():
		return
	var want := SPACING
	var acc := 0.0
	var prev: Vector2 = trail[0]
	for i in range(1, trail.size()):
		var p: Vector2 = trail[i]
		acc += prev.distance_to(p)
		prev = p
		if acc >= want:
			segments.append(p)
			want += SPACING
			if segments.size() >= seg_count:
				return
	while segments.size() < seg_count:
		segments.append(prev)


func _update_body_contact(enemy: Dictionary) -> void:
	if body_cd > 0.0 or not (state in ["trem", "vira"]):
		return
	for v in baile.viewers():
		for s in segments:
			if RTUmbraHitbox.body_hits_circle(Vector2(v["pos"]), s, SEGMENT_RADIUS):
				body_cd = BODY_CD
				baile.hurt_peer(int(v["peer_id"]), BODY_DAMAGE, "lagartona_trem")
				return


func _update_cones(delta: float) -> void:
	var kept: Array = []
	for c in cones:
		c["t"] = float(c["t"]) + delta
		if float(c["t"]) < 0.35:
			kept.append(c)
	cones = kept


func damage_taken_multiplier(enemy: Dictionary) -> float:
	match String(enemy.get("b10_state", "")):
		"entry":
			return 0.5
		"casulo":
			return 0.2
		"ofegante":
			return 1.3
		"tonta":
			return 1.5
	return 1.0


func contact_blocked(enemy: Dictionary) -> bool:
	return String(enemy.get("b10_state", "")) in ["entry", "casulo"]


func on_defeated(_enemy: Dictionary) -> void:
	clear()
	state = ""


func visual_snapshot() -> Dictionary:
	var seg_pack := PackedFloat32Array()
	for s in segments:
		seg_pack.append_array([Vector2(s).x, Vector2(s).y])
	var cone_pack := PackedFloat32Array()
	for c in cones:
		cone_pack.append_array([Vector2(c["pos"]).x, Vector2(c["pos"]).y, Vector2(c["dir"]).x, Vector2(c["dir"]).y, float(c["t"])])
	return {"segs": seg_pack, "path": path, "pi": path_i, "lit": lit_seg, "cones": cone_pack, "vc": vira_center, "st": state, "n": seg_count}


func apply_remote_visual_snapshot(data: Dictionary) -> void:
	if data.is_empty():
		return
	var sp = data.get("segs", PackedFloat32Array())
	if sp is PackedFloat32Array:
		segments.clear()
		for o in range(0, sp.size() - 1, 2):
			segments.append(Vector2(sp[o], sp[o + 1]))
	var pth = data.get("path", PackedVector2Array())
	if pth is PackedVector2Array:
		path = pth
	path_i = int(data.get("pi", path_i))
	lit_seg = int(data.get("lit", lit_seg))
	vira_center = Vector2(data.get("vc", vira_center))
	state = String(data.get("st", state))
	seg_count = int(data.get("n", seg_count))
	var cp = data.get("cones", PackedFloat32Array())
	if cp is PackedFloat32Array:
		cones.clear()
		for o in range(0, cp.size() - 4, 5):
			cones.append({"pos": Vector2(cp[o], cp[o + 1]), "dir": Vector2(cp[o + 2], cp[o + 3]), "t": cp[o + 4]})


func update_replica(delta: float) -> void:
	_update_cones(delta)
