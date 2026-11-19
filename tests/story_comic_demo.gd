extends SceneTree

## HQ animada: prologo + chegada + pos-chefe, regra das 2 primeiras runs e
## captura de frames. -- [--frames=<dir>] [--scene=prologo|boss_1|arrive_3]
const DT := 1.0 / 60.0
var game: Node
var frames_dir := ""
var scene_id := "prologo"
var seq := 0
var failed := false


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="): frames_dir = a.substr(9)
		elif a.begins_with("--scene="): scene_id = a.substr(8)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failed = true
		push_error("STORY_COMIC_FAIL " + msg)


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.is_multiplayer = false
	var story: RTStoryController = game._story()
	story.enabled = true
	story.manual_clock = true
	story.runs = 1
	story.seen = {}
	game.mode = "game"
	# Regra: runs 1-2 mostram; run 3+ so o que nunca foi visto.
	_check(story.should_show("prologo"), "run 1 nao mostra o prologo")
	story.runs = 3
	story.seen["prologo"] = true
	_check(not story.should_show("prologo"), "run 3 mostrou prologo ja visto")
	_check(story.should_show("boss_5"), "run 3 escondeu cena nunca vista")
	story.runs = 1
	story.seen = {}
	_check(story.open(scene_id), "cena nao abriu")
	_check(game.mode == "story_comic", "modo da HQ nao ativou")
	if frames_dir != "":
		DirAccess.make_dir_recursive_absolute(frames_dir)
	var t := 0.0
	var i := 0
	while game.mode == "story_comic" and t < 90.0:
		t += DT
		i += 1
		story.tick(DT)
		if frames_dir != "" and i % 3 == 0:
			game.queue_redraw()
			await process_frame
			var img := root.get_texture().get_image()
			img.resize(640, 360, Image.INTERPOLATE_BILINEAR)
			img.save_png("%s/f_%03d.png" % [frames_dir, seq])
			seq += 1
	_check(game.mode == "game", "HQ nao devolveu o jogo")
	_check(bool(story.seen.get(scene_id, false)), "cena nao ficou marcada como vista")
	print("STORY_COMIC_DEMO_OK scene=%s seconds=%.1f frames=%d images=%d" % [scene_id, t, seq, RTStoryCatalog.all_images().size()])
	quit(1 if failed else 0)
