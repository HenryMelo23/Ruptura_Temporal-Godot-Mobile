class_name RTRuntimeAssetController
extends RefCounted

# Keeps full-resolution art out of memory until the active phase or catalog
# actually needs it. Streaming changes residency only, never texture quality.

const PHASE_TEXTURE_SPECS := {
	1: {
		"enemy_common_phase_1": ["Inimig1.png", "Inimig2.png"],
		"boss": "boss1/idle/idle_01.png",
		"boss_stage1": ["boss1/idle/idle_01.png", "boss1/idle/idle_02.png"],
		"boss_stage2": ["boss1/idle/idle_03.png", "boss1/idle/idle_04.png"],
		"boss_stage3": ["boss1/idle/idle_02.png", "boss1/idle/idle_04.png"],
		"boss1_idle": ["boss1/idle/idle_01.png", "boss1/idle/idle_02.png", "boss1/idle/idle_03.png", "boss1/idle/idle_04.png"],
		"boss1_walk": ["boss1/walk/walk_01.png", "boss1/walk/walk_02.png", "boss1/walk/walk_03.png", "boss1/walk/walk_04.png"],
		"boss1_turn": ["boss1/turn/turn_01.png", "boss1/turn/turn_02.png", "boss1/turn/turn_03.png"],
		"boss1_bubble": ["boss1/bubble/bubble_01.png", "boss1/bubble/bubble_02.png", "boss1/bubble/bubble_03.png", "boss1/bubble/bubble_04.png"],
		"boss1_pincer": ["boss1/pincer/pincer_01.png", "boss1/pincer/pincer_02.png", "boss1/pincer/pincer_03.png", "boss1/pincer/pincer_04.png"],
		"boss1_pincer_up": ["boss1/pincer_up/pincer_up_01.png", "boss1/pincer_up/pincer_up_02.png", "boss1/pincer_up/pincer_up_03.png", "boss1/pincer_up/pincer_up_04.png"],
		"boss1_pincer_down": ["boss1/pincer_down/pincer_down_01.png", "boss1/pincer_down/pincer_down_02.png", "boss1/pincer_down/pincer_down_03.png", "boss1/pincer_down/pincer_down_04.png"],
		"boss1_absorb": ["boss1/absorb/absorb_01.png", "boss1/absorb/absorb_02.png", "boss1/absorb/absorb_03.png", "boss1/absorb/absorb_04.png"],
		"boss1_sand": ["boss1/sand/sand_01.png", "boss1/sand/sand_02.png", "boss1/sand/sand_03.png", "boss1/sand/sand_04.png", "boss1/sand/sand_sweep.png", "boss1/sand/sand_follow.png"],
		"boss1_tide": ["boss1/tide/tide_01.png", "boss1/tide/tide_02.png", "boss1/tide/tide_charge.png", "boss1/tide/tide_release.png", "boss1/tide/tide_03.png", "boss1/tide/tide_04.png"],
		"boss1_rain": ["boss1/rain/rain_01.png", "boss1/rain/rain_02.png", "boss1/rain/rain_charge.png", "boss1/rain/rain_release.png", "boss1/rain/rain_03.png", "boss1/rain/rain_04.png"],
		"boss1_rewind": ["boss1/rewind/rewind_01.png", "boss1/rewind/rewind_02.png", "boss1/rewind/rewind_03.png", "boss1/rewind/rewind_04.png"],
		"boss1_hit": ["boss1/hit_01.png", "boss1/hit_02.png", "boss1/hit_03.png", "boss1/hit_04.png", "boss1/hit_05.png"],
		"boss1_jump": ["boss1/jump_01.png", "boss1/jump_02.png", "boss1/jump_03.png", "boss1/jump_04.png", "boss1/jump_05.png"],
		"boss1_death": ["boss1/death_01.png", "boss1/death_02.png", "boss1/death_03.png", "boss1/death_04.png", "boss1/death_05.png", "boss1/death_06.png"],
	},
	2: {
		"enemy_common_phase_2_left": ["inimigo_direita2-1.png", "inimigo_direita2-2.png"],
		"enemy_common_phase_2_right": ["inimigo_esquerda2-1.png", "inimigo_esquerda2-2.png"],
		"enemy_phase_2_kamikaze": ["pinguim_kamikaze_01.png", "pinguim_kamikaze_02.png"],
		"enemy_phase_2_pyro": ["pinguim_incendiario_01.png", "pinguim_incendiario_02.png"],
		"boss2": ["Boss2_1.png", "Boss2_2.png"],
		"boss2_anim_idle": ["boss2_remaster/idle/idle_01.png", "boss2_remaster/idle/idle_02.png", "boss2_remaster/idle/idle_03.png", "boss2_remaster/idle/idle_04.png"],
		"boss2_anim_walk": ["boss2_remaster/walk/walk_01.png", "boss2_remaster/walk/walk_02.png", "boss2_remaster/walk/walk_03.png", "boss2_remaster/walk/walk_04.png"],
		"boss2_anim_breath": ["boss2_remaster/breath/breath_01.png", "boss2_remaster/breath/breath_02.png", "boss2_remaster/breath/breath_03.png", "boss2_remaster/breath/breath_04.png"],
		"boss2_anim_spin": ["boss2_remaster/spin/spin_01.png", "boss2_remaster/spin/spin_02.png"],
		"boss2_anim_stomp": ["boss2_remaster/stomp/stomp_01.png", "boss2_remaster/stomp/stomp_02.png"],
		"boss2_anim_prison": ["boss2_remaster/prison/prison_01.png", "boss2_remaster/prison/prison_02.png"],
		"boss2_anim_shield": ["boss2_remaster/shield/shield_01.png", "boss2_remaster/shield/shield_02.png"],
		"boss2_anim_blizzard": ["boss2_remaster/blizzard/blizzard_01.png", "boss2_remaster/blizzard/blizzard_02.png"],
		"boss2_anim_flash": ["boss2_remaster/flash/flash_01.png", "boss2_remaster/flash/flash_02.png"],
		"boss2_anim_hunt": ["boss2_remaster/hunt/hunt_01.png", "boss2_remaster/hunt/hunt_02.png"],
		"boss2_anim_hit": ["boss2_remaster/hit/hit_01.png", "boss2_remaster/hit/hit_02.png", "boss2_remaster/hit/hit_03.png", "boss2_remaster/hit/hit_04.png"],
		"boss2_anim_death": ["boss2_remaster/death/death_01.png", "boss2_remaster/death/death_02.png", "boss2_remaster/death/death_03.png", "boss2_remaster/death/death_04.png", "boss2_remaster/death/death_05.png", "boss2_remaster/death/death_06.png", "boss2_remaster/death/death_07.png", "boss2_remaster/death/death_08.png"],
		"boss2_orb": ["Bolha1.png", "Bolha2.png", "Bolha3.png", "Bolha4.png", "Bolha5.png"],
		"boss2_wave": "Onda_Boss2.png",
		"sineiro_boreal_motion": "sineiro_boreal/sineiro_boreal_motion.png",
		"sineiro_boreal_death": "sineiro_boreal/sineiro_boreal_death.png",
	},
	3: {
		"enemy_phase_3_left": ["inimigo_esquerda3-1.png", "inimigo_esquerda3-2.png"],
		"enemy_phase_3_right": ["inimigo_direita3-1.png", "inimigo_direita3-2.png"],
		"enemy_phase_3_devoto": ["phase3_enemies/devoto_febril_01.png", "phase3_enemies/devoto_febril_02.png"],
		"enemy_phase_3_incensario": ["phase3_enemies/incensario_01.png", "phase3_enemies/incensario_02.png"],
		"enemy_phase_3_guardiao": ["phase3_enemies/guardiao_sucata_01.png", "phase3_enemies/guardiao_sucata_02.png"],
		"enemy_phase_3_flagelante": ["phase3_enemies/flagelante_01.png", "phase3_enemies/flagelante_02.png"],
		"enemy_phase_3_salmodiante": ["phase3_enemies/salmodiante_01.png", "phase3_enemies/salmodiante_02.png"],
		"enemy_phase_3_relicario": ["phase3_enemies/portador_relicario_01.png", "phase3_enemies/portador_relicario_02.png"],
		"enemy_phase_3_bullet": ["Disp_inimigo3_1.png", "Disp_inimigo3_2.png"],
		"boss_walk": ["Bossandando3_1.png", "Bossandando3_2.png"],
		"boss3": ["Boss3_1.png", "Boss3_2.png"],
		"boss3_anim_idle": ["boss3/remake/idle/idle_01.png", "boss3/remake/idle/idle_02.png", "boss3/remake/idle/idle_03.png", "boss3/remake/idle/idle_04.png", "boss3/remake/idle/idle_05.png", "boss3/remake/idle/idle_06.png"],
		"boss3_anim_walk": ["boss3/remake/walk/walk_01.png", "boss3/remake/walk/walk_02.png", "boss3/remake/walk/walk_03.png", "boss3/remake/walk/walk_04.png", "boss3/remake/walk/walk_05.png", "boss3/remake/walk/walk_06.png", "boss3/remake/walk/walk_07.png", "boss3/remake/walk/walk_08.png"],
		"boss3_anim_entry": ["boss3/remake/entry/entry_01.png", "boss3/remake/entry/entry_02.png", "boss3/remake/entry/entry_03.png", "boss3/remake/entry/entry_04.png", "boss3/remake/entry/entry_05.png", "boss3/remake/entry/entry_06.png", "boss3/remake/entry/entry_07.png", "boss3/remake/entry/entry_08.png"],
		"boss3_anim_rat_spit": ["boss3/remake/rat_spit/rat_spit_01.png", "boss3/remake/rat_spit/rat_spit_02.png", "boss3/remake/rat_spit/rat_spit_03.png", "boss3/remake/rat_spit/rat_spit_04.png", "boss3/remake/rat_spit/rat_spit_05.png", "boss3/remake/rat_spit/rat_spit_06.png"],
		"boss3_anim_rat_tail": ["boss3/remake/rat_tail/rat_tail_01.png", "boss3/remake/rat_tail/rat_tail_02.png", "boss3/remake/rat_tail/rat_tail_03.png", "boss3/remake/rat_tail/rat_tail_04.png", "boss3/remake/rat_tail/rat_tail_05.png", "boss3/remake/rat_tail/rat_tail_06.png"],
		"boss3_anim_rat_rain": ["boss3/remake/rat_rain/rat_rain_01.png", "boss3/remake/rat_rain/rat_rain_02.png", "boss3/remake/rat_rain/rat_rain_03.png", "boss3/remake/rat_rain/rat_rain_04.png", "boss3/remake/rat_rain/rat_rain_05.png", "boss3/remake/rat_rain/rat_rain_06.png"],
		"boss3_anim_cheese_ritual": ["boss3/remake/cheese_ritual/cheese_ritual_01.png", "boss3/remake/cheese_ritual/cheese_ritual_02.png", "boss3/remake/cheese_ritual/cheese_ritual_03.png", "boss3/remake/cheese_ritual/cheese_ritual_04.png", "boss3/remake/cheese_ritual/cheese_ritual_05.png", "boss3/remake/cheese_ritual/cheese_ritual_06.png", "boss3/remake/cheese_ritual/cheese_ritual_07.png", "boss3/remake/cheese_ritual/cheese_ritual_08.png"],
		"boss3_anim_consume": ["boss3/remake/consume/consume_01.png", "boss3/remake/consume/consume_02.png", "boss3/remake/consume/consume_03.png", "boss3/remake/consume/consume_04.png", "boss3/remake/consume/consume_05.png", "boss3/remake/consume/consume_06.png"],
		"boss3_anim_faith": ["boss3/remake/faith/faith_01.png", "boss3/remake/faith/faith_02.png", "boss3/remake/faith/faith_03.png", "boss3/remake/faith/faith_04.png", "boss3/remake/faith/faith_05.png", "boss3/remake/faith/faith_06.png", "boss3/remake/faith/faith_07.png"],
		"boss3_anim_sector_ritual": ["boss3/remake/sector_ritual/sector_ritual_01.png", "boss3/remake/sector_ritual/sector_ritual_02.png", "boss3/remake/sector_ritual/sector_ritual_03.png", "boss3/remake/sector_ritual/sector_ritual_04.png", "boss3/remake/sector_ritual/sector_ritual_05.png", "boss3/remake/sector_ritual/sector_ritual_06.png", "boss3/remake/sector_ritual/sector_ritual_07.png", "boss3/remake/sector_ritual/sector_ritual_08.png"],
		"boss3_anim_miasma": ["boss3/remake/miasma/miasma_01.png", "boss3/remake/miasma/miasma_02.png", "boss3/remake/miasma/miasma_03.png", "boss3/remake/miasma/miasma_04.png", "boss3/remake/miasma/miasma_05.png", "boss3/remake/miasma/miasma_06.png", "boss3/remake/miasma/miasma_07.png"],
		"boss3_anim_hit": ["boss3/remake/hit/hit_01.png", "boss3/remake/hit/hit_02.png", "boss3/remake/hit/hit_03.png"],
		"boss3_anim_stun": ["boss3/remake/stun/stun_01.png", "boss3/remake/stun/stun_02.png", "boss3/remake/stun/stun_03.png", "boss3/remake/stun/stun_04.png", "boss3/remake/stun/stun_05.png"],
		"boss3_anim_death": ["boss3/remake/death/death_01.png", "boss3/remake/death/death_02.png", "boss3/remake/death/death_03.png", "boss3/remake/death/death_04.png", "boss3/remake/death/death_05.png", "boss3/remake/death/death_06.png", "boss3/remake/death/death_07.png", "boss3/remake/death/death_08.png", "boss3/remake/death/death_09.png", "boss3/remake/death/death_10.png"],
		"boss3_cheese": "queijo.png",
		"boss3_flask": "disparo_boss3.png",
	},
	4: {
		"enemy_phase_4_left": ["inimigo_direita4-1.png", "inimigo_direita4-2.png"],
		"enemy_phase_4_right": ["inimigo_esquerda4-1.png", "inimigo_esquerda4-2.png"],
		"enemy_phase_4_bullet": ["Magia_inimigo1.png", "Magia_inimigo2.png"],
		"boss4": ["boss4_rework/boss4_idle_00.png", "boss4_rework/boss4_idle_01.png", "boss4_rework/boss4_idle_02.png", "boss4_rework/boss4_idle_03.png"],
		"boss4_rework_idle": ["boss4_rework/boss4_idle_00.png", "boss4_rework/boss4_idle_01.png", "boss4_rework/boss4_idle_02.png", "boss4_rework/boss4_idle_03.png"],
		"boss4_rework_walk": ["boss4_rework/boss4_walk_00.png", "boss4_rework/boss4_walk_01.png", "boss4_rework/boss4_walk_02.png", "boss4_rework/boss4_walk_03.png"],
		"boss4_rework_hit": ["boss4_rework/boss4_hit_00.png", "boss4_rework/boss4_hit_01.png"],
		"boss4_rework_jump": ["boss4_rework/boss4_jump_00.png", "boss4_rework/boss4_jump_01.png"],
		"boss4_rework_land": ["boss4_rework/boss4_land_00.png", "boss4_rework/boss4_land_01.png"],
		"boss4_rework_slam": ["boss4_rework/boss4_slam_00.png", "boss4_rework/boss4_slam_01.png", "boss4_rework/boss4_slam_02.png", "boss4_rework/boss4_slam_03.png"],
		"boss4_rework_tongue": ["boss4_rework/boss4_tongue_00.png", "boss4_rework/boss4_tongue_01.png", "boss4_rework/boss4_tongue_02.png", "boss4_rework/boss4_tongue_03.png"],
		"boss4_rework_comet": ["boss4_rework/boss4_comet_00.png", "boss4_rework/boss4_comet_01.png", "boss4_rework/boss4_comet_02.png", "boss4_rework/boss4_comet_03.png"],
		"boss4_rework_gravity": ["boss4_rework/boss4_gravity_00.png", "boss4_rework/boss4_gravity_01.png", "boss4_rework/boss4_gravity_02.png", "boss4_rework/boss4_gravity_03.png"],
		"boss4_rework_transition_2": ["boss4_rework/boss4_hp_transition_00.png", "boss4_rework/boss4_hp_transition_01.png", "boss4_rework/boss4_hp_transition_02.png", "boss4_rework/boss4_hp_transition_03.png"],
		"boss4_rework_transition_3": ["boss4_rework/boss4_hp_transition_00.png", "boss4_rework/boss4_hp_transition_01.png", "boss4_rework/boss4_hp_transition_02.png", "boss4_rework/boss4_hp_transition_03.png"],
		"boss4_rework_transition_4": ["boss4_rework/boss4_hp_transition_00.png", "boss4_rework/boss4_hp_transition_01.png", "boss4_rework/boss4_hp_transition_02.png", "boss4_rework/boss4_hp_transition_03.png"],
		"boss4_rework_ultimate": ["boss4_rework/boss4_ultimate_00.png", "boss4_rework/boss4_ultimate_01.png", "boss4_rework/boss4_ultimate_02.png"],
		"boss4_rework_ultimate_interrupted": ["boss4_rework/boss4_ultimate_interrupted_00.png", "boss4_rework/boss4_ultimate_interrupted_01.png"],
		"boss4_rework_ultimate_failure": ["boss4_rework/boss4_ultimate_failure_00.png", "boss4_rework/boss4_ultimate_failure_01.png"],
		"boss4_rework_death": ["boss4_rework/boss4_death_00.png", "boss4_rework/boss4_death_01.png", "boss4_rework/boss4_death_02.png", "boss4_rework/boss4_death_03.png", "boss4_rework/boss4_death_04.png", "boss4_rework/boss4_death_05.png"],
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
		"boss6_rework_stage1_attack": ["boss6_rework/boss6_stage1_attack_00.png", "boss6_rework/boss6_stage1_attack_01.png", "boss6_rework/boss6_stage1_attack_02.png", "boss6_rework/boss6_stage1_attack_03.png"],
		"boss6_rework_stage2_attack": ["boss6_rework/boss6_stage2_attack_00.png", "boss6_rework/boss6_stage2_attack_01.png", "boss6_rework/boss6_stage2_attack_02.png", "boss6_rework/boss6_stage2_attack_03.png"],
		"boss6_rework_stage3_attack": ["boss6_rework/boss6_stage3_attack_00.png", "boss6_rework/boss6_stage3_attack_01.png", "boss6_rework/boss6_stage3_attack_02.png", "boss6_rework/boss6_stage3_attack_03.png"],
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


static var _prefetch_pending: Dictionary = {}
static var _prefetch_ready: Dictionary = {}
static var _prefetch_phase: int = -1
static var _registered_texture_waiting: Dictionary = {}
static var _registered_texture_pending: Dictionary = {}
static var _registered_texture_failed: Dictionary = {}


static func prefetch_paths_for_phase(phase: int, base_path: String, limit: int = 10) -> PackedStringArray:
	var result := PackedStringArray()
	if not PHASE_TEXTURE_SPECS.has(phase) or limit <= 0:
		return result
	var specs: Dictionary = PHASE_TEXTURE_SPECS[phase]
	# Dictionary insertion order is authored: common silhouettes and boss idle
	# arrive before optional action sheets. This keeps prefetch bounded and useful.
	for key in specs:
		var spec: Variant = specs[key]
		var paths: Array = spec if spec is Array else [spec]
		for relative_path in paths:
			var path := base_path + String(relative_path)
			if not result.has(path):
				result.append(path)
			if result.size() >= limit:
				return result
	return result


static func schedule_phase_prefetch(phase: int, base_path: String, limit: int = 10) -> int:
	if phase == _prefetch_phase:
		return 0
	_prefetch_phase = phase
	_prefetch_ready.clear()
	var scheduled := 0
	for path in prefetch_paths_for_phase(phase, base_path, limit):
		if _prefetch_pending.has(path) or not ResourceLoader.exists(path):
			continue
		var error := ResourceLoader.load_threaded_request(path, "Texture2D", true, ResourceLoader.CACHE_MODE_REUSE)
		if error == OK:
			_prefetch_pending[path] = phase
			scheduled += 1
	return scheduled


static func poll_prefetch(max_results: int = 2) -> int:
	var completed := 0
	for raw_path in _prefetch_pending.keys():
		if completed >= maxi(1, max_results):
			break
		var path := String(raw_path)
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var resource := ResourceLoader.load_threaded_get(path)
			if resource is Texture2D and int(_prefetch_pending[raw_path]) == _prefetch_phase:
				_prefetch_ready[path] = resource
			_prefetch_pending.erase(raw_path)
			completed += 1
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_prefetch_pending.erase(raw_path)
			completed += 1
	return completed


static func prefetch_snapshot() -> Dictionary:
	return {
		"phase": _prefetch_phase,
		"pending": _prefetch_pending.size(),
		"ready": _prefetch_ready.size(),
	}


static func reset_prefetch_for_test() -> void:
	_prefetch_pending.clear()
	_prefetch_ready.clear()
	_prefetch_phase = -1
	_registered_texture_waiting.clear()
	_registered_texture_pending.clear()
	_registered_texture_failed.clear()


static func shutdown_prefetch() -> void:
	# A threaded request cannot be cancelled in Godot. Resolve the small bounded
	# queue during runtime teardown so the loader does not retain orphaned RIDs.
	for raw_path in _prefetch_pending.keys():
		var path := String(raw_path)
		if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			ResourceLoader.load_threaded_get(path)
	_prefetch_pending.clear()
	_prefetch_ready.clear()
	_prefetch_phase = -1
	for raw_key in _registered_texture_pending.keys():
		var path := String(_registered_texture_pending[raw_key])
		if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			ResourceLoader.load_threaded_get(path)
	_registered_texture_waiting.clear()
	_registered_texture_pending.clear()
	_registered_texture_failed.clear()


static func should_stream_phase_assets(_is_mobile_runtime: bool, _memory_saver_active: bool) -> bool:
	# Every platform keeps the authored frames for the active phase while
	# releasing future/past phases. The parameters remain for API compatibility.
	return true


static func should_lazy_gallery_assets(_is_mobile_runtime: bool, _memory_saver_active: bool) -> bool:
	# Card/manifestation/aura art is presentation-only and can be restored from
	# its registered path. Lazy residency keeps the authored texture untouched.
	return true


static func release_transient_gallery_assets(game: Node) -> int:
	var released: int = 0
	for raw_key in game.textures.keys():
		var key := String(raw_key)
		if key.begins_with("card_") or key.begins_with("manifestation_") or key.begins_with("aura_"):
			game.textures.erase(raw_key)
			released += 1
	return released


static func preload_all(game: Node, base_path: String) -> void:
	for phase in PHASE_TEXTURE_SPECS:
		_load_phase(game, int(phase), base_path, false)


static func prepare_phase(game: Node, phase: int, base_path: String, release_inactive: bool, compact_animations = null) -> void:
	# Four-argument callers historically coupled release with compaction. Keep
	# that API behavior; mobile full-quality callers pass `false` explicitly.
	var should_compact: bool = release_inactive if compact_animations == null else bool(compact_animations)
	if release_inactive:
		_release_inactive(game, phase)
	_load_phase(game, phase, base_path, should_compact)


static func ensure_key(game: Node, key: String, base_path: String) -> bool:
	if game.textures.has(key):
		return true
	for phase in PHASE_TEXTURE_SPECS:
		var specs: Dictionary = PHASE_TEXTURE_SPECS[phase]
		if specs.has(key):
			_load_key(game, key, specs[key], base_path)
			return game.textures.has(key)
	return false


static func registered_texture_available(game: Node, key: String) -> bool:
	# Reward-pool construction only needs to know whether an authored texture can
	# be loaded. Loading every card image while an enemy is dying creates a
	# visible main-thread hitch; the selected drops are loaded afterwards.
	if game.textures.get(key) != null:
		return true
	return game.lazy_texture_paths.has(key)


static func request_registered_texture(game: Node, key: String) -> bool:
	if game.textures.get(key) != null:
		return true
	if _registered_texture_failed.has(key) or not game.lazy_texture_paths.has(key):
		return false
	var path := String(game.lazy_texture_paths[key])
	if not _registered_texture_waiting.has(key) and not _registered_texture_pending.has(key):
		_registered_texture_waiting[key] = path
	return false


static func poll_registered_textures(game: Node, max_starts: int = 1, max_results: int = 2) -> int:
	var started := 0
	for raw_key in _registered_texture_waiting.keys():
		if started >= maxi(1, max_starts):
			break
		var key := String(raw_key)
		var path := String(_registered_texture_waiting[raw_key])
		_registered_texture_waiting.erase(raw_key)
		if not ResourceLoader.exists(path):
			_registered_texture_failed[key] = true
			continue
		var error := ResourceLoader.load_threaded_request(path, "Texture2D", true, ResourceLoader.CACHE_MODE_REUSE)
		if error == OK:
			_registered_texture_pending[key] = path
			started += 1
		else:
			_registered_texture_failed[key] = true
	var completed := 0
	for raw_key in _registered_texture_pending.keys():
		if completed >= maxi(1, max_results):
			break
		var key := String(raw_key)
		var path := String(_registered_texture_pending[raw_key])
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var resource := ResourceLoader.load_threaded_get(path)
			_registered_texture_pending.erase(raw_key)
			if resource is Texture2D:
				game.textures[key] = resource
			else:
				_registered_texture_failed[key] = true
			completed += 1
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_registered_texture_pending.erase(raw_key)
			_registered_texture_failed[key] = true
			completed += 1
	return started + completed


static func registered_texture_failed(key: String) -> bool:
	return _registered_texture_failed.has(key)


static func phase_keys(phase: int) -> Array:
	if not PHASE_TEXTURE_SPECS.has(phase):
		return []
	return PHASE_TEXTURE_SPECS[phase].keys()


static func _load_phase(game: Node, phase: int, base_path: String, skip_optional_animation_sets: bool = false) -> void:
	if not PHASE_TEXTURE_SPECS.has(phase):
		return
	var specs: Dictionary = PHASE_TEXTURE_SPECS[phase]
	for key in specs:
		var texture_key := String(key)
		if skip_optional_animation_sets and texture_key.begins_with("boss3_anim_") and texture_key not in ["boss3_anim_idle", "boss3_anim_walk", "boss3_anim_entry"]:
			continue
		if not game.textures.has(key):
			var texture_spec: Variant = specs[key]
			if skip_optional_animation_sets and texture_key.begins_with("boss1_") and texture_spec is Array:
				texture_spec = _compact_boss1_animation_spec(texture_key, texture_spec)
			if skip_optional_animation_sets and texture_key.begins_with("boss2_anim_") and texture_spec is Array:
				texture_spec = _compact_boss2_animation_spec(texture_key, texture_spec)
			if skip_optional_animation_sets and texture_key.begins_with("boss4_rework_") and texture_spec is Array:
				texture_spec = _compact_boss4_animation_spec(texture_key, texture_spec)
			_load_key(game, texture_key, texture_spec, base_path)


static func _compact_boss1_animation_spec(key: String, spec: Array) -> Array:
	if spec.size() <= 2:
		return spec
	if key in ["boss1_jump", "boss1_hit", "boss1_death", "boss1_pincer", "boss1_pincer_up", "boss1_pincer_down"]:
		return [spec[0], spec[int(spec.size() / 2)], spec[-1]]
	# Keep the authored action/release silhouettes on low-memory devices. The
	# generic first/last reduction would erase the visual identity of these casts.
	if key in ["boss1_rain", "boss1_tide"] and spec.size() >= 6:
		return [spec[0], spec[2], spec[3], spec[-1]]
	if key == "boss1_sand" and spec.size() >= 6:
		return [spec[0], spec[3], spec[4], spec[-1]]
	return [spec[0], spec[-1]]


static func _compact_boss2_animation_spec(key: String, spec: Array) -> Array:
	if spec.size() <= 2:
		return spec
	if key in ["boss2_anim_hit", "boss2_anim_death"]:
		return [spec[0], spec[int(spec.size() / 2)], spec[-1]]
	return [spec[0], spec[-1]]


static func _compact_boss4_animation_spec(key: String, spec: Array) -> Array:
	if spec.size() <= 2:
		return spec
	if key.ends_with("_death") or key.contains("transition"):
		return [spec[0], spec[int(spec.size() / 2)], spec[-1]]
	if key.ends_with("_slam") or key.ends_with("_tongue") or key.ends_with("_comet") or key.ends_with("_gravity"):
		return [spec[0], spec[mini(2, spec.size() - 1)], spec[-1]]
	return [spec[0], spec[-1]]


static func _load_key(game: Node, key: String, spec: Variant, base_path: String) -> void:
	if key == "boss2":
		var preferred_frames: Array = []
		for index in range(1, 5):
			preferred_frames.append(_load_texture(game, "res://Boss2-%d.png" % index))
		if not preferred_frames.any(func(frame): return frame == null):
			game.textures[key] = preferred_frames
			return
	if spec is Array:
		var frames: Array = []
		for relative_path in spec:
			frames.append(_load_texture(game, base_path + String(relative_path)))
		game.textures[key] = frames
	else:
		game.textures[key] = _load_texture(game, base_path + String(spec))


static func _load_texture(game: Node, path: String) -> Texture2D:
	if _prefetch_ready.has(path):
		var resource: Texture2D = _prefetch_ready[path]
		_prefetch_ready.erase(path)
		return resource
	return game._safe_load(path)


static func _release_inactive(game: Node, active_phase: int) -> void:
	for phase in PHASE_TEXTURE_SPECS:
		if int(phase) == active_phase:
			continue
		for key in PHASE_TEXTURE_SPECS[phase]:
			game.textures.erase(key)
