class_name RTDialogueController
extends RefCounted

## Conversa no estilo RPG: retrato de um lado, caixa de texto do outro, e o
## texto so avanca quando o jogador toca a tela. Usado nas falas que contam
## historia (acontecem uma vez). Falas que repetem usam o balao do proprio
## personagem, nao esta caixa.
##
## Uma fala pode terminar em escolhas: {"who", "text", "choices": [{"label",
## "id"}]}. A escolha encerra a conversa atual e chama o `handler` passado no
## `start` com o id (o handler pode abrir outra conversa).

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
var handler: Callable = Callable()
## Escolha destacada (teclado/controle) e areas de toque desenhadas no quadro.
var selected := 0
var choice_rects: Array = []


func configure(runtime_core: Node) -> void:
	core = runtime_core


func busy() -> bool:
	return not current.is_empty()


func start(lines: Array, on_choice: Callable = Callable()) -> void:
	if lines.is_empty():
		return
	handler = on_choice
	queue.clear()
	for line in lines:
		queue.append(Dictionary(line))
	_advance()


func clear() -> void:
	queue.clear()
	current.clear()
	revealed = 0.0
	handler = Callable()
	choice_rects.clear()


func choices() -> Array:
	return Array(current.get("choices", []))


func choice_labels() -> Array:
	var out: Array = []
	for choice in choices():
		out.append(String(Dictionary(choice).get("label", "")))
	return out


## A fala ja apareceu inteira e espera o jogador escolher.
func awaiting_choice() -> bool:
	return busy() and fully_revealed() and not choices().is_empty()


func choose(index: int) -> bool:
	var options := choices()
	if not awaiting_choice() or grace > 0.0 or index < 0 or index >= options.size():
		return false
	var id := String(Dictionary(options[index]).get("id", ""))
	var callback := handler
	queue.clear()
	current.clear()
	revealed = 0.0
	choice_rects.clear()
	handler = Callable()
	if core != null:
		core._play_sfx("ui_manifest_switch", 0.01, 0.3, 1.1)
	if callback.is_valid():
		callback.call(id)
	return true


func move_selection(step: int) -> void:
	var count := choices().size()
	if count <= 0:
		return
	selected = posmod(selected + step, count)


## Toque, clique, tecla ou botao do controle enquanto a conversa esta aberta.
## Sem escolha: qualquer entrada avanca. Com escolha: toque no botao, setas
## para mover e Enter/Espaco/A para confirmar; Esc/B escolhe a ultima opcao.
func handle_input(event: InputEvent) -> void:
	if not busy():
		return
	if awaiting_choice():
		if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
			for i in range(choice_rects.size()):
				if Rect2(choice_rects[i]).has_point(event.position):
					selected = i
					choose(i)
					return
			return
		if event is InputEventKey and event.pressed and not event.echo:
			match event.keycode:
				KEY_UP, KEY_W:
					move_selection(-1)
				KEY_DOWN, KEY_S:
					move_selection(1)
				KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E:
					choose(selected)
				KEY_ESCAPE:
					choose(choices().size() - 1)
			return
		if event is InputEventJoypadButton and event.pressed:
			match event.button_index:
				JOY_BUTTON_DPAD_UP:
					move_selection(-1)
				JOY_BUTTON_DPAD_DOWN:
					move_selection(1)
				JOY_BUTTON_A:
					choose(selected)
				JOY_BUTTON_B:
					choose(choices().size() - 1)
		return
	var advance: bool = (event is InputEventScreenTouch and event.pressed)
	advance = advance or (event is InputEventMouseButton and event.pressed)
	advance = advance or (event is InputEventKey and event.pressed and not event.echo)
	advance = advance or (event is InputEventJoypadButton and event.pressed)
	if advance:
		advance_input()


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
	if awaiting_choice():
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
		handler = Callable()
		return
	current = queue.pop_front()
	revealed = 0.0
	selected = 0
	grace = INPUT_GRACE
	if core != null:
		core._play_sfx("ui_manifest_switch", 0.01, 0.22, 1.35)
