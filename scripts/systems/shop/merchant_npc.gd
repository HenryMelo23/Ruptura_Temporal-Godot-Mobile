class_name RTMerchantNpc
extends RefCounted

## O Mercador: um sujeito de outra especie, meio humanoide, bigode enorme, que
## vive consertando o teleportador quebrado dele. A fenda que a Geovana
## atravessa e justamente o defeito dessa geringonca abrindo sozinha.
##
## Guarda o que ele ja contou (nao repete historia) e o progresso da missao das
## pecas do teleportador, que estabiliza a fenda de vez.

const SAVE_PATH := "user://merchant_npc.cfg"
## Pecas do teleportador necessarias para ele estabilizar a fenda.
const PARTS_REQUIRED := 5
const PART_DROP_CHANCE := 0.34

var core: Node = null
var persist := true
## Marcos de historia ja contados (nao repetem).
var seen: Dictionary = {}
var parts := 0
var mission_offered := false
var mission_done := false
var visits := 0
var anim_time := 0.0
## Fala curta no balao sobre a cabeca dele.
var bubble := ""
var bubble_timer := 0.0


func configure(runtime_core: Node) -> void:
	core = runtime_core
	var loop = Engine.get_main_loop()
	if loop != null and loop.get_script() != null:
		persist = false
	_load()


func mission_complete() -> bool:
	return mission_done


func parts_missing() -> int:
	return maxi(0, PARTS_REQUIRED - parts)


func update(delta: float) -> void:
	anim_time += delta
	bubble_timer = maxf(0.0, bubble_timer - delta)
	if bubble_timer <= 0.0:
		bubble = ""


func say(text: String, seconds: float = 3.4) -> void:
	bubble = text
	bubble_timer = seconds


# ================================================================ historia
## Primeira coisa que ele faz quando ela chega perto.
func greet(dimension) -> void:
	visits += 1
	var dialogue = core._dialogue()
	if not seen.has("intro"):
		seen["intro"] = true
		_save()
		dialogue.start([
			{"who": "mercador", "text": "Opa! Opa opa opa. Nao encosta nisso."},
			{"who": "mercador", "text": "Esse troco e um teleportador. MEU teleportador. Ele tem... personalidade."},
			{"who": "mercador", "text": "Faz tempo que eu conserto ele. Faz tempo que ele abre sozinho. Voce e a terceira coisa que cai aqui hoje."},
			{"who": "geovana", "text": "Terceira?"},
			{"who": "mercador", "text": "As duas primeiras eu nao vou comentar. Enfim: enquanto nao conserto, eu vendo."},
			{"who": "mercador", "text": "Voce traz essencia dessas criaturas la fora, eu troco por coisa util. Todo mundo sai ganhando. Principalmente eu."},
			{"who": "mercador", "text": "So uma coisinha: a fenda esta instavel. Escolha rapido. Eu avisei bonitinho."},
		])
		return
	if visits >= 2 and not seen.has("stolen") and dimension != null and int(dimension.confiscated) > 0:
		seen["stolen"] = true
		_save()
		dialogue.start([
			{"who": "geovana", "text": "Voce ficou com a minha essencia."},
			{"who": "mercador", "text": "Eu? Nao, nao. A geringonca te puxou pra fora. A essencia escorregou do seu bolso.", "mood": "triste"},
			{"who": "mercador", "text": "E caiu. Bem aqui. No meu balcao. Uma tragedia.", "mood": "triste"},
			{"who": "geovana", "text": "Devolve."},
			{"who": "mercador", "text": "Achado nao e roubado, querida. Mas olha: eu te dou desconto no carinho."},
		])
		return
	if not mission_offered and visits >= 2:
		mission_offered = true
		_save()
		dialogue.start([
			{"who": "mercador", "text": "Escuta. Voce entra e sai de dimensao melhor do que eu conserto."},
			{"who": "mercador", "text": "As criaturas grandes la fora engoliram pecas do meu teleportador. Me traz %d que eu estabilizo essa fenda." % PARTS_REQUIRED, "mood": "triste"},
			{"who": "mercador", "text": "Ai voce entra, senta, toma um cha. Sem pressa, sem tremor, sem eu ficando com o seu troco."},
		])
		return
	_ambient_line()


## Falas curtas que podem repetir, no balao sobre a cabeca dele.
func _ambient_line() -> void:
	var lines: Array[String] = []
	if mission_done:
		lines = [
			"A casa e sua. Olha com os olhos, compra com a essencia.",
			"Teleportador consertado. Quase. Setenta por cento.",
			"Sem pressa hoje. Hoje eu sou um anfitriao.",
		]
	elif mission_offered and parts > 0:
		lines = [
			"%d de %d pecas. Vai indo." % [parts, PARTS_REQUIRED],
			"Faltam %d. Nao me decepciona." % parts_missing(),
		]
	else:
		lines = [
			"Olha o estoque, olha o estoque!",
			"Esse aqui saiu de uma dimensao que nao existe mais. Coisa fina.",
			"Rapidinho, rapidinho. A fenda nao e paciente.",
			"Nao repara na bagunca. A oficina e a minha cabeca.",
		]
	say(String(lines[core.rng.randi_range(0, lines.size() - 1)]))


# ================================================================ missao
## Inimigo extraordinario derrubado: chance de largar uma peca.
func on_extraordinary_killed(pos: Vector2) -> void:
	if not mission_offered or mission_done or core == null:
		return
	if parts >= PARTS_REQUIRED or core.rng.randf() > PART_DROP_CHANCE:
		return
	parts += 1
	_save()
	core._add_text("PECA DO TELEPORTADOR %d/%d" % [parts, PARTS_REQUIRED], pos + Vector2(-120, -84), Color(1.0, 0.86, 0.3), 2.2, 20)
	core._spawn_radial_particles(pos, Color(1.0, 0.82, 0.34), 18)


## Chamado quando ela chega na dimensao com as pecas na mao.
func on_dimension_entered(_confiscated: int) -> void:
	if mission_done or not mission_offered or parts < PARTS_REQUIRED:
		return
	mission_done = true
	seen["mission_done"] = true
	_save()
	core._dialogue().start([
		{"who": "mercador", "text": "Nao acredito. VOCE ACHOU TODAS."},
		{"who": "mercador", "text": "Me da aqui. Calma. Calma! Isso aqui e delicado."},
		{"who": "mercador", "text": "Pronto. A fenda agora obedece. Quando voce tiver essencia, eu abro pra voce."},
		{"who": "mercador", "text": "E pode ficar o tempo que quiser. Eu ja te roubei o suficiente."},
	])


func on_player_expelled() -> void:
	say("Volta sempre! E deixa a essencia!", 3.0)


# ================================================================ save
func _load() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	parts = int(cfg.get_value("mission", "parts", 0))
	mission_offered = bool(cfg.get_value("mission", "offered", false))
	mission_done = bool(cfg.get_value("mission", "done", false))
	visits = int(cfg.get_value("mission", "visits", 0))
	for key in Array(cfg.get_value("story", "seen", [])):
		seen[String(key)] = true


func _save() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("mission", "parts", parts)
	cfg.set_value("mission", "offered", mission_offered)
	cfg.set_value("mission", "done", mission_done)
	cfg.set_value("mission", "visits", visits)
	cfg.set_value("story", "seen", seen.keys())
	cfg.save(SAVE_PATH)
