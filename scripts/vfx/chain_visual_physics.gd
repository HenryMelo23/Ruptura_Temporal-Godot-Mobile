extends RefCounted

# Host-owned state and compatibility wrappers are retained during extraction.


static func _init_chain_physics(game: Node2D, a: Vector2, b: Vector2, kind: = "heavy") -> Dictionary:
	var distance: float = a.distance_to(b)
	var spacing: float = 18.0 if kind == "light" else 22.0
	var num_nodes: int = clamp(int(distance / spacing), 8, 28)
	var chain: Dictionary = {
		"points": [], 
		"progress": 0.0, 
		"a": a, 
		"b": a, 
		"target_b": b, 
		"ripple_t": 0.0, 
		"ripple_amp": 260.0, 
		"kind": kind
	}
	for i in range(num_nodes):
		var t: float = float(i) / float(num_nodes - 1)
		var pos: Vector2 = a.lerp(b, t)
		chain["points"].append({
			"pos": pos, 
			"prev_pos": pos, 
			"fixed": (i == 0 or i == num_nodes - 1)
		})
	return chain


static func _update_single_chain_physics(game: Node2D, chain: Dictionary, a_curr: Vector2, b_target: Vector2, delta: float) -> void :
	if delta <= 0.0:
		return

	if float(chain.get("progress", 0.0)) < 1.0:
		chain["progress"] = minf(1.0, float(chain.get("progress", 0.0)) + delta * 6.5)

	var progress: float = float(chain.get("progress", 0.0))
	var b_curr: Vector2 = a_curr.lerp(b_target, progress)

	chain["a"] = a_curr
	chain["b"] = b_curr
	chain["target_b"] = b_target

	var points: Array = chain.get("points", [])
	var num_nodes: int = points.size()
	if num_nodes < 2:
		return

	var gravity: Vector2 = Vector2(0.0, 6000.0)
	var damping: float = 0.94

	var ripple_amp: float = float(chain.get("ripple_amp", 0.0))
	var ripple_t: float = float(chain.get("ripple_t", 0.0))
	if ripple_amp > 0.0:
		ripple_t += delta
		ripple_amp = maxf(0.0, ripple_amp - delta * 150.0)
		chain["ripple_t"] = ripple_t
		chain["ripple_amp"] = ripple_amp

	var dir: Vector2 = (b_curr - a_curr).normalized()
	if dir.length() <= 0.01:
		dir = Vector2.RIGHT
	var normal: Vector2 = dir.orthogonal()

	for i in range(num_nodes):
		var p: Dictionary = points[i]
		if i == 0:
			p["pos"] = a_curr
			p["fixed"] = true
		elif i == num_nodes - 1:
			p["pos"] = b_curr
			p["fixed"] = true
		else:
			p["fixed"] = false

		if not bool(p.get("fixed", false)):
			var pos: Vector2 = Vector2(p.get("pos", Vector2.ZERO))
			var prev_pos: Vector2 = Vector2(p.get("prev_pos", pos))
			var temp: Vector2 = pos
			var velocity: Vector2 = (pos - prev_pos) * damping
			pos += velocity + gravity * delta * delta
			p["pos"] = pos
			p["prev_pos"] = temp

			if ripple_amp > 0.0:
				var k: float = float(i) / float(num_nodes - 1)
				var wave: float = sin(k * PI * 3.0 - ripple_t * 25.0)
				p["pos"] = pos + normal * wave * ripple_amp * delta

	var total_dist: float = a_curr.distance_to(b_curr)
	var rest_length: float = total_dist / float(num_nodes - 1)
	if rest_length > 0.1:
		for iter in range(3):
			for i in range(num_nodes - 1):
				var p1: Dictionary = points[i]
				var p2: Dictionary = points[i + 1]
				var pos1: Vector2 = Vector2(p1.get("pos", Vector2.ZERO))
				var pos2: Vector2 = Vector2(p2.get("pos", Vector2.ZERO))
				var delta_vec: Vector2 = pos2 - pos1
				var dist: float = delta_vec.length()
				if dist > 0.01:
					var diff: float = rest_length - dist
					var percent: float = (diff / dist) * 0.5
					var offset: Vector2 = delta_vec * percent
					var f1: bool = bool(p1.get("fixed", false))
					var f2: bool = bool(p2.get("fixed", false))
					if f1 and f2:
						pass
					elif f1:
						p2["pos"] = pos2 + offset * 2.0
					elif f2:
						p1["pos"] = pos1 - offset * 2.0
					else:
						p1["pos"] = pos1 - offset
						p2["pos"] = pos2 + offset


static func _init_link_chain_physics(game: Node2D, link: Dictionary) -> void :
	var kind: String = String(link.get("kind", ""))
	if kind == "anchor":
		var target: Dictionary = link.get("target", {})
		var target_pos: Vector2 = game._acorrentada_target_pos(target) if not target.is_empty() else Vector2(link.get("anchor"))
		link["physics"] = game._init_chain_physics(Vector2(link.get("anchor")), target_pos, "heavy")
	elif kind == "pair" or kind == "triad":
		var targets: Array = link.get("targets", [])
		var chains: Dictionary = {}
		for i in range(targets.size()):
			for j in range(i + 1, targets.size()):
				var a: Vector2 = game._acorrentada_target_pos(targets[i])
				var b: Vector2 = game._acorrentada_target_pos(targets[j])
				chains["%d_%d" % [i, j]] = game._init_chain_physics(a, b, "heavy")
		link["chains"] = chains
