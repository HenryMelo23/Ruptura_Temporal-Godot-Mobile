class_name RTUmbraPhaseObserver
extends RefCounted

## A UMBRA observa o jogador nas fases antes dela. Sempre que um projetil
## inimigo vem na direcao do jogador, mede a resposta no 1,1 s seguinte:
##   - along: quanto ele mantem a corrida (1 = segue reto, 0 = freia/recua)
##   - side : para que lado da corrida ele desvia (-1 esquerda, +1 direita)
##   - dash : se responde com teleporte
## Esses numeros viram priors do Eco Profetico e do Rebobinar, e ao fim de
## cada fase aparece uma licao curta ("A UMBRA OBSERVOU: ...").
## So no solo; leve (amostra a cada 0,1 s, olha no maximo 40 projeteis).

const SAMPLE_DT := 0.1
const PROBE_TIME := 1.1
const PROBE_COOLDOWN := 1.4
const THREAT_RADIUS := 230.0
const SIDE_SCALE := 150.0
const MAX_BULLETS_SCAN := 40

var core: Node = null
var sample_timer := 0.0
var cooldown := 0.0
var history: Array[Vector2] = []
var probe: Dictionary = {}
## Agregado da run: {along: [soma, n], side: [soma, n], dash: [soma, n]}
var stats: Dictionary = {}
## Licoes mostradas: [{phase, key, text}]
var lessons: Array[Dictionary] = []
var pending_text := ""
var pending_timer := 0.0


func configure(runtime_core: Node) -> void:
	core = runtime_core
	reset_run()


func reset_run() -> void:
	sample_timer = 0.0
	cooldown = 0.0
	history.clear()
	probe.clear()
	stats = {"along": [0.0, 0], "side": [0.0, 0], "dash": [0.0, 0]}
	lessons.clear()


func update(delta: float) -> void:
	if core == null or bool(core.is_multiplayer) or String(core.mode) != "game":
		return
	if pending_timer > 0.0:
		pending_timer -= delta
		if pending_timer <= 0.0 and pending_text != "":
			var at: Vector2 = Vector2(core.player_pos)
			core._add_text("A UMBRA OBSERVOU", at + Vector2(-110, -150), Color(0.55, 1.0, 0.68), 3.2, 20)
			core._add_text(pending_text, at + Vector2(-210, -122), Color(0.86, 0.95, 0.9), 3.2, 16)
			pending_text = ""
	if int(core.current_phase) == 5:
		return
	sample_timer -= delta
	cooldown = maxf(0.0, cooldown - delta)
	if sample_timer > 0.0:
		return
	sample_timer = SAMPLE_DT
	history.append(Vector2(core.player_pos))
	if history.size() > 12:
		history.pop_front()
	if not probe.is_empty():
		if float(core.time_alive) - float(probe["t"]) >= PROBE_TIME:
			_close_probe()
		return
	if cooldown > 0.0 or history.size() < 4:
		return
	if _threat_incoming():
		var vel: Vector2 = RTUmbraAim.history_velocity(history, core.player_pos)
		probe = {"t": float(core.time_alive), "origin": Vector2(core.player_pos), "vel": vel, "dash": float(core.last_dash_time)}


func _threat_incoming() -> bool:
	var p: Vector2 = core.player_pos
	var scanned := 0
	for b in core.enemy_bullets:
		scanned += 1
		if scanned > MAX_BULLETS_SCAN:
			break
		var bp: Vector2 = Vector2(b.get("pos", Vector2.INF))
		if bp.distance_squared_to(p) > THREAT_RADIUS * THREAT_RADIUS:
			continue
		var to_player: Vector2 = (p - bp).normalized()
		if Vector2(b.get("dir", Vector2.ZERO)).normalized().dot(to_player) > 0.8:
			return true
	return false


func _close_probe() -> void:
	var origin: Vector2 = probe["origin"]
	var vel: Vector2 = probe["vel"]
	var actual: Vector2 = Vector2(core.player_pos) - origin
	var dashed: bool = float(core.last_dash_time) > float(probe["dash"])
	probe.clear()
	cooldown = PROBE_COOLDOWN
	_add("dash", 1.0 if dashed else 0.0)
	if dashed:
		return  # teleporte distorce along/side
	if vel.length() > 40.0:
		var dir: Vector2 = vel.normalized()
		_add("along", clampf(actual.dot(dir) / maxf(1.0, vel.length() * PROBE_TIME), 0.0, 1.4))
		_add("side", clampf(actual.dot(dir.orthogonal()) / SIDE_SCALE, -1.0, 1.0))


func _add(key: String, value: float) -> void:
	var e: Array = stats[key]
	e[0] = float(e[0]) + value
	e[1] = int(e[1]) + 1


func mean(key: String, fallback: float) -> float:
	var e: Array = stats.get(key, [0.0, 0])
	return float(e[0]) / float(e[1]) if int(e[1]) > 0 else fallback


func samples(key: String) -> int:
	return int(Array(stats.get(key, [0.0, 0]))[1])


## Priors para o kit base: {chave: [valor, amostras]}.
func priors() -> Dictionary:
	var out: Dictionary = {}
	if samples("along") >= 3:
		out["eco_along"] = [mean("along", 0.85), samples("along")]
	if samples("side") >= 3:
		out["eco_side"] = [mean("side", 0.0), samples("side")]
	if samples("dash") >= 3:
		# Quem teleporta ao ver perigo tende a fugir do Rebobinar.
		out["rewind_escape"] = [clampf(mean("dash", 0.35) * 1.2, 0.0, 1.0), samples("dash")]
	return out


## Agenda a licao para aparecer logo depois da troca de fase.
func queue_lesson(phase: int) -> void:
	var text: String = on_phase_completed(phase)
	if text != "":
		pending_text = text
		pending_timer = 1.6


## Licao da fase que acabou (uma categoria por fase, em rodizio).
func on_phase_completed(phase: int) -> String:
	if phase == 5 or bool(core.is_multiplayer):
		return ""
	var order: Array[String] = ["side", "along", "dash"]
	var text := ""
	for k in range(order.size()):
		var key: String = order[(lessons.size() + k) % order.size()]
		if samples(key) < 3:
			continue
		text = _lesson_text(key)
		lessons.append({"phase": phase, "key": key, "text": text})
		break
	if text == "":
		text = "Ainda estou te estudando..."
	return text


func _lesson_text(key: String) -> String:
	match key:
		"side":
			var s: float = mean("side", 0.0)
			if s > 0.22:
				return "Voce desvia para a DIREITA da sua corrida."
			if s < -0.22:
				return "Voce desvia para a ESQUERDA da sua corrida."
			return "Seus desvios nao tem lado preferido."
		"along":
			var a: float = mean("along", 0.85)
			if a > 0.95:
				return "Voce mantem a direcao quando o perigo vem."
			if a < 0.5:
				return "Voce freia diante do perigo."
			return "Voce corta a corrida pela metade ao ver um tiro."
		"dash":
			return "Voce responde ao perigo com teleporte %d%% das vezes." % int(round(mean("dash", 0.0) * 100.0))
	return ""


func save_state() -> Dictionary:
	return {"stats": stats.duplicate(true), "lessons": lessons.duplicate(true)}


func load_state(data: Dictionary) -> void:
	stats = Dictionary(data.get("stats", stats)).duplicate(true)
	lessons.clear()
	for l in Array(data.get("lessons", [])):
		lessons.append(Dictionary(l))
