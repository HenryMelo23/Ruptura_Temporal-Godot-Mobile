class_name RTRunChoiceController
extends RefCounted

## Escolha obrigatoria de fim de chefe (mode "run_choice"):
##  - kind "pact": chefes 1, 3, 4, 5 e 6 -> 1 de 3 pactos (buff + debuff caotico)
##  - kind "evolution": chefe 2 -> 1 de 3 evolucoes autorais da forma atual
## Sem rerrolar e sem pular. Toque seleciona, ESCOLHER confirma; teclado/controle
## usa setas + Enter.

const OPEN_DELAY := 2.2

var core
var kind := ""
var options: Array = []
var selected := 0
var previous_mode := "game"
var pending_kind := ""
var pending_timer := 0.0
var age := 0.0


func configure(runtime_core) -> void:
	core = runtime_core


func reset() -> void:
	kind = ""
	options.clear()
	selected = 0
	pending_kind = ""
	pending_timer = 0.0


func is_open() -> bool:
	return core.mode == "run_choice"


## Agenda a escolha para depois da animacao de morte do chefe.
func queue(choice_kind: String, delay: float = OPEN_DELAY) -> void:
	pending_kind = choice_kind
	pending_timer = delay


func update(delta: float) -> void:
	if pending_kind == "":
		return
	pending_timer -= delta
	if pending_timer > 0.0 or core.mode != "game" or core.is_dead:
		return
	var next_kind := pending_kind
	pending_kind = ""
	open(next_kind)


func open(choice_kind: String) -> bool:
	var rolled: Array = []
	if choice_kind == "pact":
		rolled = core._boss_pacts().roll_offer(3)
	elif choice_kind == "evolution":
		rolled = core._form_evolutions().roll_offer(3)
	if rolled.is_empty():
		return false
	kind = choice_kind
	options = rolled
	selected = -1
	age = 0.0
	previous_mode = core.mode if core.mode != "run_choice" else "game"
	core.mode = "run_choice"
	core._block_ui_input(420)
	core._play_sfx("ui_spectrum_switch", 0.012, 0.5, 0.82)
	return true


func move_selection(step: int) -> void:
	if options.is_empty():
		return
	selected = (maxi(0, selected) + step + options.size()) % options.size() if selected >= 0 else (0 if step > 0 else options.size() - 1)
	core._play_sfx("ui_move", 0.0, 0.3, 1.0)


func select(index: int) -> void:
	if index < 0 or index >= options.size():
		return
	selected = index
	core._play_sfx("ui_move", 0.0, 0.3, 1.0)


func confirm() -> void:
	if selected < 0 or selected >= options.size():
		return
	var option: Dictionary = options[selected]
	if kind == "pact":
		core._boss_pacts().apply(option)
		core._add_text("PACTO: %s" % String(option.get("name", "")).to_upper(), core.player_pos + Vector2(0, -116), Color(1.0, 0.78, 0.36), 2.0, 24)
	elif kind == "evolution":
		core._form_evolutions().apply(option)
		core._add_text("EVOLUCAO: %s" % String(option.get("name", "")).to_upper(), core.player_pos + Vector2(0, -116), Color(option.get("color", Color(0.6, 1.0, 1.0))), 2.0, 24)
	core._spawn_radial_particles(core.player_pos, Color(1.0, 0.8, 0.4), 30)
	core._play_sfx("ui_spectrum_switch", 0.012, 0.62, 1.15)
	core._vibrate(95, 0.35)
	options.clear()
	kind = ""
	core.mode = previous_mode if previous_mode != "" else "game"
	core._block_ui_input(220)


func handle_key(keycode: int) -> void:
	if keycode in [KEY_LEFT, KEY_A, KEY_UP, KEY_W]:
		move_selection(-1)
	elif keycode in [KEY_RIGHT, KEY_D, KEY_DOWN, KEY_S]:
		move_selection(1)
	elif keycode in [KEY_ENTER, KEY_SPACE, KEY_KP_ENTER]:
		if selected < 0:
			selected = 0
		else:
			confirm()


func handle_tap(pos: Vector2) -> bool:
	if Rect2(core.buttons.get("run_choice_confirm", Rect2())).has_point(pos):
		confirm()
		return true
	for i in range(options.size()):
		if Rect2(core.buttons.get("run_choice_%d" % i, Rect2())).has_point(pos):
			if selected == i and core._uses_desktop_ui():
				confirm()
			else:
				select(i)
			return true
	return false
