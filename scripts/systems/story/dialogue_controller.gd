class_name RTDialogueController
extends RefCounted

## Conversa no estilo RPG: retrato de um lado, caixa de texto do outro, e o
## texto so avanca quando o jogador toca a tela. Usado nas falas que contam
## historia (acontecem uma vez). Falas que repetem usam o balao do proprio
## personagem, nao esta caixa.

## Velocidade da maquina de escrever, em caracteres por segundo.
const TYPE_SPEED := 46.0
## Carencia antes de aceitar toque, para o toque que abriu a fala nao pular ela.
const INPUT_GRACE := 0.18

var core: Node = null
## Falas pendentes: [{who, text}]
var queue: Array[Dictionary] = []
var current: Dictionary = {}
var revealed := 0.0
var grace := 0.0


func configure(runtime_core: Node) -> void:
	core = runtime_core


func busy() -> bool:
	return not current.is_empty()


func start(lines: Array) -> void:
	if lines.is_empty():
		return
	queue.clear()
	for line in lines:
		queue.append(Dictionary(line))
	_advance()


func clear() -> void:
	queue.clear()
	current.clear()
	revealed = 0.0


func speaker() -> String:
	return String(current.get("who", ""))


func full_text() -> String:
	return String(current.get("text", ""))


## Humor opcional da fala, usado para escolher o retrato ("triste").
func mood() -> String:
	return String(current.get("mood", ""))


## Trecho ja revelado pela maquina de escrever.
func visible_text() -> String:
	var text: String = full_text()
	var count: int = clampi(int(revealed), 0, text.length())
	return text.substr(0, count)


func fully_revealed() -> bool:
	return int(revealed) >= full_text().length()


func update(delta: float) -> void:
	if not busy():
		return
	grace = maxf(0.0, grace - delta)
	if not fully_revealed():
		revealed += delta * TYPE_SPEED


## Um toque/clique: primeiro completa a linha, depois passa para a proxima.
func advance_input() -> bool:
	if not busy() or grace > 0.0:
		return false
	if not fully_revealed():
		revealed = float(full_text().length())
		return true
	_advance()
	return true


func _advance() -> void:
	if queue.is_empty():
		current.clear()
		revealed = 0.0
		return
	current = queue.pop_front()
	revealed = 0.0
	grace = INPUT_GRACE
	if core != null:
		core._play_sfx("ui_manifest_switch", 0.01, 0.22, 1.35)
