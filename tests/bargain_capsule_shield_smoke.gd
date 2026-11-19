extends SceneTree

## Capsulas da Barganha (2026-11-18): vida acompanha o golpe atual dos inimigos,
## escudo rigido que absorve e decai por hit, e a missao do Mercador contando
## capsulas salvas.

var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("BARGAIN_SHIELD_FAIL " + message)


func _hits_to_break(hit: float, hp_max: float) -> int:
	var capsule := {"hp": hp_max, "max_hp": hp_max, "shield": RTBargainCapsuleBalance.shield_for(hp_max), "shield_max": RTBargainCapsuleBalance.shield_for(hp_max)}
	var hits := 0
	while float(capsule["hp"]) > 0.0 and hits < 500:
		RTBargainCapsuleBalance.apply_hit(capsule, hit)
		hits += 1
	return hits


func _run() -> void:
	game.startup_thanks_done = true
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	# Mesmo numero de golpes do comeco ao fim da run: a vida segue o golpe.
	var early: int = _hits_to_break(10.0, RTBargainCapsuleBalance.max_hp(170.0, 1.0, 10.0))
	var late: int = _hits_to_break(900.0, RTBargainCapsuleBalance.max_hp(170.0, 1.0, 900.0))
	var absurd: int = _hits_to_break(25000.0, RTBargainCapsuleBalance.max_hp(170.0, 1.0, 25000.0))
	_check(late >= 8, "golpe tardio quebrou em %d hits" % late)
	_check(absurd == late, "curva de dano mudou os hits para quebrar (%d x %d)" % [absurd, late])
	_check(early >= late, "inicio ficou mais fragil que o fim")
	# Escudo: segura o golpe, mas decai mesmo com golpes fracos.
	var hp_max: float = 600.0
	var capsule := {"hp": hp_max, "max_hp": hp_max, "shield": hp_max, "shield_max": hp_max}
	var lost: float = RTBargainCapsuleBalance.apply_hit(capsule, 100.0)
	_check(lost <= 25.0, "escudo nao absorveu o golpe (perdeu %.0f)" % lost)
	var weak := {"hp": hp_max, "max_hp": hp_max, "shield": hp_max, "shield_max": hp_max}
	for i in range(12):
		RTBargainCapsuleBalance.apply_hit(weak, 1.0)
	_check(float(weak["shield"]) <= 0.0, "escudo nao decaiu com golpes fracos")
	# Vida real no jogo: inimigos fortes elevam a vida da capsula.
	game.enemies.clear()
	for i in range(6):
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(400 + i * 30, 0))
		game.enemies[-1]["damage"] = 400.0
	game.time_alive = 900.0
	var hp_live: float = game._bargain_capsule_hp_for_party(1)
	_check(hp_live >= float(game._enemy_damage(game.enemies[0])) * RTBargainCapsuleBalance.HITS_TO_BREAK_HP - 1.0, "vida nao acompanhou o golpe (%.0f)" % hp_live)
	var event: Dictionary = game._spawn_bargain_capsule(game.player_pos + Vector2(200, 0))
	var first: Dictionary = Array(event.get("capsules", []))[0]
	_check(float(first.get("shield", 0.0)) > 0.0, "capsula nasceu sem escudo")
	# Missao: sobreviventes contam no placar do Mercador.
	var npc: RTMerchantNpc = game._merchant_npc()
	npc.mission_offered = true
	npc.mission_done = false
	npc.capsules_saved = 0
	for c in event["capsules"]:
		c["state"] = game.BARGAIN_CAPSULE_STATE_ACTIVE
	event["state"] = game.BARGAIN_CAPSULE_STATE_ACTIVE
	game._resolve_bargain_capsule_success()
	_check(npc.capsules_saved == 3, "capsulas salvas nao contaram (%d)" % npc.capsules_saved)
	if not failed:
		print("BARGAIN_SHIELD_OK hits_early=%d hits_late=%d hp_live=%.0f" % [early, late, hp_live])
	quit(1 if failed else 0)
