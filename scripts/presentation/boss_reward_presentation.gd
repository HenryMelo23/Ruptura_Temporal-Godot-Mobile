extends RefCounted

# Presentation only. The runtime grants the cards before constructing this immutable snapshot.


static func total_duration(game: Node2D, snapshot: Dictionary) -> float:
	var count: int = Array(snapshot.get("card_ids", [])).size()
	if count <= 0:
		return 0.0
	return game.BOSS_REWARD_REVEAL_SHAKE_TIME + game.BOSS_REWARD_REVEAL_EMERGE_TIME + game.BOSS_REWARD_REVEAL_HOVER_TIME + game.BOSS_REWARD_REVEAL_CARD_STAGGER * float(maxi(0, count - 1)) + game.BOSS_REWARD_REVEAL_COLLECT_TIME


static func draw(game: Node2D, camera: Vector2) -> void:
	var snapshot: Dictionary = game.boss_reward_reveal
	if snapshot.is_empty() or int(snapshot.get("recipient_peer_id", 0)) != game._mp_unique_id():
		return
	var card_ids: Array = Array(snapshot.get("card_ids", []))
	if card_ids.is_empty():
		return
	var elapsed: float = maxf(0.0, float(snapshot.get("elapsed", 0.0)))
	var origin: Vector2 = Vector2(snapshot.get("origin", game.boss_pos))
	var shake_end: float = game.BOSS_REWARD_REVEAL_SHAKE_TIME
	var emerge_end: float = shake_end + game.BOSS_REWARD_REVEAL_EMERGE_TIME
	var collect_start: float = emerge_end + game.BOSS_REWARD_REVEAL_HOVER_TIME
	if elapsed < emerge_end:
		_draw_boss_exit(game, camera, origin, elapsed, shake_end, emerge_end)
	for index in range(card_ids.size()):
		_draw_reward_card(game, camera, origin, game.player_pos, String(card_ids[index]), index, card_ids.size(), elapsed, shake_end, emerge_end, collect_start)


static func _draw_boss_exit(game: Node2D, camera: Vector2, origin: Vector2, elapsed: float, shake_end: float, emerge_end: float) -> void:
	var texture: Texture2D = game._boss_texture()
	var boss_size: Vector2 = game._boss_draw_size()
	var boss_screen: Vector2 = origin - camera
	if elapsed < shake_end:
		var shake: float = sin(elapsed * 64.0) * (2.0 + elapsed / maxf(0.01, shake_end) * 5.0)
		var alpha: float = 1.0 - elapsed / maxf(0.01, shake_end) * 0.18
		game._draw_entity_fit(texture, boss_screen + Vector2(shake, -absf(shake) * 0.16), boss_size, Color(1.0, 0.9, 0.68, alpha), true)
		game.draw_arc(boss_screen, maxf(42.0, boss_size.x * 0.48) + elapsed * 18.0, 0.0, TAU, 48, Color(1.0, 0.72, 0.22, 0.22 + elapsed * 0.18), 2.0, true)
		return
	var burst: float = clampf((elapsed - shake_end) / maxf(0.01, emerge_end - shake_end), 0.0, 1.0)
	var fragments: int = 0 if game.gfx_low_resource or game._memory_saver_active() else 10
	for index in range(fragments):
		var angle: float = float(index) * TAU / float(fragments) + 0.24
		var distance: float = lerpf(14.0, 80.0, burst)
		var pos: Vector2 = boss_screen + Vector2.from_angle(angle) * distance
		var color: Color = Color(1.0, 0.78, 0.3, (1.0 - burst) * 0.78)
		game.draw_rect(Rect2(pos - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), color, true)
	game.draw_arc(boss_screen, lerpf(28.0, 112.0, burst), 0.0, TAU, 56, Color(1.0, 0.86, 0.46, (1.0 - burst) * 0.52), 2.0, true)


static func _draw_reward_card(game: Node2D, camera: Vector2, origin: Vector2, receiver: Vector2, card_id: String, index: int, count: int, elapsed: float, shake_end: float, emerge_end: float, collect_start: float) -> void:
	if elapsed < shake_end:
		return
	var card: Dictionary = game._find_card_by_id(card_id)
	if card.is_empty():
		return
	var destination: Vector2 = _card_slot(receiver, index, count, elapsed)
	var position: Vector2 = destination
	var alpha: float = 1.0
	if elapsed < emerge_end:
		var emerge: float = clampf((elapsed - shake_end) / maxf(0.01, emerge_end - shake_end), 0.0, 1.0)
		position = origin.lerp(destination, _ease_out_back(emerge))
		alpha = emerge
	elif elapsed >= collect_start + float(index) * game.BOSS_REWARD_REVEAL_CARD_STAGGER:
		var collect: float = clampf((elapsed - collect_start - float(index) * game.BOSS_REWARD_REVEAL_CARD_STAGGER) / maxf(0.01, game.BOSS_REWARD_REVEAL_COLLECT_TIME), 0.0, 1.0)
		position = destination.lerp(receiver + Vector2(0.0, -22.0), collect * collect)
		alpha = 1.0 - collect
	if alpha <= 0.01:
		return
	var compact: bool = game.gfx_low_resource or game._memory_saver_active()
	var size: Vector2 = Vector2(54.0, 76.0) if compact else Vector2(68.0, 96.0)
	var rect := Rect2(position - camera - size * 0.5, size)
	var rarity: Color = game._card_rarity_color(card)
	game.draw_rect(rect.grow(3.0), Color(0.015, 0.02, 0.05, alpha * 0.86), true)
	game.draw_rect(rect.grow(2.0), Color(rarity.r, rarity.g, rarity.b, alpha * 0.82), false, 2.0, true)
	game._draw_texture_contain(game._card_texture(card), rect.grow(-4.0), Color(1.0, 1.0, 1.0, alpha))


static func _card_slot(receiver: Vector2, index: int, count: int, elapsed: float) -> Vector2:
	var spacing: float = minf(66.0, 360.0 / float(maxi(1, count - 1)))
	var horizontal: float = (float(index) - float(count - 1) * 0.5) * spacing
	var bob: float = sin(elapsed * 4.6 + float(index) * 0.77) * 5.0
	return receiver + Vector2(horizontal, -142.0 - absf(horizontal) * 0.08 + bob)


static func _ease_out_back(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0) - 1.0
	return 1.0 + 2.70158 * t * t * t + 1.70158 * t * t
