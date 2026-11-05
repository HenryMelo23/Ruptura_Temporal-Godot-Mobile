extends SceneTree

## Galeria das habilidades do Cronoguejo (Boss 1): cada linha uma habilidade, colunas em
## idades crescentes, simulando so os ataques (sem IA). Uso: -- --out=<dir> [--only=kind]
const DT := 1.0 / 60.0
var game: Node
var out_dir := "user://boss1_vfx_gallery"
## Modo GIF: --frames=<dir> salva um quadro a cada FRAME_STEP passos (≈20 fps) de cada habilidade.
var frames_dir := ""
const FRAME_STEP := 3
const CELL := Vector2i(400, 260)
# [nome, escolha do _emit_boss1_attack ou especial, tempos de captura]
const ABILITIES := [
	# bolha/pressao/chuva nascem com idade -5 s (BOSS1_BUBBLE_WARNING_LEAD): 1a coluna e o aviso.
	["bubble", "bubble", [2.5, 5.6, 6.8, 7.6, 8.1]],
	["pressure", "pressure_bubbles", [2.5, 5.3, 5.7, 6.2, 6.8]],
	["rush", "rush", [0.3, 0.8, 1.2, 1.5, 1.9]],
	["rain", "rain", [2.5, 5.6, 6.3, 7.0, 7.8]],
	["tide", "tide", [0.3, 1.2, 2.2, 3.0, 3.8]],
	["sand", "sand", [0.2, 0.8, 1.6, 2.6, 3.8]],
	["pincer", "pincer_tenaz", [0.3, 0.8, 1.3, 1.8, 2.4]],
	["whirlpool", "whirlpool", [0.4, 1.2, 2.2, 3.2, 4.2]],
	["absorb", "absorb", [0.3, 0.9, 1.6, 2.4, 3.2]],
	["timewave", "timewave", [0.3, 0.9, 1.6, 2.4, 3.4]],
	["lightning", "lightning", [0.2, 0.6, 1.0, 1.3, 1.6]],
]


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out_dir = a.substr(6)
		elif a.begins_with("--frames="): frames_dir = a.substr(9)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _prepare() -> void:
	game.startup_thanks_done = true
	game.forced_initial_phase = 1
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.set_physics_process(false)
	game.mode = "game"
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.current_phase = 1
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 6000.0
	game.boss_hp = 6000.0
	game.player_hp_max = 1.0e9
	game.player_hp = 1.0e9


func _reset_scene() -> void:
	game.boss_attacks.clear()
	game.effects.clear()
	game.enemies.clear()
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(260.0, 40.0)
	game.boss1_absorb_timer = 0.0
	game.run_retry_invulnerability_timer = 999.0


func _start(choice: String) -> void:
	match choice:
		"absorb":
			game._start_boss1_absorb()
		"timewave":
			game.boss_hp = game.boss_hp_max * 0.25
			game.boss1_rewind_cooldown = 0.0
			game.early_boss_controller.start_boss1_time_wave()
		"lightning":
			game.early_boss_controller.spawn_boss1_lightning_strike()
			game.boss_attacks[-1]["target"] = game.player_pos + Vector2(-60.0, 10.0)
		_:
			game._emit_boss1_attack(choice, game.player_pos)


func _crop() -> Image:
	var img := root.get_texture().get_image()
	var cam: Vector2 = game._camera(Vector2(1280, 720))
	var focus: Vector2 = (game.boss_pos + game.player_pos) * 0.5
	for attack in game.boss_attacks:
		if String(attack.get("kind", "")) == "tide":
			var line: float = game._boss_tide_line(attack)
			focus = Vector2(game.player_pos.x, line) if bool(attack["horizontal"]) else Vector2(line, game.player_pos.y)
	var mid: Vector2 = focus - cam
	var r := Rect2i(Vector2i(mid) - CELL / 2, CELL)
	r.position.x = clampi(r.position.x, 0, 1280 - CELL.x)
	r.position.y = clampi(r.position.y, 0, 720 - CELL.y)
	return img.get_region(r)


func _run() -> void:
	_prepare()
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="): only = a.substr(7)
	var rows: Array = ABILITIES.filter(func(x): return only == "" or String(x[0]) == only)
	var board := Image.create(CELL.x * 5, CELL.y * rows.size(), false, Image.FORMAT_RGBA8)
	board.fill(Color(0.06, 0.06, 0.08))
	for row in range(rows.size()):
		var entry: Array = rows[row]
		_reset_scene()
		_start(String(entry[1]))
		var t := 0.0
		var col := 0
		var shots: Array = entry[2]
		var step := 0
		var seq := 0
		if frames_dir != "":
			DirAccess.make_dir_recursive_absolute(frames_dir + "/" + String(entry[0]))
		while col < shots.size():
			game.time_alive += DT
			t += DT
			game._update_boss_attacks(DT)
			game._update_enemy_bullets(DT)
			game._update_effects(DT)
			game.early_boss_controller.update_boss1_time_wave(DT)
			if not game.early_boss_controller.boss1_attack_by_kind("boss1_whirlpool").is_empty():
				game.early_boss_controller.update_boss1_whirlpool(DT)
			for strike in game.boss_attacks:
				if String(strike.get("kind", "")) == "boss1_lightning":
					strike["age"] = float(strike.get("age", 0.0)) + DT
			if game.boss1_absorb_timer > 0.0:
				game.boss1_absorb_timer = maxf(0.0, game.boss1_absorb_timer - DT)
			game.player_hp = 1.0e9
			step += 1
			if frames_dir != "" and step % FRAME_STEP == 0:
				game.queue_redraw()
				await process_frame
				_crop().save_png("%s/%s/f_%03d.png" % [frames_dir, entry[0], seq])
				seq += 1
				if t >= float(shots[col]):
					col += 1
				continue
			if t >= float(shots[col]):
				game.queue_redraw()
				await process_frame
				await process_frame
				board.blit_rect(_crop(), Rect2i(Vector2i.ZERO, CELL), Vector2i(col * CELL.x, row * CELL.y))
				col += 1
		print("BOSS1_GALLERY_ROW %s attacks=%d" % [entry[0], game.boss_attacks.size()])
	DirAccess.make_dir_recursive_absolute(out_dir)
	var path := out_dir + "/boss1_vfx_gallery%s.png" % ("_" + only if only != "" else "")
	board.save_png(path)
	print("BOSS1_GALLERY_OK ", path)
	quit(0)
