extends SceneTree

## UMBRA v3: sem arte usa os sprites antigos; com arte, acao -> animacao,
## sifao em loop, dano, morte, espelhamento e tamanho de desenho.

var game: Node
var checks := 0


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		push_error("UMBRA_V3_ANIM_FAIL " + msg)
		quit(1)


func _fake(anim: String, n: int) -> void:
	var list: Array[Texture2D] = []
	for i in range(n):
		var img := Image.create(8, 12, false, Image.FORMAT_RGBA8)
		img.fill(Color(float(i) / 8.0, 0.5, 1.0))
		var tex := ImageTexture.create_from_image(img)
		tex.set_meta("anim", "%s_%d" % [anim, i])
		list.append(tex)
	RTUmbraBossAnimation._cache[anim] = list


func _name(tex: Texture2D) -> String:
	return String(tex.get_meta("anim", "")) if tex != null else ""


func _run() -> void:
	await process_frame
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game._advance_to_phase(5)
	game.set_process(false)
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 30000.0
	game.boss_hp = 30000.0
	game.boss5_siphon_timer = 0.0
	game.damage_flash_timer = 0.0
	game.boss_pos = Vector2(1600, 1000)
	game.player_pos = Vector2(1300, 1000)

	# Sem arte v3: cai nos sprites antigos.
	RTUmbraBossAnimation._cache.clear()
	if not RTUmbraBossAnimation.available():
		_check(RTUmbraBossAnimation.active_texture(game) == null, "sem arte nao deveria haver textura v3")
		_check(game._boss_draw_size() == Vector2(59.4, 88.0), "tamanho antigo mudou sem arte")
	_check(RTUmbraBossAnimation.anim_for_action("TRANSMUTAR_ATRITO") == "transmutar", "transmutar sem animacao")
	_check(RTUmbraBossAnimation.anim_for_action("MIASMA") == "conjurar", "dimensional sem conjurar")
	_check(RTUmbraBossAnimation.anim_for_action("ECO_PROFETICO") == "eco", "eco sem animacao")

	# Com arte (falsa): idle em loop.
	_fake("idle", 4)
	_fake("ataque", 4)
	_fake("sifao", 3)
	_fake("dano", 2)
	_fake("morte", 2)
	_fake("teleporte", 2)
	_check(RTUmbraBossAnimation.available(), "arte falsa nao reconhecida")
	RTUmbraBossAnimation.current = ""
	game.time_alive = 100.0
	_check(_name(game._boss_texture()).begins_with("idle_"), "boss_texture nao usou o idle v3")
	_check(game._boss_draw_size() == RTUmbraBossAnimation.DRAW_SIZE, "tamanho v3 nao aplicado")
	_check(RTUmbraBossAnimation.should_flip_h(game), "deveria espelhar com jogador a esquerda")

	# Ataque: one-shot, depois volta ao idle.
	game.enemy_bullets.clear()
	game._spawn_umbra_action("ATAQUE")
	_check(RTUmbraBossAnimation.current == "ataque", "acao nao disparou animacao")
	game.time_alive += 0.01
	_check(_name(game._boss_texture()) == "ataque_0", "ataque nao comecou no frame 1")
	game.time_alive += 0.2
	_check(_name(game._boss_texture()) == "ataque_2", "ataque nao avancou (%s)" % _name(game._boss_texture()))
	game.time_alive += 0.5
	_check(_name(game._boss_texture()).begins_with("idle_"), "ataque nao voltou ao idle")

	# Animacao ausente (rebobinar) cai no idle sem quebrar.
	RTUmbraBossAnimation._cache["rebobinar"] = [] as Array[Texture2D]
	RTUmbraBossAnimation.on_action(game, "REBOBINAR")
	_check(_name(game._boss_texture()).begins_with("idle_"), "animacao ausente deveria cair no idle")

	# Sifao em loop enquanto dura; dano; morte.
	game.boss5_siphon_timer = 3.0
	_check(_name(game._boss_texture()).begins_with("sifao_"), "sifao nao apareceu")
	game.boss5_siphon_timer = 0.0
	RTUmbraBossAnimation.current = ""
	game.damage_flash_timer = 0.2
	_check(_name(game._boss_texture()).begins_with("dano_"), "dano nao apareceu")
	game.damage_flash_timer = 0.0
	game.boss_dead = true
	_check(_name(game._boss_texture()).begins_with("morte_"), "morte nao apareceu")
	game.boss_dead = false
	game.player_pos = Vector2(1900, 1000)
	_check(not RTUmbraBossAnimation.should_flip_h(game), "nao deveria espelhar com jogador a direita")
	RTUmbraBossAnimation._cache.clear()
	print("UMBRA_V3_ANIM_OK checks=%d" % checks)
	quit(0)
