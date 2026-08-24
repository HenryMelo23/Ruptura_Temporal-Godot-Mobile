extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("PRISMATICA_ULTIMATE_DANCE_FAIL " + message)
	quit(1)


func _run() -> void:
	game._start_game()
	game.manifestation_key = "prismatica"
	game.last_secondary_time = -999.0
	game.time_alive = 20.0
	game.player_pos = Vector2(620, 430)
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(120, 0))
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(250, 35))
	for enemy in game.enemies:
		enemy["hp"] = 10000.0

	_check(game.textures.has("prismatica_dance_loop"), "missing dance loop texture key")
	_check(Array(game.textures["prismatica_dance_loop"]).size() == 15, "dance loop must have 15 frames")
	_check(Array(game.textures["prismatica_dance_final"]).size() == 2, "dance final must have 2 frames")
	_check(game.audio_streams.has("ult_prismatica"), "missing prismatica ultimate song")
	game._play_music("Fases1.mp3")
	game.music_pause_fade_mode = ""
	game._set_music_linear_volume(game._music_target_volume())
	var phase_volume_before := db_to_linear(game.music_player.volume_db)

	game._use_secondary_skill()
	var secondary: Dictionary = game._active_prismatica_secondary()
	_check(not secondary.is_empty(), "ultimate did not activate")
	_check(is_equal_approx(float(secondary.get("max", 0.0)), 10.0), "ultimate duration must be 10s")
	_check(game.prismatica_ultimate_audio_player != null, "dedicated audio player missing")
	_check(game.prismatica_ultimate_audio_player.stream == game.audio_streams["ult_prismatica"], "ultimate did not use the new song")
	_check(db_to_linear(game.music_player.volume_db) <= 0.002, "phase music was not muted during prismatica ultimate")

	secondary["active_time"] = 0.0
	secondary["life"] = 10.0
	var first_frame: Texture2D = game._prismatica_ultimate_frame_texture(secondary)
	_check(first_frame == Array(game.textures["prismatica_dance_loop"])[0], "first loop frame should be Geo-Dance00")
	_check(game._player_texture() == first_frame, "dance frame must replace the normal player sprite")
	var player_profile: Dictionary = game._player_draw_profile()
	_check(bool(player_profile.get("preserve_height", false)), "dance sprite must preserve its frame ratio")
	_check(is_equal_approx(float(player_profile.get("height", 0.0)), 84.0), "dance sprite should use player-sized height")
	secondary["active_time"] = 0.5
	secondary["life"] = 9.5
	var second_frame: Texture2D = game._prismatica_ultimate_frame_texture(secondary)
	_check(second_frame == Array(game.textures["prismatica_dance_loop"])[1], "second loop frame should appear at 0.5s")
	secondary["active_time"] = 9.05
	secondary["life"] = 0.95
	var final_frame: Texture2D = game._prismatica_ultimate_frame_texture(secondary)
	_check(Array(game.textures["prismatica_dance_final"]).has(final_frame), "last second must use Geo-Dance15 or Geo-Dance16")

	var hp_before := float(game.enemies[0]["hp"]) + float(game.enemies[1]["hp"])
	secondary["life"] = 8.0
	secondary["active_time"] = 2.0
	secondary["zaps"] = []
	secondary["zap_tick"] = 0.0
	game._update_secondary_prismatica(secondary, 0.25)
	var hp_after := float(game.enemies[0]["hp"]) + float(game.enemies[1]["hp"])
	_check(hp_after < hp_before, "targeted prism rays did not damage nearby enemies")
	_check(Array(secondary.get("zaps", [])).size() >= 2, "targeted prism rays did not create visible arcs")

	var slashes_before := Array(game.slashes).size()
	var shockwaves_before := Array(game.shockwaves).size()
	secondary["life"] = 0.01
	game._update_manifestation_secondaries(0.02)
	_check(game._active_prismatica_secondary().is_empty(), "ultimate did not end")
	_check(not game.prismatica_ultimate_audio_player.playing, "ultimate song did not stop at the end")
	_check(abs(db_to_linear(game.music_player.volume_db) - phase_volume_before) <= 0.002, "phase music volume was not restored after prismatica ultimate")
	_check(Array(game.slashes).size() > slashes_before, "finish burst did not create radial light rays")
	_check(Array(game.shockwaves).size() > shockwaves_before, "finish burst did not create glow waves")

	print("PRISMATICA_ULTIMATE_DANCE_SMOKE_OK frames=15+2 duration=10s zaps=true song=true replace_player=true finish_burst=true")
	quit(0)
