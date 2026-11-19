extends SceneTree

## Fluxo: prologo + chegada no inicio da run; chefe -> HQ pos-chefe -> pacto.
var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failed = true
		push_error("STORY_FLOW_FAIL " + msg)


func _pump(seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		t += 0.05
		game.time_alive += 0.05
		game._story().update(0.05)
		game._run_choice().update(0.05)


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.is_multiplayer = false
	var story: RTStoryController = game._story()
	story.enabled = true
	story.runs = 1
	story.seen = {}
	story._intro_checked = false
	game.mode = "game"
	game.time_alive = 0.0
	_pump(0.2)
	_check(game.mode == "story_comic" and story.active_id == "prologo", "prologo nao abriu no inicio")
	var first_page: int = story.page
	var page_panels: Array = story.panels()
	story.shown = page_panels.size()
	story.t_panel = story.panel_duration(Dictionary(page_panels[page_panels.size() - 1])) + 0.2
	story.tick(0.1)
	_check(story.page == first_page and story.turning <= 0.0, "pagina virou sem comando do jogador")
	story.advance()
	_check(story.turning > 0.0, "comando do jogador nao iniciou a virada da pagina")
	_check(RTStoryController.POST_TEXT_HOLD > 1.25, "pausa pos-texto nao foi desacelerada")
	story.skip()
	_pump(0.2)
	_check(story.active_id.begins_with("arrive_"), "chegada da primeira dimensao nao abriu")
	story.skip()
	_check(game.mode == "game", "nao voltou ao jogo")
	game._queue_post_boss_choice(1)
	_pump(2.0)
	_check(game.mode == "story_comic" and story.active_id == "boss_1", "HQ pos-chefe nao abriu antes do pacto")
	story.skip()
	_pump(0.5)
	_check(game.mode == "run_choice", "pacto nao abriu depois da HQ")
	# Henry nao ve a HQ da Geovana.
	game.active_character_key = game.CHARACTER_HENRY
	_check(not story.should_show("boss_2"), "Henry recebeu HQ da Geovana")
	print("STORY_FLOW_SMOKE_OK intro=true arrival=true boss_then_pact=true henry_skip=true")
	quit(1 if failed else 0)
