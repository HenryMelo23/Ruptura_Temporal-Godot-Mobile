extends SceneTree
const Fire = preload("res://scripts/presentation/henry_fire_presentation.gd")

class Probe extends Node2D:
	const HENRY_SKILL_RANGE := 360.0
	const HENRY_SKILL_HALF_ANGLE := 0.52
	const HENRY_SKILL_IMPACT_TIME := 0.46
	var gfx_particles := true
	var low := false
	var clock := 0.0
	var submit_us := 0
	func _runtime_visual_budget_active() -> bool:
		return low
	func _draw() -> void:
		var before := Time.get_ticks_usec()
		Fire.cone(self, Vector2(100, 170), Vector2.RIGHT, clock, 1.0)
		Fire.wave(self, Vector2(680, 290), 280.0 * clock, 280.0, 1.0)
		Fire.charge(self, Vector2(320, 390), clock, 1.0)
		submit_us = Time.get_ticks_usec() - before

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("HENRY_FIRE_BUDGET requires a renderer")
		quit(1)
		return
	var probe := Probe.new()
	root.add_child(probe)
	var report := []
	for low in [false, true]:
		probe.low = low
		var samples: Array[int] = []
		for frame in range(120):
			probe.clock = 0.2 + float(frame % 60) * 0.01
			probe.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			if frame >= 20:
				samples.append(probe.submit_us)
		var total := 0
		for sample in samples:
			total += sample
		samples.sort()
		report.append({"low": low, "mean_us": float(total) / samples.size(), "p95_us": samples[94], "samples": samples.size()})
	var bounded := Fire.flame_meshes.size() == 8 and probe.get_child_count() == 0
	print("HENRY_FIRE_BUDGET bounded=%s meshes=%d particles_nodes=0 cpu_only=%s" % [bounded, Fire.flame_meshes.size(), JSON.stringify(report)])
	probe.free()
	quit(0 if bounded else 1)
