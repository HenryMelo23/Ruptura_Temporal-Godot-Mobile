extends RefCounted
## Render-only electricity. No gameplay RNG, timers, damage or network writes.
## A frame-local spatial index protects actor silhouettes, including late VFX.

const CONTEXT := &"lightning_draw_context"
const CELL := 160.0
const PERFORMANCE := 0
const HIGH := 1
const ULTRA := 2
const SEGMENTS := [8, 14, 22]
const BRANCHES := [1, 3, 5]
const DETAIL_BUDGET := [20, 48, 80]


static func quality(game: Object) -> int:
	if game.has_method("_memory_saver_active"):
		if game._memory_saver_active() or game.gfx_low_resource:
			return PERFORMANCE
		if game._runtime_visual_budget_active() or not game.gfx_particles:
			return HIGH
	return ULTRA


static func begin_frame(game: Node2D, camera: Vector2) -> void:
	# No enemy scan on frames without electricity. Build once, on the first bolt.
	game.set_meta(CONTEXT, {"grid": {}, "ellipses": [], "count": 0, "active": true, "indexed": false, "camera": camera})


static func _populate_context(game: Node2D, context: Dictionary) -> void:
	context["indexed"] = true
	var camera: Vector2 = context["camera"]
	if not game.is_dead and not game.online_local_spectator:
		add_silhouette(context, game.player_pos - camera, game.PLAYER_DRAW_BOX_SIZE * Vector2(0.47, 0.49))
	for peer in game.net_players_by_peer.values():
		if game._remote_player_state_targetable(peer):
			add_silhouette(context, Vector2(peer.get("render_pos", peer.get("pos", Vector2.ZERO))) - camera, game.PLAYER_DRAW_BOX_SIZE * Vector2(0.47, 0.49))
	if game.boss_active and not game.boss_dead:
		add_silhouette(context, game._boss_draw_position() - camera, game._boss_draw_size() * Vector2(0.43, 0.43))
	for enemy in game.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0 or not game._world_point_in_view(Vector2(enemy.get("pos", Vector2.ZERO)), camera, 120.0):
			continue
		add_silhouette(context, Vector2(enemy["pos"]) + game._enemy_visual_offset(enemy) - camera, game._enemy_draw_size(enemy) * Vector2(0.43, 0.46))


static func end_frame(game: Node2D) -> void:
	if game.has_meta(CONTEXT):
		game.get_meta(CONTEXT)["active"] = false


static func add_silhouette(context: Dictionary, center: Vector2, radii: Vector2) -> void:
	var ellipses: Array = context["ellipses"]
	var index := ellipses.size()
	ellipses.append(Rect2(center, radii.max(Vector2(8, 8))))
	var grid: Dictionary = context["grid"]
	var first := Vector2i(((center - radii) / CELL).floor())
	var last := Vector2i(((center + radii) / CELL).floor())
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var key := Vector2i(x, y)
			if not grid.has(key):
				grid[key] = []
			grid[key].append(index)


static func channel(start: Vector2, finish: Vector2, event_seed: int, elapsed: float, tier: int) -> PackedVector2Array:
	var distance := start.distance_to(finish)
	var segments := clampi(int(distance / 22.0), 3, SEGMENTS[clampi(tier, 0, 2)])
	var points := PackedVector2Array()
	points.resize(segments + 1)
	var normal := (finish - start).normalized().orthogonal()
	# A discrete restrike changes the shape, while micro-motion keeps it alive.
	var tick := floori(elapsed * (12.0 if tier == PERFORMANCE else 24.0))
	var amplitude := minf(30.0, distance * 0.09)
	for i in range(segments + 1):
		var t := float(i) / segments
		var noise := sin(float(event_seed % 65521) * 0.137 + i * 17.71 + tick * 9.17)
		var fine := sin(i * 8.31 + elapsed * 47.0 + event_seed % 71) * 0.18
		points[i] = start.lerp(finish, t) + normal * (noise + fine) * amplitude * sin(PI * t)
	points[0] = start
	points[segments] = finish
	return points


static func visible_segments(points: PackedVector2Array, context: Dictionary, padding: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	var grid: Dictionary = context.get("grid", {})
	var ellipses: Array = context.get("ellipses", [])
	if grid.is_empty():
		for i in range(1, points.size()):
			result.append(points[i - 1])
			result.append(points[i])
		return result
	for i in range(1, points.size()):
		var a := points[i - 1]
		var b := points[i]
		var first := Vector2i(((a.min(b) - Vector2.ONE * padding) / CELL).floor())
		var last := Vector2i(((a.max(b) + Vector2.ONE * padding) / CELL).floor())
		var candidates: Dictionary = {}
		for y in range(first.y, last.y + 1):
			for x in range(first.x, last.x + 1):
				for index in grid.get(Vector2i(x, y), []):
					candidates[index] = true
		var hidden: Array[Vector2] = []
		for index in candidates:
			var ellipse: Rect2 = ellipses[index]
			var radii := ellipse.size + Vector2.ONE * padding
			var origin := (a - ellipse.position) / radii
			var direction := (b - a) / radii
			var aa := direction.length_squared()
			if aa <= 0.000001:
				continue
			var bb := 2.0 * origin.dot(direction)
			var discriminant := bb * bb - 4.0 * aa * (origin.length_squared() - 1.0)
			if discriminant <= 0.0:
				continue
			var root := sqrt(discriminant)
			var lo := maxf(0.0, (-bb - root) / (2.0 * aa))
			var hi := minf(1.0, (-bb + root) / (2.0 * aa))
			if hi > lo:
				hidden.append(Vector2(lo, hi))
		hidden.sort_custom(func(left: Vector2, right: Vector2): return left.x < right.x)
		var cursor := 0.0
		for interval in hidden:
			if interval.x > cursor:
				result.append(a.lerp(b, cursor))
				result.append(a.lerp(b, interval.x))
			cursor = maxf(cursor, interval.y)
		if cursor < 1.0:
			result.append(a.lerp(b, cursor))
			result.append(b)
	return result


static func _stroke(canvas: CanvasItem, points: PackedVector2Array, context: Dictionary, tint: Color, alpha: float, width: float, tier: int) -> void:
	var glow_width := width + (5.0 if tier == ULTRA else 2.0)
	var lines := visible_segments(points, context, glow_width * 0.5)
	if lines.is_empty():
		return
	if tier == ULTRA:
		canvas.draw_multiline(lines, Color(tint, alpha * 0.12), glow_width, true)
	canvas.draw_multiline(lines, Color(tint, alpha * 0.78), width, true)
	canvas.draw_multiline(lines, Color(0.93, 0.99, 1.0, alpha * 0.92), maxf(0.8, width * 0.27), true)


static func bolt(canvas: CanvasItem, start: Vector2, finish: Vector2, event_seed: int, elapsed: float, tint: Color, alpha: float, width: float, tier: int = -1, protect_sprites: bool = true, branch_limit: int = -1) -> void:
	if alpha <= 0.005 or start.distance_squared_to(finish) < 4.0:
		return
	if tier < 0:
		tier = quality(canvas)
	tier = clampi(tier, PERFORMANCE, ULTRA)
	var context: Dictionary = canvas.get_meta(CONTEXT, {}) if protect_sprites else {}
	if not bool(context.get("active", false)):
		context = {}
	if not context.is_empty():
		if not bool(context.get("indexed", true)):
			_populate_context(canvas, context)
		context["count"] = int(context.get("count", 0)) + 1
		if int(context["count"]) > DETAIL_BUDGET[tier]:
			tier = PERFORMANCE
	var points := channel(start, finish, event_seed, elapsed, tier)
	var pulse := 0.82 + 0.18 * sin(elapsed * 39.0 + event_seed % 31)
	_stroke(canvas, points, context, tint, clampf(alpha, 0.0, 1.0) * pulse, width, tier)
	var branch_count: int = BRANCHES[tier] if branch_limit < 0 else mini(BRANCHES[tier], branch_limit)
	for branch_index in range(branch_count):
		var index := 1 + (absi(event_seed + branch_index * 7) % maxi(1, points.size() - 2))
		var origin := points[index]
		var side := -1.0 if branch_index % 2 == 0 else 1.0
		var direction := (finish - start).normalized().rotated(side * (0.55 + branch_index * 0.12))
		var length := minf(start.distance_to(finish) * 0.22, 28.0 + branch_index * 7.0)
		var end := origin + direction * length
		var fork := channel(origin, end, event_seed + branch_index * 31, elapsed, PERFORMANCE)
		_stroke(canvas, fork, context, tint, alpha * 0.48, maxf(1.0, width * 0.36), PERFORMANCE)


static func contact(canvas: CanvasItem, pos: Vector2, event_seed: int, elapsed: float, tint: Color, alpha: float, tier: int) -> void:
	# Short sparks attach to the contact point and stop at actor silhouettes.
	for i in range(3 if tier == PERFORMANCE else 7):
		var angle := i * 2.39996 + event_seed % 37 + elapsed * 1.5
		var direction := Vector2.from_angle(angle)
		bolt(canvas, pos + direction * 5.0, pos + direction * (17.0 + i * 2.0), event_seed + i, elapsed, tint, alpha * 0.7, 1.4, PERFORMANCE)
