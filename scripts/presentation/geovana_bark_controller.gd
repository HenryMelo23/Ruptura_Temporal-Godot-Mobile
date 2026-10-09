extends RefCounted

const GLOBAL_COOLDOWN: float = 5.8
const HIT_COOLDOWN: float = 12.0
const KILL_COOLDOWN: float = 10.0
const SHOP_EXIT_COOLDOWN: float = 7.0
const LOW_HEALTH_COOLDOWN: float = 34.0
const AFFORDABLE_CARDS_COOLDOWN: float = 58.0
const SKILL_COOLDOWN_BARK_COOLDOWN: float = 9.0
const BOSS_KILL_COOLDOWN: float = 3.0
const AMBIENT_MIN_INTERVAL: float = 52.0
const AMBIENT_MAX_INTERVAL: float = 92.0
const DISPLAY_TIME_BASE: float = 1.15
const DISPLAY_TIME_PER_WORD: float = 0.34
const DISPLAY_TIME_PER_CHAR: float = 0.012
const DISPLAY_TIME_PUNCTUATION_PAUSE: float = 0.18
const DISPLAY_TIME_MIN: float = 2.35
const DISPLAY_TIME_MAX: float = 8.2

const PRIORITY_AMBIENT: int = 0
const PRIORITY_HIT: int = 1
const PRIORITY_KILL: int = 2
const PRIORITY_SHOP: int = 3
const PRIORITY_SKILL_BLOCKED: int = 4
const PRIORITY_AFFORDABLE: int = 5
const PRIORITY_LOW_HEALTH: int = 6
const PRIORITY_BOSS: int = 7

var active_text: String = ""
var active_context: String = ""
var active_priority: int = -1
var active_timer: float = 0.0
var active_duration: float = 0.0
var global_cooldown: float = 0.0
var context_cooldowns: Dictionary = {}
var affordable_notice_seen_this_shop_cycle: bool = false
var low_health_armed: bool = true
var next_ambient_at: float = 65.0
var last_rng_seed_second: int = -1


func update(game: Node2D, delta: float) -> void:
	active_timer = maxf(0.0, active_timer - delta)
	global_cooldown = maxf(0.0, global_cooldown - delta)
	for key in context_cooldowns.keys():
		context_cooldowns[key] = maxf(0.0, float(context_cooldowns[key]) - delta)
	_update_low_health(game)
	_update_affordable_cards(game)
	_update_ambient(game)


func request(game: Node2D, context: String, metadata: Dictionary = {}) -> bool:
	if not _barks_enabled(game):
		return false
	var priority: int = _priority_for(context)
	if active_timer > 0.0 and priority < active_priority:
		return false
	if global_cooldown > 0.0 and priority < PRIORITY_LOW_HEALTH:
		return false
	if _context_cooldown(context) > 0.0:
		return false
	if not _chance_allows(game, context, metadata):
		return false
	var line: String = _pick_line(game, context, metadata)
	if line == "":
		return false
	_show_line(context, line, priority)
	return true


func draw(game: Node2D, viewport: Vector2) -> void:
	if active_timer <= 0.0 or active_text == "":
		return
	var camera: Vector2 = game._camera(viewport)
	var player_screen: Vector2 = Vector2(game.player_pos) - camera
	var elapsed: float = maxf(0.0, active_duration - active_timer)
	var fade_in: float = clampf(elapsed / 0.18, 0.0, 1.0)
	var fade_out: float = clampf(active_timer / 0.32, 0.0, 1.0)
	var alpha: float = minf(fade_in, fade_out)
	var scale: float = 0.92 + 0.08 * fade_in
	var bubble_font: Font = _bubble_font(game)
	var font_size: int = maxi(10, game._readable_text_size(11))
	var max_width: float = minf(310.0, viewport.x * 0.42)
	if viewport.x <= 1024.0:
		max_width = minf(max_width, viewport.x * 0.32)
	var padding_x: float = 18.0
	var padding_y: float = 12.0
	var text_area_width: float = max_width - padding_x * 2.0
	var lines: Array = _wrap_lines(bubble_font, active_text, font_size, text_area_width, 4)
	var line_height: float = float(font_size) + 4.0
	var longest_line_width: float = _longest_line_width(bubble_font, lines, font_size)
	var bubble_width: float = clampf(longest_line_width + padding_x * 2.0, 118.0, max_width)
	var bubble_height: float = maxf(38.0, padding_y * 2.0 + line_height * float(lines.size()))
	var bubble_size: Vector2 = Vector2(bubble_width, bubble_height)
	var desired: Vector2 = player_screen + Vector2(42.0, -132.0)
	if desired.x + bubble_size.x > viewport.x - 18.0:
		desired.x = player_screen.x - bubble_size.x - 42.0
	var right_margin: float = 16.0
	if viewport.x <= 1024.0 and desired.y < 250.0:
		right_margin = 182.0
	desired.x = clampf(desired.x, 16.0, maxf(16.0, viewport.x - bubble_size.x - right_margin))
	desired.y = clampf(desired.y, 18.0, maxf(18.0, viewport.y - bubble_size.y - 104.0))
	var rect := Rect2(desired + bubble_size * (1.0 - scale) * 0.5, bubble_size * scale)
	var tail_side: float = -1.0 if player_screen.x < rect.get_center().x else 1.0
	var tail_tip: Vector2 = player_screen + Vector2(8.0 * -tail_side, -34.0)
	var tail_root: Vector2
	if player_screen.y > rect.end.y:
		tail_tip = player_screen + Vector2(0.0, -18.0)
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
	_draw_comic_bubble(game, rect, tail_root, tail_tip, fill, ink, shadow, cyan, magenta, alpha)
	var total_text_height: float = line_height * float(lines.size())
	var text_top: float = rect.position.y + (rect.size.y - total_text_height) * 0.5
	for i in range(lines.size()):
		var line: String = String(lines[i])
		var line_width: float = bubble_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var x: float = rect.get_center().x - line_width * 0.5
		var baseline_y: float = text_top + float(i) * line_height + bubble_font.get_ascent(font_size)
		_draw_high_contrast_text(game, bubble_font, line, Vector2(x, baseline_y), line_width + 4.0, font_size, alpha)


func _show_line(context: String, line: String, priority: int) -> void:
	active_text = line
	active_context = context
	active_priority = priority
	active_duration = _reading_duration_for(line)
	active_timer = active_duration
	global_cooldown = GLOBAL_COOLDOWN
	context_cooldowns[context] = _cooldown_for(context)


func _barks_enabled(game: Node2D) -> bool:
	if game.dedicated_server_mode:
		return false
	if game.mode in ["menu", "settings", "settings_audio", "settings_keys", "settings_gamepad", "game_over", "victory", "nick_setup"]:
		return false
	if bool(game.get("online_local_spectator")):
		return false
	return true


func _priority_for(context: String) -> int:
	match context:
		"boss_kill":
			return PRIORITY_BOSS
		"low_health":
			return PRIORITY_LOW_HEALTH
		"affordable_cards":
			return PRIORITY_AFFORDABLE
		"skill_cooldown":
			return PRIORITY_SKILL_BLOCKED
		"shop_exit":
			return PRIORITY_SHOP
		"enemy_kill":
			return PRIORITY_KILL
		"enemy_hit":
			return PRIORITY_HIT
	return PRIORITY_AMBIENT


func _cooldown_for(context: String) -> float:
	match context:
		"boss_kill":
			return BOSS_KILL_COOLDOWN
		"low_health":
			return LOW_HEALTH_COOLDOWN
		"affordable_cards":
			return AFFORDABLE_CARDS_COOLDOWN
		"skill_cooldown":
			return SKILL_COOLDOWN_BARK_COOLDOWN
		"shop_exit":
			return SHOP_EXIT_COOLDOWN
		"enemy_kill":
			return KILL_COOLDOWN
		"enemy_hit":
			return HIT_COOLDOWN
	return AMBIENT_MIN_INTERVAL


func _context_cooldown(context: String) -> float:
	return float(context_cooldowns.get(context, 0.0))


func _chance_allows(game: Node2D, context: String, metadata: Dictionary) -> bool:
	match context:
		"enemy_hit":
			var damage: float = float(metadata.get("damage", 0.0))
			if damage < maxf(12.0, float(game.player_damage) * 0.38):
				return false
			return _roll(game, 0.11)
		"enemy_kill":
			var kills: int = int(game.enemies_killed)
			if kills < 2:
				return false
			return kills % 4 == 0 or _roll(game, 0.18)
		"ambient":
			return _roll(game, 0.62)
	return true


func _pick_line(game: Node2D, context: String, metadata: Dictionary) -> String:
	var lines: Array = []
	match context:
		"affordable_cards":
			lines = ["Acho que e melhor eu melhorar meus atributos, esses monstros nao estao para brincadeira."]
		"skill_cooldown":
			lines = [
				"Calma, calma, Geovana, se nao vamos ter um treco.",
				"Eu ainda nao consigo usar.",
				"Acho que preciso esperar mais um pouco.",
				"Droga, quanto tempo esse negocio carrega?"
			]
			if int(game.current_phase) == 1:
				lines.append("VAI TEIA! ...nao, acho que nao e assim.")
		"shop_exit":
			lines = [
				"Agora eu vou esbagacar voces.",
				"Que tal agora?",
				"Nada mal pra mim, hein.",
				"Nossa, eu to com tudo.",
				"Geovaninha, a imparavel?"
			]
		"enemy_kill":
			lines = [
				"Achei que iria aguentar mais.",
				"Pensei que fosse maior.",
				"Toma essa.",
				"Nada pode me parar... NADA."
			]
		"boss_kill":
			lines = [
				"Acham que vao me parar, mas eu preciso chegar la, por voce, meu amor.",
				"Nossa, que cara parrudo.",
				"Caraca, esse deu trabalho.",
				"Tomara que o proximo seja mais facil."
			]
		"enemy_hit":
			lines = [
				"Eeeh, ta gostando?",
				"Acho que vai precisar de mais do que isso.",
				"Que tal uma pitada de dano marinada de critico?",
				"Ta achando que e quem?",
				"Vamo la, Geovana, a gente precisa ser forte."
			]
		"low_health":
			lines = [
				"NAO, NAO, NAO, EU NAO VOU DESISTIR!",
				"Nem que eu parta esse mundo no meio, eu vou continuar de pe.",
				"Vamos la, voce consegue.",
				"Sera que ele esta orgulhoso de mim?",
				"Nao, eu nao posso cair.",
				"Feet don't fail me now.",
				"Nao... eu nao posso."
			]
		"ambient":
			lines = [
				"Respira, Geovana. So mais um pouco.",
				"Se o mundo quebrou, eu quebro ele de volta.",
				"Ok... foco. Movimento primeiro, panico depois.",
				"Tem alguma coisa errada nesse lugar."
			]
	if lines.is_empty():
		return ""
	return String(lines[_stable_index(game, context, lines.size())])


func _update_low_health(game: Node2D) -> void:
	if not _barks_enabled(game) or game.mode != "game":
		return
	var ratio: float = float(game.player_hp) / maxf(1.0, float(game.player_hp_max))
	if ratio > 0.42:
		low_health_armed = true
	if ratio <= 0.28 and low_health_armed:
		if request(game, "low_health"):
			low_health_armed = false


func _update_affordable_cards(game: Node2D) -> void:
	if not _barks_enabled(game) or game.mode != "game":
		return
	var affordable: int = 0
	if game.has_method("_affordable_card_count"):
		affordable = int(game._affordable_card_count())
	if affordable <= 5:
		affordable_notice_seen_this_shop_cycle = false
		return
	if not affordable_notice_seen_this_shop_cycle and request(game, "affordable_cards", {"count": affordable}):
		affordable_notice_seen_this_shop_cycle = true


func _update_ambient(game: Node2D) -> void:
	if not _barks_enabled(game) or game.mode != "game":
		return
	if game.time_alive < next_ambient_at:
		return
	next_ambient_at = float(game.time_alive) + _rand_range(game, AMBIENT_MIN_INTERVAL, AMBIENT_MAX_INTERVAL)
	request(game, "ambient")


func _draw_comic_bubble(game: Node2D, rect: Rect2, tail_root: Vector2, tail_tip: Vector2, fill: Color, ink: Color, shadow: Color, accent: Color, pop: Color, alpha: float) -> void:
	var bubble_points: PackedVector2Array = _comic_panel_points(rect)
	var bubble_shadow: PackedVector2Array = _offset_points(bubble_points, Vector2(5.0, 6.0))
	var tail := PackedVector2Array([tail_root + Vector2(-22.0, 3.0), tail_root + Vector2(24.0, -3.0), tail_tip])
	var tail_shadow: PackedVector2Array = _offset_points(tail, Vector2(5.0, 6.0))
	game.draw_colored_polygon(tail_shadow, shadow)
	game.draw_colored_polygon(bubble_shadow, shadow)
	game.draw_colored_polygon(tail, fill)
	game.draw_colored_polygon(bubble_points, fill)
	game.draw_polyline(_closed_points(tail), ink, 5.0)
	game.draw_polyline(_closed_points(bubble_points), ink, 5.0)
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


func _reading_duration_for(text: String) -> float:
	var words: PackedStringArray = text.split(" ", false)
	var punctuation_count: int = 0
	for mark in [",", ".", "!", "?", ";", ":"]:
		punctuation_count += text.count(mark)
	var duration: float = DISPLAY_TIME_BASE
	duration += float(words.size()) * DISPLAY_TIME_PER_WORD
	duration += float(text.length()) * DISPLAY_TIME_PER_CHAR
	duration += float(punctuation_count) * DISPLAY_TIME_PUNCTUATION_PAUSE
	return clampf(duration, DISPLAY_TIME_MIN, DISPLAY_TIME_MAX)


func _stable_index(game: Node2D, context: String, count: int) -> int:
	if count <= 1:
		return 0
	var second: int = int(floor(float(game.time_alive) * 1.7))
	if second != last_rng_seed_second:
		last_rng_seed_second = second
	var salt: int = int(abs(hash("%s:%s:%s:%s" % [context, second, int(game.enemies_killed), int(game.current_phase)])))
	return salt % count


func _roll(game: Node2D, chance: float) -> bool:
	var basis: int = int(abs(hash("%s:%s:%s" % [int(game.time_alive * 10.0), int(game.enemies_killed), active_context])))
	return float(basis % 10000) / 10000.0 < chance


func _rand_range(game: Node2D, minimum: float, maximum: float) -> float:
	var basis: int = int(abs(hash("%s:%s:%s" % [int(game.time_alive), int(game.enemies_killed), int(game.current_phase)])))
	var ratio: float = float(basis % 10000) / 10000.0
	return lerpf(minimum, maximum, ratio)
