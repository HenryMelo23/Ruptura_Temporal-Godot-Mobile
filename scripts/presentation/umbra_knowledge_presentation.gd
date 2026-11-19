extends RefCounted


static func draw_summary(game: Node2D, rect: Rect2, knowledge: Dictionary) -> void:
	var predator := Color(1.0, 0.11, 0.2)
	game.draw_rect(rect, Color(0.035, 0.008, 0.014, 0.94), true)
	game.draw_rect(rect, Color(predator.r, predator.g, predator.b, 0.72), false, 1.6)
	game.draw_line(rect.position + Vector2(0, 1), rect.position + Vector2(rect.size.x * 0.32, 1), Color(1.0, 0.72, 0.72, 0.72), 2.0)
	var total := clampi(int(knowledge.get("total_percent", 0)), 0, 100)
	var title := "CONHECIMENTO DA UMBRA"
	game.draw_string(game.menu_title_font if game.menu_title_font != null else game.font, rect.position + Vector2(12, 16), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 90.0, game._fit_text_size(title, rect.size.x - 90.0, 13, 9), Color(1.0, 0.84, 0.86))
	game._draw_centered("%d%%" % total, Vector2(rect.end.x - 36.0, rect.position.y + 16.0), 13, Color(1.0, 0.34, 0.4))
	var bar := Rect2(rect.position + Vector2(12, 23), Vector2(rect.size.x - 24.0, 8.0))
	game.draw_rect(bar, Color(0.12, 0.03, 0.05, 0.96), true)
	var fill := Rect2(bar.position, Vector2(bar.size.x * float(total) / 100.0, bar.size.y))
	game.draw_rect(fill, Color(1.0, 0.08, 0.16, 0.92), true)
	for tick in range(1, 10):
		var x := bar.position.x + bar.size.x * float(tick) / 10.0
		game.draw_line(Vector2(x, bar.position.y), Vector2(x, bar.end.y), Color(0.02, 0.0, 0.0, 0.72), 1.0)
	if rect.size.y < 58.0:
		var archetype := "PERFIL: " + String(knowledge.get("archetype_label", "INDEFINIDO"))
		game._draw_centered(archetype, Vector2(rect.get_center().x, rect.end.y - 5.0), game._fit_text_size(archetype, rect.size.x - 20.0, 9, 7), Color(0.8, 0.72, 0.75))
		return
	var categories: Dictionary = Dictionary(knowledge.get("categories", {}))
	var keys := ["movement", "shooting", "choices", "preferences", "weaknesses"]
	var labels := ["MOVIMENTO", "DISPARO", "ESCOLHAS", "PREFER.", "FRAQUEZAS"]
	var cell_w := (rect.size.x - 24.0) / float(keys.size())
	for index in range(keys.size()):
		var category: Dictionary = Dictionary(categories.get(keys[index], {}))
		var value := clampi(int(category.get("percent", 0)), 0, 100)
		var center_x := rect.position.x + 12.0 + cell_w * (float(index) + 0.5)
		var label := "%s %d%%" % [labels[index], value]
		game._draw_centered(label, Vector2(center_x, rect.end.y - 9.0), game._fit_text_size(label, cell_w - 6.0, 9, 7), Color(0.9, 0.78, 0.8))
