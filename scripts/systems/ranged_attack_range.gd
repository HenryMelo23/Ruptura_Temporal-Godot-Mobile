extends RefCounted
class_name RTRangedAttackRange

# Shared contract for every ranged primary attack. Melee identities keep their
# authored reach; projectile/ranged identities start at the same readable ring.
const CARD_ID := "horizonte_ruptura"
const BASE_RANGE := 300.0
const RANGE_PER_STACK := 30.0
const DAMAGE_PER_STACK := 0.025
const PRISMATIC_RICOCHET_CRIT_PER_STACK := 0.03
const FADE_START_RATIO := 0.72
const INDICATOR_COLOR_NAMES := ["RUBRA", "CIANO", "VERDE D37", "AMBAR", "VIOLETA", "BRANCO"]
const INDICATOR_COLORS := [
	Color(1.0, 0.055, 0.085),
	Color(0.08, 0.9, 1.0),
	Color(0.38, 1.0, 0.18),
	Color(1.0, 0.66, 0.12),
	Color(0.72, 0.34, 1.0),
	Color(0.94, 0.98, 1.0),
]


static func card_count(game: Node) -> int:
	return maxi(0, int(game.cards_bought.get(CARD_ID, 0)))


static func attack_range(game: Node) -> float:
	# Prismatica keeps the shared ring only as an automatic-targeting boundary.
	# Its projectile preserves the authored lifetime/ricochets, while range-card
	# stacks are converted into ricochet critical chance instead.
	if is_prismatic_primary(game):
		return BASE_RANGE
	return BASE_RANGE + float(card_count(game)) * RANGE_PER_STACK


static func damage_multiplier(game: Node) -> float:
	return 1.0 + float(card_count(game)) * DAMAGE_PER_STACK


static func prismatica_ricochet_crit_bonus(game: Node) -> float:
	return float(card_count(game)) * PRISMATIC_RICOCHET_CRIT_PER_STACK


static func is_prismatic_primary(game: Node) -> bool:
	return String(game.active_character_key) != String(game.CHARACTER_HENRY) and String(game.manifestation_key) == "prismatica"


static func is_ranged_primary(game: Node) -> bool:
	if String(game.active_character_key) == String(game.CHARACTER_HENRY):
		return String(game.mutation_key) != "colosso"
	return String(game.manifestation_key) != "lacerante"


static func sanitize_indicator_color_index(value: int) -> int:
	return posmod(value, INDICATOR_COLORS.size())


static func indicator_color(game: Node) -> Color:
	return INDICATOR_COLORS[sanitize_indicator_color_index(int(game.auto_attack_range_color_index))]


static func indicator_color_name(game: Node) -> String:
	return INDICATOR_COLOR_NAMES[sanitize_indicator_color_index(int(game.auto_attack_range_color_index))]


static func cycle_indicator_color(game: Node, direction: int = 1) -> void:
	game.auto_attack_range_color_index = sanitize_indicator_color_index(int(game.auto_attack_range_color_index) + direction)


static func sanitize_indicator_opacity(value: float) -> float:
	return clampf(snappedf(value, 0.1), 0.0, 1.0)


static func configure_bullet(game: Node, bullet: Dictionary) -> void:
	if String(bullet.get("source_category", "")) != "basic_attack":
		return
	if bool(bullet.get("ranged_range_configured", false)):
		return
	bullet["damage"] = float(bullet.get("damage", 0.0)) * damage_multiplier(game)
	bullet["ranged_range_configured"] = true
	if String(bullet.get("kind", "")) == "prismatica" and is_prismatic_primary(game):
		bullet["prismatica_ricochet_crit_bonus"] = prismatica_ricochet_crit_bonus(game)
		return
	var max_range := attack_range(game)
	var origin := Vector2(bullet.get("origin", game.player_pos))
	var position := Vector2(bullet.get("pos", origin))
	var initial_travel := origin.distance_to(position)
	bullet["range_origin"] = origin
	bullet["range_traveled"] = initial_travel
	bullet["max_range"] = max_range
	bullet["range_presence"] = 1.0
	var speed := maxf(1.0, float(bullet.get("speed", 1.0)))
	var range_life := maxf(0.01, (max_range - initial_travel) / speed)
	if bullet.has("life"):
		bullet["life"] = minf(float(bullet["life"]), range_life)
		bullet["max_life"] = float(bullet["life"])


static func advance_bullet(bullet: Dictionary, previous_pos: Vector2, next_pos: Vector2) -> bool:
	if not bullet.has("max_range"):
		return false
	var max_range := maxf(1.0, float(bullet.get("max_range", BASE_RANGE)))
	var traveled := float(bullet.get("range_traveled", 0.0)) + previous_pos.distance_to(next_pos)
	bullet["range_traveled"] = traveled
	var ratio := clampf(traveled / max_range, 0.0, 1.0)
	bullet["range_presence"] = 1.0 - smoothstep(FADE_START_RATIO, 1.0, ratio)
	return traveled >= max_range


static func reset_outbound_travel(bullet: Dictionary, origin: Vector2) -> void:
	bullet["range_origin"] = origin
	bullet["range_traveled"] = 0.0
	bullet["range_presence"] = 1.0


static func can_hit_position(bullet: Dictionary, target_pos: Vector2) -> bool:
	if not bullet.has("max_range"):
		return true
	var origin := Vector2(bullet.get("range_origin", bullet.get("origin", Vector2.ZERO)))
	return origin.distance_squared_to(target_pos) <= pow(float(bullet.get("max_range", BASE_RANGE)) + 0.01, 2.0)


static func visual_presence(bullet: Dictionary) -> float:
	if bullet.has("range_presence"):
		return clampf(float(bullet["range_presence"]), 0.0, 1.0)
	return 1.0


static func begin_projectile_draw(game: CanvasItem, bullet: Dictionary, screen_pos: Vector2) -> bool:
	var presence := visual_presence(bullet)
	if presence <= 0.025:
		return false
	if presence < 0.995:
		# Procedural projectiles do not share a material. Scaling all commands
		# around the projectile center gives them a cheap, smooth dissipation
		# without changing damage, velocity, or allocating per-shot nodes.
		var scale_value := maxf(0.08, presence)
		game.draw_set_transform(screen_pos * (1.0 - scale_value), 0.0, Vector2.ONE * scale_value)
	return true


static func end_projectile_draw(game: CanvasItem) -> void:
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func draw_range_indicator(game: CanvasItem, camera: Vector2) -> void:
	if not is_ranged_primary(game):
		return
	var opacity := sanitize_indicator_opacity(float(game.auto_attack_range_opacity))
	if opacity <= 0.001:
		return
	var center := Vector2(game.player_pos) - camera
	var radius := attack_range(game)
	var aiming := bool(game.attack_holding) or not String(game.locked_target_kind).is_empty()
	var alpha := (0.14 if aiming else 0.055) * opacity
	var segments := 72 if game._runtime_visual_budget_active() else 112
	var color := indicator_color(game)
	game.draw_arc(center, radius, 0.0, TAU, segments, Color(color.r * 0.52, color.g * 0.52, color.b * 0.52, alpha * 0.32), 3.0, true)
	game.draw_arc(center, radius, 0.0, TAU, segments, Color(color.r, color.g, color.b, alpha), 1.25, true)
