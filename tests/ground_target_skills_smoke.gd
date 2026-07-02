extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	var viewport = Vector2(1280, 720)
	game._start_game()
	game._update_button_layout(viewport)
	game.time_alive = 100.0

	game.manifestation_key = "parasitica"
	var skill_center = game.buttons["skill"].get_center()
	var drag_pos = skill_center + Vector2(-92.0, -58.0)
	var expected = game._ground_target_world(drag_pos, viewport, false)
	game.skill_touch_index = 7
	game.skill_touch_pos = drag_pos
	game._handle_touch_release(7, drag_pos, viewport)
	_check(game.parasite_spit_zones.size() == 1, "parasitic Q did not launch after releasing the target gesture")
	_check(Vector2(game.parasite_spit_zones[0]["target"]).distance_to(expected) < 0.1, "parasitic Q ignored the selected ground position")

	var zones_before = game.parasite_spit_zones.size()
	var cooldown_before = game.last_skill_time
	game.skill_touch_index = 8
	game.skill_touch_pos = game._ability_cancel_center(viewport)
	game._handle_touch_release(8, game.skill_touch_pos, viewport)
	_check(game.parasite_spit_zones.size() == zones_before, "cancelled ground skill still spawned")
	_check(game.last_skill_time == cooldown_before, "cancelled ground skill consumed its cooldown")

	game.manifestation_key = "prismatica"
	game.last_skill_time = -100.0
	game.effects.clear()
	var prism_target = Vector2(720.0, 310.0)
	game._use_skill(prism_target)
	_check(Vector2(game.prisms.back()["pos"]).distance_to(prism_target) < 0.1, "prismatic Q ignored its ground target")

	game.manifestation_key = "gravitante"
	game.last_secondary_time = -100.0
	game.effects.clear()
	var gravity_target = Vector2(860.0, 420.0)
	game._use_secondary_skill(gravity_target)
	_check(Vector2(game.manifestation_secondaries.back()["center"]).distance_to(gravity_target) < 0.1, "gravitante ultimate ignored its ground target")

	game.manifestation_key = "ancorada"
	game.last_secondary_time = -100.0
	game.effects.clear()
	var anchor_target = Vector2(610.0, 640.0)
	game._use_secondary_skill(anchor_target)
	_check(Vector2(game.manifestation_secondaries.back()["center"]).distance_to(anchor_target) < 0.1, "anchored ultimate ignored its ground target")

	print("GROUND_TARGET_SKILLS_SMOKE_OK parasitic_q=true prismatic_q=true gravitante_e=true ancorada_e=true cancel=true")
	quit(0)
