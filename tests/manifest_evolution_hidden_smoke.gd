extends SceneTree

const PrismaticaEvolutionController = preload("res://scripts/systems/manifest_evolutions/prismatica_evolution_controller.gd")

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MANIFEST_EVOLUTION_HIDDEN_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game._start_game()
	game.mode = "game"
	_check(not game.MANIFEST_EVOLUTIONS_ENABLED, "temporary feature flag is enabled")
	_check(game._manifest_evolution_max_choices() == 0, "disabled evolutions still expose choice capacity")

	game.manifest_evolution_state["choices"] = [{"evolution": "prismatica_ev1_reflexao_dupla", "family": "eco"}]
	game.manifestation_key = "prismatica"
	_check(game._manifest_evolution_choices().is_empty(), "saved evolution remained active")
	_check(game._active_manifest_evolution_family() == "", "saved evolution family remained active")
	_check(not PrismaticaEvolutionController.is_active(game), "specialized evolution controller remained active")

	game.arauto_evolution_fragment = {"pos": game.player_pos, "source": "condutor"}
	game.arauto_evolution_fragments = [{"pos": game.player_pos, "source": "condutor"}]
	game._update_arauto_evolution_fragment(0.1)
	_check(game.arauto_evolution_fragment.is_empty(), "solo evolution fragment remained visible")
	_check(game.arauto_evolution_fragments.is_empty(), "replicated evolution fragments remained visible")

	game.manifest_evolution_options = [{"evolution": "fake"}]
	game._open_manifest_evolution_choice(game.player_pos)
	_check(game.mode == "game", "disabled evolution opened its selection screen")
	_check(game.manifest_evolution_options.is_empty(), "disabled evolution retained menu options")

	print("MANIFEST_EVOLUTION_HIDDEN_OK choices=0 fragments=0 saved_effects=false menu=false")
	quit(0)
