extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("CARD_QUALITY_RULES_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _has_rare(cards: Array) -> bool:
	for card in cards:
		if game._is_rare_card(card):
			return true
	return false


func _run() -> void:
	await process_frame
	game._start_game()
	game.cards_bought.clear()
	game.common_card_stat_cache = game._common_card_stat_defaults()
	game._recalculate_common_card_stat_bonuses()

	_check(not game._rare_cards_unlocked(), "rare cards unlocked without Sorte")
	_check(is_equal_approx(game._chance_carta_rara(), 0.0), "rare chance was not zero without Sorte")
	_check(not _has_rare(game._available_card_drop_pool()), "drop pool contained rare cards without Sorte")
	for i in range(18):
		var rolled: Array = game._roll_shop_cards()
		_check(not _has_rare(rolled), "shop rolled a rare card without Sorte")

	var sorte: Dictionary = game._find_card_by_id("Sorte")
	_check(not sorte.is_empty(), "Sorte card was not found by id")
	game.cards_bought["Sorte"] = 1
	game._recalculate_common_card_stat_bonuses()
	_check(game._rare_cards_unlocked(), "rare cards did not unlock after buying Sorte")
	_check(game._chance_carta_rara() > 0.0, "rare chance did not become positive after Sorte")
	_check(_has_rare(game._available_card_drop_pool()), "drop pool did not include rares after Sorte")

	var fratura: Dictionary = game._find_card_by_id("fratura_cronal")
	_check(not fratura.is_empty(), "new card Fratura Cronal was not found")
	game.cards_bought["fratura_cronal"] = 2
	var report: String = game._cards_report_text()
	_check(report.find("Fratura Cronal x2") >= 0, "webhook report did not include new card id count")
	var projection: Array = game._card_projection_lines(fratura)
	_check(projection.size() == 2 and String(projection[0]).find("Sem comprar agora") >= 0 and String(projection[1]).find("Apos comprar") >= 0, "card projection lines were incomplete")
	_check(game._catalog_detail_description(fratura).find("Sem comprar agora") >= 0, "catalog card detail did not include current state")

	var eclipsada_index := -1
	for i in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[i].get("key", "")) == "eclipsada":
			eclipsada_index = i
			break
	_check(eclipsada_index >= 0, "Eclipsada was not registered")
	var eclipsada: Dictionary = game.MANIFESTATIONS[eclipsada_index]
	var icon_path := String(eclipsada.get("icon", ""))
	_check(icon_path == "res://Game Base/Ruptura_Temporal-APOLO2.0/Sprites/manifestacao-eclipsada.png", "Eclipsada icon path used the wrong root")
	_check(ResourceLoader.exists(icon_path) or FileAccess.file_exists(icon_path), "Eclipsada icon resource does not resolve")
	_check(game._manifest_select_item_texture(eclipsada, false) != null, "Eclipsada icon texture did not load")
	_check(game._manifestation_details("eclipsada").has("funcao"), "Eclipsada details were not registered")

	print("CARD_QUALITY_RULES_SMOKE_OK rare_gate=true sorte=true webhook_new_cards=true projections=true eclipsada_icon=true")
	quit(0)
