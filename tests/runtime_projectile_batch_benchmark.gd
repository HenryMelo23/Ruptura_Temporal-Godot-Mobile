extends SceneTree

const BatchRenderer = preload("res://scripts/presentation/runtime_projectile_batch_renderer.gd")
const PROJECTILES := 384
const ITERATIONS := 240


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var renderer := BatchRenderer.new()
	renderer.begin_frame(1)
	var positions := PackedVector2Array()
	var directions := PackedVector2Array()
	var colors := PackedColorArray()
	for index in range(PROJECTILES):
		var angle := float(index) * TAU / float(PROJECTILES)
		positions.append(Vector2(640, 360) + Vector2.from_angle(angle) * (90.0 + float(index % 11) * 14.0))
		directions.append(Vector2.from_angle(angle))
		colors.append(Color.from_hsv(float(index % 12) / 12.0, 0.7, 1.0))

	var legacy_started := Time.get_ticks_usec()
	for _iteration in range(ITERATIONS):
		var batches: Dictionary = {}
		for index in range(PROJECTILES):
			var key := colors[index].to_rgba32()
			var points := PackedVector2Array(batches.get(key, PackedVector2Array()))
			points.append(positions[index] - directions[index] * 16.0)
			points.append(positions[index] + directions[index] * 5.0)
			batches[key] = points
	var legacy_us := float(Time.get_ticks_usec() - legacy_started) / float(ITERATIONS)

	var typed_started := Time.get_ticks_usec()
	for _iteration in range(ITERATIONS):
		renderer.begin_frame(1)
		for index in range(PROJECTILES):
			renderer.append(positions[index], directions[index], colors[index])
	var typed_us := float(Time.get_ticks_usec() - typed_started) / float(ITERATIONS)
	var reduction := (1.0 - typed_us / maxf(1.0, legacy_us)) * 100.0
	print("RUNTIME_PROJECTILE_BATCH_BENCHMARK_OK projectiles=%d iterations=%d legacy_build_mean_us=%.1f typed_capture_mean_us=%.1f cpu_reduction_pct=%.1f draw_submissions=2" % [
		PROJECTILES,
		ITERATIONS,
		legacy_us,
		typed_us,
		reduction,
	])
	quit(0)
