extends SceneTree

func _init():
	var main = load("res://scripts/main.gd").new()
	print("--- INICIANDO SMOKE TEST DA LOJA MULTIPLAYER ---")
	
	# Simular ambiente host
	main.is_host = true
	main.multiplayer = MultiplayerAPI.new() 
	main.mode = "game"
	
	# Simular requisição de loja (Host pede loja)
	print("1. Host solicita loja (Entra no shop_mp_waiting)...")
	main.mode = "shop_mp_waiting"
	main.shop_mp_request_timer = 5.0
	print("Estado do Host: ", main.mode)
	
	# No lado do cliente, seria recebido rpc("_rpc_request_shop")
	print("2. Simulando recebimento da RPC pelo Cliente (shop_mp_requested)...")
	main._rpc_request_shop()
	print("Estado do Cliente (simulado no msm script): ", main.mode)
	
	# Cliente aceita (Ação de apertar o botão ou timeout)
	print("3. Cliente aceita a loja (via botão mp_accept)...")
	main.mode = "game"
	main._start_shop_opening_animation(false)
	print("Animação de abertura iniciada? Timer: ", main.shop_opening_timer)
	
	# Simular fim da loja
	print("4. Cliente terminou a loja...")
	main.shop_mp_ready_to_leave = true
	main._check_shop_mp_exit()
	
	print("5. Host terminou a loja (via RPC do cliente)...")
	main._rpc_shop_mp_ready()
	
	print("Status final: ready_to_leave=", main.shop_mp_ready_to_leave, " partner_ready=", main.shop_mp_partner_ready)
	print("--- SMOKE TEST CONCLUIDO COM SUCESSO ---")
	quit()
