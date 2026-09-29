extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MINIMAL_TELEMETRY_SCHEMA_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _run() -> void:
	await process_frame
	game.selected_manifestation = 0
	game.selected_aura = 0
	game._start_game()
	game.mode = "game"
	game.current_phase = 5
	game.time_alive = 30.0
	game.player_pos = Vector2(640, 360)
	game.player_attack_interval = 0.42
	game._update_run_telemetry(0.6)
	game._apply_score_delta(250)
	game._track_enemy_damage({"type": game.ENEMY_STALKER}, 120.0)
	game._mark_boss_reached(5)
	game._track_boss_damage(333.0)
	game._damage_player(25, "umbra_contact")
	game._record_telemetry_ability_use("skill_q", 7.5)
	game._record_telemetry_ability_use("skill_e", 75.0)
	game._track_behavior_dash(Vector2(640, 360), Vector2(720, 400))
	game.boss_active = true
	game.boss_name = "UMBRA"
	game.boss_hp_max = 1000.0
	game.boss_hp = 700.0
	game.umbra_mind_status = "cached"
	game.umbra_mind_version = "qa"
	game.event_alert_text = "ANOMALIA QA"
	game.event_alert_timer = 2.0
	game.score = 1200
	game._begin_shop_visit()
	game.shop_cards = game._roll_shop_cards("open")
	game._record_telemetry_shop_open(false)
	_check(not game.shop_cards.is_empty(), "shop did not generate offers")
	game.shop_reroll_index += 1
	game.shop_rerolls -= 1
	game._record_telemetry_shop_reroll(true, 0)
	game.shop_cards = game._roll_shop_cards("reroll")
	if not game.shop_cards.is_empty():
		var card: Dictionary = game.shop_cards[0]
		var price: int = game._effective_card_price(card)
		game._record_telemetry_score_delta(-price, "shop_purchase")
		game._record_telemetry_shop_purchase(card, price)
	game.cards_bought["Petro"] = int(game.cards_bought.get("Petro", 0)) + 1
	var payload: Dictionary = game._build_minimal_telemetry_payload("Smoke")
	_check(String(payload.get("schema", "")) == "ruptura.college_run_telemetry", "schema name missing")
	_check(int(payload.get("schema_version", 0)) == 1, "schema version missing")
	_check(not bool(Dictionary(payload.get("privacy", {})).get("personal_data", true)), "privacy flag must reject personal data")
	_check(not payload.has("player") and not payload.has("profile_id") and not payload.has("room"), "payload has personal identifiers")
	for key in ["run", "build", "progress", "shop", "build_cards", "damage", "movement", "attack_cadence", "abilities", "temporary_event", "boss", "umbra"]:
		_check(payload.has(key), "missing section " + key)
	var run: Dictionary = payload["run"]
	_check(typeof(run.get("duration_seconds")) == TYPE_INT, "duration type")
	_check(typeof(run.get("phase")) == TYPE_INT, "phase type")
	var progress: Dictionary = payload["progress"]
	_check(typeof(progress.get("kills")) == TYPE_INT, "kills type")
	_check(typeof(progress.get("points_earned")) == TYPE_INT, "points earned type")
	_check(typeof(progress.get("points_spent")) == TYPE_INT, "points spent type")
	_check(Array(progress.get("score_events", [])).size() >= 1, "score events missing")
	var shop: Dictionary = payload["shop"]
	_check(int(shop.get("open_count", 0)) >= 1, "shop open missing")
	_check(int(shop.get("offer_count", 0)) >= 1, "shop offer missing")
	_check(int(shop.get("reroll_count", 0)) >= 1, "shop reroll missing")
	_check(Array(shop.get("offers", []))[0].has("slots"), "shop offer slots missing")
	var damage: Dictionary = payload["damage"]
	_check(typeof(damage.get("dealt_total")) == TYPE_INT, "damage dealt type")
	_check(typeof(damage.get("taken_total")) == TYPE_INT, "damage taken type")
	_check(Array(damage.get("taken_events", [])).size() >= 1, "damage events missing")
	var movement: Dictionary = payload["movement"]
	_check(typeof(movement.get("heatmap")) == TYPE_DICTIONARY, "heatmap type")
	_check(_is_number(movement.get("stationary_ratio")), "stationary ratio type")
	var cadence: Dictionary = payload["attack_cadence"]
	_check(_is_number(cadence.get("attack_interval")), "attack interval type")
	_check(typeof(cadence.get("shots_fired")) == TYPE_INT, "shots fired type")
	var abilities: Dictionary = payload["abilities"]
	_check(int(Dictionary(abilities.get("counts", {})).get("skill_q", 0)) == 1, "skill q count")
	_check(int(Dictionary(abilities.get("counts", {})).get("teleport", 0)) >= 1, "teleport count")
	_check(bool(Dictionary(payload["temporary_event"]).get("active", false)), "temporary event active missing")
	_check(bool(Dictionary(payload["boss"]).get("active", false)), "boss active missing")
	_check(bool(Dictionary(payload["umbra"]).get("phase5_context", false)), "umbra context missing")
	print("MINIMAL_TELEMETRY_SCHEMA_SMOKE_OK schema=v1 sections=true session=true privacy=true")
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	game = null
	await process_frame
	quit(0)
