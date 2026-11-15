class_name RTStoryController
extends RefCounted

## Mini cenas em HQ (mode "story_comic"):
##  - prólogo no início da run; chegada em cada dimensão; cena pós-chefe.
##  - Contagem própria (começa agora, independente do tutorial): nas 2 primeiras
##    runs com a Geovana tudo aparece; da 3ª em diante só cenas nunca vistas.
##  - Toque avança; segurar/botão PULAR encerra a cena.

const SAVE_PATH := "user://story_progress.cfg"
const AUTO_RUNS := 2
const TYPE_CPS := 42.0
const PANEL_ENTER := 0.42
const POST_TEXT_HOLD := 1.55
const PAGE_TURN := 0.38

var core
var runs := 0
var seen: Dictionary = {}
var _loaded := false
var queue: Array = []
var _queue_delay := 0.0
var _last_phase := -1
var _intro_checked := false
## Testes automatizados (SceneTree com script) nao disparam cenas nem gravam
## progresso, a menos que liguem "enabled" de proposito.
var enabled := true
var persist := true
## Demos de captura avancam o relogio na mao (sem o delta real do desenho).
var manual_clock := false

# Player
var active_id := ""
var scene: Dictionary = {}
var page := 0
var shown := 0
var t_panel := 0.0
var t_page := 0.0
var turning := 0.0
var previous_mode := "game"
var age := 0.0


func configure(runtime_core) -> void:
	core = runtime_core
	var loop = Engine.get_main_loop()
	if loop != null and loop.get_script() != null:
		enabled = false
		persist = false
	_load()


func _load() -> void:
	if _loaded:
		return
	_loaded = true
	if not persist:
		return
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		runs = int(cfg.get_value("story", "runs", 0))
		seen = Dictionary(cfg.get_value("story", "seen", {}))


func _save() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("story", "runs", runs)
	cfg.set_value("story", "seen", seen)
	cfg.save(SAVE_PATH)


## Chamado no começo de cada run.
func on_run_started() -> void:
	queue.clear()
	_intro_checked = false
	_last_phase = -1
	if not _story_character():
		return
	runs += 1
	_save()


func _story_character() -> bool:
	return String(core.active_character_key) != String(core.CHARACTER_HENRY) and not core.is_multiplayer


func should_show(id: String) -> bool:
	if not enabled or not _story_character():
		return false
	return runs <= AUTO_RUNS or not bool(seen.get(id, false))


func request(id: String, delay: float = 0.0) -> void:
	if not should_show(id) or RTStoryCatalog.scene(id).is_empty():
		return
	if queue.has(id) or active_id == id:
		return
	queue.append(id)
	_queue_delay = maxf(_queue_delay, delay)


func update(delta: float) -> void:
	if core.mode != "game":
		return
	if not _intro_checked and float(core.time_alive) > 0.05:
		_intro_checked = true
		request("prologo")
		_last_phase = int(core.current_phase)
		request("arrive_%d" % _last_phase)
	elif _intro_checked and int(core.current_phase) != _last_phase:
		_last_phase = int(core.current_phase)
		request("arrive_%d" % _last_phase, 0.6)
	if queue.is_empty():
		return
	_queue_delay -= delta
	if _queue_delay > 0.0 or core.is_dead:
		return
	open(String(queue.pop_front()))


func open(id: String) -> bool:
	# Multiplayer is deliberately gameplay-only. Keep this guard here as well as
	# in request(): callers that open a scene directly must not bypass the rule.
	if not should_show(id):
		return false
	var data: Dictionary = RTStoryCatalog.scene(id)
	if data.is_empty():
		return false
	active_id = id
	scene = data
	page = 0
	shown = 1
	t_panel = 0.0
	t_page = 0.0
	turning = 0.0
	age = 0.0
	previous_mode = core.mode if core.mode != "story_comic" else "game"
	core.mode = "story_comic"
	core._block_ui_input(250)
	return true


func close() -> void:
	if active_id != "":
		seen[active_id] = true
		_save()
	active_id = ""
	scene = {}
	RTStoryComicPresentation.clear_cache()
	core.mode = previous_mode if previous_mode != "" else "game"
	core._block_ui_input(200)


func pages() -> Array:
	return Array(scene.get("pages", []))


func panels() -> Array:
	var ps: Array = pages()
	if page >= ps.size():
		return []
	return Array(Dictionary(ps[page]).get("panels", []))


func fill(text: String) -> String:
	return text.replace("{frag}", "%d/7" % clampi(int(core.dimension_route_completed_count), 1, 7))


func _panel_text_len(panel: Dictionary) -> int:
	var n := 0
	for line in Array(panel.get("lines", [])):
		n += fill(String(line[1])).length()
	return n


## Tempo para o painel atual terminar de "contar" (entrada + digitação + pausa).
func panel_duration(panel: Dictionary) -> float:
	return maxf(float(panel.get("hold", 0.0)), PANEL_ENTER + float(_panel_text_len(panel)) / TYPE_CPS + POST_TEXT_HOLD)


func panel_done() -> bool:
	var ps: Array = panels()
	if shown - 1 >= ps.size():
		return true
	return t_panel >= PANEL_ENTER + float(_panel_text_len(Dictionary(ps[shown - 1]))) / TYPE_CPS


func tick(delta: float) -> void:
	if active_id == "":
		return
	age += delta
	if turning > 0.0:
		turning -= delta
		if turning <= 0.0:
			page += 1
			shown = 1
			t_panel = 0.0
			t_page = 0.0
			if page >= pages().size():
				close()
		return
	t_panel += delta
	t_page += delta
	var ps: Array = panels()
	if ps.is_empty():
		close()
		return
	# Os paineis da pagina continuam entrando no ritmo da HQ, mas a virada da
	# pagina sempre espera uma acao explicita do jogador.
	if shown < ps.size() and t_panel >= panel_duration(Dictionary(ps[shown - 1])):
		advance()


## Toque: termina a digitação ou vai para o próximo painel/página.
func advance() -> void:
	var ps: Array = panels()
	if turning > 0.0:
		return
	if not panel_done():
		t_panel = PANEL_ENTER + float(_panel_text_len(Dictionary(ps[shown - 1]))) / TYPE_CPS + 0.01
		return
	if shown < ps.size():
		shown += 1
		t_panel = 0.0
		if core.has_method("_play_sfx"):
			core._play_sfx("ui_move", 0.0, 0.25, 0.9)
		return
	turning = PAGE_TURN


func skip() -> void:
	close()


func handle_tap(pos: Vector2) -> void:
	if Rect2(core.buttons.get("story_skip", Rect2())).has_point(pos):
		skip()
		return
	advance()


func handle_key(keycode: int) -> void:
	if keycode == KEY_ESCAPE:
		skip()
	elif keycode in [KEY_ENTER, KEY_SPACE, KEY_KP_ENTER, KEY_RIGHT, KEY_D]:
		advance()
