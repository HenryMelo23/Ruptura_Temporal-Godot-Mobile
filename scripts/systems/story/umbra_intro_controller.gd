class_name RTUmbraIntro
extends RefCounted

## Cena de chegada da UMBRA (Mente da Umbra, fase 5). Roda no modo "umbra_intro":
## o mundo para, os controles travam e este diretor conduz camera, atores, baloes,
## efeitos e o desvio dos meteoros (QTE). No fim a UMBRA vira o chefe, ali mesmo.
##
## Roteiro:
##  1. a camera vai para a direita; um portal rasga e GEO231 (outra Geovana, ferida)
##     sai correndo e cai: "CORRA! ELA ESTA VINDO!" / "QUEM?!"
##  2. estrondo (como o transmutar): a UMBRA aparece e persegue GEO231, dispara uma
##     rajada, GEO231 e apagada e a energia dela voa ate a UMBRA, que absorve
##  3. a UMBRA se vira e conversa com a nossa Geovana (a resposta final dela muda a
##     cada run, entre 5 frases sobre o que e amar alguem)
##  4. a UMBRA invoca um meteoro; o tempo se arrasta e o jogador desvia de 4 meteoros
##     apertando a direcao mostrada (seta, WASD, direcional ou toque/arrasto)
##  5. a camera enquadra as duas e a batalha comeca
##
## Sem a arte do Codex, GEO231 usa os sprites da Geovana tingidos e o meteoro e
## desenhado na hora (RTUmbraIntroPresentation).

const MODE := "umbra_intro"
const SEEN_KEY := "umbra_intro"
const REPLY_KEY := "umbra_intro_reply"
const TYPE_CPS := 40.0
const QTE_COUNT := 4
const QTE_WINDOWS := [1.6, 1.3, 1.15, 1.0]
const QTE_DODGE := 150.0
const QTE_DODGE_TIME := 0.2
## Errar o desvio custa caro: ~22% da vida maxima por meteoro (nunca mata: piso 1 HP).
const QTE_FAIL_DAMAGE := 0.22
const SKIP_HOLD := 0.9
const DIRS := {"up": Vector2.UP, "down": Vector2.DOWN, "left": Vector2.LEFT, "right": Vector2.RIGHT}

## Cinco respostas da Geovana: uma por run, em rodizio.
const REPLIES := [
	"Amar não é justo. É ficar quando tudo manda ir embora.",
	"Se o preço do amor fosse pequeno, ninguém chamaria isso de amor.",
	"Você parou de sentir a dor. Eu ainda sinto. É por isso que eu ainda amo.",
	"Ele me amou em todas as realidades. Eu vou amar em todas que eu precisar atravessar.",
	"Amar alguém é escolher essa pessoa de novo, todo dia. Até contra o universo.",
]

var core: Node
var active: bool = false
var done_this_phase: bool = false
var beats: Array = []
var beat: int = 0
var t: float = 0.0
var clock: float = 0.0
var reply_index: int = 0
var can_skip: bool = false
var skip_hold: float = 0.0
var skip_pressed: bool = false
var trigger_wait: float = 0.0

# Lugares (definidos no start a partir da posicao da Geovana)
var origin := Vector2.ZERO
var portal_pos := Vector2.ZERO
var geo_stop := Vector2.ZERO
var umbra_stop := Vector2.ZERO

# Camera
var cam := Vector2.ZERO
var cam_from := Vector2.ZERO
var cam_to := Vector2.ZERO
var zoom_punch: float = 0.0

# Atores
var geo := {"pos": Vector2.ZERO, "anim": "hidden", "t": 0.0, "alpha": 1.0, "erase": 0.0}
var umbra := {"pos": Vector2.ZERO, "anim": "hidden", "t": 0.0, "alpha": 0.0, "facing": -1.0}
var hero_pose: String = ""
var hero_pose_t: float = 0.0

# Efeitos
var portal_open: float = 0.0
var letterbox: float = 0.0
var flash: float = 0.0
var flash_color := Color.WHITE
var shake: float = 0.0
var slow: float = 0.0
var rings: Array = []
var sparks: Array = []
var beam := {}
var wisp := {}
var title: float = 0.0

# Balao atual
var balloon := {}

# QTE
var meteors: Array = []
var qte_index: int = -1
var qte := {}
var qte_hits: int = 0
var qte_dodges: int = 0
var dodge := {}


func configure(p_core: Node) -> void:
	core = p_core


# ================================================================ disparo
func reset_for_phase() -> void:
	active = false
	done_this_phase = false
	trigger_wait = 0.0


## Chamado a cada quadro do modo "game". Na fase 5 nao ha inimigos comuns nem mini
## chefe: assim que a fase assenta, ou toca a cena (solo, Geovana) ou o chefe e
## chamado direto (multiplayer, Henry).
func tick_trigger(delta: float) -> void:
	if core == null or int(core.current_phase) != 5 or done_this_phase or active:
		return
	if core.boss_active or core.boss_dead or float(core.boss_call_timer) >= 0.0:
		return
	if core.mode != "game" or core._dialogue().busy() or not core._story().queue.is_empty() or core._player_start_down_active():
		trigger_wait = 0.0
		return
	trigger_wait += delta
	if trigger_wait < 0.9:
		return
	done_this_phase = true
	if plays_cutscene():
		start()
		return
	if not core._is_world_authority():
		return
	core.experimental_boss_altar_authorized = true
	core.experimental_boss_altar_used = true
	if core.is_multiplayer:
		core._begin_boss_call_for_all()
	else:
		core._start_boss_call_local()


## Scripts automatizados (treino da UMBRA, testes) desligam as cenas de historia:
## nesses casos a fase tambem pula direto para o chefe, sem travar.
func plays_cutscene() -> bool:
	return core._story().enabled and not core.dedicated_server_mode and not core.is_multiplayer \
		and String(core.active_character_key) != String(core.CHARACTER_HENRY) and not core.experimental_phase_active


func _seen() -> bool:
	return bool(core._story().seen.get(SEEN_KEY, false))


# ================================================================ inicio / fim
func start() -> void:
	active = true
	clock = 0.0
	beat = 0
	t = 0.0
	can_skip = _seen()
	skip_hold = 0.0
	reply_index = int(core._story().seen.get(REPLY_KEY, 0)) % REPLIES.size()
	origin = core.player_pos
	var world: Vector2 = core.WORLD_SIZE
	portal_pos = (origin + Vector2(640, -10)).clamp(Vector2(200, 200), world - Vector2(200, 200))
	geo_stop = origin.lerp(portal_pos, 0.47) + Vector2(0, 8)
	umbra_stop = geo_stop + (portal_pos - geo_stop) * 0.62 + Vector2(0, -40)
	cam = origin
	cam_from = origin
	cam_to = origin
	geo = {"pos": portal_pos, "anim": "hidden", "t": 0.0, "alpha": 1.0, "erase": 0.0}
	umbra = {"pos": portal_pos + Vector2(0, -30), "anim": "hidden", "t": 0.0, "alpha": 0.0, "facing": -1.0}
	hero_pose = ""
	portal_open = 0.0
	letterbox = 0.0
	flash = 0.0
	shake = 0.0
	slow = 0.0
	rings.clear()
	sparks.clear()
	beam = {}
	wisp = {}
	balloon = {}
	meteors.clear()
	qte = {}
	qte_index = -1
	qte_hits = 0
	qte_dodges = 0
	dodge = {}
	title = 0.0
	core.last_facing = Vector2.RIGHT
	# A queda de entrada da Geovana precisa ter terminado (o modo da cena congela o resto).
	core.henry_entry_timer = 0.0
	core.player_start_down_fall_timer = 0.0
	core.player_start_down_landing_timer = 0.0
	core.experimental_boss_altar_authorized = true
	core.experimental_boss_altar_used = true
	core._clear_attack_lock()
	beats = _script()
	core.mode = MODE
	core._block_ui_input(300)
	_enter_beat()


func _script() -> Array:
	return [
		{"k": "letterbox", "t": 0.7},
		{"k": "pan", "to": "portal", "t": 1.5},
		{"k": "portal", "t": 1.0},
		{"k": "geo_run", "t": 1.25},
		{"k": "geo_fall", "t": 0.7},
		{"k": "pan", "to": "mid", "t": 0.7},
		{"k": "say", "who": "geo231", "text": "CORRA! ELA ESTÁ VINDO!", "loud": true},
		{"k": "say", "who": "geovana", "text": "QUEM?!", "pose": "susto"},
		{"k": "boom", "t": 1.4},
		{"k": "chase", "t": 1.0},
		{"k": "charge", "t": 0.9},
		{"k": "blast", "t": 0.55},
		{"k": "erase", "t": 1.7},
		{"k": "absorb", "t": 1.5},
		{"k": "turn", "t": 0.6},
		{"k": "pan", "to": "duel", "t": 0.8},
		{"k": "say", "who": "umbra", "text": "Você é mais uma com a ilusão de trazê-lo de volta?"},
		{"k": "say", "who": "geovana", "text": "Não é ilusão. Custe o que custar...", "pose": "firme"},
		{"k": "laugh", "t": 1.4},
		{"k": "say", "who": "umbra", "text": "Você acha mesmo justo o universo pagar o preço do nosso egoísmo? Eu já senti a sua dor.", "anim": "risada"},
		{"k": "say", "who": "umbra", "text": "Eu ofereço a todas as nossas versões a chance de desistir e seguir uma vida comum. Mas, por mais que eu tente ajudar, vocês nunca aprendem."},
		{"k": "say", "who": "umbra", "text": "Então parei de oferecer misericórdia. Agora eu ofereço um fim rápido, que não custe ainda mais dor."},
		{"k": "say", "who": "geovana", "text": REPLIES[reply_index], "pose": "firme", "big": true},
		{"k": "say", "who": "umbra", "text": "Então carregue esse amor... até ele te esmagar."},
		{"k": "summon", "t": 1.7},
		{"k": "qte"},
		{"k": "aftermath", "t": 1.1},
		{"k": "pan", "to": "battle", "t": 0.9},
		{"k": "title", "t": 1.7},
		{"k": "finish"},
	]


func _finish(skipped: bool = false) -> void:
	if not active:
		return
	active = false
	balloon = {}
	if not skipped:
		core._story().seen[SEEN_KEY] = true
		core._story().seen[REPLY_KEY] = (reply_index + 1) % REPLIES.size()
		core._story()._save()
	var umbra_pos: Vector2 = Vector2(umbra["pos"]) if String(umbra["anim"]) != "hidden" else umbra_stop
	core.mode = "game"
	core.boss_ready = true
	core.experimental_boss_altar_authorized = true
	core.experimental_boss_altar_used = true
	core.boss_call_timer = 0.0
	core._update_boss_call(0.0)
	core.boss_pos = umbra_pos
	core.boss_entry_timer = 0.0
	core.camera_follow_center = cam
	core.camera_follow_initialized = true
	core.screen_shake_timer = 0.0
	core._block_ui_input(250)
	if qte_dodges == QTE_COUNT:
		core._add_text("LEITURA PERFEITA", core.player_pos + Vector2(0, -120), Color(0.6, 1.0, 0.9), 1.6, 24)


func skip() -> void:
	if not active:
		return
	core.player_pos = origin
	umbra["pos"] = umbra_stop
	umbra["anim"] = "idle"
	cam = origin.lerp(umbra_stop, 0.5)
	_finish(true)


# ================================================================ atualizacao
func update(delta: float) -> void:
	if not active:
		return
	clock += delta
	t += delta
	geo["t"] = float(geo["t"]) + delta
	umbra["t"] = float(umbra["t"]) + delta
	hero_pose_t += delta
	flash = maxf(0.0, flash - delta * 2.4)
	shake = maxf(0.0, shake - delta * 2.0)
	zoom_punch = maxf(0.0, zoom_punch - delta * 1.5)
	if title > 0.0 and beats[beat].get("k", "") != "title":
		title = maxf(0.0, title - delta)
	core.screen_shake_timer = shake * 0.4
	core.screen_shake_strength = 14.0 * shake
	core.damage_flash_timer = maxf(0.0, float(core.damage_flash_timer) - delta)
	_update_fx(delta)
	_update_skip(delta)
	if not active:
		return
	_update_beat(delta)
	core._update_effects(delta)


func _update_skip(delta: float) -> void:
	if not can_skip:
		return
	if skip_pressed or Input.is_key_pressed(KEY_ESCAPE):
		skip_hold += delta
		if skip_hold >= SKIP_HOLD:
			skip()
	else:
		skip_hold = maxf(0.0, skip_hold - delta * 2.0)


func _cam_point(name: String) -> Vector2:
	match name:
		"portal":
			return portal_pos + Vector2(-90, 0)
		"mid":
			return origin.lerp(geo_stop, 0.55)
		"duel", "battle":
			return origin.lerp(Vector2(umbra["pos"]), 0.5)
	return origin


func _enter_beat() -> void:
	t = 0.0
	if beat >= beats.size():
		_finish()
		return
	var b: Dictionary = beats[beat]
	match String(b.get("k", "")):
		"pan":
			cam_from = cam
			cam_to = _cam_point(String(b.get("to", "")))
		"portal":
			_ring(portal_pos, Color(0.7, 0.4, 1.0), 120.0, 0.6)
			core._play_sfx("boss_impact", 0.03, 0.45, 1.3)
		"geo_run":
			geo["anim"] = "run"
			geo["t"] = 0.0
			geo["pos"] = portal_pos
		"geo_fall":
			geo["anim"] = "fall"
			geo["t"] = 0.0
		"say":
			balloon = {"who": String(b.get("who", "")), "text": String(b.get("text", "")), "shown": 0.0, "hold": 0.0, "loud": bool(b.get("loud", false)), "big": bool(b.get("big", false))}
			if b.has("pose"):
				hero_pose = String(b["pose"])
				hero_pose_t = 0.0
			if String(b.get("who", "")) == "geo231":
				geo["anim"] = "shout"
			if b.has("anim") and String(b.get("who", "")) == "umbra":
				umbra["anim"] = String(b["anim"])
				umbra["t"] = 0.0
			elif String(b.get("who", "")) == "umbra":
				umbra["anim"] = "idle"
		"boom":
			umbra["anim"] = "transmutar"
			umbra["t"] = 0.0
			umbra["alpha"] = 0.0
			umbra["pos"] = portal_pos + Vector2(10, -30)
			umbra["facing"] = -1.0
			flash = 1.0
			flash_color = Color(0.85, 1.0, 0.9)
			shake = 1.0
			zoom_punch = 1.0
			_ring(portal_pos, Color(0.36, 1.0, 0.56), 420.0, 0.9)
			_ring(portal_pos, Color(0.7, 0.4, 1.0), 260.0, 0.6)
			core._play_sfx("boss_impact", 0.0, 1.0, 0.7)
			core._vibrate(220, 0.8)
			geo["anim"] = "kneel"
		"chase":
			umbra["anim"] = "idle"
		"charge":
			umbra["anim"] = "conjurar"
			umbra["t"] = 0.0
		"blast":
			umbra["anim"] = "ataque"
			umbra["t"] = 0.0
			beam = {"from": _umbra_hand(), "to": Vector2(geo["pos"]) + Vector2(0, -30), "t": 0.0}
			geo["anim"] = "hit"
			geo["t"] = 0.0
			flash = 0.8
			flash_color = Color(0.86, 0.6, 1.0)
			shake = 0.8
			core._play_sfx("boss_impact", 0.0, 0.9, 1.1)
			core._vibrate(160, 0.7)
		"erase":
			geo["anim"] = "erase"
			geo["t"] = 0.0
			beam = {}
		"absorb":
			umbra["anim"] = "sifao"
			umbra["t"] = 0.0
			wisp = {"from": Vector2(geo["pos"]) + Vector2(0, -36), "to": Vector2(umbra["pos"]) + Vector2(0, -40), "t": 0.0}
		"turn":
			umbra["anim"] = "idle"
			umbra["facing"] = -1.0
			hero_pose = ""
		"laugh":
			umbra["anim"] = "risada"
			umbra["t"] = 0.0
			balloon = {"who": "umbra", "text": "Ahahahaha!", "shown": 99.0, "hold": 0.0, "loud": true, "auto": true}
		"summon":
			umbra["anim"] = "invocar"
			umbra["t"] = 0.0
			hero_pose = ""
			_build_meteors()
		"qte":
			_next_meteor()
		"aftermath":
			slow = 0.0
			hero_pose = "firme"
		"title":
			title = 1.7
			cam_from = cam
			cam_to = _cam_point("battle")
		"finish":
			_finish()


func _next_beat() -> void:
	beat += 1
	balloon = {}
	_enter_beat()


func _update_beat(delta: float) -> void:
	if beat >= beats.size():
		return
	var b: Dictionary = beats[beat]
	var dur: float = float(b.get("t", 0.0))
	var k: float = clampf(t / maxf(0.001, dur), 0.0, 1.0)
	match String(b.get("k", "")):
		"letterbox":
			letterbox = k
		"pan":
			cam = cam_from.lerp(cam_to, _ease(k))
		"portal":
			portal_open = _ease(k)
			if randf() < 0.5:
				_spark(portal_pos + Vector2(randf_range(-40, 40), randf_range(-90, 70)), Color(0.75, 0.45, 1.0))
		"geo_run":
			geo["pos"] = portal_pos.lerp(geo_stop, k)
			if randf() < 0.3:
				_spark(Vector2(geo["pos"]) + Vector2(10, -20), Color(0.9, 0.2, 0.3))
		"geo_fall":
			if k >= 1.0:
				geo["anim"] = "kneel"
		"say":
			_update_balloon(delta)
			if bool(balloon.get("done", false)):
				_next_beat()
				return
		"boom":
			umbra["alpha"] = clampf(t / 0.6, 0.0, 1.0)
			portal_open = 1.0 - clampf((t - 0.5) / 0.6, 0.0, 1.0)
		"chase":
			umbra["pos"] = (portal_pos + Vector2(10, -30)).lerp(umbra_stop, _ease(k))
		"charge":
			if randf() < 0.8:
				var hand := _umbra_hand()
				_spark(hand + Vector2.from_angle(randf() * TAU) * 40.0, Color(0.6, 1.0, 0.7), hand)
		"blast":
			if not beam.is_empty():
				beam["t"] = t
		"erase":
			geo["erase"] = k
			if randf() < 0.9:
				_spark(Vector2(geo["pos"]) + Vector2(randf_range(-22, 22), randf_range(-70, 0)), Color(0.55, 0.95, 1.0))
		"absorb":
			if not wisp.is_empty():
				wisp["t"] = k
			if k >= 1.0 and not wisp.is_empty():
				wisp = {}
				flash = 0.5
				flash_color = Color(0.5, 1.0, 0.7)
				_ring(Vector2(umbra["pos"]) + Vector2(0, -40), Color(0.4, 1.0, 0.6), 160.0, 0.5)
				geo["anim"] = "hidden"
		"turn":
			cam = cam.lerp(_cam_point("duel"), clampf(delta * 3.0, 0.0, 1.0))
		"laugh":
			_update_balloon(delta)
		"summon":
			slow = clampf(t / dur, 0.0, 1.0) * 0.8
		"qte":
			cam = cam.lerp(core.player_pos.lerp(Vector2(umbra["pos"]), 0.4), clampf(delta * 2.5, 0.0, 1.0))
			_update_qte(delta)
			return
		"title":
			cam = cam_from.lerp(cam_to, _ease(k))
			letterbox = 1.0 - k
	if dur > 0.0 and t >= dur:
		_next_beat()


func _update_balloon(delta: float) -> void:
	if balloon.is_empty():
		return
	var text: String = String(balloon.get("text", ""))
	balloon["shown"] = float(balloon["shown"]) + delta * TYPE_CPS
	if float(balloon["shown"]) >= float(text.length()):
		# Igual ao Mercador: a fala NUNCA avanca sozinha, so com toque, clique,
		# tecla ou botao (advance_balloon). "hold" so serve de carencia para o
		# toque que completou o texto nao pular a fala junto.
		balloon["hold"] = float(balloon["hold"]) + delta


## Toque / clique / tecla: completa o texto ou avanca a fala.
func advance_balloon() -> void:
	if balloon.is_empty() or bool(balloon.get("auto", false)):
		return
	var text: String = String(balloon.get("text", ""))
	if float(balloon["shown"]) < float(text.length()):
		balloon["shown"] = float(text.length())
	elif float(balloon["hold"]) > 0.15:
		balloon["done"] = true


func balloon_visible_text() -> String:
	var text: String = String(balloon.get("text", ""))
	return text.substr(0, int(float(balloon.get("shown", 0.0))))


func _ease(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)


func _umbra_hand() -> Vector2:
	return Vector2(umbra["pos"]) + Vector2(46.0 * float(umbra["facing"]), -70.0)


# ================================================================ efeitos
func _ring(pos: Vector2, color: Color, radius: float, life: float) -> void:
	rings.append({"pos": pos, "color": color, "max": radius, "life": life, "t": 0.0})


func _spark(pos: Vector2, color: Color, target: Vector2 = Vector2.INF) -> void:
	var vel := Vector2(randf_range(-40, 40), randf_range(-120, -30))
	if target != Vector2.INF:
		vel = (target - pos) * 3.0
	sparks.append({"pos": pos, "vel": vel, "color": color, "life": 0.6, "t": 0.0})


func _update_fx(delta: float) -> void:
	var kept: Array = []
	for r in rings:
		r["t"] = float(r["t"]) + delta
		if float(r["t"]) < float(r["life"]):
			kept.append(r)
	rings = kept
	kept = []
	for s in sparks:
		s["t"] = float(s["t"]) + delta
		s["pos"] = Vector2(s["pos"]) + Vector2(s["vel"]) * delta
		if float(s["t"]) < float(s["life"]):
			kept.append(s)
	sparks = kept
	if not dodge.is_empty():
		dodge["t"] = float(dodge["t"]) + delta
		var k: float = clampf(float(dodge["t"]) / QTE_DODGE_TIME, 0.0, 1.0)
		core.player_pos = Vector2(dodge["from"]).lerp(Vector2(dodge["to"]), 1.0 - pow(1.0 - k, 3.0))
		if k >= 1.0:
			dodge = {}
	for m in meteors:
		if bool(m.get("impact", false)):
			m["boom"] = float(m.get("boom", 0.0)) + delta


# ================================================================ meteoros (QTE)
func _build_meteors() -> void:
	meteors.clear()
	for i in range(QTE_COUNT):
		meteors.append({"target": core.player_pos, "h": 1.0, "dir": "", "impact": false, "boom": 0.0, "big": i == 0 or i == QTE_COUNT - 1, "result": ""})
	# O primeiro e o meteoro invocado: ja aparece la no alto, caindo devagar.
	meteors[0]["h"] = 1.0


func _pick_dir(_previous: String) -> String:
	# Sorteio livre entre as 4 direcoes (pode repetir); so evita sair do mundo
	# ou mergulhar dentro da UMBRA. A camera acompanha a Geovana no QTE.
	var options: Array = []
	for name in DIRS.keys():
		var dest: Vector2 = core.player_pos + Vector2(DIRS[name]) * QTE_DODGE
		if dest.distance_to(Vector2(umbra["pos"])) < 150.0:
			continue
		if dest.x < 120.0 or dest.y < 140.0 or dest.x > core.WORLD_SIZE.x - 120.0 or dest.y > core.WORLD_SIZE.y - 120.0:
			continue
		options.append(name)
	if options.is_empty():
		options = DIRS.keys()
	return String(options[randi() % options.size()])


func _next_meteor() -> void:
	qte_index += 1
	if qte_index >= meteors.size():
		_next_beat()
		return
	var m: Dictionary = meteors[qte_index]
	m["target"] = core.player_pos
	var previous: String = String(meteors[qte_index - 1]["dir"]) if qte_index > 0 else ""
	m["dir"] = _pick_dir(previous)
	qte = {"t": 0.0, "window": float(QTE_WINDOWS[mini(qte_index, QTE_WINDOWS.size() - 1)]), "state": "wait", "after": 0.0}
	slow = 0.85


func _update_qte(delta: float) -> void:
	if qte.is_empty():
		return
	var m: Dictionary = meteors[qte_index]
	qte["t"] = float(qte["t"]) + delta
	match String(qte["state"]):
		"wait":
			# O tempo se arrasta: o meteoro desce bem devagar enquanto a seta espera.
			m["h"] = maxf(0.18, 1.0 - float(qte["t"]) / float(qte["window"]) * 0.82)
			if float(qte["t"]) >= float(qte["window"]):
				_resolve(false)
		"after":
			# Salto no tempo: o meteoro termina a queda de uma vez.
			qte["after"] = float(qte["after"]) + delta
			m["h"] = maxf(0.0, float(m["h"]) - delta * 7.0)
			if float(m["h"]) <= 0.0 and not bool(m["impact"]):
				_impact(m)
			if float(qte["after"]) >= 0.55:
				qte = {}
				_next_meteor()


func qte_waiting() -> bool:
	return not qte.is_empty() and String(qte.get("state", "")) == "wait"


func qte_dir() -> String:
	if qte_index < 0 or qte_index >= meteors.size():
		return ""
	return String(meteors[qte_index]["dir"])


func qte_progress() -> float:
	if qte.is_empty():
		return 0.0
	return clampf(float(qte["t"]) / float(qte["window"]), 0.0, 1.0)


func press(dir_name: String) -> void:
	if not qte_waiting():
		return
	_resolve(dir_name == qte_dir())


func _resolve(success: bool) -> void:
	var m: Dictionary = meteors[qte_index]
	m["result"] = "ok" if success else "hit"
	qte["state"] = "after"
	qte["after"] = 0.0
	slow = 0.0
	flash = 0.35
	flash_color = Color(1, 1, 1)
	if success:
		qte_dodges += 1
		var dir: Vector2 = DIRS[String(m["dir"])]
		dodge = {"from": core.player_pos, "to": core._clamp_player_world(core.player_pos + dir * QTE_DODGE), "t": 0.0}
		core.last_facing = dir if absf(dir.x) > 0.0 else core.last_facing
		hero_pose = "esquiva"
		hero_pose_t = 0.0
		core._add_text("DESVIOU!", core.player_pos + Vector2(0, -96), Color(0.6, 1.0, 0.9), 0.7, 22)
	else:
		qte_hits += 1


func _impact(m: Dictionary) -> void:
	m["impact"] = true
	m["boom"] = 0.0
	var pos: Vector2 = m["target"]
	shake = 1.0 if bool(m["big"]) else 0.7
	_ring(pos, Color(1.0, 0.6, 0.2), 200.0 if bool(m["big"]) else 140.0, 0.5)
	core._spawn_radial_particles(pos, Color(1.0, 0.5, 0.15), 26)
	core._play_sfx("boss_impact", 0.03, 0.9, 0.8)
	core._vibrate(140, 0.7)
	if String(m["result"]) == "hit":
		var dmg: int = maxi(1, int(round(float(core.player_hp_max) * QTE_FAIL_DAMAGE)))
		core.player_hp = maxi(1, int(core.player_hp) - dmg)
		core.damage_flash_timer = 0.3
		core._add_text("-%d" % dmg, core.player_pos + Vector2(0, -80), Color(1.0, 0.25, 0.25), 0.8, 24)
		hero_pose = ""


# ================================================================ entrada
func handle_input(event: InputEvent, viewport: Vector2) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed: bool = event.pressed
		var pos: Vector2 = event.position
		if can_skip and RTUmbraIntroPresentation.skip_rect(viewport).has_point(pos):
			skip_pressed = pressed
			return
		if not pressed:
			skip_pressed = false
			if qte_waiting() and qte.has("touch_start"):
				# Deslizar para o lado da seta; um toque curto vale pelo lado da
				# tela em relacao a Geovana (toque a esquerda dela = esquerda).
				var drag: Vector2 = pos - Vector2(qte["touch_start"])
				qte.erase("touch_start")
				if drag.length() > 50.0:
					press(_dir_of(drag))
				else:
					press(_dir_of(pos - (core.player_pos - core._camera(viewport))))
			return
		if qte_waiting():
			qte["touch_start"] = pos
			return
		advance_balloon()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var dir := _dir_of_key(event.keycode)
		if dir != "" and qte_waiting():
			press(dir)
			return
		if event.keycode != KEY_ESCAPE:
			advance_balloon()
		return
	if event is InputEventJoypadButton and event.pressed:
		var jdir := ""
		match event.button_index:
			JOY_BUTTON_DPAD_UP: jdir = "up"
			JOY_BUTTON_DPAD_DOWN: jdir = "down"
			JOY_BUTTON_DPAD_LEFT: jdir = "left"
			JOY_BUTTON_DPAD_RIGHT: jdir = "right"
		if jdir != "" and qte_waiting():
			press(jdir)
		elif jdir == "":
			advance_balloon()
		return
	if event is InputEventJoypadMotion and qte_waiting() and absf(event.axis_value) > 0.75:
		if event.axis == JOY_AXIS_LEFT_X:
			press("right" if event.axis_value > 0.0 else "left")
		elif event.axis == JOY_AXIS_LEFT_Y:
			press("down" if event.axis_value > 0.0 else "up")


func _dir_of(v: Vector2) -> String:
	if absf(v.x) > absf(v.y):
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"


func _dir_of_key(code: int) -> String:
	match code:
		KEY_UP, KEY_W: return "up"
		KEY_DOWN, KEY_S: return "down"
		KEY_LEFT, KEY_A: return "left"
		KEY_RIGHT, KEY_D: return "right"
	return ""


## Centro da camera durante a cena (o _camera do nucleo usa isto).
func camera_center() -> Vector2:
	return cam
