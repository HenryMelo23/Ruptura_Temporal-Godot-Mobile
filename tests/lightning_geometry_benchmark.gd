extends SceneTree
## CPU geometry only: excludes GPU, draw calls and runtime silhouette discovery.
const Lightning = preload("res://scripts/presentation/lightning_presentation.gd")


func _initialize() -> void:
	for tier in [Lightning.PERFORMANCE, Lightning.ULTRA]:
		var samples: Array[int] = []
		var output_pairs := 0
		for frame in range(110):
			var started := Time.get_ticks_usec()
			var context := {"grid": {}, "ellipses": [], "active": true}
			for actor in range(120):
				Lightning.add_silhouette(context, Vector2(60 + (actor % 15) * 100, 70 + (actor / 15) * 100), Vector2(25, 35))
			for event in range(12):
				var start := Vector2(50 + event * 80, 40)
				var finish := start + Vector2(110, 650)
				var points := Lightning.channel(start, finish, event * 17, frame / 60.0, tier)
				output_pairs += Lightning.visible_segments(points, context, 5.0).size() / 2
				for fork in range(Lightning.BRANCHES[tier]):
					var origin := points[1 + fork % (points.size() - 2)]
					var branch := Lightning.channel(origin, origin + Vector2(28, 20), event + fork, frame / 60.0, Lightning.PERFORMANCE)
					output_pairs += Lightning.visible_segments(branch, context, 2.0).size() / 2
			if frame >= 10:
				samples.append(Time.get_ticks_usec() - started)
		samples.sort()
		var total := 0
		for sample in samples:
			total += sample
		print("LIGHTNING_GEOMETRY_BENCH tier=%s actors=120 bolts=12 samples=100 mean_us=%.1f p95_us=%d pairs=%d GPU_NOT_MEASURED" % ["performance" if tier == 0 else "ultra", total / 100.0, samples[94], output_pairs])
	quit()
