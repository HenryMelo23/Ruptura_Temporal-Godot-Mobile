class_name RTSpeechBubbles
extends RefCounted

## Balao de fala em estilo HQ, generico: qualquer "falante" pode usar.
## Hoje so o monologo da primeira partida (tutorial) da Geovana usa; a ideia e
## reaproveitar para inimigos, chefes e NPCs sem duplicar desenho nem regras.
##
## Falantes:
##   "player"          -> ancorado no jogador local
##   "enemy:<uid>"     -> ancorado no inimigo com esse uid (some se ele morrer)
##   qualquer outro id -> precisa de options.anchor (Vector2, posicao no mundo)
##
## Uso: game.speech_bubbles.say(game, "enemy:%d" % uid, "Texto", {"priority": 2})
## Cada falante tem no maximo um balao; um balao de prioridade menor nao
## substitui o atual do mesmo falante. Puramente visual e local: nao passa
## pela rede e nao decide nada de gameplay.

const DISPLAY_TIME_BASE: float = 1.15
const DISPLAY_TIME_PER_WORD: float = 0.34
const DISPLAY_TIME_PER_CHAR: float = 0.012
const DISPLAY_TIME_PUNCTUATION_PAUSE: float = 0.18
const DISPLAY_TIME_MIN: float = 2.35
const DISPLAY_TIME_MAX: float = 8.2
const BUBBLE_ENEMY_NEAR_DISTANCE: float = 76.0
const BUBBLE_ENEMY_OVERLAP_MARGIN: float = 26.0
const BUBBLE_THREAT_ALPHA_MIN: float = 0.62
const BUBBLE_THREAT_REMAINING_DURATION_RATIO: float = 0.40
const BUBBLE_THREAT_MIN_REMAINING_DURATION: float = 0.72
const MAX_BUBBLES: int = 4
## Altura padrao do balao acima do pe do falante (antes da escala).
const DEFAULT_HEAD_OFFSET: Vector2 = Vector2(42.0, -132.0)

const SPEAKER_PLAYER: String = "player"

## speaker -> {text, priority, timer, duration, anchor, head_offset, threat_alpha, threat_shortened}
var bubbles: Dictionary = {}
var cooldowns: Dictionary = {}


static func enemy_speaker(uid: int) -> String:
	return "enemy:%d" % uid


func say(game: Node2D, speaker: String, text: String, options: Dictionary = {}) -> bool:
	if text.strip_edges() == "" or not enabled(game):
		return false
	var priority: int = int(options.get("priority", 0))
	var current: Dictionary = bubbles.get(speaker, {})
	if not current.is_empty() and float(current.get("timer", 0.0)) > 0.0 and priority < int(current.get("priority", 0)):
		return false
	var cooldown_key: String = String(options.get("cooldown_key", ""))
	if cooldown_key != "" and float(cooldowns.get(cooldown_key, 0.0)) > 0.0:
		return false
	if current.is_empty() and bubbles.size() >= MAX_BUBBLES:
		return false
	var duration: float = float(options.get("duration", reading_duration_for(text)))
	bubbles[speaker] = {
		"text": text,
		"priority": priority,
		"timer": duration,
		"duration": duration,
		"anchor": options.get("anchor", null),
		"head_offset": Vector2(options.get("head_offset", DEFAULT_HEAD_OFFSET)),
		"threat_alpha": 0.0,
		"threat_shortened": false,
	}
	if cooldown_key != "":
		cooldowns[cooldown_key] = float(options.get("cooldown", 0.0))
	return true


func is_speaking(speaker: String) -> bool:
	return float(Dictionary(bubbles.get(speaker, {})).get("timer", 0.0)) > 0.0


func text_of(speaker: String) -> String:
	return String(Dictionary(bubbles.get(speaker, {})).get("text", ""))


func silence(speaker: String) -> void:
	bubbles.erase(speaker)


func clear() -> void:
	bubbles.clear()
	cooldowns.clear()


func enabled(game: Node2D) -> bool:
	if game.dedicated_server_mode:
		return false
	if game.mode in ["menu", "settings", "settings_audio", "settings_keys", "settings_gamepad", "game_over", "victory", "nick_setup"]:
		return false
	if bool(game.get("online_local_spectator")):
		return false
	return true


func update(game: Node2D, delta: float) -> void:
	for key in cooldowns.keys():
		cooldowns[key] = maxf(0.0, float(cooldowns[key]) - delta)
	if bubbles.is_empty():
		return
	if not enabled(game):
		bubbles.clear()
		return
	for speaker in bubbles.keys():
		var bubble: Dictionary = bubbles[speaker]
		bubble["timer"] = maxf(0.0, float(bubble.get("timer", 0.0)) - delta)
		if float(bubble["timer"]) <= 0.0 or not _anchor_world(game, String(speaker), bubble).is_finite():
			bubbles.erase(speaker)


func draw(game: Node2D, viewport: Vector2) -> void:
	if bubbles.is_empty() or not enabled(game):
		return
	var camera: Vector2 = game._camera(viewport)
	for speaker in bubbles.keys():
		var bubble: Dictionary = bubbles[speaker]
		var world: Vector2 = _anchor_world(game, String(speaker), bubble)
		if not world.is_finite():
			continue
		_draw_bubble(game, viewport, camera, world - camera, bubble)


func _anchor_world(game: Node2D, speaker: String, bubble: Dictionary) -> Vector2:
	if speaker == SPEAKER_PLAYER:
		return Vector2(game.player_pos)
	if speaker.begins_with("enemy:"):
		var uid: int = int(speaker.substr(6))
		for enemy in game.enemies:
			if int(enemy.get("uid", -1)) == uid and float(enemy.get("hp", 0.0)) > 0.0:
				return Vector2(enemy["pos"])
		return Vector2.INF
	var anchor = bubble.get("anchor", null)
	if anchor is Vector2:
		return anchor
	return Vector2.INF


func _draw_bubble(game: Node2D, viewport: Vector2, camera: Vector2, speaker_screen: Vector2, bubble: Dictionary) -> void:
	var bubble_scale: float = clampf(float(game.geovana_bark_scale), 0.5, 1.5)
	var active_text: String = String(bubble.get("text", ""))
	var active_timer: float = float(bubble.get("timer", 0.0))
	var active_duration: float = float(bubble.get("duration", 1.0))
	var elapsed: float = maxf(0.0, active_duration - active_timer)
	var fade_in: float = clampf(elapsed / 0.18, 0.0, 1.0)
	var fade_out: float = clampf(active_timer / 0.32, 0.0, 1.0)
	var alpha: float = minf(fade_in, fade_out)
	var scale: float = 0.92 + 0.08 * fade_in
	var bubble_font: Font = _bubble_font(game)
	var font_size: int = maxi(7, int(round(float(game._readable_text_size(11)) * bubble_scale)))
	var max_width: float = minf(310.0 * bubble_scale, viewport.x * 0.42)
	if viewport.x <= 1024.0:
		max_width = minf(max_width, viewport.x * 0.32)
	var padding_x: float = 18.0 * bubble_scale
	var padding_y: float = 12.0 * bubble_scale
	var text_area_width: float = max_width - padding_x * 2.0
	var lines: Array = _wrap_lines(bubble_font, active_text, font_size, text_area_width, 4)
	var line_height: float = float(font_size) + maxf(2.0, 4.0 * bubble_scale)
	var longest_line_width: float = _longest_line_width(bubble_font, lines, font_size)
	var bubble_width: float = clampf(longest_line_width + padding_x * 2.0, 118.0 * bubble_scale, max_width)
	var bubble_height: float = maxf(38.0 * bubble_scale, padding_y * 2.0 + line_height * float(lines.size()))
	var bubble_size: Vector2 = Vector2(bubble_width, bubble_height)
	var desired: Vector2 = speaker_screen + Vector2(bubble.get("head_offset", DEFAULT_HEAD_OFFSET)) * bubble_scale
	if desired.x + bubble_size.x > viewport.x - 18.0:
		desired.x = speaker_screen.x - bubble_size.x - 42.0
	var right_margin: float = 16.0
	if viewport.x <= 1024.0 and desired.y < 250.0:
		right_margin = 182.0
	desired.x = clampf(desired.x, 16.0, maxf(16.0, viewport.x - bubble_size.x - right_margin))
	desired.y = clampf(desired.y, 18.0, maxf(18.0, viewport.y - bubble_size.y - 104.0))
	var rect := Rect2(desired + bubble_size * (1.0 - scale) * 0.5, bubble_size * scale)
	var enemy_threat: float = _bubble_enemy_threat(game, camera, rect)
	if enemy_threat > 0.0:
		bubble["threat_alpha"] = maxf(float(bubble.get("threat_alpha", 0.0)), enemy_threat)
		if not bool(bubble.get("threat_shortened", false)):
			bubble["threat_shortened"] = true
			var shortened_time: float = maxf(BUBBLE_THREAT_MIN_REMAINING_DURATION, active_duration * BUBBLE_THREAT_REMAINING_DURATION_RATIO)
			bubble["timer"] = minf(active_timer, shortened_time)
	var threat_alpha: float = maxf(enemy_threat, float(bubble.get("threat_alpha", 0.0)))
	alpha *= lerpf(1.0, BUBBLE_THREAT_ALPHA_MIN, threat_alpha)
	var tail_side: float = -1.0 if speaker_screen.x < rect.get_center().x else 1.0
	var tail_tip: Vector2 = speaker_screen + Vector2(8.0 * -tail_side, -34.0)
	var tail_root: Vector2
	if speaker_screen.y > rect.end.y:
		tail_tip = speaker_screen + Vector2(0.0, -18.0)
		tail_root = Vector2(clampf(tail_tip.x, rect.position.x + 32.0, rect.end.x - 32.0), rect.end.y - 3.0)
	elif tail_tip.y > rect.get_center().y:
		tail_root = Vector2(clampf(tail_tip.x, rect.position.x + 32.0, rect.end.x - 32.0), rect.end.y - 3.0)
	else:
		tail_root = rect.get_center() + Vector2(tail_side * rect.size.x * 0.34, rect.size.y * 0.24)
		if tail_tip.x < rect.position.x or tail_tip.x > rect.end.x:
			tail_root.x = clampf(tail_tip.x, rect.position.x + 54.0, rect.end.x - 54.0)
	var fill := Color(1.0, 0.985, 0.91, 0.99 * alpha)
	var ink := Color(0.0, 0.0, 0.0, 1.0 * alpha)
	var shadow := Color(0.0, 0.0, 0.0, 0.42 * alpha)
	var cyan := Color(0.28, 0.95, 1.0, 0.54 * alpha)
	var magenta := Color(1.0, 0.24, 0.56, 0.48 * alpha)
	_draw_comic_bubble(game, rect, tail_root, tail_tip, fill, ink, shadow, cyan, magenta, alpha, bubble_scale)
	var total_text_height: float = line_height * float(lines.size())
	var text_top: float = rect.position.y + (rect.size.y - total_text_height) * 0.5
	for i in range(lines.size()):
		var line: String = String(lines[i])
		var line_width: float = bubble_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var x: float = rect.get_center().x - line_width * 0.5
		var baseline_y: float = text_top + float(i) * line_height + bubble_font.get_ascent(font_size)
		_draw_high_contrast_text(game, bubble_font, line, Vector2(x, baseline_y), line_width + 4.0, font_size, alpha)


func reading_duration_for(text: String) -> float:
	var words: PackedStringArray = text.split(" ", false)
	var punctuation_count: int = 0
	for mark in [",", ".", "!", "?", ";", ":"]:
		punctuation_count += text.count(mark)
	var duration: float = DISPLAY_TIME_BASE
	duration += float(words.size()) * DISPLAY_TIME_PER_WORD
	duration += float(text.length()) * DISPLAY_TIME_PER_CHAR
	duration += float(punctuation_count) * DISPLAY_TIME_PUNCTUATION_PAUSE
	return clampf(duration, DISPLAY_TIME_MIN, DISPLAY_TIME_MAX)


func _bubble_enemy_threat(game: Node2D, camera: Vector2, rect: Rect2) -> float:
	var expanded_rect: Rect2 = rect.grow(BUBBLE_ENEMY_OVERLAP_MARGIN)
	var near_distance_sq: float = BUBBLE_ENEMY_NEAR_DISTANCE * BUBBLE_ENEMY_NEAR_DISTANCE
	var nearest_distance_sq: float = INF
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var screen_pos: Vector2 = Vector2(enemy.get("pos", game.player_pos)) - camera
		if expanded_rect.has_point(screen_pos):
			return 1.0
		var closest: Vector2 = Vector2(
			clampf(screen_pos.x, rect.position.x, rect.end.x),
			clampf(screen_pos.y, rect.position.y, rect.end.y)
		)
		nearest_distance_sq = minf(nearest_distance_sq, screen_pos.distance_squared_to(closest))
	if nearest_distance_sq >= near_distance_sq:
		return 0.0
	return clampf(1.0 - sqrt(nearest_distance_sq) / BUBBLE_ENEMY_NEAR_DISTANCE, 0.18, 0.72)


func _draw_comic_bubble(game: Node2D, rect: Rect2, tail_root: Vector2, tail_tip: Vector2, fill: Color, ink: Color, shadow: Color, accent: Color, pop: Color, alpha: float, style_scale: float) -> void:
	var bubble_points: PackedVector2Array = _comic_panel_points(rect)
	var bubble_shadow: PackedVector2Array = _offset_points(bubble_points, Vector2(5.0, 6.0))
	var tail := PackedVector2Array([tail_root + Vector2(-22.0, 3.0), tail_root + Vector2(24.0, -3.0), tail_tip])
	var tail_shadow: PackedVector2Array = _offset_points(tail, Vector2(5.0, 6.0))
	game.draw_colored_polygon(tail_shadow, shadow)
	game.draw_colored_polygon(bubble_shadow, shadow)
	game.draw_colored_polygon(tail, fill)
	game.draw_colored_polygon(bubble_points, fill)
	var outline_width: float = maxf(1.6, 5.0 * style_scale)
	game.draw_polyline(_closed_points(tail), ink, outline_width)
	game.draw_polyline(_closed_points(bubble_points), ink, outline_width)
	game.draw_polyline(_closed_points(_shrink_points(bubble_points, rect.get_center(), 0.972)), Color(0.42, 0.34, 0.20, 0.26 * alpha), 1.4)
	_draw_halftone(game, rect, Color(0.0, 0.0, 0.0, 0.13 * alpha))
	_draw_comic_speed_marks(game, rect, ink, accent, pop, alpha)


func _bubble_font(game: Node2D) -> Font:
	var fallback: Font = ThemeDB.fallback_font
	if fallback != null:
		return fallback
	return game.font


func _draw_high_contrast_text(game: Node2D, bubble_font: Font, text: String, pos: Vector2, width: float, size: int, alpha: float) -> void:
	var outline: Color = Color(1.0, 0.98, 0.82, 0.68 * alpha)
	var shadow: Color = Color(0.0, 0.0, 0.0, 0.45 * alpha)
	var ink: Color = Color(0.0, 0.0, 0.0, alpha)
	for offset in [Vector2(-0.75, 0.0), Vector2(0.75, 0.0), Vector2(0.0, -0.75), Vector2(0.0, 0.75)]:
		game.draw_string(bubble_font, pos + offset, text, HORIZONTAL_ALIGNMENT_LEFT, width, size, outline)
	game.draw_string(bubble_font, pos + Vector2(1.25, 1.25), text, HORIZONTAL_ALIGNMENT_LEFT, width, size, shadow)
	game.draw_string(bubble_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, size, ink)


func _comic_panel_points(rect: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var radius: float = minf(15.0, minf(rect.size.x, rect.size.y) * 0.28)
	var steps: int = 7
	var corners: Array = [
		{"center": rect.position + Vector2(radius, radius), "from": PI, "to": PI * 1.5},
		{"center": rect.position + Vector2(rect.size.x - radius, radius), "from": PI * 1.5, "to": TAU},
		{"center": rect.position + Vector2(rect.size.x - radius, rect.size.y - radius), "from": 0.0, "to": PI * 0.5},
		{"center": rect.position + Vector2(radius, rect.size.y - radius), "from": PI * 0.5, "to": PI}
	]
	for corner_index in range(corners.size()):
		var corner: Dictionary = corners[corner_index]
		for i in range(steps + 1):
			var ratio: float = float(i) / float(steps)
			var a: float = lerpf(float(corner["from"]), float(corner["to"]), ratio)
			var wobble: float = 1.0 + sin(float(corner_index * 5 + i) * 1.73) * 0.025
			points.append(Vector2(corner["center"]) + Vector2(cos(a), sin(a)) * radius * wobble)
	return points


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed := PackedVector2Array(points)
	if points.size() > 0:
		closed.append(points[0])
	return closed


func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var shifted := PackedVector2Array()
	for p in points:
		shifted.append(p + offset)
	return shifted


func _shrink_points(points: PackedVector2Array, center: Vector2, ratio: float) -> PackedVector2Array:
	var shrunk := PackedVector2Array()
	for p in points:
		shrunk.append(center + (p - center) * ratio)
	return shrunk


func _draw_halftone(game: Node2D, rect: Rect2, color: Color) -> void:
	var start: Vector2 = rect.position + Vector2(rect.size.x - 48.0, 12.0)
	for row in range(3):
		for col in range(4):
			var radius: float = 0.8 + float(3 - col) * 0.18 + float(row) * 0.04
			game.draw_circle(start + Vector2(float(col) * 8.0, float(row) * 7.0), radius, color)
	var bottom: Vector2 = rect.position + Vector2(22.0, rect.size.y - 14.0)
	for i in range(4):
		game.draw_circle(bottom + Vector2(float(i) * 8.0, sin(float(i)) * 2.0), 0.8, color)


func _draw_comic_speed_marks(game: Node2D, rect: Rect2, ink: Color, accent: Color, pop: Color, alpha: float) -> void:
	var left: Vector2 = rect.position + Vector2(10.0, rect.size.y * 0.30)
	game.draw_line(left + Vector2(-13.0, -8.0), left + Vector2(-4.0, -3.0), Color(ink.r, ink.g, ink.b, 0.54 * alpha), 1.6)
	game.draw_line(left + Vector2(-15.0, 6.0), left + Vector2(-4.0, 4.0), Color(ink.r, ink.g, ink.b, 0.42 * alpha), 1.3)
	var right: Vector2 = rect.end - Vector2(13.0, rect.size.y * 0.30)
	game.draw_line(right + Vector2(4.0, -6.0), right + Vector2(15.0, -11.0), Color(ink.r, ink.g, ink.b, 0.46 * alpha), 1.5)
	game.draw_rect(Rect2(rect.position + Vector2(28.0, 8.0), Vector2(6.0, 3.0)), pop, true)
	game.draw_rect(Rect2(rect.end - Vector2(32.0, 13.0), Vector2(8.0, 3.0)), accent, true)


func _wrap_lines(bubble_font: Font, text: String, size: int, max_width: float, max_lines: int) -> Array:
	var words: PackedStringArray = text.split(" ", false)
	var lines: Array = []
	var current: String = ""
	var truncated: bool = false
	for word_index in range(words.size()):
		var word: String = words[word_index]
		var candidate: String = word if current == "" else current + " " + word
		if bubble_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= max_width:
			current = candidate
		else:
			if current != "":
				lines.append(current)
			current = word
			if lines.size() >= max_lines - 1:
				truncated = word_index < words.size() - 1
				break
	if current != "" and lines.size() < max_lines:
		lines.append(_ellipsize_line(bubble_font, current, size, max_width) if truncated else current)
	if lines.is_empty():
		lines.append(text)
	return lines


func _longest_line_width(bubble_font: Font, lines: Array, size: int) -> float:
	var longest: float = 0.0
	for line in lines:
		longest = maxf(longest, bubble_font.get_string_size(String(line), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
	return longest


func _ellipsize_line(bubble_font: Font, text: String, size: int, max_width: float) -> String:
	var result: String = text
	while result.length() > 1 and bubble_font.get_string_size(result + "...", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_width:
		result = result.substr(0, result.length() - 1).strip_edges()
	return result + "..."
