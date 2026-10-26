extends SceneTree

const Scheduler = preload("res://scripts/systems/performance/runtime_work_scheduler.gd")
const BatchRenderer = preload("res://scripts/presentation/runtime_projectile_batch_renderer.gd")
const SpriteBatchRenderer = preload("res://scripts/presentation/runtime_sprite_batch_renderer.gd")
const AssetController = preload("res://scripts/systems/assets/runtime_asset_controller.gd")

var failed := false


class BatchCanvas extends Node2D:
	var renderer = BatchRenderer.new()
	var sprite_renderer = SpriteBatchRenderer.new()
	var submitted: int = 0
	var sprite_submitted: int = 0

	func _draw() -> void:
		renderer.begin_frame(2)
		for index in range(130):
			var angle := float(index) * TAU / 130.0
			renderer.append(Vector2(320, 180) + Vector2.from_angle(angle) * 90.0, Vector2.from_angle(angle), Color(0.2, 0.85, 1.0))
		submitted = renderer.submit(get_canvas_item())
		var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		var texture := ImageTexture.create_from_image(image)
		sprite_renderer.begin_frame(1)
		for index in range(80):
			sprite_renderer.append(texture, Vector2(40 + index * 3, 80), Vector2(24, 32), Color(0.7, 0.9, 1.0), index % 2 == 0)
		sprite_submitted = sprite_renderer.submit(get_canvas_item())


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scheduler := Scheduler.new()
	var lane_frames: Array[int] = []
	for _index in range(12):
		scheduler.advance()
		if scheduler.runs_key(&"phase_asset_prefetch", 3):
			lane_frames.append(scheduler.frame_index)
	_check(lane_frames.size() == 4, "deterministic three-frame lane must execute four times in twelve frames")
	var replay := Scheduler.new()
	var replay_frames: Array[int] = []
	for _index in range(12):
		replay.advance()
		if replay.runs_key(&"phase_asset_prefetch", 3):
			replay_frames.append(replay.frame_index)
	_check(replay_frames == lane_frames, "scheduler lane must reproduce exactly across runs")
	_check(Scheduler.interval_for_stage(0) == 1, "full stage cadence must be every frame")
	_check(Scheduler.interval_for_stage(2) == 3, "emergency stage cadence must spread background work")

	var phase_paths := AssetController.prefetch_paths_for_phase(2, "res://assets/sprites/", 7)
	_check(phase_paths.size() == 7, "phase prefetch must obey its hard request budget")
	_check(phase_paths[0].contains("inimigo_direita2-1.png"), "prefetch priority must begin with common enemy silhouettes")
	AssetController.reset_prefetch_for_test()
	var scheduled := AssetController.schedule_phase_prefetch(2, "res://assets/sprites/", 4)
	_check(scheduled <= 4, "threaded prefetch must never exceed the configured budget")
	_check(int(AssetController.prefetch_snapshot()["phase"]) == 2, "prefetch snapshot must expose the active target phase")

	var canvas := BatchCanvas.new()
	root.add_child(canvas)
	canvas.queue_redraw()
	await process_frame
	await process_frame
	_check(canvas.submitted == 130, "MultiMesh path must submit every captured visible projectile")
	_check(canvas.renderer.capacity == 256, "batch capacity must grow geometrically instead of reallocating every frame")
	_check(canvas.renderer.positions is PackedVector2Array, "projectile positions must use a typed packed hot buffer")
	_check(canvas.renderer.streak_texture.get_width() == 16, "emergency world batch must use the reduced 16 px source texture")
	_check(canvas.sprite_submitted == 80, "sprite MultiMesh path must retain all plain crowd members")
	_check(canvas.sprite_renderer.groups.size() == 1, "same-texture crowd must collapse into one GPU group")
	canvas.renderer.begin_frame(0)
	_check(canvas.renderer.streak_texture.get_width() == 32, "full stage must restore the authored high-resolution streak")
	canvas.queue_free()
	canvas = null
	for _frame in range(120):
		AssetController.poll_prefetch(8)
		if int(AssetController.prefetch_snapshot()["pending"]) == 0:
			break
		await process_frame
	AssetController.reset_prefetch_for_test()
	await process_frame
	await process_frame
	print("RUNTIME_ADVANCED_PIPELINE_OK scheduler=deterministic prefetch_cap=4 projectile_instances=130 sprite_instances=80 sprite_groups=1 capacity=256 world_texture=32/24/16 hud=native")
	quit(1 if failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("RUNTIME_ADVANCED_PIPELINE_FAIL " + message)
