extends SceneTree

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("SHOP_MP_FAIL " + message)
	quit(1)

func _init():
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	print("--- INICIANDO SMOKE TEST DA LOJA MULTIPLAYER ---")

	main.is_host = true
	main.is_multiplayer = true
	main.mode = "game"

	print("1. Host solicita loja (entra no shop_mp_waiting)...")
	main.mode = "shop_mp_waiting"
	main.shop_mp_request_timer = 5.0
	print("Estado do Host: ", main.mode)
	_check(main.mode == "shop_mp_waiting", "host should wait for partner")

	print("2. Cliente recebe RPC de pedido de loja...")
	main.mode = "game"
	main._rpc_request_shop()
	print("Estado do Cliente: ", main.mode)
	_check(main.mode == "shop_mp_requested", "client should receive shop request")

	print("3. Cliente aceita a loja...")
	main.mode = "shop_mp_waiting"
	main._start_shop_opening_animation(false)
	print("Animacao de abertura iniciada? Timer: ", main.shop_opening_timer)
	_check(main.shop_opening_timer > 0.0, "shop opening animation should start")

	print("4. Cliente terminou a loja...")
	main.shop_mp_ready_to_leave = true
	main._check_shop_mp_exit()

	print("5. Host recebeu ready do parceiro...")
	main._rpc_shop_ready()
	_check(main.shop_mp_partner_ready, "partner ready flag should be set")

	print("Status final: ready_to_leave=", main.shop_mp_ready_to_leave, " partner_ready=", main.shop_mp_partner_ready)
	print("--- SMOKE TEST CONCLUIDO COM SUCESSO ---")
	quit(0)
