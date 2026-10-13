class_name RTRuntimeAssetController
extends RefCounted

# Keeps full-resolution phase art out of low-memory devices until the phase or
# catalog actually needs it. Desktop keeps the historical eager preload path.

const PHASE_TEXTURE_SPECS := {
	1: {
		"enemy_common_phase_1": ["Inimig1.png", "Inimig2.png"],
		"boss": "Boss1.png",
		"boss_stage1": ["Boss1.png", "Boss2.png"],
		"boss_stage2": ["Boss3.png", "Boss4.png"],
		"boss_stage3": ["Boss5.png", "Boss6.png"],
	},
	2: {
		"enemy_common_phase_2_left": ["inimigo_direita2-1.png", "inimigo_direita2-2.png"],
		"enemy_common_phase_2_right": ["inimigo_esquerda2-1.png", "inimigo_esquerda2-2.png"],
		"enemy_phase_2_kamikaze": ["pinguim_kamikaze_01.png", "pinguim_kamikaze_02.png"],
		"enemy_phase_2_pyro": ["pinguim_incendiario_01.png", "pinguim_incendiario_02.png"],
		"boss2": ["Boss2_1.png", "Boss2_2.png"],
		"boss2_orb": ["Bolha1.png", "Bolha2.png", "Bolha3.png", "Bolha4.png", "Bolha5.png"],
		"boss2_wave": "Onda_Boss2.png",
		"sineiro_boreal_motion": "sineiro_boreal/sineiro_boreal_motion.png",
		"sineiro_boreal_death": "sineiro_boreal/sineiro_boreal_death.png",
	},
	3: {
		"enemy_phase_3_left": ["inimigo_esquerda3-1.png", "inimigo_esquerda3-2.png"],
		"enemy_phase_3_right": ["inimigo_direita3-1.png", "inimigo_direita3-2.png"],
		"enemy_phase_3_bullet": ["Disp_inimigo3_1.png", "Disp_inimigo3_2.png"],
		"boss_walk": ["Bossandando3_1.png", "Bossandando3_2.png"],
		"boss3": ["Boss3_1.png", "Boss3_2.png"],
		"boss3_cheese": "queijo.png",
		"boss3_flask": "disparo_boss3.png",
	},
	4: {
		"enemy_phase_4_left": ["inimigo_direita4-1.png", "inimigo_direita4-2.png"],
		"enemy_phase_4_right": ["inimigo_esquerda4-1.png", "inimigo_esquerda4-2.png"],
		"enemy_phase_4_bullet": ["Magia_inimigo1.png", "Magia_inimigo2.png"],
		"boss4": ["Boss4_1.png", "Boss4_3.png"],
		"boss4_attack": "Boss4_2.png",
		"boss4_planet": ["Planet1_1.png", "Planet1_2.png"],
		"boss4_vortex": ["Vortex1_1.png", "Vortex1_2.png"],
	},
	5: {
		"boss5": ["Geo-Umbra-V2-1.png", "Geo-Umbra-V2-2.png"],
		"boss5_damage": ["Geo-Umbra-V2-1-dano.png", "Geo-Umbra-V2-2-dano.png", "Geo-Umbra-V2-3-dano.png", "Geo-Umbra-V2-4-dano.png", "Geo-Umbra-V2-5-dano.png"],
		"boss5_shield": ["Geo_Umbra_Escudo-1.png", "Geo_Umbra_Escudo-2.png"],
	},
	6: {
		"enemy_phase_6_enguia_miasma": ["enquiadomiasma1.png", "enquiadomiasma2.png"],
		"enemy_phase_6_lodario": ["lodario1.png", "lodario2.png"],
		"enemy_phase_6_pustula_fossil": ["pustulafossil1.png", "pustulafossil2.png"],
		"enemy_phase_6_sanguessuga_cronal": ["sanguesugacronal1.png", "sanguesugacronal2.png"],
		"enemy_phase_6_suturador_ambar": "suturador_ambar/suturador_ambar_motion.png",
		"boss6_form_1": ["Boss6-1-1.png", "Boss6-1-2.png", "Boss6-1-3.png", "Boss6-1-4.png"],
		"boss6_form_2": ["Boss6-2-1.png", "Boss6-2-2.png", "Boss6-2-3.png", "Boss6-2-4.png"],
		"boss6_form_3": ["Boss6-3-1.png", "Boss6-3-2.png", "Boss6-3-3.png", "Boss6-3-4.png"],
	},
	7: {
		"enemy_phase_7_cinerido_mov": ["cinerido-mov-1.png", "cinerido-mov-2.png", "cinerido-mov-3.png", "cinerido-mov-4.png"],
		"enemy_phase_7_cinerido_atk": ["cinerido-atk-1.png", "cinerido-atk-2.png"],
		"enemy_phase_7_pangoliro": ["Pangoliro.png", "Pangoliro2.png", "Pangoliro3.png", "Pangoliro4.png"],
		"enemy_phase_7_pangoliro_atk": ["Pangoliro-ATK.png"],
		"enemy_phase_7_corvol": ["Corvol1.png", "Corvol2.png", "Corvol3.png", "Corvol4.png"],
		"boss7_fly": ["boss7_fenix/fenix_fly_01.png", "boss7_fenix/fenix_fly_02.png", "boss7_fenix/fenix_fly_03.png", "boss7_fenix/fenix_fly_04.png"],
		"boss7_dive": ["boss7_fenix/fenix_down_01.png", "boss7_fenix/fenix_down_02.png", "boss7_fenix/fenix_down_03.png", "boss7_fenix/fenix_down_04.png"],
		"boss7_core": ["boss7_fenix/fenix_egg_01.png", "boss7_fenix/fenix_egg_02.png", "boss7_fenix/fenix_egg_03.png", "boss7_fenix/fenix_egg_04.png"],
	},
}


static func preload_all(game: Node, base_path: String) -> void:
	for phase in PHASE_TEXTURE_SPECS:
		_load_phase(game, int(phase), base_path)


static func prepare_phase(game: Node, phase: int, base_path: String, release_inactive: bool) -> void:
	if release_inactive:
		_release_inactive(game, phase)
	_load_phase(game, phase, base_path)


static func ensure_key(game: Node, key: String, base_path: String) -> bool:
	if game.textures.has(key):
		return true
	for phase in PHASE_TEXTURE_SPECS:
		var specs: Dictionary = PHASE_TEXTURE_SPECS[phase]
		if specs.has(key):
			_load_key(game, key, specs[key], base_path)
			return game.textures.has(key)
	return false


static func phase_keys(phase: int) -> Array:
	if not PHASE_TEXTURE_SPECS.has(phase):
		return []
	return PHASE_TEXTURE_SPECS[phase].keys()


static func _load_phase(game: Node, phase: int, base_path: String) -> void:
	if not PHASE_TEXTURE_SPECS.has(phase):
		return
	var specs: Dictionary = PHASE_TEXTURE_SPECS[phase]
	for key in specs:
		if not game.textures.has(key):
			_load_key(game, String(key), specs[key], base_path)


static func _load_key(game: Node, key: String, spec: Variant, base_path: String) -> void:
	if key == "boss2":
		var preferred_frames: Array = []
		for index in range(1, 5):
			preferred_frames.append(game._safe_load("res://Boss2-%d.png" % index))
		if not preferred_frames.any(func(frame): return frame == null):
			game.textures[key] = preferred_frames
			return
	if spec is Array:
		var frames: Array = []
		for relative_path in spec:
			frames.append(game._safe_load(base_path + String(relative_path)))
		game.textures[key] = frames
	else:
		game.textures[key] = game._safe_load(base_path + String(spec))


static func _release_inactive(game: Node, active_phase: int) -> void:
	for phase in PHASE_TEXTURE_SPECS:
		if int(phase) == active_phase:
			continue
		for key in PHASE_TEXTURE_SPECS[phase]:
			game.textures.erase(key)
