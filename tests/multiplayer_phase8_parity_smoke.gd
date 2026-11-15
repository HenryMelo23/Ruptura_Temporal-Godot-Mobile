extends SceneTree

var failed := false
var host: Node
var replica: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("MULTIPLAYER_PHASE8_PARITY_FAIL " + message)


func _initialize() -> void:
	host = load("res://scenes/Main.tscn").instantiate()
	replica = load("res://scenes/Main.tscn").instantiate()
	root.add_child(host)
	root.add_child(replica)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	for game in [host, replica]:
		game._start_game()
		game.mode = "game"
		game.current_phase = 8
		game.is_multiplayer = true
	host.is_host = true
	host.online_room_owner = true
	replica.is_host = false
	replica.online_room_owner = false

	# Narrativa is deliberately solo-only even if a caller bypasses request().
	_check(not host._story().open("prologo"), "story opened directly in multiplayer")
	host._merchant_npc().say("nao deve aparecer")
	_check(host._merchant_npc().bubble == "", "merchant bubble appeared in multiplayer")
	host._merchant_npc().greet(null)
	_check(not host._dialogue().busy(), "merchant dialogue appeared in multiplayer")

	# The complete Phase 8 enemy roster keeps its identity on the wire.
	var roster: Array = []
	for i in range(RTSertaoController.KINDS.size()):
		roster.append({"uid": 8100 + i, "type": RTSertaoController.KINDS[i], "pos": Vector2(200 + i * 40, 320), "hp": 50.0, "max_hp": 50.0})
	var enemy_packet: PackedFloat32Array = host.RTNetContractScript.pack_enemies(roster, host.NET_ENEMY_TYPES, host.ENEMY_COMMON, host.NET_LEECH_STATES, host.SANGUESSUGA_STATE_DORMANT)
	var decoded: Array = host.RTNetContractScript.unpack_enemy_snapshot(enemy_packet, {}, host.NET_ENEMY_TYPES, host.ENEMY_COMMON, host.NET_LEECH_STATES, host.ENEMY_CHRONAL_LEECH, Time.get_ticks_msec())
	_check(decoded.size() == roster.size(), "phase 8 enemy roster was truncated")
	for i in range(mini(decoded.size(), roster.size())):
		_check(String(decoded[i].get("type", "")) == String(roster[i].get("type", "")), "phase 8 enemy identity changed at %d" % i)

	# Authority creates gameplay; replica receives only the exact visual state.
	host.enemies = [{
		"uid": 8188, "type": RTSertaoController.CANGACEIRO, "pos": Vector2(480, 360),
		"hp": 500.0, "max_hp": 500.0, "phase": 0.0, "s8_state": "rajada_aim", "s8_t": 0.75,
		"s8_flash": 0.4, "s8_aim": Vector2(0.6, 0.8), "s8_spin": 1.2,
	}]
	replica.enemies = [{"uid": 8188, "type": RTSertaoController.CANGACEIRO, "pos": Vector2(480, 360), "hp": 500.0, "max_hp": 500.0, "phase": 0.0}]
	host.sertao_controller.shoot(Vector2(320, 280), Vector2.RIGHT, 220.0, RTSertaoController.COL_SUN, {"delay": 0.25, "size": 1.4, "owner": 8188})
	host.sertao_controller.hazards = [{"kind": "egg", "from": Vector2(300, 200), "to": Vector2(520, 400), "t": 0.4, "flight": 1.0, "rot": 0.2, "dmg": 10}]
	host.boss8_controller.mode = "gnomon"
	host.boss8_controller.anim = "sun"
	host.boss8_controller.stage = 3
	host.boss8_controller.shadow_on = true
	host.boss8_controller.shadow_angle = 1.15
	host.boss8_controller.sun_power = 0.9
	host.boss8_controller.gaps = [0.25, 0.72]
	var packet: Dictionary = bytes_to_var(var_to_bytes(host._pack_net_boss_visuals()))
	_check(packet.has("sertao_visual") and packet.has("boss8_visual"), "phase 8 visual packet missing")
	replica._apply_remote_boss_visual_snapshot(packet)
	_check(replica.sertao_controller.bullets.size() == 1, "bullet field did not replicate")
	_check(replica.sertao_controller.hazards.size() == 1, "hazard telegraph did not replicate")
	_check(String(replica.enemies[0].get("s8_state", "")) == "rajada_aim", "enemy animation state did not replicate")
	_check(Vector2(replica.enemies[0].get("s8_aim", Vector2.ZERO)).is_equal_approx(Vector2(0.6, 0.8)), "enemy aim did not replicate")
	_check(replica.boss8_controller.mode == "gnomon" and replica.boss8_controller.stage == 3, "boss attack state did not replicate")
	_check(replica.boss8_controller.shadow_on and is_equal_approx(replica.boss8_controller.shadow_angle, 1.15), "gnomon shadow did not replicate")
	_check(is_equal_approx(replica.boss8_controller.sun_power, 0.9), "boss visual power did not replicate")

	var boss_packet: PackedFloat32Array = host.RTNetContractScript.pack_boss(Vector2(640, 400), 800.0, false, true, 8, 1200.0, 2.0)
	var boss_decoded: Dictionary = host.RTNetContractScript.unpack_boss_snapshot(boss_packet, Vector2.ZERO, 0.0, false, false, 1, 1.0, 0.0, false)
	_check(int(boss_decoded.get("phase_index", 0)) == 8, "phase 8 boss identity was clamped")

	if failed:
		quit(1)
	else:
		print("MULTIPLAYER_PHASE8_PARITY_OK narrative=skipped roster=6 bullets=1 hazards=1 enemy_anim=sync boss=sync")
		quit(0)
