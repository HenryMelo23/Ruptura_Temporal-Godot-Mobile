extends SceneTree

var game: Node

const OUTPUT := "res://.codex/phase_transition_visual.png"


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("PHASE_TRANSITION_VISUAL_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	await process_frame
	game._start_game()
	await process_frame

	for p in range(1, 7):
		game._start_phase_transition(p)
		_check(game.mode == "phase_transition", "mode is not phase_transition for phase %d" % p)
		_check(game.phase_transition_timer > 0.0, "phase_transition_timer was 0 for phase %d" % p)

		# T1: Title Screen phase (t < 0.45, early in timer)
		game.phase_transition_timer = game.PHASE_TRANSITION_TIME * 0.90
		game.queue_redraw()
		await process_frame
		_check(game.phase_transition_overlay_node != null, "overlay node missing in phase %d" % p)
		_check(game.phase_transition_overlay_node.visible, "overlay node not visible in title screen phase %d" % p)
		_check(game.phase_transition_title_label.visible, "title label not visible in title phase %d" % p)
		_check(game.phase_transition_title_label.text != "", "title label empty in title phase %d" % p)

		# T2: Shader wipe phase (t >= 0.45)
		game.phase_transition_timer = game.PHASE_TRANSITION_TIME * 0.30
		game.queue_redraw()
		await process_frame
		_check(not game.phase_transition_title_label.visible, "title label should be hidden during shader wipe phase %d" % p)
		_check(game.phase_transition_overlay_node.material != null, "shader material not applied in wipe phase %d" % p)

		var mat: ShaderMaterial = game.phase_transition_overlay_node.material as ShaderMaterial
		_check(mat != null, "material is not ShaderMaterial in phase %d" % p)
		_check(mat.shader != null, "shader missing in material for phase %d" % p)
		var prog = mat.get_shader_parameter("progress")
		_check(prog != null and float(prog) > 0.0, "progress shader parameter invalid for phase %d" % p)

	# Verify player portal animation shader
	var p_script = load("res://scripts/player.gd")
	if p_script != null:
		var p_node = Node2D.new()
		p_node.set_script(p_script)
		if p_node.has_method("play_portal_spawn_animation"):
			p_node.call("play_portal_spawn_animation")
			_check(p_node.material != null, "player material null during portal spawn animation")
		p_node.free()

	var image: Image = root.get_texture().get_image()
	if image != null:
		_check(image.save_png(OUTPUT) == OK, "could not save transition screenshot")

	print("PHASE_TRANSITION_VISUAL_SMOKE_OK " + ProjectSettings.globalize_path(OUTPUT))
	game.queue_free()
	await process_frame
	quit(0)
