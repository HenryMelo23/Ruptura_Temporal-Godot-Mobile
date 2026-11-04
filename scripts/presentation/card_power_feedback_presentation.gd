extends RefCounted


static func draw_effect(game: Node2D, camera: Vector2, effect: Dictionary, pos: Vector2, ratio: float, radius: float, color: Color, time: float) -> bool:
	match String(effect.get("kind", "")):
		"card_power_acquired":
			var progress: float = 1.0 - ratio
			var power: float = float(effect.get("power", 1.0))
			var segments: int = 6 if game._memory_saver_active() else 10
			game.draw_circle(pos, radius * (0.16 + progress * 0.28), Color(color.r, color.g, color.b, 0.12 * ratio))
			game.draw_arc(pos, radius * (0.62 + progress * 0.38), - time * 2.4, TAU - time * 2.4, 56, Color(color.r, color.g, color.b, 0.82 * ratio), 4.0 + power)
			game.draw_arc(pos, radius * (0.38 + progress * 0.24), time * 3.1, time * 3.1 + PI * 1.62, 42, Color(1.0, 1.0, 1.0, 0.62 * ratio), 2.2)
			for index in range(segments):
				var direction: Vector2 = Vector2.from_angle(float(index) * TAU / float(segments) + time * 0.22)
				game.draw_line(pos + direction * radius * 0.34, pos + direction * radius * (0.72 + 0.22 * progress), Color(color.r, color.g, color.b, 0.62 * ratio), 2.0 + power, true)
		"card_speed_trail":
			var from: Vector2 = Vector2(effect.get("from", effect.get("pos", game.player_pos))) - camera
			var direction: Vector2 = (pos - from).normalized()
			var side: Vector2 = direction.orthogonal()
			for index in range(2 if game._memory_saver_active() else 4):
				var offset: float = (float(index) - 1.5) * 7.0
				game.draw_line(from + side * offset, pos - direction * float(index) * 5.0 + side * offset * 0.35, Color(color.r, color.g, color.b, (0.46 - float(index) * 0.07) * ratio), 3.0 - float(index) * 0.35, true)
		"card_power_hit":
			var origin: Vector2 = Vector2(effect.get("origin", game.player_pos)) - camera
			var direction: Vector2 = (pos - origin).normalized()
			var side: Vector2 = direction.orthogonal()
			game.draw_line(pos - direction * radius * 0.85, pos + direction * radius * 0.32, Color(color.r, color.g, color.b, 0.82 * ratio), 5.0, true)
			for sign_value in [-1.0, 1.0]:
				var tip: Vector2 = pos - direction * radius * 0.1 + side * radius * 0.46 * sign_value
				game.draw_line(pos - direction * radius * 0.48, tip, Color(1.0, 0.72, 0.36, 0.62 * ratio), 3.0, true)
		"card_critical_hit":
			var points: int = 6 if game._memory_saver_active() else 10
			for index in range(points):
				var angle: float = float(index) * TAU / float(points) + time * 0.08
				var direction: Vector2 = Vector2.from_angle(angle)
				var inner: float = radius * (0.16 if index % 2 == 0 else 0.28)
				game.draw_line(pos + direction * inner, pos + direction * radius * (0.72 + 0.2 * (1.0 - ratio)), Color(1.0, 0.84, 0.2, 0.84 * ratio), 3.6 if index % 2 == 0 else 2.2, true)
			game.draw_circle(pos, radius * 0.18, Color(1.0, 0.96, 0.68, 0.42 * ratio))
		"card_lifesteal":
			var target: Vector2 = Vector2(effect.get("target", game.player_pos)) - camera
			var side: Vector2 = (target - pos).normalized().orthogonal()
			for index in range(2 if game._memory_saver_active() else 3):
				var offset: float = (float(index) - 1.0) * 7.0 * sin((1.0 - ratio) * PI)
				game.draw_line(pos + side * offset, target - side * offset, Color(0.95, 0.1 + float(index) * 0.16, 0.34, (0.72 - float(index) * 0.12) * ratio), 3.2 - float(index) * 0.55, true)
			game.draw_circle(target, 8.0 + 7.0 * (1.0 - ratio), Color(0.42, 1.0, 0.58, 0.32 * ratio))
		"card_defense_block":
			game.draw_arc(pos, radius, PI * 0.72, PI * 2.28, 44, Color(0.58, 0.86, 1.0, 0.82 * ratio), 5.0)
			game.draw_arc(pos, radius * 0.72, PI * 0.82, PI * 2.18, 36, Color(0.9, 0.97, 1.0, 0.54 * ratio), 2.4)
			for sign_value in [-1.0, 1.0]:
				game.draw_line(pos + Vector2(sign_value * radius * 0.48, - radius * 0.22), pos + Vector2(sign_value * radius * 0.2, radius * 0.38), Color(0.58, 0.86, 1.0, 0.48 * ratio), 2.2, true)
		"card_overkill":
			var rays: int = 7 if game._memory_saver_active() else 12
			var power: float = float(effect.get("power", 0.0))
			for index in range(rays):
				var direction: Vector2 = Vector2.from_angle(float(index) * TAU / float(rays) + sin(float(index) * 2.7) * 0.18)
				game.draw_line(pos + direction * radius * 0.22, pos + direction * radius * (0.68 + power * 0.18), Color(1.0, 0.34 + float(index % 3) * 0.12, 0.16, 0.76 * ratio), 3.4, true)
			game.draw_arc(pos, radius * 0.54, time * 1.8, time * 1.8 + PI * 1.5, 34, Color(1.0, 0.82, 0.42, 0.56 * ratio), 3.0)
		"enemy_threat_impact":
			var progress: float = 1.0 - ratio
			game.draw_circle(pos, radius * (0.28 + progress * 0.36), Color(0.42, 0.0, 0.02, 0.18 * ratio))
			for index in range(4):
				var direction: Vector2 = Vector2.from_angle(PI * 0.25 + float(index) * PI * 0.5)
				game.draw_line(pos + direction * radius * 0.36, pos + direction * radius * (0.82 + progress * 0.18), Color(1.0, 0.12, 0.08, 0.78 * ratio), 5.0, true)
			game.draw_arc(pos, radius, time * 0.8, TAU + time * 0.8, 48, Color(1.0, 0.34, 0.16, 0.64 * ratio), 3.0)
		_:
			return false
	return true
