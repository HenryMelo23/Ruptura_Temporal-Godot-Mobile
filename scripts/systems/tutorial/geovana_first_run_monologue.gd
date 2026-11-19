class_name RTGeovanaFirstRunMonologue
extends RefCounted

## Primeira partida (tutorial): a Geovana acabou de cair num mundo quebrado e
## ainda nao entende o que esta saindo das maos dela. Ela fala sozinha, em
## baloes, enquanto aprende cada poder e depois durante a missao do tutorial.
##
## So existe nessa partida: personagem Geovana, solo, com o tutorial rodando
## (passos praticos) ou com a missao do tutorial ativa. Fora disso fica mudo.
## Usa o sistema generico de baloes (game.speech_bubbles); nao mexe em
## gameplay, rede ou save.

const SPEAKER := "player"
## Respiro entre duas falas seguidas da mesma fila.
const LINE_GAP := 0.65
## Falas soltas durante a missao, para ela "pensar alto" de vez em quando.
const AMBIENT_FIRST_DELAY := 40.0
const AMBIENT_INTERVAL := 70.0
const LOW_HEALTH_RATIO := 0.35

## Ao entrar em cada passo pratico do tutorial.
const STEP_LINES := {
	"attack": [
		"Tá... o que é isso saindo da minha mão?",
		"Energia? Eu fiz isso? De novo, Geovana. Com calma.",
	],
	"skill": [
		"Tem outra coisa aqui dentro. Parece que responde quando eu quero muito.",
		"Ok. Isso definitivamente não é física normal.",
	],
	"secondary": [
		"Se eu juntar tudo de uma vez... meu Deus.",
		"Isso foi incrível. E um pouco assustador.",
	],
	"dash": [
		"Eu pisquei e já estava do outro lado?!",
		"Teleporte. Claro. Por que não.",
	],
	"dash_line": [
		"Se eu atravessar rápido, essa linha não me pega... eu acho.",
	],
}

const MISSION_LINES := [
	"Certo. Respira. Preciso ficar mais forte antes de encarar o que manda aqui.",
	"Henrique... me espera. Eu vou dar um jeito.",
]

## Primeira vez que cada coisa acontece na missao.
const EVENT_LINES := {
	"first_kill": "Eles caem. Bom saber... bom saber.",
	"rift": "Uma rachadura no ar. Tem alguém do outro lado?",
	"after_shop": "Mais forte. Dá pra sentir a diferença nas mãos.",
	"low_health": "Não, não, não... foco. Movimento primeiro, pânico depois.",
	"boss": "Lá vem ele. Ok, Geovana. Agora é pra valer.",
}

const AMBIENT_LINES := [
	"Céu roxo, ruínas flutuando... onde eu vim parar?",
	"Falar sozinha agora é oficialmente um hábito.",
	"Se eu entender como isso funciona, talvez eu consiga voltar.",
]

var queue: Array[String] = []
var gap: float = 0.0
var said: Dictionary = {}
var last_state: String = ""
var mission_seen: bool = false
var ambient_timer: float = AMBIENT_FIRST_DELAY
var ambient_index: int = 0
var kills_at_mission: int = -1
var was_in_dimension: bool = false
var last_time_alive: float = 0.0


func reset_run() -> void:
	queue.clear()
	gap = 0.0
	said.clear()
	last_state = ""
	mission_seen = false
	ambient_timer = AMBIENT_FIRST_DELAY
	ambient_index = 0
	kills_at_mission = -1
	was_in_dimension = false


func eligible(game: Node) -> bool:
	if game.dedicated_server_mode or game.is_multiplayer:
		return false
	if game.active_character_key != game.CHARACTER_GEOVANA:
		return false
	return game._tutorial_practical_state() or game._tutorial_guide().mission_active


func update(game: Node, delta: float) -> void:
	var now: float = float(game.time_alive)
	if now + 1.0 < last_time_alive:
		reset_run() # nova partida
	last_time_alive = now
	var state: String = String(game.tutorial_state)
	var state_changed: bool = state != last_state
	last_state = state
	if not eligible(game):
		queue.clear()
		return
	if state_changed and STEP_LINES.has(state) and not said.has("step:" + state):
		said["step:" + state] = true
		queue.clear() # o passo novo manda; nao terminar a fala do anterior
		game.speech_bubbles.silence(SPEAKER)
		_enqueue(STEP_LINES[state])
	if game._tutorial_guide().mission_active:
		_update_mission(game, delta)
	_pump(game, delta)


func _update_mission(game: Node, delta: float) -> void:
	if not mission_seen:
		mission_seen = true
		kills_at_mission = int(game.enemies_killed)
		_enqueue(MISSION_LINES)
		return
	if int(game.enemies_killed) > kills_at_mission:
		_event("first_kill")
	if game.shop_rift_controller.active():
		_event("rift")
	var in_dimension: bool = game._merchant_dimension().active
	if was_in_dimension and not in_dimension:
		_event("after_shop")
	was_in_dimension = in_dimension
	if float(game.player_hp) / maxf(1.0, float(game.player_hp_max)) <= LOW_HEALTH_RATIO:
		_event("low_health", true)
	if bool(game.boss_active):
		_event("boss", true)
	if in_dimension or bool(game.boss_active):
		return
	ambient_timer -= delta
	if ambient_timer <= 0.0 and ambient_index < AMBIENT_LINES.size():
		ambient_timer = AMBIENT_INTERVAL
		if queue.is_empty():
			_enqueue([AMBIENT_LINES[ambient_index]])
			ambient_index += 1


func _event(key: String, urgent: bool = false) -> void:
	if said.has(key):
		return
	said[key] = true
	if urgent:
		queue.push_front(String(EVENT_LINES[key]))
		gap = 0.0
	else:
		queue.append(String(EVENT_LINES[key]))


func _enqueue(lines: Array) -> void:
	for line in lines:
		queue.append(String(line))


func _pump(game: Node, delta: float) -> void:
	gap = maxf(0.0, gap - delta)
	if queue.is_empty() or gap > 0.0:
		return
	if game.mode != "game" or game._dialogue().busy():
		return # loja, pausa ou conversa com o Mercador: espera
	if game.speech_bubbles.is_speaking(SPEAKER):
		return
	var line: String = queue.pop_front()
	if game.speech_bubbles.say(game, SPEAKER, line, {"priority": 1}):
		var duration: float = game.speech_bubbles.reading_duration_for(line)
		gap = LINE_GAP
		# A proxima fala espera esta terminar (is_speaking cobre) + o respiro.
		ambient_timer = maxf(ambient_timer, duration + LINE_GAP)
