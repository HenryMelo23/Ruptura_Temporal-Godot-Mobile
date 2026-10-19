extends SceneTree

const Lightning = preload("res://scripts/presentation/lightning_presentation.gd")
const Director = preload("res://scripts/vfx_director.gd")
var failed := false


func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)


func _initialize() -> void:
	var start := Vector2(-300, 0)
	var finish := Vector2(300, 0)
	var context := {"grid": {}, "ellipses": [], "active": true}
	Lightning.add_silhouette(context, Vector2.ZERO, Vector2(40, 60))
	Lightning.add_silhouette(context, Vector2(25, 0), Vector2(40, 60))
	for tier in range(3):
		var path := Lightning.channel(start, finish, 913, 0.05, tier)
		check(path == Lightning.channel(start, finish, 913, 0.05, tier), "non deterministic channel")
		check(path != Lightning.channel(start, finish, 913, 0.15, tier), "static lightning")
		check(path[0] == start and path[-1] == finish, "endpoints drifted")
		check(path.size() <= Lightning.SEGMENTS[tier] + 1, "geometry budget exceeded")
		var lines := Lightning.visible_segments(path, context, 4.0)
		check(not lines.is_empty() and lines.size() % 2 == 0, "lost complete bolt")
		for i in range(0, lines.size(), 2):
			for step in range(21):
				var point := lines[i].lerp(lines[i + 1], float(step) / 20.0)
				for ellipse: Rect2 in context.ellipses:
					check(((point - ellipse.position) / (ellipse.size + Vector2.ONE * 4.0)).length() >= 0.999, "bolt cuts sprite silhouette")
	var inside := Lightning.visible_segments(PackedVector2Array([Vector2(-3, 0), Vector2(3, 0)]), context, 4.0)
	check(inside.is_empty(), "fully occluded segment still drawn")
	var straight := Lightning.visible_segments(PackedVector2Array([start, finish]), context, 4.0)
	check(straight.size() == 4, "overlapping silhouettes reconnected the bolt")
	var director := Director.new(false)
	for i in range(100):
		director.request_sky_lightning_strike(Vector2(i, 200))
	check(director.sky_lightning_bolts.size() == 24, "sky strike cap")
	check(director.impact_rings.is_empty(), "particles disabled spawned decoration")
	director.update(1.0)
	check(director.sky_lightning_bolts.is_empty(), "performance lightning does not expire")
	if not failed:
		print("LIGHTNING_PRESENTATION_OK dynamic=true deterministic=true endpoints=true occlusion=true overlapping_masks=true bounded=true performance_no_particles=true cleanup=true")
	quit(1 if failed else 0)
