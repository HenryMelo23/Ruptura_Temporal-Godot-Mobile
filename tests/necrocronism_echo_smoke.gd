extends SceneTree

## Necrocronismo rework: Eco ressurge, encadeia investidas que atravessam + lentidao,
## respeita o limite de vivos, implode no fim, nao se alimenta das proprias mortes.

var game: Node
const DT := 1.0 / 60.0


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("NECROCRONISM_ECHO_FAIL " + message)
	quit(1)


func _card(card_id: String) -> Dictionary:
	for card in game.CARDS:
		if game._card_id(card) == card_id:
			return card
	return {}


func _enemy(pos: Vector2, hp: float = 1.0e6) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var enemy: Dictionary = game.enemies[-1]
	enemy["pos"] = pos
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	enemy["speed"] = 0.0
	enemy["killed_by_source"] = "atk"
	enemy["killed_by_category"] = "basic_attack"
	return enemy


func _sim(seconds: float) -> void:
	for _i in range(int(round(seconds / DT))):
		game.time_alive += DT
		game._update_necro_specters(DT)


func _run() -> void:
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game._reset_card_counts()
	game._reset_card_proc_state()
	game.enemies.clear()
	game.active_necro_specters.clear()
	game.player_pos = Vector2(800, 800)
	game.player_damage = 100.0
	game.boss_active = false
	game.time_alive = 30.0
	game._apply_card(_card("necrocronismo"))
	_check(game._rare_card_count("necrocronismo") == 1, "card not applied")
	var ctrl: RTNecrocronismController = game._necrocronism()

	var origin := _enemy(Vector2(800, 800))
	game._spawn_necro_specter_from_enemy(origin)
	game.enemies.clear()
	_check(game.active_necro_specters.size() == 1, "no echo spawned")
	var echo: Dictionary = game.active_necro_specters[0]
	_check(String(echo["state"]) == "rise", "echo did not start rising")
	# Fila de inimigos em linha: uma investida deve atravessar varios.
	var line: Array = []
	for i in range(4):
		line.append(_enemy(Vector2(880 + i * 40, 800)))
	_sim(ctrl.RISE_TIME + 0.05)
	_check(String(echo["state"]) == "dash", "echo did not dash after rising: %s" % echo["state"])
	var hp_before: Array = []
	for e in line:
		hp_before.append(float(e["hp"]))
	_sim(0.2)
	var hit := 0
	for i in range(line.size()):
		if float(line[i]["hp"]) < float(hp_before[i]):
			hit += 1
	_check(hit >= 3, "dash pierced only %d enemies" % hit)
	_check(float(line[1].get("evolution_slow", 0.0)) > 0.0 and float(line[1].get("evolution_slow_mult", 1.0)) <= 0.6, "dash did not slow")
	var single_hit: float = hp_before[0] - float(line[0]["hp"])
	_check(absf(single_hit - ctrl.dash_damage(echo)) < 1.0, "dash hit same enemy more than once per dash (%.1f)" % single_hit)
	_sim(1.0)
	_check(float(line[0]["hp"]) < hp_before[0] - single_hit, "echo did not chain a second dash")

	# Limite de vivos: o mais antigo implode para abrir espaco.
	for i in range(ctrl.alive_cap()):
		game._spawn_necro_specter_from_enemy(_enemy(Vector2(700, 700)))
	var collapsing := 0
	for s in game.active_necro_specters:
		if String(s["state"]) == "collapse":
			collapsing += 1
	_check(collapsing >= 1, "cap did not collapse oldest echo")
	_check(game.active_necro_specters.size() - collapsing <= ctrl.alive_cap(), "alive cap exceeded")

	# Fim da vida: implode, dano e lentidao em volta.
	game.enemies.clear()
	game.active_necro_specters.clear()
	game._spawn_necro_specter_from_enemy(_enemy(Vector2(1200, 1200)))
	game.enemies.clear()
	var e2: Dictionary = game.active_necro_specters[0]
	e2["state"] = "seek"
	e2["life"] = 0.01
	var bystander := _enemy(Vector2(1210, 1190))
	var by_hp: float = float(bystander["hp"])
	_sim(ctrl.COLLAPSE_TIME + 0.1)
	_check(game.active_necro_specters.is_empty(), "echo not removed after collapse")
	_check(float(bystander["hp"]) < by_hp, "collapse dealt no damage")
	_check(game.rare_card_effects.any(func(fx): return String(fx.get("kind", "")) == "necro_collapse"), "collapse vfx missing")

	# Save antigo (sem estado) nao quebra.
	game.active_necro_specters.append({"type": game.ENEMY_COMMON, "pos": Vector2(900, 900), "life": 3.0, "max": 6.0, "elite": false, "is_necro_specter": true})
	_sim(0.1)
	_check(game.active_necro_specters.size() == 1 and String(game.active_necro_specters[0].get("state", "")) != "", "legacy echo not migrated")

	# Sem loop: morte causada por Eco nao carrega o contador.
	game.necro_kill_counter = 0
	var looped := _enemy(Vector2(500, 500))
	looped["killed_by_source"] = game.RARE_SOURCE_NECRO
	looped["killed_by_category"] = "necro_specter"
	game._register_valid_necro_kill(looped)
	_check(game.necro_kill_counter == 0, "necro kill fed itself")
	print("NECROCRONISM_ECHO_OK rise=true pierce=%d slow=true chain=true cap=%d collapse=true legacy=true no_loop=true" % [hit, ctrl.alive_cap()])
	game._cleanup_runtime_resources()
	game.free()
	quit(0)
