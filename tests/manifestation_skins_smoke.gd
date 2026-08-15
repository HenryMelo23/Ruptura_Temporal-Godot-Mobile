extends SceneTree

var game: Node

const EXPECTED_SKINS := [
	"acorrentada",
	"ancorada",
	"bombastica",
	"cartografica",
	"contratual",
	"eclipsada_sol",
	"eclipsada_lua",
	"gravitante",
	"lacerante",
	"necronada",
	"parasitica",
	"prismatica",
	"ressonante",
]


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("MANIFESTATION_SKINS_SMOKE_FAIL %s" % message)
	quit(1)


func _expect_frames(key: String, expected_count: int) -> void:
	if not game.textures.has(key):
		_fail("missing_texture_key_%s" % key)
	var frames: Array = game.textures.get(key, [])
	if frames.size() != expected_count:
		_fail("unexpected_frame_count_%s_%d" % [key, frames.size()])
	for frame in frames:
		if frame == null:
			_fail("null_frame_%s" % key)


func _run() -> void:
	for skin_key in EXPECTED_SKINS:
		_expect_frames("player_skin_%s_idle" % skin_key, 2)
		_expect_frames("player_skin_%s_right" % skin_key, 2)
		_expect_frames("player_skin_%s_down" % skin_key, 1)
		_expect_frames("player_skin_%s_up" % skin_key, 1)

	game.manifestation_key = "prismatica"
	if game._active_player_skin_key() != "prismatica":
		_fail("prismatica_skin_not_selected")
	if game._player_animation_texture_key("idle", "player_idle") != "player_skin_prismatica_idle":
		_fail("prismatica_idle_key_not_selected")

	game.manifestation_key = "eletrica"
	if game._active_player_skin_key() != "":
		_fail("eletrica_should_keep_default_skin")
	if game._player_animation_texture_key("idle", "player_idle") != "player_idle":
		_fail("eletrica_fallback_failed")

	game.manifestation_key = "eclipsada"
	game.eclipsada_form = game.ECLIPSADA_FORM_SOL
	if game._active_player_skin_key() != "eclipsada_sol":
		_fail("eclipsada_sol_skin_not_selected")
	game.eclipsada_form = game.ECLIPSADA_FORM_LUA
	if game._active_player_skin_key() != "eclipsada_lua":
		_fail("eclipsada_lua_skin_not_selected")

	print("MANIFESTATION_SKINS_SMOKE_OK skins=%d" % EXPECTED_SKINS.size())
	quit(0)
