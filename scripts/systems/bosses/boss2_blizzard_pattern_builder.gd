class_name Boss2BlizzardPatternBuilder
extends RefCounted


static func build(game: Node, vertical: bool, encounter: Rect2) -> Array:
	var waves := []
	if vertical:
		var pattern: int = game.rng.randi_range(1, 4)
		if pattern == 1:
			waves = [
				{"x": encounter.end.x + 30.0, "y": encounter.position.y, "vx": -4.2, "vy": 0.0, "width": 70.0, "direction": "left", "type": "standard"},
				{"x": encounter.end.x + 310.0, "y": encounter.position.y, "vx": -4.2, "vy": 0.0, "width": 70.0, "direction": "left", "type": "standard"},
			]
		elif pattern == 2:
			waves = [{"x": encounter.end.x + 30.0, "y": encounter.position.y, "vx": -4.0, "vy": 0.0, "width": 80.0, "direction": "left", "type": "sinusoidal", "phase": game.rng.randf_range(0.0, TAU)}]
		elif pattern == 3:
			waves = [{"x": encounter.end.x + 30.0, "y": encounter.position.y, "vx": -4.5, "vy": 0.0, "width": 80.0, "direction": "left", "type": "pivoting", "pivoted": false, "pivot_coord": encounter.position.x + 450.0, "pivot_new_vel": Vector2(0.0, 4.5)}]
		else:
			waves = [
				{"x": encounter.end.x + 30.0, "y": encounter.position.y, "vx": -4.5, "vy": 0.0, "width": 60.0, "direction": "left", "type": "standard"},
				{"x": encounter.end.x + 250.0, "y": encounter.position.y, "vx": -4.5, "vy": 0.0, "width": 60.0, "direction": "left", "type": "standard"},
				{"x": encounter.end.x + 470.0, "y": encounter.position.y, "vx": -4.5, "vy": 0.0, "width": 60.0, "direction": "left", "type": "standard"},
			]
	else:
		var pattern: int = game.rng.randi_range(1, 4)
		if pattern == 1:
			waves = [
				{"x": encounter.position.x, "y": encounter.position.y - 30.0, "vx": 0.0, "vy": 4.0, "width": 70.0, "direction": "down", "type": "standard"},
				{"x": encounter.position.x, "y": encounter.position.y - 280.0, "vx": 0.0, "vy": 4.0, "width": 70.0, "direction": "down", "type": "standard"},
			]
		elif pattern == 2:
			waves = [{"x": encounter.position.x, "y": encounter.position.y - 30.0, "vx": 0.0, "vy": 4.2, "width": 80.0, "direction": "down", "type": "pivoting", "pivoted": false, "pivot_coord": encounter.position.y + 300.0, "pivot_new_vel": Vector2(-5.0, 0.0)}]
		elif pattern == 3:
			waves = [
				{"x": encounter.position.x, "y": encounter.position.y - 30.0, "vx": 0.0, "vy": 3.6, "width": 70.0, "direction": "down", "type": "standard"},
				{"x": encounter.end.x + 30.0, "y": encounter.position.y, "vx": -3.6, "vy": 0.0, "width": 70.0, "direction": "left", "type": "standard"},
			]
		else:
			waves = [
				{"x": encounter.position.x, "y": encounter.position.y - 30.0, "vx": 0.0, "vy": 4.2, "width": 60.0, "direction": "down", "type": "standard"},
				{"x": encounter.position.x, "y": encounter.position.y - 230.0, "vx": 0.0, "vy": 4.2, "width": 60.0, "direction": "down", "type": "standard"},
				{"x": encounter.position.x, "y": encounter.position.y - 430.0, "vx": 0.0, "vy": 4.2, "width": 60.0, "direction": "down", "type": "standard"},
			]
	return waves
