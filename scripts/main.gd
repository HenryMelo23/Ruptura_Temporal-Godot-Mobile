extends Node2D

const WORLD_SIZE := Vector2(1600, 900)
const GAME_VERSION := "2.0.7"
const DESKTOP_STAGE_SIZE := Vector2(1088, 768)
const PLAYER_START := Vector2(420, 500)
const PLAYER_BASE_HP := 450
const PLAYER_BASE_SPEED := 280.0
const PLAYER_BASE_DAMAGE := 32.0
const PLAYER_BASE_ATTACK_INTERVAL := 0.68
const PLAYER_BASE_SKILL_COOLDOWN := 7.5
const PLAYER_BASE_DASH_COOLDOWN := 2.2
const PLAYER_DASH_DISTANCE := 330.0
const PLAYER_DRAW_BOX_SIZE := Vector2(54, 80)
const PLAYER_DRAW_STOP_SIZE := Vector2(54, 80)
const PLAYER_DRAW_UP_SIZE := Vector2(51, 77)
const PLAYER_DRAW_DOWN_SIZE := Vector2(51, 77)
const PLAYER_DRAW_SIDE_SIZE := Vector2(52, 76)
const PLAYER_DRAW_SHOT_SIZE := Vector2(52, 77)
const PLAYER_DRAW_DAMAGE_SIZE := Vector2(54, 80)
const PLAYER_DRAW_LACERAR_HEIGHT := 77.0
const PLAYER_ATTACK_PREP_FRAME_TIME := 0.085
const ATTACK_LOCK_HOLD_TIME := 0.8
const ATTACK_LOCK_MIN_DRAG := 18.0
const ATTACK_LOCK_CONE_COS := 0.90
const ABILITY_CANCEL_RADIUS := 54.0
const ABILITY_TARGET_DRAG_DEADZONE := 14.0
const ABILITY_TARGET_FULL_DRAG := 118.0
const UI_TRANSITION_BLOCK_MS := 180
const MANIFEST_DRAG_DEADZONE := 8.0
const BULLET_SPEED := 780.0
const MAX_BULLETS := 56
const ENEMY_BASE_HP := 30.0
const ENEMY_BASE_SPEED := 108.0
const ENEMY_MAX_BASE := 6
const ENEMY_SPAWN_INTERVAL := 0.82
const ENEMY_SPAWN_INTERVAL_EARLY := 1.34
const ENEMY_SPAWN_INTERVAL_LATE := 0.72
const ENEMY_RAMP_START_TIME := 180.0
const ENEMY_RAMP_PEAK_TIME := 780.0
const ENEMY_LIMIT_STEP_TIME := 45.0
const ENEMY_MIN_SPAWN_DISTANCE := 72.0
const ANOMALIA_ESPREITADOR_TIME := 75.0
const ANOMALIA_PROJETADOR_TIME := 150.0
const ANOMALIA_CRISTALIZADOR_TIME := 240.0
const ANOMALIA_AGLOMERADOR_TIME := 330.0
const ANOMALIA_CURATER_TIME := 420.0
const CURATER_HEAL_INTERVAL := 1.0
const CURATER_HEAL_LOST_PERCENT := 0.20
const CURATER_MITIGATION := 0.42
const FUSION_CHECK_INTERVAL := 1.0
const FUSION_RADIUS := 90.0
const FUSION_REQUIRED := 3
const FUSION_TIME := 120.0
const CARD_COST_BASE := 500
const FORCED_SHOP_CARDS := 6
const FORCED_SHOP_WARNING := 15.0
const FORCED_SHOP_SLOW_START := 3.0
const FORCED_SHOP_MIN_TIME_SCALE := 0.12
const FORCED_SHOP_INTERVAL := 180.0
const SHOP_RETURN_TIME := 3.0
const SHOP_PURCHASE_ANIM_TIME := 0.42
const SECONDARY_SKILL_COOLDOWN := 75.0
const SECONDARY_ELETRICA_DRAIN_DELAY := 10.0
const SECONDARY_ELETRICA_DRAIN_RATE := 0.005
const SECONDARY_ELETRICA_DURATION := 8.0
const SECONDARY_LACERANTE_DURATION := 3.0
const SECONDARY_PRISMATICA_DURATION := 8.0
const SECONDARY_PRISMATICA_BEAM_RANGE := 350.0
const SECONDARY_PRISMATICA_BEAM_WIDTH := 24.0
const SECONDARY_PRISMATICA_BEAM_SPIN_SPEED := TAU / 1.25
const SECONDARY_PRISMATICA_HIT_INTERVAL := 0.16
const SECONDARY_RETORNANTE_DURATION := 8.0
const SECONDARY_PARASITICA_DURATION := 8.0
const PARASITE_MARK_DURATION := 6.0
const PARASITE_FEAST_DURATION := 8.0
const PARASITE_ULTIMATE_MAX_DURATION := 11.5
const PARASITE_SPIT_RADIUS := 155.0
const PARASITE_SPIT_DURATION := 4.8
const PARASITE_SPIT_TRAVEL := 0.46
const SECONDARY_GRAVITANTE_DURATION := 8.0
const SECONDARY_ANCORADA_DURATION := 8.0
const BOSS_READY_TIME := 0.0
const BOSS_CALL_COUNTDOWN := 1.2
const BOSS_BASE_HP := 3600.0
const BOSS_ARMOR := 0.48
const BOSS_ENTRY_TIME := 1.2
const BOSS_STAGE_JUMP_TIME := 6.0
const BOSS_STAGE_SLAM_TIME := 1.35
const BOSS_STAGE_WAVE_WARNING := 0.78
const BOSS_STAGE_WAVE_INTERVAL := 1.15
const BOSS_STAGE_WAVE_SPEED := 230.0
const BOSS_STAGE_WAVE_COUNT := 3
const BOSS_STAGE_WAVE_HAPTIC_MS := 85
const BOSS1_REWIND_THRESHOLD := 0.30
const BOSS1_REWIND_SECONDS := 10.0
const BOSS1_REWIND_COOLDOWN := 45.0
const BOSS1_REWIND_BOSS_HEAL := 0.40
const BOSS1_REWIND_PLAYER_HEAL := 0.25
const BOSS1_REWIND_SAMPLE_INTERVAL := 0.08
const BOSS1_TIME_WAVE_SPEED := 360.0
const BOSS1_TIME_WAVE_WIDTH := 22.0
const BOSS1_TIME_WAVE_WARNING := 0.65
const BOSS1_CLOCK_TRAVEL_TIME := 0.70
const BOSS1_CLOCK_TURN_TIME := 3.20
const BOSS1_REWIND_PLAYBACK_TIME := 3.20
const BOSS1_RAIN_THRESHOLD := 0.30
const WEATHER_RAIN_DROP_RATE := 185.0
const WEATHER_SNOW_DROP_RATE := 72.0
const WEATHER_MAX_RAIN_DROPS := 260
const WEATHER_MAX_SNOW_FLAKES := 170
const WEATHER_MAX_PUDDLES := 28
const WEATHER_PUDDLE_MIN_SIZE := 10.0
const WEATHER_PUDDLE_MAX_SIZE := 30.0
const WEATHER_PUDDLE_SLOW_MULT := 0.90
const WEATHER_RAIN_FADE_TIME := 3.0
const WEATHER_RAIN_AUDIO_VOLUME := 0.40
const GRAVITANTE_ORBITAL_TRANSFER_RADIUS := 185.0
const TREMBO_HEAL_INTERVAL_BASE := 2.5
const TREMBO_HEAL_RATIO_BASE := 0.005
const TREMBO_REVIVE_INVULNERABILITY := 10.0
const PETRO_BASE_HP := 500.0
const PETRO_BASE_DEFENSE := 20.0
const PETRO_BASE_DAMAGE := 25.0
const PETRO_ATTACK_INTERVAL := 1.0
const PETRO_ATTACK_RANGE := 58.0
const PETRO_MOVE_SPEED := 235.0
const RARE_CARD_NAMES := ["Trembo", "Petro", "Poison", "Coletora", "Mercenaria"]
const CARD_RARITY_COMMON_COLOR := Color(0.96, 0.97, 1.0)
const CARD_RARITY_RARE_COLOR := Color(1.0, 0.76, 0.12)
const BOSS_ATTACK_BASE_COOLDOWN := 3.8
const BOSS2_ENTRY_TIME := 2.5
const BOSS2_WARNING_TIME := 1.7
const BOSS2_ATTACK_INTERVAL := 5.2
const BOSS2_WAVE_SPEED_MULT := 0.82
const BOSS2_WAVE_WIDTH_MULT := 0.88
const BOSS2_WAVE_WIDTH := 70.0
const BOSS2_BREATH_TIME := 2.6
const BOSS2_SHIELD_TIME := 3.2
const BOSS2_SLOW_ZONE_TIME := 4.0
const BOSS2_SLOW_MULT := 0.58
const PHASE_TRANSITION_TIME := 1.4
const BOSS_FRAGMENT_PICKUP_RADIUS := 42.0
const MUSIC_PAUSE_FADE_TIME := 3.0
const LARAPIO_SPAWN_TIME := 180.0
const LARAPIO_PORTAL_TIME := 10.0
const LARAPIO_PORTAL_HIT_PAUSE := 2.0
const LARAPIO_STEAL_RADIUS := 72.0
const LARAPIO_STEAL_RATIO := 0.10
const LARAPIO_STUN_TIME := 1.4
const LARAPIO_THROW_INTERVAL := 4.0
const LARAPIO_COIN_DROP_LIFE := 2.4
const LARAPIO_COIN_DROP_INTERVAL := 0.16

const ENEMY_COMMON := "comum"
const ENEMY_ATIRADOR := "atirador"
const ENEMY_KAMIKAZE := "kamikaze"
const ENEMY_AGGLOMERATOR := "aglomerador"
const ENEMY_STALKER := "espreitador"
const ENEMY_PROJECTOR := "projetador"
const ENEMY_CRYSTAL := "cristalizador"
const ENEMY_CURATER := "curater"
const ENEMY_LARAPIO := "larapio"
const ENEMY_DEVOTO := "devoto_febril"
const ENEMY_INCENSARIO := "incensario"
const ENEMY_GUARDIAO := "guardiao_sucata"

const BOSS3_ENTRY_TIME := 1.8
const BOSS3_MIASMA_TICK := 0.65
const BOSS3_CHEESE_INTERVAL := 12.0

const MANIFESTATIONS := [
	{
		"key": "eletrica",
		"name": "Eletrica",
		"desc": "Simples e segura: tiro reto, explosao eletrica, Q empurra e E cria anel de dano.",
		"icon": "manifestacao_eletrica.png",
		"color": Color(0.0, 0.88, 1.0),
		"accent": Color(0.62, 0.38, 1.0)
	},
	{
		"key": "lacerante",
		"name": "Lacerante",
		"desc": "Corpo a corpo agressivo: cortes atravessam, aplicam laceracao, Q limpa ao redor e E trava em uma carnificina.",
		"icon": "manifestacao_lacerante.png",
		"color": Color(1.0, 0.12, 0.18),
		"accent": Color(1.0, 0.58, 0.64)
	},
	{
		"key": "prismatica",
		"name": "Prismatica",
		"desc": "Mira e angulo: feixe ricocheteia, Q divide tiros em prismas e E deixa Geovana invulneravel com linhas de luz.",
		"icon": "manifestacao_prismatica.png",
		"color": Color(0.32, 1.0, 0.96),
		"accent": Color(1.0, 0.42, 0.72)
	},
	{
		"key": "retornante",
		"name": "Retornante",
		"desc": "Dano no retorno: o tiro vai fraco, volta forte, Q fortalece um pulso e E cria paradoxos de retorno.",
		"icon": "manifestacao_retornante.png",
		"color": Color(0.58, 0.38, 1.0),
		"accent": Color(1.0, 0.35, 0.68)
	},
	{
		"key": "parasitica",
		"name": "Parasitica",
		"desc": "Larvas vivas: tiros marcam por 6s, Q cospe um viveiro contaminante e E chama vermes subterraneos que devoram os marcados.",
		"icon": "manifestacao_parasitica.png",
		"color": Color(0.38, 1.0, 0.50),
		"accent": Color(0.86, 1.0, 0.28)
	},
	{
		"key": "gravitante",
		"name": "Gravitante",
		"desc": "Controle automatico: orbes perseguem alvos, Q cria orbitais extras e E puxa inimigos para um colapso.",
		"icon": "manifestacao_gravitante.png",
		"color": Color(0.46, 0.78, 1.0),
		"accent": Color(0.86, 0.96, 1.0)
	},
	{
		"key": "ancorada",
		"name": "Ancorada",
		"desc": "Defesa de territorio: tiros plantam ancoras, Q solta uma onda e E fortalece a area escolhida.",
		"icon": "manifestacao_ancorada.png",
		"color": Color(0.30, 0.88, 1.0),
		"accent": Color(1.0, 0.78, 0.26)
	}
]

const CARDS := [
	{"name": "Speed Boost", "nick": "Vento Celeste", "desc": "+6.5% velocidade de movimento.", "icon": "Deck/Speed_boost1.png", "color": Color(0.0, 1.0, 0.78)},
	{"name": "Porcao", "nick": "Sopro Vital", "desc": "Cura 45% da vida maxima; excesso aumenta vida maxima.", "icon": "Deck/carta_por1.png", "color": Color(0.38, 1.0, 0.54)},
	{"name": "Disparo crescente", "nick": "Odio Canalizado", "desc": "+10 dano base do auto attack.", "icon": "Deck/carta_odio1.png", "color": Color(1.0, 0.30, 0.28)},
	{"name": "Tempestade", "nick": "Precisao Critica", "desc": "+5 dano e +2% chance critica.", "icon": "Deck/Carta_tempestade_crescente1.png", "color": Color(0.96, 0.82, 0.22)},
	{"name": "Trembo", "nick": "Reversao Temporal", "desc": "Trembo acompanha e cura Geovana. Ao morrer, explode, restaura toda a vida, teleporta e concede 10s de imunidade.", "icon": "Deck/carta_trem1.png", "color": Color(0.16, 0.72, 1.0)},
	{"name": "Roubo de Vida", "nick": "Hemofluxo", "desc": "Projeteis curam uma fracao da vida perdida ao acertar.", "icon": "Deck/Carta_roubo_vida1.png", "color": Color(0.95, 0.10, 0.34)},
	{"name": "Speed Atack", "nick": "Fluidez Letal", "desc": "Reduz o intervalo entre disparos.", "icon": "Deck/carta_onda.png", "color": Color(1.0, 0.88, 0.20)},
	{"name": "Teleporte", "nick": "Salto Espacial", "desc": "Reduz recarga do teleporte ate 0.5s.", "icon": "Deck/carta_teleporte1.png", "color": Color(1.0, 0.0, 0.92)},
	{"name": "Petro", "nick": "Sentinela Leal", "desc": "Invoca Petro com vida e resistencia proprias. Ele persegue, luta e evolui visualmente com novas copias.", "icon": "Deck/carta_petro1.png", "color": Color(0.24, 0.95, 1.0)},
	{"name": "Defesa", "nick": "Pele Cronal", "desc": "+3.5 de resistencia, ate 50.", "icon": "Deck/carta_defesa1.png", "color": Color(0.70, 0.88, 1.0)},
	{"name": "Sorte", "nick": "Anomalia Favoravel", "desc": "+0.3% sorte para drops e cartas raras.", "icon": "Deck/carta_sorte1.png", "color": Color(1.0, 0.66, 0.80)},
	{"name": "Poison", "nick": "Toxina Temporal", "desc": "Projeteis envenenam inimigos e boss com dano por tempo.", "icon": "Deck/carta_poison1.png", "color": Color(0.68, 1.0, 0.20)},
	{"name": "Coletora", "nick": "Foice do Tempo", "desc": "Executa comuns abaixo do limite. Boss usa 20% desse valor, com teto de 1,5%.", "icon": "Deck/carta_estalo1.png", "color": Color(0.95, 0.08, 0.24)},
	{"name": "Mercenaria", "nick": "Contrato de Guerra", "desc": "Cada abate paga o bonus atual. A cada 5, o contrato melhora; sofrer dano quebra a sequencia.", "icon": "Deck/carta_mercenaria1.png", "color": Color(1.0, 0.62, 0.16)}
]

const CATALOG_TABS := ["Manifestacoes", "Inimigos", "Chefes", "Fracoes", "Aureas", "Cartas"]

const AURAS := [
	{"name": "Voraz", "desc": "Coleta fome, cura pouco e recompensa aproximacao controlada."},
	{"name": "Racional", "desc": "Favorece eficiencia: acertos e escolhas corretas viram vantagem."},
	{"name": "Insana", "desc": "Pressiona com Eco e risco alto para ganhar dano e ritmo."}
]

var mode = "menu"
var previous_mode = "game"
var font: Font
var textures = {}
var current_phase = 1
var pending_phase = 0
var selected_manifestation = 0
var menu_selected = 0
var manifest_drag_start_x = 0.0
var manifest_drag_start_scroll = 0.0
var manifest_drag_touch_index = -999
var manifest_drag_moved = false
var manifest_is_dragging = false
var manifest_scroll_pos = 0.0
var manifest_last_vibrated_index = 0
var deck_selected = 0
var deck_scroll_pos = 0.0
var deck_drag_start_x = 0.0
var deck_drag_start_scroll = 0.0
var deck_drag_touch_index = -999
var deck_drag_moved = false
var deck_is_dragging = false
var deck_previous_mode = "paused"
var manifestation_key = "eletrica"
var player_pos = PLAYER_START
var player_hp = PLAYER_BASE_HP
var player_hp_max = PLAYER_BASE_HP
var player_speed = PLAYER_BASE_SPEED
var player_damage = PLAYER_BASE_DAMAGE
var player_attack_interval = PLAYER_BASE_ATTACK_INTERVAL
var player_dash_cooldown = PLAYER_BASE_DASH_COOLDOWN
var player_defense = 0.0
var player_crit_chance = 0.0
var player_lifesteal = 0.0
var poison_damage = 0.0
var execute_threshold = 0.0
var luck = 0.0
var trembo_charges = 0
var trembo_pos = PLAYER_START + Vector2(64, 20)
var trembo_side = 1.0
var trembo_heal_timer = 0.0
var trembo_anim_time = 0.0
var trembo_facing = "stop"
var trembo_invulnerability = 0.0
var petro_active = false
var petro_pos = PLAYER_START + Vector2(-64, 32)
var petro_fire_timer = 0.0
var petro_hp = PETRO_BASE_HP
var petro_hp_max = PETRO_BASE_HP
var petro_defense = PETRO_BASE_DEFENSE
var petro_damage = PETRO_BASE_DAMAGE
var petro_evolution = 1
var petro_anim_time = 0.0
var petro_facing = "left"
var boss_poison_timer = 0.0
var boss_poison_tick = 0.0
var boss_parasite_seeds = 0
var boss_parasite_mark_time = 0.0
var mercenary_bonus_points = 0
var mercenary_hud_pulse = 0.0
var collector_hud_pulse = 0.0
var score = 0
var score_total = 0
var card_cost = CARD_COST_BASE
var cards_bought = {}
var combo_kills = 0
var enemies_killed = 0
var enemy_base_hp = ENEMY_BASE_HP
var enemy_speed_base = ENEMY_BASE_SPEED
var enemy_close_damage = 0.0
var enemy_far_damage = 0.0
var time_alive = 0.0
var elapsed_unpaused = 0.0
var spawn_timer = 0.0
var last_attack_time = -10.0
var last_dash_time = -10.0
var last_skill_time = -10.0
var last_secondary_time = -999.0
var secondary_key_was_pressed = false
var last_damage_time = -10.0
var retornante_memoria_pending = false
var forced_shop_timer = -1.0
var forced_shop_triggered = false
var forced_shop_enabled = true
var shop_countdown_last_second = -1
var next_forced_shop_time = FORCED_SHOP_INTERVAL
var shop_auto_elapsed = 0.0
var shop_return_timer = 0.0
var shop_cards = []
var shop_selected = 0
var shop_rerolls = 3
var shop_purchase_anim_timer = 0.0
var shop_purchase_pending_card = {}
var shop_purchase_pending_can_continue = false
var boss_ready = false
var boss_call_timer = -1.0
var boss_active = false
var boss_dead = false
var boss_hp = BOSS_BASE_HP
var boss_hp_max = BOSS_BASE_HP
var boss_pos = Vector2(1240, 410)
var boss_phase = 0.0
var boss_attack_timer = 0.0
var boss_entry_timer = 0.0
var boss_stage_timer = 0.0
var boss_stage_60_done = false
var boss_stage_40_done = false
var boss_stage_safe_angle = 0.0
var boss_attacks = []
var boss_transition_waves = []
var boss1_rewind_cooldown = 0.0
var boss1_rewind_history = []
var boss1_rewind_sample_timer = 0.0
var boss1_time_wave = {}
var boss1_rewind_sequence = {}
var boss1_rewind_visual_projectiles = []
var boss1_rewind_vibration_timer = 0.0
var boss1_rewind_clock_tick = -1
var boss_empurrou_player = false
var boss_name = "CARANGUEJO COSMICO GIGANTE"
var boss_title_color = Color(1.0, 0.52, 0.16)
var phase_transition_timer = 0.0
var phase_fragment = {}
var larapio_spawned = false
var next_larapio_spawn_time = LARAPIO_SPAWN_TIME
var larapio_coin_drops = []
var fusion_check_timer = 0.0
var event_alert_text = ""
var event_alert_color = Color.WHITE
var event_alert_timer = 0.0
var screen_shake_timer = 0.0
var screen_shake_strength = 0.0
var damage_flash_timer = 0.0
var orientation_poll_timer = 0.0
var last_manual_orientation = DisplayServer.SCREEN_SENSOR_LANDSCAPE
var alert_stalker_done = false
var alert_projector_done = false
var alert_crystal_done = false
var alert_agglomerator_done = false
var alert_curater_done = false
var touch_move = Vector2.ZERO
var pointer_down = false
var active_screen_touches: Dictionary = {}
var ignore_mouse_until_msec: int = 0
var ui_input_block_until_msec: int = 0
var player_stun_timer = 0.0
var move_touch_index = -1
var attack_touch_index = -1
var attack_dragging = false
var attack_holding = false
var attack_hold_timer = 0.0
var attack_drag_touch_index = -1
var attack_drag_direction = Vector2.ZERO
var attack_drag_start_pos = Vector2.ZERO
var attack_touch_pos = Vector2.ZERO
var attack_lock_selecting = false
var attack_lock_candidate_kind = ""
var attack_lock_candidate_uid = -1
var locked_target_kind = ""
var locked_target_uid = -1
var skill_touch_index = -1
var secondary_touch_index = -1
var dash_touch_index = -1
var skill_touch_pos = Vector2.ZERO
var secondary_touch_pos = Vector2.ZERO
var teleport_dragging = false
var teleport_drag_screen = Vector2.ZERO
var teleport_drag_origin = Vector2.ZERO
var joystick_origin = Vector2.ZERO
var hud_joy_pos: Vector2 = Vector2.ZERO
var hud_joy_scale: float = 1.0
var hud_attack_pos: Vector2 = Vector2.ZERO
var hud_attack_scale: float = 1.0
var hud_skill_scale: float = 1.0
var hud_secondary_pos: Vector2 = Vector2.ZERO
var hud_secondary_scale: float = 1.0
var hud_dash_pos: Vector2 = Vector2.ZERO
var hud_dash_scale: float = 1.0

var edit_layout_offset = Vector2.ZERO

var settings_previous_mode: String = "menu"

var hud_left_panel_pos = Vector2(-1, -1)
var hud_right_panel_pos = Vector2(-1, -1)
var hud_boss_panel_pos = Vector2(-1, -1)
var hud_skill_pos = Vector2(-1, -1)
var hud_pause_pos = Vector2(-1, -1)
var hud_boss_call_pos = Vector2(-1, -1)
var edit_layout_start_scale = 1.0

var vol_master: float = 1.0
var vol_music: float = 1.0
var vol_sfx: float = 1.0

var gfx_particles: bool = true
var gfx_shadows: bool = true
var gfx_screen_shake: bool = true
var damage_text_scale: float = 1.0
var interface_text_scale: float = 1.25
var analog_fixed: bool = true
var shop_auto_enabled: bool = true
var shop_auto_interval: float = 180.0
var auto_target_priority: String = "nearest"
var haptics_enabled: bool = true
var edit_layout_selected: String = ""
var edit_layout_touch_index: int = -1
var settings_selected = 0
var buttons = {}
var menu_buttons = {}
var settings_buttons = {}
var catalog_tab = 0
var catalog_selected = 0
var catalog_detail_open = false
var eletrica_shot_counter = 0
var shop_select_pulse_timer = 0.0
var shop_select_pulse_index = -1
var enemies = []
var bullets = []
var enemy_bullets = []
var shockwaves = []
var effects = []
var heal_orbs = []
var slashes = []
var boss2_ice_shards = []
var boss2_snow_zones = []
var boss2_frost_particles = []
var phase3_miasma_zones = []
var phase3_cheeses = []
var boss3_faith = 50.0
var boss3_stage = 1
var boss3_stun_timer = 0.0
var boss3_rain_timer = 4.3
var boss3_spit_timer = 4.2
var boss3_tail_timer = 3.2
var boss3_charge_timer = 6.8
var boss3_cheese_timer = BOSS3_CHEESE_INTERVAL
var boss3_dialogue_timer = 8.0
var boss3_events = {}
var boss3_consume_uid = -1
var boss3_consume_timer = 0.0
var boss3_ritual_timer = 0.0
var boss3_ritual_destroyed = 0
var anchors = []
var prisms = []
var orbitals = []
var seed_links = []
var parasite_spit_zones = []
var return_bullets = []
var manifestation_secondaries = []
var last_facing = Vector2.RIGHT
var lacerante_combo = 0
var lacerante_combo_visual = 0
var lacerante_preparing = false
var lacerante_prepare_stage = 0
var lacerante_prepare_frame = 0
var lacerante_prepare_timer = 0.0
var lacerante_prepare_dir = Vector2.RIGHT
var rng = RandomNumberGenerator.new()

var sfx_players = []
var music_player = null
var current_music = ""
var audio_streams = {}
var music_pause_fade_mode = ""
var music_pause_fade_timer = 0.0
var music_pause_resume_volume = 1.0
var music_paused_by_pause = false
var rain_audio_player = null
var rain_audio_fade_timer = 0.0
var rain_audio_fade_mode = ""
var rain_audio_current_volume = 0.0
var boss1_rain_active = false
var weather_kind = ""
var weather_rain_intro_timer = 0.0
var raindrops = []
var puddles = []
var rain_splashes = []
var snowflakes = []

func _ready() -> void:
	font = ThemeDB.fallback_font
	rng.randomize()
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)

	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)

	rain_audio_player = AudioStreamPlayer.new()
	rain_audio_player.bus = "Master"
	add_child(rain_audio_player)

	for i in range(12):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)

	_load_audio_streams()

	_load_config()
	_load_textures()
	_reset_card_counts()
	set_process(true)

	_play_music("Menu.mp3")


func _load_config() -> void:
	if not FileAccess.file_exists("user://hud_config.save"):
		return
	var file = FileAccess.open("user://hud_config.save", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var lines = content.split("\n")
		for line in lines:
			var parts = line.split("=")
			if parts.size() == 2:
				var k = parts[0].strip_edges()
				var v = parts[1].strip_edges()
				var coords = v.split(",")
				if k == "joy_pos" and coords.size() == 2: hud_joy_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "joy_scale": hud_joy_scale = float(v)
				elif k == "attack_pos" and coords.size() == 2: hud_attack_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "attack_scale": hud_attack_scale = float(v)
				elif k == "skill_scale": hud_skill_scale = float(v)
				elif k == "secondary_pos" and coords.size() == 2: hud_secondary_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "secondary_scale": hud_secondary_scale = float(v)
				elif k == "dash_pos" and coords.size() == 2: hud_dash_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "dash_scale": hud_dash_scale = float(v)
				elif k == "hud_left_panel_pos" and coords.size() == 2: hud_left_panel_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "hud_right_panel_pos" and coords.size() == 2: hud_right_panel_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "hud_boss_panel_pos" and coords.size() == 2: hud_boss_panel_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "hud_skill_pos" and coords.size() == 2: hud_skill_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "hud_pause_pos" and coords.size() == 2: hud_pause_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "hud_boss_call_pos" and coords.size() == 2: hud_boss_call_pos = Vector2(float(coords[0]), float(coords[1]))
				elif k == "analog_fixed": analog_fixed = v != "false"
				elif k == "analog_mode": analog_fixed = v != "dinamico"
				elif k == "shop_auto_enabled": shop_auto_enabled = v != "false"
				elif k == "shop_auto_interval": shop_auto_interval = clamp(float(v), 180.0, 480.0)
				elif k == "auto_target_priority": auto_target_priority = _sanitize_target_priority(v)
				elif k == "haptics_enabled": haptics_enabled = v != "false"

				elif k == "vol_master": vol_master = float(v)

				elif k == "vol_music": vol_music = float(v)

				elif k == "vol_sfx": vol_sfx = float(v)

				elif k == "gfx_particles": gfx_particles = v == "true"

				elif k == "gfx_shadows": gfx_shadows = v == "true"

				elif k == "gfx_screen_shake": gfx_screen_shake = v == "true"
				elif k == "damage_text_scale": damage_text_scale = clamp(float(v), 0.7, 1.8)
				elif k == "interface_text_scale": interface_text_scale = clamp(float(v), 0.9, 1.6)
				elif k == "vol_master": vol_master = float(v)
				elif k == "vol_music": vol_music = float(v)
				elif k == "vol_sfx": vol_sfx = float(v)
				elif k == "gfx_particles": gfx_particles = v == "true"
				elif k == "gfx_shadows": gfx_shadows = v == "true"
				elif k == "gfx_screen_shake": gfx_screen_shake = v == "true"
				elif k == "damage_text_scale": damage_text_scale = clamp(float(v), 0.7, 1.8)
		file.close()
	forced_shop_enabled = shop_auto_enabled


func _save_config() -> void:
	var file = FileAccess.open("user://hud_config.save", FileAccess.WRITE)
	if file:
		file.store_string("joy_pos=" + str(hud_joy_pos.x) + "," + str(hud_joy_pos.y) + "\n")
		file.store_string("joy_scale=" + str(hud_joy_scale) + "\n")
		file.store_string("attack_pos=" + str(hud_attack_pos.x) + "," + str(hud_attack_pos.y) + "\n")
		file.store_string("attack_scale=" + str(hud_attack_scale) + "\n")
		file.store_string("skill_scale=" + str(hud_skill_scale) + "\n")
		file.store_string("secondary_pos=" + str(hud_secondary_pos.x) + "," + str(hud_secondary_pos.y) + "\n")
		file.store_string("secondary_scale=" + str(hud_secondary_scale) + "\n")
		file.store_string("dash_pos=" + str(hud_dash_pos.x) + "," + str(hud_dash_pos.y) + "\n")
		file.store_string("dash_scale=" + str(hud_dash_scale) + "\n")
		file.store_string("hud_left_panel_pos=" + str(hud_left_panel_pos.x) + "," + str(hud_left_panel_pos.y) + "\n")
		file.store_string("hud_right_panel_pos=" + str(hud_right_panel_pos.x) + "," + str(hud_right_panel_pos.y) + "\n")
		file.store_string("hud_boss_panel_pos=" + str(hud_boss_panel_pos.x) + "," + str(hud_boss_panel_pos.y) + "\n")
		file.store_string("hud_skill_pos=" + str(hud_skill_pos.x) + "," + str(hud_skill_pos.y) + "\n")
		file.store_string("hud_pause_pos=" + str(hud_pause_pos.x) + "," + str(hud_pause_pos.y) + "\n")
		file.store_string("hud_boss_call_pos=" + str(hud_boss_call_pos.x) + "," + str(hud_boss_call_pos.y) + "\n")
		file.store_string("analog_mode=" + ("fixo" if analog_fixed else "dinamico") + "\n")
		file.store_string("analog_fixed=" + ("true" if analog_fixed else "false") + "\n")
		file.store_string("shop_auto_enabled=" + ("true" if shop_auto_enabled else "false") + "\n")
		file.store_string("shop_auto_interval=" + str(shop_auto_interval) + "\n")
		file.store_string("auto_target_priority=" + auto_target_priority + "\n")
		file.store_string("haptics_enabled=" + ("true" if haptics_enabled else "false") + "\n")

		file.store_string("vol_master=" + str(vol_master) + "\n")

		file.store_string("vol_music=" + str(vol_music) + "\n")

		file.store_string("vol_sfx=" + str(vol_sfx) + "\n")

		file.store_string("gfx_particles=" + ("true" if gfx_particles else "false") + "\n")

		file.store_string("gfx_shadows=" + ("true" if gfx_shadows else "false") + "\n")

		file.store_string("gfx_screen_shake=" + ("true" if gfx_screen_shake else "false") + "\n")
		file.store_string("damage_text_scale=" + str(damage_text_scale) + "\n")
		file.store_string("interface_text_scale=" + str(interface_text_scale) + "\n")
		file.store_string("vol_master=" + str(vol_master) + "\n")
		file.store_string("vol_music=" + str(vol_music) + "\n")
		file.store_string("vol_sfx=" + str(vol_sfx) + "\n")
		file.store_string("gfx_particles=" + ("true" if gfx_particles else "false") + "\n")
		file.store_string("gfx_shadows=" + ("true" if gfx_shadows else "false") + "\n")
		file.store_string("gfx_screen_shake=" + ("true" if gfx_screen_shake else "false") + "\n")
		file.store_string("damage_text_scale=" + str(damage_text_scale) + "\n")
		file.close()


func _load_textures() -> void:
	var base = "res://assets/sprites/"
	textures["map_phase_1"] = _safe_load(base + "Fase1.png")
	textures["map_phase_2"] = _safe_load(base + "Fase2.png")
	textures["map_phase_3"] = _safe_load(base + "Fase3.png")
	textures["menu"] = _safe_load(base + "Menu_intro.png.png")
	textures["choice_bg"] = _safe_load(base + "Escolha.png")
	textures["cards_back"] = _safe_load(base + "Cartas_back.png")
	textures["menu_panels"] = [_safe_load(base + "Melhoria_1.png"), _safe_load(base + "Melhoria_2.png"), _safe_load(base + "Melhoria_3.png"), _safe_load(base + "Melhoria_4.png"), _safe_load(base + "Melhoria_5.png")]
	textures["player_idle"] = [_safe_load(base + "Geo1.png"), _safe_load(base + "Geo2.png"), _safe_load(base + "Geo3.png"), _safe_load(base + "Geo4.png")]
	textures["player_right"] = [_safe_load(base + "Geo1-Dir.png"), _safe_load(base + "Geo2-Dir.png"), _safe_load(base + "Geo3-Dir.png")]
	textures["player_left"] = [_safe_load(base + "Geo1-Esq.png"), _safe_load(base + "Geo2-Esq.png"), _safe_load(base + "Geo3-Esq.png")]
	textures["player_up"] = [_safe_load(base + "Geo1-up.png"), _safe_load(base + "Geo2-up.png")]
	textures["player_down"] = [_safe_load(base + "Geo1-Down.png"), _safe_load(base + "Geo2-Down.png")]
	textures["player_fire"] = [_safe_load(base + "Geo_Disp1.png"), _safe_load(base + "Geo_Disp2.png")]
	textures["player_damage"] = [_safe_load(base + "Geo-Umbra-V2-1-dano.png"), _safe_load(base + "Geo-Umbra-V2-2-dano.png"), _safe_load(base + "Geo-Umbra-V2-3-dano.png"), _safe_load(base + "Geo-Umbra-V2-4-dano.png"), _safe_load(base + "Geo-Umbra-V2-5-dano.png")]
	textures["player_lacerar"] = [_safe_load(base + "Disp_Lacerar1.png"), _safe_load(base + "Disp_Lacerar2.png"), _safe_load(base + "Disp_Lacerar3.png"), _safe_load(base + "Disp_Lacerar4.png"), _safe_load(base + "Disp_Lacerar5.png"), _safe_load(base + "Disp_Lacerar6.png")]
	var companion_base = base + "companions/"
	textures["trembo_up"] = [_safe_load(companion_base + "trembo_costa1.png")]
	textures["trembo_down"] = [_safe_load(companion_base + "trembo_frente1.png"), _safe_load(companion_base + "trembo_frente2.png")]
	textures["trembo_left"] = [_safe_load(companion_base + "trembo_esquerda1.png"), _safe_load(companion_base + "trembo_esquerda2.png")]
	textures["trembo_right"] = [_safe_load(companion_base + "trembo_direita1.png"), _safe_load(companion_base + "trembo_direita2.png")]
	textures["trembo_stop"] = [_safe_load(companion_base + "trembo_stop1.png"), _safe_load(companion_base + "trembo_stop2.png")]
	textures["petro_1_left"] = [_safe_load(companion_base + "Petro_nivel1_esq1.png"), _safe_load(companion_base + "Petro_nivel1_esq2.png")]
	textures["petro_1_right"] = [_safe_load(companion_base + "Petro_nivel1_dir1.png"), _safe_load(companion_base + "Petro_nivel1_dir2.png")]
	textures["petro_1_up"] = [_safe_load(companion_base + "Petro_nivel1_up1.png"), _safe_load(companion_base + "Petro_nivel1_up2.png")]
	textures["petro_1_stop"] = [_safe_load(companion_base + "Petro_nivel1_stop1.png"), _safe_load(companion_base + "Petro_nivel1_stop2.png"), _safe_load(companion_base + "Petro_nivel1_stop3.png")]
	for level in [2, 3]:
		textures["petro_%d_left" % level] = [_safe_load(companion_base + "Petro_nivel%d_esq1.png" % level), _safe_load(companion_base + "Petro_nivel%d_esq2.png" % level)]
		textures["petro_%d_right" % level] = [_safe_load(companion_base + "Petro_nivel%d_dir1.png" % level), _safe_load(companion_base + "Petro_nivel%d_dir2.png" % level)]
	textures["enemy_common_phase_1"] = [_safe_load(base + "Inimig1.png"), _safe_load(base + "Inimig2.png")]
	textures["enemy_common_phase_2_left"] = [_safe_load(base + "inimigo_direita2-1.png"), _safe_load(base + "inimigo_direita2-2.png")]
	textures["enemy_common_phase_2_right"] = [_safe_load(base + "inimigo_esquerda2-1.png"), _safe_load(base + "inimigo_esquerda2-2.png")]
	textures["enemy_phase_3_left"] = [_safe_load(base + "inimigo_esquerda3-1.png"), _safe_load(base + "inimigo_esquerda3-2.png")]
	textures["enemy_phase_3_right"] = [_safe_load(base + "inimigo_direita3-1.png"), _safe_load(base + "inimigo_direita3-2.png")]
	textures["enemy_phase_3_bullet"] = [_safe_load(base + "Disp_inimigo3_1.png"), _safe_load(base + "Disp_inimigo3_2.png")]
	textures["enemy_right"] = [_safe_load(base + "inimigo_direita2-1.png"), _safe_load(base + "inimigo_direita2-2.png")]
	textures["enemy_left"] = [_safe_load(base + "inimigo_esquerda2-1.png"), _safe_load(base + "inimigo_esquerda2-2.png")]
	textures["agglomerator"] = [_safe_load(base + "aglomerador1.png"), _safe_load(base + "aglomerador2.png")]
	textures["stalker"] = [_safe_load(base + "espreitador1.png"), _safe_load(base + "espreitador2.png")]
	textures["projector"] = [_safe_load(base + "projetador1.png"), _safe_load(base + "projetador2.png")]
	textures["crystal"] = [_safe_load(base + "cristalizador1.png"), _safe_load(base + "cristalizador2.png")]
	textures["curater"] = [_safe_load(base + "curater1.png"), _safe_load(base + "curater2.png")]
	textures["larapio"] = [_safe_load(base + "larapio1.png"), _safe_load(base + "larapio2.png")]
	textures["boss"] = _safe_load(base + "Boss1.png")
	textures["boss_stage1"] = [_safe_load(base + "Boss1.png"), _safe_load(base + "Boss2.png")]
	textures["boss_stage2"] = [_safe_load(base + "Boss3.png"), _safe_load(base + "Boss4.png")]
	textures["boss_stage3"] = [_safe_load(base + "Boss5.png"), _safe_load(base + "Boss6.png")]
	textures["boss_walk"] = [_safe_load(base + "Bossandando3_1.png"), _safe_load(base + "Bossandando3_2.png")]
	textures["boss3"] = [_safe_load(base + "Boss3_1.png"), _safe_load(base + "Boss3_2.png")]
	textures["boss3_cheese"] = _safe_load(base + "queijo.png")
	textures["boss3_flask"] = _safe_load(base + "disparo_boss3.png")
	textures["boss2"] = [_safe_load(base + "Boss2_1.png"), _safe_load(base + "Boss2_2.png")]
	textures["boss2_orb"] = [_safe_load(base + "Bolha1.png"), _safe_load(base + "Bolha2.png"), _safe_load(base + "Bolha3.png"), _safe_load(base + "Bolha4.png"), _safe_load(base + "Bolha5.png")]
	textures["boss2_wave"] = _safe_load(base + "Onda_Boss2.png")
	textures["coin"] = _safe_load(base + "moeda.png")
	for item in MANIFESTATIONS:
		textures["manifestation_" + item["key"]] = _safe_load(base + item["icon"])
	for card in CARDS:
		textures["card_" + card["name"]] = _safe_load(base + card["icon"])


func _safe_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource is Texture2D:
			return resource
	if FileAccess.file_exists(path):
		var image := Image.new()
		var err = image.load(path)
		if err == OK and not image.is_empty():
			return ImageTexture.create_from_image(image)
	return null

func _load_audio_streams() -> void:
	var path = "res://Game Base/Ruptura_Temporal-APOLO2.0/Sounds/"
	var files = ["Agudos-leve.mp3", "Boss1.mp3", "Boss2.mp3", "Boss3.mp3", "Boss3_andando.mp3", "Brinquedo.mp3", "Disparo_Geo.wav", "Esgoto.mp3", "Estalo.mp3", "Fase2_Boss.mp3", "Fase3_Boss.mp3", "fases.mp3", "Fase_boas.mp3", "Flauta.mp3", "Frasco.mp3", "frog.mp3", "Game_Over.mp3", "Geo_andando.mp3", "Hit_Boss1.mp3", "hit_person.mp3", "Inimigo1_hit.wav", "Inimigo3_hit.mp3", "Menu.mp3", "Neve.wav", "piano.mp3", "Portal.mp3", "Praia.wav", "Queijo.mp3", "Tema_Neve.mp3", "Tema_Praia.mp3", "Tema_Ratos.mp3"]
	for f in files:
		var stream = _safe_load_audio(path + f)
		if stream:
			audio_streams[f] = stream
	var root_music = {
		"Menu.mp3": "res://Menu.mp3",
		"Fase2.mp3": "res://Fase2.mp3",
		"Boss1-1.mp3": "res://Boss1-1.mp3"
	}
	for name in root_music:
		var stream = _safe_load_audio(root_music[name], true)
		if stream:
			audio_streams[name] = stream
	var phase1_tracks = {
		"Fase1.mp3": "res://Fase1.mp3",
		"Fase1-2.mp3": "res://Fase1-2.mp3"
	}
	for name in phase1_tracks:
		var stream = _safe_load_audio(phase1_tracks[name], false)
		if stream:
			audio_streams[name] = stream
	var phase3_tracks = {
		"Fase3-1.mp3": "res://Fase3-1.mp3",
		"Fase3-2.mp3": "res://Fase3-2.mp3"
	}
	for name in phase3_tracks:
		var stream = _safe_load_audio(phase3_tracks[name], false)
		if stream:
			audio_streams[name] = stream
	var root_sfx = {
		"shop_countdown_tick": "res://Disparo.MP3",
		"rain": "res://rain.mp3"
	}
	for name in root_sfx:
		var stream = _safe_load_audio(root_sfx[name], name == "rain")
		if stream:
			audio_streams[name] = stream

func _safe_load_audio(path: String, loop := false) -> AudioStream:
	if not _import_resource_ready(path):
		return null
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			if loop:
				_enable_audio_loop(res)
			return res
	if FileAccess.file_exists(path) and path.get_extension().to_lower() == "mp3":
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var buffer = file.get_buffer(file.get_length())
			var stream = AudioStreamMP3.new()
			stream.data = buffer
			if loop:
				_enable_audio_loop(stream)
			return stream
	return null


func _import_resource_ready(path: String) -> bool:
	var import_path = path + ".import"
	if not FileAccess.file_exists(import_path):
		return true
	var file = FileAccess.open(import_path, FileAccess.READ)
	if not file:
		return true
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.begins_with("dest_files="):
			var has_dest = false
			var cursor = line.find("res://")
			while cursor >= 0:
				var end = line.find("\"", cursor)
				if end < 0:
					break
				var dest = line.substr(cursor, end - cursor)
				has_dest = true
				if FileAccess.file_exists(dest):
					file.close()
					return true
				cursor = line.find("res://", end + 1)
			file.close()
			return not has_dest
	file.close()
	return true


func _enable_audio_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

func _play_sfx(name: String, pitch_variance := 0.0, volume_scale := 1.0, pitch_center := 1.0) -> void:
	if not audio_streams.has(name): return
	var stream = audio_streams[name]
	var duck = 1.0 if name == "shop_countdown_tick" else _shop_countdown_audio_duck()
	var db = linear_to_db(max(0.001, vol_master * vol_sfx * volume_scale * duck))
	var pitch = clamp(pitch_center + (rng.randf_range(-pitch_variance, pitch_variance) if pitch_variance > 0.0 else 0.0), 0.55, 1.65)
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = db
			p.pitch_scale = pitch
			p.play()
			return
	if sfx_players.size() > 0:
		sfx_players[0].stream = stream
		sfx_players[0].volume_db = db
		sfx_players[0].pitch_scale = pitch
		sfx_players[0].play()

func _play_music(name: String) -> void:
	if current_music == name: return
	current_music = name
	music_pause_fade_mode = ""
	music_paused_by_pause = false
	if audio_streams.has(name):
		music_player.stream = audio_streams[name]
		music_player.stream_paused = false
		music_player.volume_db = linear_to_db(max(0.001, _music_target_volume()))
		music_player.play()
	else:
		music_player.stop()


func _music_target_volume() -> float:
	return vol_master * vol_music * _shop_countdown_audio_duck()


func _set_music_linear_volume(value: float) -> void:
	if music_player == null:
		return
	music_player.volume_db = linear_to_db(max(0.001, value))


func _begin_pause_music_fade_out() -> void:
	if music_player == null or music_player.stream == null or not music_player.playing:
		return
	music_pause_fade_mode = "out"
	music_pause_fade_timer = 0.0
	music_pause_resume_volume = max(0.001, _music_target_volume())
	music_paused_by_pause = false
	music_player.stream_paused = false


func _begin_pause_music_fade_in() -> void:
	if music_player == null or music_player.stream == null:
		return
	music_pause_fade_mode = "in"
	music_pause_fade_timer = 0.0
	music_pause_resume_volume = max(0.001, _music_target_volume())
	if not music_player.playing:
		music_player.play()
	music_player.stream_paused = false
	_set_music_linear_volume(0.001)
	music_paused_by_pause = false


func _update_music_pause_fade(delta: float) -> void:
	if music_player == null or music_pause_fade_mode == "":
		return
	music_pause_fade_timer += delta
	var progress = clamp(music_pause_fade_timer / MUSIC_PAUSE_FADE_TIME, 0.0, 1.0)
	if music_pause_fade_mode == "out":
		_set_music_linear_volume(lerp(music_pause_resume_volume, 0.001, progress))
		if progress >= 1.0:
			music_player.stream_paused = true
			music_paused_by_pause = true
			music_pause_fade_mode = ""
	elif music_pause_fade_mode == "in":
		var target = max(0.001, _music_target_volume())
		_set_music_linear_volume(lerp(0.001, target, progress))
		if progress >= 1.0:
			music_paused_by_pause = false
			music_pause_fade_mode = ""
			_update_audio_volumes()


func _play_phase_music() -> void:
	if current_phase == 3:
		_play_phase3_music_random()
	elif current_phase == 2:
		_play_music("Fase2.mp3")
	else:
		_play_phase1_music_random()


func _on_music_finished() -> void:
	if current_music == "Fase1.mp3" or current_music == "Fase1-2.mp3":
		_play_phase1_music_random()
		return
	if current_music == "Fase3-1.mp3" or current_music == "Fase3-2.mp3":
		_play_phase3_music_random()
		return
	if current_music != "" and music_player != null and music_player.stream != null:
		music_player.play()


func _play_phase1_music_random() -> void:
	var available = []
	for track in ["Fase1.mp3", "Fase1-2.mp3"]:
		if audio_streams.has(track):
			available.append(track)
	if available.is_empty():
		_play_music("fases.mp3")
		return
	var chosen = String(available[rng.randi_range(0, available.size() - 1)])
	if chosen == current_music and music_player != null:
		music_player.stream = audio_streams[chosen]
		music_player.stream_paused = false
		music_player.volume_db = linear_to_db(max(0.001, _music_target_volume()))
		music_player.play()
		return
	_play_music(chosen)


func _play_phase3_music_random() -> void:
	var available = []
	for track in ["Fase3-1.mp3", "Fase3-2.mp3"]:
		if audio_streams.has(track):
			available.append(track)
	if available.is_empty():
		_play_music("Esgoto.mp3")
		return
	var chosen = String(available[rng.randi_range(0, available.size() - 1)])
	if chosen == current_music and music_player != null:
		music_player.stream = audio_streams[chosen]
		music_player.stream_paused = false
		music_player.volume_db = linear_to_db(max(0.001, _music_target_volume()))
		music_player.play()
		return
	_play_music(chosen)


func _go_to_menu() -> void:
	mode = "menu"
	_block_ui_input()
	_update_audio_volumes()
	_play_music("Menu.mp3")

func _update_audio_volumes() -> void:
	if music_pause_fade_mode != "" or music_paused_by_pause:
		return
	if music_player != null:
		music_player.volume_db = linear_to_db(max(0.001, _music_target_volume()))
	if rain_audio_player != null and rain_audio_fade_mode == "":
		rain_audio_player.volume_db = linear_to_db(max(0.001, rain_audio_current_volume))


func _rain_audio_target_volume() -> float:
	return vol_master * vol_music * WEATHER_RAIN_AUDIO_VOLUME


func _start_rain_audio() -> void:
	if rain_audio_player == null or not audio_streams.has("rain"):
		return
	rain_audio_player.stream = audio_streams["rain"]
	if not rain_audio_player.playing:
		rain_audio_player.play()
	rain_audio_player.stream_paused = false
	rain_audio_current_volume = 0.001
	rain_audio_player.volume_db = linear_to_db(0.001)
	rain_audio_fade_timer = 0.0
	rain_audio_fade_mode = "in"


func _stop_rain_audio() -> void:
	if rain_audio_player == null or rain_audio_player.stream == null:
		return
	rain_audio_fade_timer = 0.0
	rain_audio_fade_mode = "out"


func _update_rain_audio_fade(delta: float) -> void:
	if rain_audio_player == null or rain_audio_fade_mode == "":
		return
	rain_audio_fade_timer += delta
	var progress = clamp(rain_audio_fade_timer / WEATHER_RAIN_FADE_TIME, 0.0, 1.0)
	if rain_audio_fade_mode == "in":
		rain_audio_current_volume = lerp(0.001, _rain_audio_target_volume(), progress)
		rain_audio_player.volume_db = linear_to_db(max(0.001, rain_audio_current_volume))
		if progress >= 1.0:
			rain_audio_fade_mode = ""
			rain_audio_current_volume = _rain_audio_target_volume()
			rain_audio_player.volume_db = linear_to_db(max(0.001, rain_audio_current_volume))
	elif rain_audio_fade_mode == "out":
		rain_audio_current_volume = lerp(rain_audio_current_volume, 0.001, progress)
		rain_audio_player.volume_db = linear_to_db(max(0.001, rain_audio_current_volume))
		if progress >= 1.0:
			rain_audio_fade_mode = ""
			rain_audio_current_volume = 0.0
			rain_audio_player.stop()


func _vibrate(duration_ms: int, amplitude := 0.5) -> void:
	if haptics_enabled:
		Input.vibrate_handheld(duration_ms, amplitude)

func _reset_card_counts() -> void:
	cards_bought.clear()
	for card in CARDS:
		cards_bought[card["name"]] = 0


func _start_game() -> void:
	mode = "game"
	current_phase = 1
	pending_phase = 0
	_play_phase_music()
	manifestation_key = MANIFESTATIONS[selected_manifestation]["key"]
	player_pos = PLAYER_START
	player_hp_max = PLAYER_BASE_HP
	player_hp = player_hp_max
	player_speed = PLAYER_BASE_SPEED
	player_damage = _manifestation_base_damage()
	player_attack_interval = _manifestation_attack_interval()
	player_dash_cooldown = PLAYER_BASE_DASH_COOLDOWN
	player_defense = 0.0
	player_crit_chance = 0.0
	player_lifesteal = 0.0
	poison_damage = 0.0
	execute_threshold = 0.0
	luck = 0.0
	trembo_charges = 0
	trembo_pos = player_pos + Vector2(64, 20)
	trembo_side = 1.0
	trembo_heal_timer = 0.0
	trembo_anim_time = 0.0
	trembo_facing = "stop"
	trembo_invulnerability = 0.0
	petro_active = false
	petro_pos = player_pos + Vector2(-64, 32)
	petro_fire_timer = 0.0
	petro_hp = PETRO_BASE_HP
	petro_hp_max = PETRO_BASE_HP
	petro_defense = PETRO_BASE_DEFENSE
	petro_damage = PETRO_BASE_DAMAGE
	petro_evolution = 1
	petro_anim_time = 0.0
	petro_facing = "left"
	boss_poison_timer = 0.0
	boss_poison_tick = 0.0
	boss_parasite_seeds = 0
	boss_parasite_mark_time = 0.0
	mercenary_bonus_points = 0
	mercenary_hud_pulse = 0.0
	collector_hud_pulse = 0.0
	score = 0
	score_total = 0
	card_cost = CARD_COST_BASE
	combo_kills = 0
	enemies_killed = 0
	enemy_base_hp = ENEMY_BASE_HP
	enemy_speed_base = ENEMY_BASE_SPEED
	enemy_close_damage = 0.0
	enemy_far_damage = 0.0
	time_alive = 0.0
	elapsed_unpaused = 0.0
	spawn_timer = 0.0
	last_attack_time = -10.0
	lacerante_combo = 0
	lacerante_combo_visual = 0
	lacerante_preparing = false
	lacerante_prepare_stage = 0
	lacerante_prepare_frame = 0
	lacerante_prepare_timer = 0.0
	lacerante_prepare_dir = Vector2.RIGHT
	last_dash_time = -10.0
	last_skill_time = -10.0
	last_secondary_time = -999.0
	secondary_key_was_pressed = false
	last_damage_time = -10.0
	retornante_memoria_pending = false
	forced_shop_timer = -1.0
	forced_shop_triggered = false
	shop_auto_elapsed = 0.0
	next_forced_shop_time = shop_auto_interval if shop_auto_enabled else INF
	shop_return_timer = 0.0
	boss_ready = false
	boss_call_timer = -1.0
	boss_active = false
	boss_dead = false
	boss_hp_max = BOSS_BASE_HP
	boss_hp = boss_hp_max
	boss_pos = Vector2(1240, 410)
	boss_phase = 0.0
	boss_attack_timer = 0.0
	boss_entry_timer = 0.0
	boss_stage_timer = 0.0
	boss_stage_60_done = false
	boss_stage_40_done = false
	boss_attacks.clear()
	boss_transition_waves.clear()
	_reset_boss1_rewind_state()
	boss2_ice_shards.clear()
	boss2_snow_zones.clear()
	boss2_frost_particles.clear()
	_clear_environment_weather()
	boss_empurrou_player = false
	boss_name = "CARANGUEJO COSMICO GIGANTE"
	boss_title_color = Color(1.0, 0.52, 0.16)
	phase_transition_timer = 0.0
	phase_fragment.clear()
	larapio_spawned = false
	next_larapio_spawn_time = LARAPIO_SPAWN_TIME
	fusion_check_timer = 0.0
	event_alert_text = ""
	event_alert_timer = 0.0
	alert_stalker_done = false
	alert_projector_done = false
	alert_crystal_done = false
	alert_agglomerator_done = false
	alert_curater_done = false
	touch_move = Vector2.ZERO
	pointer_down = false
	active_screen_touches.clear()
	ignore_mouse_until_msec = 0
	move_touch_index = -1
	attack_touch_index = -1
	attack_dragging = false
	attack_holding = false
	attack_hold_timer = 0.0
	attack_drag_touch_index = -1
	attack_drag_direction = Vector2.ZERO
	attack_drag_start_pos = Vector2.ZERO
	attack_touch_pos = Vector2.ZERO
	attack_lock_selecting = false
	attack_lock_candidate_kind = ""
	attack_lock_candidate_uid = -1
	locked_target_kind = ""
	locked_target_uid = -1
	skill_touch_index = -1
	secondary_touch_index = -1
	dash_touch_index = -1
	skill_touch_pos = Vector2.ZERO
	secondary_touch_pos = Vector2.ZERO
	teleport_dragging = false
	teleport_drag_screen = Vector2.ZERO
	eletrica_shot_counter = 0
	shop_select_pulse_timer = 0.0
	shop_select_pulse_index = -1
	_reset_card_counts()
	enemies.clear()
	bullets.clear()
	enemy_bullets.clear()
	larapio_coin_drops.clear()
	shockwaves.clear()
	effects.clear()
	heal_orbs.clear()
	slashes.clear()
	anchors.clear()
	prisms.clear()
	orbitals.clear()
	seed_links.clear()
	parasite_spit_zones.clear()
	return_bullets.clear()
	manifestation_secondaries.clear()
	_reset_phase3_state()
	_spawn_enemy(ENEMY_COMMON, _spawn_point_on_edge())
	_add_text("Manifestacao " + MANIFESTATIONS[selected_manifestation]["name"], player_pos + Vector2(0, -80), _manifestation_color(), 1.8, 28)


func _advance_to_phase(phase: int) -> void:
	var rain_should_become_snow = phase == 2 and boss1_rain_active and weather_kind == "rain"
	current_phase = phase
	pending_phase = 0
	mode = "game"
	_play_phase_music()
	phase_transition_timer = 0.0
	phase_fragment.clear()
	player_pos = PLAYER_START
	petro_pos = player_pos + Vector2(-64, 32)
	time_alive = 0.0
	elapsed_unpaused = 0.0
	spawn_timer = 0.0
	last_attack_time = -10.0
	last_skill_time = -10.0
	last_dash_time = -10.0
	last_secondary_time = -999.0
	last_damage_time = -10.0
	boss_parasite_seeds = 0
	boss_parasite_mark_time = 0.0
	retornante_memoria_pending = false
	damage_flash_timer = 0.0
	screen_shake_timer = 0.0
	screen_shake_strength = 0.0
	lacerante_preparing = false
	lacerante_prepare_stage = 0
	lacerante_prepare_frame = 0
	lacerante_prepare_timer = 0.0
	lacerante_prepare_dir = last_facing if last_facing.length() > 0.05 else Vector2.RIGHT
	forced_shop_timer = -1.0
	forced_shop_triggered = false
	next_forced_shop_time = max(0.0, shop_auto_interval - shop_auto_elapsed) if shop_auto_enabled else INF
	boss_ready = true
	boss_call_timer = -1.0
	boss_active = false
	boss_dead = false
	boss_phase = 0.0
	boss_attack_timer = 0.0
	boss_entry_timer = 0.0
	boss_stage_timer = 0.0
	boss_stage_60_done = false
	boss_stage_40_done = false
	boss_attacks.clear()
	boss_transition_waves.clear()
	_reset_boss1_rewind_state()
	boss_empurrou_player = false
	larapio_spawned = false
	next_larapio_spawn_time = LARAPIO_SPAWN_TIME
	alert_stalker_done = false
	alert_projector_done = false
	alert_crystal_done = false
	alert_agglomerator_done = false
	alert_curater_done = false
	event_alert_text = ""
	event_alert_timer = 0.0
	_clear_attack_lock()
	enemies.clear()
	bullets.clear()
	enemy_bullets.clear()
	larapio_coin_drops.clear()
	shockwaves.clear()
	effects.clear()
	heal_orbs.clear()
	slashes.clear()
	anchors.clear()
	prisms.clear()
	orbitals.clear()
	seed_links.clear()
	parasite_spit_zones.clear()
	return_bullets.clear()
	manifestation_secondaries.clear()
	_reset_phase3_state()
	if phase == 1:
		_clear_environment_weather()
	elif rain_should_become_snow:
		_convert_rain_to_snow()
	elif phase != 2:
		_clear_environment_weather()
	if current_phase == 3:
		enemy_base_hp = ENEMY_BASE_HP * 2.45
		enemy_speed_base = ENEMY_BASE_SPEED * 1.12
		boss_hp_max = 8200.0 + score_total * 0.18 + enemies_killed * 14.0
		boss_hp = boss_hp_max
		boss_name = "PAI-RATO"
		boss_title_color = Color(0.72, 0.92, 0.24)
		_spawn_enemy(ENEMY_COMMON, _spawn_point_on_edge())
		_spawn_enemy(ENEMY_DEVOTO, _spawn_point_on_edge())
		_add_text("FASE 3: CATEDRAL DO ESGOTO", player_pos + Vector2(0, -110), boss_title_color, 2.4, 30)
	elif current_phase == 2:
		enemy_base_hp = ENEMY_BASE_HP * 1.85
		enemy_speed_base = ENEMY_BASE_SPEED * 1.08
		boss_hp_max = 5800.0 + score_total * 0.16 + enemies_killed * 12.0
		boss_hp = boss_hp_max
		boss_name = "SENTINELA GLACIAL"
		boss_title_color = Color(0.50, 0.86, 1.0)
		_spawn_enemy(ENEMY_COMMON, _spawn_point_on_edge())
		_spawn_enemy(ENEMY_COMMON, _spawn_point_on_edge())
		_add_text("FASE 2: FENDA GLACIAL", player_pos + Vector2(0, -110), boss_title_color, 2.4, 30)
	else:
		enemy_base_hp = ENEMY_BASE_HP
		enemy_speed_base = ENEMY_BASE_SPEED
		boss_hp_max = BOSS_BASE_HP
		boss_hp = boss_hp_max
		boss_name = "CARANGUEJO COSMICO GIGANTE"
		boss_title_color = Color(1.0, 0.52, 0.16)


func _reset_phase3_state() -> void:
	phase3_miasma_zones.clear()
	phase3_cheeses.clear()
	boss3_faith = 50.0
	boss3_stage = 1
	boss3_stun_timer = 0.0
	boss3_rain_timer = 4.3
	boss3_spit_timer = 4.2
	boss3_tail_timer = 3.2
	boss3_charge_timer = 6.8
	boss3_cheese_timer = BOSS3_CHEESE_INTERVAL
	boss3_dialogue_timer = 8.0
	boss3_events = {}
	boss3_consume_uid = -1
	boss3_consume_timer = 0.0
	boss3_ritual_timer = 0.0
	boss3_ritual_destroyed = 0


func _reset_boss1_rewind_state() -> void:
	boss1_rewind_cooldown = 0.0
	boss1_rewind_history.clear()
	boss1_rewind_sample_timer = 0.0
	boss1_time_wave.clear()
	boss1_rewind_sequence.clear()
	boss1_rewind_visual_projectiles.clear()
	boss1_rewind_vibration_timer = 0.0
	boss1_rewind_clock_tick = -1


func _process(delta: float) -> void:
	_update_orientation(delta)
	_update_music_pause_fade(delta)
	_update_rain_audio_fade(delta)
	if mode == "game":
		_update_game(delta)
	elif mode == "phase_transition":
		_update_phase_transition(delta)
	elif mode == "shop_countdown":
		_update_shop_countdown(delta)
	elif mode == "shop_return":
		_update_shop_return(delta)
	elif mode == "boss_call":
		_update_boss_call(delta)
	elif mode == "pause_countdown":
		_update_pause_countdown(delta)
	elif mode == "shop":
		_update_shop(delta)
	elif mode == "manifest":
		if not manifest_is_dragging:
			var target = float(selected_manifestation)
			var diff = target - manifest_scroll_pos
			var half_size = MANIFESTATIONS.size() / 2.0
			if diff > half_size:
				manifest_scroll_pos += MANIFESTATIONS.size()
			elif diff < -half_size:
				manifest_scroll_pos -= MANIFESTATIONS.size()
			manifest_scroll_pos = lerp(manifest_scroll_pos, target, 12.0 * delta)
			manifest_scroll_pos = _wrap_manifest_scroll(manifest_scroll_pos)
	elif mode == "game_over" or mode == "victory":
		_update_effects(delta)
	queue_redraw()


func _update_orientation(delta: float) -> void:
	orientation_poll_timer -= delta
	if orientation_poll_timer > 0.0:
		return
	orientation_poll_timer = 0.5
	last_manual_orientation = DisplayServer.SCREEN_SENSOR_LANDSCAPE
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)


func _update_game(delta: float) -> void:
	if not boss1_rewind_sequence.is_empty():
		_update_boss1_rewind_sequence(delta)
		return
	_sync_touch_state()
	time_alive += delta
	elapsed_unpaused += delta
	if shop_auto_enabled and not forced_shop_triggered:
		shop_auto_elapsed += delta
		next_forced_shop_time = max(0.0, shop_auto_interval - shop_auto_elapsed)
	screen_shake_timer = max(0.0, screen_shake_timer - delta)
	damage_flash_timer = max(0.0, damage_flash_timer - delta)
	shop_select_pulse_timer = max(0.0, shop_select_pulse_timer - delta)
	if boss_parasite_mark_time > 0.0:
		boss_parasite_mark_time = max(0.0, boss_parasite_mark_time - delta)
		if boss_parasite_mark_time <= 0.0:
			boss_parasite_seeds = 0
	spawn_timer -= delta
	mercenary_hud_pulse = max(0.0, mercenary_hud_pulse - delta)
	collector_hud_pulse = max(0.0, collector_hud_pulse - delta)
	_update_boss2_environment(delta)
	_update_phase3_environment(delta)
	if not boss_ready and time_alive >= BOSS_READY_TIME:
		boss_ready = true
		_add_text("Aperte BOSS quando quiser chamar", player_pos + Vector2(0, -100), Color(1.0, 0.72, 0.20), 2.2, 24)
	if _should_trigger_forced_shop():
		_start_forced_shop_countdown()
		return

	var player_locked = _secondary_player_locked()
	player_stun_timer = max(0.0, player_stun_timer - delta)
	if player_stun_timer <= 0.0 and not player_locked:
		var move = _read_move()
		if move.length() > 0.05:
			last_facing = move.normalized()
			player_pos += last_facing * player_speed * _environment_player_slow_mult() * delta
	player_pos = player_pos.clamp(Vector2(70, 80), WORLD_SIZE - Vector2(70, 80))

	_update_lacerante_prepare(delta)

	_validate_attack_lock()
	if attack_holding and not attack_dragging:
		attack_hold_timer += delta
		if not attack_lock_selecting and attack_hold_timer >= ATTACK_LOCK_HOLD_TIME:
			attack_lock_selecting = true
			attack_lock_candidate_kind = ""
			attack_lock_candidate_uid = -1
			_update_attack_lock_candidate(attack_touch_pos, get_viewport_rect().size)

	if Input.is_key_pressed(KEY_SPACE) or attack_dragging:
		_try_attack()
	if Input.is_key_pressed(KEY_Q):
		_use_skill()
	var secondary_key_pressed = Input.is_key_pressed(KEY_E)
	if secondary_key_pressed and not secondary_key_was_pressed:
		_use_secondary_skill()
	secondary_key_was_pressed = secondary_key_pressed
	if Input.is_key_pressed(KEY_SHIFT):
		_try_dash()
	if Input.is_key_pressed(KEY_ESCAPE):
		_start_pause_countdown()
	if Input.is_key_pressed(KEY_R):
		_start_boss_call()

	if spawn_timer <= 0.0 and not boss_dead:
		_spawn_wave()
	_update_event_alerts(delta)
	_update_agglomeration(delta)
	_try_spawn_larapio()

	_update_phase_fragment(delta)

	_update_bullets(delta)
	_update_parasite_spit_zones(delta)
	_update_prisms(delta)
	_update_return_bullets(delta)
	_update_enemies(delta)
	_update_enemy_bullets(delta)
	_update_larapio_coin_drops(delta)
	_update_orbitals(delta)
	_update_trembo(delta)
	_update_petrov(delta)
	_update_shockwaves(delta)
	_update_manifestation_secondaries(delta)
	_update_heal_orbs(delta)
	_update_effects(delta)
	if boss_active:
		_update_boss(delta)
		_update_boss_poison(delta)
	var active_lacerante = _active_lacerante_secondary()
	if not active_lacerante.is_empty():
		player_pos = Vector2(active_lacerante.get("center", player_pos))
	_update_environment_weather(delta)
	if player_hp <= 0:
		_handle_player_down()
	if mode == "game" and boss_active and current_phase == 1 and boss_entry_timer <= 0.0:
		_record_boss1_rewind_history(delta)


func _read_move() -> Vector2:
	var move = Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move.y += 1
	if move_touch_index != -1 and touch_move.length() > 0.05:
		move = touch_move
	return move.normalized() if move.length() > 1.0 else move


func _try_attack() -> void:
	if _secondary_player_locked():
		return
	if manifestation_key == "lacerante":
		if lacerante_preparing:
			return
		if time_alive - last_attack_time < _current_attack_interval():
			return
		_begin_lacerante_prepare()
		return
	if time_alive - last_attack_time < _current_attack_interval():
		return
	last_attack_time = time_alive

	_play_sfx("Disparo_Geo.wav", 0.04, 0.20)
	match manifestation_key:
		"prismatica":
			_fire_projectile("prismatica", player_damage * 0.60, BULLET_SPEED * 1.35, 1.0, true)
		"retornante":
			_fire_returning()
		"parasitica":
			_fire_projectile("parasitica", player_damage * 0.78, BULLET_SPEED * 0.82, 1.4, false)
		"gravitante":
			_fire_projectile("gravitante", player_damage * 0.52, BULLET_SPEED * 0.72, 1.2, false)
		"ancorada":
			_place_anchor()
			_fire_projectile("ancorada", player_damage * _anchor_bonus(), BULLET_SPEED * 0.95, 1.2, false)
		_:
			eletrica_shot_counter += 1
			var charged = eletrica_shot_counter % 4 == 0
			_fire_projectile("eletrica_charged" if charged else "eletrica", player_damage * (1.28 if charged else 1.0), BULLET_SPEED, 1.2, false)
			if charged:
				_add_text("SOBRECARGA", player_pos + Vector2(0, -88), Color(0.48, 1.0, 1.0), 0.7, 22)


func _fire_projectile(kind: String, damage: float, speed: float, life: float, pierce: bool) -> void:
	if bullets.size() >= MAX_BULLETS:
		return
	var dir = _aim_direction()
	var palette = _projectile_palette(kind)
	var final_damage = damage
	if kind == "ancorada":
		final_damage *= 1.0 + _secondary_ancorada_charge_at_player() * 0.32
	bullets.append({
		"pos": player_pos + dir * 44.0,
		"dir": dir,
		"life": life,
		"max_life": life,
		"age": 0.0,
		"phase": rng.randf_range(0.0, TAU),
		"trail_cd": 0.0,
		"damage": final_damage,
		"speed": speed,
		"kind": kind,
		"pierce": pierce,
		"hits": {},
		"ricochets": 3 if kind == "prismatica" else 0,
		"durability": 100.0 if kind == "prismatica" else 0.0,
		"color": palette["glow"]
	})
	_spawn_projectile_muzzle(kind, player_pos + dir * 34.0, dir)


func _fire_returning() -> void:
	if return_bullets.size() >= 8:
		return
	var dir = _aim_direction()
	var bullet = {
		"pos": player_pos + dir * 44.0,
		"dir": dir,
		"age": 0.0,
		"phase": rng.randf_range(0.0, TAU),
		"trail_cd": 0.0,
		"state": "ida",
		"returning": false,
		"damage": player_damage * 0.62,
		"hits": {},
		"memory_bonus": 1.0,
		"memory_impacts": 0,
		"memory_until": 0.0,
		"memory_seek_cd": 0.0,
		"memory_last_uid": -1,
		"memory_last_hit_time": -999.0,
		"memory_hit_times": {},
		"forced": false
	}
	return_bullets.append(bullet)
	if retornante_memoria_pending:
		retornante_memoria_pending = false
		_activate_retornante_memory(bullet)


func _begin_lacerante_prepare() -> void:
	var attack_dir = _aim_direction()
	if attack_dir.length() <= 0.05:
		attack_dir = last_facing.normalized()
	lacerante_prepare_stage = posmod(int(lacerante_combo), 3)
	lacerante_prepare_frame = 0
	lacerante_prepare_timer = 0.0
	lacerante_prepare_dir = attack_dir
	lacerante_preparing = true


func _update_lacerante_prepare(delta: float) -> void:
	if not lacerante_preparing:
		return
	lacerante_prepare_timer += delta
	while lacerante_prepare_timer >= PLAYER_ATTACK_PREP_FRAME_TIME:
		lacerante_prepare_timer -= PLAYER_ATTACK_PREP_FRAME_TIME
		lacerante_prepare_frame += 1
		if lacerante_prepare_frame >= 2:
			_fire_lacerante(lacerante_prepare_stage, lacerante_prepare_dir)
			lacerante_preparing = false
			lacerante_prepare_frame = 0
			lacerante_prepare_timer = 0.0
			break


func _fire_lacerante(stage: int, dir: Vector2) -> void:
	var slash_stage = posmod(int(stage), 3)
	var attack_dir = dir.normalized()
	if attack_dir.length() <= 0.05:
		attack_dir = _aim_direction()
	if attack_dir.length() <= 0.05:
		attack_dir = last_facing.normalized()
	last_attack_time = time_alive

	_play_sfx("Disparo_Geo.wav", 0.04, 0.20)
	lacerante_combo_visual = slash_stage
	lacerante_combo = (slash_stage + 1) % 3
	var points = _lacerante_stage_points(player_pos, attack_dir, slash_stage)
	var width = 52.0
	slashes.append({
		"points": points,
		"life": 0.20,
		"max": 0.20,
		"color": _manifestation_color(),
		"width": width,
		"stage": slash_stage
	})
	_spawn_radial_particles(player_pos + attack_dir * 80.0, Color(1.0, 0.08, 0.14), 8)
	for enemy in enemies:
		if _distance_to_polyline(enemy["pos"], points) <= width:
			var killed = _damage_enemy(enemy, player_damage * 1.12, "lacerante")
			enemy["laceracao"] = int(enemy.get("laceracao", 0)) + 1
			enemy["bleed_timer"] = 4.0
			if slash_stage == 2 and killed:
				last_secondary_time -= 1.5
	for cheese in phase3_cheeses:
		if _distance_to_polyline(Vector2(cheese["pos"]), points) <= width:
			_damage_phase3_cheeses_at(Vector2(cheese["pos"]), player_damage * 1.12, 4.0)
	if boss_active and boss_hp > 0.0 and _distance_to_polyline(boss_pos, points) <= width + 32.0:
		_damage_boss(player_damage * 1.12, "lacerante")


func _place_anchor() -> void:
	anchors.append({"pos": player_pos, "life": 9.0})
	if anchors.size() > 5:
		anchors.pop_front()


func _aim_direction() -> Vector2:
	if lacerante_preparing and lacerante_prepare_dir.length() > 0.05:
		return lacerante_prepare_dir.normalized()
	if attack_dragging and attack_drag_direction.length() > 0.05:
		return attack_drag_direction.normalized()
	var target = _nearest_target()
	if target != Vector2.ZERO:
		return (target - player_pos).normalized()
	return last_facing.normalized() if last_facing.length() > 0.05 else Vector2.RIGHT


func _nearest_target() -> Vector2:
	var locked_pos = _locked_attack_target_pos()
	if locked_pos != Vector2.ZERO:
		return locked_pos
	var best_enemy = _auto_target_enemy()
	if not best_enemy.is_empty():
		if auto_target_priority == "nearest" and boss_active and boss_hp > 0.0:
			var enemy_distance = player_pos.distance_squared_to(best_enemy["pos"])
			if _pos_in_auto_attack_range(boss_pos) and player_pos.distance_squared_to(boss_pos) < enemy_distance:
				return boss_pos
		return best_enemy["pos"]
	if boss_active and boss_hp > 0.0 and _pos_in_auto_attack_range(boss_pos):
		return boss_pos
	return Vector2.ZERO


func _locked_attack_target_pos() -> Vector2:
	if locked_target_kind == "enemy":
		var enemy = _enemy_by_uid(locked_target_uid)
		if enemy:
			return Vector2(enemy["pos"])
	elif locked_target_kind == "boss" and boss_active and boss_hp > 0.0:
		return boss_pos
	elif locked_target_kind == "cheese":
		var cheese = _boss3_cheese_by_uid(locked_target_uid)
		if not cheese.is_empty():
			return Vector2(cheese["pos"])
	return Vector2.ZERO


func _validate_attack_lock() -> void:
	if locked_target_kind == "enemy" and not _enemy_by_uid(locked_target_uid):
		_clear_attack_lock()
	elif locked_target_kind == "boss" and (not boss_active or boss_hp <= 0.0):
		_clear_attack_lock()
	elif locked_target_kind == "cheese" and _boss3_cheese_by_uid(locked_target_uid).is_empty():
		_clear_attack_lock()


func _clear_attack_lock() -> void:
	locked_target_kind = ""
	locked_target_uid = -1


func _update_attack_lock_candidate(touch_pos: Vector2, viewport: Vector2) -> void:
	attack_touch_pos = touch_pos
	attack_lock_candidate_kind = ""
	attack_lock_candidate_uid = -1
	var drag = touch_pos - attack_drag_start_pos
	if drag.length() < ATTACK_LOCK_MIN_DRAG:
		return
	var direction = drag.normalized()
	var camera = _camera(viewport)
	var visible_rect = Rect2(Vector2.ZERO, viewport).grow(42.0)
	var best_score = INF
	for enemy in enemies:
		var enemy_screen = Vector2(enemy["pos"]) - camera
		if not visible_rect.has_point(enemy_screen):
			continue
		var to_enemy = Vector2(enemy["pos"]) - player_pos
		if to_enemy.length_squared() <= 1.0:
			continue
		var alignment = direction.dot(to_enemy.normalized())
		if alignment < ATTACK_LOCK_CONE_COS:
			continue
		var score = (1.0 - alignment) * 1000.0 + to_enemy.length() * 0.01
		if score < best_score:
			best_score = score
			attack_lock_candidate_kind = "enemy"
			attack_lock_candidate_uid = int(enemy["uid"])
	if boss_active and boss_hp > 0.0:
		var boss_screen = boss_pos - camera
		var to_boss = boss_pos - player_pos
		if visible_rect.has_point(boss_screen) and to_boss.length_squared() > 1.0:
			var alignment = direction.dot(to_boss.normalized())
			if alignment >= ATTACK_LOCK_CONE_COS:
				var score = (1.0 - alignment) * 1000.0 + to_boss.length() * 0.01
				if score < best_score:
					attack_lock_candidate_kind = "boss"
					attack_lock_candidate_uid = -1
	for cheese in phase3_cheeses:
		var cheese_screen = Vector2(cheese["pos"]) - camera
		var to_cheese = Vector2(cheese["pos"]) - player_pos
		if not visible_rect.has_point(cheese_screen) or to_cheese.length_squared() <= 1.0:
			continue
		var alignment = direction.dot(to_cheese.normalized())
		if alignment < ATTACK_LOCK_CONE_COS:
			continue
		var score = (1.0 - alignment) * 1000.0 + to_cheese.length() * 0.01
		if score < best_score:
			best_score = score
			attack_lock_candidate_kind = "cheese"
			attack_lock_candidate_uid = int(cheese["uid"])


func _commit_attack_lock() -> void:
	if attack_lock_candidate_kind.is_empty():
		var had_lock = not locked_target_kind.is_empty()
		_clear_attack_lock()
		if had_lock:
			_add_text("MIRA LIVRE", player_pos + Vector2(0, -88), Color(0.82, 0.88, 0.94), 0.75, 18)
		return
	locked_target_kind = attack_lock_candidate_kind
	locked_target_uid = attack_lock_candidate_uid
	_vibrate(45, 0.24)
	var target_pos = _locked_attack_target_pos()
	if target_pos != Vector2.ZERO:
		_add_text("ALVO TRAVADO", target_pos + Vector2(0, -72), Color(1.0, 0.88, 0.22), 0.75, 18)


func _attack_target_is_enemy(uid: int) -> bool:
	if attack_lock_selecting:
		return attack_lock_candidate_kind == "enemy" and attack_lock_candidate_uid == uid
	return locked_target_kind == "enemy" and locked_target_uid == uid


func _attack_target_is_boss() -> bool:
	if attack_lock_selecting:
		return attack_lock_candidate_kind == "boss"
	return locked_target_kind == "boss"


func _auto_target_enemy() -> Dictionary:
	var best = {}
	var best_metric = INF
	var best_distance = INF
	for enemy in enemies:
		var distance = player_pos.distance_squared_to(enemy["pos"])
		if distance > _auto_attack_range_squared():
			continue
		var metric = distance
		match auto_target_priority:
			"max_hp_low":
				metric = float(enemy.get("max_hp", INF)) + sqrt(distance) * 0.018
			"hp_low":
				metric = float(enemy.get("hp", INF)) + sqrt(distance) * 0.018
		if metric < best_metric or (is_equal_approx(metric, best_metric) and distance < best_distance):
			best_metric = metric
			best_distance = distance
			best = enemy
	return best


func _auto_attack_range() -> float:
	match manifestation_key:
		"lacerante":
			return 260.0
		"gravitante":
			return BULLET_SPEED * 0.72 * 1.2
		"prismatica":
			return BULLET_SPEED * 1.35 * 1.0
		"parasitica":
			return BULLET_SPEED * 0.82 * 1.4
		"ancorada":
			return BULLET_SPEED * 0.95 * 1.2
	return BULLET_SPEED * 1.2


func _auto_attack_range_squared() -> float:
	var range = _auto_attack_range()
	return range * range


func _pos_in_auto_attack_range(pos: Vector2) -> bool:
	return player_pos.distance_squared_to(pos) <= _auto_attack_range_squared()


func _use_skill(target_world = null) -> void:
	if _secondary_player_locked():
		return
	if effects.any(func(e): return e.get("skill_lock", false)):
		return
	var cooldown = _skill_cooldown()
	if time_alive - last_skill_time < cooldown:
		var remaining = cooldown - (time_alive - last_skill_time)
		_add_text("%.1fs" % remaining, player_pos + Vector2(0, -86), Color(0.72, 0.92, 1.0), 0.45, 18)
		return
	last_skill_time = time_alive
	match manifestation_key:
		"lacerante":
			var radius = 128.0
			var points = _circle_polyline_points(player_pos, radius, 28)
			slashes.append({
				"points": points,
				"life": 0.38,
				"max": 0.38,
				"color": Color(1.0, 0.02, 0.08),
				"width": 86.0,
				"stage": 99
			})
			for enemy in enemies:
				if enemy["pos"].distance_to(player_pos) <= radius + _enemy_radius(enemy) + 18.0:
					_damage_enemy(enemy, float(enemy.get("max_hp", 1.0)) * 0.05 + player_damage, "lacerante")
			if boss_active and boss_hp > 0.0 and boss_pos.distance_to(player_pos) <= radius + 72.0:
				_damage_boss(boss_hp_max * 0.05 + player_damage, "lacerante")
			_add_text("CIRCULO LACERANTE", player_pos + Vector2(0, -90), Color(1.0, 0.20, 0.28), 1.1, 24)
		"parasitica":
			_spawn_parasite_spit(target_world)
		"gravitante":
			for i in range(3):
				var target = _nearest_enemy_dict()
				if target:
					orbitals.append({"enemy_uid": target["uid"], "angle": i * TAU / 3.0, "life": 5.0, "tick": 0.0, "damage": player_damage * 0.24})
			_add_text("COLAPSO ORBITAL", player_pos + Vector2(0, -90), Color(0.60, 0.82, 1.0), 1.3, 25)
		"ancorada":
			shockwaves.append({"pos": player_pos, "radius": 0.0, "max": 270.0, "life": 0.55, "damage": player_damage * 1.25, "hit": {}})
		"prismatica":
			var prism_pos = Vector2(target_world) if target_world is Vector2 else player_pos
			prisms.append({
				"pos": prism_pos,
				"life": 6.2,
				"max_life": 6.2,
				"damage_tick": 0.0
			})
			_add_text("PRISMA DE REFRACAO", prism_pos + Vector2(0, -70), Color(0.32, 1.0, 0.96), 1.3, 25)
		"retornante":
			var chosen = _choose_retornante_memory_bullet()
			if chosen.is_empty():
				retornante_memoria_pending = true
				_add_text("MEMORIA RESERVADA", player_pos + Vector2(0, -90), Color(0.86, 0.58, 1.0), 1.2, 24)
			else:
				_activate_retornante_memory(chosen)
				_add_text("MEMORIA INSTAVEL", Vector2(chosen.get("pos", player_pos)) + Vector2(0, -52), Color(1.0, 0.44, 0.80), 1.2, 24)
		_:
			shockwaves.append({"pos": player_pos, "radius": 0.0, "max": 250.0, "life": 0.45, "damage": player_damage * 1.05, "hit": {}})
	_spawn_radial_particles(player_pos, _manifestation_color(), 22)
	effects.append({"pos": player_pos, "text": "", "life": 0.25, "max": 0.25, "color": Color.WHITE, "size": 1, "skill_lock": true})


func _retornante_memory_target_point() -> Vector2:
	if attack_dragging and attack_drag_direction.length() > 0.05:
		return player_pos + attack_drag_direction.normalized() * 320.0
	var nearest = _nearest_target()
	if nearest != Vector2.ZERO:
		return nearest
	return player_pos + last_facing.normalized() * 240.0


func _choose_retornante_memory_bullet() -> Dictionary:
	var target = _retornante_memory_target_point()
	var best = {}
	var best_d = INF
	for bullet in return_bullets:
		if bool(bullet.get("expired", false)):
			continue
		if String(bullet.get("state", "ida")) == "instavel":
			continue
		var d = Vector2(bullet.get("pos", player_pos)).distance_squared_to(target)
		if d < best_d:
			best_d = d
			best = bullet
	return best


func _activate_retornante_memory(bullet: Dictionary) -> void:
	bullet["state"] = "instavel"
	bullet["returning"] = false
	bullet["memory_until"] = time_alive + 4.0
	bullet["memory_impacts"] = 0
	bullet["memory_seek_cd"] = 0.0
	bullet["memory_last_uid"] = -1
	bullet["memory_last_hit_time"] = -999.0
	bullet["memory_hit_times"] = {}
	bullet["forced"] = false


func _active_lacerante_secondary() -> Dictionary:
	for secondary in manifestation_secondaries:
		if String(secondary.get("kind", "")) == "lacerante" and bool(secondary.get("lock_player", false)) and float(secondary.get("life", 0.0)) > 0.0:
			return secondary
	return {}

func _active_prismatica_secondary() -> Dictionary:
	for sec in manifestation_secondaries:
		if String(sec.get("kind", "")) == "prismatica" and float(sec.get("life", 0.0)) > 0.0:
			return sec
	return {}


func _active_eletrica_secondary() -> Dictionary:
	for sec in manifestation_secondaries:
		if String(sec.get("kind", "")) == "eletrica" and float(sec.get("life", 0.0)) > 0.0:
			return sec
	return {}


func _secondary_player_locked() -> bool:
	return not _active_lacerante_secondary().is_empty() or not _active_prismatica_secondary().is_empty()


func _player_invulnerable() -> bool:
	return trembo_invulnerability > 0.0 or not _active_lacerante_secondary().is_empty() or not _active_prismatica_secondary().is_empty()


func _secondary_skill_cooldown() -> float:
	return SECONDARY_SKILL_COOLDOWN


func _use_secondary_skill(target_world = null) -> void:
	var active_eletrica = _active_eletrica_secondary()
	if manifestation_key == "eletrica" and not active_eletrica.is_empty():
		_finish_toggle_secondary(active_eletrica, "ANEL CANCELADO", Color(0.52, 0.88, 1.0))
		return
	var active_prismatica = _active_prismatica_secondary()
	if manifestation_key == "prismatica" and not active_prismatica.is_empty():
		_finish_toggle_secondary(active_prismatica, "COROA CANCELADA", Color(0.64, 1.0, 0.96), false)
		return
	if _secondary_player_locked():
		return
	var cooldown = _secondary_skill_cooldown()
	if time_alive - last_secondary_time < cooldown:
		var remaining = cooldown - (time_alive - last_secondary_time)
		_add_text("%.1fs" % remaining, player_pos + Vector2(0, -110), Color(1.0, 0.84, 0.40), 0.55, 18)
		return
	match manifestation_key:
		"lacerante":
			last_secondary_time = time_alive
			_spawn_secondary_lacerante()
		"eletrica":
			_spawn_secondary_eletrica()
		"prismatica":
			last_secondary_time = time_alive
			_spawn_secondary_prismatica()
		"retornante":
			last_secondary_time = time_alive
			_spawn_secondary_retornante()
		"parasitica":
			if _has_parasite_ultimate_targets():
				last_secondary_time = time_alive
				_spawn_secondary_parasitica()
			else:
				_add_text("NENHUM ALVO COM LARVAS", player_pos + Vector2(0, -110), Color(0.72, 1.0, 0.42), 1.0, 19)
		"gravitante":
			last_secondary_time = time_alive
			_spawn_secondary_gravitante(target_world)
		"ancorada":
			last_secondary_time = time_alive
			_spawn_secondary_ancorada(target_world)
		_:
			_add_text("2A HABILIDADE EM PREPARO", player_pos + Vector2(0, -110), Color(1.0, 0.82, 0.32), 0.9, 18)


func _finish_toggle_secondary(secondary: Dictionary, message: String, color: Color, start_cooldown := true) -> void:
	if bool(secondary.get("cooldown_started", false)):
		return
	secondary["life"] = 0.0
	secondary["cooldown_started"] = true
	if start_cooldown:
		last_secondary_time = time_alive
	_add_text(message, player_pos + Vector2(0, -108), color, 0.85, 19)
	_spawn_radial_particles(player_pos, color, 18)


func _spawn_secondary_eletrica() -> void:
	manifestation_secondaries.append({
		"kind": "eletrica",
		"life": 1.0,
		"max": 1.0,
		"tick": 0.0,
		"active_time": 0.0,
		"empty_time": 0.0,
		"health_drain_timer": 0.0,
		"health_drain_carry": 0.0,
		"cooldown_started": false,
		"bonus_step": 0,
		"seed": rng.randi()
	})
	_add_text("ANEL DE TESLA", player_pos + Vector2(0, -110), Color(0.52, 1.0, 1.0), 1.4, 28)
	_spawn_radial_particles(player_pos, Color(0.38, 0.96, 1.0), 30)


func _spawn_parasite_spit(target_world = null) -> void:
	var target: Vector2
	if target_world is Vector2:
		target = Vector2(target_world)
	else:
		var direction = _aim_direction()
		if direction.length() <= 0.05:
			direction = last_facing.normalized()
		target = player_pos + direction * 285.0
	target = target.clamp(Vector2(PARASITE_SPIT_RADIUS, PARASITE_SPIT_RADIUS), WORLD_SIZE - Vector2(PARASITE_SPIT_RADIUS, PARASITE_SPIT_RADIUS))
	parasite_spit_zones.append({
		"state": "flying",
		"origin": player_pos,
		"target": target,
		"age": 0.0,
		"travel": PARASITE_SPIT_TRAVEL,
		"life": PARASITE_SPIT_DURATION,
		"max": PARASITE_SPIT_DURATION,
		"tick": 0.0,
		"phase": rng.randf_range(0.0, TAU),
		"infected": {}
	})
	_add_text("CUSPE INFESTANTE", player_pos + Vector2(0, -92), Color(0.68, 1.0, 0.34), 1.0, 22)


func _update_parasite_spit_zones(delta: float) -> void:
	for zone in parasite_spit_zones:
		if String(zone.get("state", "flying")) == "flying":
			zone["age"] = float(zone.get("age", 0.0)) + delta
			if float(zone["age"]) >= float(zone.get("travel", PARASITE_SPIT_TRAVEL)):
				zone["state"] = "active"
				zone["age"] = 0.0
				zone["tick"] = 0.0
				_spawn_radial_particles(Vector2(zone["target"]), Color(0.58, 0.90, 0.20), 26)
			continue
		zone["life"] = max(0.0, float(zone.get("life", 0.0)) - delta)
		zone["tick"] = float(zone.get("tick", 0.0)) - delta
		if float(zone["tick"]) > 0.0:
			continue
		zone["tick"] = 0.55
		var center = Vector2(zone["target"])
		var infected = Dictionary(zone.get("infected", {}))
		for enemy in enemies:
			if float(enemy.get("hp", 0.0)) <= 0.0 or Vector2(enemy["pos"]).distance_to(center) > PARASITE_SPIT_RADIUS + _enemy_radius(enemy) * 0.35:
				continue
			enemy["seeds"] = min(5, int(enemy.get("seeds", 0)) + 1)
			enemy["parasite_mark_time"] = PARASITE_MARK_DURATION
			_damage_enemy(enemy, player_damage * 0.42, "parasitica", false)
			var uid = str(enemy["uid"])
			if not infected.has(uid):
				infected[uid] = true
				_add_text("CONTAMINADO", Vector2(enemy["pos"]) + Vector2(0, -64), Color(0.72, 1.0, 0.34), 0.8, 16)
		if boss_active and boss_hp > 0.0 and boss_pos.distance_to(center) <= PARASITE_SPIT_RADIUS + 68.0:
			boss_parasite_seeds = min(5, boss_parasite_seeds + 1)
			boss_parasite_mark_time = PARASITE_MARK_DURATION
			_damage_boss(player_damage * 0.34, "parasitica")
		zone["infected"] = infected
	parasite_spit_zones = parasite_spit_zones.filter(func(zone): return String(zone.get("state", "")) == "flying" or float(zone.get("life", 0.0)) > 0.0)


func _spawn_secondary_lacerante() -> void:
	var center = player_pos + _aim_direction() * 170.0
	center = center.clamp(Vector2(120, 120), WORLD_SIZE - Vector2(120, 120))
	player_pos = center
	manifestation_secondaries.append({
		"kind": "lacerante",
		"life": SECONDARY_LACERANTE_DURATION,
		"max": SECONDARY_LACERANTE_DURATION,
		"center": center,
		"cut_timer": 0.0,
		"cuts": [],
		"cut_index": 0,
		"max_cuts": 15,
		"lock_player": true,
		"seed": rng.randi()
	})
	_add_text("CARNIFICINA TEMPORAL", center + Vector2(0, -118), Color(1.0, 0.18, 0.28), 1.6, 28)
	_spawn_radial_particles(center, Color(1.0, 0.12, 0.18), 36)


func _spawn_secondary_prismatica() -> void:
	manifestation_secondaries.append({
		"kind": "prismatica",
		"life": SECONDARY_PRISMATICA_DURATION,
		"max": SECONDARY_PRISMATICA_DURATION,
		"center": player_pos,
		"tick": 0.0,
		"angle": 0.0,
		"spin_hit_times": {},
		"boss_spin_hit": -999.0,
		"cooldown_started": false
	})
	_add_text("COROA ESPECTRAL", player_pos + Vector2(0, -110), Color(0.52, 1.0, 0.96), 1.4, 28)
	_spawn_radial_particles(player_pos, Color(0.74, 1.0, 1.0), 34)


func _spawn_secondary_retornante() -> void:
	manifestation_secondaries.append({
		"kind": "retornante",
		"life": SECONDARY_RETORNANTE_DURATION,
		"max": SECONDARY_RETORNANTE_DURATION,
		"line_tick": 0.0,
		"ghost_tick": 0.0,
		"ghosts": [],
		"marked": false,
		"forced_final": false
	})
	_add_text("PARADOXO DE RETORNO", player_pos + Vector2(0, -110), Color(0.74, 0.55, 1.0), 1.4, 28)
	_spawn_radial_particles(player_pos, Color(0.88, 0.52, 1.0), 28)


func _spawn_secondary_parasitica() -> void:
	var targets = []
	var target_index = 0
	for enemy in enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0 or float(enemy.get("parasite_mark_time", 0.0)) <= 0.0:
			continue
		targets.append(_make_parasite_ultimate_target(int(enemy["uid"]), false, Vector2(enemy["pos"]), target_index))
		enemy["parasite_mark_time"] = 0.0
		enemy["seeds"] = 0
		target_index += 1
	if boss_active and boss_hp > 0.0 and boss_parasite_mark_time > 0.0:
		targets.append(_make_parasite_ultimate_target(-1, true, boss_pos, target_index))
		boss_parasite_mark_time = 0.0
		boss_parasite_seeds = 0
	manifestation_secondaries.append({
		"kind": "parasitica",
		"life": PARASITE_ULTIMATE_MAX_DURATION,
		"max": PARASITE_ULTIMATE_MAX_DURATION,
		"targets": targets,
		"seed": rng.randi()
	})
	_add_text("ENXAME SUBTERRANEO x%d" % targets.size(), player_pos + Vector2(0, -110), Color(0.68, 1.0, 0.46), 1.6, 28)
	_spawn_radial_particles(player_pos, Color(0.44, 1.0, 0.42), 36)


func _has_parasite_ultimate_targets() -> bool:
	for enemy in enemies:
		if float(enemy.get("hp", 0.0)) > 0.0 and float(enemy.get("parasite_mark_time", 0.0)) > 0.0:
			return true
	return boss_active and boss_hp > 0.0 and boss_parasite_mark_time > 0.0


func _make_parasite_ultimate_target(uid: int, is_boss: bool, target_pos: Vector2, target_index: int) -> Dictionary:
	var viewport = get_viewport_rect().size
	var camera = _camera(viewport)
	var worms = []
	for worm_index in range(3):
		var edge = posmod(target_index + worm_index + rng.randi_range(0, 3), 4)
		var start_screen = Vector2.ZERO
		match edge:
			0:
				start_screen = Vector2(-34.0, rng.randf_range(54.0, viewport.y - 54.0))
			1:
				start_screen = Vector2(viewport.x + 34.0, rng.randf_range(54.0, viewport.y - 54.0))
			2:
				start_screen = Vector2(rng.randf_range(54.0, viewport.x - 54.0), -34.0)
			_:
				start_screen = Vector2(rng.randf_range(54.0, viewport.x - 54.0), viewport.y + 34.0)
		var start_world = camera + start_screen
		var distance = start_world.distance_to(target_pos)
		worms.append({
			"start": start_world,
			"delay": worm_index * 0.14 + rng.randf_range(0.0, 0.10),
			"duration": clamp(0.82 + distance / 1050.0 + worm_index * 0.08, 0.95, 1.65),
			"bend": rng.randf_range(-150.0, 150.0),
			"phase": rng.randf_range(0.0, TAU),
			"scale": rng.randf_range(0.88, 1.14)
		})
	return {
		"uid": uid,
		"boss": is_boss,
		"age": 0.0,
		"arrival": 1.95,
		"arrived": false,
		"feed_left": PARASITE_FEAST_DURATION,
		"tick": 1.0,
		"worms": worms,
		"seed": rng.randi(),
		"done": false
	}


func _spawn_secondary_gravitante(target_world = null) -> void:
	var center = Vector2(target_world) if target_world is Vector2 else player_pos
	manifestation_secondaries.append({
		"kind": "gravitante",
		"life": SECONDARY_GRAVITANTE_DURATION,
		"max": SECONDARY_GRAVITANTE_DURATION,
		"center": center,
		"pulse_tick": 0.0,
		"captured": 0,
		"orbital_bonus": 0,
		"finalized": false
	})
	_add_text("COLAPSO ORBITAL", center + Vector2(0, -110), Color(0.60, 0.82, 1.0), 1.4, 28)
	_spawn_radial_particles(center, Color(0.58, 0.80, 1.0), 30)


func _spawn_secondary_ancorada(target_world = null) -> void:
	var center = Vector2(target_world) if target_world is Vector2 else player_pos
	manifestation_secondaries.append({
		"kind": "ancorada",
		"life": SECONDARY_ANCORADA_DURATION,
		"max": SECONDARY_ANCORADA_DURATION,
		"center": center,
		"charge": 0.0,
		"pulse_tick": 0.0,
		"final_wave": false
	})
	_add_text("DOMINIO FIXO", center + Vector2(0, -110), Color(0.42, 0.92, 1.0), 1.4, 28)
	_spawn_radial_particles(center, Color(0.42, 0.92, 1.0), 32)


func _try_dash() -> void:
	if _secondary_player_locked():
		return
	if time_alive - last_dash_time < player_dash_cooldown:
		return
	var dir = _read_move()
	if dir.length() <= 0.05:
		dir = last_facing
	_execute_teleport(player_pos + dir.normalized() * PLAYER_DASH_DISTANCE)


func _try_dash_to_screen(screen_pos: Vector2, viewport: Vector2) -> void:
	if _secondary_player_locked():
		return
	if time_alive - last_dash_time < player_dash_cooldown:
		var remaining = player_dash_cooldown - (time_alive - last_dash_time)
		_add_text("%.1fs" % remaining, player_pos + Vector2(0, -62), Color(0.35, 0.95, 1.0), 0.45, 18)
		return
	_execute_teleport(_teleport_destination_from_drag(screen_pos, viewport))


func _teleport_destination_from_drag(screen_pos: Vector2, viewport: Vector2) -> Vector2:
	var drag = screen_pos - _dash_center(viewport)
	var dir = drag.normalized()
	if drag.length() <= 8.0:
		dir = last_facing.normalized()
	var strength = clamp(drag.length() / 64.0, 0.46, 1.0)
	return player_pos + dir * PLAYER_DASH_DISTANCE * strength


func _ground_target_profile(secondary: bool) -> Dictionary:
	if secondary:
		match manifestation_key:
			"gravitante":
				return {"range": 560.0, "radius": 330.0, "default": 0.0, "minimum": 90.0, "color": Color(0.46, 0.78, 1.0)}
			"ancorada":
				return {"range": 500.0, "radius": 220.0, "default": 0.0, "minimum": 80.0, "color": Color(0.30, 0.88, 1.0)}
	else:
		match manifestation_key:
			"parasitica":
				return {"range": 520.0, "radius": PARASITE_SPIT_RADIUS, "default": 285.0, "minimum": 110.0, "color": Color(0.58, 0.92, 0.20)}
			"prismatica":
				return {"range": 480.0, "radius": 58.0, "default": 180.0, "minimum": 90.0, "color": Color(0.32, 1.0, 0.96)}
	return {}


func _ground_target_world(screen_pos: Vector2, viewport: Vector2, secondary: bool) -> Vector2:
	var profile = _ground_target_profile(secondary)
	if profile.is_empty():
		return player_pos
	var origin_screen = _secondary_center(viewport) if secondary else buttons["skill"].get_center()
	var drag = screen_pos - origin_screen
	var direction = drag.normalized()
	var distance = float(profile["default"])
	if drag.length() > ABILITY_TARGET_DRAG_DEADZONE:
		var strength = clamp((drag.length() - ABILITY_TARGET_DRAG_DEADZONE) / (ABILITY_TARGET_FULL_DRAG - ABILITY_TARGET_DRAG_DEADZONE), 0.0, 1.0)
		distance = lerp(float(profile["minimum"]), float(profile["range"]), strength)
	else:
		direction = _aim_direction()
		if direction.length() <= 0.05:
			direction = last_facing.normalized()
	if direction.length() <= 0.05 or distance <= 0.0:
		return player_pos
	var margin = min(180.0, float(profile["radius"]))
	return (player_pos + direction * distance).clamp(Vector2(margin, margin), WORLD_SIZE - Vector2(margin, margin))


func _execute_teleport(target_world: Vector2) -> void:
	last_dash_time = time_alive
	var origin = player_pos
	player_pos = target_world.clamp(Vector2(70, 80), WORLD_SIZE - Vector2(70, 80))
	var dash_color = _manifestation_color()
	slashes.append({"a": origin, "b": player_pos, "life": 0.32, "max": 0.32, "color": dash_color, "width": 38.0})
	_spawn_radial_particles(origin, dash_color, 12)
	_spawn_radial_particles(player_pos, dash_color, 18)
	if manifestation_key == "lacerante":
		for enemy in enemies:
			if _distance_to_segment(enemy["pos"], origin, player_pos) <= 48.0:
				_damage_enemy(enemy, player_damage * 0.45, manifestation_key)
				enemy["laceracao"] = int(enemy.get("laceracao", 0)) + 1
	elif manifestation_key == "retornante":
		var recalled = 0
		for bullet in return_bullets:
			var state = String(bullet.get("state", "ida"))
			if state != "volta" and state != "instavel":
				bullet["state"] = "volta"
				bullet["returning"] = true
				bullet["forced"] = true
				bullet["damage"] = float(bullet["damage"]) * 1.18
				recalled += 1
		if recalled > 0:
			_add_text("RETORNO x%d" % recalled, player_pos + Vector2(0, -74), Color(0.74, 0.56, 1.0), 0.7, 20)


func _spawn_wave() -> void:
	spawn_timer = _enemy_spawn_interval()
	if boss_active:
		return
	var limit = _enemy_limit()
	if enemies.size() >= limit:
		return
	var kind = _choose_enemy_type()
	_spawn_enemy(kind, _spawn_point_for_type(kind))


func _choose_enemy_type() -> String:
	if current_phase == 3:
		var r3 = rng.randf()
		if r3 <= 0.06 and _enemy_type_count(ENEMY_GUARDIAO) < 2:
			return ENEMY_GUARDIAO
		if r3 <= 0.15 and _enemy_type_count(ENEMY_INCENSARIO) < 2:
			return ENEMY_INCENSARIO
		if r3 <= 0.33 and _enemy_type_count(ENEMY_DEVOTO) < 3:
			return ENEMY_DEVOTO
		return ENEMY_COMMON
	if current_phase == 2:
		var r2 = rng.randf()
		if r2 < 0.50: return ENEMY_COMMON
		elif r2 < 0.80: return ENEMY_ATIRADOR
		else: return ENEMY_KAMIKAZE
	var roll = rng.randf()
	if time_alive >= ANOMALIA_CURATER_TIME:
		if roll < 0.08:
			return ENEMY_CURATER
		if roll < 0.53:
			return ENEMY_COMMON
		if roll < 0.69:
			return ENEMY_STALKER
		if roll < 0.83:
			return ENEMY_PROJECTOR
		if not _has_enemy_type(ENEMY_CRYSTAL) and roll < 0.93:
			return ENEMY_CRYSTAL
		return ENEMY_COMMON
	if time_alive >= ANOMALIA_CRISTALIZADOR_TIME:
		if roll < 0.58:
			return ENEMY_COMMON
		if roll < 0.76:
			return ENEMY_STALKER
		if roll < 0.91:
			return ENEMY_PROJECTOR
		if not _has_enemy_type(ENEMY_CRYSTAL):
			return ENEMY_CRYSTAL
		return ENEMY_COMMON
	if time_alive >= ANOMALIA_PROJETADOR_TIME:
		if roll < 0.66:
			return ENEMY_COMMON
		if roll < 0.86:
			return ENEMY_STALKER
		return ENEMY_PROJECTOR
	if time_alive >= ANOMALIA_ESPREITADOR_TIME and roll < 0.24:
		return ENEMY_STALKER
	return ENEMY_COMMON


func _enemy_limit() -> int:
	if current_phase == 3:
		return 7
	if current_phase == 2:
		return 5
	var extra = 0
	if time_alive >= ENEMY_RAMP_START_TIME:
		var ramp_window = max(0.0, ENEMY_RAMP_PEAK_TIME - ENEMY_RAMP_START_TIME)
		var elapsed_ramp = min(time_alive - ENEMY_RAMP_START_TIME, ramp_window)
		extra = int(floor(elapsed_ramp / ENEMY_LIMIT_STEP_TIME))
	return ENEMY_MAX_BASE + extra


func _enemy_spawn_interval() -> float:
	var interval = ENEMY_SPAWN_INTERVAL
	if current_phase != 2:
		var ramp_window = max(1.0, ENEMY_RAMP_PEAK_TIME - ENEMY_RAMP_START_TIME)
		var progress = clamp((time_alive - ENEMY_RAMP_START_TIME) / ramp_window, 0.0, 1.0)
		interval = lerp(ENEMY_SPAWN_INTERVAL_EARLY, ENEMY_SPAWN_INTERVAL_LATE, progress)
	if not _active_prismatica_secondary().is_empty():
		interval *= 0.5
	return interval


func _has_enemy_type(kind: String) -> bool:
	for enemy in enemies:
		if enemy["type"] == kind:
			return true
	return false


func _try_spawn_larapio() -> void:
	if current_phase != 1 or boss_active or boss_dead:
		return
	if time_alive < next_larapio_spawn_time:
		return
	if _has_enemy_type(ENEMY_LARAPIO):
		next_larapio_spawn_time = time_alive + 12.0
		return
	larapio_spawned = true
	next_larapio_spawn_time = time_alive + LARAPIO_SPAWN_TIME
	_spawn_enemy(ENEMY_LARAPIO, _spawn_point_on_edge())
	_add_text("LARAPIO CHEGANDO!", player_pos + Vector2(0, -120), Color(1.0, 0.72, 0.22), 2.2, 25)


func _spawn_enemy(kind: String, pos: Vector2) -> void:
	var base_hp = enemy_base_hp
	var hp_mult = 1.0
	var speed = enemy_speed_base
	var damage = 0.06 * player_hp_max + enemy_close_damage
	var points = 75
	match kind:
		ENEMY_ATIRADOR:
			hp_mult = 1.2
			speed *= 0.8
			points = 90
		ENEMY_KAMIKAZE:
			hp_mult = 0.8
			speed *= 1.4
			points = 80
		ENEMY_AGGLOMERATOR:
			hp_mult = 3.2
			speed *= 1.35
			points = 120
		ENEMY_STALKER:
			hp_mult = 0.9
			speed *= _stalker_profile()["base"]
			points = 94
		ENEMY_PROJECTOR:
			hp_mult = 1.2
			speed *= 0.8
			points = 101
		ENEMY_CRYSTAL:
			hp_mult = 2.0
			speed *= 0.5
			points = 109
		ENEMY_CURATER:
			hp_mult = 2.4
			speed *= 0.45
			points = 135
		ENEMY_LARAPIO:
			hp_mult = 3.2 * (1.0 + time_alive * 0.005 + enemies_killed * 0.002)
			speed *= 1.25
			damage *= 0.28
			points = 120
		ENEMY_DEVOTO:
			hp_mult = 0.60
			speed *= 1.35
			damage *= 0.90
			points = 105
		ENEMY_INCENSARIO:
			hp_mult = 0.90
			speed *= 0.72
			damage *= 0.75
			points = 125
		ENEMY_GUARDIAO:
			hp_mult = 2.75
			speed *= 0.52
			damage *= 1.35
			points = 170
	var hp = base_hp * hp_mult
	enemies.append({
		"uid": randi(),
		"type": kind,
		"pos": pos,
		"hp": hp,
		"max_hp": hp,
		"speed": speed,
		"damage": damage,
		"points": points,
		"phase": rng.randf() * 10.0,
		"hit_cd": 0.0,
		"shoot_cd": rng.randf_range(0.5, 2.0),
		"heal_tick": 0.0,
		"agglomerated_time": 0.0,
		"stun": 0.0,
		"poison": 0.0,
		"poison_tick": 0.0,
		"laceracao": 0,
		"bleed_timer": 0.0,
		"seeds": 0,
		"parasite_mark_time": 0.0,
		"parasite_slow_time": 0.0,
		"bit": rng.randi_range(0, 1),
		"portal": 0.0,
		"portal_pause": 0.0,
		"stolen": 0,
		"steal_cd": rng.randf_range(0.3, 0.8),
		"throw_cd": rng.randf_range(2.0, LARAPIO_THROW_INTERVAL),
		"happy_timer": 0.0,
		"coin_drop_cd": 0.0,
		"alerted": false,
		"direct_steal": false,
		"state": "hunting",
		"facing_dir": _enemy_default_facing(kind),
		"last_move_dir": Vector2.ZERO,
		"invisible": false,
		"alpha": 1.0,
		"sprint_timer": time_alive,
		"sprint_active": false,
		"miasma_cd": rng.randf_range(0.1, 0.26),
		"prepare": 0.0,
		"strafe": -1.0 if rng.randf() < 0.5 else 1.0
	})


func _spawn_point_around_player(radius: float) -> Vector2:
	var angle = rng.randf_range(0.0, TAU)
	var pos = player_pos + Vector2.from_angle(angle) * radius
	return pos.clamp(Vector2(50, 50), WORLD_SIZE - Vector2(50, 50))


func _spawn_point_for_type(kind: String) -> Vector2:
	if kind == ENEMY_CURATER:
		var margin = 28.0
		var corners = [
			Vector2(margin, margin),
			Vector2(WORLD_SIZE.x - margin, margin),
			Vector2(margin, WORLD_SIZE.y - margin),
			Vector2(WORLD_SIZE.x - margin, WORLD_SIZE.y - margin)
		]
		return (corners[rng.randi_range(0, corners.size() - 1)] + Vector2(rng.randf_range(-12, 36), rng.randf_range(-12, 36))).clamp(Vector2(40, 40), WORLD_SIZE - Vector2(40, 40))
	var best = _spawn_point_on_edge()
	for i in range(12):
		var candidate = _spawn_point_on_edge()
		var too_close = false
		for enemy in enemies:
			if candidate.distance_to(enemy["pos"]) < ENEMY_MIN_SPAWN_DISTANCE:
				too_close = true
				break
		if not too_close:
			return candidate
	return best


func _spawn_point_on_edge() -> Vector2:
	match rng.randi_range(0, 3):
		0:
			return Vector2(40, rng.randf_range(40, WORLD_SIZE.y - 40))
		1:
			return Vector2(WORLD_SIZE.x - 40, rng.randf_range(40, WORLD_SIZE.y - 40))
		2:
			return Vector2(rng.randf_range(40, WORLD_SIZE.x - 40), 40)
		_:
			return Vector2(rng.randf_range(40, WORLD_SIZE.x - 40), WORLD_SIZE.y - 40)


func _update_enemies(delta: float) -> void:
	var dead = []
	var lacerante_storm = not _active_lacerante_secondary().is_empty()
	var phase1_boss_freeze = _phase1_boss_freezes_enemies()
	for enemy in enemies:
		enemy["phase"] = float(enemy.get("phase", 0.0)) + delta * 7.0
		enemy["hit_cd"] = max(0.0, float(enemy.get("hit_cd", 0.0)) - delta)
		enemy["stun"] = max(0.0, float(enemy.get("stun", 0.0)) - delta)
		_update_enemy_dots(enemy, delta)
		if float(enemy.get("hp", 0.0)) <= 0.0:
			dead.append(enemy)
			continue
		if phase1_boss_freeze:
			continue
		if enemy["type"] == ENEMY_CURATER:
			_update_curater(enemy, delta)
		if enemy["type"] == ENEMY_STALKER:
			_update_stalker(enemy, delta)
		if enemy["type"] == ENEMY_PROJECTOR:
			_update_projector(enemy, delta)
		if enemy["type"] == ENEMY_ATIRADOR:
			_update_atirador(enemy, delta)
		if enemy["type"] == ENEMY_KAMIKAZE:
			_update_kamikaze(enemy, delta)
		if enemy["type"] == ENEMY_LARAPIO:
			_update_larapio(enemy, delta)
		if current_phase == 3:
			_update_phase3_enemy(enemy, delta)
		var is_disco = not _active_prismatica_secondary().is_empty()
		if float(enemy.get("stun", 0.0)) <= 0.0 and (not bool(enemy.get("parado", false)) or is_disco):
			_move_enemy(enemy, delta)

		if not lacerante_storm and enemy["type"] == ENEMY_KAMIKAZE and enemy["pos"].distance_to(player_pos) < 60.0:
			_damage_player(player_hp_max * 0.15, ENEMY_KAMIKAZE)
			if not _player_invulnerable():
				player_stun_timer = 1.0
				_add_text("CONGELADO!", player_pos + Vector2(0, -40), Color(0.0, 0.88, 1.0), 1.5, 20)
				_spawn_radial_particles(enemy["pos"], Color(0.6, 0.9, 1.0), 16)
			enemy["hp"] = -1.0
			continue

		if not lacerante_storm and not bool(enemy.get("invisible", false)) and enemy["pos"].distance_to(player_pos) < 46.0 and float(enemy.get("hit_cd", 0.0)) <= 0.0:
			enemy["hit_cd"] = 0.55
			_damage_player(_enemy_damage(enemy), enemy["type"])
	for enemy in dead:
		_kill_enemy(enemy)


func _update_phase3_enemy(enemy: Dictionary, delta: float) -> void:
	var kind = String(enemy.get("type", ENEMY_COMMON))
	if kind == ENEMY_DEVOTO:
		enemy["miasma_cd"] = float(enemy.get("miasma_cd", 0.0)) - delta
		if float(enemy["miasma_cd"]) <= 0.0:
			enemy["miasma_cd"] = 0.26
			_add_phase3_miasma(Vector2(enemy["pos"]), rng.randf_range(18.0, 26.0), 2.5, 0.012)
	elif kind == ENEMY_INCENSARIO:
		var dist = Vector2(enemy["pos"]).distance_to(player_pos)
		var radial = (player_pos - Vector2(enemy["pos"])).normalized()
		var tangent = radial.orthogonal() * float(enemy.get("strafe", 1.0))
		var move_dir = tangent
		if dist < 220.0:
			move_dir = -radial
		elif dist > 430.0:
			move_dir = radial
		if move_dir.length() > 0.05:
			enemy["pos"] = (Vector2(enemy["pos"]) + move_dir.normalized() * float(enemy["speed"]) * delta).clamp(Vector2(40, 40), WORLD_SIZE - Vector2(40, 40))
			enemy["facing_dir"] = move_dir
		enemy["parado"] = true
		enemy["shoot_cd"] = float(enemy.get("shoot_cd", 1.0)) - delta
		if float(enemy["shoot_cd"]) <= 0.0 and float(enemy.get("prepare", 0.0)) <= 0.0:
			enemy["prepare"] = 0.55
			enemy["miasma_target"] = player_pos
		if float(enemy.get("prepare", 0.0)) > 0.0:
			enemy["prepare"] = float(enemy["prepare"]) - delta
			if float(enemy["prepare"]) <= 0.0:
				_add_phase3_miasma(Vector2(enemy.get("miasma_target", player_pos)), rng.randf_range(58.0, 72.0), rng.randf_range(2.8, 3.5), 0.015)
				enemy["shoot_cd"] = rng.randf_range(2.2, 3.0)
	if kind == ENEMY_COMMON or kind == ENEMY_DEVOTO:
		enemy["shoot_cd"] = float(enemy.get("shoot_cd", 1.0)) - delta
		if float(enemy["shoot_cd"]) <= 0.0:
			enemy["shoot_cd"] = 1.5
			if rng.randf() <= 0.10:
				_spawn_phase3_projectile(Vector2(enemy["pos"]), (player_pos - Vector2(enemy["pos"])).normalized(), player_hp_max * 0.07 + enemy_far_damage, "rat_shot", 0.62)


func _add_phase3_miasma(pos: Vector2, radius: float, duration: float, damage_ratio: float) -> void:
	phase3_miasma_zones.append({"pos": pos, "radius": radius, "life": duration, "max": duration, "tick": 0.0, "damage_ratio": damage_ratio, "phase": rng.randf_range(0.0, TAU)})


func _update_phase3_environment(delta: float) -> void:
	for zone in phase3_miasma_zones:
		zone["life"] = float(zone["life"]) - delta
		zone["tick"] = float(zone.get("tick", 0.0)) - delta
		if float(zone["tick"]) <= 0.0 and player_pos.distance_to(Vector2(zone["pos"])) <= float(zone["radius"]):
			zone["tick"] = BOSS3_MIASMA_TICK
			_damage_player(max(1, int(player_hp_max * float(zone["damage_ratio"]))), "miasma")
	phase3_miasma_zones = phase3_miasma_zones.filter(func(z): return float(z["life"]) > 0.0)


func _spawn_phase3_projectile(pos: Vector2, dir: Vector2, damage: float, kind: String, speed_mult: float) -> void:
	enemy_bullets.append({"pos": pos, "dir": dir.normalized(), "life": 5.0, "damage": damage, "phase": 0.0, "type": kind, "speed_mult": speed_mult})


func _phase1_boss_freezes_enemies() -> bool:
	return current_phase == 1 and (mode == "boss_call" or boss_active) and not boss_dead


func _move_enemy(enemy: Dictionary, delta: float) -> void:
	var lacerante_secondary = _active_lacerante_secondary()
	var target_pos = player_pos
	if not lacerante_secondary.is_empty():
		target_pos = Vector2(lacerante_secondary.get("center", player_pos))
	var is_disco = not _active_prismatica_secondary().is_empty()
	var dir = (target_pos - enemy["pos"]).normalized()
	if enemy["type"] == ENEMY_LARAPIO and not is_disco:
		var to_player = (player_pos - Vector2(enemy["pos"])).normalized()
		var dist = Vector2(enemy["pos"]).distance_to(player_pos)
		var has_loot = int(enemy.get("stolen", 0)) > 0
		if bool(enemy.get("direct_steal", false)) and player_stun_timer > 0.0:
			dir = to_player
		elif has_loot or enemy["hp"] < enemy["max_hp"] * 0.5:
			dir = -to_player
		elif bool(enemy.get("alerted", false)) and dist < 430.0:
			dir = (-to_player + to_player.orthogonal() * float(enemy.get("strafe", 1.0)) * 0.72).normalized()
		elif dist < LARAPIO_STEAL_RADIUS * 0.82:
			dir = -to_player
		else:
			dir = (to_player + to_player.orthogonal() * float(enemy.get("strafe", 1.0)) * 0.24).normalized()
	var speed_mult = 1.0
	if float(enemy.get("parasite_slow_time", 0.0)) > 0.0:
		speed_mult *= 0.80
	if is_disco:
		speed_mult *= 1.12
		dir = (player_pos - enemy["pos"]).normalized()
	if manifestation_key == "ancorada":
		for anchor in anchors:
			if anchor["pos"].distance_to(enemy["pos"]) < 130.0:
				speed_mult = 0.76
				break
	for secondary in manifestation_secondaries:
		if String(secondary.get("kind", "")) != "ancorada":
			continue
		var center: Vector2 = secondary.get("center", player_pos)
		if Vector2(enemy["pos"]).distance_to(center) <= 220.0:
			var charge = clamp(float(secondary.get("charge", 0.0)) / SECONDARY_ANCORADA_DURATION, 0.0, 1.0)
			speed_mult = min(speed_mult, 0.78 - charge * 0.18)
	if enemy["type"] == ENEMY_LARAPIO:
		if bool(enemy.get("direct_steal", false)) and player_stun_timer > 0.0:
			speed_mult *= 1.55
		if int(enemy.get("stolen", 0)) > 0:
			speed_mult *= 1.35
		if float(enemy.get("happy_timer", 0.0)) > 0.0:
			speed_mult *= 1.18
	if dir.length() > 0.05:
		enemy["last_move_dir"] = dir
		enemy["facing_dir"] = dir
	enemy["pos"] += dir * float(enemy["speed"]) * speed_mult * delta
	enemy["pos"] = enemy["pos"].clamp(Vector2(40, 40), WORLD_SIZE - Vector2(40, 40))


func _stalker_profile() -> Dictionary:
	var window = max(1.0, 720.0 - ANOMALIA_ESPREITADOR_TIME)
	var progress = clamp((time_alive - ANOMALIA_ESPREITADOR_TIME) / window, 0.0, 1.0)
	return {
		"base": 0.82 + progress * 0.28,
		"furtivo": 0.62 + progress * 0.16,
		"sprint": 1.24 + progress * 0.46,
		"duration": 0.85 + progress * 0.45,
		"cooldown": 9.2 - progress * 2.6
	}


func _update_stalker(enemy: Dictionary, delta: float) -> void:
	var dist = enemy["pos"].distance_to(player_pos)
	var profile = _stalker_profile()
	if dist > 300.0:
		enemy["invisible"] = true
		enemy["alpha"] = 0.32 + (sin(time_alive * 6.0 + float(enemy["phase"])) + 1.0) * 0.20
		enemy["speed"] = enemy_speed_base * float(profile["furtivo"])
	else:
		enemy["invisible"] = false
		enemy["alpha"] = 1.0
		if not bool(enemy.get("sprint_active", false)) and time_alive - float(enemy.get("sprint_timer", 0.0)) > float(profile["cooldown"]):
			enemy["sprint_active"] = true
			enemy["sprint_timer"] = time_alive
			_spawn_radial_particles(enemy["pos"], Color(0.65, 0.95, 1.0), 8)
		if bool(enemy.get("sprint_active", false)):
			if time_alive - float(enemy["sprint_timer"]) < float(profile["duration"]):
				enemy["speed"] = enemy_speed_base * float(profile["sprint"])
				enemy["alpha"] = 1.0
			else:
				enemy["sprint_active"] = false
				enemy["sprint_timer"] = time_alive
				enemy["speed"] = enemy_speed_base * float(profile["base"])
		else:
			enemy["speed"] = enemy_speed_base * float(profile["base"])


func _update_enemy_dots(enemy: Dictionary, delta: float) -> void:
	enemy["parasite_slow_time"] = max(0.0, float(enemy.get("parasite_slow_time", 0.0)) - delta)
	if float(enemy.get("parasite_mark_time", 0.0)) > 0.0:
		enemy["parasite_mark_time"] = max(0.0, float(enemy["parasite_mark_time"]) - delta)
		if float(enemy["parasite_mark_time"]) <= 0.0:
			enemy["seeds"] = 0
	if float(enemy.get("poison", 0.0)) > 0.0:
		enemy["poison_tick"] = float(enemy.get("poison_tick", 0.0)) - delta
		if float(enemy["poison_tick"]) <= 0.0:
			enemy["poison_tick"] = 0.65
			enemy["poison"] = max(0.0, float(enemy["poison"]) - 0.65)
			_damage_enemy(enemy, max(1.0, player_damage * poison_damage), "veneno", false)
	if int(enemy.get("laceracao", 0)) > 0:
		enemy["bleed_timer"] = max(0.0, float(enemy.get("bleed_timer", 0.0)) - delta)
		if float(enemy["bleed_timer"]) > 0.0 and int(Time.get_ticks_msec() / 350) % 2 == 0:
			enemy["hp"] = float(enemy["hp"]) - int(enemy.get("laceracao", 0)) * 0.18


func _update_curater(enemy: Dictionary, delta: float) -> void:
	enemy["heal_tick"] = float(enemy.get("heal_tick", 0.0)) - delta
	if float(enemy["heal_tick"]) > 0.0:
		return
	enemy["heal_tick"] = 1.0
	for target in enemies:
		if target == enemy or target["type"] == ENEMY_CURATER or float(target["hp"]) <= 0.0:
			continue
		if target["pos"].distance_to(enemy["pos"]) < 210.0 and float(target["hp"]) < float(target["max_hp"]):
			var heal = (float(target["max_hp"]) - float(target["hp"])) * 0.20
			target["hp"] = min(float(target["max_hp"]), float(target["hp"]) + heal)
			_add_text("+%d" % int(heal), target["pos"] + Vector2(0, -44), Color(0.3, 1.0, 0.45), 0.8, 18)


func _update_projector(enemy: Dictionary, delta: float) -> void:
	var dist = enemy["pos"].distance_to(player_pos)
	enemy["parado"] = dist <= 280.0
	if bool(enemy["parado"]):
		var aim = (player_pos - enemy["pos"]).normalized()
		if aim.length() > 0.05:
			enemy["facing_dir"] = aim
	if not bool(enemy["parado"]):
		return
	enemy["shoot_cd"] = float(enemy.get("shoot_cd", 1.0)) - delta
	if float(enemy["shoot_cd"]) > 0.0:
		return
	enemy["shoot_cd"] = 2.5
	var dir = (player_pos - enemy["pos"]).normalized()
	enemy_bullets.append({"pos": enemy["pos"], "dir": dir, "life": 3.2, "damage": (player_hp_max * 0.05) + enemy_far_damage, "phase": 0.0})


func _update_atirador(enemy: Dictionary, delta: float) -> void:
	var dist = enemy["pos"].distance_to(player_pos)
	enemy["parado"] = dist <= 320.0
	if not bool(enemy["parado"]):
		return
	enemy["shoot_cd"] = float(enemy.get("shoot_cd", 1.0)) - delta
	if float(enemy["shoot_cd"]) > 0.0:
		return
	enemy["shoot_cd"] = 3.0
	var dir = (player_pos - enemy["pos"]).normalized()
	enemy_bullets.append({"pos": enemy["pos"], "dir": dir, "life": 4.0, "damage": (player_hp_max * 0.08) + enemy_far_damage, "phase": 0.0, "type": "atirador"})


func _update_kamikaze(enemy: Dictionary, delta: float) -> void:
	pass


func _update_larapio(enemy: Dictionary, delta: float) -> void:
	var has_loot = int(enemy.get("stolen", 0)) > 0
	enemy["happy_timer"] = max(0.0, float(enemy.get("happy_timer", 0.0)) - delta)
	if player_stun_timer <= 0.0:
		enemy["steal_cd"] = max(0.0, float(enemy.get("steal_cd", 0.0)) - delta)
		enemy["throw_cd"] = max(0.0, float(enemy.get("throw_cd", 0.0)) - delta)

	if has_loot:
		enemy["coin_drop_cd"] = float(enemy.get("coin_drop_cd", 0.0)) - delta
		if float(enemy["coin_drop_cd"]) <= 0.0:
			enemy["coin_drop_cd"] = LARAPIO_COIN_DROP_INTERVAL
			_spawn_larapio_coin_drop(Vector2(enemy["pos"]) + Vector2(0, 20), 0, false)

	var dist = Vector2(enemy["pos"]).distance_to(player_pos)
	if score > 0 and dist < LARAPIO_STEAL_RADIUS and float(enemy.get("steal_cd", 0.0)) <= 0.0:
		_larapio_steal(enemy, LARAPIO_STEAL_RATIO)
		return

	if has_loot and enemy["hp"] < enemy["max_hp"] * 0.7:
		enemy["portal_pause"] = max(0.0, float(enemy.get("portal_pause", 0.0)) - delta)
		if float(enemy["portal_pause"]) <= 0.0:
			enemy["portal"] = float(enemy.get("portal", 0.0)) + delta
		if float(enemy["portal"]) >= LARAPIO_PORTAL_TIME:
			_add_text("LARAPIO ESCAPOU COM %d" % int(enemy.get("stolen", 0)), enemy["pos"] + Vector2(0, -70), Color(0.82, 0.36, 1.0), 1.8, 24)
			enemies.erase(enemy)
			return
	else:
		enemy["portal"] = 0.0

	if float(enemy.get("throw_cd", 0.0)) <= 0.0 and (bool(enemy.get("alerted", false)) or has_loot) and dist <= 560.0:
		enemy["throw_cd"] = LARAPIO_THROW_INTERVAL
		_throw_larapio_projectile(enemy)


func _larapio_steal(enemy: Dictionary, ratio: float) -> void:
	var stolen = min(score, max(1, int(round(score * ratio))))
	if stolen <= 0:
		return
	score = max(0, score - stolen)
	score_total = max(0, score_total - stolen)
	enemy["stolen"] = int(enemy.get("stolen", 0)) + stolen
	enemy["steal_cd"] = 2.3
	enemy["hit_cd"] = max(float(enemy.get("hit_cd", 0.0)), 1.1)
	enemy["happy_timer"] = 3.2
	enemy["alerted"] = true
	enemy["direct_steal"] = false
	player_stun_timer = max(player_stun_timer, LARAPIO_STUN_TIME)
	screen_shake_timer = max(screen_shake_timer, 0.22)
	screen_shake_strength = max(screen_shake_strength, 9.0)
	_vibrate(120, 0.46)
	_play_sfx("Moeda.mp3", 0.04, 0.58, 1.08)
	_add_text("-%d PONTOS" % stolen, player_pos + Vector2(0, -56), Color(1.0, 0.78, 0.18), 1.0, 22)
	_add_text("+%d" % stolen, Vector2(enemy["pos"]) + Vector2(0, -54), Color(1.0, 0.88, 0.28), 0.9, 18)
	for i in range(8):
		_spawn_larapio_coin_drop(player_pos.lerp(Vector2(enemy["pos"]), 0.35 + i * 0.05), 0, false)


func _throw_larapio_projectile(enemy: Dictionary) -> void:
	var dir = (player_pos - Vector2(enemy["pos"])).normalized()
	if dir.length() <= 0.05:
		dir = Vector2.LEFT
	var has_loot = int(enemy.get("stolen", 0)) > 0
	enemy_bullets.append({
		"pos": Vector2(enemy["pos"]) + Vector2(0, -10),
		"dir": dir,
		"life": 3.4,
		"damage": max(1.0, player_hp_max * 0.015),
		"phase": 0.0,
		"type": "larapio_coin" if has_loot else "larapio_stone",
		"speed_mult": 1.36,
		"owner_uid": int(enemy.get("uid", -1))
	})
	_add_text("TIN!", Vector2(enemy["pos"]) + Vector2(0, -72), Color(1.0, 0.82, 0.24), 0.45, 14)


func _spawn_larapio_coin_drop(pos: Vector2, value: int, collectable: bool) -> void:
	var impulse = Vector2(rng.randf_range(-70.0, 70.0), rng.randf_range(-135.0, -58.0))
	larapio_coin_drops.append({
		"pos": pos,
		"vel": impulse,
		"value": value,
		"collectable": collectable,
		"life": LARAPIO_COIN_DROP_LIFE if not collectable else 7.5,
		"max": LARAPIO_COIN_DROP_LIFE if not collectable else 7.5,
		"phase": rng.randf_range(0.0, TAU),
		"spin": rng.randf_range(-8.0, 8.0)
	})


func _spawn_larapio_loot(pos: Vector2, total: int) -> void:
	if total <= 0:
		return
	var pieces = clampi(int(ceil(float(total) / max(45.0, float(card_cost) * 0.25))), 4, 14)
	var remaining = total
	for i in range(pieces):
		var value = int(round(float(total) / float(pieces)))
		if i == pieces - 1:
			value = remaining
		remaining = max(0, remaining - value)
		_spawn_larapio_coin_drop(pos + Vector2(rng.randf_range(-20.0, 20.0), rng.randf_range(-8.0, 10.0)), max(1, value), true)


func _update_larapio_coin_drops(delta: float) -> void:
	var kept = []
	for coin in larapio_coin_drops:
		coin["life"] = float(coin["life"]) - delta
		coin["phase"] = float(coin.get("phase", 0.0)) + float(coin.get("spin", 1.0)) * delta
		var vel = Vector2(coin.get("vel", Vector2.ZERO))
		var pos = Vector2(coin.get("pos", Vector2.ZERO))
		vel.y += 330.0 * delta
		pos += vel * delta
		var ground_y = float(coin.get("ground_y", pos.y + 18.0))
		if not coin.has("ground_y"):
			coin["ground_y"] = ground_y
		if pos.y > ground_y:
			pos.y = ground_y
			vel.y = -abs(vel.y) * 0.28
			vel.x *= 0.68
			if abs(vel.y) < 26.0:
				vel.y = 0.0
		coin["pos"] = pos
		coin["vel"] = vel
		if bool(coin.get("collectable", false)) and pos.distance_to(player_pos) <= 46.0:
			var value = int(coin.get("value", 0))
			if value > 0:
				score += value
				score_total += value
				_add_text("+%d PONTOS" % value, player_pos + Vector2(0, -64), Color(1.0, 0.86, 0.24), 0.7, 17)
				_play_sfx("Moeda.mp3", 0.05, 0.42, 1.15)
			continue
		if float(coin["life"]) > 0.0:
			kept.append(coin)
	larapio_coin_drops = kept


func _update_agglomeration(delta: float) -> void:
	fusion_check_timer -= delta
	if fusion_check_timer > 0.0 or boss_active:
		return
	fusion_check_timer = FUSION_CHECK_INTERVAL
	var commons = []
	for enemy in enemies:
		if enemy["type"] == ENEMY_COMMON:
			commons.append(enemy)
	var used = {}
	for enemy in commons:
		if used.has(enemy["uid"]):
			continue
		var cluster = [enemy]
		for other in commons:
			if other == enemy or used.has(other["uid"]):
				continue
			if enemy["pos"].distance_to(other["pos"]) <= FUSION_RADIUS:
				cluster.append(other)
		if cluster.size() >= FUSION_REQUIRED:
			var ready = true
			var center = Vector2.ZERO
			var hp_sum = 0.0
			for item in cluster:
				item["agglomerated_time"] = float(item.get("agglomerated_time", 0.0)) + FUSION_CHECK_INTERVAL
				center += item["pos"]
				hp_sum += float(item.get("max_hp", enemy_base_hp))
				if float(item["agglomerated_time"]) < FUSION_TIME:
					ready = false
				used[item["uid"]] = true
			if ready:
				center /= cluster.size()
				for item in cluster:
					enemies.erase(item)
				_spawn_enemy(ENEMY_AGGLOMERATOR, center)
				var fused = enemies[enemies.size() - 1]
				fused["max_hp"] = max(float(fused["max_hp"]), hp_sum * 0.9)
				fused["hp"] = fused["max_hp"]
				fused["speed"] = max(float(fused["speed"]), enemy_speed_base * (1.35 + max(0, cluster.size() - FUSION_REQUIRED) * 0.15))
				_add_text("FUSAO FORCADA!", center + Vector2(0, -55), Color(1.0, 0.78, 0.12), 1.5, 24)
				_spawn_radial_particles(center, Color(1.0, 0.78, 0.12), 26)


func _update_event_alerts(delta: float) -> void:
	event_alert_timer = max(0.0, event_alert_timer - delta)
	if current_phase != 1:
		return
	if not alert_curater_done and time_alive >= ANOMALIA_CURATER_TIME:
		_show_event_alert("ANOMALIA DE CURA DETECTADA: CURATER!", Color(0.47, 1.0, 0.55))
		alert_curater_done = true
	elif not alert_agglomerator_done and time_alive >= ANOMALIA_AGLOMERADOR_TIME:
		_show_event_alert("ANOMALIA DE FUSAO: AGLOMERADORES!", Color(1.0, 0.82, 0.28))
		alert_agglomerator_done = true
	elif not alert_crystal_done and time_alive >= ANOMALIA_CRISTALIZADOR_TIME:
		_show_event_alert("ANOMALIA DETECTADA: INIMIGOS CRISTALIZADOS!", Color(1.0, 0.0, 0.50))
		alert_crystal_done = true
	elif not alert_projector_done and time_alive >= ANOMALIA_PROJETADOR_TIME:
		_show_event_alert("ANOMALIA DETECTADA: PROJETADORES!", Color(1.0, 0.0, 0.50))
		alert_projector_done = true
	elif not alert_stalker_done and time_alive >= ANOMALIA_ESPREITADOR_TIME:
		_show_event_alert("ALERTA: A AREIA COSMICA SE ADAPTOU!", Color(0.0, 1.0, 1.0))
		alert_stalker_done = true


func _show_event_alert(text: String, color: Color) -> void:
	event_alert_text = text
	event_alert_color = color
	event_alert_timer = 4.0
	_add_text(text, player_pos + Vector2(0, -128), color, 2.0, 22)


func _enemy_damage(enemy: Dictionary) -> int:
	var raw = float(enemy.get("damage", 10.0))
	var early_mult = 0.55 if time_alive < 480.0 else min(1.0, 0.55 + (time_alive - 480.0) / 240.0 * 0.45)
	return max(1, int(raw * early_mult - player_defense))


func _update_bullets(delta: float) -> void:
	var new_bullets = []
	for bullet in bullets:
		bullet["age"] = float(bullet.get("age", 0.0)) + delta
		bullet["phase"] = float(bullet.get("phase", 0.0)) + delta * 8.0
		bullet["trail_cd"] = float(bullet.get("trail_cd", 0.0)) - delta
		bullet["pos"] += bullet["dir"] * float(bullet["speed"]) * delta
		bullet["life"] = float(bullet["life"]) - delta
		if float(bullet["trail_cd"]) <= 0.0:
			bullet["trail_cd"] = 0.028 if String(bullet.get("kind", "")) == "eletrica_charged" else 0.040
			_emit_projectile_trail(bullet)

		# Prismatica Wall Ricochet
		if bullet["kind"] == "prismatica":
			var pos: Vector2 = bullet["pos"]
			var hit_wall = false
			if pos.x < 10.0 or pos.x > WORLD_SIZE.x - 10.0:
				bullet["dir"].x = -bullet["dir"].x
				hit_wall = true
			if pos.y < 10.0 or pos.y > WORLD_SIZE.y - 10.0:
				bullet["dir"].y = -bullet["dir"].y
				hit_wall = true
			if hit_wall:
				bullet["pos"] = bullet["pos"].clamp(Vector2(10.0, 10.0), WORLD_SIZE - Vector2(10.0, 10.0))
				if not bool(bullet.get("refracted", false)):
					bullet["durability"] = float(bullet.get("durability", 100.0)) - 10.0
					if float(bullet["durability"]) <= 0.0:
						bullet["life"] = 0.0
						_spawn_radial_particles(Vector2(bullet["pos"]), Color(0.32, 1.0, 0.96), 7)
						continue
					bullet["damage"] = float(bullet["damage"]) * 1.02
					bullet["ricocheted"] = true
					bullet["life"] = float(bullet.get("max_life", 1.0))
				else:
					bullet["life"] = 0.0

		# Prismatica Refraction Split
		if bullet["kind"] == "prismatica" and not bool(bullet.get("refracted", false)):
			for prism in prisms:
				if abs(bullet["pos"].x - prism["pos"].x) < 25.0 and abs(bullet["pos"].y - prism["pos"].y) < 25.0:
					var current_angle = bullet["dir"].angle()
					var angles = [-0.26, 0.0, 0.26]
					for offset_angle in angles:
						var new_dir = Vector2.from_angle(current_angle + offset_angle)
						new_bullets.append({
							"pos": bullet["pos"],
							"dir": new_dir,
							"speed": float(bullet["speed"]) * 0.92,
							"life": min(1.0, float(bullet["life"])),
							"max_life": min(1.0, float(bullet["life"])),
							"age": 0.0,
							"phase": rng.randf_range(0.0, TAU),
							"trail_cd": 0.0,
							"damage": float(bullet["damage"]) * 0.72,
							"kind": "prismatica",
							"color": Color(0.32, 1.0, 0.96),
							"pierce": true,
							"hits": {},
							"refracted": true,
							"ricochets": 0,
							"durability": max(0.0, float(bullet.get("durability", 100.0)) - 15.0)
						})
					bullet["life"] = 0.0
					break

		if float(bullet["life"]) <= 0.0:
			continue

		for enemy in enemies:
			if float(enemy.get("hp", 0.0)) <= 0.0:
				continue
			var uid = str(enemy["uid"])
			if bullet["hits"].has(uid):
				continue
			if bullet["pos"].distance_to(enemy["pos"]) < _enemy_radius(enemy):
				bullet["hits"][uid] = true
				_apply_bullet_effect(bullet, enemy)

				if bullet["kind"] == "prismatica" and not bool(bullet.get("refracted", false)):
					var e_hits = int(bullet.get("enemy_hits_count", 0)) + 1
					bullet["enemy_hits_count"] = e_hits
					if e_hits < 2:
						bullet["ricocheted"] = true
						bullet["life"] = float(bullet.get("max_life", 1.0))
						var normal = (bullet["pos"] - enemy["pos"]).normalized()
						if normal.length() < 0.1: normal = -bullet["dir"]
						bullet["dir"] = bullet["dir"].bounce(normal)
						break
					else:
						bullet["life"] = 0.0
						break
				elif not bool(bullet["pierce"]):
					bullet["life"] = 0.0
					break
		if float(bullet["life"]) > 0.0 and _damage_phase3_cheeses_at(Vector2(bullet["pos"]), float(bullet["damage"]), 30.0):
			if not bool(bullet["pierce"]):
				bullet["life"] = 0.0
		if float(bullet["life"]) > 0.0 and boss_active and boss_hp > 0.0 and bullet["pos"].distance_to(boss_pos) < 82.0:
			if not bullet["hits"].has("boss"):
				bullet["hits"]["boss"] = true
				_damage_boss(float(bullet["damage"]), bullet["kind"])
				if bullet["kind"] == "gravitante":
					orbitals.append({
						"target_kind": "boss",
						"enemy_uid": -1,
						"origin_pos": boss_pos,
						"angle": rng.randf_range(0.0, TAU),
						"life": 4.0,
						"tick": 0.10,
						"damage": player_damage * 0.14,
						"sfx_cd": 0.0
					})
				if bullet["kind"] == "parasitica":
					boss_parasite_seeds = min(5, boss_parasite_seeds + 1)
					boss_parasite_mark_time = PARASITE_MARK_DURATION
				if bullet["kind"] == "eletrica_charged":
					shockwaves.append({"pos": boss_pos, "radius": 18.0, "max": 132.0, "life": 0.28, "damage": float(bullet["damage"]) * 0.42, "hit": {}})
					_spawn_radial_particles(boss_pos, Color(0.46, 1.0, 1.0), 10)

				if bullet["kind"] == "prismatica" and not bool(bullet.get("refracted", false)):
					var e_hits = int(bullet.get("enemy_hits_count", 0)) + 1
					bullet["enemy_hits_count"] = e_hits
					if e_hits < 2:
						bullet["ricocheted"] = true
						bullet["life"] = float(bullet.get("max_life", 1.0))
						var normal = (bullet["pos"] - boss_pos).normalized()
						if normal.length() < 0.1: normal = -bullet["dir"]
						bullet["dir"] = bullet["dir"].bounce(normal)
					else:
						bullet["life"] = 0.0
				elif not bool(bullet["pierce"]):
					bullet["life"] = 0.0
	if not new_bullets.is_empty():
		bullets.append_array(new_bullets)
	bullets = bullets.filter(func(b): return float(b["life"]) > 0.0)


func _apply_bullet_effect(bullet: Dictionary, enemy: Dictionary) -> void:
	var damage = _critical_damage(float(bullet["damage"]))
	_damage_enemy(enemy, damage, bullet["kind"])

	_spawn_custom_collision(bullet["pos"], bullet["kind"])
	_spawn_custom_collision(bullet["pos"], bullet["kind"])
	if player_lifesteal > 0.0 and player_hp < player_hp_max:
		var heal = max(1, int((player_hp_max - player_hp) * player_lifesteal))
		player_hp = min(player_hp_max, player_hp + heal)
		_add_text("+%d" % heal, player_pos + Vector2(0, -70), Color(0.45, 1.0, 0.55), 0.6, 18)
	if poison_damage > 0.0:
		enemy["poison"] = min(5.0, max(float(enemy.get("poison", 0.0)), 2.2) + 0.55)
	if bullet["kind"] == "parasitica":
		enemy["seeds"] = min(5, int(enemy.get("seeds", 0)) + 1)
		enemy["parasite_mark_time"] = PARASITE_MARK_DURATION
	if bullet["kind"] == "gravitante":
		orbitals.append({
			"target_kind": "enemy",
			"enemy_uid": enemy["uid"],
			"origin_pos": Vector2(enemy["pos"]),
			"angle": rng.randf_range(0.0, TAU),
			"life": 4.0,
			"tick": 0.10,
			"damage": player_damage * 0.18,
			"sfx_cd": 0.0
		})
	if bullet["kind"] == "eletrica_charged":
		shockwaves.append({"pos": enemy["pos"], "radius": 18.0, "max": 128.0, "life": 0.28, "damage": damage * 0.52, "hit": {str(enemy["uid"]): true}})
		_spawn_radial_particles(enemy["pos"], Color(0.46, 1.0, 1.0), 10)
	elif bullet["kind"] == "prismatica" and bool(bullet.get("ricocheted", false)):
		var chain_target = {}
		var chain_dist = 165.0
		for other in enemies:
			if other == enemy or float(other.get("hp", 0.0)) <= 0.0:
				continue
			var d = enemy["pos"].distance_to(other["pos"])
			if d < chain_dist:
				chain_target = other
				chain_dist = d
		if not chain_target.is_empty():
			_damage_enemy(chain_target, damage * 0.42, "prismatica", false)
			slashes.append({"a": enemy["pos"], "b": chain_target["pos"], "life": 0.12, "max": 0.12, "color": Color(0.62, 1.0, 1.0), "width": 10.0})


func _critical_damage(base: float) -> float:
	if rng.randf() < player_crit_chance:
		_add_text("CRIT", player_pos + Vector2(0, -86), Color(1.0, 0.82, 0.18), 0.6, 20)
		return base * 3.0
	return base


func _update_prisms(delta: float) -> void:
	for prism in prisms:
		prism["life"] = float(prism["life"]) - delta
		prism["damage_tick"] = float(prism["damage_tick"]) - delta
		if float(prism["damage_tick"]) <= 0.0:
			prism["damage_tick"] = 0.2
			for enemy in enemies:
				if enemy["pos"].distance_to(prism["pos"]) < 45.0:
					_damage_enemy(enemy, player_damage * 0.75 * 0.2, "prismatica", false)
			if boss_active and boss_hp > 0.0 and boss_pos.distance_to(prism["pos"]) < 82.0:
				_damage_boss(player_damage * 0.75 * 0.2, "prismatica")
	prisms = prisms.filter(func(p): return float(p["life"]) > 0.0)


func _update_return_bullets(delta: float) -> void:
	for bullet in return_bullets:
		bullet["age"] = float(bullet["age"]) + delta
		bullet["phase"] = float(bullet.get("phase", 0.0)) + delta * 9.0
		bullet["trail_cd"] = float(bullet.get("trail_cd", 0.0)) - delta
		var state = String(bullet.get("state", "volta" if bool(bullet.get("returning", false)) else "ida"))
		if state == "ida" and float(bullet["age"]) > 0.58:
			state = "volta"
		var dir: Vector2 = Vector2(bullet.get("dir", Vector2.RIGHT))
		var speed = BULLET_SPEED * 0.92
		var damage = float(bullet["damage"])
		if state == "instavel":
			if time_alive >= float(bullet.get("memory_until", 0.0)):
				state = "volta"
				var impacts = int(bullet.get("memory_impacts", 0))
				bullet["memory_bonus"] = 1.25 if impacts >= 6 else (1.15 if impacts >= 3 else 1.0)
				bullet["forced"] = false
			else:
				bullet["memory_seek_cd"] = float(bullet.get("memory_seek_cd", 0.0)) - delta
				if float(bullet.get("memory_seek_cd", 0.0)) <= 0.0:
					bullet["memory_seek_cd"] = 0.48
					var chosen = {}
					var best_d = 520.0
					for enemy in enemies:
						if float(enemy.get("hp", 0.0)) <= 0.0:
							continue
						if int(enemy.get("uid", -1)) == int(bullet.get("memory_last_uid", -999999)) and time_alive - float(bullet.get("memory_last_hit_time", -999.0)) < 0.40:
							continue
						var d = Vector2(enemy["pos"]).distance_to(Vector2(bullet["pos"]))
						if d <= best_d:
							best_d = d
							chosen = enemy
					if not chosen.is_empty():
						dir = (Vector2(chosen["pos"]) - Vector2(bullet["pos"])).normalized()
					else:
						dir = dir.rotated(PI + 0.19).normalized()
				var next = Vector2(bullet["pos"]) + dir * speed * delta
				var bounced = false
				if next.x <= 10.0 or next.x >= WORLD_SIZE.x - 10.0:
					dir.x = -dir.x
					bounced = true
				if next.y <= 10.0 or next.y >= WORLD_SIZE.y - 10.0:
					dir.y = -dir.y
					bounced = true
				if bounced:
					bullet["memory_last_uid"] = -1
					bullet["memory_seek_cd"] = 0.0
				dir = dir.normalized()
				bullet["pos"] = (Vector2(bullet["pos"]) + dir * speed * delta).clamp(Vector2(10.0, 10.0), WORLD_SIZE - Vector2(10.0, 10.0))
				damage *= 0.32
		if state == "volta":
			bullet["returning"] = true
			dir = (player_pos - Vector2(bullet["pos"])).normalized()
			damage *= 1.85 * float(bullet.get("memory_bonus", 1.0))
			if bool(bullet.get("forced", false)):
				damage *= 1.28
			bullet["pos"] = Vector2(bullet["pos"]) + dir * speed * delta
		elif state == "ida":
			bullet["returning"] = false
			bullet["pos"] = Vector2(bullet["pos"]) + dir * speed * delta
		else:
			bullet["returning"] = false
		bullet["state"] = state
		bullet["dir"] = dir
		if float(bullet["trail_cd"]) <= 0.0:
			bullet["trail_cd"] = 0.045
			effects.append({
				"kind": "trail",
				"text": "",
				"pos": bullet["pos"] - dir * 14.0,
				"life": 0.18,
				"max": 0.18,
				"color": Color(1.0, 0.28, 0.76, 0.40) if state == "instavel" else (Color(1.0, 0.42, 0.92, 0.36) if bool(bullet["returning"]) else Color(0.64, 0.42, 1.0, 0.32)),
				"size": 8.0,
				"vel": -dir * 26.0
			})
		for enemy in enemies:
			if float(enemy.get("hp", 0.0)) <= 0.0:
				continue
			var hit_radius_bonus = 14.0 if float(bullet.get("paradox_until", 0.0)) > time_alive or state == "instavel" else 0.0
			if state == "instavel":
				var last_enemy_hit = float(Dictionary(bullet.get("memory_hit_times", {})).get(str(enemy["uid"]), -999.0))
				if time_alive - last_enemy_hit < 0.40 or time_alive - float(bullet.get("memory_last_hit_time", -999.0)) < 0.09:
					continue
				if Vector2(bullet["pos"]).distance_to(enemy["pos"]) < _enemy_radius(enemy) + hit_radius_bonus:
					var hit_times = Dictionary(bullet.get("memory_hit_times", {}))
					hit_times[str(enemy["uid"])] = time_alive
					bullet["memory_hit_times"] = hit_times
					bullet["memory_last_hit_time"] = time_alive
					bullet["memory_last_uid"] = int(enemy["uid"])
					bullet["memory_impacts"] = int(bullet.get("memory_impacts", 0)) + 1
					bullet["memory_seek_cd"] = 0.0
					_damage_enemy(enemy, damage, "retornante")
				continue
			var key = str(enemy["uid"]) + ("r" if state == "volta" else "i")
			if bullet["hits"].has(key):
				continue
			if Vector2(bullet["pos"]).distance_to(enemy["pos"]) < _enemy_radius(enemy) + hit_radius_bonus:
				bullet["hits"][key] = true
				_damage_enemy(enemy, damage, "retornante")
		if time_alive >= float(bullet.get("cheese_hit_at", 0.0)) and _damage_phase3_cheeses_at(Vector2(bullet["pos"]), damage, 30.0):
			bullet["cheese_hit_at"] = time_alive + 0.35
		var boss_hit_bonus = 14.0 if float(bullet.get("paradox_until", 0.0)) > time_alive or state == "instavel" else 0.0
		if boss_active and boss_hp > 0.0 and bullet["pos"].distance_to(boss_pos) < 82.0 + boss_hit_bonus:
			if state == "instavel":
				var boss_hit_times = Dictionary(bullet.get("memory_hit_times", {}))
				var last_boss_hit = float(boss_hit_times.get("boss", -999.0))
				if time_alive - last_boss_hit >= 0.40 and time_alive - float(bullet.get("memory_last_hit_time", -999.0)) >= 0.09:
					boss_hit_times["boss"] = time_alive
					bullet["memory_hit_times"] = boss_hit_times
					bullet["memory_last_hit_time"] = time_alive
					bullet["memory_last_uid"] = -2
					bullet["memory_impacts"] = int(bullet.get("memory_impacts", 0)) + 1
					bullet["memory_seek_cd"] = 0.0
					_damage_boss(damage, "retornante")
			else:
				_damage_boss(damage, "retornante")
		if state == "volta" and Vector2(bullet["pos"]).distance_to(player_pos) < 34.0:
			if float(bullet.get("paradox_until", 0.0)) > time_alive:
				var cycles = min(2, int(bullet.get("paradox_cycles", 0)) + 1)
				bullet["paradox_cycles"] = cycles
				bullet["state"] = "ida"
				bullet["returning"] = false
				bullet["age"] = 0.0
				bullet["hits"] = {}
				bullet["dir"] = dir
				var new_range = 165.0 + cycles * 45.0
				bullet["pos"] = player_pos + dir * 18.0
				bullet["memory_bonus"] = float(bullet.get("memory_bonus", 1.0))
			else:
				bullet["age"] = 99.0
	return_bullets = return_bullets.filter(func(b):
		var state = String(b.get("state", "ida"))
		return state == "instavel" or float(b["age"]) < 6.0
	)


func _damage_enemy(enemy: Dictionary, amount: float, source: String, show_text := true) -> bool:
	_play_enemy_hit_sfx(enemy, source)
	if source != "parasite_feast":
		if enemy["type"] == ENEMY_LARAPIO:
			amount *= 0.45
			enemy["portal_pause"] = LARAPIO_PORTAL_HIT_PAUSE
			enemy["alerted"] = true
			enemy["throw_cd"] = min(float(enemy.get("throw_cd", LARAPIO_THROW_INTERVAL)), LARAPIO_THROW_INTERVAL)
		elif enemy["type"] == ENEMY_CURATER:
			amount *= 0.58
		elif enemy["type"] == ENEMY_CRYSTAL:
			amount *= 0.66
		elif enemy["type"] == ENEMY_GUARDIAO:
			var incoming = (player_pos - Vector2(enemy["pos"])).normalized()
			var facing = Vector2(enemy.get("facing_dir", Vector2.LEFT)).normalized()
			var alignment = facing.dot(incoming)
			if alignment > 0.55:
				amount *= 0.25
			elif alignment < -0.45:
				amount *= 1.12
	enemy["hp"] = float(enemy["hp"]) - max(1.0, amount)
	if execute_threshold > 0.0 and float(enemy["hp"]) > 0.0 and float(enemy["hp"]) / float(enemy["max_hp"]) <= execute_threshold:
		enemy["hp"] = 0.0
		collector_hud_pulse = 0.85
		_add_text("COLETORA", enemy["pos"] + Vector2(0, -62), Color(0.95, 0.08, 0.24), 0.75, _damage_text_size(18))
		_spawn_radial_particles(Vector2(enemy["pos"]), Color(1.0, 0.08, 0.24), 18)
	if show_text:
		_add_text("-%d" % int(amount), enemy["pos"] + Vector2(0, -42), _damage_color(source), 0.55, _damage_text_size(18))
	return float(enemy["hp"]) <= 0.0


func _play_enemy_hit_sfx(enemy: Dictionary, source: String) -> void:
	if source == "veneno" or source == "gravitante_orbital":
		return
	var last_sfx = float(enemy.get("hit_sfx_time", -999.0))
	if time_alive - last_sfx < 0.045:
		return
	enemy["hit_sfx_time"] = time_alive
	var profile = _enemy_hit_audio_profile(enemy, source)
	_play_sfx("Inimigo1_hit.wav", float(profile["variance"]), float(profile["volume"]), float(profile["pitch"]))


func _enemy_hit_audio_profile(enemy: Dictionary, source: String) -> Dictionary:
	var uid = abs(int(enemy.get("uid", 0)))
	var variant = uid % 7
	var pitch_options = [0.76, 0.84, 0.92, 1.00, 1.08, 1.18, 1.30]
	var volume_options = [0.18, 0.20, 0.19, 0.22, 0.20, 0.18, 0.17]
	var pitch = float(pitch_options[variant])
	var volume = float(volume_options[variant])
	match String(enemy.get("type", "")):
		ENEMY_AGGLOMERATOR:
			pitch *= 0.78
			volume *= 1.12
		ENEMY_CRYSTAL:
			pitch *= 0.70
			volume *= 1.18
		ENEMY_CURATER:
			pitch *= 1.12
			volume *= 0.94
		ENEMY_STALKER:
			pitch *= 1.22
			volume *= 0.86
		ENEMY_PROJECTOR, ENEMY_ATIRADOR:
			pitch *= 1.08
		ENEMY_KAMIKAZE:
			pitch *= 1.28
			volume *= 0.88
		ENEMY_LARAPIO:
			pitch *= 0.88
			volume *= 0.96
	match source:
		"lacerante":
			pitch *= 0.92
		"prismatica":
			pitch *= 1.10
		"retornante":
			pitch *= 0.96
		"parasitica":
			volume *= 0.82
	return {
		"pitch": clamp(pitch, 0.58, 1.52),
		"volume": clamp(volume, 0.12, 0.28),
		"variance": 0.025
	}


func _damage_boss(amount: float, source: String) -> void:
	if current_phase == 1 and (not boss1_time_wave.is_empty() or not boss1_rewind_sequence.is_empty()):
		return
	if source != "gravitante_orbital":
		_play_sfx("Hit_Boss1.mp3", 0.06, 0.30)
	var armor = BOSS_ARMOR + (time_alive / 60.0) * 0.0016 + enemies_killed * 0.00006 + cards_bought.get("Coletora", 0) * 0.004
	if current_phase == 2:
		armor += 0.04
	if source == "veneno":
		armor += 0.10
	if source == "parasite_feast":
		armor = 0.0
	armor = min(0.88, armor)
	var final = max(1.0, amount * (1.0 - armor))
	if current_phase == 2 and _boss2_shield_active() and source != "parasite_feast":
		final = max(1.0, final * 0.10)
	if current_phase == 3 and boss3_stun_timer > 0.0 and source != "parasite_feast":
		final *= 1.35
	boss_hp = max(0.0, boss_hp - final)
	if current_phase == 1 and boss_hp > 0.0 and boss_hp <= boss_hp_max * BOSS1_RAIN_THRESHOLD:
		_start_boss1_rain()
	if source != "veneno" and poison_damage > 0.0 and boss_hp > 0.0:
		_apply_boss_poison()
	_add_text("-%d" % int(final), boss_pos + Vector2(rng.randf_range(-34, 34), -72), _damage_color(source), 0.65, 19)
	if current_phase == 1 and boss_hp > 0.0 and boss_hp < boss_hp_max * BOSS1_REWIND_THRESHOLD and boss1_rewind_cooldown <= 0.0:
		_start_boss1_time_wave()
		return
	var boss_executed = _boss_execute_threshold() > 0.0 and boss_hp <= boss_hp_max * _boss_execute_threshold()
	if boss_executed and boss_hp > 0.0:
		boss_hp = 0.0
		collector_hud_pulse = 1.2
		_add_text("COLETORA", boss_pos + Vector2(0, -116), Color(0.95, 0.08, 0.24), 1.4, 26)
	if boss_hp <= 0.0 and not boss_dead:
		boss_dead = true
		boss_active = false
		boss_poison_timer = 0.0
		boss_poison_tick = 0.0
		boss_parasite_seeds = 0
		boss_parasite_mark_time = 0.0
		var reward = 2600 if current_phase == 3 else (1800 if current_phase == 2 else 1100)
		score += reward
		score_total += reward
		_add_text("BOSS DISSOLVIDO", boss_pos + Vector2(0, -100), Color(1.0, 0.78, 0.25), 3.0, 34)
		if current_phase == 1:
			_spawn_phase_fragment(boss_pos, 2)
		elif current_phase == 2:
			_spawn_phase_fragment(boss_pos, 3)
		else:
			mode = "victory"


func _apply_boss_poison() -> void:
	boss_poison_timer = max(boss_poison_timer, 3.2)
	if boss_poison_tick <= 0.0:
		boss_poison_tick = 0.65


func _update_boss_poison(delta: float) -> void:
	if boss_poison_timer <= 0.0 or poison_damage <= 0.0 or boss_hp <= 0.0:
		return
	boss_poison_timer = max(0.0, boss_poison_timer - delta)
	boss_poison_tick -= delta
	if boss_poison_tick > 0.0:
		return
	boss_poison_tick = 0.65
	var poison_tick_damage = max(1.0, player_damage * poison_damage)
	_damage_boss(poison_tick_damage, "veneno")


func _boss_execute_threshold() -> float:
	if execute_threshold <= 0.0:
		return 0.0
	return min(execute_threshold * 0.20, 0.015)


func _kill_enemy(enemy: Dictionary) -> void:
	if not enemies.has(enemy):
		return
	var kill_pos: Vector2 = enemy["pos"]
	var shard_color = _enemy_shard_color(enemy)
	if String(enemy.get("type", "")) == ENEMY_DEVOTO:
		_add_phase3_miasma(kill_pos, 52.0, 2.0, 0.018)
	enemies.erase(enemy)
	enemies_killed += 1
	var gain = _points_for_enemy(enemy)
	var mercenary_level = int(cards_bought.get("Mercenaria", 0))
	if mercenary_level > 0:
		combo_kills += 1
		gain += mercenary_bonus_points
		if combo_kills % 5 == 0:
			var contract_value = 25 + 40 * mercenary_level
			mercenary_bonus_points = min(500, mercenary_bonus_points + contract_value)
			mercenary_hud_pulse = 1.0
			_add_text("MERCENARIA +%d" % mercenary_bonus_points, kill_pos + Vector2(0, -96), Color(1.0, 0.62, 0.16), 0.9, 19)
	score += gain
	score_total += gain
	_add_text("+%d" % gain, kill_pos + Vector2(0, -64), Color(1.0, 0.85, 0.18), 0.8, 18)
	_spawn_enemy_desfragmentation(kill_pos, shard_color, 14 + int(clamp(float(enemy.get("max_hp", 0.0)) / 18.0, 0.0, 12.0)))
	if enemy["type"] == ENEMY_AGGLOMERATOR:
		for i in range(2):
			_spawn_enemy(ENEMY_COMMON, kill_pos + Vector2.from_angle(rng.randf_range(0, TAU)) * 42.0)
	if enemy["type"] == ENEMY_CURATER:
		_spawn_heal_orb(kill_pos, 0.20)
		var heal = int((player_hp_max - player_hp) * 0.50)
		if heal > 0:
			player_hp = min(player_hp_max, player_hp + heal)
			_add_text("CURATER +%d" % heal, player_pos + Vector2(0, -78), Color(0.28, 1.0, 0.45), 1.0, 20)
	if enemy["type"] == ENEMY_LARAPIO:
		_spawn_heal_orb(kill_pos, 0.08)
		var returned = int(round(float(enemy.get("stolen", 0)) * 0.90))
		if returned > 0:
			_spawn_larapio_loot(kill_pos, returned)
			_add_text("MOEDAS NO CHAO", kill_pos + Vector2(0, -88), Color(1.0, 0.78, 0.24), 1.0, 20)
	if int(enemy.get("seeds", 0)) > 0:
		var spreads = 0
		for other in enemies:
			if other == enemy or float(other.get("hp", 0.0)) <= 0.0:
				continue
			if kill_pos.distance_to(other["pos"]) <= 180.0:
				other["seeds"] = min(5, int(other.get("seeds", 0)) + 1)
				other["parasite_mark_time"] = PARASITE_MARK_DURATION
				spreads += 1
				if spreads >= 2:
					break
		if spreads > 0:
			_spawn_radial_particles(kill_pos, Color(0.48, 1.0, 0.42), 10)
			_add_text("ESPALHOU x%d" % spreads, kill_pos + Vector2(0, -96), Color(0.58, 1.0, 0.46), 0.8, 18)
	if rng.randf() < _card_drop_chance():
		_spawn_heal_orb(kill_pos, 0.08)
	var threat = int(enemies_killed / 10)
	var mult = 1.0 + threat * 0.1
	enemy_base_hp += 0.62 * mult
	enemy_close_damage += 0.05 * mult
	enemy_far_damage += 0.015 * mult
	player_damage += 0.06 * mult
	enemy_speed_base = min(300.0, enemy_speed_base + 0.009)
	if not boss_active and not boss_dead:
		boss_hp_max += 6.0 * mult
		boss_hp += 6.0 * mult


func _points_for_enemy(enemy: Dictionary) -> int:
	var mult = clamp(1.35 + (time_alive / 60.0) * 0.14, 1.35, 4.4)
	return max(int(enemy.get("points", 20)), int(round(float(enemy.get("points", 20)) * mult)))


func _card_drop_chance() -> float:
	var progress = clamp(time_alive / (120.0 * 60.0), 0.0, 1.0)
	return clamp(0.045 + (0.40 - 0.045) * progress + luck * 0.25, 0.0, 0.70)


func _update_enemy_bullets(delta: float) -> void:
	for bullet in enemy_bullets:
		var slow_mult = _secondary_ancorada_projectile_slow_at(Vector2(bullet["pos"]))
		bullet["pos"] += bullet["dir"] * 210.0 * slow_mult * float(bullet.get("speed_mult", 1.0)) * delta
		bullet["life"] = float(bullet["life"]) - delta
		bullet["phase"] = float(bullet.get("phase", 0.0)) + delta * 9.0
		if String(bullet.get("type", "")) == "frost_shard":
			bullet["trail_cd"] = float(bullet.get("trail_cd", 0.0)) - delta
			if float(bullet["trail_cd"]) <= 0.0:
				bullet["trail_cd"] = 0.08
				_spawn_boss2_slow_zone(Vector2(bullet["pos"]), rng.randf_range(14.0, 20.0), 1.25)
		if bullet["pos"].distance_to(player_pos) < 34.0:
			var bullet_type = String(bullet.get("type", "projetador"))
			_damage_player(int(bullet["damage"]), bullet_type)
			if current_phase == 2:
				_apply_phase2_projectile_freeze()
			elif bullet_type == "rat_spit":
				player_stun_timer = max(player_stun_timer, 0.8)
				_add_phase3_miasma(Vector2(bullet["pos"]), 48.0, 1.9, 0.018)
				bullet["exploded"] = true
				_add_text("DOENCA", player_pos + Vector2(0, -44), Color(0.64, 1.0, 0.22), 0.9, 18)
			elif bullet_type == "larapio_coin" or bullet_type == "larapio_stone":
				_apply_larapio_projectile_hit(bullet)
			bullet["life"] = 0.0
		if float(bullet["life"]) <= 0.0 and String(bullet.get("type", "")) == "rat_spit" and not bool(bullet.get("exploded", false)):
			_add_phase3_miasma(Vector2(bullet["pos"]), 48.0, 1.9, 0.018)
			bullet["exploded"] = true
	enemy_bullets = enemy_bullets.filter(func(b): return float(b["life"]) > 0.0)


func _apply_larapio_projectile_hit(bullet: Dictionary) -> void:
	if _player_invulnerable():
		return
	player_stun_timer = max(player_stun_timer, LARAPIO_STUN_TIME)
	screen_shake_timer = max(screen_shake_timer, 0.22)
	screen_shake_strength = max(screen_shake_strength, 10.0)
	_vibrate(170, 0.62)
	_add_text("ATORDOADO 1.4s", player_pos + Vector2(0, -76), Color(1.0, 0.36, 0.28), 0.9, 19)
	for enemy in enemies:
		if int(enemy.get("uid", -999)) == int(bullet.get("owner_uid", -1)) and String(enemy.get("type", "")) == ENEMY_LARAPIO:
			enemy["alerted"] = true
			enemy["direct_steal"] = true
			enemy["steal_cd"] = 0.0
			enemy["throw_cd"] = LARAPIO_THROW_INTERVAL
			break


func _apply_phase2_projectile_freeze() -> void:
	if _player_invulnerable():
		return
	player_stun_timer = max(player_stun_timer, 1.0)
	_add_text("CONGELADO!", player_pos + Vector2(0, -42), Color(0.0, 0.88, 1.0), 1.0, 20)
	_spawn_radial_particles(player_pos, Color(0.62, 0.90, 1.0), 10)


func _update_boss2_environment(delta: float) -> void:
	if current_phase != 2 and boss2_ice_shards.is_empty() and boss2_snow_zones.is_empty() and boss2_frost_particles.is_empty():
		return
	var kept_shards = []
	for shard in boss2_ice_shards:
		shard["pos"] = Vector2(shard["pos"]) + Vector2(shard["vel"]) * delta
		shard["vel"] = Vector2(shard["vel"]) + Vector2(0, 260.0) * delta
		shard["life"] = float(shard["life"]) - delta
		if float(shard["life"]) > 0.0:
			kept_shards.append(shard)
	boss2_ice_shards = kept_shards
	var kept_zones = []
	for zone in boss2_snow_zones:
		zone["life"] = float(zone["life"]) - delta
		if float(zone["life"]) > 0.0:
			kept_zones.append(zone)
	boss2_snow_zones = kept_zones
	var kept_particles = []
	for particle in boss2_frost_particles:
		particle["pos"] = Vector2(particle["pos"]) + Vector2(particle["vel"]) * delta
		particle["life"] = float(particle["life"]) - delta
		if float(particle["life"]) > 0.0:
			kept_particles.append(particle)
	boss2_frost_particles = kept_particles


func _boss2_player_slow_mult() -> float:
	if current_phase != 2:
		return 1.0
	for zone in boss2_snow_zones:
		if player_pos.distance_to(Vector2(zone["pos"])) <= float(zone["radius"]):
			return BOSS2_SLOW_MULT
	return 1.0


func _environment_player_slow_mult() -> float:
	var mult = _boss2_player_slow_mult()
	if boss1_rain_active and weather_kind == "rain":
		for puddle in puddles:
			if player_pos.distance_to(Vector2(puddle["pos"])) <= float(puddle["r"]):
				mult = min(mult, WEATHER_PUDDLE_SLOW_MULT)
				break
	return mult


func _spawn_boss2_slow_zone(pos: Vector2, radius: float, life := BOSS2_SLOW_ZONE_TIME) -> void:
	if current_phase != 2:
		return
	boss2_snow_zones.append({
		"pos": pos.clamp(Vector2(40, 40), WORLD_SIZE - Vector2(40, 40)),
		"radius": radius,
		"life": life,
		"max": life,
		"phase": rng.randf_range(0.0, TAU)
	})
	if boss2_snow_zones.size() > 34:
		boss2_snow_zones.pop_front()


func _spawn_boss2_ice_burst(pos: Vector2, count: int, power := 1.0) -> void:
	for i in range(count):
		var angle = rng.randf_range(0.0, TAU)
		var speed = rng.randf_range(180.0, 520.0) * power
		boss2_ice_shards.append({
			"pos": pos,
			"vel": Vector2.from_angle(angle) * speed + Vector2(0, rng.randf_range(-260.0, -80.0) * power),
			"life": rng.randf_range(0.55, 1.2),
			"max": 1.2,
			"size": rng.randf_range(4.0, 11.0),
			"angle": angle
		})


func _spawn_boss2_frost_particle(pos: Vector2, dir: Vector2) -> void:
	var side = dir.orthogonal().normalized()
	boss2_frost_particles.append({
		"pos": pos + side * rng.randf_range(-26.0, 26.0),
		"vel": dir * rng.randf_range(240.0, 390.0) + side * rng.randf_range(-70.0, 70.0),
		"life": rng.randf_range(0.28, 0.58),
		"max": 0.58,
		"size": rng.randf_range(8.0, 18.0)
	})


func _spawn_boss2_frost_bullet(pos: Vector2, dir: Vector2, damage: float, speed := 5.8) -> void:
	enemy_bullets.append({
		"pos": pos,
		"dir": dir.normalized(),
		"life": 3.6,
		"damage": damage,
		"phase": rng.randf_range(0.0, TAU),
		"type": "frost_shard",
		"trail_cd": 0.0,
		"speed_mult": speed / 5.8
	})


func _update_orbitals(delta: float) -> void:
	for orbital in orbitals:
		orbital["life"] = float(orbital["life"]) - delta
		orbital["angle"] = float(orbital["angle"]) + delta * 5.5
		orbital["tick"] = float(orbital.get("tick", 0.0)) - delta
		var target_kind = String(orbital.get("target_kind", "enemy"))
		if target_kind == "boss":
			if boss_active and boss_hp > 0.0:
				orbital["origin_pos"] = boss_pos
				if float(orbital["tick"]) <= 0.0:
					orbital["tick"] = 0.62
					_damage_boss(float(orbital["damage"]) * 0.68, "gravitante_orbital")
			else:
				orbital["life"] = 0.0
			continue
		var enemy = _enemy_by_uid(int(orbital["enemy_uid"]))
		if enemy == null:
			enemy = _nearest_enemy_near(Vector2(orbital.get("origin_pos", player_pos)), GRAVITANTE_ORBITAL_TRANSFER_RADIUS)
			if enemy:
				orbital["enemy_uid"] = enemy["uid"]
			else:
				orbital["life"] = min(float(orbital["life"]), 0.35)
				continue
		orbital["origin_pos"] = Vector2(enemy["pos"])
		if float(orbital["tick"]) <= 0.0:
			orbital["tick"] = 0.62
			_damage_enemy(enemy, float(orbital["damage"]), "gravitante_orbital", false)
	orbitals = orbitals.filter(func(o): return float(o["life"]) > 0.0)


func _update_petrov(delta: float) -> void:
	if not petro_active:
		return
	petro_anim_time += delta
	petro_fire_timer = max(0.0, petro_fire_timer - delta)
	var target = _nearest_enemy_dict()
	if not target and boss_active and boss_hp > 0.0:
		target = {"pos": boss_pos, "boss": true}
	if not target:
		var rest_target = player_pos + Vector2(-68, 38)
		var rest_delta = rest_target - petro_pos
		if rest_delta.length() > 3.0:
			petro_pos += rest_delta.normalized() * min(rest_delta.length(), PETRO_MOVE_SPEED * delta)
			petro_facing = _companion_facing(rest_delta)
		else:
			petro_facing = "stop"
		return
	var target_pos = Vector2(target["pos"])
	var offset = target_pos - petro_pos
	petro_facing = _companion_facing(offset)
	if offset.length() > PETRO_ATTACK_RANGE:
		petro_pos += offset.normalized() * min(offset.length() - PETRO_ATTACK_RANGE, PETRO_MOVE_SPEED * delta)
		return
	if petro_fire_timer > 0.0:
		return
	petro_fire_timer = PETRO_ATTACK_INTERVAL
	if bool(target.get("boss", false)):
		petro_hp -= max(1.0, float(_boss_contact_damage()) - petro_defense)
		petro_hp += (petro_hp_max - petro_hp) * player_lifesteal
		_damage_boss(int(player_damage * 0.15) + petro_damage, "petro")
	else:
		petro_hp -= max(1.0, float(_enemy_damage(target)) - petro_defense)
		var killed = _damage_enemy(target, int(player_damage * 0.005) + petro_damage, "petro")
		if killed:
			petro_defense += 0.08
			petro_hp_max += 0.25
			petro_damage += 0.008
			_kill_enemy(target)
	petro_hp = min(petro_hp, petro_hp_max)
	if petro_hp <= 0.0:
		petro_active = false
		petro_hp = petro_hp_max
		_add_text("PETRO DESATIVADO", petro_pos + Vector2(0, -54), Color(0.36, 0.94, 1.0), 1.4, 21)
		_spawn_radial_particles(petro_pos, Color(0.24, 0.94, 1.0), 22)


func _update_trembo(delta: float) -> void:
	trembo_invulnerability = max(0.0, trembo_invulnerability - delta)
	if trembo_charges <= 0:
		return
	trembo_anim_time += delta
	if player_pos.x > WORLD_SIZE.x - 125.0:
		trembo_side = -1.0
	elif player_pos.x < 125.0:
		trembo_side = 1.0
	var target = player_pos + Vector2(62.0 * trembo_side, 18.0)
	var offset = target - trembo_pos
	if offset.length() > 2.0:
		trembo_pos += offset.normalized() * min(offset.length(), 240.0 * delta)
		trembo_facing = _companion_facing(offset)
	else:
		trembo_facing = "stop"
	var copies = max(1, int(cards_bought.get("Trembo", 1)))
	var heal_interval = max(0.45, TREMBO_HEAL_INTERVAL_BASE * pow(0.90, copies))
	var heal_ratio = TREMBO_HEAL_RATIO_BASE + (0.003 if copies == 1 else 0.011 + 0.008 * max(0, copies - 2))
	trembo_heal_timer -= delta
	if trembo_heal_timer <= 0.0 and player_hp < player_hp_max:
		trembo_heal_timer = heal_interval
		var heal = max(1, int(player_hp_max * heal_ratio))
		player_hp = min(player_hp_max, player_hp + heal)
		_add_text("+%d" % heal, trembo_pos + Vector2(0, -48), Color(0.42, 0.92, 1.0), 0.7, 17)
		_spawn_radial_particles(trembo_pos, Color(0.45, 0.88, 1.0), 7)


func _companion_facing(offset: Vector2) -> String:
	if abs(offset.x) > abs(offset.y):
		return "right" if offset.x > 0.0 else "left"
	return "down" if offset.y > 0.0 else "up"


func _boss_contact_damage() -> int:
	return max(18, int(player_hp_max * 0.08 + current_phase * 4.0))


func _update_shockwaves(delta: float) -> void:
	for wave in shockwaves:
		wave["life"] = float(wave["life"]) - delta
		wave["radius"] = lerp(float(wave["radius"]), float(wave["max"]), delta * 8.5)
		for enemy in enemies:
			var uid = str(enemy["uid"])
			if wave["hit"].has(uid):
				continue
			if enemy["pos"].distance_to(wave["pos"]) <= float(wave["radius"]):
				wave["hit"][uid] = true
				_damage_enemy(enemy, float(wave["damage"]), "eletrica")
		if boss_active and boss_pos.distance_to(wave["pos"]) <= float(wave["radius"]):
			_damage_boss(float(wave["damage"]) * 0.38, "eletrica")
	shockwaves = shockwaves.filter(func(w): return float(w["life"]) > 0.0)


func _update_manifestation_secondaries(delta: float) -> void:
	for secondary in manifestation_secondaries:
		var kind = String(secondary.get("kind", ""))
		var was_active = float(secondary.get("life", 0.0)) > 0.0
		if kind != "eletrica":
			secondary["life"] = max(0.0, float(secondary.get("life", 0.0)) - delta)
		match kind:
			"eletrica":
				_update_secondary_eletrica(secondary, delta)
			"lacerante":
				_update_secondary_lacerante(secondary, delta)
			"prismatica":
				_update_secondary_prismatica(secondary, delta)
			"retornante":
				_update_secondary_retornante(secondary, delta)
			"parasitica":
				_update_secondary_parasitica(secondary, delta)
			"gravitante":
				_update_secondary_gravitante(secondary, delta)
			"ancorada":
				_update_secondary_ancorada(secondary, delta)
		if was_active and float(secondary.get("life", 0.0)) <= 0.0:
			if kind == "eletrica":
				_finish_toggle_secondary(secondary, "ANEL ENCERRADO", Color(0.52, 0.88, 1.0))
			elif kind == "prismatica":
				_finish_toggle_secondary(secondary, "COROA ENCERRADA", Color(0.64, 1.0, 0.96), false)
	manifestation_secondaries = manifestation_secondaries.filter(func(s): return float(s.get("life", 0.0)) > 0.0)


func _update_secondary_eletrica(secondary: Dictionary, delta: float) -> void:
	var previous_active_time = float(secondary.get("active_time", 0.0))
	var active_time = previous_active_time + delta
	secondary["active_time"] = active_time
	var drain_delta = max(0.0, active_time - SECONDARY_ELETRICA_DRAIN_DELAY) - max(0.0, previous_active_time - SECONDARY_ELETRICA_DRAIN_DELAY)
	secondary["health_drain_timer"] = float(secondary.get("health_drain_timer", 0.0)) + drain_delta
	while float(secondary["health_drain_timer"]) >= 1.0:
		secondary["health_drain_timer"] = float(secondary["health_drain_timer"]) - 1.0
		var drain_carry = float(secondary.get("health_drain_carry", 0.0)) + player_hp_max * SECONDARY_ELETRICA_DRAIN_RATE
		var drain_damage = maxi(1, int(floor(drain_carry)))
		secondary["health_drain_carry"] = max(0.0, drain_carry - float(drain_damage))
		player_hp = max(0, player_hp - drain_damage)
		_add_text("-%d VIDA" % drain_damage, player_pos + Vector2(0, -82), Color(0.42, 0.86, 1.0), 0.65, 17)
	var ring_radius = 150.0 + sin((time_alive + active_time * 0.12) * 6.2) * 18.0
	var touching = []
	var has_target_in_radius = false
	for enemy in enemies:
		var dist = enemy["pos"].distance_to(player_pos)
		if dist <= ring_radius + 42.0:
			has_target_in_radius = true
		if abs(dist - ring_radius) <= 42.0 or dist <= ring_radius * 0.48:
			touching.append(enemy)
	var boss_touching = false
	var boss_in_radius = false
	if boss_active and boss_hp > 0.0:
		var boss_dist = boss_pos.distance_to(player_pos)
		boss_in_radius = boss_dist <= ring_radius + 68.0
		boss_touching = abs(boss_dist - ring_radius) <= 68.0 or boss_dist <= ring_radius * 0.46
	if not has_target_in_radius and not boss_in_radius:
		secondary["empty_time"] = float(secondary.get("empty_time", 0.0)) + delta
		if float(secondary["empty_time"]) >= 3.0:
			_finish_toggle_secondary(secondary, "ANEL SEM ALVOS", Color(0.52, 0.88, 1.0))
			return
	else:
		secondary["empty_time"] = 0.0
	var bonus_step = max(0, int(floor(active_time - 10.0)))
	if bonus_step > int(secondary.get("bonus_step", 0)):
		secondary["bonus_step"] = bonus_step
		_add_text("TESLA +%d%%" % (bonus_step * 2), player_pos + Vector2(0, -108), Color(0.74, 1.0, 1.0), 0.65, 17)
	var damage_multiplier = 1.0 + float(bonus_step) * 0.02
	secondary["tick"] = float(secondary.get("tick", 0.0)) - delta
	if float(secondary["tick"]) > 0.0:
		return
	secondary["tick"] = 0.36
	for enemy in enemies:
		var dist = enemy["pos"].distance_to(player_pos)
		if abs(dist - ring_radius) <= 42.0 or dist <= ring_radius * 0.48:
			enemy["stun"] = max(float(enemy.get("stun", 0.0)), 0.26)
			_damage_enemy(enemy, player_damage * 1.05 * damage_multiplier, "eletrica", false)
	if touching.size() > 1:
		var links = min(3, touching.size())
		for i in range(links):
			var origem = touching[i]
			var alvo = touching[(i + 1) % touching.size()]
			if origem != alvo:
				_damage_enemy(alvo, player_damage * 0.62 * damage_multiplier, "eletrica", false)
	if boss_touching:
		_damage_boss(player_damage * 0.52 * damage_multiplier, "eletrica")


func _spawn_lacerante_secondary_cut(secondary: Dictionary) -> void:
	var center: Vector2 = secondary.get("center", player_pos)
	var idx = int(secondary.get("cut_index", 0))
	var seed = int(secondary.get("seed", 0))
	var angle = float(seed) * 0.001 + idx * 2.399 + rng.randf_range(-0.28, 0.28)
	var length = rng.randf_range(250.0, 370.0)
	var lateral = rng.randf_range(-55.0, 55.0)
	var normal = Vector2.from_angle(angle + PI * 0.5)
	var dir = Vector2.from_angle(angle)
	var start = center + normal * lateral - dir * length * 0.45
	var finish = center + normal * lateral + dir * length * 0.55
	var cut = {
		"a": start,
		"b": finish,
		"life": 0.36,
		"max": 0.36
	}
	secondary["cuts"].append(cut)
	secondary["cut_index"] = idx + 1
	for enemy in enemies:
		if _distance_to_segment(enemy["pos"], start, finish) <= 84.0:
			var lacerated = int(enemy.get("laceracao", 0)) > 0
			var damage = max(enemy["max_hp"] * (0.10 if lacerated else 0.06), player_damage * (1.15 if lacerated else 0.65))
			_damage_enemy(enemy, damage, "lacerante", false)
			if lacerated:
				enemy["laceracao"] = 0
				enemy["bleed_timer"] = 0.0
	if boss_active and boss_hp > 0.0 and _distance_to_segment(boss_pos, start, finish) <= 128.0:
		_damage_boss(player_damage * 1.20, "lacerante")


func _update_secondary_lacerante(secondary: Dictionary, delta: float) -> void:
	player_pos = Vector2(secondary.get("center", player_pos))
	secondary["cut_timer"] = float(secondary.get("cut_timer", 0.0)) - delta
	var max_cuts = int(secondary.get("max_cuts", 15))
	var interval = SECONDARY_LACERANTE_DURATION / max(1.0, float(max_cuts))
	var generated = 0
	while float(secondary["cut_timer"]) <= 0.0 and generated < 3 and float(secondary.get("life", 0.0)) > 0.0 and int(secondary.get("cut_index", 0)) < max_cuts:
		secondary["cut_timer"] = float(secondary.get("cut_timer", 0.0)) + interval
		_spawn_lacerante_secondary_cut(secondary)
		generated += 1
	var alive_cuts = []
	for cut in secondary.get("cuts", []):
		cut["life"] = max(0.0, float(cut.get("life", 0.0)) - delta)
		if float(cut["life"]) > 0.0:
			alive_cuts.append(cut)
	secondary["cuts"] = alive_cuts


func _circle_polyline_points(center: Vector2, radius: float, segments: int = 24) -> Array:
	var pts = []
	for i in range(segments + 1):
		var ang = float(i) / float(segments) * TAU
		pts.append(center + Vector2.from_angle(ang) * radius)
	return pts


func _calculate_secondary_ricochet_segments(origin: Vector2, angle: float, ricochets: int, total_length: float) -> Array:
	var segments: Array = []
	var pos = origin
	var dir = Vector2.from_angle(angle).normalized()
	var remaining = total_length
	var bounces_left = ricochets
	while remaining > 0.1:
		var tx = INF
		var ty = INF
		if abs(dir.x) > 0.001:
			tx = ((WORLD_SIZE.x if dir.x > 0.0 else 0.0) - pos.x) / dir.x
		if abs(dir.y) > 0.001:
			ty = ((WORLD_SIZE.y if dir.y > 0.0 else 0.0) - pos.y) / dir.y
		var distance_to_wall = min(tx, ty)
		if distance_to_wall == INF or distance_to_wall == -INF or distance_to_wall <= 0.001:
			distance_to_wall = remaining
		var step = min(remaining, distance_to_wall)
		var next = pos + dir * step
		next = next.clamp(Vector2.ZERO, WORLD_SIZE)
		segments.append({"a": pos, "b": next})
		remaining -= step
		if step + 0.01 < distance_to_wall or bounces_left <= 0:
			break
		if abs(step - tx) <= 0.06:
			dir.x = -dir.x
		if abs(step - ty) <= 0.06:
			dir.y = -dir.y
		pos = next.clamp(Vector2(1.0, 1.0), WORLD_SIZE - Vector2(1.0, 1.0))
		bounces_left -= 1
	return segments


func _spawn_secondary_prismatica_beams(secondary: Dictionary) -> void:
	var center: Vector2 = secondary.get("center", player_pos)
	var beams = secondary.get("beams", [])
	var base = time_alive * 0.95 + int(secondary.get("beam_index", 0)) * 0.19
	var colors = [
		Color(0.32, 1.0, 0.96),
		Color(1.0, 0.45, 0.72),
		Color(0.72, 0.42, 1.0),
		Color(1.0, 0.88, 0.42)
	]
	for i in range(10):
		var angle = base + i * TAU / 10.0
		var segments = _calculate_secondary_ricochet_segments(center, angle, 2, 460.0)
		var beam = {
			"id": int(secondary.get("beam_index", 0)) * 100 + i,
			"life": 0.28,
			"max": 0.28,
			"color": colors[i % colors.size()],
			"segments": segments
		}
		beams.append(beam)
		for enemy in enemies:
			if float(enemy.get("hp", 0.0)) <= 0.0:
				continue
			for segment in segments:
				if _distance_to_segment(enemy["pos"], segment["a"], segment["b"]) <= 20.0:
					_damage_enemy(enemy, player_damage * 0.54, "prismatica", false)
					break
		if boss_active and boss_hp > 0.0:
			for segment in segments:
				if _distance_to_segment(boss_pos, segment["a"], segment["b"]) <= 74.0:
					_damage_boss(player_damage * 0.30, "prismatica")
					break
	secondary["beam_index"] = int(secondary.get("beam_index", 0)) + 1
	secondary["beams"] = beams


func _update_secondary_prismatica(secondary: Dictionary, delta: float) -> void:
	var center: Vector2 = secondary.get("center", player_pos)
	secondary["angle"] = fposmod(float(secondary.get("angle", 0.0)) + SECONDARY_PRISMATICA_BEAM_SPIN_SPEED * delta, TAU)
	var beam_dirs = _secondary_prismatica_beam_dirs(float(secondary["angle"]))
	var hit_times: Dictionary = secondary.get("spin_hit_times", {})
	for enemy in enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var uid = str(enemy.get("uid", 0))
		for dir in beam_dirs:
			var a = center - dir * SECONDARY_PRISMATICA_BEAM_RANGE
			var b = center + dir * SECONDARY_PRISMATICA_BEAM_RANGE
			if _distance_to_segment(enemy["pos"], a, b) <= SECONDARY_PRISMATICA_BEAM_WIDTH + _enemy_radius(enemy) * 0.55:
				if time_alive - float(hit_times.get(uid, -999.0)) >= SECONDARY_PRISMATICA_HIT_INTERVAL:
					hit_times[uid] = time_alive
					_damage_enemy(enemy, player_damage * 0.34 + float(enemy.get("max_hp", enemy_base_hp)) * 0.012, "prismatica", false)
				break
	secondary["spin_hit_times"] = hit_times
	if boss_active and boss_hp > 0.0:
		for dir in beam_dirs:
			var a = center - dir * SECONDARY_PRISMATICA_BEAM_RANGE
			var b = center + dir * SECONDARY_PRISMATICA_BEAM_RANGE
			if _distance_to_segment(boss_pos, a, b) <= SECONDARY_PRISMATICA_BEAM_WIDTH + 72.0:
				if time_alive - float(secondary.get("boss_spin_hit", -999.0)) >= SECONDARY_PRISMATICA_HIT_INTERVAL:
					secondary["boss_spin_hit"] = time_alive
					_damage_boss(player_damage * 0.20 + boss_hp_max * 0.0012, "prismatica")
				break


func _secondary_prismatica_beam_dirs(angle: float) -> Array:
	return [
		Vector2.from_angle(angle),
		Vector2.from_angle(angle + PI * 0.5),
		Vector2.from_angle(angle + PI * 0.25),
		Vector2.from_angle(angle - PI * 0.25)
	]


func _ensure_secondary_retornante_targets(secondary: Dictionary) -> void:
	if bool(secondary.get("marked", false)):
		return
	secondary["marked"] = true
	var found = false
	for bullet in return_bullets:
		bullet["paradox_until"] = time_alive + float(secondary.get("life", SECONDARY_RETORNANTE_DURATION))
		bullet["paradox_cycles"] = 0
		bullet["paradox_hit_tick"] = 0.0
		found = true
	if found:
		return
	var ghosts = []
	for i in range(5):
		var angle = i * TAU / 5.0 + rng.randf_range(-0.20, 0.20)
		ghosts.append({
			"base_angle": angle,
			"radius_x": 260.0,
			"radius_y": 210.0,
			"phase": rng.randf_range(0.0, TAU)
		})
	secondary["ghosts"] = ghosts


func _update_secondary_retornante(secondary: Dictionary, delta: float) -> void:
	_ensure_secondary_retornante_targets(secondary)
	secondary["line_tick"] = float(secondary.get("line_tick", 0.0)) - delta
	secondary["ghost_tick"] = float(secondary.get("ghost_tick", 0.0)) + delta
	if float(secondary["line_tick"]) <= 0.0:
		secondary["line_tick"] = 0.41
		for bullet in return_bullets:
			if float(bullet.get("paradox_until", 0.0)) < time_alive:
				continue
			var cycles = min(2, int(bullet.get("paradox_cycles", 0)))
			var mults = [1.25, 1.0, 0.82]
			var mult = mults[cycles]
			for enemy in enemies:
				if float(enemy.get("hp", 0.0)) <= 0.0:
					continue
				if _distance_to_segment(enemy["pos"], player_pos, bullet["pos"]) <= 34.0:
					_damage_enemy(enemy, player_damage * mult, "retornante", false)
			if boss_active and boss_hp > 0.0 and _distance_to_segment(boss_pos, player_pos, bullet["pos"]) <= 84.0:
				_damage_boss(player_damage * 0.55 * mult, "retornante")
			bullet["paradox_cycles"] = cycles + 1
		for ghost in secondary.get("ghosts", []):
			var ang = float(ghost.get("base_angle", 0.0)) + float(secondary.get("ghost_tick", 0.0)) * 0.9
			var endpoint = player_pos + Vector2(cos(ang) * float(ghost.get("radius_x", 260.0)), sin(ang + float(ghost.get("phase", 0.0)) * 0.18) * float(ghost.get("radius_y", 210.0)))
			for enemy in enemies:
				if float(enemy.get("hp", 0.0)) <= 0.0:
					continue
				if _distance_to_segment(enemy["pos"], player_pos, endpoint) <= 32.0:
					_damage_enemy(enemy, player_damage * 0.78, "retornante", false)
			if boss_active and boss_hp > 0.0 and _distance_to_segment(boss_pos, player_pos, endpoint) <= 82.0:
				_damage_boss(player_damage * 0.34, "retornante")
	var progress = 1.0 - float(secondary.get("life", 0.0)) / max(0.01, float(secondary.get("max", SECONDARY_RETORNANTE_DURATION)))
	if progress >= 0.88 and not bool(secondary.get("forced_final", false)):
		secondary["forced_final"] = true
		for bullet in return_bullets:
			if float(bullet.get("paradox_until", 0.0)) < time_alive:
				continue
			bullet["state"] = "volta"
			bullet["returning"] = true
			bullet["forced"] = true
			bullet["damage"] = float(bullet.get("damage", player_damage * 0.62)) * 1.35
			bullet["paradox_final"] = true
			bullet["paradox_until"] = time_alive + 0.45


func _update_secondary_parasitica(secondary: Dictionary, delta: float) -> void:
	var active_targets = 0
	for target in secondary.get("targets", []):
		if bool(target.get("done", false)):
			continue
		var target_pos = _parasite_ultimate_target_pos(target)
		if target_pos == Vector2.ZERO:
			target["done"] = true
			continue
		active_targets += 1
		target["age"] = float(target.get("age", 0.0)) + delta
		if not bool(target.get("arrived", false)):
			if float(target["age"]) >= float(target.get("arrival", 1.95)):
				target["arrived"] = true
				target["feed_left"] = PARASITE_FEAST_DURATION
				target["tick"] = 1.0
				_spawn_radial_particles(target_pos + Vector2(0, 22), Color(0.52, 0.90, 0.22), 22)
				_add_text("INFESTADO", target_pos + Vector2(0, -72), Color(0.72, 1.0, 0.36), 1.0, 19)
			continue
		target["feed_left"] = max(0.0, float(target.get("feed_left", 0.0)) - delta)
		if not bool(target.get("boss", false)):
			var slowed_enemy = _enemy_by_uid(int(target.get("uid", -1)))
			if slowed_enemy:
				slowed_enemy["parasite_slow_time"] = max(0.20, float(slowed_enemy.get("parasite_slow_time", 0.0)))
		target["tick"] = float(target.get("tick", 0.0)) - delta
		if float(target["tick"]) <= 0.0:
			target["tick"] = 1.0
			if bool(target.get("boss", false)):
				_damage_boss(boss_hp * 0.05, "parasite_feast")
			else:
				var enemy = _enemy_by_uid(int(target.get("uid", -1)))
				if enemy:
					_damage_enemy(enemy, max(1.0, float(enemy["hp"]) * 0.05), "parasite_feast", true)
			_spawn_radial_particles(target_pos, Color(0.66, 1.0, 0.26), 7)
		if float(target["feed_left"]) <= 0.0:
			target["done"] = true
	if active_targets <= 0:
		secondary["life"] = 0.0


func _parasite_ultimate_target_pos(target: Dictionary) -> Vector2:
	if bool(target.get("boss", false)):
		return boss_pos if boss_active and boss_hp > 0.0 else Vector2.ZERO
	var enemy = _enemy_by_uid(int(target.get("uid", -1)))
	return Vector2(enemy["pos"]) if enemy else Vector2.ZERO


func _update_secondary_gravitante(secondary: Dictionary, delta: float) -> void:
	var progress = 1.0 - float(secondary.get("life", 0.0)) / max(0.01, float(secondary.get("max", SECONDARY_GRAVITANTE_DURATION)))
	var center: Vector2 = secondary.get("center", player_pos)
	var radius = _gravitante_radius(progress)
	var captured = 0
	var orbital_bonus = 0
	for bullet in bullets:
		if String(bullet.get("kind", "")) != "gravitante":
			continue
		if Vector2(bullet["pos"]).distance_to(center) <= radius + 120.0:
			orbital_bonus += 1
			var dx = center.x - float(bullet["pos"].x)
			var dy = center.y - float(bullet["pos"].y)
			var dist = max(1.0, sqrt(dx * dx + dy * dy))
			var radial = Vector2(dx, dy) / dist
			var tangential = Vector2(-radial.y, radial.x)
			bullet["dir"] = (Vector2(bullet["dir"]) + radial * 0.22 + tangential * 0.14).normalized()
			bullet["pos"] += radial * 11.0 * delta * 60.0 + tangential * 7.0 * delta * 60.0
	for enemy in enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var dist = Vector2(enemy["pos"]).distance_to(center)
		if dist <= radius:
			captured += 1
	var capture_power = clamp(float(captured) / 8.0 + float(orbital_bonus) / 12.0, 0.0, 2.2)
	var spin_speed = 250.0 + progress * 95.0 + float(captured) * 28.0 + float(orbital_bonus) * 13.0
	var pull_speed = 18.0 + progress * 16.0 + capture_power * 11.0
	for enemy in enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var dist = Vector2(enemy["pos"]).distance_to(center)
		if dist <= radius:
			var radial = (center - Vector2(enemy["pos"])) / max(1.0, dist)
			var tangential = Vector2(-radial.y, radial.x)
			var edge_ratio = _gravitante_edge_ratio(dist, radius)
			var rim_drag = 0.62 + edge_ratio * 0.95
			enemy["pos"] += radial * pull_speed * delta * (0.38 + (1.0 - edge_ratio) * 0.55)
			enemy["pos"] += tangential * spin_speed * rim_drag * delta
			enemy["pos"] = enemy["pos"].clamp(Vector2(40, 40), WORLD_SIZE - Vector2(40, 40))
			enemy["stun"] = max(float(enemy.get("stun", 0.0)), 0.11 + capture_power * 0.03)
	secondary["captured"] = captured
	secondary["orbital_bonus"] = orbital_bonus
	secondary["capture_power"] = capture_power
	secondary["spin_speed"] = spin_speed
	secondary["edge_damage"] = 1.0 + capture_power * 0.42
	secondary["pulse_tick"] = float(secondary.get("pulse_tick", 0.0)) - delta
	if float(secondary["pulse_tick"]) <= 0.0:
		secondary["pulse_tick"] = max(0.18, 0.36 - capture_power * 0.045)
		var colapse = progress >= 0.86
		var capture_bonus = 1.0 + min(1.75, float(captured + orbital_bonus) * 0.085)
		for enemy in enemies:
			if float(enemy.get("hp", 0.0)) <= 0.0:
				continue
			var dist = Vector2(enemy["pos"]).distance_to(center)
			if dist <= radius + (92.0 if colapse else 0.0):
				var active_radius = radius + (92.0 if colapse else 0.0)
				var edge_ratio = _gravitante_edge_ratio(dist, active_radius)
				var event_horizon_mult = lerp(0.55, 2.25 + capture_power * 0.35, edge_ratio)
				var collapse_mult = 3.35 if colapse else 0.92
				var mult = collapse_mult * capture_bonus * event_horizon_mult
				_damage_enemy(enemy, player_damage * mult, "gravitante", false)
		if boss_active and boss_hp > 0.0 and boss_pos.distance_to(center) <= radius + 100.0:
			var boss_edge_ratio = _gravitante_edge_ratio(boss_pos.distance_to(center), radius + 100.0)
			var boss_edge_mult = lerp(0.72, 1.85 + capture_power * 0.22, boss_edge_ratio)
			_damage_boss(player_damage * (0.58 if not colapse else 1.55) * capture_bonus * boss_edge_mult, "gravitante")


func _gravitante_radius(progress: float) -> float:
	return 330.0 * (1.0 - progress * 0.22)


func _gravitante_edge_ratio(dist: float, radius: float) -> float:
	return clamp(dist / max(1.0, radius), 0.0, 1.0)


func _update_secondary_ancorada(secondary: Dictionary, delta: float) -> void:
	var center: Vector2 = secondary.get("center", player_pos)
	var radius = 220.0
	if player_pos.distance_to(center) <= radius:
		secondary["charge"] = min(SECONDARY_ANCORADA_DURATION, float(secondary.get("charge", 0.0)) + delta)
	secondary["pulse_tick"] = float(secondary.get("pulse_tick", 0.0)) - delta
	var charge_ratio = clamp(float(secondary.get("charge", 0.0)) / SECONDARY_ANCORADA_DURATION, 0.0, 1.0)
	if float(secondary["pulse_tick"]) <= 0.0:
		secondary["pulse_tick"] = 0.62
		for enemy in enemies:
			if float(enemy.get("hp", 0.0)) <= 0.0:
				continue
			var dist = Vector2(enemy["pos"]).distance_to(center)
			if dist <= radius:
				var push = (Vector2(enemy["pos"]) - center).normalized()
				if push.length() <= 0.01:
					push = Vector2.RIGHT
				enemy["pos"] += push * (5.0 + charge_ratio * 7.0)
				enemy["pos"] = enemy["pos"].clamp(Vector2(40, 40), WORLD_SIZE - Vector2(40, 40))
				_damage_enemy(enemy, player_damage * (0.40 + charge_ratio * 0.55), "ancorada", false)
		if boss_active and boss_hp > 0.0 and boss_pos.distance_to(center) <= radius:
			_damage_boss(player_damage * (0.24 + charge_ratio * 0.32), "ancorada")
	var progress = 1.0 - float(secondary.get("life", 0.0)) / max(0.01, float(secondary.get("max", SECONDARY_ANCORADA_DURATION)))
	if progress >= 0.90 and not bool(secondary.get("final_wave", false)):
		secondary["final_wave"] = true
		for enemy in enemies:
			if float(enemy.get("hp", 0.0)) <= 0.0:
				continue
			if Vector2(enemy["pos"]).distance_to(center) <= radius * 1.22:
				_damage_enemy(enemy, player_damage * (1.8 + charge_ratio * 4.2), "ancorada", false)
		if boss_active and boss_hp > 0.0 and boss_pos.distance_to(center) <= radius * 1.25:
			_damage_boss(player_damage * (0.75 + charge_ratio * 1.4), "ancorada")


func _update_heal_orbs(delta: float) -> void:
	for orb in heal_orbs:
		orb["life"] = float(orb["life"]) - delta
		if orb["pos"].distance_to(player_pos) < 58.0:
			var heal = int((player_hp_max - player_hp) * float(orb["fraction"]))
			if heal > 0:
				player_hp = min(player_hp_max, player_hp + heal)
				_add_text("+%d" % heal, player_pos + Vector2(0, -64), Color(0.36, 1.0, 0.46), 0.8, 18)
			orb["life"] = 0.0
	heal_orbs = heal_orbs.filter(func(o): return float(o["life"]) > 0.0)


func _spawn_heal_orb(pos: Vector2, fraction: float) -> void:
	heal_orbs.append({"pos": pos, "fraction": fraction, "life": 12.0, "phase": rng.randf_range(0.0, TAU)})


func _capture_boss1_rewind_projectiles() -> Array:
	var captured = []
	for bullet in bullets:
		if captured.size() >= 24:
			break
		captured.append({
			"visual": "player",
			"kind": String(bullet.get("kind", "eletrica")),
			"pos": Vector2(bullet.get("pos", player_pos)),
			"dir": Vector2(bullet.get("dir", last_facing))
		})
	for bullet in return_bullets:
		if captured.size() >= 30:
			break
		captured.append({
			"visual": "returning",
			"kind": "retornante",
			"pos": Vector2(bullet.get("pos", player_pos)),
			"dir": Vector2(bullet.get("dir", last_facing))
		})
	for bullet in enemy_bullets:
		if captured.size() >= 36:
			break
		captured.append({
			"visual": "enemy",
			"kind": String(bullet.get("type", "enemy")),
			"pos": Vector2(bullet.get("pos", boss_pos)),
			"dir": Vector2(bullet.get("dir", Vector2.DOWN))
		})
	for wave in shockwaves:
		if captured.size() >= 40:
			break
		captured.append({"visual": "shockwave", "pos": Vector2(wave.get("pos", player_pos)), "radius": float(wave.get("radius", 0.0))})
	for prism in prisms:
		if captured.size() >= 44:
			break
		captured.append({"visual": "prism", "pos": Vector2(prism.get("pos", player_pos))})
	for wave in boss_transition_waves:
		if captured.size() >= 47:
			break
		captured.append({"visual": "boss_wave", "pos": Vector2(wave.get("pos", boss_pos)), "radius": float(wave.get("radius", 0.0))})
	return captured


func _capture_boss1_rewind_snapshot() -> Dictionary:
	return {
		"time": time_alive,
		"elapsed": elapsed_unpaused,
		"player_pos": player_pos,
		"boss_pos": boss_pos,
		"player_hp": player_hp,
		"last_facing": last_facing,
		"last_attack": last_attack_time,
		"last_dash": last_dash_time,
		"last_skill": last_skill_time,
		"last_secondary": last_secondary_time,
		"last_damage": last_damage_time,
		"boss_phase": boss_phase,
		"boss_attack_timer": boss_attack_timer,
		"projectiles": _capture_boss1_rewind_projectiles()
	}


func _record_boss1_rewind_history(delta: float) -> void:
	if not boss1_rewind_sequence.is_empty():
		return
	boss1_rewind_sample_timer += delta
	if not boss1_rewind_history.is_empty() and boss1_rewind_sample_timer < BOSS1_REWIND_SAMPLE_INTERVAL:
		return
	boss1_rewind_sample_timer = fmod(boss1_rewind_sample_timer, BOSS1_REWIND_SAMPLE_INTERVAL)
	boss1_rewind_history.append(_capture_boss1_rewind_snapshot())
	var cutoff = time_alive - BOSS1_REWIND_SECONDS - BOSS1_REWIND_SAMPLE_INTERVAL
	while boss1_rewind_history.size() > 1 and float(boss1_rewind_history[0].get("time", time_alive)) < cutoff:
		boss1_rewind_history.pop_front()


func _chrono_variant_name(variant: int) -> String:
	match variant:
		1:
			return "CRONO-FENDA DUPLA"
		2:
			return "ESPIRAL DE 11:10"
		3:
			return "PONTEIROS PARTIDOS"
	return "ONDA DE RETROCESSO"


func _chrono_variant_color(variant: int) -> Color:
	match variant:
		1:
			return Color(1.0, 0.44, 0.78)
		2:
			return Color(0.72, 0.52, 1.0)
		3:
			return Color(1.0, 0.78, 0.30)
	return Color(0.36, 0.94, 1.0)


func _start_boss1_time_wave() -> void:
	if current_phase != 1 or boss1_rewind_cooldown > 0.0 or boss_dead or boss_hp <= 0.0 or boss_hp >= boss_hp_max * BOSS1_REWIND_THRESHOLD:
		return
	boss1_rewind_cooldown = BOSS1_REWIND_COOLDOWN
	boss_stage_timer = 0.0
	boss_attacks.clear()
	boss_transition_waves.clear()
	if boss1_rewind_history.is_empty() or time_alive - float(boss1_rewind_history[-1].get("time", -999.0)) > 0.02:
		boss1_rewind_history.append(_capture_boss1_rewind_snapshot())
	var origin = boss_pos
	var max_radius = 0.0
	for corner in [Vector2.ZERO, Vector2(WORLD_SIZE.x, 0.0), Vector2(0.0, WORLD_SIZE.y), WORLD_SIZE]:
		max_radius = max(max_radius, origin.distance_to(corner))
	var variant = rng.randi_range(0, 3)
	boss1_time_wave = {
		"origin": origin,
		"radius": 48.0,
		"direction": 1.0,
		"max_radius": max_radius + 48.0,
		"age": 0.0,
		"variant": variant
	}
	boss_pos = origin
	screen_shake_timer = 0.18
	screen_shake_strength = 7.0
	_vibrate(70, 0.24)
	_add_text(_chrono_variant_name(variant), boss_pos + Vector2(0, -126), _chrono_variant_color(variant), 2.0, 28)
	_spawn_radial_particles(boss_pos, Color(0.34, 0.84, 1.0), 32)


func _update_boss1_time_wave(delta: float) -> void:
	if boss1_time_wave.is_empty():
		return
	boss_pos = Vector2(boss1_time_wave["origin"])
	boss1_time_wave["age"] = float(boss1_time_wave.get("age", 0.0)) + delta
	if float(boss1_time_wave["age"]) < BOSS1_TIME_WAVE_WARNING:
		return
	var previous_radius = float(boss1_time_wave["radius"])
	var direction = float(boss1_time_wave["direction"])
	var next_radius = previous_radius + direction * BOSS1_TIME_WAVE_SPEED * delta
	var max_radius = float(boss1_time_wave["max_radius"])
	if direction > 0.0 and next_radius >= max_radius:
		next_radius = max_radius
		boss1_time_wave["direction"] = -1.0
		screen_shake_timer = 0.20
		screen_shake_strength = 9.0
		_add_text("A ONDA ESTA VOLTANDO", boss_pos + Vector2(0, -112), Color(1.0, 0.34, 0.72), 1.4, 22)
	elif direction < 0.0 and next_radius <= 34.0:
		boss1_time_wave.clear()
		boss_attack_timer = 1.6
		_add_text("LINHA TEMPORAL EVITADA", boss_pos + Vector2(0, -108), Color(0.42, 1.0, 0.78), 1.2, 21)
		return
	boss1_time_wave["radius"] = next_radius
	var player_distance = player_pos.distance_to(Vector2(boss1_time_wave["origin"]))
	var swept_min = min(previous_radius, next_radius) - BOSS1_TIME_WAVE_WIDTH - 22.0
	var swept_max = max(previous_radius, next_radius) + BOSS1_TIME_WAVE_WIDTH + 22.0
	if player_distance >= swept_min and player_distance <= swept_max:
		_start_boss1_rewind_sequence()


func _start_boss1_rewind_sequence() -> void:
	if not boss1_rewind_sequence.is_empty():
		return
	if boss1_rewind_history.is_empty():
		boss1_rewind_history.append(_capture_boss1_rewind_snapshot())
	elif time_alive - float(boss1_rewind_history[-1].get("time", -999.0)) > 0.02:
		boss1_rewind_history.append(_capture_boss1_rewind_snapshot())
	var chrono_variant = int(boss1_time_wave.get("variant", rng.randi_range(0, 3)))
	boss1_time_wave.clear()
	boss_attacks.clear()
	boss_transition_waves.clear()
	effects.clear()
	boss1_rewind_visual_projectiles = Array(boss1_rewind_history[-1].get("projectiles", [])).duplicate(true)
	boss1_rewind_sequence = {
		"elapsed": 0.0,
		"variant": chrono_variant,
		"boss_heal": (boss_hp_max - boss_hp) * BOSS1_REWIND_BOSS_HEAL,
		"player_final_hp": min(player_hp_max, player_hp + (player_hp_max - player_hp) * BOSS1_REWIND_PLAYER_HEAL)
	}
	pointer_down = false
	active_screen_touches.clear()
	move_touch_index = -1
	attack_touch_index = -1
	attack_drag_touch_index = -1
	skill_touch_index = -1
	secondary_touch_index = -1
	dash_touch_index = -1
	touch_move = Vector2.ZERO
	attack_holding = false
	attack_dragging = false
	screen_shake_timer = 0.16
	screen_shake_strength = 6.0
	_vibrate(110, 0.35)
	boss1_rewind_vibration_timer = 0.0
	boss1_rewind_clock_tick = -1
	_add_text("TEMPO CAPTURADO", player_pos + Vector2(0, -102), Color(0.48, 0.92, 1.0), 1.2, 26)


func _boss1_rewind_interpolated_sample(progress: float) -> Dictionary:
	if boss1_rewind_history.is_empty():
		return {}
	var cursor = lerp(float(boss1_rewind_history.size() - 1), 0.0, clamp(progress, 0.0, 1.0))
	var lower_index = int(floor(cursor))
	var upper_index = min(lower_index + 1, boss1_rewind_history.size() - 1)
	var weight = cursor - lower_index
	var lower: Dictionary = boss1_rewind_history[lower_index]
	var upper: Dictionary = boss1_rewind_history[upper_index]
	var nearest: Dictionary = boss1_rewind_history[int(round(cursor))]
	return {
		"time": lerp(float(lower["time"]), float(upper["time"]), weight),
		"elapsed": lerp(float(lower["elapsed"]), float(upper["elapsed"]), weight),
		"player_pos": Vector2(lower["player_pos"]).lerp(Vector2(upper["player_pos"]), weight),
		"boss_pos": Vector2(lower["boss_pos"]).lerp(Vector2(upper["boss_pos"]), weight),
		"player_hp": lerp(float(lower["player_hp"]), float(upper["player_hp"]), weight),
		"last_facing": Vector2(nearest["last_facing"]),
		"last_attack": float(nearest["last_attack"]),
		"last_dash": float(nearest["last_dash"]),
		"last_skill": float(nearest["last_skill"]),
		"last_secondary": float(nearest["last_secondary"]),
		"last_damage": float(nearest["last_damage"]),
		"boss_phase": lerp(float(lower["boss_phase"]), float(upper["boss_phase"]), weight),
		"boss_attack_timer": float(nearest["boss_attack_timer"]),
		"projectiles": Array(nearest.get("projectiles", []))
	}


func _apply_boss1_rewind_sample(sample: Dictionary) -> void:
	if sample.is_empty():
		return
	time_alive = float(sample["time"])
	elapsed_unpaused = float(sample["elapsed"])
	player_pos = Vector2(sample["player_pos"])
	boss_pos = Vector2(sample["boss_pos"])
	player_hp = clampi(int(round(float(sample["player_hp"]))), 1, int(player_hp_max))
	last_facing = Vector2(sample["last_facing"])
	last_attack_time = float(sample["last_attack"])
	last_dash_time = float(sample["last_dash"])
	last_skill_time = float(sample["last_skill"])
	last_secondary_time = float(sample["last_secondary"])
	last_damage_time = float(sample["last_damage"])
	boss_phase = float(sample["boss_phase"])
	boss_attack_timer = float(sample["boss_attack_timer"])
	boss1_rewind_visual_projectiles = Array(sample.get("projectiles", [])).duplicate(true)


func _update_boss1_rewind_sequence(delta: float) -> void:
	if boss1_rewind_sequence.is_empty():
		return
	boss1_rewind_sequence["elapsed"] = float(boss1_rewind_sequence.get("elapsed", 0.0)) + delta
	var elapsed = float(boss1_rewind_sequence["elapsed"])
	_update_boss1_rewind_feedback(delta, elapsed)
	if elapsed < BOSS1_CLOCK_TRAVEL_TIME:
		return
	var progress = clamp((elapsed - BOSS1_CLOCK_TRAVEL_TIME) / BOSS1_CLOCK_TURN_TIME, 0.0, 1.0)
	_apply_boss1_rewind_sample(_boss1_rewind_interpolated_sample(progress))
	if progress >= 1.0:
		_finish_boss1_rewind()


func _update_boss1_rewind_feedback(delta: float, elapsed: float) -> void:
	boss1_rewind_vibration_timer -= delta
	if boss1_rewind_vibration_timer <= 0.0:
		boss1_rewind_vibration_timer = 0.90
		_vibrate(95, 0.30)
	if elapsed >= BOSS1_CLOCK_TRAVEL_TIME and elapsed <= BOSS1_CLOCK_TRAVEL_TIME + BOSS1_CLOCK_TURN_TIME:
		var turn_progress = clamp((elapsed - BOSS1_CLOCK_TRAVEL_TIME) / BOSS1_CLOCK_TURN_TIME, 0.0, 1.0)
		var tick = int(floor(turn_progress * 10.0))
		if tick != boss1_rewind_clock_tick:
			boss1_rewind_clock_tick = tick
			_play_sfx("shop_countdown_tick", 0.015, 0.52, 0.82 + turn_progress * 0.14)


func _finish_boss1_rewind() -> void:
	if boss1_rewind_sequence.is_empty():
		return
	var heal = float(boss1_rewind_sequence.get("boss_heal", 0.0))
	if not boss1_rewind_history.is_empty():
		_apply_boss1_rewind_sample(boss1_rewind_history[0])
	boss_hp = min(boss_hp_max, boss_hp + heal)
	player_hp = clampi(int(round(float(boss1_rewind_sequence.get("player_final_hp", player_hp)))), 1, int(player_hp_max))
	bullets.clear()
	return_bullets.clear()
	enemy_bullets.clear()
	shockwaves.clear()
	slashes.clear()
	prisms.clear()
	orbitals.clear()
	seed_links.clear()
	parasite_spit_zones.clear()
	manifestation_secondaries.clear()
	effects.clear()
	boss_attacks.clear()
	boss_transition_waves.clear()
	boss1_rewind_history.clear()
	boss1_rewind_visual_projectiles.clear()
	boss1_rewind_sequence.clear()
	boss1_rewind_sample_timer = 0.0
	boss1_rewind_vibration_timer = 0.0
	boss1_rewind_clock_tick = -1
	boss_attack_timer = max(1.4, boss_attack_timer)
	_add_text("-10s  /  BOSS +40%  /  GEO +25%", boss_pos + Vector2(0, -120), Color(0.42, 0.94, 1.0), 1.8, 24)
	_spawn_radial_particles(boss_pos, Color(0.30, 0.78, 1.0), 36)


func _boss_entry_impact_feedback(mult := 1.0) -> void:
	screen_shake_timer = max(screen_shake_timer, 0.42 * mult)
	screen_shake_strength = max(screen_shake_strength, 24.0 * mult)
	_vibrate(int(520.0 * mult), 1.0)


func _update_boss(delta: float) -> void:
	if current_phase == 3:
		_update_boss_phase3(delta)
		return
	if current_phase == 2:
		_update_boss_phase2(delta)
		return
	boss1_rewind_cooldown = max(0.0, boss1_rewind_cooldown - delta)
	var rewind_health_ratio = boss_hp / max(1.0, boss_hp_max)
	if boss_entry_timer <= 0.0 and rewind_health_ratio < BOSS1_REWIND_THRESHOLD and boss1_rewind_cooldown <= 0.0 and boss1_time_wave.is_empty():
		_start_boss1_time_wave()
	var fury = _boss1_fury_scale()
	boss_phase += delta * (6.0 + fury * 2.2)
	boss_attack_timer -= delta
	if boss_entry_timer > 0.0:
		boss_entry_timer -= delta
		var progress = 1.0 - boss_entry_timer / BOSS_ENTRY_TIME
		var target = WORLD_SIZE * 0.5
		if progress < 0.8:
			boss_pos = Vector2(target.x, lerp(-220.0, target.y, progress / 0.8))
		else:
			boss_pos = target
			if not boss_empurrou_player:
				boss_empurrou_player = true
				_boss_entry_impact_feedback(1.0)
				var dist = player_pos.distance_to(target)
				if dist < 350.0:
					var push = (player_pos - target).normalized()
					if push.length() <= 0.01:
						push = Vector2.RIGHT
					player_pos = (player_pos + push * max(35.0, 120.0 * (1.0 - dist / 350.0))).clamp(Vector2(70, 80), WORLD_SIZE - Vector2(70, 80))
					_spawn_radial_particles(target, Color(0.78, 0.1, 1.0), 48)
		return
	if not boss1_time_wave.is_empty():
		_update_boss1_time_wave(delta)
		return
	_update_boss_transition_waves(delta)
	if boss_stage_timer > 0.0:
		_update_boss_stage(delta)
		return
	_update_boss_attacks(delta)
	var moving_by_attack = boss_attacks.any(func(a): return String(a.get("kind", "")) == "rush" and ["dash", "grab", "throw"].has(String(a.get("state", ""))))
	if not moving_by_attack:
		var dir = (player_pos - boss_pos).normalized()
		boss_pos += dir * (58.0 + fury * 26.0) * delta
		boss_pos = boss_pos.clamp(Vector2(90, 90), WORLD_SIZE - Vector2(90, 90))
	var rush_collision_suppressed = boss_attacks.any(func(a): return String(a.get("kind", "")) == "rush" and ["dash", "grab", "throw"].has(String(a.get("state", ""))))
	if not rush_collision_suppressed and boss_pos.distance_to(player_pos) < 86.0 and boss_attack_timer <= 0.0:
		boss_attack_timer = 2.5
		_damage_player(int(player_hp_max * 0.10 + 150 + 90), "boss")
	var pct = boss_hp / max(1.0, boss_hp_max)
	if pct < 0.60 and not boss_stage_60_done:
		_start_boss_stage()
		boss_stage_60_done = true
	elif pct < 0.40 and not boss_stage_40_done:
		_start_boss_stage()
		boss_stage_40_done = true
	var cooldown = BOSS_ATTACK_BASE_COOLDOWN
	if pct <= 0.35:
		cooldown = 2.15
	elif pct <= 0.70:
		cooldown = 3.0
	if boss_attacks.is_empty() and boss_attack_timer <= 0.0:
		boss_attack_timer = cooldown
		_launch_boss_attack()
	if boss_hp / max(1.0, boss_hp_max) <= BOSS1_RAIN_THRESHOLD:
		_start_boss1_rain()


func _boss1_fury_scale() -> float:
	var pct = boss_hp / max(1.0, boss_hp_max)
	if pct <= 0.30:
		return 1.85
	if pct <= 0.40:
		return 1.45
	if pct <= 0.60:
		return 1.0
	return 0.0


func _update_boss_phase3(delta: float) -> void:
	boss_phase += delta * (3.3 if boss3_consume_uid < 0 else 5.4)
	boss3_stun_timer = max(0.0, boss3_stun_timer - delta)
	if boss_entry_timer > 0.0:
		boss_entry_timer -= delta
		var progress = clamp(1.0 - boss_entry_timer / BOSS3_ENTRY_TIME, 0.0, 1.0)
		boss_pos = Vector2(WORLD_SIZE.x * 0.5, lerp(-220.0, WORLD_SIZE.y * 0.5, ease(progress, -1.8)))
		if boss_entry_timer <= 0.0 and not boss_empurrou_player:
			boss_empurrou_player = true
			_boss_entry_impact_feedback(0.82)
		return
	var pct = boss_hp / max(1.0, boss_hp_max)
	boss3_stage = 1 if pct > 0.70 else (2 if pct > 0.35 else 3)
	_update_boss3_events(pct)
	_update_boss3_cheeses(delta)
	_update_boss3_attacks(delta)
	if boss3_ritual_timer > 0.0:
		boss3_ritual_timer -= delta
		if boss3_ritual_timer <= 0.0:
			_finish_boss3_ritual()
		return
	if boss3_stun_timer > 0.0:
		return
	boss3_dialogue_timer -= delta
	if boss3_dialogue_timer <= 0.0:
		boss3_dialogue_timer = rng.randf_range(8.0, 12.0)
		var lines = ["A FE ALIMENTA O ESGOTO", "VOCES CHAMAM ISSO DE FOME", "MEUS FILHOS NAO TEMEM A LUZ"]
		_add_text(lines[rng.randi_range(0, lines.size() - 1)], boss_pos + Vector2(0, -118), Color(0.82, 1.0, 0.42), 2.0, 21)
	if boss3_consume_uid >= 0:
		return
	boss3_rain_timer -= delta
	boss3_spit_timer -= delta
	boss3_tail_timer -= delta
	boss3_charge_timer -= delta
	boss3_cheese_timer -= delta
	if boss3_stage >= 2 and boss3_cheese_timer <= 0.0 and not _boss3_has_true_cheese():
		boss3_cheese_timer = BOSS3_CHEESE_INTERVAL
		_spawn_boss3_cheese(_boss3_random_cheese_pos(), true, 34.0 + boss3_stage * 7.0, 10.5, false)
		_spawn_enemy(ENEMY_DEVOTO, _spawn_point_around_player(440.0))
	if boss3_stage >= 3 and boss3_charge_timer <= 0.0 and boss_attacks.is_empty():
		boss3_charge_timer = max(4.2, 6.8 - (50.0 - boss3_faith) * 0.045)
		_start_boss3_charge()
	elif boss3_stage >= 2 and boss3_tail_timer <= 0.0 and boss_pos.distance_to(player_pos) <= 145.0 and boss_attacks.is_empty():
		boss3_tail_timer = 3.2
		boss_attacks.append({"kind": "rat_tail", "age": 0.0, "duration": 0.52, "hit": false})
	elif boss3_spit_timer <= 0.0 and not _boss3_has_true_cheese() and boss_attacks.is_empty():
		boss3_spit_timer = [4.2, 3.4, 3.0][boss3_stage - 1]
		var spit_dir = (player_pos - boss_pos).normalized()
		boss_attacks.append({"kind": "rat_spit", "age": 0.0, "duration": 0.36, "dir": spit_dir, "fired": false})
	elif boss3_rain_timer <= 0.0 and boss_attacks.is_empty():
		boss3_rain_timer = max(2.2, [4.3, 3.6, 3.0][boss3_stage - 1] - boss3_faith * 0.009)
		_start_boss3_rain()
	elif boss_attacks.is_empty():
		var dir = (player_pos - boss_pos).normalized()
		boss_pos = (boss_pos + dir * (58.0 + boss3_stage * 7.0) * delta).clamp(Vector2(80, 80), WORLD_SIZE - Vector2(80, 80))


func _update_boss3_events(pct: float) -> void:
	if pct <= 0.35 and not boss3_events.has("final"):
		boss3_events["final"] = true
		_add_text("O ESGOTO VAI REZAR COMIGO", boss_pos + Vector2(0, -122), Color(1.0, 0.38, 0.18), 2.5, 25)
	if pct <= 0.85 and not boss3_events.has("cheese85"):
		boss3_events["cheese85"] = true
		_spawn_boss3_cheese(_boss3_random_cheese_pos(), true, 26.0, 11.0, false)
		_add_text("TRAGAM-ME O QUEIJO", boss_pos + Vector2(0, -120), Color(1.0, 0.88, 0.28), 1.8, 24)
	if pct <= 0.60 and not boss3_events.has("cheese60"):
		boss3_events["cheese60"] = true
		_spawn_boss3_cheese(_boss3_random_cheese_pos(), true, 38.0, 12.0, false)
		_spawn_boss3_cheese(_boss3_random_cheese_pos(), false, 30.0, 12.0, false)
		_spawn_enemy(ENEMY_DEVOTO, _spawn_point_around_player(420.0))
		_spawn_enemy(ENEMY_DEVOTO, _spawn_point_around_player(500.0))
	if pct <= 0.25 and not boss3_events.has("ritual"):
		boss3_events["ritual"] = true
		_start_boss3_ritual()


func _start_boss3_rain() -> void:
	var safe_lane = rng.randi_range(0, 3)
	boss_attacks.append({"kind": "rat_rain", "age": 0.0, "duration": 0.65, "safe": safe_lane, "fired": false})
	_play_sfx("Frasco.mp3", 0.04, 0.46)
	if rng.randf() < 0.35:
		_add_text("BEBA DA MINHA FE", boss_pos + Vector2(0, -112), Color(0.78, 1.0, 0.36), 1.4, 20)


func _start_boss3_charge() -> void:
	var dir = (player_pos - boss_pos).normalized()
	boss_attacks.append({"kind": "rat_charge", "age": 0.0, "duration": 1.55, "warn": 0.70, "dir": dir, "hit": false})


func _update_boss3_attacks(delta: float) -> void:
	for attack in boss_attacks:
		attack["age"] = float(attack.get("age", 0.0)) + delta
		var kind = String(attack.get("kind", ""))
		if kind == "rat_rain" and float(attack["age"]) >= 0.65 and not bool(attack.get("fired", false)):
			attack["fired"] = true
			for lane in range(4):
				if lane == int(attack["safe"]):
					continue
				var y = WORLD_SIZE.y * (0.18 + lane * 0.215)
				_spawn_phase3_projectile(Vector2(WORLD_SIZE.x + 30.0, y), Vector2.LEFT, player_hp_max * 0.10, "rat_flask", 1.75)
		elif kind == "rat_spit" and float(attack["age"]) >= 0.36 and not bool(attack.get("fired", false)):
			attack["fired"] = true
			_spawn_phase3_projectile(boss_pos, Vector2(attack["dir"]), player_hp_max * 0.10, "rat_spit", 1.48)
		elif kind == "rat_tail" and float(attack["age"]) >= 0.52 and not bool(attack.get("hit", false)):
			attack["hit"] = true
			if player_pos.distance_to(boss_pos) <= 155.0:
				_damage_player(int(player_hp_max * 0.12), "cauda")
				var push = (player_pos - boss_pos).normalized()
				player_pos = (player_pos + push * 42.0).clamp(Vector2(70, 80), WORLD_SIZE - Vector2(70, 80))
		elif kind == "rat_charge" and float(attack["age"]) >= float(attack["warn"]):
			var old_pos = boss_pos
			boss_pos += Vector2(attack["dir"]) * 510.0 * delta
			var clamped = boss_pos.clamp(Vector2(76, 76), WORLD_SIZE - Vector2(76, 76))
			if clamped != boss_pos:
				boss_pos = clamped
				boss3_stun_timer = 1.7
				attack["age"] = float(attack["duration"])
				_add_text("ATORDOADO +35% DANO", boss_pos + Vector2(0, -112), Color(1.0, 0.86, 0.28), 1.6, 22)
			if not bool(attack.get("hit", false)) and _distance_to_segment(player_pos, old_pos, boss_pos) <= 74.0:
				attack["hit"] = true
				_damage_player(int(player_hp_max * 0.16), "carga")
	boss_attacks = boss_attacks.filter(func(a): return float(a.get("age", 0.0)) < float(a.get("duration", 0.0)))


func _spawn_boss3_cheese(pos: Vector2, is_true: bool, hp: float, duration: float, ritual: bool) -> void:
	phase3_cheeses.append({"uid": randi(), "pos": pos, "true": is_true, "hp": hp, "max_hp": hp, "life": duration, "max": duration, "ritual": ritual})
	_play_sfx("Queijo.mp3", 0.03, 0.42)


func _boss3_random_cheese_pos() -> Vector2:
	return Vector2(rng.randf_range(230.0, WORLD_SIZE.x - 230.0), rng.randf_range(150.0, WORLD_SIZE.y - 150.0))


func _boss3_has_true_cheese() -> bool:
	for cheese in phase3_cheeses:
		if bool(cheese.get("true", false)) and float(cheese.get("hp", 0.0)) > 0.0:
			return true
	return false


func _boss3_cheese_by_uid(uid: int) -> Dictionary:
	for cheese in phase3_cheeses:
		if int(cheese.get("uid", -1)) == uid:
			return cheese
	return {}


func _update_boss3_cheeses(delta: float) -> void:
	for cheese in phase3_cheeses:
		cheese["life"] = float(cheese["life"]) - delta
		if float(cheese["life"]) <= 0.0 and not bool(cheese.get("true", false)):
			_add_phase3_miasma(Vector2(cheese["pos"]), 78.0, 2.6, 0.018)
	if boss3_consume_uid < 0 and boss3_ritual_timer <= 0.0:
		var nearest = {}
		var best = INF
		for cheese in phase3_cheeses:
			if not bool(cheese.get("true", false)) or float(cheese.get("hp", 0.0)) <= 0.0:
				continue
			var dist = boss_pos.distance_to(Vector2(cheese["pos"]))
			if dist < best:
				best = dist
				nearest = cheese
		if not nearest.is_empty():
			boss3_consume_uid = int(nearest["uid"])
			boss3_consume_timer = 0.0
	if boss3_consume_uid >= 0:
		var target = _boss3_cheese_by_uid(boss3_consume_uid)
		if target.is_empty() or float(target.get("hp", 0.0)) <= 0.0:
			boss3_consume_uid = -1
		elif boss_pos.distance_to(Vector2(target["pos"])) > 52.0:
			var speed = (0.85 + boss3_stage * 0.18 + boss3_faith * 0.004) * 60.0
			boss_pos += (Vector2(target["pos"]) - boss_pos).normalized() * speed * delta
		else:
			boss3_consume_timer += delta
			if boss3_consume_timer >= 1.0:
				var missing = boss_hp_max - boss_hp
				var heal_ratio = 0.22 + boss3_faith * 0.0015
				var heal = missing * heal_ratio
				boss_hp = min(boss_hp_max, boss_hp + heal)
				boss3_faith = min(100.0, boss3_faith + 20.0)
				target["hp"] = 0.0
				_add_text("FE +20  CURA +%d" % int(heal), boss_pos + Vector2(0, -110), Color(0.76, 1.0, 0.30), 1.7, 23)
				boss3_consume_uid = -1
	phase3_cheeses = phase3_cheeses.filter(func(c): return float(c.get("life", 0.0)) > 0.0 and float(c.get("hp", 0.0)) > 0.0)


func _damage_phase3_cheeses_at(pos: Vector2, amount: float, radius := 32.0) -> bool:
	if current_phase != 3:
		return false
	var hit = false
	for cheese in phase3_cheeses:
		if pos.distance_to(Vector2(cheese["pos"])) > radius:
			continue
		cheese["hp"] = float(cheese["hp"]) - max(1.0, amount)
		_add_text("-%d" % int(amount), Vector2(cheese["pos"]) + Vector2(0, -38), Color(1.0, 0.88, 0.30), 0.45, 16)
		hit = true
		if float(cheese["hp"]) <= 0.0:
			if bool(cheese.get("true", false)):
				boss3_faith = max(0.0, boss3_faith - 15.0)
				if bool(cheese.get("ritual", false)):
					boss3_ritual_destroyed += 1
				_add_text("FE -15", Vector2(cheese["pos"]) + Vector2(0, -58), Color(1.0, 0.94, 0.46), 1.0, 20)
				_add_text("MEU SACRAMENTO!", boss_pos + Vector2(0, -112), Color(1.0, 0.62, 0.24), 1.2, 19)
			else:
				_add_phase3_miasma(Vector2(cheese["pos"]), 82.0, 3.0, 0.018)
	return hit


func _start_boss3_ritual() -> void:
	boss3_ritual_timer = 8.5
	boss3_ritual_destroyed = 0
	phase3_cheeses.clear()
	var positions = [Vector2(WORLD_SIZE.x * 0.22, WORLD_SIZE.y * 0.25), Vector2(WORLD_SIZE.x * 0.50, WORLD_SIZE.y * 0.70), Vector2(WORLD_SIZE.x * 0.78, WORLD_SIZE.y * 0.32)]
	for pos in positions:
		_spawn_boss3_cheese(pos, true, 30.0, 9.0, true)
	_add_text("RITUAL: DESTRUA 2 QUEIJOS", boss_pos + Vector2(0, -132), Color(1.0, 0.32, 0.18), 3.0, 27)


func _finish_boss3_ritual() -> void:
	if boss3_ritual_destroyed >= 2:
		boss3_faith = max(0.0, boss3_faith - 30.0)
		boss3_stun_timer = 3.2
		_add_text("RITUAL QUEBRADO: VULNERAVEL", boss_pos + Vector2(0, -126), Color(1.0, 0.88, 0.26), 2.4, 25)
	else:
		boss3_faith = min(100.0, boss3_faith + 25.0)
		var heal = (boss_hp_max - boss_hp) * 0.32
		boss_hp = min(boss_hp_max, boss_hp + heal)
		_add_phase3_miasma(boss_pos, 150.0, 3.2, 0.025)
		_add_text("RITUAL COMPLETO: FE +25", boss_pos + Vector2(0, -126), Color(0.62, 1.0, 0.24), 2.4, 25)
	phase3_cheeses.clear()


func _update_boss_phase2(delta: float) -> void:
	boss_phase += delta * 4.5
	boss_attack_timer -= delta
	if boss_entry_timer > 0.0:
		boss_entry_timer -= delta
		var progress = clamp(1.0 - boss_entry_timer / BOSS2_ENTRY_TIME, 0.0, 1.0)
		var target = WORLD_SIZE * 0.5
		if progress < 0.8:
			boss_pos = Vector2(target.x, lerp(-260.0, target.y, progress / 0.8))
		else:
			boss_pos = target
			if not boss_empurrou_player:
				boss_empurrou_player = true
				_boss_entry_impact_feedback(0.9)
				screen_shake_timer = max(screen_shake_timer, 0.34)
				screen_shake_strength = max(screen_shake_strength, 20.0)
				_spawn_boss2_ice_burst(target, 35, 1.0)
				_spawn_boss2_slow_zone(target, 125.0, 2.2)
				_add_text("A NEVASCA EMITE UM GRITO", target + Vector2(0, -138), Color(0.38, 0.88, 1.0), 1.7, 30)
		if boss_entry_timer <= 0.0:
			boss_entry_timer = 0.0
			boss_attack_timer = BOSS2_ATTACK_INTERVAL
			_add_boss2_blizzard(true)
		return
	if boss_pos.distance_to(player_pos) < 82.0 and boss_attack_timer <= 0.0:
		boss_attack_timer = 2.2
		_damage_player(int(player_hp_max * 0.09 + 70 + enemy_close_damage), "boss")
	if boss_attacks.is_empty() and boss_attack_timer <= 0.0:
		boss_attack_timer = BOSS2_ATTACK_INTERVAL
		_launch_boss2_attack()
	_update_boss2_attacks(delta)


func _launch_boss2_attack() -> void:
	var pool = ["blizzard_h", "blizzard_v", "avalanche", "frost_breath", "shield"]
	var pct = boss_hp / max(1.0, boss_hp_max)
	if pct < 0.40:
		pool.append("double_blizzard")
	var choice = pool[rng.randi_range(0, pool.size() - 1)]
	match choice:
		"blizzard_h":
			_add_boss2_blizzard(false)
		"blizzard_v":
			_add_boss2_blizzard(true)
		"frost_breath":
			_add_boss2_frost_breath()
		"avalanche":
			_add_boss2_avalanche()
		"double_blizzard":
			_add_boss2_blizzard(false)
			_add_boss2_blizzard(true)
		"shield":
			_add_boss2_shield()


func _add_boss2_blizzard(vertical: bool) -> void:
	var waves = []
	var speed_scale = _boss2_speed_scale()
	if vertical:
		var pattern = rng.randi_range(1, 4)
		if pattern == 1:
			waves = [
				{"x": WORLD_SIZE.x + 30.0, "y": 0.0, "vx": -4.2, "vy": 0.0, "width": 70.0, "direction": "left", "type": "standard"},
				{"x": WORLD_SIZE.x + 310.0, "y": 0.0, "vx": -4.2, "vy": 0.0, "width": 70.0, "direction": "left", "type": "standard"}
			]
		elif pattern == 2:
			waves = [{"x": WORLD_SIZE.x + 30.0, "y": 0.0, "vx": -4.0, "vy": 0.0, "width": 80.0, "direction": "left", "type": "sinusoidal", "phase": rng.randf_range(0.0, TAU)}]
		elif pattern == 3:
			waves = [{"x": WORLD_SIZE.x + 30.0, "y": 0.0, "vx": -4.5, "vy": 0.0, "width": 80.0, "direction": "left", "type": "pivoting", "pivoted": false, "pivot_coord": 450.0, "pivot_new_vel": Vector2(0.0, 4.5)}]
		else:
			waves = [
				{"x": WORLD_SIZE.x + 30.0, "y": 0.0, "vx": -4.5, "vy": 0.0, "width": 60.0, "direction": "left", "type": "standard"},
				{"x": WORLD_SIZE.x + 250.0, "y": 0.0, "vx": -4.5, "vy": 0.0, "width": 60.0, "direction": "left", "type": "standard"},
				{"x": WORLD_SIZE.x + 470.0, "y": 0.0, "vx": -4.5, "vy": 0.0, "width": 60.0, "direction": "left", "type": "standard"}
			]
	else:
		var pattern = rng.randi_range(1, 4)
		if pattern == 1:
			waves = [
				{"x": 0.0, "y": -30.0, "vx": 0.0, "vy": 4.0, "width": 70.0, "direction": "down", "type": "standard"},
				{"x": 0.0, "y": -280.0, "vx": 0.0, "vy": 4.0, "width": 70.0, "direction": "down", "type": "standard"}
			]
		elif pattern == 2:
			waves = [{"x": 0.0, "y": -30.0, "vx": 0.0, "vy": 4.2, "width": 80.0, "direction": "down", "type": "pivoting", "pivoted": false, "pivot_coord": 300.0, "pivot_new_vel": Vector2(-5.0, 0.0)}]
		elif pattern == 3:
			waves = [
				{"x": 0.0, "y": -30.0, "vx": 0.0, "vy": 3.6, "width": 70.0, "direction": "down", "type": "standard"},
				{"x": WORLD_SIZE.x + 30.0, "y": 0.0, "vx": -3.6, "vy": 0.0, "width": 70.0, "direction": "left", "type": "standard"}
			]
		else:
			waves = [
				{"x": 0.0, "y": -30.0, "vx": 0.0, "vy": 4.2, "width": 60.0, "direction": "down", "type": "standard"},
				{"x": 0.0, "y": -230.0, "vx": 0.0, "vy": 4.2, "width": 60.0, "direction": "down", "type": "standard"},
				{"x": 0.0, "y": -430.0, "vx": 0.0, "vy": 4.2, "width": 60.0, "direction": "down", "type": "standard"}
			]
	waves = _boss2_smooth_waves(waves, speed_scale)
	boss_attacks.append({
		"kind": "blizzard",
		"vertical": vertical,
		"waves": waves,
		"age": 0.0,
		"duration": BOSS2_WARNING_TIME + 4.2,
		"warn": BOSS2_WARNING_TIME,
		"hit": {}
	})


func _add_boss2_frost_breath() -> void:
	var dir = (player_pos - boss_pos).normalized()
	if dir.length() <= 0.01:
		dir = Vector2.DOWN
	boss_attacks.append({
		"kind": "frost_breath",
		"dir": dir,
		"age": 0.0,
		"duration": BOSS2_WARNING_TIME + BOSS2_BREATH_TIME,
		"warn": BOSS2_WARNING_TIME,
		"tick": 0.0
	})


func _add_boss2_avalanche() -> void:
	var targets = []
	for i in range(4):
		targets.append((player_pos + Vector2(rng.randf_range(-220, 220), rng.randf_range(-160, 160))).clamp(Vector2(90, 90), WORLD_SIZE - Vector2(90, 90)))
	boss_attacks.append({
		"kind": "avalanche",
		"targets": targets,
		"age": 0.0,
		"duration": BOSS2_WARNING_TIME + 2.5,
		"warn": BOSS2_WARNING_TIME,
		"hit": {},
		"dropped": {}
	})


func _add_boss2_shield() -> void:
	boss_attacks.append({
		"kind": "shield",
		"age": 0.0,
		"duration": BOSS2_SHIELD_TIME,
		"angle": 0.0,
		"shot_timer": 0.0
	})
	_add_text("ESCUDO DE CRISTAIS", boss_pos + Vector2(0, -116), Color(0.65, 0.94, 1.0), 1.1, 24)


func _boss2_speed_scale() -> float:
	var pct = boss_hp / max(1.0, boss_hp_max)
	if pct <= 0.40:
		return 1.25
	if pct <= 0.60:
		return 1.12
	return 1.0


func _boss2_smooth_waves(waves: Array, speed_scale: float) -> Array:
	var adjusted = []
	for wave in waves:
		var w = wave.duplicate()
		w["vx"] = float(w.get("vx", 0.0)) * BOSS2_WAVE_SPEED_MULT * speed_scale * 60.0
		w["vy"] = float(w.get("vy", 0.0)) * BOSS2_WAVE_SPEED_MULT * speed_scale * 60.0
		w["width"] = max(42.0, float(w.get("width", BOSS2_WAVE_WIDTH)) * BOSS2_WAVE_WIDTH_MULT)
		if w.has("pivot_new_vel"):
			var pivot_vel: Vector2 = w["pivot_new_vel"]
			w["pivot_new_vel"] = pivot_vel * BOSS2_WAVE_SPEED_MULT * speed_scale * 60.0
		adjusted.append(w)
	return adjusted


func _boss2_shield_active() -> bool:
	if current_phase != 2:
		return false
	for attack in boss_attacks:
		if String(attack.get("kind", "")) == "shield":
			return true
	return false


func _update_boss2_attacks(delta: float) -> void:
	for attack in boss_attacks:
		attack["age"] = float(attack.get("age", 0.0)) + delta
		var age = float(attack["age"])
		match String(attack["kind"]):
			"blizzard":
				if age < float(attack["warn"]):
					continue
				for i in range(attack["waves"].size()):
					var wave = attack["waves"][i]
					wave["x"] = float(wave.get("x", 0.0)) + float(wave.get("vx", 0.0)) * delta
					wave["y"] = float(wave.get("y", 0.0)) + float(wave.get("vy", 0.0)) * delta
					if String(wave.get("type", "")) == "sinusoidal":
						wave["y"] = WORLD_SIZE.y * 0.5 + sin(age * 4.2 + float(wave.get("phase", 0.0))) * 180.0
					if String(wave.get("type", "")) == "pivoting" and not bool(wave.get("pivoted", false)):
						var direction = String(wave.get("direction", "left"))
						if (direction == "left" and float(wave["x"]) <= float(wave["pivot_coord"])) or (direction == "down" and float(wave["y"]) >= float(wave["pivot_coord"])):
							wave["pivoted"] = true
							var new_vel: Vector2 = wave["pivot_new_vel"]
							wave["vx"] = new_vel.x
							wave["vy"] = new_vel.y
					var key = "w" + str(i)
					if _boss2_wave_hits_player(wave) and time_alive - float(attack["hit"].get(key, -999.0)) >= 1.1:
						attack["hit"][key] = time_alive
						_damage_player(int(player_hp_max * 0.045 + 12 + 55 + enemy_far_damage * 0.55), "boss")
						_spawn_boss2_slow_zone(player_pos, 54.0, 2.2)
					attack["waves"][i] = wave
			"frost_breath":
				if age < float(attack["warn"]):
					continue
				attack["tick"] = float(attack.get("tick", 0.0)) - delta
				var dir: Vector2 = attack["dir"]
				for i in range(3):
					_spawn_boss2_frost_particle(boss_pos + dir * 54.0, dir)
				var to_player = player_pos - boss_pos
				var dist = to_player.length()
				if dist > 0.0:
					var angle_diff = abs(wrapf(to_player.angle() - dir.angle(), -PI, PI))
					if dist < 420.0 and angle_diff < 0.48 and float(attack["tick"]) <= 0.0:
						attack["tick"] = 0.18
						_damage_player(int(player_hp_max * 0.022 + 8), "boss")
						_spawn_boss2_slow_zone(player_pos, 42.0, 1.4)
				if float(attack["tick"]) <= 0.0:
					attack["tick"] = 0.18
					var base_angle = dir.angle()
					for offset in [-0.25, 0.0, 0.25]:
						_spawn_boss2_frost_bullet(boss_pos + dir * 64.0, Vector2.from_angle(base_angle + offset), player_hp_max * 0.035 + 18 + enemy_far_damage, 5.8)
			"avalanche":
				if age < float(attack["warn"]):
					continue
				for i in range(attack["targets"].size()):
					var target: Vector2 = attack["targets"][i]
					var key = str(i)
					var local = age - float(attack["warn"])
					if local >= 1.0 and not attack["dropped"].has(key):
						attack["dropped"][key] = true
						screen_shake_timer = max(screen_shake_timer, 0.20)
						screen_shake_strength = max(screen_shake_strength, 9.0)
						_spawn_boss2_ice_burst(target, 8, 0.62)
						_spawn_boss2_slow_zone(target, 62.0, BOSS2_SLOW_ZONE_TIME)
						if player_pos.distance_to(target) <= 58.0 and not attack["hit"].has(key):
							attack["hit"][key] = true
							_damage_player(int((player_hp_max - player_hp) * 0.06 + 12 + 55 + enemy_far_damage * 0.55), "boss")
			"shield":
				attack["angle"] = float(attack.get("angle", 0.0)) + delta * 3.0
				attack["shot_timer"] = float(attack.get("shot_timer", 0.0)) - delta
				if float(attack["shot_timer"]) <= 0.0:
					attack["shot_timer"] = 1.5
					for i in range(3):
						var angle = float(attack["angle"]) + i * TAU / 3.0
						var origin = boss_pos + Vector2.from_angle(angle) * 92.0
						var dir = (player_pos - origin).normalized()
						_spawn_boss2_frost_bullet(origin, dir, player_hp_max * 0.04 + 22 + enemy_far_damage, 5.2)
	boss_attacks = boss_attacks.filter(func(a): return float(a.get("age", 0.0)) < float(a.get("duration", 1.0)))


func _boss2_wave_hits_player(wave: Dictionary) -> bool:
	var width = float(wave.get("width", BOSS2_WAVE_WIDTH))
	var direction = String(wave.get("direction", "left"))
	if direction == "left" or direction == "right":
		return abs(player_pos.x - float(wave.get("x", 0.0))) <= width * 0.5
	return abs(player_pos.y - float(wave.get("y", 0.0))) <= width * 0.5


func _start_boss_stage() -> void:
	boss_stage_timer = BOSS_STAGE_JUMP_TIME
	boss_stage_safe_angle = rng.randf_range(-PI, PI)
	boss_transition_waves.clear()
	boss_attacks.clear()
	_vibrate(140, 0.42)
	_add_text("SALTO DE RUPTURA", boss_pos + Vector2(0, -120), Color(0.74, 0.20, 1.0), 1.5, 30)


func _update_boss_stage(delta: float) -> void:
	boss_stage_timer -= delta
	boss_pos = WORLD_SIZE * 0.5
	var elapsed = BOSS_STAGE_JUMP_TIME - boss_stage_timer
	var latest_wave_index = int(floor((elapsed - BOSS_STAGE_SLAM_TIME) / BOSS_STAGE_WAVE_INTERVAL))
	latest_wave_index = min(latest_wave_index, BOSS_STAGE_WAVE_COUNT - 1)
	for wave_index in range(latest_wave_index + 1 if elapsed >= BOSS_STAGE_SLAM_TIME else 0):
		var already = false
		for wave in boss_transition_waves:
			if int(wave.get("idx", -1)) == wave_index:
				already = true
				break
		if not already:
			_vibrate(BOSS_STAGE_WAVE_HAPTIC_MS, 0.34 + float(wave_index) * 0.08)
			if wave_index == 0:
				screen_shake_timer = 0.32
				screen_shake_strength = 18.0
				_spawn_radial_particles(boss_pos, Color(0.70, 0.24, 1.0), 34)
				_add_text("FIQUE NAS ABERTURAS", boss_pos + Vector2(0, -138), Color(0.34, 1.0, 0.92), 1.8, 24)
			boss_transition_waves.append({
				"idx": wave_index,
				"pos": boss_pos,
				"radius": 42.0,
				"speed": BOSS_STAGE_WAVE_SPEED,
				"width": 16.0,
				"kind": "dupla_abertura",
				"open_angle": boss_stage_safe_angle + wave_index * PI / 8.0,
				"open_size": PI * 0.48,
				"age": 0.0,
				"warning": BOSS_STAGE_WAVE_WARNING,
				"hit": false
			})
	if boss_stage_timer <= 0.0:
		boss_stage_timer = 0.0
		boss_attack_timer = 1.0


func _update_boss_transition_waves(delta: float) -> void:
	for wave in boss_transition_waves:
		wave["age"] = float(wave.get("age", 0.0)) + delta
		if float(wave["age"]) < float(wave.get("warning", 0.0)):
			continue
		wave["radius"] = float(wave["radius"]) + float(wave["speed"]) * delta
		var dist = player_pos.distance_to(Vector2(wave["pos"]))
		if bool(wave.get("hit", false)) or abs(dist - float(wave["radius"])) > float(wave["width"]) + 16.0:
			continue
		var angle_to_player = (player_pos - Vector2(wave["pos"])).angle()
		var opening = float(wave["open_angle"])
		var opening_size = float(wave["open_size"])
		var first_gap = abs(wrapf(angle_to_player - opening, -PI, PI)) <= opening_size * 0.5
		var opposite_gap = abs(wrapf(angle_to_player - (opening + PI), -PI, PI)) <= opening_size * 0.5
		if not first_gap and not opposite_gap:
			wave["hit"] = true
			_damage_player(int(player_hp_max * 0.045 + 18), "boss")
	boss_transition_waves = boss_transition_waves.filter(func(w): return float(w.get("radius", 0.0)) < 1250.0 and float(w.get("age", 0.0)) < 7.5)


func _launch_boss_attack() -> void:
	var pct = boss_hp / max(1.0, boss_hp_max)
	var pool = ["bubble", "pressure_bubbles", "rush"]
	if pct <= 0.70:
		pool = ["bubble", "pressure_bubbles", "rain", "tide", "sand", "rush"]
	if pct <= 0.35:
		pool = ["bubble_combo", "pressure_barrage", "tide_combo", "rush_combo"]
	var choice = pool[rng.randi_range(0, pool.size() - 1)]
	match choice:
		"bubble":
			_add_boss_bubble(player_pos)
		"pressure_bubbles":
			_add_boss_pressure_bubbles(5)
		"rain":
			_add_boss_rain(7)
		"tide":
			_add_boss_tide()
		"sand":
			_add_boss_sand(3)
		"rush":
			_add_boss_rush()
		"bubble_combo":
			_add_boss_bubble(player_pos)
			_add_boss_sand(2)
		"pressure_barrage":
			_add_boss_pressure_bubbles(8)
		"tide_combo":
			_add_boss_tide()
			_add_boss_sand(3)
		"rush_combo":
			_add_boss_rush()
			_add_boss_pressure_bubbles(6)


func _add_boss_bubble(target: Vector2) -> void:
	boss_attacks.append({"kind": "bubble", "target": target, "age": 0.0, "duration": 3.2, "hit": false, "particles": []})


func _add_boss_rain(count: int) -> void:
	boss_attacks.append({
		"kind": "boiling_bubbles",
		"age": 0.0,
		"duration": 4.9,
		"count": 5,
		"fired": 0,
		"spawn_cd": 0.0,
		"drops": []
	})


func _add_boss_pressure_bubbles(count: int) -> void:
	var dir = (player_pos - boss_pos).normalized()
	if dir.length() <= 0.01:
		dir = Vector2.LEFT
	boss_attacks.append({
		"kind": "pressure_bubbles",
		"age": 0.0,
		"duration": 1.45 + count * 0.12,
		"count": count,
		"fired": 0,
		"spawn_cd": 0.0,
		"dir": dir,
		"spread": 0.42 + _boss1_fury_scale() * 0.05
	})


func _spawn_boss_pressure_bubble(origin: Vector2, dir: Vector2, damage: float, speed_mult := 1.0) -> void:
	enemy_bullets.append({
		"pos": origin,
		"dir": dir.normalized(),
		"life": 2.7,
		"damage": damage,
		"phase": rng.randf_range(0.0, TAU),
		"type": "boss_pressure_bubble",
		"speed_mult": speed_mult,
		"radius": rng.randf_range(15.0, 22.0)
	})


func _add_boss_tide() -> void:
	var horizontal = rng.randf() > 0.5
	var from_positive = rng.randf() > 0.5
	boss_attacks.append({"kind": "tide", "age": 0.0, "duration": 4.2, "horizontal": horizontal, "positive": from_positive, "hit": false})


func _add_boss_sand(count: int) -> void:
	for i in range(count):
		boss_attacks.append({"kind": "sand", "target": _spawn_point_around_player(120 + i * 40), "age": 0.0, "duration": 4.2, "tick": 0.0})


func _add_boss_pincer() -> void:
	boss_attacks.append({"kind": "pincer", "target": player_pos, "age": 0.0, "duration": 3.0, "hit": false})


func _add_boss_rush() -> void:
	var dir = (player_pos - boss_pos).normalized()
	if dir.length() <= 0.01:
		dir = Vector2.LEFT
	boss_attacks.append({
		"kind": "rush",
		"age": 0.0,
		"duration": 2.65,
		"hit": false,
		"state": "telegraph",
		"from": boss_pos,
		"dir": dir,
		"warn": 0.62,
		"run_time": 0.92,
		"grab_age": 0.0,
		"throw_dir": Vector2.ZERO
	})


func _update_boss_attacks(delta: float) -> void:
	for attack in boss_attacks:
		attack["age"] = float(attack.get("age", 0.0)) + delta
		var age = float(attack["age"])
		var kind = String(attack["kind"])
		if age < 0.0:
			continue
		match kind:
			"bubble":
				var progress = age / float(attack["duration"])
				if progress >= 0.75 and progress <= 0.92 and not bool(attack["hit"]):
					if player_pos.distance_to(attack["target"]) <= 95.0:
						attack["hit"] = true
						_damage_player(int(player_hp_max * 0.15 + 90), "boss")
			"rain":
				if age > 2.2 and age < 2.55 and not bool(attack["hit"]):
					if player_pos.distance_to(attack["target"]) <= 42.0:
						attack["hit"] = true
						_damage_player(int(player_hp_max * 0.08 + 40), "boss")
			"boiling_bubbles":
				attack["spawn_cd"] = float(attack.get("spawn_cd", 0.0)) - delta
				if int(attack.get("fired", 0)) < int(attack.get("count", 5)) and float(attack["spawn_cd"]) <= 0.0:
					var fired = int(attack.get("fired", 0))
					attack["fired"] = fired + 1
					attack["spawn_cd"] = 0.38
					var offset = Vector2.ZERO if fired == 0 else Vector2(rng.randf_range(-58.0, 58.0), rng.randf_range(-42.0, 42.0))
					var target = (player_pos + offset).clamp(Vector2(70, 80), WORLD_SIZE - Vector2(70, 80))
					var launch = boss_pos + Vector2(rng.randf_range(-34.0, 34.0), -50.0)
					var apex = Vector2(launch.x + rng.randf_range(-80.0, 80.0), -120.0 - fired * 18.0)
					var drops: Array = attack.get("drops", [])
					drops.append({
						"age": 0.0,
						"launch": launch,
						"apex": apex,
						"target": target,
						"hit": false,
						"phase": rng.randf_range(0.0, TAU)
					})
					attack["drops"] = drops
					_play_sfx("Frasco.mp3", 0.035, 0.34, 1.12 + fired * 0.03)
				var active_drops = []
				for drop in attack.get("drops", []):
					drop["age"] = float(drop.get("age", 0.0)) + delta
					var drop_age = float(drop["age"])
					if drop_age >= 1.42 and drop_age <= 1.76 and not bool(drop.get("hit", false)):
						if player_pos.distance_to(Vector2(drop["target"])) <= 58.0:
							drop["hit"] = true
							_damage_player(int(player_hp_max * 0.105 + 55), "agua_fervente")
							_spawn_radial_particles(Vector2(drop["target"]), Color(0.36, 0.92, 1.0), 18)
					if drop_age < 2.05:
						active_drops.append(drop)
				attack["drops"] = active_drops
			"pressure_bubbles":
				attack["spawn_cd"] = float(attack.get("spawn_cd", 0.0)) - delta
				if int(attack.get("fired", 0)) < int(attack.get("count", 5)) and float(attack["spawn_cd"]) <= 0.0:
					var fired = int(attack.get("fired", 0))
					attack["fired"] = fired + 1
					attack["spawn_cd"] = max(0.12, 0.24 - _boss1_fury_scale() * 0.025)
					var base_dir = (player_pos - boss_pos).normalized()
					if base_dir.length() <= 0.01:
						base_dir = Vector2(attack.get("dir", Vector2.LEFT)).normalized()
					attack["dir"] = base_dir
					var fan_count = 1 + int(_boss1_fury_scale() >= 1.4)
					for fan in range(fan_count):
						var offset = (float(fan) - float(fan_count - 1) * 0.5) * float(attack.get("spread", 0.42))
						var jitter = rng.randf_range(-0.09, 0.09)
						var dir = base_dir.rotated(offset + jitter).normalized()
						var muzzle = boss_pos + dir * 72.0 + dir.orthogonal() * rng.randf_range(-18.0, 18.0)
						_spawn_boss_pressure_bubble(muzzle, dir, player_hp_max * 0.055 + 38 + enemy_far_damage * 0.7, 1.22 + _boss1_fury_scale() * 0.18)
					_play_sfx("Frasco.mp3", 0.04, 0.30, 0.92 + min(0.35, fired * 0.035))
			"tide":
				var line_pos = _boss_tide_line(attack)
				var distance = abs((player_pos.y - line_pos) if bool(attack["horizontal"]) else (player_pos.x - line_pos))
				if distance < 42.0 and not bool(attack["hit"]):
					attack["hit"] = true
					_damage_player(int(player_hp_max * 0.10 + 65), "boss")
			"sand":
				attack["tick"] = float(attack.get("tick", 0.0)) - delta
				if player_pos.distance_to(attack["target"]) < 70.0 and float(attack["tick"]) <= 0.0:
					attack["tick"] = 0.55
					_damage_player(int(player_hp_max * 0.025 + 18), "boss")
			"pincer":
				if age > 1.55 and age < 1.9 and not bool(attack["hit"]):
					var dx = abs(player_pos.x - float(attack["target"].x))
					var dy = abs(player_pos.y - float(attack["target"].y))
					if dx < 44.0 or dy < 44.0:
						attack["hit"] = true
						_damage_player(int(player_hp_max * 0.12 + 70), "boss")
			"rush":
				var state = String(attack.get("state", "telegraph"))
				var warn = float(attack.get("warn", 0.62))
				var run_time = float(attack.get("run_time", 0.92))
				var dir: Vector2 = Vector2(attack.get("dir", Vector2.LEFT)).normalized()
				if state == "grab":
					_update_boss1_rush_grab(attack, delta)
					continue
				if state == "throw":
					_update_boss1_rush_throw(attack, delta)
					continue
				if age < warn:
					attack["state"] = "telegraph"
				elif age < warn + run_time:
					attack["state"] = "dash"
					var old_pos = boss_pos
					var speed = 560.0 + _boss1_fury_scale() * 95.0
					boss_pos = (boss_pos + dir * speed * delta).clamp(Vector2(76, 76), WORLD_SIZE - Vector2(76, 76))
					for i in range(2):
						effects.append({"pos": old_pos + dir.orthogonal() * rng.randf_range(-42.0, 42.0), "vel": -dir * rng.randf_range(80.0, 150.0), "life": 0.18, "max": 0.18, "color": Color(1.0, 0.28, 0.16, 0.55), "size": rng.randf_range(8.0, 18.0), "kind": "trail"})
					if not bool(attack["hit"]) and _distance_to_segment(player_pos, old_pos, boss_pos) <= 92.0:
						attack["hit"] = true
						_start_boss1_rush_throw(attack, dir)
				else:
					attack["state"] = "final"
	boss_attacks = boss_attacks.filter(func(a): return float(a.get("age", 0.0)) < float(a.get("duration", 1.0)))


func _start_boss1_rush_throw(attack: Dictionary, dir: Vector2) -> void:
	attack["state"] = "grab"
	attack["grab_age"] = 0.0
	attack["grab_start_angle"] = (player_pos - boss_pos).angle()
	var throw_dir = (dir.rotated(rng.randf_range(-0.72, 0.72))).normalized()
	if throw_dir.length() <= 0.01:
		throw_dir = Vector2.from_angle(rng.randf_range(0.0, TAU))
	attack["throw_dir"] = throw_dir
	attack["duration"] = max(float(attack.get("duration", 2.65)), float(attack.get("age", 0.0)) + 1.5)
	player_stun_timer = max(player_stun_timer, 0.74)
	screen_shake_timer = max(screen_shake_timer, 0.20)
	screen_shake_strength = max(screen_shake_strength, 13.0)
	_vibrate(180, 0.66)
	_spawn_radial_particles(player_pos, Color(1.0, 0.38, 0.18), 18)


func _update_boss1_rush_grab(attack: Dictionary, delta: float) -> void:
	attack["grab_age"] = float(attack.get("grab_age", 0.0)) + delta
	var progress = clamp(float(attack["grab_age"]) / 0.44, 0.0, 1.0)
	var angle = float(attack.get("grab_start_angle", 0.0)) + TAU * progress
	player_pos = (boss_pos + Vector2.from_angle(angle) * 82.0).clamp(Vector2(70, 80), WORLD_SIZE - Vector2(70, 80))
	if progress >= 1.0:
		attack["state"] = "throw"
		attack["throw_age"] = 0.0
		player_stun_timer = max(player_stun_timer, 0.46)


func _update_boss1_rush_throw(attack: Dictionary, delta: float) -> void:
	attack["throw_age"] = float(attack.get("throw_age", 0.0)) + delta
	var dir: Vector2 = Vector2(attack.get("throw_dir", Vector2.RIGHT)).normalized()
	var old_pos = player_pos
	var next_pos = player_pos + dir * 860.0 * delta
	var clamped = next_pos.clamp(Vector2(70, 80), WORLD_SIZE - Vector2(70, 80))
	player_pos = clamped
	effects.append({"pos": old_pos, "vel": -dir * 130.0, "life": 0.20, "max": 0.20, "color": Color(1.0, 0.72, 0.24, 0.50), "size": 15.0, "kind": "trail"})
	if clamped != next_pos or float(attack.get("throw_age", 0.0)) >= 0.78:
		_damage_player(int(player_hp_max * 0.18 + 85), "arremesso")
		screen_shake_timer = max(screen_shake_timer, 0.34)
		screen_shake_strength = max(screen_shake_strength, 22.0)
		_vibrate(260, 0.82)
		_spawn_radial_particles(player_pos, Color(1.0, 0.34, 0.18), 28)
		attack["age"] = float(attack.get("duration", 1.0))


func _boss_tide_line(attack: Dictionary) -> float:
	var age = clamp(float(attack.get("age", 0.0)) / max(0.1, float(attack.get("duration", 1.0))), 0.0, 1.0)
	if bool(attack["horizontal"]):
		return lerp(-80.0, WORLD_SIZE.y + 80.0, age) if bool(attack["positive"]) else lerp(WORLD_SIZE.y + 80.0, -80.0, age)
	return lerp(-80.0, WORLD_SIZE.x + 80.0, age) if bool(attack["positive"]) else lerp(WORLD_SIZE.x + 80.0, -80.0, age)


func _start_boss_call() -> void:
	if not boss_ready or boss_active or boss_dead or boss_call_timer >= 0.0:
		return
	boss_call_timer = BOSS_CALL_COUNTDOWN
	mode = "boss_call"


func _update_boss_call(delta: float) -> void:
	boss_call_timer -= delta
	_update_effects(delta)
	if boss_call_timer <= 0.0:
		mode = "game"
		boss_active = true
		_play_music("Fase3_Boss.mp3" if current_phase == 3 else ("Fase2_Boss.mp3" if current_phase == 2 else "Boss1-1.mp3"))
		if current_phase == 3:
			boss_hp_max = max(boss_hp_max, 8200.0 + score_total * 0.18 + enemies_killed * 14.0)
			boss_name = "PAI-RATO"
			boss_title_color = Color(0.72, 0.92, 0.24)
		elif current_phase == 2:
			boss_hp_max = max(boss_hp_max, 5800.0 + score_total * 0.16 + enemies_killed * 12.0)
			boss_name = "SENTINELA GLACIAL"
			boss_title_color = Color(0.50, 0.86, 1.0)
		else:
			boss_hp_max = max(boss_hp_max, BOSS_BASE_HP + score_total * 0.12 + enemies_killed * 9.0)
			boss_name = "CARANGUEJO COSMICO GIGANTE"
			boss_title_color = Color(1.0, 0.52, 0.16)
		boss_hp = boss_hp_max
		boss_poison_timer = 0.0
		boss_poison_tick = 0.0
		boss_parasite_seeds = 0
		boss_parasite_mark_time = 0.0
		boss_pos = Vector2(WORLD_SIZE.x * 0.5, -220.0)
		boss_entry_timer = BOSS3_ENTRY_TIME if current_phase == 3 else (BOSS2_ENTRY_TIME if current_phase == 2 else BOSS_ENTRY_TIME)
		boss_attack_timer = 4.3 if current_phase == 3 else (BOSS2_ATTACK_INTERVAL if current_phase == 2 else BOSS_ATTACK_BASE_COOLDOWN)
		boss_stage_timer = 0.0
		boss_empurrou_player = false
		boss_attacks.clear()
		boss_transition_waves.clear()
		_reset_boss1_rewind_state()
		boss2_ice_shards.clear()
		boss2_snow_zones.clear()
		boss2_frost_particles.clear()
		_reset_phase3_state()
		if current_phase == 3:
			boss3_dialogue_timer = 3.2
			_add_text("A FE TEM FOME", WORLD_SIZE * 0.5 + Vector2(0, -118), boss_title_color, 2.0, 28)
		_add_text("BOSS %d" % current_phase, WORLD_SIZE * 0.5 + Vector2(0, -150), boss_title_color, 2.0, 36)


func _update_shop_countdown(delta: float) -> void:
	forced_shop_timer -= delta
	if forced_shop_timer <= 0.0:
		_open_shop(true)
		return
	_update_audio_volumes()
	_update_shop_countdown_tick()
	_update_game(delta * _shop_countdown_time_scale())


func _shop_countdown_time_scale() -> float:
	if forced_shop_timer > FORCED_SHOP_SLOW_START:
		return 1.0
	var slow_progress = clamp(1.0 - forced_shop_timer / FORCED_SHOP_SLOW_START, 0.0, 1.0)
	return lerp(1.0, FORCED_SHOP_MIN_TIME_SCALE, slow_progress)


func _shop_countdown_visible_second() -> int:
	return int(ceil(max(0.01, forced_shop_timer)))


func _shop_countdown_tick_volume() -> float:
	var progress = clamp(1.0 - (forced_shop_timer - FORCED_SHOP_SLOW_START) / max(0.01, FORCED_SHOP_WARNING - FORCED_SHOP_SLOW_START), 0.0, 1.0)
	return lerp(0.10, 0.70, progress)


func _shop_countdown_audio_duck() -> float:
	if mode != "shop_countdown" or forced_shop_timer <= 0.0:
		return 1.0
	var progress = clamp(1.0 - forced_shop_timer / FORCED_SHOP_WARNING, 0.0, 1.0)
	return lerp(1.0, 0.32, progress)


func _update_shop_countdown_tick() -> void:
	var second = _shop_countdown_visible_second()
	if second == shop_countdown_last_second:
		return
	shop_countdown_last_second = second
	_play_sfx("shop_countdown_tick", 0.0, _shop_countdown_tick_volume())


func _shop_purchase_animating() -> bool:
	return shop_purchase_anim_timer > 0.0 and not shop_purchase_pending_card.is_empty()


func _update_shop(delta: float) -> void:
	shop_select_pulse_timer = max(0.0, shop_select_pulse_timer - delta)
	_update_effects(delta)
	if not _shop_purchase_animating():
		return
	shop_purchase_anim_timer = max(0.0, shop_purchase_anim_timer - delta)
	if shop_purchase_anim_timer > 0.0:
		return
	var card: Dictionary = shop_purchase_pending_card
	shop_purchase_pending_card = {}
	score -= card_cost
	card_cost += 100
	_apply_card(card)
	if shop_purchase_pending_can_continue and score >= card_cost:
		shop_cards = _roll_shop_cards()
		shop_selected = 0
		shop_select_pulse_index = 0
		shop_select_pulse_timer = 0.22
		shop_purchase_pending_can_continue = false
		return
	shop_purchase_pending_can_continue = false
	_finish_shop()


func _open_shop(forced: bool) -> void:
	if mode == "shop":
		return
	previous_mode = "game"
	mode = "shop"
	_update_audio_volumes()
	shop_rerolls = 3
	shop_purchase_anim_timer = 0.0
	shop_purchase_pending_card = {}
	shop_purchase_pending_can_continue = false
	if score < card_cost:
		_add_text("Sem pontos para carta", player_pos + Vector2(0, -92), Color(1.0, 0.52, 0.24), 1.0, 22)
		_finish_shop()
		return
	shop_cards = _roll_shop_cards()
	shop_selected = 0
	shop_select_pulse_index = 0
	shop_select_pulse_timer = 0.20
	if forced:
		_add_text("Loja forcada", player_pos + Vector2(0, -92), Color(0.0, 1.0, 0.82), 1.4, 26)


func _roll_shop_cards() -> Array:
	var pool_rares = []
	var pool_commons = []

	for card in CARDS:
		if _is_rare_card(card):
			pool_rares.append(card)
		else:
			pool_commons.append(card)

	var picks = []
	var chance_rara = _chance_carta_rara()

	# Determine if we should roll a rare card
	if rng.randf() < chance_rara and pool_rares.size() > 0:
		var idx = rng.randi_range(0, pool_rares.size() - 1)
		picks.append(pool_rares[idx])
		pool_rares.remove_at(idx)

	# Fill remaining slots with commons
	while picks.size() < 3 and pool_commons.size() > 0:
		var idx = rng.randi_range(0, pool_commons.size() - 1)
		picks.append(pool_commons[idx])
		pool_commons.remove_at(idx)

	# Fallback to rares if not enough commons
	while picks.size() < 3 and pool_rares.size() > 0:
		var idx = rng.randi_range(0, pool_rares.size() - 1)
		picks.append(pool_rares[idx])
		pool_rares.remove_at(idx)

	picks.shuffle()
	return picks


func _is_rare_card(card: Dictionary) -> bool:
	return String(card.get("name", "")) in RARE_CARD_NAMES


func _card_rarity_color(card: Dictionary) -> Color:
	return CARD_RARITY_RARE_COLOR if _is_rare_card(card) else CARD_RARITY_COMMON_COLOR


func _card_rarity_label(card: Dictionary) -> String:
	return "RARA" if _is_rare_card(card) else "COMUM"


func _chance_carta_rara() -> float:
	var chance_rara_base = 0.05
	var chance_rara_maxima = 0.25
	var sorte_peso_raridade = 0.45
	var sorte_bonus_raridade_por_carta = 0.015

	var qtd_sorte = cards_bought.get("Sorte", 0)
	var chance = chance_rara_base + luck * sorte_peso_raridade + qtd_sorte * sorte_bonus_raridade_por_carta
	return clamp(chance, 0.0, chance_rara_maxima)


func _buy_selected_card() -> void:
	if shop_cards.is_empty():
		return
	if _shop_purchase_animating():
		return
	if score < card_cost:
		_finish_shop()
		return
	var card: Dictionary = shop_cards[shop_selected]
	var next_score = score - card_cost
	var next_cost = card_cost + 100
	shop_purchase_pending_card = card.duplicate(true)
	shop_purchase_pending_can_continue = next_score >= next_cost
	shop_purchase_anim_timer = SHOP_PURCHASE_ANIM_TIME
	shop_select_pulse_index = shop_selected
	shop_select_pulse_timer = 0.26


func _set_shop_selection(index: int) -> void:
	if _shop_purchase_animating():
		return
	if index < 0 or index >= shop_cards.size():
		return
	if shop_selected == index:
		return
	shop_selected = index
	shop_select_pulse_index = index
	shop_select_pulse_timer = 0.26


func _reroll_shop() -> void:
	if _shop_purchase_animating():
		return
	if shop_rerolls > 0:
		shop_rerolls -= 1
		shop_cards = _roll_shop_cards()
		shop_selected = 0
		shop_select_pulse_index = 0
		shop_select_pulse_timer = 0.20


func _card_category(card_name: String) -> String:
	match card_name:
		"Speed Boost": return "MOBILIDADE TEMPORAL"
		"Porcao": return "SUPORTE E ELIXIR VITAL"
		"Disparo crescente": return "POTENCIA DE COMBATE"
		"Tempestade": return "ANOMALIA CRITICA"
		"Roubo de Vida": return "REGENERACAO E SUSTENTO"
		"Trembo": return "SOBREVIVENCIA CAUSAL"
		"Speed Atack": return "FLUIDEZ DE DISPAROS"
		"Teleporte": return "MANIPULACAO ESPACIAL"
		"Petro": return "CONSTRUCTO TEMPORAL"
		"Defesa": return "RESISTENCIA FASICA"
		"Sorte": return "PROBABILIDADE FAVORAVEL"
		"Poison": return "TOXINA DE ALTA ESCALA"
		"Coletora": return "CEIFADOR E EXECUCAO"
		"Mercenaria": return "COMBO E PONTUACAO"
	return "MELHORIA"


func _card_lore(card_name: String) -> String:
	match card_name:
		"Speed Boost": return "O vento corre rapido, mas voce deve correr ainda mais rapido que o proprio tempo."
		"Porcao": return "Uma gota de pura energia vital extraida de linhas temporais estaveis."
		"Disparo crescente": return "Deixe cada projetil carregar o peso do colapso temporal."
		"Tempestade": return "O caos atmosferico canalizado em disparos de precisao quantica."
		"Roubo de Vida": return "Drene a forca vital dos oponentes para restaurar sua integridade."
		"Trembo": return "A morte e apenas um contratempo em um loop perfeitamente controlado."
		"Speed Atack": return "Acelere sua frequencia temporal ate seus tiros virarem um borrao continuo."
		"Teleporte": return "Dobre o espaco para estar exatamente onde o inimigo nao espera."
		"Petro": return "Um guardiao leal que se alimenta de energia e lealdade ancestral."
		"Defesa": return "Aumente a densidade do seu campo de forca contra impactos nocivos."
		"Sorte": return "Altere as probabilidades de eventos quanticos a seu favor."
		"Poison": return "Uma toxina que envelhece aceleradamente as celulas de quem a toca."
		"Coletora": return "O ceifador nao espera por aqueles que ja estao a beira do abismo."
		"Mercenaria": return "Toda queda vira contrato. Todo contrato bem cumprido paga mais caro."
	return ""


func _apply_card(card: Dictionary) -> void:
	var name = String(card["name"])
	cards_bought[name] = int(cards_bought.get(name, 0)) + 1
	match name:
		"Speed Boost":
			player_speed *= 1.065
		"Porcao":
			var heal = int(player_hp_max * 0.45)
			if player_hp + heal > player_hp_max:
				player_hp_max += int((player_hp + heal - player_hp_max) * 0.35)
			player_hp = min(player_hp_max, player_hp + heal)
		"Disparo crescente":
			player_damage += 10.0
		"Tempestade":
			player_damage += 5.0
			player_crit_chance += 0.02
		"Trembo":
			trembo_charges = min(2, trembo_charges + 1)
			trembo_pos = player_pos + Vector2(62.0 * trembo_side, 18.0)
			trembo_heal_timer = 0.0
		"Roubo de Vida":
			player_lifesteal += 0.001
		"Speed Atack":
			player_attack_interval = max(0.18, player_attack_interval - 0.026)
		"Teleporte":
			player_dash_cooldown = max(0.50, player_dash_cooldown - 0.30)
		"Petro":
			petro_active = true
			petro_fire_timer = 0.0
			petro_damage += 5.0
			var previous_evolution = petro_evolution
			var copies = int(cards_bought.get("Petro", 1))
			petro_evolution = min(3, 1 + int((copies - 1) / 2))
			if petro_evolution >= 2 and previous_evolution < 2:
				petro_hp_max += 1400.0
			if petro_evolution >= 3 and previous_evolution < 3:
				petro_hp_max += 2800.0
				petro_defense += 24.0
				petro_damage += 360.0
			petro_hp = min(petro_hp_max, petro_hp + petro_hp_max * 0.58)
		"Defesa":
			player_defense = min(50.0, player_defense + 3.5)
		"Sorte":
			luck += 0.003
		"Poison":
			if poison_damage <= 0.0:
				poison_damage = 0.05
			poison_damage += 0.009
		"Coletora":
			if execute_threshold <= 0.0:
				execute_threshold = 0.05
			execute_threshold = min(0.20, execute_threshold + 0.008)
			collector_hud_pulse = 0.8
		"Mercenaria":
			mercenary_hud_pulse = 0.8
	_add_text(name, player_pos + Vector2(0, -100), Color(card["color"]), 1.3, 25)


func _close_shop() -> void:
	_finish_shop()


func _finish_shop() -> void:
	shop_purchase_anim_timer = 0.0
	shop_purchase_pending_card = {}
	shop_purchase_pending_can_continue = false
	mode = "shop_return"
	_update_audio_volumes()
	shop_return_timer = SHOP_RETURN_TIME
	forced_shop_timer = -1.0
	forced_shop_triggered = false
	shop_auto_elapsed = 0.0
	next_forced_shop_time = shop_auto_interval if shop_auto_enabled else INF


func _update_shop_return(delta: float) -> void:
	shop_return_timer -= delta
	_update_effects(delta)
	if shop_return_timer <= 0.0:
		mode = previous_mode
		shop_return_timer = 0.0


func _affordable_card_count() -> int:
	var temp_score = score
	var temp_cost = card_cost
	var count = 0
	while temp_score >= temp_cost:
		temp_score -= temp_cost
		temp_cost += 100
		count += 1
	return count


func _should_trigger_forced_shop() -> bool:
	if not shop_auto_enabled or forced_shop_triggered or forced_shop_timer >= 0.0:
		return false
	return shop_auto_elapsed >= shop_auto_interval


func _set_shop_auto_enabled(enabled: bool) -> void:
	shop_auto_enabled = enabled
	forced_shop_enabled = enabled
	forced_shop_timer = -1.0
	forced_shop_triggered = false
	shop_countdown_last_second = -1
	shop_auto_elapsed = 0.0
	if enabled:
		next_forced_shop_time = shop_auto_interval
	else:
		next_forced_shop_time = INF
		if mode == "shop_countdown":
			mode = "game"
		if previous_mode == "shop_countdown":
			previous_mode = "game"
		if settings_previous_mode == "shop_countdown":
			settings_previous_mode = "game"


func _try_open_manual_shop() -> void:
	if shop_auto_enabled or mode != "game":
		return
	if score < card_cost:
		_add_text("FALTAM %d PONTOS" % (card_cost - score), player_pos + Vector2(0, -96), Color(1.0, 0.56, 0.28), 0.9, 20)
		return
	_open_shop(false)


func _start_forced_shop_countdown() -> void:
	if not shop_auto_enabled:
		return
	forced_shop_triggered = true
	forced_shop_timer = FORCED_SHOP_WARNING
	shop_countdown_last_second = -1
	mode = "shop_countdown"


func _start_pause_countdown() -> void:
	if mode != "game" and mode != "shop_countdown" and mode != "boss_call":
		return
	previous_mode = mode
	forced_shop_timer = -1.0
	mode = "paused"
	_begin_pause_music_fade_out()
	_block_ui_input()


func _update_pause_countdown(delta: float) -> void:
	forced_shop_timer -= delta
	if forced_shop_timer <= 0.0:
		mode = "paused"


func _resume_from_pause() -> void:
	mode = previous_mode
	forced_shop_timer = -1.0
	_begin_pause_music_fade_in()
	_block_ui_input()


func _damage_player(amount: int, source: String) -> void:
	if _player_invulnerable():
		return
	_play_sfx("hit_person.mp3")
	var final = max(1, amount - int(player_defense))
	player_hp -= final
	if int(cards_bought.get("Mercenaria", 0)) > 0 and (combo_kills > 0 or mercenary_bonus_points > 0):
		combo_kills = 0
		mercenary_bonus_points = 0
		mercenary_hud_pulse = 1.2
		_add_text("CONTRATO QUEBRADO", player_pos + Vector2(0, -108), Color(1.0, 0.24, 0.12), 1.1, 20)
	last_damage_time = time_alive
	damage_flash_timer = 0.22
	screen_shake_timer = 0.24
	screen_shake_strength = clamp(5.0 + final * 0.18, 7.0, 22.0)
	_vibrate(260, 0.85)
	_add_text("-%d" % final, player_pos + Vector2(rng.randf_range(-24, 24), -72), Color(1.0, 0.18, 0.20), 0.75, 22)
	_spawn_radial_particles(player_pos, Color(1.0, 0.08, 0.12), 8)


func _handle_player_down() -> void:
	if trembo_charges > 0:
		var death_pos = player_pos
		trembo_charges -= 1
		player_hp = player_hp_max
		trembo_invulnerability = TREMBO_REVIVE_INVULNERABILITY
		player_pos = Vector2(rng.randf_range(110.0, WORLD_SIZE.x - 110.0), rng.randf_range(110.0, WORLD_SIZE.y - 110.0))
		for enemy in enemies:
			var distance = death_pos.distance_to(Vector2(enemy["pos"]))
			if distance <= 230.0:
				var push = (Vector2(enemy["pos"]) - death_pos).normalized()
				enemy["pos"] = (Vector2(enemy["pos"]) + push * (230.0 - distance)).clamp(Vector2(40, 40), WORLD_SIZE - Vector2(40, 40))
		_spawn_radial_particles(death_pos, Color.WHITE, 42)
		_spawn_radial_particles(trembo_pos, Color(0.35, 0.82, 1.0), 30)
		shockwaves.append({"pos": death_pos, "radius": 10.0, "max": 230.0, "life": 0.72, "damage": 0.0, "hit": {}})
		_play_sfx("Portal.mp3", 0.05, 0.72)
		_add_text("REVERSAO TEMPORAL", death_pos + Vector2(0, -96), Color(0.25, 0.78, 1.0), 2.0, 30)
		if trembo_charges > 0:
			trembo_pos = player_pos + Vector2(62.0, 18.0)
		return
	mode = "game_over"


func _update_phase_transition(delta: float) -> void:
	phase_transition_timer -= delta
	_update_environment_weather(delta)
	_update_effects(delta)
	if phase_transition_timer <= 0.0 and pending_phase > 0:
		_advance_to_phase(pending_phase)


func _spawn_phase_fragment(pos: Vector2, next_phase: int) -> void:
	phase_fragment = {
		"pos": pos,
		"next_phase": next_phase,
		"pulse": 0.0,
		"life": 0.0
	}


func _start_phase_transition(next_phase: int) -> void:
	pending_phase = next_phase
	mode = "phase_transition"
	phase_transition_timer = PHASE_TRANSITION_TIME
	_add_text("FRATURA DIMENSIONAL", player_pos + Vector2(0, -120), Color(0.64, 0.92, 1.0), 1.8, 30)


func _update_phase_fragment(delta: float) -> void:
	if phase_fragment.is_empty():
		return
	phase_fragment["life"] = float(phase_fragment.get("life", 0.0)) + delta
	phase_fragment["pulse"] = float(phase_fragment.get("pulse", 0.0)) + delta * 4.0
	if player_pos.distance_to(phase_fragment["pos"]) <= BOSS_FRAGMENT_PICKUP_RADIUS:
		var next_phase = int(phase_fragment.get("next_phase", 0))
		phase_fragment.clear()
		if next_phase > 0:
			_start_phase_transition(next_phase)


func _update_effects(delta: float) -> void:
	for effect in effects:
		effect["life"] = float(effect["life"]) - delta
		var kind = String(effect.get("kind", ""))
		if kind == "enemy_shard":
			var delay = max(0.0, float(effect.get("delay", 0.0)) - delta)
			effect["delay"] = delay
			if delay > 0.0:
				if effect.has("vel"):
					effect["pos"] += effect["vel"] * delta
					var delayed_vel: Vector2 = effect["vel"]
					effect["vel"] = delayed_vel * max(0.0, 1.0 - delta * 3.2)
			else:
				var to_player = player_pos - effect["pos"]
				var dir = to_player.normalized() if to_player.length() > 0.01 else Vector2.ZERO
				var desired_speed = lerp(float(effect.get("speed", 70.0)), float(effect.get("home_speed", 420.0)), clamp(1.0 - float(effect["life"]) / float(effect.get("max", 1.0)), 0.0, 1.0))
				var current_vel: Vector2 = effect.get("vel", Vector2.ZERO)
				var vel = current_vel.lerp(dir * desired_speed, min(1.0, delta * 7.5))
				effect["vel"] = vel
				effect["pos"] += vel * delta
				effect["phase"] = float(effect.get("phase", 0.0)) + delta * float(effect.get("spin", 6.0))
				if to_player.length() <= 26.0:
					effect["life"] = 0.0
					var pickup_color: Color = effect["color"]
					_spawn_radial_particles(player_pos + Vector2(rng.randf_range(-10, 10), rng.randf_range(-10, 10)), pickup_color, 2)
		elif effect.has("vel"):
			effect["pos"] += effect["vel"] * delta
			if kind == "trail":
				var trail_vel: Vector2 = effect["vel"]
				effect["vel"] = trail_vel * max(0.0, 1.0 - delta * 6.0)
	for slash in slashes:
		slash["life"] = float(slash["life"]) - delta
	for anchor in anchors:
		anchor["life"] = float(anchor["life"]) - delta
	for link in seed_links:
		link["time"] = float(link["time"]) - delta
	effects = effects.filter(func(e): return float(e["life"]) > 0.0)
	slashes = slashes.filter(func(s): return float(s["life"]) > 0.0)
	anchors = anchors.filter(func(a): return float(a["life"]) > 0.0)
	seed_links = seed_links.filter(func(l): return float(l["time"]) > 0.0)


func _add_text(text: String, pos: Vector2, color: Color, life: float, size: int) -> void:
	effects.append({"text": text, "pos": pos, "life": life, "max": life, "color": color, "size": size, "vel": Vector2(0, -24)})


func _spawn_radial_particles(pos: Vector2, color: Color, count: int) -> void:

	if not gfx_particles: return
	if not gfx_particles: return
	for i in range(count):
		effects.append({"text": "", "pos": pos, "life": rng.randf_range(0.25, 0.55), "max": 0.55, "color": color, "size": rng.randi_range(3, 7), "vel": Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(40, 120)})


func _enemy_shard_color(enemy: Dictionary) -> Color:
	match String(enemy.get("type", ENEMY_COMMON)):
		ENEMY_AGGLOMERATOR:
			return Color(0.86, 0.78, 1.0)
		ENEMY_STALKER:
			return Color(0.42, 0.94, 1.0)
		ENEMY_PROJECTOR:
			return Color(0.84, 0.64, 1.0)
		ENEMY_CRYSTAL:
			return Color(0.22, 0.90, 1.0)
		ENEMY_CURATER:
			return Color(0.44, 1.0, 0.60)
		ENEMY_LARAPIO:
			return Color(0.92, 0.52, 1.0)
		ENEMY_ATIRADOR:
			return Color(0.74, 0.88, 1.0)
		ENEMY_KAMIKAZE:
			return Color(1.0, 0.52, 0.52)
	return Color(0.76, 0.88, 1.0)


func _spawn_enemy_desfragmentation(pos: Vector2, color: Color, count: int) -> void:
	var total = int(clamp(count, 10, 28))
	for i in range(total):
		var angle = rng.randf_range(0.0, TAU)
		var speed = rng.randf_range(90.0, 250.0)
		var size = rng.randf_range(4.0, 10.0)
		effects.append({
			"kind": "enemy_shard",
			"text": "",
			"pos": pos + Vector2.from_angle(angle) * rng.randf_range(6.0, 20.0),
			"life": rng.randf_range(0.85, 1.25),
			"max": 1.25,
			"color": Color(color.r, color.g, color.b, 1.0),
			"size": size,
			"vel": Vector2.from_angle(angle) * speed,
			"speed": speed,
			"home_speed": rng.randf_range(360.0, 560.0),
			"delay": rng.randf_range(0.05, 0.18),
			"phase": rng.randf_range(0.0, TAU),
			"spin": rng.randf_range(5.0, 11.0)
		})


func _projectile_palette(kind: String) -> Dictionary:
	match kind:
		"eletrica":
			return {"core": Color(0.76, 1.0, 1.0), "glow": Color(0.10, 0.95, 1.0, 0.92), "trail": Color(0.82, 0.22, 1.0, 0.46), "size": 8.0, "trail_size": 7.0}
		"eletrica_charged":
			return {"core": Color(1.0, 1.0, 1.0), "glow": Color(0.18, 1.0, 1.0, 1.0), "trail": Color(0.92, 0.32, 1.0, 0.62), "size": 11.0, "trail_size": 10.0}
		"prismatica":
			return {"core": Color(1.0, 1.0, 1.0), "glow": Color(0.36, 1.0, 0.96, 0.95), "trail": Color(1.0, 0.42, 0.78, 0.44), "size": 7.0, "trail_size": 6.0}
		"parasitica":
			return {"core": Color(0.80, 1.0, 0.54), "glow": Color(0.24, 0.95, 0.38, 0.90), "trail": Color(0.78, 1.0, 0.26, 0.42), "size": 8.0, "trail_size": 8.0}
		"gravitante":
			return {"core": Color(0.92, 0.98, 1.0), "glow": Color(0.50, 0.78, 1.0, 0.92), "trail": Color(0.74, 0.54, 1.0, 0.34), "size": 9.0, "trail_size": 9.0}
		"ancorada":
			return {"core": Color(1.0, 1.0, 1.0), "glow": Color(0.26, 0.96, 1.0, 0.90), "trail": Color(1.0, 0.78, 0.24, 0.38), "size": 8.0, "trail_size": 6.0}
		"petro":
			return {"core": Color(0.82, 1.0, 1.0), "glow": Color(0.16, 0.92, 1.0, 0.88), "trail": Color(0.72, 1.0, 1.0, 0.38), "size": 6.0, "trail_size": 5.0}
	return {"core": Color.WHITE, "glow": Color(0.72, 0.92, 1.0, 0.9), "trail": Color(0.72, 0.92, 1.0, 0.35), "size": 7.0, "trail_size": 6.0}


func _spawn_projectile_muzzle(kind: String, pos: Vector2, dir: Vector2) -> void:
	var palette = _projectile_palette(kind)
	var glow: Color = palette["glow"]
	var core: Color = palette["core"]
	var count = 7 if kind == "eletrica_charged" else 5
	_spawn_radial_particles(pos, glow, count)
	for i in range(3):
		var spread = rng.randf_range(-0.42, 0.42)
		var spark_dir = dir.rotated(spread)
		effects.append({
			"kind": "trail",
			"text": "",
			"pos": pos + spark_dir * rng.randf_range(6.0, 12.0),
			"life": rng.randf_range(0.12, 0.20),
			"max": 0.20,
			"color": Color(core.r, core.g, core.b, 0.95),
			"size": rng.randf_range(6.0, 11.0),
			"vel": spark_dir * rng.randf_range(120.0, 280.0)
		})


func _emit_projectile_trail(bullet: Dictionary) -> void:
	var palette = _projectile_palette(String(bullet.get("kind", "")))
	var trail: Color = palette["trail"]
	var dir = Vector2(bullet.get("dir", Vector2.RIGHT))
	var side = dir.orthogonal().normalized()
	var drift = side * sin(float(bullet.get("age", 0.0)) * 18.0 + float(bullet.get("phase", 0.0))) * 6.0
	effects.append({
		"kind": "trail",
		"text": "",
		"pos": bullet["pos"] - dir * rng.randf_range(12.0, 22.0) + drift,
		"life": rng.randf_range(0.12, 0.22),
		"max": 0.22,
		"color": trail,
		"size": float(palette["trail_size"]) + rng.randf_range(-1.5, 1.5),
		"vel": -dir * rng.randf_range(20.0, 55.0) + drift * 2.5
	})


func _draw() -> void:
	var viewport = get_viewport_rect().size
	_update_button_layout(viewport)
	match mode:
		"menu":
			_draw_menu(viewport)
		"settings":
			_draw_settings(viewport)
		"settings_gameplay":
			_draw_gameplay_settings(viewport)
		"settings_audio":
			_draw_audio_settings(viewport)
		"settings_graphics":
			_draw_graphics_settings(viewport)
		"edit_layout":
			_draw_edit_layout(viewport)
		"catalog":
			_draw_catalog(viewport)
		"manifest":
			_draw_manifest_select(viewport)
		"shop":
			_draw_game(viewport)
			_draw_shop(viewport)
		"shop_return":
			_draw_game(viewport)
			_draw_centered("VOLTANDO EM %.0fs" % max(0.0, shop_return_timer), Vector2(viewport.x * 0.5, 92), 30, Color(0.72, 1.0, 1.0))
		"shop_countdown":
			_draw_game(viewport)
			_draw_shop_countdown_alert(viewport)
		"boss_call":
			_draw_game(viewport)
			_draw_centered("BOSS CHEGANDO EM %.1fs" % max(0.0, boss_call_timer), Vector2(viewport.x * 0.5, 92), 34, Color(1.0, 0.45, 0.16))
		"pause_countdown":
			_draw_game(viewport)
			_draw_centered("PAUSE EM %.0fs" % max(0.0, forced_shop_timer), Vector2(viewport.x * 0.5, 92), 34, Color(0.72, 1.0, 1.0))
		"paused":
			_draw_game(viewport)
			_draw_pause(viewport)
		"pause_deck":
			_draw_game(viewport)
			_draw_pause_deck(viewport)
		"game_over":
			_draw_game(viewport)
			_draw_end_overlay(viewport, "GAME OVER", Color(1.0, 0.12, 0.18))
		"victory":
			_draw_game(viewport)
			_draw_end_overlay(viewport, "BOSS VENCIDO", Color(1.0, 0.82, 0.22))
		_:
			_draw_game(viewport)


func _draw_menu(viewport: Vector2) -> void:
	var msec = Time.get_ticks_msec()
	var cycle_pos = msec % 6950
	var current_bg: Texture2D = null
	if cycle_pos < 5000:
		current_bg = textures["menu_panels"][0]
	else:
		var trans_pos = int((cycle_pos - 5000) / 150)
		var sequence = [0, 3, 1, 3, 4, 2, 1, 2, 3, 4, 2, 1, 4]
		var idx = clamp(trans_pos, 0, sequence.size() - 1)
		current_bg = textures["menu_panels"][sequence[idx]]

	var accent = Color(0.0, 1.0, 0.82)
	var danger = Color(1.0, 0.08, 0.46)
	_draw_holo_background(viewport, current_bg, accent)
	var portrait = _is_portrait(viewport)
	menu_buttons = _menu_rects(viewport)

	var safe = max(18.0, min(viewport.x, viewport.y) * 0.034)
	var title_size = 34 if portrait else 46
	var title_pos = Vector2(viewport.x * 0.5, safe + title_size * (0.62 if portrait else 0.92))
	_draw_glitch_title("RUPTURA TEMPORAL", title_pos, title_size, accent)

	var top_chip = Rect2(viewport.x * 0.5 - (170.0 if portrait else 210.0), title_pos.y + title_size * (0.50 if portrait else 0.58), 340.0 if portrait else 420.0, 30.0)
	_draw_hub_chip(top_chip, "APOLO 2.0 / HUB DE RUPTURA", accent, true)

	var avatar_rect: Rect2
	var primary_rect: Rect2 = menu_buttons["start"]
	var manifest_rect: Rect2
	var status_rect: Rect2
	if portrait:
		avatar_rect = Rect2(viewport.x * 0.13, viewport.y * 0.145, viewport.x * 0.74, viewport.y * 0.27)
		manifest_rect = Rect2(viewport.x * 0.08, menu_buttons["catalog"].end.y + 12.0, viewport.x * 0.84, clamp(viewport.y * 0.095, 66.0, 84.0))
		status_rect = Rect2(viewport.x * 0.08, manifest_rect.end.y + 12.0, viewport.x * 0.84, 42.0)
	else:
		var avatar_w = min(360.0, viewport.x * 0.30)
		avatar_rect = Rect2(viewport.x - avatar_w - viewport.x * 0.09, viewport.y * 0.24, avatar_w, viewport.y * 0.58)
		manifest_rect = Rect2(viewport.x * 0.08, menu_buttons["catalog"].end.y + 14.0, min(430.0, viewport.x * 0.38), 96.0)
		status_rect = Rect2(viewport.x * 0.08, manifest_rect.end.y + 14.0, min(430.0, viewport.x * 0.38), 42.0)

	_draw_holo_panel(avatar_rect, accent, true, 0.24)
	_draw_energy_particles(avatar_rect, danger, 26)
	for i in range(5):
		var scan_y = avatar_rect.position.y + fmod(Time.get_ticks_msec() * 0.030 + i * avatar_rect.size.y * 0.22, avatar_rect.size.y)
		draw_line(Vector2(avatar_rect.position.x + 18.0, scan_y), Vector2(avatar_rect.end.x - 18.0, scan_y), Color(accent.r, accent.g, accent.b, 0.08 + i * 0.016), 1.0)

	var geo_tex: Texture2D = textures["player_idle"][int(Time.get_ticks_msec() / 170) % textures["player_idle"].size()]
	if portrait:
		_draw_entity_fit(geo_tex, avatar_rect.get_center() + Vector2(0, avatar_rect.size.y * 0.11), Vector2(avatar_rect.size.x * 0.52, avatar_rect.size.y * 0.90), Color.WHITE, true)
	else:
		_draw_entity_fit(geo_tex, avatar_rect.get_center() + Vector2(0, avatar_rect.size.y * 0.08), Vector2(avatar_rect.size.x * 0.58, avatar_rect.size.y * 0.82), Color.WHITE, true)

	_draw_hub_button(menu_buttons["start"], "INICIAR", "selecao de manifestacao", accent, menu_selected == 0, true)
	_draw_hub_button(menu_buttons["catalog"], "CATALOGO", "bestiario e cartas", Color(0.36, 0.84, 1.0), menu_selected == 1, false)
	_draw_hub_button(menu_buttons["settings"], "CONFIG", "controles e jogo", Color(1.0, 0.74, 0.22), menu_selected == 2, false)
	_draw_hub_button(menu_buttons["exit"], "SAIR", "", Color(1.0, 0.26, 0.36), menu_selected == 3, false)

	_draw_hub_manifest_card(manifest_rect)
	var status = "LOJA: AUTOMATICA" if shop_auto_enabled else "LOJA: MANUAL"
	_draw_hub_chip(status_rect, status, Color(0.72, 0.92, 1.0), false)
	draw_string(font, Vector2(safe, viewport.y - safe * 0.55), "v" + GAME_VERSION, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.74, 0.92, 1.0, 0.78))


func _draw_menu_button(rect: Rect2, label: String, is_selected: bool) -> void:
	if is_selected:
		var bg_color = Color(0.0, 0.70, 0.78, 0.25)
		draw_rect(rect, bg_color, true)
		var border_color = Color(0.0, 1.0, 0.90, 1.0)
		draw_rect(rect, border_color, false, 2)
		var bar_rect = Rect2(rect.position, Vector2(6.0, rect.size.y))
		draw_rect(bar_rect, Color(0.0, 1.0, 0.90), true)
		_draw_centered(label, rect.get_center() + Vector2(0, 6), 16, Color.WHITE)
	else:
		var bg_color = Color(0.06, 0.06, 0.10, 0.62)
		draw_rect(rect, bg_color, true)
		var border_color = Color(0.39, 0.39, 0.58, 0.18)
		draw_rect(rect, border_color, false, 1)
		_draw_centered(label, rect.get_center() + Vector2(0, 6), 16, Color(0.78, 0.78, 0.86))


func _draw_hub_button(rect: Rect2, label: String, detail: String, accent: Color, is_selected: bool, primary := false) -> void:
	var fill = 0.64 if primary else 0.52
	_draw_holo_panel(rect, accent, is_selected or primary, fill)
	if is_selected:
		draw_rect(rect.grow(5.0), Color(accent.r, accent.g, accent.b, 0.12), false, 4)
	var core = Rect2(rect.position + Vector2(10.0, 10.0), rect.size - Vector2(20.0, 20.0))
	draw_rect(core, Color(0.0, 0.0, 0.0, 0.16), true)
	var icon_r = min(core.size.y * 0.34, core.size.x * 0.12)
	var icon_center = Vector2(core.position.x + icon_r + 10.0, core.get_center().y)
	draw_circle(icon_center, icon_r, Color(accent.r, accent.g, accent.b, 0.20))
	draw_arc(icon_center, icon_r + 4.0, -PI * 0.25, PI * 1.25, 28, Color(accent.r, accent.g, accent.b, 0.86), 2.4)
	if primary:
		var tri = PackedVector2Array([
			icon_center + Vector2(-icon_r * 0.28, -icon_r * 0.48),
			icon_center + Vector2(icon_r * 0.54, 0.0),
			icon_center + Vector2(-icon_r * 0.28, icon_r * 0.48)
		])
		draw_polygon(tri, PackedColorArray([Color.WHITE]))
	else:
		draw_circle(icon_center, max(3.0, icon_r * 0.18), Color.WHITE)
		draw_arc(icon_center, icon_r * 0.58, 0, TAU, 20, Color.WHITE, 1.6)
	var title_size = int(clamp(rect.size.y * (0.30 if primary else 0.26), 15.0, 26.0))
	var text_x = icon_center.x + icon_r + 16.0
	var title_y = rect.position.y + rect.size.y * (0.46 if detail == "" else 0.38)
	draw_string(font, Vector2(text_x, title_y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color.WHITE)
	if detail != "":
		var detail_size = int(clamp(rect.size.y * 0.16, 10.0, 14.0))
		draw_string(font, Vector2(text_x, rect.position.y + rect.size.y * 0.68), detail.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, detail_size, Color(0.68, 0.86, 0.90, 0.82))
	var rail_x = rect.end.x - 22.0
	draw_line(Vector2(rail_x, rect.position.y + 14.0), Vector2(rail_x, rect.end.y - 14.0), Color(accent.r, accent.g, accent.b, 0.40), 2)


func _draw_hub_manifest_card(rect: Rect2) -> void:
	var item: Dictionary = MANIFESTATIONS[selected_manifestation]
	var color: Color = item["color"]
	_draw_holo_panel(rect, color, false, 0.50)
	var icon_rect = Rect2(rect.position + Vector2(12.0, 10.0), Vector2(rect.size.y - 20.0, rect.size.y - 20.0))
	_draw_texture_contain(textures.get("manifestation_" + item["key"]), icon_rect, Color.WHITE)
	var text_x = icon_rect.end.x + 14.0
	draw_string(font, Vector2(text_x, rect.position.y + rect.size.y * 0.36), String(item["name"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
	_draw_wrapped(String(item["desc"]), Rect2(Vector2(text_x, rect.position.y + rect.size.y * 0.48), Vector2(rect.end.x - text_x - 12.0, rect.size.y * 0.44)), 12, Color(0.80, 0.90, 0.92, 0.86))


func _draw_hub_chip(rect: Rect2, label: String, accent: Color, strong := false) -> void:
	draw_rect(rect, Color(0.012, 0.024, 0.034, 0.74 if strong else 0.58), true)
	draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.52 if strong else 0.28), false, 1)
	draw_line(rect.position + Vector2(10.0, rect.size.y - 7.0), rect.position + Vector2(rect.size.x * 0.42, rect.size.y - 7.0), Color(accent.r, accent.g, accent.b, 0.58), 2)
	_draw_centered(label, rect.get_center() + Vector2(0, 5), 13 if not strong else 14, Color(0.86, 0.98, 1.0, 0.92))


func _draw_settings(viewport: Vector2) -> void:
	_draw_holo_background(viewport, textures["choice_bg"], Color(1.0, 0.74, 0.22))
	var portrait = _is_portrait(viewport)
	_draw_glitch_title("CONFIGURACOES", Vector2(viewport.x * 0.5, 56 if not portrait else 48), 34 if not portrait else 30, Color(1.0, 0.74, 0.22))
	settings_buttons = _settings_rects(viewport)
	_draw_settings_card(settings_buttons["controls"], "CONTROLES", "reposicionar botoes, tamanho e HUD", Color(0.0, 1.0, 0.82), settings_selected == 0)
	_draw_settings_card(settings_buttons["gameplay"], "JOGABILIDADE", "analogico fixo/dinamico e preferencias", Color(0.36, 0.84, 1.0), settings_selected == 1)
	_draw_settings_card(settings_buttons["audio"], "SOM", "mixagem mobile e volume", Color(1.0, 0.42, 0.78), settings_selected == 2)
	_draw_settings_card(settings_buttons["graphics"], "GRAFICOS", "sombras, particulas e tremor", Color(0.6, 0.8, 1.0), settings_selected == 3)
	var back_subtitle = "retomar partida" if settings_previous_mode == "paused" else "retornar ao hub"
	_draw_settings_card(settings_buttons["back"], "VOLTAR", back_subtitle, Color(1.0, 0.26, 0.36), settings_selected == 4)
	var info_rect = Rect2(viewport.x * 0.10, viewport.y - (86 if portrait else 70), viewport.x * 0.80, 42)
	_draw_hub_chip(info_rect, "CONFIGURACOES SALVAS AUTOMATICAMENTE", Color(0.72, 0.92, 1.0), false)


func _draw_gameplay_settings(viewport: Vector2) -> void:
	_draw_holo_background(viewport, null, Color(0.36, 0.84, 1.0))
	var portrait = _is_portrait(viewport)
	_draw_glitch_title("JOGABILIDADE", Vector2(viewport.x * 0.5, 56 if not portrait else 48), 34 if not portrait else 30, Color(0.36, 0.84, 1.0))
	settings_buttons = _gameplay_preferences_rects(viewport)
	var analog_accent = Color(0.0, 1.0, 0.82) if analog_fixed else Color(1.0, 0.74, 0.22)
	_draw_gameplay_preference(settings_buttons["analog"], "ANALOGICO", "Origem do controle de movimento.", "FIXO" if analog_fixed else "DINAMICO", analog_accent)
	var shop_accent = Color(0.0, 1.0, 0.82) if shop_auto_enabled else Color(1.0, 0.68, 0.24)
	_draw_gameplay_preference(settings_buttons["shop_mode"], "ABERTURA DA LOJA", "Automatica usa contagem; manual usa botao no HUD.", "AUTOMATICA" if shop_auto_enabled else "MANUAL", shop_accent)
	_draw_toggle_switch(_shop_mode_toggle_rect(settings_buttons["shop_mode"]), shop_auto_enabled, shop_accent)
	var interval_panel: Rect2 = settings_buttons["shop_interval"]
	var interval_value = "%d MIN" % int(shop_auto_interval / 60.0) if shop_auto_enabled else "DESATIVADO"
	_draw_gameplay_preference(interval_panel, "INTERVALO DA LOJA", "Tempo entre aberturas automaticas.", interval_value, Color(0.44, 0.82, 1.0) if shop_auto_enabled else Color(0.48, 0.52, 0.58))
	if shop_auto_enabled:
		_draw_small_rect_button(_shop_interval_minus_rect(interval_panel), "-", Color(0.04, 0.10, 0.14), Color(0.44, 0.82, 1.0))
		_draw_small_rect_button(_shop_interval_plus_rect(interval_panel), "+", Color(0.04, 0.10, 0.14), Color(0.44, 0.82, 1.0))
	_draw_gameplay_preference(settings_buttons["target_priority"], "PRIORIDADE DO DISPARO", "Define o alvo escolhido pela mira automatica.", _target_priority_label(), Color(1.0, 0.48, 0.74))
	var damage_panel = settings_buttons["damage_text"]
	_draw_gameplay_preference(damage_panel, "TEXTO DE DANO", "Tamanho dos numeros exibidos nos inimigos.", "%d%%" % int(round(damage_text_scale * 100.0)), Color(1.0, 0.50, 0.28))
	_draw_small_rect_button(_damage_text_minus_rect(damage_panel), "-", Color(0.20, 0.10, 0.08), Color(1.0, 0.50, 0.28))
	_draw_small_rect_button(_damage_text_plus_rect(damage_panel), "+", Color(0.20, 0.10, 0.08), Color(1.0, 0.50, 0.28))
	var interface_panel = settings_buttons["interface_text"]
	_draw_gameplay_preference(interface_panel, "FONTES DA LOJA / MANIFESTACOES", "Tamanho dos textos informativos dessas telas.", "%d%%" % int(round(interface_text_scale * 100.0)), Color(0.62, 0.88, 1.0))
	_draw_small_rect_button(_interface_text_minus_rect(interface_panel), "-", Color(0.04, 0.10, 0.16), Color(0.62, 0.88, 1.0))
	_draw_small_rect_button(_interface_text_plus_rect(interface_panel), "+", Color(0.04, 0.10, 0.16), Color(0.62, 0.88, 1.0))
	var haptics_accent = Color(0.0, 1.0, 0.82) if haptics_enabled else Color(0.48, 0.52, 0.58)
	_draw_gameplay_preference(settings_buttons["haptics"], "VIBRACAO", "Feedback tatil dos impactos e habilidades.", "ON" if haptics_enabled else "OFF", haptics_accent)
	_draw_toggle_switch(_shop_mode_toggle_rect(settings_buttons["haptics"]), haptics_enabled, haptics_accent)
	_draw_settings_card(settings_buttons["back"], "VOLTAR", "retornar as configuracoes", Color(1.0, 0.26, 0.36), false)


func _draw_gameplay_preference(rect: Rect2, title: String, subtitle: String, value: String, accent: Color) -> void:
	_draw_holo_panel(rect, accent, false, 0.60)
	var value_rect = _gameplay_value_rect(rect)
	var text_width = max(120.0, value_rect.position.x - rect.position.x - 84.0)
	draw_string(font, rect.position + Vector2(18, 28), title, HORIZONTAL_ALIGNMENT_LEFT, text_width, 17, Color.WHITE)
	draw_string(font, rect.position + Vector2(18, 50), subtitle.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, text_width, 10, Color(0.70, 0.86, 0.90, 0.84))
	draw_rect(value_rect, Color(accent.r, accent.g, accent.b, 0.16), true)
	draw_rect(value_rect, Color(accent.r, accent.g, accent.b, 0.82), false, 2)
	_draw_centered(value, value_rect.get_center() + Vector2(0, 5), 14, Color.WHITE)


func _draw_audio_settings(viewport: Vector2) -> void:
	_draw_holo_background(viewport, null, Color(1.0, 0.42, 0.78))
	var portrait = _is_portrait(viewport)
	_draw_glitch_title("SOM", Vector2(viewport.x * 0.5, 56 if not portrait else 48), 34 if not portrait else 30, Color(1.0, 0.42, 0.78))
	settings_buttons = _gameplay_settings_rects(viewport)
	var panel = settings_buttons["analog"]
	_draw_holo_panel(panel, Color(1.0, 0.42, 0.78), true, 0.62)
	var titles = ["MASTER", "MUSICA", "EFEITOS"]
	var vols = [vol_master, vol_music, vol_sfx]
	var y_start = panel.position.y + 40
	for i in range(3):
		var y_off = y_start + i * 50
		draw_string(font, Vector2(panel.position.x + 20, y_off + 20), titles[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
		var bar_rect = Rect2(panel.position.x + 110, y_off, panel.size.x - 170, 26)
		draw_rect(bar_rect, Color(1, 1, 1, 0.1), true)
		draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * vols[i], bar_rect.size.y)), Color(1.0, 0.42, 0.78), true)
		_draw_small_rect_button(Rect2(bar_rect.position.x - 38, y_off - 4, 34, 34), "-", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))
		_draw_small_rect_button(Rect2(bar_rect.end.x + 4, y_off - 4, 34, 34), "+", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))
	_draw_settings_card(settings_buttons["back"], "VOLTAR", "retornar as configuracoes", Color(1.0, 0.26, 0.36), false)


func _draw_settings_card(rect: Rect2, title: String, subtitle: String, accent: Color, selected: bool) -> void:
	_draw_holo_panel(rect, accent, selected, 0.58)
	var marker = Rect2(rect.position + Vector2(12, 12), Vector2(42, rect.size.y - 24))
	draw_rect(marker, Color(accent.r, accent.g, accent.b, 0.16), true)
	draw_rect(marker, Color(accent.r, accent.g, accent.b, 0.68), false, 1)
	draw_circle(marker.get_center(), min(marker.size.x, marker.size.y) * 0.18, Color.WHITE)
	draw_string(font, rect.position + Vector2(70, rect.size.y * 0.42), title, HORIZONTAL_ALIGNMENT_LEFT, -1, int(clamp(rect.size.y * 0.28, 16, 22)), Color.WHITE)
	if subtitle != "":
		draw_string(font, rect.position + Vector2(70, rect.size.y * 0.68), subtitle.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, int(clamp(rect.size.y * 0.15, 10, 13)), Color(0.70, 0.86, 0.90, 0.84))


func _settings_rects(viewport: Vector2) -> Dictionary:
	var portrait = _is_portrait(viewport)
	var margin = viewport.x * (0.08 if portrait else 0.12)
	var w = viewport.x - margin * 2.0
	var h = clamp(viewport.y * (0.095 if portrait else 0.12), 58.0, 78.0)
	var y = viewport.y * (0.18 if portrait else 0.20)
	var gap = 14.0
	if not portrait:
		w = min(620.0, viewport.x * 0.52)
		margin = viewport.x * 0.5 - w * 0.5
	return {
		"controls": Rect2(margin, y, w, h),
		"gameplay": Rect2(margin, y + (h + gap), w, h),
		"audio": Rect2(margin, y + (h + gap) * 2.0, w, h),
		"graphics": Rect2(margin, y + (h + gap) * 3.0, w, h),
		"back": Rect2(margin, y + (h + gap) * 4.0, w, h)
	}


func _gameplay_settings_rects(viewport: Vector2) -> Dictionary:
	var portrait = _is_portrait(viewport)
	var margin = viewport.x * (0.08 if portrait else 0.18)
	var w = viewport.x - margin * 2.0
	if not portrait:
		w = min(720.0, viewport.x * 0.58)
		margin = viewport.x * 0.5 - w * 0.5
	var panel_h = clamp(viewport.y * (0.24 if portrait else 0.28), 150.0, 190.0)
	var y = viewport.y * (0.16 if portrait else 0.18)
	return {
		"analog": Rect2(margin, y, w, panel_h),
		"damage_text": Rect2(margin, y + panel_h + 14.0, w, panel_h),
		"back": Rect2(margin, y + (panel_h + 14.0) * 2.0 + 18.0, w, clamp(viewport.y * 0.09, 56.0, 70.0))
	}


func _gameplay_preferences_rects(viewport: Vector2) -> Dictionary:
	var portrait = _is_portrait(viewport)
	var w = min(760.0, viewport.x * (0.86 if portrait else 0.68))
	var x = viewport.x * 0.5 - w * 0.5
	var y = viewport.y * (0.12 if portrait else 0.13)
	var gap = 8.0
	var back_h = clamp(viewport.y * 0.075, 48.0, 58.0)
	var panel_h = clamp((viewport.y - y - back_h - 24.0 - gap * 7.0) / 7.0, 46.0, 68.0)
	return {
		"analog": Rect2(x, y, w, panel_h),
		"shop_mode": Rect2(x, y + (panel_h + gap), w, panel_h),
		"shop_interval": Rect2(x, y + (panel_h + gap) * 2.0, w, panel_h),
		"target_priority": Rect2(x, y + (panel_h + gap) * 3.0, w, panel_h),
		"damage_text": Rect2(x, y + (panel_h + gap) * 4.0, w, panel_h),
		"interface_text": Rect2(x, y + (panel_h + gap) * 5.0, w, panel_h),
		"haptics": Rect2(x, y + (panel_h + gap) * 6.0, w, panel_h),
		"back": Rect2(x, y + (panel_h + gap) * 7.0 + 4.0, w, back_h)
	}


func _gameplay_value_rect(panel: Rect2) -> Rect2:
	var value_w = min(190.0, panel.size.x * 0.32)
	return Rect2(panel.end.x - value_w - 68.0, panel.position.y + 12.0, value_w, panel.size.y - 24.0)


func _shop_interval_minus_rect(panel: Rect2) -> Rect2:
	var value_rect = _gameplay_value_rect(panel)
	return Rect2(value_rect.position.x - 52.0, panel.position.y + 14.0, 42.0, panel.size.y - 28.0)


func _shop_mode_toggle_rect(panel: Rect2) -> Rect2:
	return Rect2(panel.end.x - 58.0, panel.get_center().y - 13.0, 46.0, 26.0)


func _shop_interval_plus_rect(panel: Rect2) -> Rect2:
	var value_rect = _gameplay_value_rect(panel)
	return Rect2(value_rect.end.x + 10.0, panel.position.y + 14.0, 42.0, panel.size.y - 28.0)


func _damage_text_minus_rect(panel: Rect2) -> Rect2:
	var value_rect = _gameplay_value_rect(panel)
	return Rect2(value_rect.position.x - 52.0, panel.position.y + 14.0, 42.0, panel.size.y - 28.0)


func _damage_text_plus_rect(panel: Rect2) -> Rect2:
	var value_rect = _gameplay_value_rect(panel)
	return Rect2(value_rect.end.x + 10.0, panel.position.y + 14.0, 42.0, panel.size.y - 28.0)


func _interface_text_minus_rect(panel: Rect2) -> Rect2:
	return _damage_text_minus_rect(panel)


func _interface_text_plus_rect(panel: Rect2) -> Rect2:
	return _damage_text_plus_rect(panel)


func _readable_text_size(base_size: int) -> int:
	return maxi(9, int(round(float(base_size) * interface_text_scale)))


func _draw_menu_grid(viewport: Vector2, color: Color, spacing: float) -> void:
	var x = 0.0
	while x <= viewport.x:
		draw_line(Vector2(x, 0), Vector2(x, viewport.y), color, 1)
		x += spacing
	var y = 0.0
	while y <= viewport.y:
		draw_line(Vector2(0, y), Vector2(viewport.x, y), color, 1)
		y += spacing


func _is_portrait(viewport: Vector2) -> bool:
	return viewport.y > viewport.x


func _draw_texture_cover(texture: Texture2D, rect: Rect2, modulate := Color.WHITE) -> void:
	if texture == null:
		draw_rect(rect, Color(0.01, 0.014, 0.030), true)
		return
	var src = Rect2(Vector2.ZERO, texture.get_size())
	var src_ratio = src.size.x / max(1.0, src.size.y)
	var dst_ratio = rect.size.x / max(1.0, rect.size.y)
	if src_ratio > dst_ratio:
		var w = src.size.y * dst_ratio
		src.position.x = (src.size.x - w) * 0.5
		src.size.x = w
	else:
		var h = src.size.x / dst_ratio
		src.position.y = (src.size.y - h) * 0.5
		src.size.y = h
	draw_texture_rect_region(texture, rect, src, modulate)


func _draw_texture_contain(texture: Texture2D, rect: Rect2, modulate := Color.WHITE) -> void:
	if texture == null:
		draw_circle(rect.get_center(), min(rect.size.x, rect.size.y) * 0.34, Color(0.0, 0.90, 1.0, 0.28))
		return
	var size = texture.get_size()
	var scale = min(rect.size.x / max(1.0, size.x), rect.size.y / max(1.0, size.y))
	var draw_size = size * scale
	draw_texture_rect(texture, Rect2(rect.get_center() - draw_size * 0.5, draw_size), false, modulate)


func _draw_holo_background(viewport: Vector2, texture: Texture2D = null, accent := Color(0.0, 1.0, 0.82)) -> void:
	if texture:
		_draw_texture_cover(texture, Rect2(Vector2.ZERO, viewport))
	else:
		draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.006, 0.010, 0.026), true)
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, 0.58), true)
	_draw_menu_grid(viewport, Color(accent.r, accent.g, accent.b, 0.13), 38.0)
	for i in range(12):
		var x1 = fmod(time_alive * (28.0 + i * 2.0) + i * 97.0, viewport.x + 220.0) - 110.0
		var y1 = viewport.y * (0.10 + (i % 6) * 0.14)
		draw_line(Vector2(x1, y1), Vector2(x1 + 92.0, y1 + 12.0), Color(accent.r, accent.g, accent.b, 0.15), 2)
	for y in range(0, int(viewport.y), 5):
		if y % 15 == 0:
			draw_line(Vector2(0, y), Vector2(viewport.x, y), Color(1, 1, 1, 0.025), 1)


func _draw_glitch_title(text: String, pos: Vector2, size: int, accent := Color(0.0, 1.0, 0.82)) -> void:
	var jitter = sin(Time.get_ticks_msec() * 0.025) * 2.0
	_draw_centered(text, pos + Vector2(-3.0 + jitter, 1), size, Color(1.0, 0.08, 0.78, 0.58))
	_draw_centered(text, pos + Vector2(3.0 - jitter, -1), size, Color(0.0, 0.90, 1.0, 0.64))
	_draw_centered(text, pos, size, Color.WHITE)
	draw_line(pos + Vector2(-170, size * 0.42), pos + Vector2(170, size * 0.42), Color(accent.r, accent.g, accent.b, 0.72), 2)


func _draw_holo_panel(rect: Rect2, border := Color(0.0, 1.0, 0.82), selected := false, fill_alpha := 0.70) -> void:
	var bg = Color(0.010, 0.025, 0.040, fill_alpha)
	if selected:
		bg = bg.lerp(border, 0.12)
	draw_rect(rect, bg, true)
	draw_rect(rect.grow(-5), Color(1, 1, 1, 0.035), false, 1)
	draw_rect(rect, Color(border.r, border.g, border.b, 0.96 if selected else 0.54), false, 3 if selected else 2)
	var left = rect.position + Vector2(0, rect.size.y * 0.20)
	var right = rect.position + Vector2(rect.size.x, rect.size.y * 0.80)
	draw_line(left, left + Vector2(0, rect.size.y * 0.58), Color(border.r, border.g, border.b, 0.50), 4)
	draw_line(right, right - Vector2(0, rect.size.y * 0.58), Color(1.0, 0.08, 0.78, 0.28), 3)
	for i in range(3):
		var yy = rect.position.y + 12 + i * 9
		draw_line(Vector2(rect.position.x + 14, yy), Vector2(rect.position.x + 54 + i * 18, yy), Color(border.r, border.g, border.b, 0.28), 1)


func _draw_section_flow(label: String, label_color: Color, text: String, text_color: Color, start_y: float, details_rect: Rect2, font_size: int) -> float:
	# Desenhar o rÃ³tulo/categoria da seÃ§Ã£o com realce neon
	draw_string(font, Vector2(details_rect.position.x + 20, start_y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 1, label_color)

	# O texto flui logo abaixo
	var text_y = start_y + font_size + 5
	var words = text.split(" ")
	var line = ""
	var max_w = details_rect.size.x - 40

	for word in words:
		var test = line + (" " if line != "" else "") + word
		if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_w and line != "":
			draw_string(font, Vector2(details_rect.position.x + 20, text_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
			line = word
			text_y += font_size + 4
		else:
			line = test

	if line != "":
		draw_string(font, Vector2(details_rect.position.x + 20, text_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
		text_y += font_size + 4

	# Retorna o Y final mais o padding confortÃ¡vel para a prÃ³xima seÃ§Ã£o
	return text_y + 12


func _draw_energy_particles(area: Rect2, accent := Color(0.0, 1.0, 0.82), count := 18) -> void:
	for i in range(count):
		var px = area.position.x + fmod(i * 71.0 + time_alive * (22.0 + i), area.size.x)
		var py = area.position.y + fmod(i * 43.0 + sin(time_alive * 1.7 + i) * 26.0 + time_alive * 12.0, area.size.y)
		var alpha = 0.18 + 0.22 * abs(sin(time_alive * 3.0 + i))
		draw_circle(Vector2(px, py), 1.5 + float(i % 3), Color(accent.r, accent.g, accent.b, alpha))


func _menu_rects(viewport: Vector2) -> Dictionary:
	var portrait = _is_portrait(viewport)

	if portrait:
		var margin = viewport.x * 0.08
		var start_y = viewport.y * 0.43
		var start_h = clamp(viewport.y * 0.105, 72.0, 96.0)
		var utility_y = start_y + start_h + 12.0
		var utility_h = clamp(viewport.y * 0.085, 54.0, 68.0)
		var gap = 12.0
		var half_w = (viewport.x - margin * 2.0 - gap) * 0.5
		return {
			"start": Rect2(margin, start_y, viewport.x - margin * 2.0, start_h),
			"catalog": Rect2(margin, utility_y, half_w, utility_h),
			"settings": Rect2(margin + half_w + gap, utility_y, half_w, utility_h),
			"exit": Rect2(viewport.x - margin - 118.0, viewport.y - 62.0, 118.0, 42.0)
		}
	var x = viewport.x * 0.08
	var w = min(430.0, viewport.x * 0.38)
	var start_h = clamp(viewport.y * 0.14, 86.0, 108.0)
	var start_y = viewport.y * 0.23
	var small_h = clamp(viewport.y * 0.09, 56.0, 68.0)
	var gap = 14.0
	return {
		"start": Rect2(x, start_y, w, start_h),
		"catalog": Rect2(x, start_y + start_h + 14.0, (w - gap) * 0.5, small_h),
		"settings": Rect2(x + (w - gap) * 0.5 + gap, start_y + start_h + 14.0, (w - gap) * 0.5, small_h),
		"exit": Rect2(x, viewport.y - 74.0, min(170.0, w * 0.40), 46.0)
	}



func _draw_catalog(viewport: Vector2) -> void:
	_draw_holo_background(viewport, null, Color(0.0, 0.88, 1.0))
	_draw_glitch_title("CATALOGO TEMPORAL", Vector2(viewport.x * 0.5, 54), 34, Color(0.0, 0.88, 1.0))
	var tab_w = viewport.x / CATALOG_TABS.size()
	for i in range(CATALOG_TABS.size()):
		var rect = Rect2(i * tab_w + 3, 92, tab_w - 6, 48)
		var selected = i == catalog_tab
		_draw_holo_panel(rect, Color(0.0, 1.0, 0.82) if selected else Color(0.18, 0.38, 0.48), selected, 0.68)
		_draw_centered(_catalog_tab_label(i), rect.get_center() + Vector2(0, 6), 12 if _is_portrait(viewport) else 16, Color.WHITE)
	if catalog_detail_open:
		_draw_catalog_detail(viewport)
		return
	var items = _catalog_items()
	var portrait = _is_portrait(viewport)
	var cols = 1 if portrait else 2
	var visible = 6 if portrait else 8
	var card_w = viewport.x * 0.86 if portrait else min(390.0, viewport.x * 0.42)
	var card_h = 126.0 if portrait else 118.0
	var start_x = viewport.x * 0.5 - card_w * 0.5 if portrait else viewport.x * 0.5 - card_w - 14
	var start_y = 164.0
	for i in range(min(items.size(), visible)):
		var row = int(i / cols)
		var col = i % cols
		var item: Dictionary = items[i]
		var rect = Rect2(start_x + col * (card_w + 28), start_y + row * (card_h + 16), card_w, card_h)
		var color: Color = item.get("color", Color(0.62, 0.92, 1.0))
		_draw_holo_panel(rect, color, catalog_selected == i, 0.74)
		var icon_rect = Rect2(rect.position + Vector2(16, 20), Vector2(72, 72))
		_draw_texture_contain(_catalog_item_texture(item), icon_rect, Color.WHITE)
		draw_string(font, rect.position + Vector2(106, 36), String(item["name"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
		_draw_wrapped(String(item["desc"]), Rect2(rect.position + Vector2(106, 56), Vector2(card_w - 126, 54)), 14, Color(0.78, 0.88, 0.92))
		draw_line(rect.position + Vector2(106, card_h - 18), rect.position + Vector2(card_w - 22, card_h - 18), Color(color.r, color.g, color.b, 0.38), 1)
	var back_rect = Rect2(viewport.x * 0.08, viewport.y - 72, viewport.x * 0.84, 48) if portrait else Rect2(viewport.x * 0.06, viewport.y - 68, 160, 44)
	_draw_big_button(back_rect, "VOLTAR", Color(0.11, 0.04, 0.06, 0.88), Color(1.0, 0.28, 0.34))


func _catalog_tab_label(index: int) -> String:
	match index:
		0:
			return "MANIF."
		1:
			return "INIMIGOS"
		2:
			return "CHEFES"
		3:
			return "FRACOES"
		4:
			return "AUREAS"
		_:
			return "CARTAS"


func _draw_catalog_detail(viewport: Vector2) -> void:
	var items = _catalog_items()
	if items.is_empty():
		return
	var item: Dictionary = items[clamp(catalog_selected, 0, items.size() - 1)]
	var color: Color = item.get("color", Color(0.0, 1.0, 0.82))
	var portrait = _is_portrait(viewport)

	if portrait:
		var panel = Rect2(viewport.x * 0.07, 156, viewport.x * 0.86, viewport.y - 246)
		_draw_holo_panel(panel, color, true, 0.78)
		var image_rect = Rect2(panel.position + Vector2(20, 22), Vector2(panel.size.x - 40, min(300.0, panel.size.y * 0.32)))
		draw_rect(image_rect, Color(0.0, 0.0, 0.0, 0.32), true)
		draw_rect(image_rect, Color(color.r, color.g, color.b, 0.50), false, 2)
		_draw_texture_contain(_catalog_item_texture(item), image_rect.grow(-12), Color.WHITE)
		var y = image_rect.end.y + 24
		_draw_centered(String(item["name"]).to_upper(), Vector2(panel.get_center().x, y), 24, Color.WHITE)
		y += 28
		_draw_wrapped(String(item["desc"]), Rect2(panel.position.x + 20, y, panel.size.x - 40, 48), 14, Color(0.78, 0.90, 0.95))
		y += 58
		draw_line(Vector2(panel.position.x + 20, y), Vector2(panel.end.x - 20, y), Color(color.r, color.g, color.b, 0.38), 1)
		y += 16
		draw_string(font, Vector2(panel.position.x + 20, y), "HISTORIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
		y += 18
		_draw_wrapped(String(item.get("lore", "Registro estabilizado no banco de dados temporal da Geovana.")), Rect2(panel.position.x + 20, y, panel.size.x - 40, 54), 13, Color(0.70, 0.82, 0.88))
		y += 64
		draw_string(font, Vector2(panel.position.x + 20, y), "MECANICAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
		y += 18
		_draw_wrapped(String(item.get("mechanics", "Entrada monitorada durante a jornada.")), Rect2(panel.position.x + 20, y, panel.size.x - 40, 72), 13, Color(0.82, 0.90, 0.94))
	else:
		var panel = Rect2(viewport.x * 0.06, 148, viewport.x * 0.88, viewport.y - 238)
		_draw_holo_panel(panel, color, true, 0.78)

		# Left Column: Image Showcase
		var left_w = panel.size.x * 0.38
		var image_rect = Rect2(panel.position + Vector2(24, 24), Vector2(left_w, panel.size.y - 106))
		draw_rect(image_rect, Color(0.0, 0.0, 0.0, 0.32), true)
		draw_rect(image_rect, Color(color.r, color.g, color.b, 0.50), false, 2)
		_draw_texture_contain(_catalog_item_texture(item), image_rect.grow(-16), Color.WHITE)

		_draw_centered(String(item["name"]).to_upper(), Vector2(image_rect.get_center().x, image_rect.end.y + 32), 24, Color.WHITE)

		# Divider line
		var div_x = panel.position.x + left_w + 48
		draw_line(Vector2(div_x, panel.position.y + 24), Vector2(div_x, panel.end.y - 24), Color(color.r, color.g, color.b, 0.28), 1)

		# Right Column: Details (stacked)
		var right_x = div_x + 24
		var right_w = panel.end.x - right_x - 24
		var ry = panel.position.y + 24

		# Description
		draw_string(font, Vector2(right_x, ry), "DESCRICAO", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
		ry += 18
		_draw_wrapped(String(item["desc"]), Rect2(right_x, ry, right_w, 42), 14, Color(0.85, 0.92, 0.96))
		ry += 52

		# Lore
		draw_string(font, Vector2(right_x, ry), "HISTORIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
		ry += 18
		_draw_wrapped(String(item.get("lore", "Registro estabilizado no banco de dados temporal da Geovana.")), Rect2(right_x, ry, right_w, 54), 13, Color(0.70, 0.82, 0.88))
		ry += 64

		# Mechanics
		draw_string(font, Vector2(right_x, ry), "MECANICAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
		ry += 18
		_draw_wrapped(String(item.get("mechanics", "Entrada monitorada durante a jornada.")), Rect2(right_x, ry, right_w, 64), 13, Color(0.82, 0.90, 0.94))

	_draw_big_button(Rect2(viewport.x * 0.5 - 120, viewport.y - 72, 240, 48), "VOLTAR AO INDICE", Color(0.08, 0.04, 0.10, 0.90), Color(1.0, 0.20, 0.78))


func _catalog_item_texture(item: Dictionary) -> Texture2D:
	if item.has("key") and textures.has("manifestation_" + String(item["key"])):
		return textures["manifestation_" + String(item["key"])]
	var texture_key = String(item.get("texture", ""))
	if texture_key != "" and textures.has(texture_key):
		var value = textures[texture_key]
		if value is Array:
			return value[0]
		return value
	if item.has("icon"):
		return textures.get("card_" + String(item["name"]), null)
	return null


func _catalog_items() -> Array:
	match catalog_tab:
		0:
			return MANIFESTATIONS
		1:
			return [
				{"name": "Comum", "desc": "Persegue Geovana e pressiona contato corpo a corpo.", "color": Color(0.8, 0.86, 0.95), "texture": "enemy_common", "lore": "Fragmento instavel da primeira ruptura.", "mechanics": "Aproxima em linha direta e aplica dano por contato."},
				{"name": "Aglomerador", "desc": "Mais vida, divide a tela e gera inimigos ao cair.", "color": Color(0.56, 0.56, 1.0), "texture": "agglomerator", "mechanics": "Serve como massa de pressao e aumenta a ocupacao do mapa."},
				{"name": "Projetador", "desc": "Atira projeteis cinza/roxo enquanto tenta manter distancia.", "color": Color(0.65, 0.45, 1.0), "texture": "projector", "mechanics": "Para perto do alcance ideal e dispara em cadencia controlada."},
				{"name": "Curater", "desc": "Cura aliados e deixa orbe de cura ao ser eliminado.", "color": Color(0.34, 1.0, 0.42), "texture": "curater", "mechanics": "Prioridade tatica alta: prolonga ondas inimigas."},
				{"name": "Larapio", "desc": "Rouba pontos, fica mais resistente e foge pelo portal quando ferido.", "color": Color(0.74, 0.24, 1.0), "texture": "larapio", "mechanics": "Abaixo de 50% de vida abandona coleta e canaliza fuga."}
			]
		2:
			return [
				{"name": "Boss 1", "desc": "Caranguejo cosmico gigante: entrada com impacto, ondas e ataques de area.", "color": Color(1.0, 0.32, 0.18), "texture": "boss_stage1", "lore": "Entidade da primeira fissura de Ruptura Temporal.", "mechanics": "Persegue Geovana, troca de estagio e cria ondas incompletas/completas."}
			]
		3:
			return [
				{"name": "APOLO", "desc": "Protocolo de observacao, catalogacao e resposta a anomalias.", "color": Color(0.0, 1.0, 0.82), "texture": "choice_bg", "mechanics": "Interface militar que organiza jornada, catalogo e manifestacoes."},
				{"name": "Ruptura", "desc": "Forca temporal que altera Geovana, inimigos e o proprio mapa.", "color": Color(1.0, 0.08, 0.78), "texture": "map", "mechanics": "Escala dificuldade, eventos e manifestacoes durante a run."}
			]
		4:
			return AURAS
		_:
			return CARDS
func _draw_manifest_select(viewport: Vector2) -> void:
	# Fundo hologrÃ¡fico Sci-Fi limpo
	_draw_holo_background(viewport, null, Color(0.0, 1.0, 0.82))
	var portrait = _is_portrait(viewport)

	# TÃ­tulo e subtÃ­tulo superiores (alinhados ao carrossel em landscape para evitar overlap com o painel)
	var title_x = viewport.x * 0.5 if portrait else viewport.x * 0.28
	var title_y = 74 if portrait else 64
	_draw_glitch_title("MANIFESTACOES", Vector2(title_x, title_y), 34, Color(0.0, 1.0, 0.82))
	_draw_centered("FORMAS QUE A RUPTURA ASSUME ATRAVES DE GEOVANA", Vector2(title_x, title_y + 38), _readable_text_size(12 if not portrait else 14), Color(0.72, 0.94, 1.0, 0.90))

	var item: Dictionary = MANIFESTATIONS[selected_manifestation]
	var color: Color = item["color"]

	# Layout de Carrossel DinÃ¢mico Animado
	var center_x = viewport.x * 0.5 if portrait else viewport.x * 0.28
	var center_y = viewport.y * 0.28 if portrait else viewport.y * 0.42
	var card_w = 140.0 if portrait else 168.0
	var card_h = 160.0 if portrait else 188.0
	var spacing = _manifest_carousel_spacing(viewport)

	var half_size = MANIFESTATIONS.size() / 2.0
	for i in range(MANIFESTATIONS.size()):
		var diff = float(i) - manifest_scroll_pos
		if diff > half_size:
			diff -= MANIFESTATIONS.size()
		elif diff < -half_size:
			diff += MANIFESTATIONS.size()

		var abs_diff = abs(diff)
		if abs_diff > 2.2:
			continue # Ignora os que estÃ£o muito distantes do centro visual

		# InterpolaÃ§Ã£o suave de escala e opacidade para efeito 3D
		var scale = 1.15
		if abs_diff <= 1.0:
			scale = lerp(1.15, 0.85, abs_diff)
		else:
			scale = lerp(0.85, 0.65, clamp(abs_diff - 1.0, 0.0, 1.0))

		var opacity = 1.0
		if abs_diff <= 1.0:
			opacity = lerp(1.0, 0.45, abs_diff)
		else:
			opacity = lerp(0.45, 0.15, clamp(abs_diff - 1.0, 0.0, 1.0))

		var pos_x = center_x + diff * spacing
		var rect = Rect2(pos_x - card_w * scale * 0.5, center_y - card_h * scale * 0.5, card_w * scale, card_h * scale)

		# Desenhar painel hologrÃ¡fico para cada carta
		var item_color: Color = MANIFESTATIONS[i]["color"]
		_draw_holo_panel(rect, item_color, abs_diff < 0.5, opacity * 0.70)

		if abs_diff < 0.5:
			# PartÃ­culas energÃ©ticas mais intensas quando no centro
			_draw_energy_particles(rect, item_color, int(24 * (1.0 - abs_diff)))

		# Carregar Ã­cone da manifestaÃ§Ã£o
		var icon: Texture2D = textures.get("manifestation_" + MANIFESTATIONS[i]["key"])
		if icon:
			var icon_color = Color(1, 1, 1, opacity)
			_draw_texture_contain(icon, rect.grow(-26 * scale), icon_color)

		# RÃ³tulo de nome do card
		var name_color = Color(1, 1, 1, opacity)
		var label_y = rect.end.y - (18 * scale)
		_draw_centered(String(MANIFESTATIONS[i]["name"]).to_upper(), Vector2(rect.get_center().x, label_y), _readable_text_size(int(16 * scale)), name_color)

	# Indicadores (dots) de progresso abaixo do carrossel
	var dots_y = center_y + (card_h * 0.65) + 10
	var total_w = MANIFESTATIONS.size() * 18
	for i in range(MANIFESTATIONS.size()):
		var x = center_x - total_w * 0.5 + i * 18
		draw_circle(Vector2(x, dots_y), 4 if i != selected_manifestation else 7, color if i == selected_manifestation else Color(0.38, 0.52, 0.62, 0.60 * (1.0 if i == selected_manifestation else 0.5)))

	# Painel de Detalhes HologrÃ¡ficos
	var details_rect: Rect2
	if portrait:
		details_rect = Rect2(viewport.x * 0.06, viewport.y * 0.48, viewport.x * 0.88, viewport.y * 0.38)
	else:
		details_rect = Rect2(viewport.x * 0.52, viewport.y * 0.15, viewport.x * 0.42, viewport.y * 0.70)

	var details = _manifestation_details(item["key"])
	_draw_holo_panel(details_rect, color, true, 0.42)

	# TÃ­tulo do painel de detalhes
	var title_pos = details_rect.position + Vector2(20, 26)
	draw_string(font, title_pos, item["name"].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, _readable_text_size(22), color)
	draw_string(font, title_pos + Vector2(0, 24), "NOME DE CODIGO // SINAL ESTAVEL", HORIZONTAL_ALIGNMENT_LEFT, -1, _readable_text_size(12), Color(0.5, 0.78, 0.86, 0.82))

	# Divisor de linha
	var line_y = title_pos.y + _readable_text_size(22) + 16
	draw_line(Vector2(details_rect.position.x + 20, line_y), Vector2(details_rect.end.x - 20, line_y), Color(color.r, color.g, color.b, 0.26), 1)

	# SeÃ§Ãµes detalhadas usando layout dinÃ¢mico de fluxo (evita qualquer tipo de overlap ou overflow)
	var current_y = line_y + 14
	var font_size = _readable_text_size(11 if portrait else 12)
	var text_color = Color(0.80, 0.90, 0.95, 0.90)

	current_y = _draw_section_flow("FUNCAO", color, details["funcao"], text_color, current_y, details_rect, font_size)
	current_y = _draw_section_flow("DISPARO", color, details["disparo"], text_color, current_y, details_rect, font_size)
	current_y = _draw_section_flow("HABILIDADE ATIVA: " + String(details["habilidade"]).to_upper(), color, details["desc_hab"], text_color, current_y, details_rect, font_size)

	var traco_risco_text = details["traco"] + " // Risco: " + details["risco"]
	current_y = _draw_section_flow("TRACO E RISCO", color, traco_risco_text, text_color, current_y, details_rect, font_size)

	# BotÃµes inferiores de aÃ§Ã£o
	var button_y = viewport.y - 72
	var btn_w = 200.0
	var btn_h = 44.0
	var btn_start_rect: Rect2
	var btn_back_rect: Rect2

	if portrait:
		var py = viewport.y - 82
		var pw = viewport.x * 0.40
		var ph = 52.0
		btn_start_rect = Rect2(viewport.x * 0.08, py, pw, ph)
		btn_back_rect = Rect2(viewport.x * 0.52, py, pw, ph)
	else:
		btn_start_rect = Rect2(viewport.x * 0.10, button_y, btn_w, btn_h)
		btn_back_rect = Rect2(viewport.x * 0.10 + 220, button_y, btn_w, btn_h)

	# Armazenar rects globais de botÃµes para clique/toque
	buttons["manifest_start"] = btn_start_rect
	buttons["manifest_back"] = btn_back_rect

	_draw_big_button(btn_start_rect, "MANIFESTAR", Color(0.02, 0.14, 0.11, 0.88), Color(0.0, 1.0, 0.82))
	_draw_big_button(btn_back_rect, "VOLTAR", Color(0.12, 0.04, 0.05, 0.88), Color(1.0, 0.28, 0.34))


func _draw_game(viewport: Vector2) -> void:
	var camera = _camera(viewport)
	camera += _screen_shake_offset()
	var map_texture = _current_map_texture()
	if map_texture:
		draw_texture_rect(map_texture, _desktop_stage_draw_rect(camera), false)
	else:
		draw_rect(Rect2(-camera, WORLD_SIZE), Color(0.05, 0.055, 0.08), true)

	if not _active_prismatica_secondary().is_empty():
		var dr = Rect2(-camera, WORLD_SIZE)
		draw_rect(dr, Color(0.01, 0.0, 0.05, 0.85), true)
		var t = float(Time.get_ticks_msec()) * 0.001
		var p_pos = player_pos - camera

		# Floor Grid Neon (Checkerboard)
		var grid_size = 100.0
		var ox = fmod(camera.x, grid_size)
		var oy = fmod(camera.y, grid_size)
		for x in range(int(viewport.x / grid_size) + 2):
			for y in range(int(viewport.y / grid_size) + 2):
				if (x + y) % 2 == 0:
					var rect = Rect2(x * grid_size - ox, y * grid_size - oy, grid_size, grid_size)
					var hue = fmod(t * 0.4 + (x+y) * 0.05, 1.0)
					draw_rect(rect, Color.from_hsv(hue, 0.9, 1.0, 0.15), true)

		# Moving Spotlights (Soft Glow)
		for i in range(4):
			var a = t * (1.2 + i * 0.3) + i * TAU / 4.0
			var center = Vector2(viewport.x/2, viewport.y/2) + Vector2(cos(a*0.8), sin(a*1.2)) * (300.0 + sin(t)*50.0)
			var c = Color.from_hsv(fmod(t*0.5 + i*0.25, 1.0), 1.0, 1.0, 1.0)
			var base_r = 180.0 + sin(t*3+i)*40.0
			# Draw layered soft circles
			for k in range(5):
				draw_circle(center, base_r * (1.0 - k * 0.15), Color(c.r, c.g, c.b, 0.04 + k * 0.02))

		for i in range(10):
			var r = 160.0 + sin(t * 2.5 + i) * 35.0 + i * 45.0
			var c = Color.from_hsv(fmod(t * 0.2 + i * 0.15, 1.0), 0.9, 1.0, 0.05)
			draw_circle(p_pos, r, c)

	if boss1_rain_active and weather_kind == "rain":
		_draw_rain_puddles(camera)
	for anchor in anchors:
		var p: Vector2 = anchor["pos"] - camera
		draw_circle(p, 52, Color(0.2, 0.86, 1.0, 0.10))
		draw_arc(p, 52, 0, TAU, 48, Color(0.4, 0.95, 1.0, 0.55), 2)
	for prism in prisms:
		var p: Vector2 = prism["pos"] - camera
		var pulse = 0.5 + 0.5 * sin(float(prism["life"]) * 8.0)
		var size = 42.0 + pulse * 6.0
		var points = PackedVector2Array([
			p + Vector2(0, -size),
			p + Vector2(size, 0),
			p + Vector2(0, size),
			p + Vector2(-size, 0)
		])
		draw_polygon(points, PackedColorArray([Color(0.27, 0.96, 1.0, 0.14)]))
		draw_polyline(points, Color(0.27, 0.96, 1.0, 0.82), 3.0)
		draw_circle(p, size * 0.45, Color(1.0, 0.45, 0.72, 0.22 + pulse * 0.15))
		draw_arc(p, size * 0.45, 0, TAU, 32, Color(1.0, 0.45, 0.72, 0.82), 1.5)
	for link in seed_links:
		var enemy = _enemy_by_uid(int(link.get("uid", -1)))
		if enemy:
			draw_arc(enemy["pos"] - camera, 34, 0, TAU, 32, Color(0.40, 1.0, 0.36, 0.66), 3)
	for slash in slashes:
		var alpha = clamp(float(slash["life"]) / float(slash["max"]), 0.0, 1.0)
		var c: Color = slash["color"]
		c.a = 0.22 + alpha * 0.55
		if slash.has("points"):
			var packed := PackedVector2Array()
			for point in slash["points"]:
				packed.append(point - camera)
			draw_polyline(packed, c, float(slash["width"]) * alpha, true)
		else:
			draw_line(slash["a"] - camera, slash["b"] - camera, c, float(slash["width"]) * alpha)
	for wave in shockwaves:
		draw_arc(wave["pos"] - camera, float(wave["radius"]), 0, TAU, 80, Color(0.2, 1.0, 1.0, 0.6), 4)
	_draw_manifestation_secondaries(camera)
	_draw_parasite_spit_zones(camera)
	_draw_boss2_environment(camera)
	_draw_phase3_environment(camera)
	_draw_boss_attacks(camera)
	_draw_boss1_rewind_world(camera)
	for orb in heal_orbs:
		draw_circle(orb["pos"] - camera, 15, Color(0.25, 1.0, 0.42, 0.78))
		draw_arc(orb["pos"] - camera, 22, 0, TAU, 32, Color(0.65, 1.0, 0.75, 0.65), 2)
	_draw_larapio_coin_drops(camera)
	_draw_enemies(camera)
	_draw_projectiles(camera)
	if boss_active and boss_hp > 0.0:
		if boss_entry_timer > 0.0:
			_draw_boss_entry(camera)
		var boss_tex: Texture2D = _boss_texture()
		var boss_draw_pos = _boss_draw_position()
		_draw_dynamic_shadow_fit(boss_tex, boss_pos - camera, Vector2(184, 170), false, true, 0.44)
		var boss_modulate = Color.WHITE
		if _attack_target_is_boss():
			_draw_attack_target_marker(boss_draw_pos - camera + Vector2(0, 55), 64.0, locked_target_kind == "boss")
			boss_modulate = Color(1.0, 0.93, 0.48, 1.0)
		_draw_entity_fit(boss_tex, boss_draw_pos - camera, Vector2(184, 170), boss_modulate, true)
		_draw_bar(boss_draw_pos - camera + Vector2(-74, -88), 148, boss_hp / boss_hp_max, Color(1.0, 0.12, 0.22))
	_draw_parasite_marks(camera)
	_draw_parasite_foreground(camera)
	if not phase_fragment.is_empty():
		_draw_phase_fragment(camera)
	_draw_companions(camera)
	_draw_player(camera)
	_draw_effects(camera)
	if boss1_rain_active:
		_draw_weather_precipitation(camera)
	if boss1_rewind_sequence.is_empty() and (mode == "game" or mode == "shop_countdown" or mode == "boss_call" or mode == "pause_countdown"):
		_draw_ground_target_preview(viewport, camera)
	_draw_hud(viewport)
	_draw_boss1_rewind_overlay(viewport, camera)
	if boss1_rewind_sequence.is_empty() and (mode == "game" or mode == "shop_countdown" or mode == "boss_call" or mode == "pause_countdown"):
		if teleport_dragging:
			_draw_teleport_preview(viewport, camera)
		_draw_touch_controls(viewport)
	if damage_flash_timer > 0.0:
		var alpha = clamp(damage_flash_timer / 0.22, 0.0, 1.0) * 0.30
		draw_rect(Rect2(Vector2.ZERO, viewport), Color(1.0, 0.04, 0.02, alpha), true)


func _screen_shake_offset() -> Vector2:
	if screen_shake_timer <= 0.0 or not gfx_screen_shake:
		return Vector2.ZERO
	var strength = screen_shake_strength * (screen_shake_timer / 0.24)
	return Vector2(rng.randf_range(-strength, strength), rng.randf_range(-strength, strength))


func _draw_companions(camera: Vector2) -> void:
	if trembo_charges > 0:
		var trembo_texture = _companion_frame("trembo_" + trembo_facing, trembo_anim_time, 7.0)
		var trembo_screen = trembo_pos - camera
		_draw_dynamic_shadow_fit(trembo_texture, trembo_screen, Vector2(66, 92), false, true, 0.38)
		_draw_entity_fit(trembo_texture, trembo_screen, Vector2(66, 92), Color.WHITE, true)
		var pulse = 0.50 + sin(trembo_anim_time * 4.0) * 0.12
		draw_arc(trembo_screen + Vector2(0, 34), 25.0, 0, TAU, 30, Color(0.32, 0.84, 1.0, pulse), 2.0)
	if petro_active:
		var direction = petro_facing
		if petro_evolution > 1 and direction in ["up", "down", "stop"]:
			direction = "left" if petro_facing != "right" else "right"
		var key = "petro_%d_%s" % [petro_evolution, direction]
		var petro_texture = _companion_frame(key, petro_anim_time, 6.0)
		if petro_texture == null:
			petro_texture = _companion_frame("petro_1_" + direction, petro_anim_time, 6.0)
		var size = Vector2(58, 72) if petro_evolution == 1 else (Vector2(86, 104) if petro_evolution == 2 else Vector2(122, 138))
		var petro_screen = petro_pos - camera
		_draw_dynamic_shadow_fit(petro_texture, petro_screen, size, false, true, 0.42)
		_draw_entity_fit(petro_texture, petro_screen, size, Color.WHITE, true)
		_draw_bar(petro_screen + Vector2(-28, -size.y * 0.55), 56, clamp(petro_hp / max(1.0, petro_hp_max), 0.0, 1.0), Color(0.18, 0.94, 1.0))
		_draw_centered("PETRO %d" % petro_evolution, petro_screen + Vector2(0, -size.y * 0.55 - 8), 12, Color(0.78, 1.0, 1.0, 0.92))


func _companion_frame(key: String, animation_time: float, fps: float) -> Texture2D:
	var frames = textures.get(key, [])
	if not frames is Array or frames.is_empty():
		return null
	return frames[int(animation_time * fps) % frames.size()]


func _draw_enemies(camera: Vector2) -> void:
	for enemy in enemies:
		var pos: Vector2 = enemy["pos"] - camera
		var tex = _enemy_texture(enemy)
		var size = Vector2(72, 72)
		if enemy["type"] == ENEMY_AGGLOMERATOR:
			size = Vector2(86, 86)
		elif enemy["type"] == ENEMY_LARAPIO:
			size = Vector2(78, 78)
		elif enemy["type"] == ENEMY_ATIRADOR:
			size = Vector2(82, 82)
		elif enemy["type"] == ENEMY_KAMIKAZE:
			size = Vector2(64, 64)
		elif enemy["type"] == ENEMY_DEVOTO:
			size = Vector2(62, 62)
		elif enemy["type"] == ENEMY_GUARDIAO:
			size = Vector2(98, 98)
		var draw_pos = pos + _enemy_visual_offset(enemy)
		var alpha = float(enemy.get("alpha", 1.0))
		var modulate_color = Color(1, 1, 1, alpha)
		if enemy["type"] == ENEMY_ATIRADOR:
			modulate_color = Color(0.7, 0.86, 1.0, alpha)
		elif enemy["type"] == ENEMY_KAMIKAZE:
			modulate_color = Color(1.0, 0.47, 0.47, alpha)
			if sin(time_alive * 12.0) > 0.0:
				modulate_color = Color(1.0, 0.8, 0.8, alpha)
		elif enemy["type"] == ENEMY_DEVOTO:
			modulate_color = Color(0.76, 1.0, 0.56, alpha)
		elif enemy["type"] == ENEMY_INCENSARIO:
			modulate_color = Color(0.88, 0.72, 1.0, alpha)
		elif enemy["type"] == ENEMY_GUARDIAO:
			modulate_color = Color(0.70, 0.76, 0.62, alpha)
		_draw_dynamic_shadow(tex, pos, size, _enemy_should_flip(enemy), 0.40 * alpha)
		var is_attack_target = _attack_target_is_enemy(int(enemy["uid"]))
		if is_attack_target:
			_draw_attack_target_marker(draw_pos + Vector2(0, size.y * 0.30), size.x * 0.43, locked_target_kind == "enemy" and locked_target_uid == int(enemy["uid"]))

		if not _active_prismatica_secondary().is_empty() and enemy["pos"].distance_to(player_pos) < 900.0:
			var t = float(Time.get_ticks_msec()) * 0.001
			var hue = fmod(t * 0.8 + int(enemy["uid"]) * 0.15, 1.0)
			var c = Color.from_hsv(hue, 1.0, 1.0, 0.5)

			draw_circle(draw_pos + Vector2(0, 16), 46, Color(c.r, c.g, c.b, 0.18))
			modulate_color = c
		if is_attack_target:
			modulate_color = modulate_color.lerp(Color(1.0, 0.92, 0.34, alpha), 0.48)

		_draw_entity(tex, draw_pos, size, modulate_color, _enemy_should_flip(enemy))
		var enemy_bar_pos = pos + Vector2(-30, -48)
		var enemy_hp_ratio = float(enemy["hp"]) / float(enemy["max_hp"])
		_draw_bar(enemy_bar_pos, 60, enemy_hp_ratio, Color(0.2, 1.0, 0.2))
		if execute_threshold > 0.0:
			_draw_collector_threshold(enemy_bar_pos, 60.0, execute_threshold, enemy_hp_ratio)
		if enemy["type"] == ENEMY_AGGLOMERATOR:
			for i in range(8):
				var ang = time_alive * 5.0 + i * TAU / 8.0
				draw_circle(pos + Vector2(cos(ang), sin(ang)) * 44.0, 3 + int(i % 3), Color(0.48, 0.48, 0.56, 0.75))
		if enemy["type"] == ENEMY_CURATER:
			draw_arc(pos, 92, 0, TAU, 48, Color(0.32, 1.0, 0.42, 0.35), 2)
			for i in range(7):
				var px = pos.x + cos(i * 1.7) * 30.0 + sin(time_alive * 2.0 + i) * 2.0
				var py = pos.y + 26.0 + sin(i * 1.3) * 8.0
				draw_line(Vector2(px, py), Vector2(px, py - 10 - (i % 3) * 3), Color(0.28, 0.86, 0.36), 2)
				draw_circle(Vector2(px + 3, py - 12), 4, Color(0.50, 1.0, 0.58))
		if enemy["type"] == ENEMY_PROJECTOR:
			var r = 24.0 + sin(time_alive * 9.0) * 3.0
			draw_arc(pos, r, 0, TAU, 40, Color(1.0, 0.76, 0.28, 0.86), 2)
			draw_circle(pos + Vector2(0, -12), 5, Color(1.0, 0.96, 0.62, 0.95))
		if enemy["type"] == ENEMY_CRYSTAL:
			_draw_hex(pos, 38.0 + sin(time_alive * 4.0) * 8.0, Color(0.0, 0.78, 1.0, 0.70))
		if enemy["type"] == ENEMY_LARAPIO and int(enemy.get("stolen", 0)) > 0:
			var bag_pulse = 0.5 + 0.5 * sin(time_alive * 8.0)
			draw_circle(draw_pos + Vector2(23, -21), 11.0 + bag_pulse * 2.0, Color(1.0, 0.78, 0.18, 0.72))
			draw_circle(draw_pos + Vector2(23, -21), 5.0, Color(0.45, 0.24, 0.04, 0.88))
			_draw_centered(str(int(enemy.get("stolen", 0))), draw_pos + Vector2(23, -39), 11, Color(1.0, 0.92, 0.42, 0.92))
		if enemy["type"] == ENEMY_LARAPIO and int(enemy.get("stolen", 0)) > 0 and enemy["hp"] < enemy["max_hp"] * 0.7:
			var ratio = clamp(float(enemy.get("portal", 0.0)) / LARAPIO_PORTAL_TIME, 0.0, 1.0)
			draw_circle(pos + Vector2(0, 30), 16 + 34 * ratio, Color(0.25, 0.0, 0.38, 0.45))
			draw_arc(pos + Vector2(0, 30), 18 + 36 * ratio, 0, TAU, 40, Color(0.75, 0.2, 1.0, 0.8), 3)
		if enemy["type"] == ENEMY_INCENSARIO and float(enemy.get("prepare", 0.0)) > 0.0:
			var target = Vector2(enemy.get("miasma_target", player_pos)) - camera
			draw_circle(target, 64.0, Color(0.42, 0.72, 0.08, 0.13))
			draw_arc(target, 64.0, 0, TAU, 40, Color(0.72, 1.0, 0.28, 0.82), 3.0)
		if enemy["type"] == ENEMY_GUARDIAO:
			var shield_dir = Vector2(enemy.get("facing_dir", Vector2.LEFT)).normalized()
			draw_arc(pos + shield_dir * 26.0, 42.0, shield_dir.angle() - PI * 0.45, shield_dir.angle() + PI * 0.45, 24, Color(0.78, 0.92, 0.56, 0.82), 5.0)
		if int(enemy.get("laceracao", 0)) > 0:
			_draw_centered("x%d" % int(enemy["laceracao"]), pos + Vector2(28, -36), 14, Color(1.0, 0.2, 0.25))


func _draw_larapio_coin_drops(camera: Vector2) -> void:
	for coin in larapio_coin_drops:
		var pos = Vector2(coin.get("pos", Vector2.ZERO)) - camera
		var life_ratio = clamp(float(coin.get("life", 0.0)) / max(0.01, float(coin.get("max", 1.0))), 0.0, 1.0)
		var collectable = bool(coin.get("collectable", false))
		var radius = 7.0 if collectable else 4.5
		var shine = 0.5 + 0.5 * sin(float(coin.get("phase", 0.0)) * 3.2)
		var alpha = 0.95 if collectable else clamp(life_ratio, 0.0, 0.85)
		draw_circle(pos + Vector2(0, 5), radius * 1.25, Color(0.05, 0.035, 0.0, 0.22 * alpha))
		draw_circle(pos, radius, Color(1.0, 0.76 + shine * 0.16, 0.12, alpha))
		draw_arc(pos, radius + 2.0, 0, TAU, 20, Color(0.50, 0.30, 0.03, 0.86 * alpha), 1.3)
		draw_line(pos + Vector2(-radius * 0.35, -radius * 0.35), pos + Vector2(radius * 0.35, radius * 0.35), Color(1.0, 1.0, 0.72, 0.55 * alpha), 1.2)
		if collectable:
			draw_arc(pos, radius + 7.0 + shine * 2.0, 0, TAU, 24, Color(1.0, 0.82, 0.20, 0.36), 1.4)


func _draw_phase_fragment(camera: Vector2) -> void:
	var pos: Vector2 = phase_fragment["pos"] - camera
	var pulse_t = float(phase_fragment.get("pulse", 0.0))
	var pulse = 0.5 + 0.5 * sin(pulse_t * 2.0)
	var hover = sin(float(phase_fragment.get("life", 0.0)) * 2.4) * 7.0
	pos.y += hover
	var outer_r = 38.0 + pulse * 10.0
	var inner_r = 20.0 + pulse * 5.0
	draw_circle(pos, outer_r * 1.20, Color(0.06, 0.0, 0.12, 0.28))
	draw_circle(pos, outer_r * 0.92, Color(0.45, 0.08, 1.0, 0.12 + pulse * 0.06))
	draw_arc(pos, outer_r + 12.0, 0, TAU, 72, Color(0.74, 0.34, 1.0, 0.92), 3)
	draw_arc(pos, outer_r * 0.78, 0, TAU, 64, Color(0.22, 0.92, 1.0, 0.82), 2)
	for i in range(6):
		var ang = pulse_t * 1.55 + i * TAU / 6.0
		var shard_pos = pos + Vector2.from_angle(ang) * (outer_r + 12.0 + sin(pulse_t * 3.0 + i) * 5.0)
		var shard_size = 7.0 + float(i % 2) * 2.0
		var shard_points = PackedVector2Array([
			shard_pos + Vector2(0, -shard_size),
			shard_pos + Vector2(shard_size * 0.58, 0),
			shard_pos + Vector2(0, shard_size),
			shard_pos + Vector2(-shard_size * 0.58, 0)
		])
		draw_polygon(shard_points, PackedColorArray([Color(0.86, 0.94, 1.0, 0.82)]))
		draw_polyline(PackedVector2Array([shard_points[0], shard_points[1], shard_points[2], shard_points[3], shard_points[0]]), Color(0.30, 0.94, 1.0, 0.78), 1.5, true)
	var core_points = PackedVector2Array([
		pos + Vector2(0, -inner_r * 1.35),
		pos + Vector2(inner_r * 0.58, -inner_r * 0.28),
		pos + Vector2(inner_r * 0.74, inner_r * 0.48),
		pos + Vector2(0, inner_r * 1.50),
		pos + Vector2(-inner_r * 0.74, inner_r * 0.48),
		pos + Vector2(-inner_r * 0.58, -inner_r * 0.28)
	])
	draw_polygon(core_points, PackedColorArray([Color(0.78, 0.90, 1.0, 0.92)]))
	draw_polyline(PackedVector2Array([core_points[0], core_points[1], core_points[2], core_points[3], core_points[4], core_points[5], core_points[0]]), Color(1.0, 1.0, 1.0, 0.92), 2.0, true)
	draw_circle(pos, inner_r * 0.48, Color(0.18, 0.95, 1.0, 0.86))
	draw_circle(pos, inner_r * 0.22, Color(1.0, 1.0, 1.0, 0.94))
	for i in range(4):
		var line_ang = pulse_t * 2.2 + i * PI * 0.5
		draw_line(pos + Vector2.from_angle(line_ang) * 8.0, pos + Vector2.from_angle(line_ang) * (outer_r + 4.0), Color(1.0, 1.0, 1.0, 0.54), 1.6)
	_draw_centered("FRAGMENTO", pos + Vector2(0, -62), 18, Color(0.92, 0.98, 1.0))
	_draw_centered("TOQUE PARA ATRAVESSAR", pos + Vector2(0, 68), 13, Color(0.58, 0.94, 1.0, 0.92))


func _draw_parasite_spit_zones(camera: Vector2) -> void:
	for zone in parasite_spit_zones:
		var state = String(zone.get("state", "flying"))
		var phase = float(zone.get("phase", 0.0))
		if state == "flying":
			var progress = clamp(float(zone.get("age", 0.0)) / max(0.01, float(zone.get("travel", PARASITE_SPIT_TRAVEL))), 0.0, 1.0)
			var world_pos = Vector2(zone["origin"]).lerp(Vector2(zone["target"]), progress) + Vector2(0, -sin(progress * PI) * 92.0)
			var pos = world_pos - camera
			draw_circle(pos, 21.0, Color(0.18, 0.30, 0.05, 0.30))
			for worm_index in range(4):
				var angle = phase + progress * 10.0 + worm_index * TAU / 4.0
				_draw_parasite_worm(pos + Vector2.from_angle(angle) * 13.0, angle + PI * 0.5, 0.62, time_alive * 8.0 + worm_index, 0.96)
			var shadow = Vector2(zone["origin"]).lerp(Vector2(zone["target"]), progress) - camera
			draw_set_transform(shadow, 0.0, Vector2(1.0, 0.34))
			draw_circle(Vector2.ZERO, 20.0 + progress * 10.0, Color(0.05, 0.04, 0.02, 0.28))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			continue
		var center = Vector2(zone["target"]) - camera
		var fade = clamp(float(zone.get("life", 0.0)) / max(0.01, float(zone.get("max", PARASITE_SPIT_DURATION))), 0.0, 1.0)
		var pulse = 0.5 + 0.5 * sin(time_alive * 5.5 + phase)
		draw_circle(center, PARASITE_SPIT_RADIUS, Color(0.22, 0.34, 0.05, 0.10 * fade))
		draw_arc(center, PARASITE_SPIT_RADIUS + pulse * 5.0, 0.0, TAU, 56, Color(0.58, 0.88, 0.18, 0.54 * fade), 2.4)
		draw_arc(center, PARASITE_SPIT_RADIUS * 0.72, time_alive * 0.35, time_alive * 0.35 + PI * 1.55, 40, Color(0.78, 1.0, 0.32, 0.28 * fade), 1.2)
		for crack_index in range(11):
			var angle = phase + crack_index * TAU / 11.0
			var start = center + Vector2.from_angle(angle) * (24.0 + (crack_index % 3) * 13.0)
			var finish = center + Vector2.from_angle(angle + sin(crack_index * 2.4) * 0.10) * (72.0 + (crack_index % 4) * 14.0)
			draw_line(start, finish, Color(0.10, 0.075, 0.025, 0.58 * fade), 2.0)
		for worm_index in range(7):
			var angle = time_alive * (0.34 + worm_index * 0.015) + phase + worm_index * TAU / 7.0
			var radius = PARASITE_SPIT_RADIUS * (0.25 + 0.55 * float((worm_index % 3) + 1) / 3.0)
			var worm_pos = center + Vector2.from_angle(angle) * radius
			_draw_parasite_worm(worm_pos, angle + PI * 0.58, 0.46 + (worm_index % 2) * 0.10, time_alive * 5.0 + worm_index, fade)


func _draw_parasite_marks(camera: Vector2) -> void:
	for enemy in enemies:
		var mark_time = float(enemy.get("parasite_mark_time", 0.0))
		if mark_time <= 0.0 or float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		_draw_parasite_host(Vector2(enemy["pos"]) - camera, 30.0, int(enemy.get("seeds", 1)), int(enemy["uid"]), mark_time)
	if boss_active and boss_hp > 0.0 and boss_parasite_mark_time > 0.0:
		_draw_parasite_host(boss_pos - camera, 78.0, max(3, boss_parasite_seeds), -9173, boss_parasite_mark_time)


func _draw_parasite_host(center: Vector2, radius: float, seeds: int, uid: int, mark_time: float) -> void:
	var pulse = 0.5 + 0.5 * sin(time_alive * 7.0 + uid * 0.013)
	var fade = clamp(mark_time / PARASITE_MARK_DURATION, 0.0, 1.0)
	draw_circle(center, radius * 0.82, Color(0.12, 0.22, 0.04, 0.07 + pulse * 0.04))
	for vein_index in range(5):
		var vein_angle = time_alive * 0.16 + uid * 0.007 + vein_index * TAU / 5.0
		var inner = center + Vector2.from_angle(vein_angle + sin(time_alive * 2.0 + vein_index) * 0.12) * radius * 0.34
		var outer = center + Vector2.from_angle(vein_angle) * radius * (0.78 + pulse * 0.10)
		draw_line(inner, outer, Color(0.36, 0.68, 0.12, 0.34 * fade), 3.4)
		draw_line(inner, outer, Color(0.76, 1.0, 0.32, 0.54 * fade), 1.0)
	var worm_count = clamp(seeds + 1, 3, 6)
	for worm_index in range(worm_count):
		var angle = time_alive * (0.72 + worm_index * 0.035) + worm_index * TAU / worm_count + uid * 0.001
		var orbit = radius * (0.70 + 0.13 * sin(time_alive * 2.7 + worm_index))
		var worm_pos = center + Vector2.from_angle(angle) * orbit
		_draw_parasite_worm(worm_pos, angle + PI * 0.56, 0.72 + (worm_index % 3) * 0.10, time_alive * 5.0 + worm_index, fade)
	for drop_index in range(3):
		var cycle = fposmod(time_alive * (0.58 + drop_index * 0.08) + drop_index * 0.31 + abs(uid) * 0.0007, 1.0)
		var drop_alpha = sin(cycle * PI) * fade
		var x = center.x + sin(uid * 0.017 + drop_index * 2.1) * radius * 0.52
		var start_y = center.y + radius * 0.34
		var larva_pos = Vector2(x + sin(cycle * 8.0 + drop_index) * 3.0, start_y + cycle * (radius * 0.82 + 24.0))
		draw_line(Vector2(x, start_y - 3.0), larva_pos, Color(0.42, 0.70, 0.16, 0.18 * drop_alpha), 1.0)
		_draw_parasite_larva_drop(larva_pos, 0.62 + drop_index * 0.08, drop_alpha)


func _draw_parasite_worm(origin: Vector2, angle: float, scale: float, phase: float, alpha := 1.0) -> void:
	var points = PackedVector2Array()
	var segments = 8
	for segment in range(segments):
		var along = (float(segment) / float(segments - 1) - 0.5) * 30.0 * scale
		var local = Vector2(along, sin(phase + segment * 0.92) * 4.2 * scale)
		points.append(origin + local.rotated(angle))
	if points.size() < 2:
		return
	draw_polyline(points, Color(0.035, 0.055, 0.018, 0.92 * alpha), 9.0 * scale, true)
	draw_polyline(points, Color(0.42, 0.68, 0.15, 0.96 * alpha), 6.0 * scale, true)
	draw_polyline(points, Color(0.78, 0.96, 0.32, 0.46 * alpha), 1.4 * scale, true)
	for segment in range(1, segments - 1):
		var segment_radius = (2.4 + (segment % 2) * 0.7) * scale
		draw_circle(points[segment], segment_radius, Color(0.54, 0.78, 0.20, 0.88 * alpha))
	var head = points[points.size() - 1]
	var head_dir = (head - points[points.size() - 2]).normalized()
	var side = head_dir.orthogonal()
	draw_circle(head, 5.4 * scale, Color(0.20, 0.32, 0.08, 0.96 * alpha))
	draw_circle(head + head_dir * 1.4 * scale, 3.8 * scale, Color(0.62, 0.84, 0.22, 0.96 * alpha))
	draw_circle(head + side * 2.1 * scale, 0.85 * scale, Color(1.0, 0.76, 0.18, alpha))
	draw_circle(head - side * 2.1 * scale, 0.85 * scale, Color(1.0, 0.76, 0.18, alpha))
	draw_line(head + head_dir * 3.0 * scale, head + head_dir * 7.0 * scale + side * 3.0 * scale, Color(0.92, 0.92, 0.48, 0.92 * alpha), 1.4 * scale)
	draw_line(head + head_dir * 3.0 * scale, head + head_dir * 7.0 * scale - side * 3.0 * scale, Color(0.92, 0.92, 0.48, 0.92 * alpha), 1.4 * scale)


func _draw_parasite_larva_drop(pos: Vector2, scale: float, alpha: float) -> void:
	for segment in range(4):
		var p = pos + Vector2(sin(time_alive * 7.0 + segment) * 1.5, segment * 3.2) * scale
		draw_circle(p, (2.5 - segment * 0.22) * scale, Color(0.62, 0.88, 0.22, 0.86 * alpha))
	draw_circle(pos + Vector2(0, -1.0), 1.0 * scale, Color(1.0, 0.80, 0.20, alpha))


func _draw_manifestation_secondaries(camera: Vector2) -> void:
	for secondary in manifestation_secondaries:
		match String(secondary.get("kind", "")):
			"eletrica":
				_draw_secondary_eletrica(secondary, camera)
			"lacerante":
				_draw_secondary_lacerante(secondary, camera)
			"prismatica":
				_draw_secondary_prismatica(secondary, camera)
			"retornante":
				_draw_secondary_retornante(secondary, camera)
			"parasitica":
				_draw_secondary_parasitica(secondary, camera)
			"gravitante":
				_draw_secondary_gravitante(secondary, camera)
			"ancorada":
				_draw_secondary_ancorada(secondary, camera)


func _draw_secondary_eletrica(secondary: Dictionary, camera: Vector2) -> void:
	var active_time = float(secondary.get("active_time", 0.0))
	var ring_radius = 150.0 + sin((time_alive + active_time * 0.12) * 6.2) * 18.0
	var center = player_pos - camera
	var points = PackedVector2Array()
	var giro = time_alive * 0.9
	for i in range(18):
		var ang = giro + i * TAU / 18.0
		points.append(center + Vector2(cos(ang), sin(ang)) * ring_radius)
	if points.size() >= 3:
		draw_polyline(points, Color(0.32, 1.0, 1.0, 0.72), 4.0, true)
		draw_polyline(points, Color(1.0, 1.0, 1.0, 0.88), 1.5, true)
	for i in range(0, points.size(), 3):
		var a = points[i]
		var b = points[(i + 1) % points.size()]
		draw_line(a, b, Color(0.92, 0.42, 1.0, 0.42), 5.0)
		draw_line(a, b, Color(0.74, 1.0, 1.0, 0.95), 1.5)
	for enemy in enemies:
		var dist = enemy["pos"].distance_to(player_pos)
		if abs(dist - ring_radius) <= 42.0 or dist <= ring_radius * 0.48:
			draw_line(center, enemy["pos"] - camera, Color(0.54, 1.0, 1.0, 0.52), 2.0)
	var bonus_step = int(secondary.get("bonus_step", 0))
	if bonus_step > 0:
		draw_arc(center, ring_radius + 10.0, 0, TAU, 54, Color(1.0, 0.48, 0.92, min(0.72, 0.24 + bonus_step * 0.025)), 2.0)


func _draw_secondary_lacerante(secondary: Dictionary, camera: Vector2) -> void:
	var center_world: Vector2 = secondary.get("center", player_pos)
	var center = center_world - camera
	var pulse = 132.0 + 30.0 * pow(sin(time_alive * 5.0), 2.0)
	draw_circle(center, pulse, Color(0.12, 0.0, 0.03, 0.12))
	draw_arc(center, pulse, 0, TAU, 56, Color(0.55, 0.0, 0.10, 0.75), 2.0)
	draw_arc(center, max(42.0, pulse * 0.58), 0, TAU, 42, Color(1.0, 0.18, 0.24, 0.82), 1.5)
	for cut in secondary.get("cuts", []):
		var fade = clamp(float(cut.get("life", 0.0)) / max(0.01, float(cut.get("max", 0.36))), 0.0, 1.0)
		var world_a: Vector2 = cut["a"]
		var world_b: Vector2 = cut["b"]
		var a = world_a - camera
		var b = world_b - camera
		var width = max(1.0, 10.0 * fade)
		draw_line(a, b, Color(0.37, 0.0, 0.05, 0.82), width + 5.0)
		draw_line(a, b, Color(1.0, 0.16, 0.22, 0.94), width)
		draw_line(a, b, Color(1.0, 0.90, 0.88, 0.92), max(1.0, width * 0.26))


func _draw_secondary_prismatica(secondary: Dictionary, camera: Vector2) -> void:
	var center_world: Vector2 = secondary.get("center", player_pos)
	var center = center_world - camera
	var ring = 42.0 + sin(time_alive * 4.2) * 6.0
	draw_arc(center, ring, 0.0, TAU, 32, Color(0.42, 1.0, 0.96, 0.68), 2.2)
	draw_arc(center, ring + 12.0, time_alive * 1.4, time_alive * 1.4 + PI * 1.3, 26, Color(1.0, 0.54, 0.78, 0.82), 1.8)
	var angle = float(secondary.get("angle", 0.0))
	var beam_dirs = _secondary_prismatica_beam_dirs(angle)
	for beam_index in range(beam_dirs.size()):
		var dir: Vector2 = beam_dirs[beam_index]
		var hue = fposmod(time_alive * 0.65 + float(beam_index) * 0.19, 1.0)
		var disco = Color.from_hsv(hue, 0.82, 1.0, 0.22)
		var disco_alt = Color.from_hsv(fposmod(hue + 0.34, 1.0), 0.76, 1.0, 0.16)
		var beam_start = center_world - dir * SECONDARY_PRISMATICA_BEAM_RANGE - camera
		var beam_end = center_world + dir * SECONDARY_PRISMATICA_BEAM_RANGE - camera
		draw_line(beam_start, beam_end, disco, SECONDARY_PRISMATICA_BEAM_WIDTH * 0.78)
		draw_line(beam_start, beam_end, disco_alt, SECONDARY_PRISMATICA_BEAM_WIDTH * 0.36)
		draw_line(beam_start, beam_end, Color(1.0, 1.0, 1.0, 0.28), 1.4)
		draw_line(beam_start, beam_end, Color.from_hsv(hue, 0.55, 1.0, 0.24), 0.8)
		var side = dir.orthogonal().normalized()
		for tip_dir in [-1.0, 1.0]:
			var tip = center + dir * SECONDARY_PRISMATICA_BEAM_RANGE * tip_dir
			var diamond_dir = dir * tip_dir
			var diamond = PackedVector2Array([
				tip + diamond_dir * 10.0,
				tip + side * 6.0,
				tip - diamond_dir * 10.0,
				tip - side * 6.0
			])
			draw_polygon(diamond, PackedColorArray([Color(disco_alt.r, disco_alt.g, disco_alt.b, 0.18)]))
			draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color(1.0, 1.0, 1.0, 0.34), 1.0, true)
	for i in range(3):
		var phase_offset = float(i + 1) * 0.08
		var ghost_alpha = 0.10 - i * 0.025
		for ghost_index in range(beam_dirs.size()):
			var dir: Vector2 = _secondary_prismatica_beam_dirs(angle - phase_offset)[ghost_index]
			var ghost_color = Color.from_hsv(fposmod(time_alive * 0.65 + float(ghost_index) * 0.19 - phase_offset, 1.0), 0.82, 1.0, ghost_alpha)
			var ga = center_world - dir * SECONDARY_PRISMATICA_BEAM_RANGE - camera
			var gb = center_world + dir * SECONDARY_PRISMATICA_BEAM_RANGE - camera
			draw_line(ga, gb, ghost_color, max(1.0, SECONDARY_PRISMATICA_BEAM_WIDTH * (0.16 - i * 0.035)))
	for beam in secondary.get("beams", []):
		var fade = clamp(float(beam.get("life", 0.0)) / max(0.01, float(beam.get("max", 0.28))), 0.0, 1.0)
		var beam_color: Color = beam.get("color", Color(0.32, 1.0, 0.96))
		for segment in beam.get("segments", []):
			var a = Vector2(segment["a"]) - camera
			var b = Vector2(segment["b"]) - camera
			draw_line(a, b, Color(beam_color.r, beam_color.g, beam_color.b, 0.18 + fade * 0.22), 6.0)
			draw_line(a, b, Color(beam_color.r, beam_color.g, beam_color.b, 0.85), 3.0)
			draw_line(a, b, Color(1.0, 1.0, 1.0, 0.92), 1.0)


func _draw_secondary_retornante(secondary: Dictionary, camera: Vector2) -> void:
	var center = player_pos - camera
	draw_arc(center, 34.0 + sin(time_alive * 5.4) * 4.0, 0.0, TAU, 28, Color(0.72, 0.48, 1.0, 0.58), 2.0)
	for bullet in return_bullets:
		if float(bullet.get("paradox_until", 0.0)) < time_alive:
			continue
		var pos = Vector2(bullet["pos"]) - camera
		var phase = float(bullet.get("phase", 0.0))
		draw_line(center, pos, Color(0.80, 0.60, 1.0, 0.42), 3.0)
		draw_line(center, pos, Color(1.0, 1.0, 1.0, 0.78), 1.0)
		draw_arc(pos, 18.0 + sin(phase * 2.0) * 4.0, phase, phase + PI * 1.45, 22, Color(1.0, 0.50, 0.84, 0.86), 2.0)
	for ghost in secondary.get("ghosts", []):
		var ang = float(ghost.get("base_angle", 0.0)) + float(secondary.get("ghost_tick", 0.0)) * 0.9
		var endpoint = player_pos + Vector2(cos(ang) * float(ghost.get("radius_x", 260.0)), sin(ang + float(ghost.get("phase", 0.0)) * 0.18) * float(ghost.get("radius_y", 210.0)))
		var draw_end = endpoint - camera
		draw_line(center, draw_end, Color(0.66, 0.42, 1.0, 0.28), 2.5)
		draw_circle(draw_end, 8.0, Color(0.94, 0.76, 1.0, 0.82))
		draw_circle(draw_end, 14.0, Color(0.52, 0.30, 0.92, 0.22))


func _draw_secondary_parasitica(secondary: Dictionary, camera: Vector2) -> void:
	for target in secondary.get("targets", []):
		if bool(target.get("done", false)):
			continue
		var target_world = _parasite_ultimate_target_pos(target)
		if target_world == Vector2.ZERO:
			continue
		var age = float(target.get("age", 0.0))
		if not bool(target.get("arrived", false)):
			for worm in target.get("worms", []):
				var travel = clamp((age - float(worm.get("delay", 0.0))) / max(0.01, float(worm.get("duration", 1.2))), 0.0, 1.0)
				if age < float(worm.get("delay", 0.0)):
					continue
				_draw_parasite_burrow(worm, target_world + Vector2(0, 26), travel, camera)
			var warning = clamp(age / max(0.01, float(target.get("arrival", 1.95))), 0.0, 1.0)
			_draw_parasite_emergence(target_world + Vector2(0, 26) - camera, warning, int(target.get("seed", 0)))
		else:
			_draw_parasite_feast_ground(target, target_world, camera)


func _parasite_curve_point(start: Vector2, finish: Vector2, t: float, bend: float) -> Vector2:
	var direction = finish - start
	var side = direction.normalized().orthogonal()
	var control_a = start + direction * 0.30 + side * bend
	var control_b = start + direction * 0.72 - side * bend * 0.42
	var inv = 1.0 - t
	return start * inv * inv * inv + control_a * 3.0 * inv * inv * t + control_b * 3.0 * inv * t * t + finish * t * t * t


func _draw_parasite_burrow(worm: Dictionary, finish: Vector2, t: float, camera: Vector2) -> void:
	var start = Vector2(worm.get("start", finish))
	var bend = float(worm.get("bend", 0.0))
	var phase = float(worm.get("phase", 0.0))
	var scale = float(worm.get("scale", 1.0))
	var trail = PackedVector2Array()
	var trail_start = max(0.0, t - 0.11)
	for sample in range(9):
		var sample_t = lerp(trail_start, t, float(sample) / 8.0)
		trail.append(_parasite_curve_point(start, finish, sample_t, bend) - camera)
	if trail.size() >= 2:
		draw_polyline(trail, Color(0.07, 0.055, 0.025, 0.52), 8.0 * scale, true)
		draw_polyline(trail, Color(0.34, 0.28, 0.10, 0.60), 3.5 * scale, true)
		draw_polyline(trail, Color(0.64, 0.74, 0.18, 0.18), 1.0 * scale, true)
		for groove_index in range(1, trail.size(), 2):
			var groove = trail[groove_index]
			var groove_side = Vector2.from_angle(phase + groove_index * 1.7) * 6.0 * scale
			draw_line(groove - groove_side, groove + groove_side, Color(0.22, 0.15, 0.05, 0.48), 1.5)
	for break_index in range(1, 9):
		var break_t = float(break_index) / 9.0
		if break_t > t:
			continue
		var break_world = _parasite_curve_point(start, finish, break_t, bend)
		var before = _parasite_curve_point(start, finish, max(0.0, break_t - 0.015), bend)
		var after = _parasite_curve_point(start, finish, min(1.0, break_t + 0.015), bend)
		var break_heading = (after - before).angle()
		var break_fade = clamp(1.0 - (t - break_t) * 1.15, 0.18, 1.0)
		_draw_parasite_ground_break(break_world - camera, break_heading, scale, phase + break_index * 1.73, break_fade)
	var mound = _parasite_curve_point(start, finish, t, bend) - camera
	var next_t = min(1.0, t + 0.02)
	var heading = (_parasite_curve_point(start, finish, next_t, bend) - _parasite_curve_point(start, finish, max(0.0, t - 0.02), bend)).normalized()
	draw_set_transform(mound, heading.angle(), Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, 15.0 * scale, Color(0.08, 0.055, 0.025, 0.72))
	draw_circle(Vector2.ZERO, 10.5 * scale, Color(0.42, 0.31, 0.10, 0.72))
	draw_arc(Vector2.ZERO, 18.0 * scale, 0.0, TAU, 28, Color(0.72, 0.82, 0.22, 0.30), 1.6)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for dirt_index in range(5):
		var dirt_angle = phase + dirt_index * 2.3 + t * 10.0
		var dirt_pos = mound + Vector2.from_angle(dirt_angle) * (10.0 + dirt_index * 2.1) * scale
		draw_circle(dirt_pos, (2.6 - dirt_index * 0.24) * scale, Color(0.38, 0.27, 0.08, 0.72))
	if t > 0.76:
		var emerge = smoothstep(0.76, 1.0, t)
		var worm_pos = finish - camera + Vector2(0, 12.0 - emerge * 26.0)
		_draw_parasite_worm(worm_pos, -PI * 0.5 + sin(phase + t * 8.0) * 0.18, scale, phase + t * 12.0, emerge)


func _draw_parasite_ground_break(center: Vector2, heading: float, scale: float, seed: float, fade: float) -> void:
	var forward = Vector2.from_angle(heading)
	var side = forward.orthogonal()
	draw_set_transform(center, heading, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, 13.0 * scale, Color(0.045, 0.032, 0.014, 0.46 * fade))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for branch_index in range(5):
		var branch_angle = heading + (branch_index - 2) * 0.48 + sin(seed + branch_index * 2.2) * 0.16
		var inner = center + forward * sin(seed + branch_index) * 3.0 * scale
		var joint = inner + Vector2.from_angle(branch_angle) * (7.0 + branch_index % 2 * 3.0) * scale
		var outer = joint + Vector2.from_angle(branch_angle + sin(seed * 1.7 + branch_index) * 0.34) * (6.0 + branch_index % 3 * 2.0) * scale
		draw_line(inner, joint, Color(0.035, 0.025, 0.010, 0.86 * fade), 2.4 * scale)
		draw_line(joint, outer, Color(0.12, 0.075, 0.018, 0.72 * fade), 1.5 * scale)
	var chunk_center = center + side * sin(seed * 2.4) * 8.0 * scale - Vector2(0, 3.0 * scale)
	var chunk = PackedVector2Array([
		chunk_center + Vector2(-5.0, 3.0) * scale,
		chunk_center + Vector2(-1.0, -5.0) * scale,
		chunk_center + Vector2(6.0, 1.0) * scale
	])
	draw_polygon(chunk, PackedColorArray([Color(0.34, 0.24, 0.075, 0.72 * fade)]))
	draw_polyline(PackedVector2Array([chunk[0], chunk[1], chunk[2], chunk[0]]), Color(0.09, 0.055, 0.016, 0.82 * fade), 1.2, true)


func _draw_parasite_emergence(foot: Vector2, progress: float, seed: int) -> void:
	if progress < 0.58:
		return
	var reveal = smoothstep(0.58, 1.0, progress)
	draw_set_transform(foot, 0.0, Vector2(1.0, 0.38))
	draw_circle(Vector2.ZERO, 34.0 * reveal, Color(0.10, 0.07, 0.025, 0.34 * reveal))
	draw_arc(Vector2.ZERO, 37.0 * reveal, 0.0, TAU, 36, Color(0.58, 0.72, 0.16, 0.52 * reveal), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for crack_index in range(7):
		var angle = seed * 0.001 + crack_index * TAU / 7.0
		var inner = foot + Vector2.from_angle(angle) * 8.0 * reveal
		var outer = foot + Vector2.from_angle(angle + sin(seed + crack_index) * 0.08) * (24.0 + (crack_index % 3) * 7.0) * reveal
		draw_line(inner, outer, Color(0.16, 0.10, 0.03, 0.78 * reveal), 2.2)


func _draw_parasite_feast_ground(target: Dictionary, target_world: Vector2, camera: Vector2) -> void:
	var center = target_world - camera
	var scale = 1.45 if bool(target.get("boss", false)) else 1.0
	var seed = int(target.get("seed", 0))
	var bite = 0.5 + 0.5 * sin(time_alive * 10.0 + seed * 0.01)
	draw_circle(center + Vector2(0, 20.0 * scale), 34.0 * scale, Color(0.18, 0.28, 0.05, 0.10 + bite * 0.05))
	draw_arc(center + Vector2(0, 20.0 * scale), 38.0 * scale, 0.0, TAU, 34, Color(0.62, 0.92, 0.20, 0.42 + bite * 0.20), 2.4)


func _draw_parasite_feast_foreground(target: Dictionary, target_world: Vector2, camera: Vector2) -> void:
	var center = target_world - camera
	var scale = 1.45 if bool(target.get("boss", false)) else 1.0
	var seed = int(target.get("seed", 0))
	for worm_index in range(4):
		var angle = time_alive * (0.84 + worm_index * 0.05) + worm_index * TAU / 4.0 + seed * 0.002
		var orbit = (31.0 + worm_index * 5.0 + sin(time_alive * 3.0 + worm_index) * 4.0) * scale
		var worm_pos = center + Vector2.from_angle(angle) * orbit + Vector2(0, 5.0 * sin(angle * 2.0))
		var facing = (center - worm_pos).angle()
		_draw_parasite_worm(worm_pos, facing, (0.78 + worm_index * 0.07) * scale, time_alive * 7.0 + worm_index, 1.0)
	for drip_index in range(5):
		var cycle = fposmod(time_alive * (0.72 + drip_index * 0.035) + drip_index * 0.19 + seed * 0.0003, 1.0)
		var drip = center + Vector2(sin(seed * 0.03 + drip_index * 1.8) * 30.0 * scale, 14.0 * scale + cycle * 54.0 * scale)
		_draw_parasite_larva_drop(drip, (0.58 + drip_index * 0.045) * scale, sin(cycle * PI))
	var feed_left = float(target.get("feed_left", 0.0))
	_draw_centered("DEVORANDO %.1fs" % feed_left, center + Vector2(0, -68.0 * scale), 13, Color(0.74, 1.0, 0.38, 0.88))


func _draw_parasite_foreground(camera: Vector2) -> void:
	for secondary in manifestation_secondaries:
		if String(secondary.get("kind", "")) != "parasitica":
			continue
		for target in secondary.get("targets", []):
			if bool(target.get("done", false)) or not bool(target.get("arrived", false)):
				continue
			var target_world = _parasite_ultimate_target_pos(target)
			if target_world != Vector2.ZERO:
				_draw_parasite_feast_foreground(target, target_world, camera)


func _draw_secondary_gravitante(secondary: Dictionary, camera: Vector2) -> void:
	var center_world: Vector2 = secondary.get("center", player_pos)
	var center = center_world - camera
	var progress = 1.0 - float(secondary.get("life", 0.0)) / max(0.01, float(secondary.get("max", SECONDARY_GRAVITANTE_DURATION)))
	var radius = _gravitante_radius(progress)
	var captured = int(secondary.get("captured", 0))
	var orbital_bonus = int(secondary.get("orbital_bonus", 0))
	var capture_power = float(secondary.get("capture_power", 0.0))
	var spin_speed = float(secondary.get("spin_speed", 250.0))
	var intensity = clamp(float(captured + orbital_bonus) / 10.0 + capture_power * 0.34 + progress * 0.25, 0.25, 2.3)
	var t = time_alive
	var spin = t * (0.72 + spin_speed * 0.006)

	_draw_gravitante_map_distortion(center_world, camera, radius, progress, intensity, spin)
	draw_circle(center, radius * 1.04, Color(0.02, 0.03, 0.08, 0.08 + 0.05 * intensity))
	for lens_index in range(11):
		var ring = radius * (0.18 + lens_index * 0.075) + sin(t * 2.0 + lens_index) * (5.0 + intensity * 3.0)
		var rot = spin * (0.18 + lens_index * 0.012) + lens_index * 0.27
		var stretch = Vector2(1.0 + sin(lens_index * 1.7) * 0.10, 0.58 + cos(t + lens_index) * 0.07)
		var alpha = clamp(0.20 - lens_index * 0.010 + intensity * 0.030, 0.04, 0.30)
		draw_set_transform(center, rot, stretch)
		draw_arc(Vector2.ZERO, ring, -PI * 0.78, PI * 1.22, 64, Color(0.54, 0.74, 1.0, alpha), 1.1 + intensity * 0.22)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for lane in range(18):
		var ang = spin * (1.0 + lane % 3 * 0.08) + lane * TAU / 18.0
		var edge = center + Vector2.from_angle(ang) * radius * (0.76 + 0.12 * sin(t * 3.0 + lane))
		var inner = center + Vector2.from_angle(ang + 0.36 + intensity * 0.08) * radius * (0.18 + 0.04 * (lane % 4))
		var lane_alpha = 0.07 + intensity * 0.028
		draw_line(edge, inner, Color(0.44, 0.70, 1.0, lane_alpha), 1.2)
		if lane % 3 == 0:
			draw_circle(edge, 2.2 + intensity, Color(0.76, 0.90, 1.0, 0.28))

	draw_arc(center, radius, spin * 0.55, spin * 0.55 + TAU, 96, Color(0.56, 0.82, 1.0, 0.62 + min(0.24, intensity * 0.10)), 2.2 + intensity * 0.45)
	draw_arc(center, radius * 0.72, -spin * 0.95, -spin * 0.95 + PI * 1.65, 86, Color(0.96, 0.36, 1.0, 0.26 + intensity * 0.05), 3.0)

	for enemy in enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var dist = Vector2(enemy["pos"]).distance_to(center_world)
		if dist <= radius:
			var draw_pos = enemy["pos"] - camera
			var edge_ratio = _gravitante_edge_ratio(dist, radius)
			var beam_alpha = 0.10 + edge_ratio * 0.16 + min(0.12, intensity * 0.04)
			draw_line(draw_pos, center, Color(0.58, 0.82, 1.0, beam_alpha), 1.2 + edge_ratio * 1.8)
			_draw_gravitante_enemy_distortion(enemy, center_world, camera, radius, progress, intensity)

	var core_r = 40.0 + progress * 42.0 + intensity * 5.0
	for glow_index in range(5):
		draw_circle(center, core_r + 56.0 - glow_index * 10.0, Color(0.26, 0.08, 0.46, 0.035 + glow_index * 0.012))
	draw_circle(center, core_r * 1.18, Color(0.01, 0.00, 0.03, 0.82))
	draw_circle(center, core_r * 0.74, Color(0.0, 0.0, 0.0, 0.96))
	draw_arc(center, core_r * 1.28, spin * 1.55, spin * 1.55 + PI * 1.72, 76, Color(0.82, 0.94, 1.0, 0.90), 3.0 + intensity * 0.55)
	draw_arc(center, core_r * 1.56, -spin * 1.18, -spin * 1.18 + PI * 1.38, 72, Color(0.54, 0.22, 1.0, 0.54), 5.0)
	draw_arc(center, core_r * 0.96, spin * 2.25, spin * 2.25 + TAU * 0.72, 52, Color(0.18, 0.88, 1.0, 0.64), 2.0)


func _draw_gravitante_map_distortion(center_world: Vector2, camera: Vector2, radius: float, progress: float, intensity: float, spin: float) -> void:
	var map_texture = _current_map_texture()
	if map_texture == null:
		return
	var center = center_world - camera
	var map_rect = _desktop_stage_draw_rect(camera)
	var tex_size = map_texture.get_size()
	var t = time_alive
	var event_radius = 64.0 + progress * 44.0 + intensity * 7.0

	_draw_gravitante_map_mask(map_texture, map_rect, tex_size, center, radius, event_radius, progress, intensity, spin)

	for ring_index in range(5):
		var ring_ratio = 0.24 + float(ring_index) * 0.145
		var sample_radius = radius * ring_ratio
		var pieces = 12 + ring_index * 5
		for piece_index in range(pieces):
			if piece_index % 2 == 1 and ring_index >= 3:
				continue
			var seed = float(piece_index * 37 + ring_index * 113)
			var angle = spin * (0.22 + ring_index * 0.065) + piece_index * TAU / float(pieces) + sin(t * 1.7 + seed) * 0.035
			var radial = Vector2.from_angle(angle)
			var tangent = radial.orthogonal()
			var source_center = center + radial * sample_radius + tangent * sin(t * 2.4 + seed) * (8.0 + intensity * 5.0)
			if not map_rect.has_point(source_center):
				continue
			var source_size = 34.0 - ring_index * 2.4 + intensity * 4.0
			var source_rect = Rect2(source_center - Vector2(source_size, source_size) * 0.5, Vector2(source_size, source_size))
			var src = _map_screen_rect_to_source(map_rect, tex_size, source_rect)
			if src.size.x <= 1.0 or src.size.y <= 1.0:
				continue
			var pull = 0.18 + progress * 0.16 + intensity * 0.045 + float(4 - ring_index) * 0.018
			var sink = source_center.lerp(center, pull)
			sink += tangent * (22.0 + ring_index * 4.0) * sin(spin * 0.8 + seed)
			var stretch = 1.10 + ring_ratio * 1.45 + intensity * 0.14
			var crush = 0.40 + ring_index * 0.035
			var dest_size = Vector2(source_size * stretch, source_size * crush)
			var alpha = clamp(0.28 + intensity * 0.08 - ring_index * 0.025, 0.18, 0.58)
			draw_set_transform(sink, angle + PI * 0.5 + sin(t + seed) * 0.22, Vector2.ONE)
			draw_texture_rect_region(map_texture, Rect2(-dest_size * 0.5, dest_size), src, Color(1.0, 1.0, 1.0, alpha))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for shard_index in range(34):
		var shard_seed = float(shard_index) * 19.73
		var cycle = fposmod(t * (0.10 + intensity * 0.025) + shard_seed * 0.017, 1.0)
		var start_radius = radius * (0.96 - float(shard_index % 5) * 0.055)
		var end_radius = event_radius * (1.02 + float(shard_index % 3) * 0.16)
		var shard_radius = lerp(start_radius, end_radius, pow(cycle, 0.72))
		var angle = spin * (0.52 + float(shard_index % 4) * 0.055) + shard_seed + cycle * TAU * (0.18 + intensity * 0.04)
		var dir = Vector2.from_angle(angle)
		var tangent = dir.orthogonal()
		var pos = center + dir * shard_radius + tangent * sin(t * 3.1 + shard_seed) * 14.0
		var shard_alpha = sin(cycle * PI) * clamp(0.26 + intensity * 0.10, 0.22, 0.52)
		var shard_len = lerp(26.0, 8.0, cycle) + intensity * 3.0
		var shard_w = 5.0 + float(shard_index % 4) * 1.4
		var shard = PackedVector2Array([
			pos + dir * shard_len,
			pos + tangent * shard_w,
			pos - dir * shard_len * 0.62,
			pos - tangent * shard_w * 0.72
		])
		draw_polygon(shard, PackedColorArray([Color(0.70, 0.74, 0.68, shard_alpha), Color(0.42, 0.38, 0.46, shard_alpha * 0.92), Color(0.16, 0.12, 0.20, shard_alpha), Color(0.86, 0.82, 0.72, shard_alpha * 0.78)]))
		draw_polyline(PackedVector2Array([shard[0], shard[1], shard[2], shard[3], shard[0]]), Color(0.02, 0.01, 0.04, shard_alpha * 0.60), 1.0, true)

	for beam_index in range(22):
		var beam_seed = float(beam_index) * 41.0
		var angle = -spin * (0.34 + float(beam_index % 3) * 0.035) + beam_index * TAU / 22.0
		var outer = center + Vector2.from_angle(angle) * radius * (0.86 + 0.08 * sin(t * 1.4 + beam_seed))
		var mid = center + Vector2.from_angle(angle + 0.34 + intensity * 0.03) * radius * (0.45 + 0.04 * sin(beam_seed))
		var inner = center + Vector2.from_angle(angle + 0.68) * event_radius * (1.04 + 0.08 * sin(t * 4.0 + beam_seed))
		var beam_alpha = 0.08 + intensity * 0.035
		draw_polyline(PackedVector2Array([outer, mid, inner]), Color(0.92, 0.98, 1.0, beam_alpha), 2.0 + intensity * 0.32, true)
		draw_polyline(PackedVector2Array([outer, mid, inner]), Color(0.48, 0.18, 1.0, beam_alpha * 0.70), 5.0 + intensity * 0.7, true)

	for crack_index in range(18):
		var crack_angle = spin * 0.12 + crack_index * TAU / 18.0 + sin(t + crack_index) * 0.045
		var dir = Vector2.from_angle(crack_angle)
		var start = center + dir * (event_radius + 24.0)
		var finish = center + dir * radius * (0.58 + float(crack_index % 4) * 0.055)
		draw_line(start, finish, Color(0.0, 0.0, 0.02, 0.20 + intensity * 0.035), 2.4)
		draw_line(start.lerp(finish, 0.54), finish, Color(0.62, 0.82, 1.0, 0.08 + intensity * 0.025), 1.0)


func _draw_gravitante_map_mask(map_texture: Texture2D, map_rect: Rect2, tex_size: Vector2, center: Vector2, radius: float, event_radius: float, progress: float, intensity: float, spin: float) -> void:
	var outer_radius = radius * 0.82
	var inner_radius = max(28.0, event_radius * 0.48)
	var rings = 5
	var segments = 28
	for ring_index in range(rings):
		var ring_a = float(ring_index) / float(rings)
		var ring_b = float(ring_index + 1) / float(rings)
		var r0 = lerp(inner_radius, outer_radius, ring_a)
		var r1 = lerp(inner_radius, outer_radius, ring_b)
		for segment in range(segments):
			var a0 = float(segment) * TAU / float(segments)
			var a1 = float(segment + 1) * TAU / float(segments)
			var p0 = center + Vector2.from_angle(a0) * r0
			var p1 = center + Vector2.from_angle(a1) * r0
			var p2 = center + Vector2.from_angle(a1) * r1
			var p3 = center + Vector2.from_angle(a0) * r1
			var uv0 = _gravitante_distorted_map_uv(p0, center, map_rect, tex_size, radius, progress, intensity, spin)
			var uv1 = _gravitante_distorted_map_uv(p1, center, map_rect, tex_size, radius, progress, intensity, spin)
			var uv2 = _gravitante_distorted_map_uv(p2, center, map_rect, tex_size, radius, progress, intensity, spin)
			var uv3 = _gravitante_distorted_map_uv(p3, center, map_rect, tex_size, radius, progress, intensity, spin)
			var edge = clamp((r0 + r1) * 0.5 / max(1.0, outer_radius), 0.0, 1.0)
			var horizon = 1.0 - clamp((r0 - inner_radius) / max(1.0, outer_radius - inner_radius), 0.0, 1.0)
			var light = 0.82 - horizon * 0.48 + edge * 0.18
			var alpha = clamp(0.54 + intensity * 0.08 - horizon * 0.10, 0.36, 0.78)
			var color = Color(light * 0.80, light * 0.86, light, alpha)
			var colors = PackedColorArray([color, color, color, color])
			draw_polygon(PackedVector2Array([p0, p1, p2, p3]), colors, PackedVector2Array([uv0, uv1, uv2, uv3]), map_texture)

	draw_circle(center, outer_radius, Color(0.02, 0.00, 0.04, 0.15 + intensity * 0.04))
	for veil_index in range(6):
		var r = lerp(inner_radius * 1.15, outer_radius, float(veil_index) / 5.0)
		var alpha = 0.12 + intensity * 0.018 - veil_index * 0.010
		draw_arc(center, r, spin * (0.48 + veil_index * 0.05), spin * (0.48 + veil_index * 0.05) + TAU * 0.72, 80, Color(0.02, 0.00, 0.08, alpha), 9.0 - veil_index * 0.8)
		draw_arc(center, r * 0.98, -spin * (0.36 + veil_index * 0.04), -spin * (0.36 + veil_index * 0.04) + TAU * 0.46, 72, Color(0.72, 0.88, 1.0, 0.055 + intensity * 0.010), 2.0)


func _gravitante_distorted_map_uv(screen_point: Vector2, center: Vector2, map_rect: Rect2, tex_size: Vector2, radius: float, progress: float, intensity: float, spin: float) -> Vector2:
	var local = screen_point - center
	var dist_ratio = clamp(local.length() / max(1.0, radius * 0.82), 0.0, 1.0)
	var pull = pow(1.0 - dist_ratio, 1.45)
	var swirl = spin * (0.08 + intensity * 0.012) + pull * (2.9 + intensity * 0.45) + progress * 0.8
	var squeeze = 1.0 - pull * 0.48
	var stretch = 1.0 + pull * 0.90
	var warped = local.rotated(swirl)
	warped = Vector2(warped.x * stretch, warped.y * squeeze).rotated(-swirl * 0.42)
	var sink = center + warped + local.normalized() * pull * radius * 0.20
	return _map_screen_point_to_source_uv(map_rect, tex_size, sink)


func _map_screen_point_to_source_uv(map_rect: Rect2, tex_size: Vector2, screen_point: Vector2) -> Vector2:
	var rel = (screen_point - map_rect.position) / map_rect.size
	return Vector2(clamp(rel.x * tex_size.x, 0.0, tex_size.x), clamp(rel.y * tex_size.y, 0.0, tex_size.y))


func _map_screen_rect_to_source(map_rect: Rect2, tex_size: Vector2, screen_rect: Rect2) -> Rect2:
	var start = (screen_rect.position - map_rect.position) / map_rect.size
	var finish = (screen_rect.end - map_rect.position) / map_rect.size
	var x1 = clamp(start.x * tex_size.x, 0.0, tex_size.x)
	var y1 = clamp(start.y * tex_size.y, 0.0, tex_size.y)
	var x2 = clamp(finish.x * tex_size.x, 0.0, tex_size.x)
	var y2 = clamp(finish.y * tex_size.y, 0.0, tex_size.y)
	return Rect2(Vector2(x1, y1), Vector2(max(0.0, x2 - x1), max(0.0, y2 - y1)))


func _draw_gravitante_enemy_distortion(enemy: Dictionary, center_world: Vector2, camera: Vector2, radius: float, progress: float, intensity: float) -> void:
	var enemy_pos: Vector2 = enemy["pos"]
	var dist = enemy_pos.distance_to(center_world)
	var edge_ratio = _gravitante_edge_ratio(dist, radius)
	var dir = (enemy_pos - center_world).normalized()
	if dir.length() <= 0.01:
		dir = Vector2.RIGHT
	var tangent = dir.orthogonal()
	var tex = _enemy_texture(enemy)
	var size = _enemy_draw_size(enemy)
	var swirl = time_alive * (3.4 + intensity * 1.2) + float(enemy.get("uid", 0)) * 0.021
	var bend = tangent * sin(swirl) * (10.0 + edge_ratio * 22.0) - dir * (6.0 + (1.0 - edge_ratio) * 10.0)
	var ghost_pos = enemy_pos + bend
	var stretch = 1.0 + edge_ratio * 0.65 + intensity * 0.10
	var compress = 0.82 - edge_ratio * 0.18
	var ghost_size = Vector2(size.x * stretch, size.y * compress)
	var alpha = clamp(0.10 + edge_ratio * 0.22 + intensity * 0.04, 0.10, 0.42)
	_draw_enemy_texture_raw(tex, ghost_pos - camera, ghost_size, dir.angle() + PI * 0.5 + sin(swirl) * 0.18, Color(0.46, 0.72, 1.0, alpha), _enemy_should_flip(enemy))
	var smear_pos = enemy_pos + tangent * sin(swirl + 1.2) * (18.0 + edge_ratio * 18.0) - dir * 14.0
	_draw_enemy_texture_raw(tex, smear_pos - camera, Vector2(size.x * (0.82 + edge_ratio * 0.35), size.y * 0.64), dir.angle() + PI * 0.5, Color(0.96, 0.42, 1.0, alpha * 0.42), _enemy_should_flip(enemy))


func _enemy_draw_size(enemy: Dictionary) -> Vector2:
	match String(enemy.get("type", ENEMY_COMMON)):
		ENEMY_AGGLOMERATOR:
			return Vector2(86, 86)
		ENEMY_LARAPIO:
			return Vector2(78, 78)
		ENEMY_ATIRADOR:
			return Vector2(82, 82)
		ENEMY_KAMIKAZE:
			return Vector2(64, 64)
		ENEMY_DEVOTO:
			return Vector2(62, 62)
		ENEMY_GUARDIAO:
			return Vector2(98, 98)
	return Vector2(72, 72)


func _draw_enemy_texture_raw(texture: Texture2D, center: Vector2, size: Vector2, rotation: float, modulate: Color, flip_h := false) -> void:
	if texture == null:
		draw_circle(center, min(size.x, size.y) * 0.28, modulate)
		return
	draw_set_transform(center, rotation, Vector2(-1.0, 1.0) if flip_h else Vector2.ONE)
	draw_texture_rect(texture, Rect2(-size * 0.5, size), false, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_secondary_ancorada(secondary: Dictionary, camera: Vector2) -> void:
	var center_world: Vector2 = secondary.get("center", player_pos)
	var center = center_world - camera
	var radius = 220.0
	var charge = clamp(float(secondary.get("charge", 0.0)) / SECONDARY_ANCORADA_DURATION, 0.0, 1.0)
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.62, 0.94, 1.0, 0.82), 2.0)
	draw_arc(center, 54.0 + 42.0 * charge, 0.0, TAU, 32, Color(0.30, 0.88, 1.0, 0.94), 2.6)
	for i in range(12):
		var ang = time_alive * 0.7 + i * TAU / 12.0
		var p = center + Vector2.from_angle(ang) * radius
		draw_line(center, p, Color(0.72, 0.96, 1.0, 0.24), 1.0)
	if player_pos.distance_to(center_world) <= radius:
		draw_arc(player_pos - camera, 32.0, 0.0, TAU, 28, Color(1.0, 0.96, 0.72, 0.92), 2.0)


func _enemy_texture(enemy: Dictionary) -> Texture2D:
	var idx = int(enemy["phase"]) % 2
	if current_phase == 3:
		var moving_right = Vector2(enemy.get("facing_dir", Vector2.LEFT)).x >= 0.0
		var phase3_key = "enemy_phase_3_right" if moving_right else "enemy_phase_3_left"
		return textures[phase3_key][idx] if textures.has(phase3_key) and textures[phase3_key][idx] else textures["enemy_common_phase_1"][idx]
	match enemy["type"]:
		ENEMY_AGGLOMERATOR:
			return textures["agglomerator"][idx]
		ENEMY_STALKER:
			return textures["stalker"][idx]
		ENEMY_PROJECTOR:
			return textures["projector"][idx]
		ENEMY_CRYSTAL:
			return textures["crystal"][idx]
		ENEMY_CURATER:
			return textures["curater"][idx]
		ENEMY_LARAPIO:
			return textures["larapio"][idx]
	if current_phase == 2:
		var player_is_right = player_pos.x >= float(enemy["pos"].x)
		var phase2_key = "enemy_common_phase_2_right" if player_is_right else "enemy_common_phase_2_left"
		if textures.has(phase2_key) and textures[phase2_key][idx]:
			return textures[phase2_key][idx]
	var common_key = "enemy_common_phase_1"
	return textures[common_key][idx] if textures.has(common_key) and textures[common_key][idx] else textures["enemy_left"][idx]


func _enemy_default_facing(kind: String) -> Vector2:
	match kind:
		ENEMY_COMMON, ENEMY_CRYSTAL:
			return Vector2.LEFT
		ENEMY_STALKER, ENEMY_PROJECTOR, ENEMY_LARAPIO:
			return Vector2.RIGHT
	return Vector2.LEFT


func _enemy_should_flip(enemy: Dictionary) -> bool:
	if current_phase == 3:
		return false
	var dir: Vector2 = Vector2(enemy.get("facing_dir", _enemy_default_facing(String(enemy.get("type", ENEMY_COMMON)))))
	var moving_right = dir.x >= 0.0
	match String(enemy.get("type", ENEMY_COMMON)):
		ENEMY_COMMON:
			return moving_right
		ENEMY_STALKER:
			return not moving_right
		ENEMY_PROJECTOR:
			return not moving_right
		ENEMY_CRYSTAL:
			return moving_right
		ENEMY_LARAPIO:
			return not moving_right
	return false


func _enemy_type_count(kind: String) -> int:
	var count = 0
	for enemy in enemies:
		if String(enemy.get("type", "")) == kind:
			count += 1
	return count


func _enemy_visual_offset(enemy: Dictionary) -> Vector2:
	if String(enemy.get("type", "")) != ENEMY_LARAPIO:
		return Vector2.ZERO
	var move_dir: Vector2 = Vector2(enemy.get("last_move_dir", Vector2.ZERO))
	if move_dir.length() <= 0.05:
		return Vector2.ZERO
	var cycle = fmod(time_alive + float(enemy.get("phase", 0.0)) * 0.07, 1.0)
	var hop = 0.0
	var happy = float(enemy.get("happy_timer", 0.0)) > 0.0 or int(enemy.get("stolen", 0)) > 0
	var hop_window = 0.32 if happy else 0.22
	var hop_height = 24.0 if happy else 14.0
	if cycle < hop_window:
		hop = -sin(cycle / hop_window * PI) * hop_height
	return Vector2(0.0, hop)


func _boss_texture() -> Texture2D:
	if current_phase == 3:
		var idx3 = int(boss_phase) % 2
		var moving_to_cheese = boss3_consume_uid >= 0 and textures.has("boss_walk")
		return textures["boss_walk"][idx3] if moving_to_cheese else textures["boss3"][idx3]
	if current_phase == 2:
		var idx2 = int(boss_phase) % 2
		return textures["boss2"][idx2] if textures.has("boss2") and textures["boss2"][idx2] else textures["boss"]
	var pct = boss_hp / max(1.0, boss_hp_max)
	var idx = int(boss_phase) % 2
	if pct >= 0.60:
		return textures["boss_stage1"][idx] if textures["boss_stage1"][idx] else textures["boss"]
	if pct >= 0.40:
		return textures["boss_stage2"][idx] if textures["boss_stage2"][idx] else textures["boss"]
	return textures["boss_stage3"][idx] if textures["boss_stage3"][idx] else textures["boss"]


func _boss_draw_position() -> Vector2:
	if current_phase == 3:
		return boss_pos
	if boss_stage_timer <= 0.0:
		return boss_pos
	var elapsed = BOSS_STAGE_JUMP_TIME - boss_stage_timer
	var hop = 0.0
	if elapsed <= BOSS_STAGE_SLAM_TIME:
		var jump_progress = clamp(elapsed / BOSS_STAGE_SLAM_TIME, 0.0, 1.0)
		hop = sin(jump_progress * PI) * 188.0
	else:
		var rebound_time = elapsed - BOSS_STAGE_SLAM_TIME
		hop = abs(sin(rebound_time * PI * 2.2)) * 28.0 * exp(-rebound_time * 2.6)
	return boss_pos + Vector2(0, -hop)


func _draw_projectiles(camera: Vector2) -> void:
	if not boss1_rewind_sequence.is_empty():
		return
	for bullet in bullets:
		var kind = String(bullet.get("kind", ""))
		var palette = _projectile_palette(kind)
		var pos = bullet["pos"] - camera
		var dir: Vector2 = bullet["dir"]
		var side = dir.orthogonal().normalized()
		var age = float(bullet.get("age", 0.0))
		var phase = float(bullet.get("phase", 0.0))
		match kind:
			"prismatica":
				var start = pos - dir * 30.0
				var end = pos + dir * 8.0
				draw_line(start, end, Color(1.0, 1.0, 1.0, 0.95), 2.2)
				draw_line(start, end, Color(0.32, 1.0, 0.96, 0.42), 7.0)
				var diamond = PackedVector2Array([
					pos + dir * 10.0,
					pos + side * 7.0,
					pos - dir * 10.0,
					pos - side * 7.0
				])
				draw_polygon(diamond, PackedColorArray([Color(0.90, 1.0, 1.0, 0.96)]))
				draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color(1.0, 0.62, 0.86, 0.72), 1.5, true)
			"parasitica":
				var wobble = side * sin(age * 13.0 + phase) * 5.0
				var draw_pos = pos + wobble
				draw_circle(draw_pos, 9.0, palette["glow"])
				draw_circle(draw_pos, 5.2, palette["core"])
				for i in range(3):
					var ang = age * 7.0 + phase + i * TAU / 3.0
					draw_circle(draw_pos + Vector2.from_angle(ang) * 7.0, 2.2, Color(0.72, 1.0, 0.40, 0.82))
			"gravitante":
				draw_circle(pos, 10.0, palette["glow"])
				draw_circle(pos, 4.5, palette["core"])
				var orb_ang = age * 9.0 + phase
				draw_arc(pos, 14.0, orb_ang, orb_ang + PI * 1.35, 24, Color(0.82, 0.88, 1.0, 0.82), 2)
				draw_circle(pos + Vector2.from_angle(orb_ang) * 12.0, 2.8, Color(0.86, 0.92, 1.0, 0.90))
			"ancorada":
				var head = pos + dir * 10.0
				var tail = pos - dir * 18.0
				draw_line(tail, head, Color(0.30, 0.95, 1.0, 0.88), 4.5)
				draw_line(tail, head, Color(1.0, 1.0, 1.0, 0.68), 1.2)
				draw_arc(head, 6.0, dir.angle() - PI * 0.9, dir.angle() + PI * 0.9, 18, Color(1.0, 0.82, 0.22, 0.76), 2)
			"eletrica", "eletrica_charged":
				var charge_mult = 1.45 if kind == "eletrica_charged" else 1.0
				var a = pos - dir * (16.0 * charge_mult)
				var b = pos - dir * (6.0 * charge_mult) + side * sin(age * 28.0 + phase) * 5.0 * charge_mult
				var c = pos + dir * (7.0 * charge_mult)
				draw_polyline(PackedVector2Array([a, b, c]), Color(0.86, 0.28, 1.0, 0.54), 7.0 * charge_mult, true)
				draw_polyline(PackedVector2Array([a, b, c]), Color(0.74, 1.0, 1.0, 0.96), 3.0 * charge_mult, true)
				draw_circle(pos, 7.0 * charge_mult, palette["glow"])
				draw_circle(pos, 3.8 * charge_mult, Color.WHITE)
				if kind == "eletrica_charged":
					draw_arc(pos, 18.0, 0, TAU, 28, Color(1.0, 1.0, 1.0, 0.68), 2)
			"petro":
				var body = PackedVector2Array([
					pos + dir * 9.0,
					pos + side * 5.0,
					pos - dir * 9.0,
					pos - side * 5.0
				])
				draw_polygon(body, PackedColorArray([Color(0.24, 1.0, 1.0, 0.92)]))
				draw_polyline(PackedVector2Array([body[0], body[1], body[2], body[3], body[0]]), Color.WHITE, 1.2, true)
			_:
				var c: Color = bullet["color"]
				draw_circle(pos, 7, c)
				c.a = 0.22
				draw_circle(pos, 15, c)
	for bullet in return_bullets:
		var pos = bullet["pos"] - camera
		var dir = Vector2(bullet.get("dir", Vector2.RIGHT))
		var age = float(bullet.get("age", 0.0))
		var state = String(bullet.get("state", "volta" if bool(bullet.get("returning", false)) else "ida"))
		var c = _manifestation_color()
		if state == "instavel":
			c = Color(1.0, 0.28, 0.76)
		elif state == "volta":
			c = Color(1.0, 0.42, 0.92)
		var boosted = float(bullet.get("paradox_until", 0.0)) > time_alive or state == "instavel"
		var core_radius = 13.0 if boosted else 6.5
		var outer = 34.0 + sin(age * 16.0) * 6.0 if boosted else (17.0 + sin(age * 16.0) * 3.0 if state == "instavel" else 13.0 + sin(age * 16.0) * 2.0)
		draw_circle(pos, core_radius, c)
		draw_arc(pos, outer, age * 7.0, age * 7.0 + PI * 1.55, 28, Color(c.r, c.g, c.b, 0.88), 2.2)
		draw_line(pos - dir * 10.0, pos + dir * 10.0, Color(1.0, 1.0, 1.0, 0.68), 1.2)
		if state == "instavel":
			draw_arc(pos, outer + 8.0, age * 4.5, age * 4.5 + PI * 1.15, 22, Color(1.0, 0.76, 0.92, 0.56), 1.6)
	for bullet in enemy_bullets:
		if bullet.get("type") == "rat_flask" or bullet.get("type") == "rat_spit":
			var pos = Vector2(bullet["pos"]) - camera
			var tex: Texture2D = textures.get("boss3_flask")
			_draw_entity_fit(tex, pos, Vector2(34, 44), Color(0.72, 1.0, 0.30) if bullet.get("type") == "rat_spit" else Color.WHITE)
			draw_circle(pos, 23.0, Color(0.50, 0.88, 0.12, 0.16))
		elif bullet.get("type") == "rat_shot":
			var idx = int(float(bullet.get("phase", 0.0))) % 2
			var rat_tex: Texture2D = textures["enemy_phase_3_bullet"][idx]
			_draw_entity_fit(rat_tex, Vector2(bullet["pos"]) - camera, Vector2(34, 24), Color.WHITE)
		elif bullet.get("type") == "larapio_coin" or bullet.get("type") == "larapio_stone":
			var pos = Vector2(bullet["pos"]) - camera
			var phase = float(bullet.get("phase", 0.0))
			var is_coin = bullet.get("type") == "larapio_coin"
			var body = Color(1.0, 0.78, 0.14) if is_coin else Color(0.36, 0.34, 0.32)
			var rim = Color(0.52, 0.28, 0.04) if is_coin else Color(0.12, 0.11, 0.10)
			draw_circle(pos, 10.0, Color(body.r, body.g, body.b, 0.82))
			draw_arc(pos, 12.5, phase, phase + TAU * 0.92, 28, rim, 2.0)
			if is_coin:
				draw_line(pos + Vector2(cos(phase), sin(phase)) * -6.0, pos + Vector2(cos(phase), sin(phase)) * 6.0, Color(1.0, 1.0, 0.72, 0.75), 1.6)
			else:
				draw_line(pos + Vector2(-4, 2), pos + Vector2(5, -3), Color(0.18, 0.17, 0.16, 0.9), 1.4)
		elif bullet.get("type") == "atirador":
			var c = Color(0.65, 0.85, 1.0)
			draw_circle(bullet["pos"] - camera, 14, c)
			draw_circle(bullet["pos"] - camera, 24, Color(0.3, 0.7, 1.0, 0.3))
		elif bullet.get("type") == "boss_pressure_bubble":
			var pos = Vector2(bullet["pos"]) - camera
			var phase = float(bullet.get("phase", 0.0))
			var radius = float(bullet.get("radius", 18.0)) * (1.0 + sin(time_alive * 15.0 + phase) * 0.07)
			draw_circle(pos, radius + 8.0, Color(0.18, 0.76, 1.0, 0.18))
			draw_circle(pos, radius, Color(0.58, 0.92, 1.0, 0.28))
			draw_arc(pos, radius, phase + time_alive * 5.5, phase + time_alive * 5.5 + TAU * 0.76, 34, Color(0.92, 1.0, 1.0, 0.88), 2.8)
			draw_circle(pos + Vector2(-radius * 0.28, -radius * 0.34), radius * 0.22, Color.WHITE)
		elif bullet.get("type") == "frost_shard":
			var pos = bullet["pos"] - camera
			var dir: Vector2 = bullet["dir"]
			var side = dir.orthogonal().normalized()
			var shard = PackedVector2Array([
				pos + dir * 15.0,
				pos + side * 7.0,
				pos - dir * 10.0,
				pos - side * 7.0
			])
			draw_polygon(shard, PackedColorArray([Color(0.78, 0.94, 1.0, 0.96)]))
			draw_polyline(PackedVector2Array([shard[0], shard[1], shard[2], shard[3], shard[0]]), Color(0.15, 0.80, 1.0, 0.78), 1.5, true)
			draw_circle(pos, 18, Color(0.45, 0.84, 1.0, 0.22))
		else:
			var t = 0.5 + sin(float(bullet["phase"])) * 0.5
			var c = Color(0.45 + t * 0.28, 0.42, 0.50 + t * 0.50)
			draw_circle(bullet["pos"] - camera, 9, c)
			draw_circle(bullet["pos"] - camera, 16, Color(0.54, 0.16, 0.90, 0.22))
	for orbital in orbitals:
		var anchor = Vector2(orbital.get("origin_pos", player_pos))
		if String(orbital.get("target_kind", "enemy")) == "enemy":
			var enemy = _enemy_by_uid(int(orbital["enemy_uid"]))
			if enemy:
				anchor = Vector2(enemy["pos"])
		elif boss_active and boss_hp > 0.0:
			anchor = boss_pos
		var orbit_radius = 62.0 if String(orbital.get("target_kind", "enemy")) == "boss" else 42.0
		var p = anchor + Vector2.from_angle(float(orbital["angle"])) * orbit_radius
		draw_circle(p - camera, 8, Color(0.55, 0.82, 1.0))
		draw_arc(anchor - camera, orbit_radius, float(orbital["angle"]) - 0.7, float(orbital["angle"]) + 0.35, 18, Color(0.46, 0.78, 1.0, 0.42), 1.6)


func _draw_player(camera: Vector2) -> void:
	if not _active_lacerante_secondary().is_empty():
		return
	if attack_dragging:
		var p = player_pos - camera
		var color = _manifestation_color()
		color.a = 0.65
		draw_arc(p, 68.0, 0, TAU, 36, color, 2.5)
		var ball_p = p + attack_drag_direction * 68.0
		color.a = 1.0
		draw_circle(ball_p, 8.0, color)
		draw_circle(ball_p, 14.0, Color(color.r, color.g, color.b, 0.26))
	var tex = _player_texture()
	var center = player_pos - camera
	var profile = _player_draw_profile()
	var move = _read_move()
	var rotation = 0.0
	var flip_h = _should_flip_player_sprite()
	if move.y < -0.20 and abs(move.x) > 0.20:
		rotation = deg_to_rad(15.0) if move.x > 0.0 else deg_to_rad(-15.0)
	if gfx_shadows and tex != null:
		var s_rot = rotation + deg_to_rad(-10.0 if flip_h else 10.0)
		var s_scale = Vector2(-1.0 if flip_h else 1.0, -0.35)
		draw_set_transform(center + profile.get("offset", Vector2.ZERO) + Vector2(0, 38.0), s_rot, s_scale)
		var shadow_color = Color(0.0, 0.0, 0.0, 0.42)
		if bool(profile.get("preserve_height", false)):
			var tex_size = tex.get_size()
			if tex_size.y > 0.0:
				var target_height = float(profile.get("height", PLAYER_DRAW_LACERAR_HEIGHT))
				var draw_size = tex_size * (target_height / tex_size.y)
				var pos = Vector2(-draw_size.x * 0.5, PLAYER_DRAW_BOX_SIZE.y * 0.5 - draw_size.y)
				draw_texture_rect(tex, Rect2(pos, draw_size), false, shadow_color)
		else:
			var draw_size = profile["size"]
			var pos = Vector2(-draw_size.x * 0.5, PLAYER_DRAW_BOX_SIZE.y * 0.5 - draw_size.y)
			draw_texture_rect(tex, Rect2(pos, draw_size), false, shadow_color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if bool(profile.get("preserve_height", false)):
		_draw_entity_by_height_rotated(tex, center + profile["offset"], float(profile.get("height", PLAYER_DRAW_LACERAR_HEIGHT)), rotation, Color.WHITE, flip_h)
	else:
		_draw_entity_stretched_rotated(tex, center + profile["offset"], profile["size"], rotation, Color.WHITE, flip_h)


func _should_flip_player_sprite() -> bool:
	var move = _read_move()
	if lacerante_preparing and move.length() <= 0.12:
		return lacerante_prepare_dir.x < -0.1
	if time_alive - last_attack_time < 0.50:
		return _aim_direction().x < -0.1
	if move.x < -0.1:
		return true
	if move.x > 0.1:
		return false
	return last_facing.x < -0.1


func _player_is_moving_for_animation() -> bool:
	var move = _read_move()
	return move.length() > 0.12


func _player_draw_profile() -> Dictionary:
	var move = _read_move()
	if time_alive - last_damage_time < 0.35:
		return {
			"size": PLAYER_DRAW_DAMAGE_SIZE,
			"offset": Vector2.ZERO
		}
	if lacerante_preparing and move.length() <= 0.12:
		return {
			"preserve_height": true,
			"height": PLAYER_DRAW_LACERAR_HEIGHT,
			"offset": Vector2.ZERO
		}
	if time_alive - last_attack_time < 0.50:
		if manifestation_key == "lacerante":
			return {
				"preserve_height": true,
				"height": PLAYER_DRAW_LACERAR_HEIGHT,
				"offset": Vector2.ZERO
			}
		if not _player_is_moving_for_animation():
			return {
				"size": PLAYER_DRAW_SHOT_SIZE,
				"offset": Vector2.ZERO
			}
	if move.y < -0.1:
		return {
			"size": PLAYER_DRAW_UP_SIZE,
			"offset": Vector2.ZERO
		}
	if move.y > 0.1:
		return {
			"size": PLAYER_DRAW_DOWN_SIZE,
			"offset": Vector2.ZERO
		}
	if abs(move.x) > 0.1:
		return {
			"size": PLAYER_DRAW_SIDE_SIZE,
			"offset": Vector2.ZERO
		}
	return {
		"size": PLAYER_DRAW_STOP_SIZE,
		"offset": Vector2.ZERO
	}


func _draw_phase3_environment(camera: Vector2) -> void:
	if current_phase != 3:
		return
	for zone in phase3_miasma_zones:
		var fade = clamp(float(zone["life"]) / max(0.01, float(zone["max"])), 0.0, 1.0)
		var p = Vector2(zone["pos"]) - camera
		var radius = float(zone["radius"])
		draw_circle(p, radius, Color(0.22, 0.46, 0.06, 0.16 * fade))
		draw_arc(p, radius, 0, TAU, 48, Color(0.58, 0.92, 0.18, 0.52 * fade), 2.0)
		for i in range(5):
			var ang = time_alive * 0.7 + float(zone["phase"]) + i * TAU / 5.0
			draw_circle(p + Vector2.from_angle(ang) * radius * 0.55, 4.0, Color(0.72, 1.0, 0.28, 0.28 * fade))
	for cheese in phase3_cheeses:
		var p = Vector2(cheese["pos"]) - camera
		var pulse = 1.0 + sin(time_alive * 7.0 + int(cheese["uid"]) % 5) * 0.08
		var tex: Texture2D = textures.get("boss3_cheese")
		_draw_dynamic_shadow_fit(tex, p, Vector2(58, 48) * pulse, false, false, 0.38)
		_draw_entity_fit(tex, p, Vector2(58, 48) * pulse, Color.WHITE)
		var cheese_selected = (attack_lock_selecting and attack_lock_candidate_kind == "cheese" and attack_lock_candidate_uid == int(cheese["uid"])) or (locked_target_kind == "cheese" and locked_target_uid == int(cheese["uid"]))
		if cheese_selected:
			_draw_attack_target_marker(p + Vector2(0, 16), 30.0, locked_target_kind == "cheese")
		var c = Color(1.0, 0.88, 0.20) if bool(cheese["true"]) else Color(0.66, 1.0, 0.24)
		draw_arc(p, 35.0, 0, TAU, 32, Color(c.r, c.g, c.b, 0.76), 2.0)
		_draw_bar(p + Vector2(-27, -38), 54, float(cheese["hp"]) / float(cheese["max_hp"]), c)
		if bool(cheese.get("ritual", false)):
			_draw_centered("RITUAL", p + Vector2(0, -50), 13, Color(1.0, 0.42, 0.20))


func _draw_boss2_environment(camera: Vector2) -> void:
	if current_phase != 2:
		return
	for zone in boss2_snow_zones:
		var fade = clamp(float(zone.get("life", 0.0)) / max(0.01, float(zone.get("max", BOSS2_SLOW_ZONE_TIME))), 0.0, 1.0)
		var pos = Vector2(zone["pos"]) - camera
		var radius = float(zone["radius"]) * (0.78 + 0.22 * sin(time_alive * 4.0 + float(zone.get("phase", 0.0))))
		draw_circle(pos, radius, Color(0.62, 0.92, 1.0, 0.10 * fade))
		draw_arc(pos, radius, 0, TAU, 36, Color(0.80, 0.96, 1.0, 0.34 * fade), 2.0)
		for i in range(5):
			var ang = float(zone.get("phase", 0.0)) + time_alive * 0.8 + i * TAU / 5.0
			draw_circle(pos + Vector2.from_angle(ang) * radius * 0.52, 2.4, Color(1.0, 1.0, 1.0, 0.46 * fade))
	for shard in boss2_ice_shards:
		var fade = clamp(float(shard.get("life", 0.0)) / max(0.01, float(shard.get("max", 1.2))), 0.0, 1.0)
		var pos = Vector2(shard["pos"]) - camera
		var angle = float(shard.get("angle", 0.0))
		var size = float(shard.get("size", 8.0)) * (0.7 + fade * 0.5)
		var tip = Vector2.from_angle(angle) * size * 1.45
		var side = Vector2.from_angle(angle + PI * 0.5) * size * 0.62
		var points = PackedVector2Array([pos + tip, pos + side, pos - tip, pos - side])
		draw_polygon(points, PackedColorArray([Color(0.72, 0.94, 1.0, 0.78 * fade)]))
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(1.0, 1.0, 1.0, 0.62 * fade), 1.2, true)
	for particle in boss2_frost_particles:
		var fade = clamp(float(particle.get("life", 0.0)) / max(0.01, float(particle.get("max", 0.58))), 0.0, 1.0)
		var pos = Vector2(particle["pos"]) - camera
		var radius = float(particle.get("size", 12.0)) * fade
		draw_circle(pos, radius, Color(0.74, 0.92, 1.0, 0.18 * fade))
		draw_circle(pos, radius * 0.42, Color(1.0, 1.0, 1.0, 0.60 * fade))


func _draw_boss_entry(camera: Vector2) -> void:
	var target = WORLD_SIZE * 0.5 - camera
	if current_phase == 3:
		var progress3 = clamp(1.0 - boss_entry_timer / BOSS3_ENTRY_TIME, 0.0, 1.0)
		for i in range(3):
			var radius = 70.0 + i * 32.0 + progress3 * 120.0
			draw_arc(target, radius, 0, TAU, 64, Color(0.54, 0.92, 0.16, (1.0 - progress3) * (0.72 - i * 0.14)), 4.0)
		_draw_centered("PAI-RATO", target + Vector2(0, -142), 34, Color(0.82, 1.0, 0.42))
		return
	if current_phase == 2:
		var progress2 = clamp(1.0 - boss_entry_timer / BOSS2_ENTRY_TIME, 0.0, 1.0)
		var boss_draw = boss_pos - camera
		if progress2 < 0.8:
			var crystal_h = 220.0
			var crystal_w = 120.0
			var points = PackedVector2Array([
				boss_draw + Vector2(0, -crystal_h * 0.52),
				boss_draw + Vector2(crystal_w * 0.45, -crystal_h * 0.18),
				boss_draw + Vector2(crystal_w * 0.34, crystal_h * 0.34),
				boss_draw + Vector2(0, crystal_h * 0.52),
				boss_draw + Vector2(-crystal_w * 0.34, crystal_h * 0.34),
				boss_draw + Vector2(-crystal_w * 0.45, -crystal_h * 0.18)
			])
			draw_polygon(points, PackedColorArray([Color(0.46, 0.88, 1.0, 0.34)]))
			draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[4], points[5], points[0]]), Color(0.82, 0.96, 1.0, 0.92), 3.0, true)
			draw_line(points[0], points[3], Color(1.0, 1.0, 1.0, 0.58), 2.0)
		else:
			var impact = (progress2 - 0.8) / 0.2
			for i in range(3):
				draw_arc(target, 82.0 + impact * 520.0 + i * 32.0, 0, TAU, 96, Color(0.62, 0.92, 1.0, (1.0 - impact) * (0.70 - i * 0.16)), 4.0)
		if int(time_alive * 7.0) % 2 == 0:
			_draw_centered("A NEVASCA EMITE UM GRITO", target + Vector2(0, -142), 30, Color(0.72, 0.96, 1.0))
		return
	var progress = 1.0 - boss_entry_timer / BOSS_ENTRY_TIME
	var radius = 115.0 * (1.0 + 0.1 * sin(time_alive * 10.0))
	draw_circle(target, radius, Color(0.08, 0.0, 0.16, 0.44))
	draw_arc(target, radius * 0.82, 0, TAU, 64, Color(0.62, 0.0, 1.0, 0.88), 5)
	draw_arc(target, radius * 0.52, 0, TAU, 64, Color(0.0, 0.80, 1.0, 0.82), 3)
	for i in range(8):
		var a = time_alive * 4.0 + i * TAU / 8.0
		draw_line(target + Vector2.from_angle(a) * radius * 0.25, target + Vector2.from_angle(a) * radius * 0.92, Color(1.0, 0.35, 1.0, 0.72), 4)
	if progress >= 0.8:
		var impact = (progress - 0.8) / 0.2
		draw_arc(target, 90 + impact * 600.0, 0, TAU, 96, Color(1.0, 1.0, 1.0, 1.0 - impact), 6)
		draw_arc(target, 70 + impact * 520.0, 0, TAU, 96, Color(0.0, 0.75, 1.0, 0.7 * (1.0 - impact)), 4)
	_draw_centered("CARANGUEJO COSMICO GIGANTE", target + Vector2(0, -150), 34, Color.WHITE)


func _draw_boss1_time_wave(camera: Vector2) -> void:
	if boss1_time_wave.is_empty():
		return
	var center = Vector2(boss1_time_wave["origin"]) - camera
	var radius = float(boss1_time_wave["radius"])
	var returning = float(boss1_time_wave.get("direction", 1.0)) < 0.0
	var pulse = 0.5 + 0.5 * sin(float(boss1_time_wave.get("age", 0.0)) * 11.0)
	var variant = int(boss1_time_wave.get("variant", 0))
	var variant_color = _chrono_variant_color(variant)
	var primary = Color(1.0, 0.24, 0.66, 0.88) if returning else Color(variant_color.r, variant_color.g, variant_color.b, 0.88)
	var secondary = Color(0.54, 0.22, 1.0, 0.54) if returning else Color(0.20, 0.48, 1.0, 0.54)
	draw_arc(center, radius, 0.0, TAU, 128, Color(secondary.r, secondary.g, secondary.b, 0.16), BOSS1_TIME_WAVE_WIDTH + 18.0)
	draw_arc(center, radius, 0.0, TAU, 128, primary, BOSS1_TIME_WAVE_WIDTH + pulse * 4.0)
	draw_arc(center, radius, 0.0, TAU, 128, Color(0.90, 1.0, 1.0, 0.92), 2.0)
	match variant:
		1:
			draw_arc(center, max(24.0, radius - 44.0), PI * 0.15, PI * 1.15, 86, Color(1.0, 0.42, 0.86, 0.46), 5.0)
			draw_arc(center, radius + 44.0, PI * 1.15, PI * 2.15, 86, Color(1.0, 0.42, 0.86, 0.34), 4.0)
		2:
			for spiral in range(4):
				var a0 = float(boss1_time_wave.get("age", 0.0)) * 1.9 + spiral * TAU / 4.0
				draw_line(center + Vector2.from_angle(a0) * radius * 0.28, center + Vector2.from_angle(a0 + 0.75) * radius, Color(0.74, 0.52, 1.0, 0.38), 3.0)
		3:
			for shard in range(10):
				var a = shard * TAU / 10.0 + float(boss1_time_wave.get("age", 0.0)) * 0.42
				var p0 = center + Vector2.from_angle(a) * (radius - 18.0)
				var p1 = center + Vector2.from_angle(a + 0.08) * (radius + 26.0)
				draw_line(p0, p1, Color(1.0, 0.78, 0.30, 0.54), 3.0)
	for tick_index in range(24):
		var angle = tick_index * TAU / 24.0 + float(boss1_time_wave.get("age", 0.0)) * (-0.9 if returning else 0.9)
		var tick_length = 17.0 if tick_index % 3 == 0 else 9.0
		var inner = center + Vector2.from_angle(angle) * (radius - tick_length)
		var outer = center + Vector2.from_angle(angle) * (radius + tick_length * 0.35)
		draw_line(inner, outer, Color(primary.r, primary.g, primary.b, 0.82), 2.5 if tick_index % 3 == 0 else 1.4)
	draw_circle(center, 42.0 + pulse * 5.0, Color(0.04, 0.10, 0.18, 0.42))
	draw_arc(center, 44.0 + pulse * 5.0, 0.0, TAU, 40, primary, 3.0)
	var hand_angle = -PI * 0.5 + float(boss1_time_wave.get("age", 0.0)) * (-2.8 if returning else 2.8)
	draw_line(center, center + Vector2.from_angle(hand_angle) * 28.0, Color.WHITE, 3.0)
	draw_circle(center, 4.0, Color.WHITE)


func _draw_boss1_rewind_world(camera: Vector2) -> void:
	if boss1_rewind_sequence.is_empty() or boss1_rewind_history.is_empty():
		return
	var elapsed = float(boss1_rewind_sequence.get("elapsed", 0.0))
	var playback_start = BOSS1_CLOCK_TRAVEL_TIME
	var progress = clamp((elapsed - playback_start) / BOSS1_REWIND_PLAYBACK_TIME, 0.0, 1.0) if elapsed >= playback_start else 0.0
	var cursor = int(round(lerp(float(boss1_rewind_history.size() - 1), 0.0, progress)))
	var variant = int(boss1_rewind_sequence.get("variant", 0))
	var variant_color = _chrono_variant_color(variant)
	var player_path = PackedVector2Array()
	var boss_path = PackedVector2Array()
	var step = max(1, int(ceil(float(cursor + 1) / 70.0)))
	for history_index in range(0, cursor + 1, step):
		var snapshot: Dictionary = boss1_rewind_history[history_index]
		player_path.append(Vector2(snapshot["player_pos"]) - camera)
		boss_path.append(Vector2(snapshot["boss_pos"]) - camera)
	if player_path.size() >= 2:
		draw_polyline(player_path, Color(0.26, 0.94, 1.0, 0.46), 4.0, true)
	if boss_path.size() >= 2:
		draw_polyline(boss_path, Color(variant_color.r, variant_color.g, variant_color.b, 0.40), 5.0, true)
	for marker_index in range(0, player_path.size(), max(1, int(player_path.size() / 8.0))):
		draw_circle(player_path[marker_index], 4.0, Color(0.82, 1.0, 1.0, 0.72))
	for echo_offset in [5, 12, 22, 34]:
		var echo_index = min(boss1_rewind_history.size() - 1, cursor + echo_offset)
		if echo_index == cursor:
			continue
		var echo: Dictionary = boss1_rewind_history[echo_index]
		var alpha = max(0.06, 0.26 - float(echo_offset) * 0.0045)
		_draw_entity_fit(_player_texture(), Vector2(echo["player_pos"]) - camera, Vector2(74, 88), Color(0.42, 0.92, 1.0, alpha), _should_flip_player_sprite())
		_draw_entity_fit(_boss_texture(), Vector2(echo["boss_pos"]) - camera, Vector2(184, 170), Color(variant_color.r, variant_color.g, variant_color.b, alpha * 0.86), true)
	for visual in boss1_rewind_visual_projectiles:
		var pos = Vector2(visual.get("pos", player_pos)) - camera
		var visual_kind = String(visual.get("visual", "player"))
		match visual_kind:
			"player":
				var palette = _projectile_palette(String(visual.get("kind", "eletrica")))
				var direction = Vector2(visual.get("dir", Vector2.RIGHT)).normalized()
				draw_line(pos - direction * 18.0, pos + direction * 5.0, Color(palette["glow"].r, palette["glow"].g, palette["glow"].b, 0.82), 5.0)
				draw_circle(pos, 4.5, Color.WHITE)
			"returning":
				draw_circle(pos, 10.0, Color(0.84, 0.32, 1.0, 0.42))
				draw_arc(pos, 12.0, 0.0, TAU, 18, Color(1.0, 0.54, 0.96, 0.92), 2.4)
			"enemy":
				draw_circle(pos, 7.0, Color(1.0, 0.24, 0.52, 0.72))
				draw_arc(pos, 10.0, 0.0, TAU, 16, Color(0.64, 0.28, 1.0, 0.70), 2.0)
			"shockwave", "boss_wave":
				draw_arc(pos, float(visual.get("radius", 0.0)), 0.0, TAU, 64, Color(0.34, 0.92, 1.0, 0.56), 3.0)
			"prism":
				var diamond = PackedVector2Array([pos + Vector2(0, -16), pos + Vector2(16, 0), pos + Vector2(0, 16), pos + Vector2(-16, 0), pos + Vector2(0, -16)])
				draw_polyline(diamond, Color(0.42, 1.0, 0.94, 0.86), 3.0)


func _draw_boss1_rewind_overlay(viewport: Vector2, camera: Vector2) -> void:
	if boss1_rewind_sequence.is_empty():
		return
	var elapsed = float(boss1_rewind_sequence.get("elapsed", 0.0))
	var center_target = viewport * 0.5
	var travel_progress = clamp(elapsed / BOSS1_CLOCK_TRAVEL_TIME, 0.0, 1.0)
	var smooth_travel = smoothstep(0.0, 1.0, travel_progress)
	var clock_origin = boss_pos - camera + Vector2(0, -36)
	var clock_center = clock_origin.lerp(center_target, smooth_travel)
	var clock_scale = lerp(0.34, 1.0, smooth_travel)
	var turn_progress = clamp((elapsed - BOSS1_CLOCK_TRAVEL_TIME) / BOSS1_CLOCK_TURN_TIME, 0.0, 1.0)
	var variant = int(boss1_rewind_sequence.get("variant", 0))
	var variant_color = _chrono_variant_color(variant)
	var overlay_alpha = 0.06 + 0.09 * smooth_travel
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.01, 0.04, 0.10, overlay_alpha), true)
	for scan_index in range(7):
		var scan_y = fposmod(elapsed * -180.0 + scan_index * viewport.y / 7.0, viewport.y)
		draw_line(Vector2(0, scan_y), Vector2(viewport.x, scan_y), Color(0.22, 0.86, 1.0, 0.06), 2.0)
	var radius = 106.0 * clock_scale
	for glow_index in range(4):
		draw_circle(clock_center, radius + 18.0 - glow_index * 5.0, Color(variant_color.r, variant_color.g, variant_color.b, 0.018 + glow_index * 0.010))
	draw_circle(clock_center, radius, Color(0.015, 0.035, 0.075, 0.42))
	draw_arc(clock_center, radius, 0.0, TAU, 80, Color(variant_color.r, variant_color.g, variant_color.b, 0.78), 5.0 * clock_scale)
	draw_arc(clock_center, radius * 0.88, 0.0, TAU, 80, Color(1.0, 0.42, 0.78, 0.52), 2.0 * clock_scale)
	match variant:
		1:
			draw_arc(clock_center + Vector2(-radius * 0.16, 0), radius * 0.72, PI * 0.2, PI * 1.2, 54, Color(1.0, 0.48, 0.82, 0.34), 3.0)
			draw_arc(clock_center + Vector2(radius * 0.16, 0), radius * 0.72, PI * 1.2, PI * 2.2, 54, Color(0.42, 0.92, 1.0, 0.34), 3.0)
		2:
			for spiral in range(3):
				var spiral_angle = -turn_progress * TAU * 2.0 + spiral * TAU / 3.0
				draw_arc(clock_center, radius * (0.35 + spiral * 0.16), spiral_angle, spiral_angle + PI * 1.25, 42, Color(0.72, 0.52, 1.0, 0.30), 2.0)
		3:
			for fracture in range(8):
				var fracture_angle = fracture * TAU / 8.0 + turn_progress * 0.4
				draw_line(clock_center + Vector2.from_angle(fracture_angle) * radius * 0.30, clock_center + Vector2.from_angle(fracture_angle + 0.08) * radius * 0.78, Color(1.0, 0.78, 0.30, 0.34), 2.0)
	for tick_index in range(60):
		var angle = -PI * 0.5 + tick_index * TAU / 60.0
		var major = tick_index % 5 == 0
		var outer = clock_center + Vector2.from_angle(angle) * radius * 0.82
		var inner = clock_center + Vector2.from_angle(angle) * radius * (0.68 if major else 0.75)
		draw_line(inner, outer, Color(0.82, 0.98, 1.0, 0.92 if major else 0.54), (3.2 if major else 1.4) * clock_scale)
	var shown_minutes = lerp(10.0, 0.0, turn_progress)
	var minute_angle = -PI * 0.5 + shown_minutes * TAU / 60.0
	var hour_angle = -PI * 0.5 + (11.0 + shown_minutes / 60.0) * TAU / 12.0
	if turn_progress > 0.0 and turn_progress < 1.0:
		for trail_index in range(1, 5):
			var trail_minutes = min(10.0, shown_minutes + trail_index * 0.65)
			var trail_angle = -PI * 0.5 + trail_minutes * TAU / 60.0
			draw_line(clock_center, clock_center + Vector2.from_angle(trail_angle) * radius * 0.62, Color(0.32, 0.88, 1.0, 0.13), 3.0 * clock_scale)
	draw_line(clock_center, clock_center + Vector2.from_angle(hour_angle) * radius * 0.44, Color(1.0, 0.42, 0.76), 7.0 * clock_scale)
	draw_line(clock_center, clock_center + Vector2.from_angle(minute_angle) * radius * 0.64, Color(0.82, 0.98, 1.0), 5.0 * clock_scale)
	draw_circle(clock_center, 8.0 * clock_scale, Color.WHITE)
	var minute_label = int(round(shown_minutes))
	_draw_centered("11:%02d PM" % minute_label, clock_center + Vector2(0, radius * 0.46), int(18 * clock_scale), Color(0.82, 0.98, 1.0))
	if elapsed < BOSS1_CLOCK_TRAVEL_TIME:
		_draw_centered("CRONO-RUPTURA", clock_center + Vector2(0, radius + 34.0), 20, Color(0.42, 0.92, 1.0))
	elif turn_progress < 1.0:
		_draw_centered("TEMPO -%.1fs" % (turn_progress * BOSS1_REWIND_SECONDS), clock_center + Vector2(0, radius + 40.0), 22, Color(1.0, 0.42, 0.76))
	else:
		_draw_centered("LINHA RESTAURADA", clock_center + Vector2(0, radius + 40.0), 22, Color(0.48, 0.94, 1.0))


func _draw_boss_wave_safe_sector(center: Vector2, angle: float, size: float, radius: float, alpha: float) -> void:
	var points = PackedVector2Array([center])
	var segments = 14
	for segment in range(segments + 1):
		var sector_angle = angle - size * 0.5 + size * float(segment) / float(segments)
		points.append(center + Vector2.from_angle(sector_angle) * radius)
	draw_polygon(points, PackedColorArray([Color(0.10, 0.88, 0.62, alpha)]))
	var left = center + Vector2.from_angle(angle - size * 0.5) * radius
	var right = center + Vector2.from_angle(angle + size * 0.5) * radius
	draw_line(center, left, Color(0.32, 1.0, 0.84, min(0.72, alpha * 2.4)), 2.0)
	draw_line(center, right, Color(0.32, 1.0, 0.84, min(0.72, alpha * 2.4)), 2.0)


func _draw_boss_attacks(camera: Vector2) -> void:
	_draw_boss1_time_wave(camera)
	for wave in boss_transition_waves:
		var center = Vector2(wave["pos"]) - camera
		if String(wave.get("kind", "")) == "dupla_abertura":
			var age = float(wave.get("age", 0.0))
			var warning = float(wave.get("warning", BOSS_STAGE_WAVE_WARNING))
			var opening = float(wave["open_angle"])
			var opening_size = float(wave["open_size"])
			var warning_progress = clamp(age / max(0.01, warning), 0.0, 1.0)
			var sector_alpha = (0.18 + warning_progress * 0.12) if age < warning else 0.08
			_draw_boss_wave_safe_sector(center, opening, opening_size, 780.0, sector_alpha)
			_draw_boss_wave_safe_sector(center, opening + PI, opening_size, 780.0, sector_alpha)
			if age < warning:
				draw_circle(center, 44.0 + warning_progress * 28.0, Color(0.78, 0.08, 1.0, 0.10 + warning_progress * 0.12))
				draw_arc(center, 48.0 + warning_progress * 30.0, 0.0, TAU, 52, Color(1.0, 0.34, 0.78, 0.72), 3.0)
				continue
			var radius = float(wave["radius"])
			var half_gap = opening_size * 0.5
			var dangerous_arcs = [
				Vector2(opening + half_gap, opening + PI - half_gap),
				Vector2(opening + PI + half_gap, opening + TAU - half_gap)
			]
			for arc_range in dangerous_arcs:
				draw_arc(center, radius, arc_range.x, arc_range.y, 58, Color(0.52, 0.0, 0.72, 0.76), float(wave["width"]) + 6.0)
				draw_arc(center, radius, arc_range.x, arc_range.y, 58, Color(1.0, 0.22, 0.54, 0.88), float(wave["width"]) + 1.0)
				draw_arc(center, radius, arc_range.x, arc_range.y, 58, Color(1.0, 0.88, 1.0, 0.82), 2.0)
			for gap_angle in [opening, opening + PI]:
				var gate = center + Vector2.from_angle(gap_angle) * radius
				draw_arc(gate, 13.0, 0.0, TAU, 20, Color(0.32, 1.0, 0.86, 0.78), 2.0)
			continue
		var c1 = Color(0.58, 0.0, 1.0, 0.75)
		var c2 = Color(0.0, 1.0, 1.0, 0.72)
		var start = float(wave.get("open_angle", 0.0)) + float(wave.get("open_size", 0.0)) * 0.5
		var end = start + TAU - float(wave.get("open_size", 0.0))
		draw_arc(center, float(wave["radius"]), start, end, 96, c1, float(wave["width"]) + 4)
		draw_arc(center, float(wave["radius"]), start, end, 96, c2, max(2.0, float(wave["width"]) - 4))
	for attack in boss_attacks:
		var age = float(attack.get("age", 0.0))
		if age < 0.0:
			continue
		var kind = String(attack["kind"])
		match kind:
			"rat_rain":
				var safe = int(attack.get("safe", 0))
				for lane in range(4):
					var y = WORLD_SIZE.y * (0.18 + lane * 0.215) - camera.y
					var c = Color(0.48, 1.0, 0.20, 0.12) if lane == safe else Color(1.0, 0.30, 0.12, 0.22)
					draw_rect(Rect2(-camera.x, y - 34.0, WORLD_SIZE.x, 68.0), c, true)
					draw_line(Vector2(-camera.x, y), Vector2(WORLD_SIZE.x - camera.x, y), Color(c.r, c.g, c.b, 0.86), 2.0)
			"rat_spit":
				var dir = Vector2(attack.get("dir", Vector2.RIGHT))
				draw_line(boss_pos - camera, boss_pos - camera + dir * 620.0, Color(0.64, 1.0, 0.18, 0.72), 4.0)
			"rat_tail":
				var pulse = clamp(age / 0.52, 0.0, 1.0)
				draw_circle(boss_pos - camera, 155.0, Color(1.0, 0.48, 0.12, 0.08 + pulse * 0.08))
				draw_arc(boss_pos - camera, 155.0, 0, TAU, 64, Color(1.0, 0.72, 0.22, 0.78), 4.0)
			"rat_charge":
				if age < float(attack.get("warn", 0.7)):
					var dir = Vector2(attack.get("dir", Vector2.RIGHT))
					draw_line(boss_pos - camera, boss_pos - camera + dir * 650.0, Color(1.0, 0.22, 0.10, 0.78), 12.0)
					draw_line(boss_pos - camera, boss_pos - camera + dir * 650.0, Color(1.0, 0.86, 0.28, 0.84), 3.0)
			"bubble":
				var progress = clamp(age / float(attack["duration"]), 0.0, 1.0)
				var r = 15.0
				var color = Color(0.0, 1.0, 0.80, 0.45)
				if progress < 0.25:
					r = 15.0 + sin(time_alive * 20.0) * 3.0
				elif progress < 0.50:
					r = 50.0 + sin(time_alive * 10.0) * 5.0
				elif progress < 0.75:
					r = 65.0 + sin(time_alive * 50.0) * 8.0
					color = Color(1.0, 0.0, 0.5, 0.48)
				else:
					r = 90.0 + (progress - 0.75) * 180.0
					color = Color(0.65, 0.15, 1.0, 0.35)
				var p = attack["target"] - camera
				draw_circle(p, r, Color(color.r, color.g, color.b, 0.12))
				draw_arc(p, r, 0, TAU, 64, color, 4)
				draw_line(boss_pos - camera, p, Color(0.0, 1.0, 0.8, 0.22), 2)
			"rain":
				var p = attack["target"] - camera
				var local = age
				if local < 2.2:
					var shadow_r = clamp(local / 2.2, 0.0, 1.0) * 35.0
					draw_circle(p, shadow_r, Color(0.0, 0.45, 1.0, 0.18))
					draw_arc(p, shadow_r, 0, TAU, 32, Color(0.0, 0.75, 1.0, 0.72), 2)
				else:
					draw_line(p + Vector2(0, -180 + (local - 2.2) * 360.0), p, Color(0.0, 0.78, 1.0, 0.88), 8)
					draw_circle(p, 28.0 + sin(time_alive * 16.0) * 4.0, Color(0.0, 0.55, 1.0, 0.22))
			"boiling_bubbles":
				for drop in attack.get("drops", []):
					var drop_age = float(drop.get("age", 0.0))
					var launch = Vector2(drop.get("launch", boss_pos))
					var apex = Vector2(drop.get("apex", Vector2(launch.x, -120.0)))
					var target = Vector2(drop.get("target", player_pos))
					var phase = float(drop.get("phase", 0.0))
					var pos_world = launch
					var warning = clamp(drop_age / 1.36, 0.0, 1.0)
					var target_screen = target - camera
					var warn_r = 22.0 + warning * 42.0
					draw_circle(target_screen, warn_r, Color(0.12, 0.62, 1.0, 0.08 + warning * 0.10))
					draw_arc(target_screen, warn_r, 0.0, TAU, 42, Color(0.35, 0.92, 1.0, 0.58 + warning * 0.25), 2.2)
					if drop_age < 0.48:
						var up = smoothstep(0.0, 1.0, drop_age / 0.48)
						pos_world = launch.lerp(apex, up)
						draw_line(launch - camera, pos_world - camera, Color(0.28, 0.88, 1.0, 0.38), 5.0)
					elif drop_age < 1.18:
						pos_world = apex
						var glint = apex - camera + Vector2(sin(time_alive * 7.0 + phase) * 10.0, 0)
						draw_circle(glint, 13.0, Color(0.58, 1.0, 1.0, 0.58))
					else:
						var fall = clamp((drop_age - 1.18) / 0.45, 0.0, 1.0)
						pos_world = apex.lerp(target, fall)
						draw_line(pos_world - camera + Vector2(0, -42), target_screen, Color(0.30, 0.86, 1.0, 0.70), 7.0)
					var bubble_pos = pos_world - camera
					var wobble = 1.0 + sin(time_alive * 13.0 + phase) * 0.08
					draw_circle(bubble_pos, 18.0 * wobble, Color(0.72, 1.0, 1.0, 0.34))
					draw_arc(bubble_pos, 18.0 * wobble, phase, phase + TAU * 0.82, 32, Color(0.92, 1.0, 1.0, 0.86), 2.4)
					draw_circle(bubble_pos + Vector2(-5, -6), 4.0, Color.WHITE)
					if drop_age >= 1.58:
						var splash = clamp((drop_age - 1.58) / 0.42, 0.0, 1.0)
						draw_circle(target_screen, 28.0 + splash * 42.0, Color(0.18, 0.78, 1.0, 0.22 * (1.0 - splash)))
						for i in range(8):
							var a = phase + i * TAU / 8.0
							draw_line(target_screen, target_screen + Vector2.from_angle(a) * (22.0 + splash * 46.0), Color(0.70, 1.0, 1.0, 0.44 * (1.0 - splash)), 1.8)
			"pressure_bubbles":
				var dir = Vector2(attack.get("dir", Vector2.LEFT)).normalized()
				var origin = boss_pos - camera
				var pulse = 0.5 + sin(time_alive * 12.0) * 0.5
				for i in range(4):
					var p = origin + dir * (42.0 + i * 34.0)
					draw_circle(p, 10.0 + i * 3.0, Color(0.22, 0.84, 1.0, 0.08 + pulse * 0.06))
					draw_arc(p, 12.0 + i * 3.0, time_alive * 5.0, time_alive * 5.0 + PI * 1.2, 22, Color(0.88, 1.0, 1.0, 0.30 + pulse * 0.22), 1.7)
			"tide":
				var line_pos = _boss_tide_line(attack)
				if bool(attack["horizontal"]):
					draw_rect(Rect2(-camera.x, line_pos - camera.y - 32, WORLD_SIZE.x, 64), Color(0.0, 0.75, 1.0, 0.22), true)
					draw_line(Vector2(-camera.x, line_pos - camera.y), Vector2(WORLD_SIZE.x - camera.x, line_pos - camera.y), Color(0.78, 0.94, 1.0, 0.8), 5)
				else:
					draw_rect(Rect2(line_pos - camera.x - 32, -camera.y, 64, WORLD_SIZE.y), Color(0.0, 0.75, 1.0, 0.22), true)
					draw_line(Vector2(line_pos - camera.x, -camera.y), Vector2(line_pos - camera.x, WORLD_SIZE.y - camera.y), Color(0.78, 0.94, 1.0, 0.8), 5)
			"sand":
				var p = attack["target"] - camera
				var r = 48.0 + sin(time_alive * 8.0) * 8.0
				draw_arc(p, r, 0, TAU, 48, Color(0.78, 0.64, 0.42, 0.72), 5)
				for i in range(8):
					draw_circle(p + Vector2.from_angle(time_alive * 5.0 + i) * (r * 0.65), 3, Color(0.90, 0.82, 0.62, 0.75))
			"pincer":
				var p = attack["target"] - camera
				var alpha = 0.32 if age < 1.55 else 0.76
				draw_line(Vector2(p.x, -camera.y), Vector2(p.x, WORLD_SIZE.y - camera.y), Color(1.0, 0.15, 0.55, alpha), 8)
				draw_line(Vector2(-camera.x, p.y), Vector2(WORLD_SIZE.x - camera.x, p.y), Color(1.0, 0.15, 0.55, alpha), 8)
			"rush":
				var dir = Vector2(attack.get("dir", Vector2.LEFT)).normalized()
				var state = String(attack.get("state", "telegraph"))
				var origin = boss_pos - camera
				if state == "telegraph":
					var flash = 0.45 + 0.55 * sin(time_alive * 16.0)
					var arrow_center = origin + dir * 118.0
					var side = dir.orthogonal()
					var tip = arrow_center + dir * 42.0
					var left = arrow_center - dir * 24.0 + side * 30.0
					var right = arrow_center - dir * 24.0 - side * 30.0
					draw_polygon(PackedVector2Array([tip, left, right]), PackedColorArray([Color(1.0, 0.04, 0.02, 0.38 + flash * 0.32)]))
					draw_polyline(PackedVector2Array([left, tip, right]), Color(1.0, 0.88, 0.78, 0.72 + flash * 0.20), 4.0, false)
					draw_line(origin + dir * 38.0, origin + dir * 210.0, Color(1.0, 0.06, 0.02, 0.18 + flash * 0.20), 10.0)
				elif state == "dash":
					draw_line(origin - dir * 90.0, origin + dir * 54.0, Color(1.0, 0.25, 0.08, 0.56), 13.0)
					draw_line(origin - dir * 76.0, origin + dir * 42.0, Color(1.0, 0.92, 0.62, 0.84), 3.0)
				elif state == "grab":
					draw_arc(origin, 82.0, 0.0, TAU, 54, Color(1.0, 0.30, 0.10, 0.78), 4.0)
				elif state == "throw":
					draw_line(player_pos - camera - dir * 90.0, player_pos - camera + dir * 20.0, Color(1.0, 0.66, 0.16, 0.62), 8.0)
			"blizzard":
				var warn = float(attack["warn"])
				if age < warn:
					var progress = age / warn
					var c = Color(0.0, 0.75, 1.0, 0.18 + 0.26 * progress)
					for wave in attack["waves"]:
						var width = float(wave.get("width", BOSS2_WAVE_WIDTH))
						var dir_name = String(wave.get("direction", "left"))
						if dir_name == "left" or dir_name == "right":
							var x_pos = float(wave.get("x", 0.0)) - camera.x
							draw_rect(Rect2(x_pos - width * 0.5, -camera.y, width, WORLD_SIZE.y), c, true)
							draw_line(Vector2(x_pos, -camera.y), Vector2(x_pos, WORLD_SIZE.y - camera.y), Color(0.90, 1.0, 1.0, 0.70 * progress), 2.0)
						else:
							var y_pos = float(wave.get("y", 0.0)) - camera.y
							draw_rect(Rect2(-camera.x, y_pos - width * 0.5, WORLD_SIZE.x, width), c, true)
							draw_line(Vector2(-camera.x, y_pos), Vector2(WORLD_SIZE.x - camera.x, y_pos), Color(0.90, 1.0, 1.0, 0.70 * progress), 2.0)
					var label = "ALERTA: NEVASCA VERTICAL" if bool(attack.get("vertical", false)) else "ALERTA: NEVASCA HORIZONTAL"
					_draw_centered(label, Vector2(get_viewport_rect().size.x * 0.5, 86), 20, Color(0.62, 0.94, 1.0, 0.88))
				else:
					for wave in attack["waves"]:
						var width = float(wave.get("width", BOSS2_WAVE_WIDTH))
						var dir_name = String(wave.get("direction", "left"))
						if dir_name == "left" or dir_name == "right":
							var x_pos = float(wave.get("x", 0.0)) - camera.x
							draw_rect(Rect2(x_pos - width * 0.5, -camera.y, width, WORLD_SIZE.y), Color(0.58, 0.88, 1.0, 0.42), true)
							draw_line(Vector2(x_pos, -camera.y), Vector2(x_pos, WORLD_SIZE.y - camera.y), Color(1.0, 1.0, 1.0, 0.92), 3.0)
							for j in range(13):
								var drift = sin(time_alive * 5.0 + j) * 16.0
								var y = -camera.y + fposmod(j * 78.0 + time_alive * 240.0, WORLD_SIZE.y + 120.0) - 60.0
								draw_line(Vector2(x_pos + drift, y), Vector2(x_pos + drift - 14.0, y + 34.0), Color.WHITE, 2.4)
						else:
							var y_pos = float(wave.get("y", 0.0)) - camera.y
							draw_rect(Rect2(-camera.x, y_pos - width * 0.5, WORLD_SIZE.x, width), Color(0.58, 0.88, 1.0, 0.42), true)
							draw_line(Vector2(-camera.x, y_pos), Vector2(WORLD_SIZE.x - camera.x, y_pos), Color(1.0, 1.0, 1.0, 0.92), 3.0)
							for j in range(16):
								var x = -camera.x + fposmod(j * 95.0 + time_alive * 250.0, WORLD_SIZE.x + 160.0) - 80.0
								draw_line(Vector2(x, y_pos - 16.0), Vector2(x + 28.0, y_pos + 13.0), Color.WHITE, 2.3)
			"frost_breath":
				var warn = float(attack["warn"])
				var dir: Vector2 = attack["dir"]
				var start = boss_pos - camera
				var length = 1500.0
				if age < warn:
					var progress = age / warn
					draw_line(start, start + dir * length, Color(0.0, 0.8, 1.0, 0.3 * progress), 60)
				else:
					draw_line(start, start + dir * length, Color(0.6, 0.9, 1.0, 0.85), 60 + sin(time_alive * 15.0) * 10)
					draw_line(start, start + dir * length, Color(1.0, 1.0, 1.0, 1.0), 20)
			"avalanche":
				var warn = float(attack["warn"])
				for pos in attack["targets"]:
					var p = pos - camera
					if age < warn:
						var r = 40.0 * (age / warn)
						draw_circle(p, 40.0, Color(0.2, 0.6, 1.0, 0.2))
						draw_arc(p, r, 0, TAU, 32, Color(0.2, 0.8, 1.0, 0.8), 2)
					else:
						var drop = clamp((age - warn) * 2.0, 0.0, 1.0)
						if drop < 1.0:
							var h = (1.0 - drop) * 500.0
							draw_circle(p + Vector2(0, -h), 35.0, Color(0.8, 0.9, 1.0))
						else:
							draw_circle(p, 45.0, Color(0.6, 0.9, 1.0, 0.6))
			"shield":
				var shield_angle = float(attack.get("angle", 0.0))
				var center = boss_pos - camera
				for radius_opacity in [[78.0, 0.24], [92.0, 0.14]]:
					draw_circle(center, radius_opacity[0], Color(0.60, 0.90, 1.0, radius_opacity[1]))
					draw_arc(center, radius_opacity[0], 0, TAU, 56, Color(0.88, 0.98, 1.0, radius_opacity[1] + 0.28), 2.2)
				for i in range(3):
					var angle = shield_angle + i * TAU / 3.0
					var p = center + Vector2.from_angle(angle) * 92.0
					var tip = Vector2.from_angle(angle) * 14.0
					var side = Vector2.from_angle(angle + PI * 0.5) * 9.0
					var crystal = PackedVector2Array([p + tip, p + side, p - tip, p - side])
					draw_polygon(crystal, PackedColorArray([Color(0.0, 0.76, 1.0, 0.95)]))
					draw_polyline(PackedVector2Array([crystal[0], crystal[1], crystal[2], crystal[3], crystal[0]]), Color.WHITE, 1.4, true)


func _draw_effects(camera: Vector2) -> void:
	for effect in effects:
		var alpha = clamp(float(effect["life"]) / float(effect["max"]), 0.0, 1.0)
		var color: Color = effect["color"]
		color.a = alpha
		var kind = String(effect.get("kind", ""))
		if String(effect.get("text", "")) != "":
			_draw_centered(effect["text"], effect["pos"] - camera, int(effect["size"]), color)
		elif kind == "enemy_shard":
			var pos = effect["pos"] - camera
			var size = float(effect["size"]) * (0.72 + alpha * 0.65)
			var phase = float(effect.get("phase", 0.0))
			var tip = Vector2.from_angle(phase) * size
			var side = Vector2.from_angle(phase + PI * 0.5) * size * 0.62
			var points = PackedVector2Array([
				pos + tip,
				pos + side,
				pos - tip,
				pos - side
			])
			draw_polygon(points, PackedColorArray([Color(color.r, color.g, color.b, alpha * 0.92)]))
			draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(1.0, 1.0, 1.0, alpha * 0.75), 1.5, true)
			draw_circle(pos, size * 0.34, Color(1.0, 1.0, 1.0, alpha * 0.85))
		elif kind == "trail":
			var p = effect["pos"] - camera
			var radius = float(effect["size"]) * alpha
			draw_circle(p, radius, color)
			draw_circle(p, radius * 1.8, Color(color.r, color.g, color.b, alpha * 0.20))
			if effect.has("vel"):
				var vel: Vector2 = effect["vel"]
				if vel.length() > 4.0:
					draw_line(p - vel.normalized() * radius * 1.6, p, Color(1.0, 1.0, 1.0, alpha * 0.70), max(1.0, radius * 0.34))
		elif kind == "spark":
			var p = effect["pos"] - camera
			var r = float(effect["size"]) * alpha
			draw_line(p - effect["vel"].normalized() * r * 2.0, p + effect["vel"].normalized() * r * 2.0, color, r)
			draw_circle(p, r * 1.5, Color(1, 1, 1, alpha))
		elif kind == "slash_mark":
			var p = effect["pos"] - camera
			var r = float(effect["size"]) * alpha
			var a = float(effect.get("angle", 0.0))
			draw_line(p - Vector2.from_angle(a) * r * 3.0, p + Vector2.from_angle(a) * r * 3.0, color, r * 0.8)
			draw_line(p - Vector2.from_angle(a) * r * 1.5, p + Vector2.from_angle(a) * r * 1.5, Color(1, 1, 1, alpha), r * 0.4)
		elif kind == "shard":
			var p = effect["pos"] - camera
			var r = float(effect["size"]) * alpha
			var rot = float(effect.get("rot", 0.0))
			draw_set_transform(p, rot * (1.0 - alpha), Vector2.ONE)
			draw_rect(Rect2(Vector2(-r, -r), Vector2(r*2, r*2)), color, true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif kind == "bit":
			var p = effect["pos"] - camera
			var r = float(effect["size"]) * alpha
			draw_rect(Rect2(p - Vector2(r, r), Vector2(r*2, r*2)), color, false, max(1.0, r*0.5))
			draw_rect(Rect2(p - Vector2(r*0.5, r*0.5), Vector2(r, r)), Color(1,1,1,alpha), true)
		else:
			draw_circle(effect["pos"] - camera, float(effect["size"]) * alpha, color)


func _draw_hud(viewport: Vector2) -> void:
	var portrait = _is_portrait(viewport)
	var left_w = 236.0 if not portrait else min(236.0, viewport.x * 0.46)
	var left_rect = Rect2(_left_panel_pos(viewport), Vector2(left_w, 76))
	_draw_combat_panel(left_rect, Color(0.0, 1.0, 0.82), 0.58)
	draw_string(font, left_rect.position + Vector2(16, 30), "VIDA %d/%d" % [player_hp, player_hp_max], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
	_draw_hud_bar(left_rect.position + Vector2(16, 43), left_rect.size.x - 32.0, 8.0, float(player_hp) / float(player_hp_max), Color(0.20, 1.0, 0.42))
	var minutes = int(time_alive) / 60
	var seconds = int(time_alive) % 60
	var manifest_color = _manifestation_color()
	draw_string(font, left_rect.position + Vector2(16, 66), "%02d:%02d" % [minutes, seconds], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.36, 0.96, 1.0))
	draw_string(font, left_rect.position + Vector2(78, 66), MANIFESTATIONS[selected_manifestation]["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, manifest_color)

	var right_w = 220.0 if not portrait else min(220.0, viewport.x * 0.44)
	var right_rect = Rect2(_right_panel_pos(viewport), Vector2(right_w, 76))
	_draw_combat_panel(right_rect, Color(1.0, 0.82, 0.20), 0.54)
	draw_string(font, right_rect.position + Vector2(16, 30), "PONTOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.72, 0.86, 0.92))
	draw_string(font, right_rect.position + Vector2(84, 30), str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
	draw_string(font, right_rect.position + Vector2(16, 60), "CARTAS %d" % _affordable_card_count(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.86, 0.26))
	draw_string(font, right_rect.position + Vector2(112, 60), "CUSTO %d" % card_cost, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.86, 0.26))
	if boss_active and boss_hp > 0.0:
		var boss_rect = Rect2(_boss_panel_pos(viewport), Vector2(380, 30))
		_draw_combat_panel(boss_rect, Color(1.0, 0.16, 0.30), 0.62)
		_draw_hud_bar(boss_rect.position + Vector2(14, 11), boss_rect.size.x - 28.0, 8.0, boss_hp / boss_hp_max, Color(1.0, 0.16, 0.28))
		if _boss_execute_threshold() > 0.0:
			_draw_collector_threshold(boss_rect.position + Vector2(14, 11), boss_rect.size.x - 28.0, _boss_execute_threshold(), boss_hp / boss_hp_max, 8.0)
		if current_phase == 1 and boss_hp / max(1.0, boss_hp_max) < BOSS1_REWIND_THRESHOLD and boss1_rewind_cooldown > 0.0:
			var chrono_text = "CRONO %.0fs" % ceil(boss1_rewind_cooldown)
			draw_string(font, boss_rect.position + Vector2(boss_rect.size.x - 94.0, 28.0), chrono_text, HORIZONTAL_ALIGNMENT_LEFT, 82.0, 11, Color(0.48, 0.94, 1.0, 0.92))
		if current_phase == 3:
			var faith_rect = Rect2(boss_rect.position + Vector2(64, 34), Vector2(252, 24))
			_draw_combat_panel(faith_rect, Color(0.62, 0.94, 0.18), 0.48)
			_draw_hud_bar(faith_rect.position + Vector2(54, 8), 184.0, 7.0, boss3_faith / 100.0, Color(0.66, 1.0, 0.22))
			draw_string(font, faith_rect.position + Vector2(8, 17), "FE %d" % int(boss3_faith), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.86, 1.0, 0.58))
			if boss3_ritual_timer > 0.0:
				_draw_centered("RITUAL %.1fs  %d/2" % [boss3_ritual_timer, boss3_ritual_destroyed], Vector2(viewport.x * 0.5, 112), 20, Color(1.0, 0.42, 0.18))
	if event_alert_timer > 0.0:
		var c = event_alert_color
		c.a = min(1.0, event_alert_timer)
		_draw_centered(event_alert_text, Vector2(viewport.x * 0.5, 92), 24, c)
	_draw_card_mechanic_huds(viewport, left_rect)


func _draw_card_mechanic_huds(viewport: Vector2, anchor: Rect2) -> void:
	var y = anchor.end.y + 8.0
	var width = min(224.0, viewport.x * 0.46)
	if int(cards_bought.get("Mercenaria", 0)) > 0:
		var pulse = clamp(mercenary_hud_pulse, 0.0, 1.0)
		var rect = Rect2(anchor.position.x, y, width, 46.0)
		_draw_combat_panel(rect, Color(1.0, 0.58 + pulse * 0.22, 0.10), 0.62)
		draw_string(font, rect.position + Vector2(10, 17), "CONTRATO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.80, 0.30))
		draw_string(font, rect.position + Vector2(width - 74, 17), "+%d" % mercenary_bonus_points, HORIZONTAL_ALIGNMENT_RIGHT, 64, 13, Color.WHITE)
		var progress = combo_kills % 5
		for i in range(5):
			var pip_pos = rect.position + Vector2(16 + i * 24, 32)
			var filled = i < progress
			draw_circle(pip_pos, 6.0, Color(1.0, 0.65, 0.12, 0.95) if filled else Color(0.22, 0.16, 0.08, 0.86))
			draw_arc(pip_pos, 7.5, 0, TAU, 18, Color(1.0, 0.82, 0.34, 0.72), 1.2)
		draw_string(font, rect.position + Vector2(138, 37), "%d ABATES" % combo_kills, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.92, 0.86, 0.72))
		y += 52.0
	if execute_threshold > 0.0:
		var pulse = clamp(collector_hud_pulse, 0.0, 1.0)
		var rect = Rect2(anchor.position.x, y, width, 42.0)
		_draw_combat_panel(rect, Color(1.0, 0.05, 0.20), 0.62)
		draw_string(font, rect.position + Vector2(10, 17), "COLETORA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.32 + pulse * 0.28, 0.38))
		draw_string(font, rect.position + Vector2(10, 34), "COMUM %.1f%%" % (execute_threshold * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		draw_string(font, rect.position + Vector2(116, 34), "BOSS %.1f%%" % (_boss_execute_threshold() * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.76, 0.40))


func _draw_collector_threshold(pos: Vector2, width: float, threshold: float, hp_ratio: float, height := 5.0) -> void:
	var marker_x = pos.x + width * clamp(threshold, 0.0, 1.0)
	var active = hp_ratio <= threshold
	var pulse = 0.5 + 0.5 * sin(time_alive * 12.0)
	var color = Color(1.0, 0.08, 0.20, 1.0) if active else Color(1.0, 0.76, 0.22, 0.92)
	draw_line(Vector2(marker_x, pos.y - 3.0), Vector2(marker_x, pos.y + height + 4.0), color, 2.0)
	if active:
		draw_arc(Vector2(marker_x, pos.y + height * 0.5), 7.0 + pulse * 2.0, 0, TAU, 18, Color(1.0, 0.04, 0.16, 0.55), 2.0)


func _draw_teleport_preview(viewport: Vector2, camera: Vector2) -> void:
	var dest = _teleport_destination_from_drag(teleport_drag_screen, viewport)
	var a = player_pos - camera
	var b = dest - camera
	draw_line(a, b, Color(0.25, 0.95, 1.0, 0.72), 8)
	draw_line(a, b, Color(1.0, 0.14, 0.95, 0.42), 3)
	draw_circle(b, 28, Color(0.05, 0.85, 1.0, 0.22))
	draw_arc(b, 34, 0, TAU, 48, Color(0.80, 0.15, 1.0, 0.88), 4)


func _draw_ground_target_preview(viewport: Vector2, camera: Vector2) -> void:
	var secondary = false
	var touch_pos = Vector2.ZERO
	if skill_touch_index != -1 and not _ground_target_profile(false).is_empty():
		touch_pos = skill_touch_pos
	elif secondary_touch_index != -1 and not _ground_target_profile(true).is_empty():
		secondary = true
		touch_pos = secondary_touch_pos
	else:
		return
	if _ability_cancel_has_point(touch_pos, viewport):
		return
	var profile = _ground_target_profile(secondary)
	var target_world = _ground_target_world(touch_pos, viewport, secondary)
	var start = player_pos - camera
	var target = target_world - camera
	var color: Color = profile["color"]
	var radius = float(profile["radius"])
	var pulse = 0.5 + sin(Time.get_ticks_msec() * 0.010) * 0.5
	draw_arc(start, float(profile["range"]), 0.0, TAU, 96, Color(color.r, color.g, color.b, 0.18), 2.0)
	draw_line(start, target, Color(color.r, color.g, color.b, 0.24), 10.0)
	draw_line(start, target, Color(color.r, color.g, color.b, 0.86), 2.0)
	draw_circle(target, radius, Color(color.r, color.g, color.b, 0.10 + pulse * 0.04))
	draw_arc(target, radius + pulse * 5.0, 0.0, TAU, 64, Color(color.r, color.g, color.b, 0.94), 3.0)
	draw_arc(target, radius * 0.68, -Time.get_ticks_msec() * 0.002, TAU - Time.get_ticks_msec() * 0.002, 48, Color(1.0, 1.0, 1.0, 0.54), 1.5)
	draw_line(target + Vector2(-14.0, 0.0), target + Vector2(14.0, 0.0), Color.WHITE, 2.0)
	draw_line(target + Vector2(0.0, -14.0), target + Vector2(0.0, 14.0), Color.WHITE, 2.0)


func _draw_touch_controls(viewport: Vector2) -> void:
	var joy = _active_joy_center(viewport)
	var joy_r = 76.0 * _joy_scale()
	_draw_virtual_stick(joy, joy_r)

	var atk_c = buttons["attack"].position + buttons["attack"].size * 0.5
	var atk_r = 54.0 * _attack_scale()
	_draw_button(atk_c, atk_r, "ATK", Color(1.0, 0.24, 0.26, 0.70))
	if attack_holding and not attack_dragging:
		var hold_ratio = clamp(attack_hold_timer / ATTACK_LOCK_HOLD_TIME, 0.0, 1.0)
		draw_arc(atk_c, atk_r + 7.0, -PI * 0.5, -PI * 0.5 + TAU * hold_ratio, 48, Color(1.0, 0.86, 0.24, 0.96), 4.0)
		if attack_lock_selecting:
			_draw_attack_lock_preview(viewport)

	var skill_c = buttons["skill"].position + buttons["skill"].size * 0.5
	var skill_r = 46.0 * _skill_scale()
	_draw_button(skill_c, skill_r, "Q", Color(_manifestation_color().r, _manifestation_color().g, _manifestation_color().b, 0.70))
	var secondary_c = buttons["secondary"].position + buttons["secondary"].size * 0.5
	var secondary_r = 43.0 * _secondary_scale()
	var toggle_ultimate_active = not _active_eletrica_secondary().is_empty() or not _active_prismatica_secondary().is_empty()
	_draw_button(secondary_c, secondary_r, "X" if toggle_ultimate_active else "E", Color(1.0, 0.24, 0.28, 0.82) if toggle_ultimate_active else Color(1.0, 0.72, 0.22, 0.72))
	if toggle_ultimate_active:
		var cancel_pulse = 0.5 + sin(time_alive * 7.0) * 0.5
		draw_arc(secondary_c, secondary_r + 6.0 + cancel_pulse * 3.0, 0.0, TAU, 48, Color(1.0, 0.30, 0.34, 0.82), 3.0)
		_draw_centered("CANCELAR", secondary_c + Vector2(0, secondary_r + 16.0), 10, Color(1.0, 0.78, 0.80))

	var dash_c = buttons["dash"].position + buttons["dash"].size * 0.5
	var dash_r = 46.0 * _dash_scale()
	_draw_button(dash_c, dash_r, "TP", Color(0.20, 0.85, 1.0, 0.72))

	_draw_cooldown_overlay(atk_c, atk_r, time_alive - last_attack_time, _current_attack_interval())
	_draw_cooldown_overlay(skill_c, skill_r, time_alive - last_skill_time, _skill_cooldown())
	if not toggle_ultimate_active:
		_draw_cooldown_overlay(secondary_c, secondary_r, time_alive - last_secondary_time, _secondary_skill_cooldown())
	_draw_cooldown_overlay(dash_c, dash_r, time_alive - last_dash_time, player_dash_cooldown)
	_draw_hud_rect_button(buttons["pause"], "II", Color(0.0, 1.0, 0.82))
	if buttons.has("shop_manual"):
		var shop_rect: Rect2 = buttons["shop_manual"]
		var shop_accent = Color(0.0, 1.0, 0.82) if score >= card_cost and mode == "game" else Color(0.38, 0.42, 0.46)
		_draw_centered("LOJA %d" % card_cost, shop_rect.get_center() + Vector2(0, -29), 12, Color(shop_accent.r, shop_accent.g, shop_accent.b, 0.92))
		_draw_hud_rect_button(shop_rect, "LOJA", shop_accent)
	if boss_ready and not boss_active and not boss_dead:
		var boss_rect: Rect2 = buttons["boss"]
		_draw_centered("BOSS PRONTO", boss_rect.get_center() + Vector2(0, -31), 16, Color(1.0, 0.82, 0.24))
		_draw_hud_rect_button(boss_rect, "BOSS", Color(1.0, 0.52, 0.16))
	if _ability_cancel_active():
		_draw_ability_cancel_button(viewport)

func _draw_edit_layout(viewport: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.05, 0.05, 0.08, 0.9))
	_draw_centered("EDITAR HUD (Arraste para Mover)", Vector2(viewport.x * 0.5, 40), 28, Color(0.0, 1.0, 0.82))

	var joy = _joy_center(viewport)
	var joy_r = 76.0 * _joy_scale()
	draw_circle(joy, joy_r, Color(0.8, 0.8, 0.0, 0.4) if edit_layout_selected == "joy" else Color(0.0, 0.8, 0.8, 0.4))
	draw_arc(joy, joy_r, 0, TAU, 64, Color(1.0, 1.0, 0.0) if edit_layout_selected == "joy" else Color(0.0, 1.0, 0.85), 3)
	_draw_centered("JOY", joy, 20, Color.WHITE)
	_draw_small_rect_button(Rect2(joy.x - 60, joy.y + joy_r + 10, 50, 40), "-", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))
	_draw_small_rect_button(Rect2(joy.x + 10, joy.y + joy_r + 10, 50, 40), "+", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))

	var atk_c = buttons["attack"].position + buttons["attack"].size * 0.5
	var atk_r = 54.0 * _attack_scale()
	draw_circle(atk_c, atk_r, Color(0.8, 0.8, 0.0, 0.4) if edit_layout_selected == "attack" else Color(1.0, 0.16, 0.28, 0.4))
	draw_arc(atk_c, atk_r, 0, TAU, 32, Color(1.0, 1.0, 0.0) if edit_layout_selected == "attack" else Color(1.0, 0.16, 0.28), 3)
	_draw_centered("ATK", atk_c, 20, Color.WHITE)
	_draw_small_rect_button(Rect2(atk_c.x - 60, atk_c.y + atk_r + 10, 50, 40), "-", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))
	_draw_small_rect_button(Rect2(atk_c.x + 10, atk_c.y + atk_r + 10, 50, 40), "+", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))

	var secondary_c = buttons["secondary"].position + buttons["secondary"].size * 0.5
	var secondary_r = 43.0 * _secondary_scale()
	draw_circle(secondary_c, secondary_r, Color(0.8, 0.8, 0.0, 0.4) if edit_layout_selected == "secondary" else Color(1.0, 0.72, 0.22, 0.4))
	draw_arc(secondary_c, secondary_r, 0, TAU, 32, Color(1.0, 1.0, 0.0) if edit_layout_selected == "secondary" else Color(1.0, 0.72, 0.22), 3)
	_draw_centered("E", secondary_c + Vector2(0, -6), 20, Color.WHITE)
	_draw_centered("ULT", secondary_c + Vector2(0, 13), 12, Color.WHITE)
	_draw_small_rect_button(Rect2(secondary_c.x - 60, secondary_c.y + secondary_r + 10, 50, 40), "-", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))
	_draw_small_rect_button(Rect2(secondary_c.x + 10, secondary_c.y + secondary_r + 10, 50, 40), "+", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))

	var dash_c = buttons["dash"].position + buttons["dash"].size * 0.5
	var dash_r = 46.0 * _dash_scale()
	draw_circle(dash_c, dash_r, Color(0.8, 0.8, 0.0, 0.4) if edit_layout_selected == "dash" else Color(0.20, 0.85, 1.0, 0.4))
	draw_arc(dash_c, dash_r, 0, TAU, 32, Color(1.0, 1.0, 0.0) if edit_layout_selected == "dash" else Color(0.20, 0.85, 1.0), 3)
	_draw_centered("TP", dash_c, 20, Color.WHITE)
	_draw_small_rect_button(Rect2(dash_c.x - 60, dash_c.y + dash_r + 10, 50, 40), "-", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))
	_draw_small_rect_button(Rect2(dash_c.x + 10, dash_c.y + dash_r + 10, 50, 40), "+", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))

	var portrait = _is_portrait(viewport)
	var left_w = 236.0 if not portrait else min(236.0, viewport.x * 0.46)
	var left_rect = Rect2(_left_panel_pos(viewport), Vector2(left_w, 76))
	var c_left = Color(1,1,0,0.6) if edit_layout_selected == "left_panel" else Color(0,1,0.8,0.3)
	draw_rect(left_rect, c_left, false, 2)
	_draw_centered("VIDA", left_rect.get_center(), 16, Color.WHITE)

	var right_w = 220.0 if not portrait else min(220.0, viewport.x * 0.44)
	var right_rect = Rect2(_right_panel_pos(viewport), Vector2(right_w, 76))
	var c_right = Color(1,1,0,0.6) if edit_layout_selected == "right_panel" else Color(1,0.8,0.2,0.3)
	draw_rect(right_rect, c_right, false, 2)
	_draw_centered("PONTOS", right_rect.get_center(), 16, Color.WHITE)

	var boss_rect = Rect2(_boss_panel_pos(viewport), Vector2(380, 30))
	var c_boss = Color(1,1,0,0.6) if edit_layout_selected == "boss_panel" else Color(1,0.16,0.3,0.3)
	draw_rect(boss_rect, c_boss, false, 2)
	_draw_centered("BOSS HP", boss_rect.get_center(), 14, Color.WHITE)

	var skill_r = 46.0 * _skill_scale()
	var skill_rect = Rect2(_skill_pos(viewport), Vector2(skill_r * 2.0, skill_r * 2.0))
	var skill_c = skill_rect.get_center()
	draw_circle(skill_c, skill_r, Color(0.8, 0.8, 0.0, 0.4) if edit_layout_selected == "skill" else Color(_manifestation_color().r, _manifestation_color().g, _manifestation_color().b, 0.4))
	draw_arc(skill_c, skill_r, 0, TAU, 32, Color(1.0, 1.0, 0.0) if edit_layout_selected == "skill" else _manifestation_color(), 3)
	_draw_centered("Q", skill_c + Vector2(0, -6), 20, Color.WHITE)
	_draw_centered("HAB", skill_c + Vector2(0, 13), 12, Color.WHITE)
	_draw_small_rect_button(Rect2(skill_c.x - 60, skill_c.y + skill_r + 10, 50, 40), "-", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))
	_draw_small_rect_button(Rect2(skill_c.x + 10, skill_c.y + skill_r + 10, 50, 40), "+", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))

	var pause_rect = Rect2(_pause_pos(viewport), Vector2(52, 42))
	var c_pause = Color(1,1,0,0.6) if edit_layout_selected == "pause" else Color(1,1,1,0.3)
	draw_rect(pause_rect, c_pause, false, 2)
	_draw_centered("||", pause_rect.get_center(), 14, Color.WHITE)

	var call_rect = Rect2(_boss_call_pos(viewport), Vector2(96, 42))
	var c_call = Color(1,1,0,0.6) if edit_layout_selected == "boss_call" else Color(1,0.5,0,0.3)
	draw_rect(call_rect, c_call, false, 2)
	_draw_centered("CALL", call_rect.get_center(), 14, Color.WHITE)

	_draw_big_button(Rect2(viewport.x * 0.5 - 150, viewport.y - 80, 300, 60), "SALVAR & VOLTAR", Color(0.1, 0.3, 0.1), Color(0.2, 1.0, 0.4))



func _draw_cooldown_overlay(center: Vector2, radius: float, elapsed: float, cooldown: float) -> void:
	if elapsed >= cooldown:
		return
	var ratio = clamp(elapsed / max(0.01, cooldown), 0.0, 1.0)
	draw_circle(center, radius * 0.92, Color(0.0, 0.0, 0.0, 0.46))
	draw_arc(center, radius + 3, -PI * 0.5, -PI * 0.5 + TAU * ratio, 64, Color(0.80, 1.0, 1.0, 0.88), 4)
	draw_arc(center, radius * 0.62, 0, TAU, 32, Color(1.0, 1.0, 1.0, 0.18), 1.4)
	_draw_centered("%.1f" % (cooldown - elapsed), center + Vector2(0, 6), int(clamp(radius * 0.28, 13.0, 17.0)), Color.WHITE)


func _draw_shop(viewport: Vector2) -> void:
	# Draw holo background
	_draw_holo_background(viewport, textures["cards_back"], Color(0.0, 1.0, 0.82))

	var portrait = _is_portrait(viewport)
	var purchase_animating = _shop_purchase_animating()
	var purchase_progress = 0.0
	if purchase_animating:
		purchase_progress = 1.0 - clamp(shop_purchase_anim_timer / SHOP_PURCHASE_ANIM_TIME, 0.0, 1.0)
	var purchase_index = shop_select_pulse_index if purchase_animating else -1

	if portrait:
		var header = Rect2(viewport.x * 0.06, 24, viewport.x * 0.88, 104)
		_draw_holo_panel(header, Color(0.0, 1.0, 0.82), true, 0.76)
		_draw_glitch_title("LOJA DE CARTAS", Vector2(viewport.x * 0.5, 66), 30, Color(0.0, 1.0, 0.82))
		var header_text = "Pontos %d  |  Custo %d  |  Rerolls %d" % [score, card_cost, shop_rerolls]
		if purchase_animating:
			header_text = "Carta confirmada  |  sincronizando deck"
		_draw_centered(header_text, Vector2(viewport.x * 0.5, 108), _readable_text_size(17), Color(1.0, 0.85, 0.24))
		_draw_shop_round_button(_shop_reroll_center(viewport), _shop_round_button_radius(viewport), "REROLL", Color(0.0, 0.86, 1.0), shop_rerolls > 0 and not purchase_animating, "reroll")
		_draw_shop_round_button(_shop_deck_center(viewport), _shop_round_button_radius(viewport), "DECK", Color(0.64, 0.88, 1.0), _deck_total_cards() > 0 and not purchase_animating, "deck")

		var w = viewport.x * 0.74
		var h = min(242.0, viewport.y * 0.19)
		for i in range(shop_cards.size()):
			var card: Dictionary = shop_cards[i]
			var rarity_color := _card_rarity_color(card)
			var x = viewport.x * 0.5 - w * 0.5
			var y = 164.0 + i * (h + 22.0)
			var rect = Rect2(x, y, w, h)
			var card_alpha = 1.0
			if purchase_animating:
				card_alpha = 0.18 if i != purchase_index else 1.0
			if i == shop_selected:
				var select_pulse = 0.0
				if shop_select_pulse_index == i and shop_select_pulse_timer > 0.0:
					select_pulse = sin((1.0 - shop_select_pulse_timer / 0.26) * PI)
				rect = rect.grow(12 + select_pulse * 12.0)
			if purchase_animating and i == purchase_index:
				var rise = clamp((purchase_progress - 0.18) / 0.82, 0.0, 1.0)
				var burst = sin(min(1.0, purchase_progress / 0.45) * PI)
				rect = rect.grow(14.0 + burst * 18.0 - rise * 46.0)
				rect.position.y -= rise * 86.0
				card_alpha = 1.0 - rise * 0.76
			var bg_color = Color(0.035, 0.045, 0.060)
			bg_color = bg_color.lerp(card["color"], 0.14 if i == shop_selected else 0.05)
			bg_color.a = 0.94 * card_alpha
			draw_rect(rect, bg_color, true)
			var border_color = rarity_color if i == shop_selected else Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.58)
			border_color.a = max(0.16, card_alpha)
			draw_rect(rect, border_color, false, 5 if i == shop_selected else 2)
			if purchase_animating and i == purchase_index:
				var glow = (0.35 + sin(Time.get_ticks_msec() * 0.01) * 0.15) * (1.0 - purchase_progress * 0.35)
				for g in range(1, 4):
					var glow_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, glow / float(g))
					draw_rect(rect.grow(g * 7.0), glow_color, false, 2)
			var icon: Texture2D = textures.get("card_" + card["name"])
			if icon:
				var icon_rect = Rect2(rect.position + Vector2(18, 18), Vector2(94, rect.size.y - 36))
				_draw_texture_contain(icon, icon_rect, Color(1.0, 1.0, 1.0, card_alpha))
			_draw_centered(card["name"], Vector2(rect.position.x + 128 + (rect.size.x - 150) * 0.5, rect.position.y + 48), _readable_text_size(19), Color(1.0, 1.0, 1.0, card_alpha))
			_draw_centered(_card_rarity_label(card), Vector2(rect.end.x - 52.0, rect.position.y + 24.0), _readable_text_size(10), Color(rarity_color.r, rarity_color.g, rarity_color.b, card_alpha))
			var nick_color = Color(card["color"].r, card["color"].g, card["color"].b, card_alpha)
			_draw_centered(card["nick"], Vector2(rect.position.x + 128 + (rect.size.x - 150) * 0.5, rect.position.y + 80), _readable_text_size(15), nick_color)
			_draw_wrapped(card["desc"], Rect2(rect.position + Vector2(128, 102), Vector2(rect.size.x - 150, rect.size.y - 118)), _readable_text_size(12), Color(0.84, 0.89, 0.93, max(0.28, card_alpha)))
			if i == shop_selected:
				_draw_card_stat_chips(_card_stat_chips(String(card["name"])), rect.position + Vector2(128, rect.size.y - 76), rect.size.x - 150, Color(card["color"]), _readable_text_size(11))
				var conf_rect = Rect2(rect.position.x + 128, rect.position.y + rect.size.y - 45, rect.size.x - 140, 35)
				draw_rect(conf_rect, Color(0.05, 0.35, 0.15, 0.9 * card_alpha), true)
				draw_rect(conf_rect, Color(0.2, 1.0, 0.45, max(0.14, card_alpha)), false, 1)
				var confirm_label = "CONFIRMADA" if purchase_animating and i == purchase_index else "SELECIONADA"
				_draw_centered(confirm_label, Vector2(conf_rect.position.x + conf_rect.size.x * 0.5, conf_rect.position.y + 22), _readable_text_size(16), Color(1.0, 1.0, 1.0, card_alpha))

		var btn_h = 44.0
		var btn_w = viewport.x * 0.40
		var btn_y = viewport.y - btn_h - 24

		# Buy Button
		var btn_buy_rect = Rect2(viewport.x * 0.25 - btn_w * 0.5, btn_y, btn_w, btn_h)
		var buy_bg_portrait = Color(0.03, 0.12, 0.05) if score >= card_cost else Color(0.08, 0.08, 0.08)
		var buy_border_portrait = Color(0.2, 1.0, 0.45) if score >= card_cost else Color(0.3, 0.3, 0.3)
		if purchase_animating:
			buy_bg_portrait = Color(0.08, 0.08, 0.08, 0.55)
			buy_border_portrait = Color(0.36, 0.36, 0.36, 0.55)
		_draw_small_rect_button(btn_buy_rect, "CONFIRMANDO..." if purchase_animating else "COMPRAR", buy_bg_portrait, buy_border_portrait)

		# Close Button
		var btn_sair_rect = Rect2(viewport.x * 0.75 - btn_w * 0.5, btn_y, btn_w, btn_h)
		_draw_small_rect_button(btn_sair_rect, "AGUARDE" if purchase_animating else "FECHAR LOJA", Color(0.12, 0.03, 0.05, 0.55 if purchase_animating else 1.0), Color(1.0, 0.25, 0.28, 0.55 if purchase_animating else 1.0))
		return

	# LANDSCAPE LAYOUT
	# Header Panel
	var header = Rect2(viewport.x * 0.05, 16, viewport.x * 0.90, 76)
	_draw_holo_panel(header, Color(0.0, 1.0, 0.82), true, 0.76)
	_draw_glitch_title("LOJA DE CARTAS", Vector2(viewport.x * 0.5, 54), 26, Color(0.0, 1.0, 0.82))

	# Draw score HUD inside header
	var hud_text = "Pontos: %d  |  Custo: %d  |  Rerolls: %d" % [score, card_cost, shop_rerolls]
	if purchase_animating:
		hud_text = "Carta confirmada  |  atualizando deck"
	_draw_centered(hud_text, Vector2(viewport.x * 0.5, 84), _readable_text_size(16), Color(1.0, 0.85, 0.24))
	_draw_shop_round_button(_shop_reroll_center(viewport), _shop_round_button_radius(viewport), "REROLL", Color(0.0, 0.86, 1.0), shop_rerolls > 0 and not purchase_animating, "reroll")
	_draw_shop_round_button(_shop_deck_center(viewport), _shop_round_button_radius(viewport), "DECK", Color(0.64, 0.88, 1.0), _deck_total_cards() > 0 and not purchase_animating, "deck")
	if purchase_animating and shop_cards.size() > purchase_index:
		_draw_centered("CARTA ADQUIRIDA", Vector2(viewport.x * 0.5, 106), _readable_text_size(14), shop_cards[purchase_index]["color"])
	elif shop_select_pulse_timer > 0.0 and shop_cards.size() > shop_selected:
		_draw_centered("CARTA SELECIONADA", Vector2(viewport.x * 0.5, 106), _readable_text_size(14), shop_cards[shop_selected]["color"])

	# Card carousel variables
	var w = 150.0
	var h = 200.0
	var y = 120.0

	# Loop to draw each card
	for i in range(shop_cards.size()):
		var card: Dictionary = shop_cards[i]
		var rarity_color := _card_rarity_color(card)

		# Position and scale based on selection
		var is_sel = (i == shop_selected)
		var scale = 1.15 if is_sel else 0.85
		if is_sel and shop_select_pulse_index == i and shop_select_pulse_timer > 0.0:
			scale += sin((1.0 - shop_select_pulse_timer / 0.26) * PI) * 0.10
		var alpha = 1.0 if is_sel else 0.5
		if purchase_animating:
			alpha = 0.18 if i != purchase_index else 1.0
		if purchase_animating and i == purchase_index:
			var rise = clamp((purchase_progress - 0.18) / 0.82, 0.0, 1.0)
			var burst = sin(min(1.0, purchase_progress / 0.45) * PI)
			scale += burst * 0.22 - rise * 0.48
			alpha = 1.0 - rise * 0.78
		var curr_w = w * scale
		var curr_h = h * scale
		var x = viewport.x * 0.5 + (i - 1) * 200 - curr_w * 0.5
		var curr_y = y - 10 if is_sel else y + 15
		if purchase_animating and i == purchase_index:
			curr_y -= clamp((purchase_progress - 0.18) / 0.82, 0.0, 1.0) * 86.0
		var rect = Rect2(x, curr_y, curr_w, curr_h)

		# Draw card glassmorphic background
		var bg_color = Color(0.04, 0.05, 0.07, 0.85 * alpha)
		bg_color = bg_color.lerp(card["color"], 0.14 if is_sel else 0.05)
		draw_rect(rect, bg_color, true)

		# Glow concentric if selected
		if is_sel:
			var pulsar = (sin(Time.get_ticks_msec() * 0.005) + 1.0) * 0.5
			for g in range(1, 5):
				var glow_alpha = (1.0 - float(g)/5.0) * (0.3 + pulsar * 0.15)
				if purchase_animating and i == purchase_index:
					glow_alpha += 0.16
				var glow_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, glow_alpha)
				draw_rect(rect.grow(g * 3), glow_color, false, 1)

		# Card Border
		var border_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, alpha if is_sel else 0.55 * alpha)
		draw_rect(rect, border_color, false, 4 if is_sel else 2)
		if is_sel:
			var scan_y = rect.position.y + 12.0 + fposmod(Time.get_ticks_msec() * 0.065, max(1.0, rect.size.y - 24.0))
			draw_line(Vector2(rect.position.x + 10.0, scan_y), Vector2(rect.end.x - 10.0, scan_y), Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.72), 2.0)
			var ribbon = Rect2(rect.position.x + 10.0, rect.position.y + 10.0, rect.size.x - 20.0, 25.0)
			draw_rect(ribbon, Color(0.0, 0.0, 0.0, 0.68 * alpha), true)
			draw_rect(ribbon, Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.88 * alpha), false, 1)
			_draw_centered("%s | PRE-SELECIONADA" % _card_rarity_label(card), ribbon.get_center() + Vector2(0, 5), _readable_text_size(9), Color.WHITE)

		# Draw Card Icon/Texture
		var icon: Texture2D = textures.get("card_" + card["name"])
		if icon:
			var icon_rect = Rect2(rect.position + Vector2(6, 6), rect.size - Vector2(12, 12))
			_draw_texture_contain(icon, icon_rect, Color(1, 1, 1, alpha))

		# Small overlay for card title/nickname on the card itself
		var text_color = Color(1.0, 1.0, 1.0, alpha)
		_draw_centered(card["nick"].to_upper(), Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y - 18), _readable_text_size(12 if is_sel else 10), text_color)

		if is_sel and purchase_animating and i == purchase_index:
			var overlay_rect = Rect2(rect.position.x, rect.position.y + rect.size.y * 0.5 - 18, rect.size.x, 36)
			draw_rect(overlay_rect, Color(0.05, 0.35, 0.15, 0.95), true)
			draw_rect(overlay_rect, Color(0.2, 1.0, 0.45), false, 2)
			_draw_centered("CONFIRMADA", Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y * 0.5 + 5), _readable_text_size(16), Color(1.0, 1.0, 1.0, alpha))

	# 8. Descriptive Glassmorphic Panel (Bottom)
	if shop_cards.size() > shop_selected and shop_selected >= 0:
		var sel_card = shop_cards[shop_selected]
		var sel_rarity_color := _card_rarity_color(sel_card)
		var panel_w = viewport.x * 0.90
		var panel_h = 180.0
		var panel_x = viewport.x * 0.05
		var panel_y = viewport.y - panel_h - 96.0
		var panel_rect = Rect2(panel_x, panel_y, panel_w, panel_h)

		# Draw dark transparent panel
		draw_rect(panel_rect, Color(0.03, 0.04, 0.06, 0.92), true)

		# Shiny border colored using selected card theme color
		var border_p_color = Color(sel_rarity_color.r, sel_rarity_color.g, sel_rarity_color.b, 0.8)
		draw_rect(panel_rect, border_p_color, false, 2)

		# Vertical Divider
		var sep_x = panel_x + panel_w * 0.5 + 30.0
		draw_line(Vector2(sep_x, panel_y + 16), Vector2(sep_x, panel_y + panel_h - 16), Color(0.2, 0.2, 0.25, 0.6), 1)

		# Left side details
		# Title
		var title_pos = Vector2(panel_x + 24, panel_y + 30)
		draw_string(font, title_pos, sel_card["name"].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, _readable_text_size(22), sel_card["color"])

		# Nickname
		var nick_pos = Vector2(panel_x + 24, panel_y + 60)
		draw_string(font, nick_pos, '"' + sel_card["nick"].to_upper() + '"', HORIZONTAL_ALIGNMENT_LEFT, -1, _readable_text_size(15), Color(1, 1, 1, 0.9))

		# Description
		var desc_rect = Rect2(panel_x + 24, panel_y + 82, (sep_x - panel_x) - 48, panel_h - 94)
		_draw_wrapped(sel_card["desc"], desc_rect, _readable_text_size(13), Color(0.88, 0.92, 0.96))

		# Right side details
		var cat_name = _card_category(sel_card["name"])

		# Category
		var cat_pos = Vector2(sep_x + 24, panel_y + 30)
		draw_string(font, cat_pos, "%s | %s" % [_card_rarity_label(sel_card), cat_name], HORIZONTAL_ALIGNMENT_LEFT, -1, _readable_text_size(14), sel_rarity_color)

		# Direct stat chips
		_draw_card_stat_chips(_card_stat_chips(String(sel_card["name"])), Vector2(sep_x + 24, panel_y + 56), (panel_x + panel_w - sep_x) - 48, Color(sel_card["color"]), _readable_text_size(13))

		# Owned count
		var owned_count = cards_bought.get(sel_card["name"], 0)
		var owned_text = "POSSUIDO NO DECK: %d" % owned_count
		var owned_pos = Vector2(sep_x + 24, panel_y + panel_h - 18)
		draw_string(font, owned_pos, owned_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _readable_text_size(13), sel_card["color"])

	# Footer buttons
	var btn_w = 220.0
	var btn_h = 42.0
	var btn_y = viewport.y - btn_h - 24.0

	# Buy Button
	var btn_buy_rect = Rect2(viewport.x * 0.38 - btn_w * 0.5, btn_y, btn_w, btn_h)
	var buy_enabled = score >= card_cost and not purchase_animating
	var buy_bg = Color(0.03, 0.16, 0.08, 0.9) if buy_enabled else Color(0.08, 0.08, 0.08, 0.6)
	var buy_border = Color(0.2, 1.0, 0.45) if buy_enabled else Color(0.3, 0.3, 0.3)
	var buy_text_color = Color(1.0, 1.0, 1.0) if buy_enabled else Color(0.5, 0.5, 0.5)
	draw_rect(btn_buy_rect, buy_bg, true)
	draw_rect(btn_buy_rect, buy_border, false, 2)
	_draw_centered("CONFIRMANDO..." if purchase_animating else "COMPRAR (%d pts)" % card_cost, btn_buy_rect.get_center() + Vector2(0, 7), 15, buy_text_color)

	# Close Button
	var btn_sair_rect = Rect2(viewport.x * 0.62 - btn_w * 0.5, btn_y, btn_w, btn_h)
	draw_rect(btn_sair_rect, Color(0.15, 0.03, 0.05, 0.5 if purchase_animating else 0.9), true)
	draw_rect(btn_sair_rect, Color(1.0, 0.25, 0.28, 0.55 if purchase_animating else 1.0), false, 2)
	_draw_centered("AGUARDE" if purchase_animating else "FECHAR LOJA", btn_sair_rect.get_center() + Vector2(0, 7), 15, Color(1.0, 1.0, 1.0, 0.75 if purchase_animating else 1.0))


func _draw_pause(viewport: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, 0.62), true)
	var portrait = _is_portrait(viewport)
	var panel = Rect2(viewport.x * 0.18 if not portrait else viewport.x * 0.08, viewport.y * 0.22, viewport.x * 0.64 if not portrait else viewport.x * 0.84, viewport.y * 0.52)
	_draw_holo_panel(panel, Color(0.0, 1.0, 0.82), true, 0.82)
	_draw_glitch_title("PAUSE", Vector2(viewport.x * 0.5, panel.position.y + panel.size.y * 0.28), 42 if not portrait else 48, Color(0.0, 1.0, 0.82))
	_draw_centered("PROTOCOLO TEMPORAL SUSPENSO", Vector2(viewport.x * 0.5, panel.position.y + panel.size.y * 0.52), 14 if not portrait else 16, Color(0.72, 0.94, 1.0))

	var resume_rect: Rect2
	var settings_rect: Rect2
	var deck_rect: Rect2
	var menu_rect: Rect2
	if not portrait:
		var btn_w = 160.0
		var btn_h = 48.0
		var start_x = viewport.x * 0.5 - (btn_w * 4.0 + 36.0) * 0.5
		resume_rect = Rect2(start_x, panel.end.y - btn_h - 24.0, btn_w, btn_h)
		deck_rect = Rect2(start_x + btn_w + 12.0, panel.end.y - btn_h - 24.0, btn_w, btn_h)
		settings_rect = Rect2(start_x + (btn_w + 12.0) * 2.0, panel.end.y - btn_h - 24.0, btn_w, btn_h)
		menu_rect = Rect2(start_x + (btn_w + 12.0) * 3.0, panel.end.y - btn_h - 24.0, btn_w, btn_h)
	else:
		var btn_w = 260.0
		var btn_h = 40.0
		resume_rect = Rect2(viewport.x * 0.5 - 130.0, panel.end.y - 200.0, btn_w, btn_h)
		deck_rect = Rect2(viewport.x * 0.5 - 130.0, panel.end.y - 150.0, btn_w, btn_h)
		settings_rect = Rect2(viewport.x * 0.5 - 130.0, panel.end.y - 100.0, btn_w, btn_h)
		menu_rect = Rect2(viewport.x * 0.5 - 130.0, panel.end.y - 50.0, btn_w, btn_h)

	buttons["pause_resume"] = resume_rect
	buttons["pause_deck"] = deck_rect
	buttons["pause_settings"] = settings_rect
	buttons["pause_menu"] = menu_rect

	_draw_big_button(resume_rect, "CONTINUAR", Color(0.04, 0.15, 0.18, 0.90), Color(0.0, 1.0, 0.82))
	_draw_big_button(deck_rect, "DECK (%d)" % _deck_total_cards(), Color(0.05, 0.10, 0.16, 0.90), Color(0.44, 0.84, 1.0))
	_draw_big_button(settings_rect, "CONFIGURACOES", Color(0.04, 0.15, 0.18, 0.90), Color(1.0, 0.8, 0.2))
	_draw_big_button(menu_rect, "MENU INICIAL", Color(0.12, 0.05, 0.08, 0.90), Color(1.0, 0.22, 0.44))


func _draw_pause_deck(viewport: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, 0.66), true)
	var portrait = _is_portrait(viewport)
	var panel = Rect2(viewport.x * 0.08 if not portrait else viewport.x * 0.05, viewport.y * 0.08, viewport.x * 0.84 if not portrait else viewport.x * 0.90, viewport.y * 0.80)
	_draw_holo_panel(panel, Color(0.44, 0.84, 1.0), true, 0.84)
	_draw_glitch_title("DECK", Vector2(viewport.x * 0.5, panel.position.y + 44), 34 if not portrait else 30, Color(0.44, 0.84, 1.0))
	_draw_centered("TOTAL DE CARTAS: %d" % _deck_total_cards(), Vector2(viewport.x * 0.5, panel.position.y + 84), 18, Color.WHITE)

	var owned = _owned_deck_cards()
	if owned.is_empty():
		_draw_centered("Nenhuma carta comprada nesta run.", panel.get_center(), 18, Color(0.72, 0.88, 0.94))
	else:
		_clamp_deck_selection(owned.size())
		var center = Vector2(viewport.x * 0.5, panel.position.y + (245.0 if not portrait else 260.0))
		var spacing = _deck_carousel_spacing(viewport)
		var card_w = 154.0 if not portrait else min(160.0, viewport.x * 0.34)
		var card_h = 214.0 if not portrait else 224.0
		for i in range(owned.size()):
			var diff = _carousel_diff(float(i), deck_scroll_pos, owned.size())
			if abs(diff) > 2.15:
				continue
			var selected = abs(diff) < 0.45
			var scale = clamp(1.0 - abs(diff) * 0.16, 0.66, 1.0)
			var rect = Rect2(center.x + diff * spacing - card_w * scale * 0.5, center.y - card_h * scale * 0.5 + abs(diff) * 18.0, card_w * scale, card_h * scale)
			var alpha = clamp(1.0 - abs(diff) * 0.26, 0.36, 1.0)
			_draw_card_surface(owned[i]["card"], rect, selected, alpha, int(owned[i]["count"]))

		var selected_entry: Dictionary = owned[deck_selected]
		var detail = Rect2(panel.position.x + 26.0, panel.end.y - 154.0, panel.size.x - 52.0, 84.0)
		_draw_card_detail_panel(selected_entry["card"], detail, int(selected_entry["count"]), true)

	var back_rect = Rect2(panel.get_center().x - 112.0, panel.end.y - 50.0, 224.0, 36.0)
	buttons["pause_deck_back"] = back_rect
	_draw_small_rect_button(back_rect, "VOLTAR", Color(0.03, 0.10, 0.14, 0.90), Color(0.44, 0.84, 1.0))


func _deck_total_cards() -> int:
	var total = 0
	for card_name in cards_bought.keys():
		total += int(cards_bought.get(card_name, 0))
	return total


func _owned_deck_cards() -> Array:
	var owned = []
	for card in CARDS:
		var count = int(cards_bought.get(card["name"], 0))
		if count > 0:
			owned.append({"card": card, "count": count})
	return owned


func _clamp_deck_selection(count: int) -> void:
	if count <= 0:
		deck_selected = 0
		deck_scroll_pos = 0.0
		return
	deck_selected = clamp(deck_selected, 0, count - 1)
	deck_scroll_pos = clamp(deck_scroll_pos, 0.0, float(count - 1))


func _deck_carousel_spacing(viewport: Vector2) -> float:
	return clamp(viewport.x * (0.22 if _is_portrait(viewport) else 0.18), 130.0, 230.0)


func _carousel_diff(index: float, scroll: float, count: int) -> float:
	if count <= 0:
		return 0.0
	var diff = index - scroll
	var half = float(count) * 0.5
	if diff > half:
		diff -= float(count)
	elif diff < -half:
		diff += float(count)
	return diff


func _card_stat_chips(card_name: String) -> Array:
	match card_name:
		"Speed Boost":
			return ["+6.5% VEL"]
		"Porcao":
			return ["+45% CURA", "+HP MAX"]
		"Disparo crescente":
			return ["+10 DANO"]
		"Tempestade":
			return ["+5 DANO", "+2% CRIT"]
		"Trembo":
			return ["+1 REVIVER"]
		"Roubo de Vida":
			return ["+0.1% ROUBO"]
		"Speed Atack":
			return ["-0.026s ATK"]
		"Teleporte":
			return ["-0.30s TP"]
		"Petro":
			return ["+PETRO", "+2 DANO"]
		"Defesa":
			return ["+3.5 DEF"]
		"Sorte":
			return ["+0.3% SORTE"]
		"Poison":
			return ["+0.9% VENENO"]
		"Coletora":
			return ["+0.8% EXEC"]
		"Mercenaria":
			return ["+40 CONTRATO"]
	return ["MELHORIA"]


func _draw_card_surface(card: Dictionary, rect: Rect2, selected: bool, alpha := 1.0, count := 0) -> void:
	var color: Color = card["color"]
	var rarity_color := _card_rarity_color(card)
	var pulse = 0.5 + sin(Time.get_ticks_msec() * 0.007) * 0.5
	var bg = Color(0.025, 0.030, 0.046, 0.92 * alpha).lerp(color, 0.12 if selected else 0.05)
	draw_rect(rect, bg, true)
	if selected:
		for g in range(1, 5):
			draw_rect(rect.grow(g * (3.0 + pulse * 1.8)), Color(rarity_color.r, rarity_color.g, rarity_color.b, (0.22 + pulse * 0.10) / float(g)), false, 2)
	draw_rect(rect, Color(rarity_color.r, rarity_color.g, rarity_color.b, (0.96 if selected else 0.58) * alpha), false, 4 if selected else 2)
	var icon: Texture2D = textures.get("card_" + card["name"])
	if icon:
		_draw_texture_contain(icon, rect.grow(-8.0), Color(1.0, 1.0, 1.0, alpha))
	var rarity_badge = Rect2(rect.position + Vector2(8.0, 8.0), Vector2(56.0, 24.0))
	draw_rect(rarity_badge, Color(0.0, 0.0, 0.0, 0.74 * alpha), true)
	draw_rect(rarity_badge, Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.92 * alpha), false, 1)
	_draw_centered(_card_rarity_label(card), rarity_badge.get_center() + Vector2(0, 4), 10, rarity_color)
	draw_rect(Rect2(rect.position.x, rect.end.y - 44.0, rect.size.x, 44.0), Color(0.0, 0.0, 0.0, 0.58 * alpha), true)
	_draw_centered(String(card["nick"]).to_upper(), Vector2(rect.get_center().x, rect.end.y - 18.0), 11 if not selected else 13, Color(1.0, 1.0, 1.0, alpha))
	if count > 0:
		var badge = Rect2(rect.end.x - 44.0, rect.position.y + 8.0, 34.0, 28.0)
		draw_rect(badge, Color(0.0, 0.0, 0.0, 0.76 * alpha), true)
		draw_rect(badge, Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.92 * alpha), false, 2)
		_draw_centered("x%d" % count, badge.get_center() + Vector2(0, 5), 14, Color.WHITE)


func _draw_card_stat_chips(chips: Array, origin: Vector2, max_width: float, accent: Color, size := 13) -> float:
	var x = origin.x
	var y = origin.y
	var chip_h = max(22.0, float(size) + 10.0)
	for chip in chips:
		var text = String(chip)
		var chip_w = clamp(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 22.0, 58.0, max_width)
		if x + chip_w > origin.x + max_width:
			x = origin.x
			y += chip_h + 6.0
		var rect = Rect2(x, y, chip_w, chip_h)
		draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.18), true)
		draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.82), false, 1)
		_draw_centered(text, rect.get_center() + Vector2(0, float(size) * 0.16), size, Color.WHITE)
		x += chip_w + 8.0
	return y + chip_h + 2.0 - origin.y


func _draw_card_detail_panel(card: Dictionary, rect: Rect2, owned_count := 0, compact := false) -> void:
	var color: Color = card["color"]
	var rarity_color := _card_rarity_color(card)
	draw_rect(rect, Color(0.02, 0.025, 0.040, 0.92), true)
	draw_rect(rect, Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.78), false, 2)
	draw_string(font, rect.position + Vector2(18, 26), String(card["name"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18 if compact else 22, color)
	var count_text = "x%d NO DECK" % owned_count if owned_count > 0 else "AINDA NAO POSSUI"
	draw_string(font, rect.position + Vector2(18, 48), "%s | %s" % [_card_rarity_label(card), count_text], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, rarity_color)
	_draw_card_stat_chips(_card_stat_chips(String(card["name"])), rect.position + Vector2(rect.size.x * 0.42, 17.0), rect.size.x * 0.54, color, 12)
	var desc_y = 60.0 if compact else 72.0
	var desc_rect = Rect2(rect.position + Vector2(18, desc_y), Vector2(rect.size.x - 36, max(24.0, rect.size.y - desc_y - 10.0)))
	if not compact:
		_draw_wrapped(String(card["desc"]), desc_rect, 13, Color(0.84, 0.88, 0.92))


func _shop_round_button_radius(viewport: Vector2) -> float:
	return 32.0 if not _is_portrait(viewport) else 28.0


func _shop_reroll_center(viewport: Vector2) -> Vector2:
	return Vector2(viewport.x * (0.09 if not _is_portrait(viewport) else 0.13), 58.0 if not _is_portrait(viewport) else 76.0)


func _shop_deck_center(viewport: Vector2) -> Vector2:
	return Vector2(viewport.x * (0.91 if not _is_portrait(viewport) else 0.87), 58.0 if not _is_portrait(viewport) else 76.0)


func _draw_shop_round_button(center: Vector2, radius: float, label: String, accent: Color, enabled: bool, kind: String) -> void:
	var alpha = 1.0 if enabled else 0.42
	draw_circle(center, radius + 7.0, Color(accent.r, accent.g, accent.b, 0.10 * alpha))
	draw_circle(center, radius, Color(0.015, 0.025, 0.040, 0.92 * alpha))
	draw_arc(center, radius, 0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.92 * alpha), 2.4)
	if kind == "reroll":
		var rot = time_alive * 3.2
		for i in range(2):
			var start = rot + i * PI
			draw_arc(center, radius * 0.48, start, start + PI * 0.74, 24, Color.WHITE, 2.8)
			var tip = center + Vector2.from_angle(start + PI * 0.74) * radius * 0.48
			var side = Vector2.from_angle(start + PI * 0.74 + PI * 0.68)
			var tri = PackedVector2Array([tip, tip - Vector2.from_angle(start + PI * 0.74) * 8.0 + side * 4.0, tip - Vector2.from_angle(start + PI * 0.74) * 8.0 - side * 4.0])
			draw_polygon(tri, PackedColorArray([Color.WHITE]))
		_draw_centered(str(shop_rerolls), center + Vector2(0, 5), 13, accent if enabled else Color(0.6, 0.6, 0.6))
	else:
		var w = radius * 0.72
		var h = radius * 0.92
		for offset in [-7.0, 0.0, 7.0]:
			var rect = Rect2(center.x - w * 0.5 + offset, center.y - h * 0.5 - abs(offset) * 0.25, w, h)
			draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.16 * alpha), true)
			draw_rect(rect, Color.WHITE, false, 1)
	_draw_centered(label, center + Vector2(0, radius + 18.0), 10, Color(0.82, 0.92, 0.96, alpha))


func _draw_end_overlay(viewport: Vector2, title: String, color: Color) -> void:
	if title == "GAME OVER":
		_draw_game_over_overlay(viewport)
		return
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, 0.64), true)
	var portrait = _is_portrait(viewport)
	var panel = Rect2(viewport.x * 0.18 if not portrait else viewport.x * 0.08, viewport.y * 0.22, viewport.x * 0.64 if not portrait else viewport.x * 0.84, viewport.y * 0.56)
	_draw_holo_panel(panel, color, true, 0.82)
	_draw_glitch_title(title, Vector2(viewport.x * 0.5, panel.position.y + panel.size.y * 0.28), 36 if not portrait else 46, color)
	_draw_centered("Pontuacao %d" % score_total, Vector2(viewport.x * 0.5, panel.position.y + panel.size.y * 0.52), 22 if not portrait else 28, Color.WHITE)
	var btn_w = 260.0 if not portrait else 340.0
	var btn_h = 52.0 if not portrait else 68.0
	_draw_big_button(Rect2(viewport.x * 0.5 - btn_w * 0.5, panel.end.y - btn_h - 24, btn_w, btn_h), "MENU", Color(0.04, 0.13, 0.17, 0.92), Color(0.0, 1.0, 0.82))
	buttons["end_menu"] = Rect2(viewport.x * 0.5 - btn_w * 0.5, panel.end.y - btn_h - 24, btn_w, btn_h)


func _draw_game_over_overlay(viewport: Vector2) -> void:
	var t = float(Time.get_ticks_msec()) * 0.001
	var end_buttons = _game_over_button_layout(viewport)
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.015, 0.010, 0.020, 0.88), true)
	for gx in range(0, int(viewport.x) + 80, 80):
		for gy in range(0, int(viewport.y) + 80, 80):
			draw_circle(Vector2(gx, gy), 1.2, Color(1.0, 0.10, 0.28, 0.13))

	var center = viewport * 0.5
	var crack = PackedVector2Array()
	var crack_w = min(viewport.x * 0.62, 720.0)
	for i in range(18):
		var k = float(i) / 17.0
		var x = center.x - crack_w * 0.5 + crack_w * k
		var y = center.y - 58.0 + (k - 0.5) * 150.0 + sin(t * 6.0 + i * 1.77) * (10.0 + float(i % 3) * 7.0)
		crack.append(Vector2(x, y))
	for width_alpha in [[14.0, 0.08], [8.0, 0.18], [4.0, 0.52], [1.6, 0.94]]:
		var c = Color(1.0, 0.18, 0.42, float(width_alpha[1]))
		if float(width_alpha[0]) <= 4.0:
			c = Color(0.35, 1.0, 0.88, float(width_alpha[1]))
		draw_polyline(crack, c, float(width_alpha[0]), false)

	for i in range(38):
		var seed = float(i) * 19.17
		var x = fposmod(seed * 31.0 + sin(t * 0.8 + seed) * 140.0, viewport.x + 80.0) - 40.0
		var y = fposmod(viewport.y - t * (24.0 + float(i % 5) * 7.0) + seed * 23.0, viewport.y + 80.0) - 40.0
		var sz = 4.0 + float(i % 5)
		var rot = t * (0.8 + float(i % 4) * 0.22) + seed
		var shard = PackedVector2Array([
			Vector2(x, y) + Vector2.from_angle(rot) * sz,
			Vector2(x, y) + Vector2.from_angle(rot + TAU / 3.0) * sz,
			Vector2(x, y) + Vector2.from_angle(rot + TAU * 2.0 / 3.0) * sz
		])
		var sc = [Color(0.0, 1.0, 0.82, 0.30), Color(0.70, 0.34, 1.0, 0.28), Color(1.0, 0.12, 0.34, 0.30)][i % 3]
		draw_polygon(shard, PackedColorArray([sc]))

	var glitch = 3.0 if int(Time.get_ticks_msec() / 90) % 7 == 0 else 1.0
	_draw_centered("FLUXO TEMPORAL ROMPIDO", Vector2(center.x - glitch, viewport.y * 0.20), 42 if not _is_portrait(viewport) else 34, Color(0.0, 1.0, 0.82, 0.78))
	_draw_centered("FLUXO TEMPORAL ROMPIDO", Vector2(center.x + glitch, viewport.y * 0.20), 42 if not _is_portrait(viewport) else 34, Color(1.0, 0.0, 0.45, 0.78))
	_draw_centered_outlined("FLUXO TEMPORAL ROMPIDO", Vector2(center.x, viewport.y * 0.20), 42 if not _is_portrait(viewport) else 34, Color.WHITE, Color(0, 0, 0, 0.9), 3)
	_draw_centered("A fenda colapsou o espaco-tempo. Sua jornada foi fragmentada.", Vector2(center.x, viewport.y * 0.29), 18 if not _is_portrait(viewport) else 14, Color(0.74, 0.76, 0.84, 0.90))
	_draw_centered("Pontuacao total: %d" % score_total, Vector2(center.x, viewport.y * 0.36), 22 if not _is_portrait(viewport) else 18, Color(1.0, 0.82, 0.30))

	var labels = [
		["end_retry", "TENTAR NOVAMENTE", Color(0.0, 1.0, 0.82)],
		["end_menu", "VOLTAR AO MENU", Color(0.72, 0.34, 1.0)],
		["end_exit", "SAIR", Color(1.0, 0.22, 0.28)]
	]
	for i in range(labels.size()):
		var rect: Rect2 = end_buttons[String(labels[i][0])]
		buttons[String(labels[i][0])] = rect
		var accent: Color = labels[i][2]
		var pulse = 0.18 + 0.08 * sin(t * 4.0 + i)
		_draw_holo_panel(rect, accent, false, 0.68)
		draw_rect(rect.grow(-8), Color(0.02, 0.014, 0.025, 0.54 + pulse), true)
		_draw_centered(String(labels[i][1]), rect.get_center() + Vector2(0, 4), 19 if not _is_portrait(viewport) else 17, Color.WHITE)


func _game_over_button_layout(viewport: Vector2) -> Dictionary:
	var center = viewport * 0.5
	var btn_w = min(350.0, viewport.x * 0.72)
	var btn_h = 54.0 if not _is_portrait(viewport) else 58.0
	var gap = 14.0
	var start_y = viewport.y * 0.48
	var rects = {}
	rects["end_retry"] = Rect2(center.x - btn_w * 0.5, start_y, btn_w, btn_h)
	rects["end_menu"] = Rect2(center.x - btn_w * 0.5, start_y + btn_h + gap, btn_w, btn_h)
	rects["end_exit"] = Rect2(center.x - btn_w * 0.5, start_y + (btn_h + gap) * 2.0, btn_w, btn_h)
	return rects


func _draw_shop_countdown_alert(viewport: Vector2) -> void:
	var portrait = _is_portrait(viewport)
	var center = Vector2(viewport.x * 0.5, viewport.y * (0.17 if portrait else 0.18) + 20.0)
	var seconds_left = _shop_countdown_visible_second()
	var slow_phase = forced_shop_timer <= FORCED_SHOP_SLOW_START
	var danger = clamp(1.0 - forced_shop_timer / FORCED_SHOP_WARNING, 0.0, 1.0)
	var pulse = 1.0 + sin(Time.get_ticks_msec() * (0.008 if slow_phase else 0.006)) * (0.035 if slow_phase else 0.025)
	var base_size = 70 if not portrait else 62
	var number_size = int(base_size * pulse)
	var number_color = Color(1.0, lerp(0.68, 0.04, danger), lerp(0.44, 0.02, danger))
	_draw_centered_outlined(str(seconds_left), center, number_size, number_color, Color(0.0, 0.0, 0.0, 1.0), 6)
	var label_y = center.y + (46.0 if portrait else 52.0)
	_draw_centered_outlined("Loja abre em", Vector2(center.x, label_y), 10 if portrait else 11, Color(1.0, 0.86, 0.80, 0.90), Color(0.0, 0.0, 0.0, 0.88), 2)


func _draw_big_button(rect: Rect2, label: String, bg: Color, border: Color) -> void:
	_draw_holo_panel(rect, border, false, max(0.56, bg.a))
	draw_rect(rect.grow(-9), Color(bg.r, bg.g, bg.b, 0.42), true)

	# Determinar tamanho de fonte dinÃ¢mico para caber perfeitamente no botÃ£o
	var font_size = int(rect.size.y * 0.45)
	var text_size = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	while text_size.x > rect.size.x - 24 and font_size > 12:
		font_size -= 1
		text_size = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

	# Ajuste fino vertical para alinhar a baseline no centro da caixa
	var y_offset = text_size.y * 0.16
	_draw_centered(label, rect.get_center() + Vector2(0, y_offset), font_size, Color.WHITE)


func _draw_combat_panel(rect: Rect2, accent: Color, alpha := 0.58) -> void:
	draw_rect(rect, Color(0.010, 0.018, 0.026, alpha), true)
	draw_rect(rect.grow(-3), Color(1.0, 1.0, 1.0, 0.035), false, 1)
	draw_line(rect.position + Vector2(0, rect.size.y), rect.position + Vector2(rect.size.x * 0.45, rect.size.y), Color(accent.r, accent.g, accent.b, 0.72), 2)
	draw_line(rect.position, rect.position + Vector2(rect.size.x * 0.28, 0), Color(accent.r, accent.g, accent.b, 0.56), 2)
	draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.18), false, 1)


func _draw_hud_bar(pos: Vector2, width: float, height: float, ratio: float, color: Color) -> void:
	ratio = clamp(ratio, 0.0, 1.0)
	var rect = Rect2(pos, Vector2(width, height))
	draw_rect(rect, Color(0.02, 0.03, 0.04, 0.86), true)
	draw_rect(Rect2(pos, Vector2(width * ratio, height)), Color(color.r, color.g, color.b, 0.94), true)
	draw_line(pos + Vector2(0, height + 3), pos + Vector2(width * ratio, height + 3), Color(color.r, color.g, color.b, 0.50), 2)


func _draw_virtual_stick(center: Vector2, radius: float) -> void:
	var accent = Color(0.0, 1.0, 0.82)
	draw_circle(center, radius, Color(0.0, 0.72, 0.72, 0.055))
	draw_arc(center, radius, -PI * 0.82, PI * 0.82, 42, Color(accent.r, accent.g, accent.b, 0.72), 2.3)
	draw_arc(center, radius * 0.70, PI * 0.18, PI * 1.32, 34, Color(1.0, 1.0, 1.0, 0.22), 1.4)
	for i in range(4):
		var a = i * PI * 0.5 + PI * 0.25
		draw_line(center + Vector2.from_angle(a) * radius * 0.78, center + Vector2.from_angle(a) * radius * 0.95, Color(accent.r, accent.g, accent.b, 0.38), 1.5)
	var knob = center + touch_move * (radius * 0.46)
	draw_circle(knob, max(18.0, radius * 0.22), Color(accent.r, accent.g, accent.b, 0.26))
	draw_circle(knob, max(9.0, radius * 0.11), Color(accent.r, accent.g, accent.b, 0.62))
	draw_arc(knob, max(22.0, radius * 0.27), 0, TAU, 34, Color(1.0, 1.0, 1.0, 0.38), 1.5)


func _draw_button(center: Vector2, radius: float, label: String, color: Color) -> void:
	var c = color
	draw_circle(center, radius, Color(0.02, 0.03, 0.04, 0.30))
	draw_circle(center, radius * 0.84, Color(c.r, c.g, c.b, 0.12))
	draw_arc(center, radius, -PI * 0.28, PI * 1.24, 48, Color(c.r, c.g, c.b, 0.78), 2.6)
	draw_arc(center, radius * 0.72, PI * 0.58, PI * 1.66, 32, Color(1.0, 1.0, 1.0, 0.34), 1.4)
	draw_circle(center, radius * 0.34, Color(c.r, c.g, c.b, 0.16))
	var font_size = int(clamp(radius * 0.34, 15.0, 22.0))
	_draw_centered(label, center + Vector2(0, font_size * 0.30), font_size, Color.WHITE)


func _draw_attack_target_marker(center: Vector2, radius: float, confirmed: bool) -> void:
	var pulse = 1.0 + sin(time_alive * 7.0) * 0.07
	var color = Color(1.0, 0.84, 0.12, 0.92 if confirmed else 0.76)
	draw_set_transform(center, 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, radius * pulse, Color(1.0, 0.76, 0.08, 0.10))
	draw_arc(Vector2.ZERO, radius * pulse, 0.0, TAU, 48, color, 3.0)
	draw_arc(Vector2.ZERO, radius * 0.72, -PI * 0.15, PI * 0.55, 20, Color(1.0, 0.96, 0.48, 0.82), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _attack_lock_preview_screen(viewport: Vector2) -> Vector2:
	var camera = _camera(viewport)
	if attack_lock_candidate_kind == "enemy":
		var enemy = _enemy_by_uid(attack_lock_candidate_uid)
		if enemy:
			return Vector2(enemy["pos"]) - camera
	elif attack_lock_candidate_kind == "boss" and boss_active and boss_hp > 0.0:
		return boss_pos - camera
	var drag = attack_touch_pos - attack_drag_start_pos
	if drag.length() < ATTACK_LOCK_MIN_DRAG:
		return player_pos - camera
	var reach = clamp(drag.length() * 2.2, 90.0, min(viewport.x, viewport.y) * 0.72)
	return (player_pos - camera + drag.normalized() * reach).clamp(Vector2(24, 24), viewport - Vector2(24, 24))


func _draw_attack_lock_preview(viewport: Vector2) -> void:
	var center = _attack_lock_preview_screen(viewport)
	var has_candidate = not attack_lock_candidate_kind.is_empty()
	var color = Color(1.0, 0.86, 0.18, 0.96) if has_candidate else Color(1.0, 0.34, 0.24, 0.72)
	var radius = 24.0 + sin(time_alive * 8.0) * 2.0
	draw_circle(center, radius, Color(color.r, color.g, color.b, 0.08))
	draw_arc(center, radius, 0.0, TAU, 36, color, 2.5)
	draw_line(center + Vector2(-radius - 8, 0), center + Vector2(-8, 0), color, 2.0)
	draw_line(center + Vector2(radius + 8, 0), center + Vector2(8, 0), color, 2.0)
	draw_line(center + Vector2(0, -radius - 8), center + Vector2(0, -8), color, 2.0)
	draw_line(center + Vector2(0, radius + 8), center + Vector2(0, 8), color, 2.0)


func _ability_cancel_center(viewport: Vector2) -> Vector2:
	return Vector2(viewport.x * (0.84 if _is_portrait(viewport) else 0.88), viewport.y * 0.30)


func _ability_cancel_active() -> bool:
	return skill_touch_index != -1 or secondary_touch_index != -1 or dash_touch_index != -1


func _ability_cancel_has_point(pos: Vector2, viewport: Vector2) -> bool:
	return pos.distance_to(_ability_cancel_center(viewport)) <= ABILITY_CANCEL_RADIUS


func _active_ability_touch_pos() -> Vector2:
	if skill_touch_index != -1:
		return skill_touch_pos
	if secondary_touch_index != -1:
		return secondary_touch_pos
	return teleport_drag_screen


func _draw_ability_cancel_button(viewport: Vector2) -> void:
	var center = _ability_cancel_center(viewport)
	var hovered = _ability_cancel_has_point(_active_ability_touch_pos(), viewport)
	var pulse = 1.0 + sin(time_alive * 9.0) * (0.06 if hovered else 0.025)
	var radius = ABILITY_CANCEL_RADIUS * pulse
	draw_circle(center, radius, Color(0.22, 0.01, 0.02, 0.84))
	draw_circle(center, radius * 0.78, Color(1.0, 0.06, 0.10, 0.34 if hovered else 0.18))
	draw_arc(center, radius, 0.0, TAU, 48, Color(1.0, 0.16, 0.18, 1.0), 4.0 if hovered else 2.5)
	var arm = radius * 0.30
	draw_line(center + Vector2(-arm, -arm), center + Vector2(arm, arm), Color.WHITE, 6.0, true)
	draw_line(center + Vector2(arm, -arm), center + Vector2(-arm, arm), Color.WHITE, 6.0, true)


func _draw_hud_rect_button(rect: Rect2, label: String, accent: Color) -> void:
	draw_rect(rect, Color(0.012, 0.020, 0.028, 0.64), true)
	draw_rect(rect.grow(-4), Color(accent.r, accent.g, accent.b, 0.12), true)
	draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.82), false, 2)
	draw_line(rect.position + Vector2(8, rect.size.y - 6), rect.position + Vector2(rect.size.x - 8, rect.size.y - 6), Color(accent.r, accent.g, accent.b, 0.42), 2)
	_draw_centered(label, rect.get_center() + Vector2(0, 6), int(clamp(rect.size.y * 0.38, 13.0, 18.0)), Color.WHITE)


func _draw_small_rect_button(rect: Rect2, label: String, bg := Color(0.03, 0.10, 0.12), border := Color(0.0, 1.0, 0.82)) -> void:
	draw_rect(rect, bg, true)
	draw_rect(rect, border, false, 2)
	var font_size = int(rect.size.y * 0.40)
	var text_size = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	while text_size.x > rect.size.x - 12 and font_size > 10:
		font_size -= 1
		text_size = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var y_offset = text_size.y * 0.16
	_draw_centered(label, rect.get_center() + Vector2(0, y_offset), font_size, Color.WHITE)


func _draw_toggle_switch(rect: Rect2, enabled: bool, accent: Color) -> void:
	var track = accent if enabled else Color(0.28, 0.32, 0.36)
	draw_rect(rect, Color(track.r, track.g, track.b, 0.30), true)
	draw_rect(rect, Color(track.r, track.g, track.b, 0.92), false, 2.0)
	var knob_radius = rect.size.y * 0.34
	var knob_x = rect.end.x - rect.size.y * 0.5 if enabled else rect.position.x + rect.size.y * 0.5
	draw_circle(Vector2(knob_x, rect.get_center().y), knob_radius, Color.WHITE)


func _draw_dynamic_shadow(texture: Texture2D, center: Vector2, size: Vector2, flip_h := false, alpha := 0.42) -> void:
	if not gfx_shadows or texture == null or alpha <= 0.0:
		return
	var foot = center + Vector2(0.0, size.y * 0.50)
	var light_sway = sin(time_alive * 0.72) * 2.0
	var cast_rotation = deg_to_rad(9.0) + sin(time_alive * 0.45) * 0.018
	var horizontal = -1.0 if flip_h else 1.0
	var rect = Rect2(Vector2(-size.x * 0.5, -size.y), size)
	draw_set_transform(foot + Vector2(10.0 + light_sway, 5.0), cast_rotation, Vector2(horizontal * 1.03, -0.30))
	draw_texture_rect(texture, rect, false, Color(0.0, 0.0, 0.0, alpha * 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_set_transform(foot + Vector2(6.0 + light_sway * 0.45, 2.0), cast_rotation, Vector2(horizontal, -0.27))
	draw_texture_rect(texture, rect, false, Color(0.0, 0.0, 0.0, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_dynamic_shadow_fit(texture: Texture2D, center: Vector2, max_size: Vector2, flip_h := false, align_bottom := false, alpha := 0.42) -> void:
	if not gfx_shadows or texture == null:
		return
	var texture_size = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var fit_scale = min(max_size.x / texture_size.x, max_size.y / texture_size.y)
	var draw_size = texture_size * fit_scale
	var visual_center = center
	if align_bottom:
		var top = center.y + max_size.y * 0.5 - draw_size.y
		visual_center.y = top + draw_size.y * 0.5
	_draw_dynamic_shadow(texture, visual_center, draw_size, flip_h, alpha)


func _draw_entity(texture: Texture2D, center: Vector2, size: Vector2, modulate := Color.WHITE, flip_h := false) -> void:
	if texture:
		draw_set_transform(center, 0.0, Vector2(-1.0, 1.0) if flip_h else Vector2.ONE)
		draw_texture_rect(texture, Rect2(-size * 0.5, size), false, modulate)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_circle(center, min(size.x, size.y) * 0.34, Color(1.0, 0.2, 0.4))


func _draw_entity_fit(texture: Texture2D, center: Vector2, max_size: Vector2, modulate := Color.WHITE, align_bottom := false) -> void:
	if texture == null:
		draw_circle(center, min(max_size.x, max_size.y) * 0.34, Color(1.0, 0.2, 0.4))
		return
	var tex_size = texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		_draw_entity(texture, center, max_size, modulate)
		return
	var scale = min(max_size.x / tex_size.x, max_size.y / tex_size.y)
	var draw_size = tex_size * scale
	var pos = center - draw_size * 0.5
	if align_bottom:
		pos.y = center.y + max_size.y * 0.5 - draw_size.y
	draw_texture_rect(texture, Rect2(pos, draw_size), false, modulate)


func _draw_entity_fit_rotated(texture: Texture2D, center: Vector2, max_size: Vector2, rotation: float, modulate := Color.WHITE, align_bottom := false) -> void:
	draw_set_transform(center, rotation, Vector2.ONE)
	_draw_entity_fit(texture, Vector2.ZERO, max_size, modulate, align_bottom)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_entity_stretched_rotated(texture: Texture2D, center: Vector2, draw_size: Vector2, rotation: float, modulate := Color.WHITE, flip_h := false) -> void:
	if texture == null:
		return
	draw_set_transform(center, rotation, Vector2(-1.0, 1.0) if flip_h else Vector2.ONE)
	var pos = Vector2(-draw_size.x * 0.5, PLAYER_DRAW_BOX_SIZE.y * 0.5 - draw_size.y)
	draw_texture_rect(texture, Rect2(pos, draw_size), false, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_entity_by_height_rotated(texture: Texture2D, center: Vector2, target_height: float, rotation: float, modulate := Color.WHITE, flip_h := false) -> void:
	if texture == null:
		return
	var tex_size = texture.get_size()
	if tex_size.y <= 0.0:
		return
	var scale = target_height / tex_size.y
	var draw_size = tex_size * scale
	draw_set_transform(center, rotation, Vector2(-1.0, 1.0) if flip_h else Vector2.ONE)
	var pos = Vector2(-draw_size.x * 0.5, PLAYER_DRAW_BOX_SIZE.y * 0.5 - draw_size.y)
	draw_texture_rect(texture, Rect2(pos, draw_size), false, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_hex(center: Vector2, radius: float, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(6):
		var a = i * TAU / 6.0 + time_alive * 0.5
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	points.append(points[0])
	draw_polyline(points, color, 3.0, true)


func _draw_bar(pos: Vector2, width: float, ratio: float, color: Color) -> void:
	ratio = clamp(ratio, 0.0, 1.0)
	draw_rect(Rect2(pos, Vector2(width, 7)), Color(0.05, 0.05, 0.07, 0.9), true)
	draw_rect(Rect2(pos, Vector2(width * ratio, 7)), color, true)


func _draw_centered(text: String, pos: Vector2, size: int, color: Color) -> void:
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	draw_string(font, pos - Vector2(text_size.x * 0.5, text_size.y * 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw_centered_outlined(text: String, pos: Vector2, size: int, color: Color, outline: Color, thickness: int) -> void:
	var offsets = [
		Vector2(-thickness, 0),
		Vector2(thickness, 0),
		Vector2(0, -thickness),
		Vector2(0, thickness),
		Vector2(-thickness, -thickness),
		Vector2(thickness, -thickness),
		Vector2(-thickness, thickness),
		Vector2(thickness, thickness)
	]
	for offset in offsets:
		_draw_centered(text, pos + offset, size, outline)
	_draw_centered(text, pos + Vector2(0, thickness * 0.45), size, Color(0.0, 0.0, 0.0, min(0.55, outline.a)))
	_draw_centered(text, pos, size, color)


func _draw_wrapped(text: String, rect: Rect2, size: int, color: Color) -> void:
	var words = text.split(" ")
	var line = ""
	var y = rect.position.y + size
	for word in words:
		var test = line + (" " if line != "" else "") + word
		if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > rect.size.x and line != "":
			draw_string(font, Vector2(rect.position.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
			line = word
			y += size + 4
			if y > rect.end.y:
				return
		else:
			line = test
	if line != "" and y <= rect.end.y:
		draw_string(font, Vector2(rect.position.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _player_texture() -> Texture2D:
	var move = _read_move()
	if time_alive - last_damage_time < 0.35:
		return _frame_texture_relative("player_damage", time_alive - last_damage_time, 70, "player_idle")
	if lacerante_preparing and manifestation_key == "lacerante" and move.length() <= 0.12:
		return _lacerante_prepare_texture()
	if time_alive - last_attack_time < 0.50:
		if manifestation_key == "lacerante":
			return _lacerante_combo_texture(time_alive - last_attack_time)
		if not _player_is_moving_for_animation():
			return _frame_texture_relative("player_fire", time_alive - last_attack_time, 70, "player_idle")
	var idle_speed = 115 if time_alive - last_attack_time < 0.65 or time_alive - last_dash_time < 1.0 else 175
	if move.y < -0.1:
		return _frame_texture("player_up", 120, "player_idle")
	if move.y > 0.1:
		return _frame_texture("player_down", 120, "player_idle")
	if move.x > 0.1:
		return _frame_texture("player_right", 105, "player_idle")
	if move.x < -0.1:
		return _frame_texture("player_right", 105, "player_idle")
	return _frame_texture("player_idle", idle_speed, "player_fire")


func _frame_texture(key: String, period_ms: int, fallback_key: String) -> Texture2D:
	var frames: Array = textures.get(key, [])
	if frames.is_empty():
		frames = textures.get(fallback_key, [])
	if frames.is_empty():
		return null
	var idx = int(Time.get_ticks_msec() / max(1, period_ms)) % frames.size()
	return frames[idx]


func _frame_texture_relative(key: String, elapsed_time: float, period_ms: int, fallback_key: String) -> Texture2D:
	var frames: Array = textures.get(key, [])
	if frames.is_empty():
		frames = textures.get(fallback_key, [])
	if frames.is_empty():
		return null
	var elapsed_ms = int(elapsed_time * 1000.0)
	var idx = int(elapsed_ms / max(1, period_ms)) % frames.size()
	return frames[idx]


func _lacerante_combo_texture(elapsed: float) -> Texture2D:
	var all_frames: Array = textures.get("player_lacerar", [])
	if all_frames.size() < 6:
		return _frame_texture_relative("player_lacerar", elapsed, 85, "player_fire")
	var combo_idx = posmod(int(lacerante_combo_visual), 3)
	var base_idx = combo_idx * 2
	var frame_a: Texture2D = all_frames[base_idx]
	var frame_b: Texture2D = all_frames[base_idx + 1]
	var elapsed_ms = int(elapsed * 1000.0)
	if elapsed_ms < 120:
		return frame_a
	return frame_b


func _lacerante_prepare_texture() -> Texture2D:
	var all_frames: Array = textures.get("player_lacerar", [])
	if all_frames.size() < 6:
		return _frame_texture_relative("player_lacerar", lacerante_prepare_timer, 85, "player_fire")
	var combo_idx = posmod(int(lacerante_prepare_stage), 3)
	var frame_idx = combo_idx * 2 + clamp(lacerante_prepare_frame, 0, 1)
	return all_frames[frame_idx]


func _camera(viewport: Vector2) -> Vector2:
	var camera = player_pos - viewport * 0.5
	return camera.clamp(Vector2.ZERO, WORLD_SIZE - viewport)


func _update_button_layout(viewport: Vector2) -> void:
	var atk_r = 62.0 * _attack_scale()
	buttons["attack"] = Rect2(_attack_center(viewport) - Vector2(atk_r, atk_r), Vector2(atk_r * 2.0, atk_r * 2.0))
	var skill_r = 46.0 * _skill_scale()
	buttons["skill"] = Rect2(_skill_pos(viewport), Vector2(skill_r * 2.0, skill_r * 2.0))
	var secondary_r = 48.0 * _secondary_scale()
	buttons["secondary"] = Rect2(_secondary_center(viewport) - Vector2(secondary_r, secondary_r), Vector2(secondary_r * 2.0, secondary_r * 2.0))
	var dash_r = 52.0 * _dash_scale()
	buttons["dash"] = Rect2(_dash_center(viewport) - Vector2(dash_r, dash_r), Vector2(dash_r * 2.0, dash_r * 2.0))
	buttons["pause"] = Rect2(_pause_pos(viewport), Vector2(52, 42))
	buttons["boss"] = Rect2(_boss_call_pos(viewport), Vector2(96, 42))
	if shop_auto_enabled:
		buttons.erase("shop_manual")
	else:
		buttons["shop_manual"] = Rect2(_manual_shop_pos(viewport), Vector2(104, 42))


func _unhandled_input(event: InputEvent) -> void:
	var viewport = get_viewport_rect().size
	_update_button_layout(viewport)
	if not boss1_rewind_sequence.is_empty():
		return
	if event is InputEventScreenTouch:
		ignore_mouse_until_msec = Time.get_ticks_msec() + 300
		if event.pressed:
			active_screen_touches[event.index] = true
		else:
			active_screen_touches.erase(event.index)
		if event.pressed:
			if mode != "game" and mode != "shop_countdown" and mode != "boss_call" and mode != "pause_countdown" and _ui_input_blocked():
				return
			if mode == "edit_layout":
				_handle_edit_layout_press(event.index, event.position, viewport)
				return
			if mode == "manifest":
				_start_manifest_drag(event.index, event.position, viewport)
				return
			if mode == "pause_deck":
				_start_deck_drag(event.index, event.position, viewport)
				return
			_handle_touch_press(event.index, event.position, viewport)
		else:
			if mode == "edit_layout":
				_handle_edit_layout_release(event.index, event.position, viewport)
				return
			if mode == "manifest" and event.index == manifest_drag_touch_index:
				_finish_manifest_drag(event.position, viewport)
				return
			if mode == "pause_deck" and event.index == deck_drag_touch_index:
				_finish_deck_drag(event.position, viewport)
				return
			_handle_touch_release(event.index, event.position, viewport)
	elif event is InputEventScreenDrag:
		ignore_mouse_until_msec = Time.get_ticks_msec() + 300
		active_screen_touches[event.index] = true
		if mode == "edit_layout":
			_handle_edit_layout_drag(event.index, event.position, viewport)
		elif mode == "manifest" and event.index == manifest_drag_touch_index:
			_update_manifest_drag(event.position, viewport)
		elif mode == "pause_deck" and event.index == deck_drag_touch_index:
			_update_deck_drag(event.position, viewport)
		else:
			_handle_touch_drag(event.index, event.position, viewport)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _should_ignore_emulated_mouse():
				return
			if mode != "game" and mode != "shop_countdown" and mode != "boss_call" and mode != "pause_countdown" and _ui_input_blocked():
				return
			if mode == "edit_layout":
				_handle_edit_layout_press(-2, event.position, viewport)
				return
			if mode == "manifest":
				_start_manifest_drag(-2, event.position, viewport)
				return
			if mode == "pause_deck":
				_start_deck_drag(-2, event.position, viewport)
				return
			_handle_mouse_press(event.position, viewport)
		else:
			if _should_ignore_emulated_mouse() and not _mouse_release_has_active_action():
				return
			if mode == "edit_layout":
				_handle_edit_layout_release(-2, event.position, viewport)
				return
			if mode == "manifest" and manifest_drag_touch_index == -2:
				_finish_manifest_drag(event.position, viewport)
				return
			if mode == "pause_deck" and deck_drag_touch_index == -2:
				_finish_deck_drag(event.position, viewport)
				return
			_handle_touch_release(-2, event.position, viewport)
	elif event is InputEventMouseMotion:
		if _should_ignore_emulated_mouse():
			return
		if mode == "edit_layout" and edit_layout_touch_index != -1:
			_handle_edit_layout_drag(edit_layout_touch_index, event.position, viewport)
		elif mode == "manifest" and manifest_drag_touch_index == -2:
			_update_manifest_drag(event.position, viewport)
		elif mode == "pause_deck" and deck_drag_touch_index == -2:
			_update_deck_drag(event.position, viewport)
		else:
			if move_touch_index == -2:
				touch_move = ((event.position - joystick_origin) / (76.0 * _joy_scale())).limit_length(1.0)
			if teleport_dragging:
				teleport_drag_screen = event.position
			if skill_touch_index == -2:
				skill_touch_pos = event.position
			if secondary_touch_index == -2:
				secondary_touch_pos = event.position
			if attack_holding or attack_dragging:
				attack_touch_pos = event.position
				var delta_vec = event.position - attack_drag_start_pos
				if attack_lock_selecting:
					_update_attack_lock_candidate(event.position, viewport)
				elif delta_vec.length() > 25.0:
					attack_dragging = true
				if not attack_lock_selecting and delta_vec.length() > 10.0:
					attack_drag_direction = delta_vec.normalized()
	elif event is InputEventKey and event.pressed:
		_handle_key(event)


func _should_ignore_emulated_mouse() -> bool:
	return not active_screen_touches.is_empty() or Time.get_ticks_msec() <= ignore_mouse_until_msec


func _mouse_release_has_active_action() -> bool:
	return move_touch_index == -2 or attack_drag_touch_index == -2 or skill_touch_index == -2 or secondary_touch_index == -2 or dash_touch_index == -2 or manifest_drag_touch_index == -2 or deck_drag_touch_index == -2


func _block_ui_input(duration_ms := UI_TRANSITION_BLOCK_MS) -> void:
	ui_input_block_until_msec = max(ui_input_block_until_msec, Time.get_ticks_msec() + duration_ms)


func _ui_input_blocked() -> bool:
	return Time.get_ticks_msec() <= ui_input_block_until_msec


func _sync_touch_state() -> void:
	if move_touch_index >= 0 and not active_screen_touches.has(move_touch_index):
		_stop_move_touch()
	elif move_touch_index == -2 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_stop_move_touch()
	if attack_drag_touch_index >= 0 and not active_screen_touches.has(attack_drag_touch_index):
		attack_drag_touch_index = -1
		attack_dragging = false
		attack_holding = false
		attack_hold_timer = 0.0
		attack_lock_selecting = false
		attack_lock_candidate_kind = ""
		attack_lock_candidate_uid = -1
	if skill_touch_index >= 0 and not active_screen_touches.has(skill_touch_index):
		skill_touch_index = -1
	if secondary_touch_index >= 0 and not active_screen_touches.has(secondary_touch_index):
		secondary_touch_index = -1
	if dash_touch_index >= 0 and not active_screen_touches.has(dash_touch_index):
		dash_touch_index = -1
		teleport_dragging = false
	if active_screen_touches.is_empty() and move_touch_index == -1:
		pointer_down = false


func _handle_edit_layout_press(index: int, pos: Vector2, viewport: Vector2) -> void:
	if Rect2(viewport.x * 0.5 - 150, viewport.y - 80, 300, 60).has_point(pos):
		_save_config()
		mode = "settings"
		return

	var joy = _joy_center(viewport)
	var joy_r = 76.0 * _joy_scale()
	if Rect2(joy.x - 60, joy.y + joy_r + 10, 50, 40).has_point(pos):
		hud_joy_scale = max(0.5, hud_joy_scale - 0.1)
		return
	if Rect2(joy.x + 10, joy.y + joy_r + 10, 50, 40).has_point(pos):
		hud_joy_scale = min(2.0, hud_joy_scale + 0.1)
		return
	if pos.distance_to(joy) < joy_r:
		edit_layout_selected = "joy"
		edit_layout_touch_index = index
		edit_layout_offset = hud_joy_pos - pos
		return

	var atk_c = buttons.get("attack", Rect2()).position + buttons.get("attack", Rect2()).size * 0.5
	var atk_r = 54.0 * _attack_scale()
	if Rect2(atk_c.x - 60, atk_c.y + atk_r + 10, 50, 40).has_point(pos):
		hud_attack_scale = max(0.5, hud_attack_scale - 0.1)
		return
	if Rect2(atk_c.x + 10, atk_c.y + atk_r + 10, 50, 40).has_point(pos):
		hud_attack_scale = min(2.0, hud_attack_scale + 0.1)
		return
	if pos.distance_to(atk_c) < atk_r:
		edit_layout_selected = "attack"
		edit_layout_touch_index = index
		edit_layout_offset = hud_attack_pos - pos
		return

	var secondary_c = buttons.get("secondary", Rect2()).position + buttons.get("secondary", Rect2()).size * 0.5
	var secondary_r = 43.0 * _secondary_scale()
	if Rect2(secondary_c.x - 60, secondary_c.y + secondary_r + 10, 50, 40).has_point(pos):
		hud_secondary_scale = max(0.5, hud_secondary_scale - 0.1)
		return
	if Rect2(secondary_c.x + 10, secondary_c.y + secondary_r + 10, 50, 40).has_point(pos):
		hud_secondary_scale = min(2.0, hud_secondary_scale + 0.1)
		return
	if pos.distance_to(secondary_c) < secondary_r:
		edit_layout_selected = "secondary"
		edit_layout_touch_index = index
		edit_layout_offset = hud_secondary_pos - pos
		return

	var dash_c = buttons.get("dash", Rect2()).position + buttons.get("dash", Rect2()).size * 0.5
	var dash_r = 46.0 * _dash_scale()
	if Rect2(dash_c.x - 60, dash_c.y + dash_r + 10, 50, 40).has_point(pos):
		hud_dash_scale = max(0.5, hud_dash_scale - 0.1)
		return
	if Rect2(dash_c.x + 10, dash_c.y + dash_r + 10, 50, 40).has_point(pos):
		hud_dash_scale = min(2.0, hud_dash_scale + 0.1)
		return
	if pos.distance_to(dash_c) < dash_r:
		edit_layout_selected = "dash"
		edit_layout_touch_index = index
		edit_layout_offset = hud_dash_pos - pos
		return

	var skill_r = 46.0 * _skill_scale()
	var skill_rect = Rect2(_skill_pos(viewport), Vector2(skill_r * 2.0, skill_r * 2.0))
	var skill_c = skill_rect.get_center()
	if Rect2(skill_c.x - 60, skill_c.y + skill_r + 10, 50, 40).has_point(pos):
		hud_skill_scale = max(0.5, hud_skill_scale - 0.1)
		return
	if Rect2(skill_c.x + 10, skill_c.y + skill_r + 10, 50, 40).has_point(pos):
		hud_skill_scale = min(2.0, hud_skill_scale + 0.1)
		return
	if pos.distance_to(skill_c) < skill_r:
		edit_layout_selected = "skill"
		edit_layout_touch_index = index
		edit_layout_offset = _skill_pos(viewport) - pos
		return

	var portrait = _is_portrait(viewport)
	var left_w = 236.0 if not portrait else min(236.0, viewport.x * 0.46)
	var right_w = 220.0 if not portrait else min(220.0, viewport.x * 0.44)

	var rects = {
		"left_panel": [Rect2(_left_panel_pos(viewport), Vector2(left_w, 76)), _left_panel_pos(viewport)],
		"right_panel": [Rect2(_right_panel_pos(viewport), Vector2(right_w, 76)), _right_panel_pos(viewport)],
		"boss_panel": [Rect2(_boss_panel_pos(viewport), Vector2(380, 30)), _boss_panel_pos(viewport)],
		"pause": [Rect2(_pause_pos(viewport), Vector2(52, 42)), _pause_pos(viewport)],
		"boss_call": [Rect2(_boss_call_pos(viewport), Vector2(96, 42)), _boss_call_pos(viewport)]
	}

	for key in rects:
		if rects[key][0].has_point(pos):
			edit_layout_selected = key
			edit_layout_touch_index = index
			edit_layout_offset = rects[key][1] - pos
			return

func _handle_edit_layout_drag(index: int, pos: Vector2, viewport: Vector2) -> void:
	if index != edit_layout_touch_index: return
	var target = pos + edit_layout_offset
	if edit_layout_selected == "joy":
		hud_joy_pos = target.clamp(Vector2.ZERO, viewport)
	elif edit_layout_selected == "attack":
		hud_attack_pos = target.clamp(Vector2.ZERO, viewport)
	elif edit_layout_selected == "secondary":
		hud_secondary_pos = target.clamp(Vector2.ZERO, viewport)
	elif edit_layout_selected == "dash":
		hud_dash_pos = target.clamp(Vector2.ZERO, viewport)
	elif edit_layout_selected == "left_panel": hud_left_panel_pos = target.clamp(Vector2.ZERO, viewport)
	elif edit_layout_selected == "right_panel": hud_right_panel_pos = target.clamp(Vector2.ZERO, viewport)
	elif edit_layout_selected == "boss_panel": hud_boss_panel_pos = target.clamp(Vector2.ZERO, viewport)
	elif edit_layout_selected == "skill": hud_skill_pos = target.clamp(Vector2.ZERO, viewport)
	elif edit_layout_selected == "pause": hud_pause_pos = target.clamp(Vector2.ZERO, viewport)
	elif edit_layout_selected == "boss_call": hud_boss_call_pos = target.clamp(Vector2.ZERO, viewport)

func _handle_edit_layout_release(index: int, pos: Vector2, viewport: Vector2) -> void:
	if index == edit_layout_touch_index:
		edit_layout_touch_index = -1
		edit_layout_selected = ""


func _open_edit_layout(viewport: Vector2) -> void:
	mode = "edit_layout"
	hud_joy_pos = _joy_center(viewport)
	hud_attack_pos = _attack_center(viewport)
	hud_secondary_pos = _secondary_center(viewport)
	hud_dash_pos = _dash_center(viewport)
	hud_skill_pos = _skill_pos(viewport)


func _return_from_settings() -> void:
	_save_config()
	if settings_previous_mode == "paused":
		mode = "paused"
		_block_ui_input()
	elif settings_previous_mode == "game" or settings_previous_mode == "shop_countdown" or settings_previous_mode == "boss_call":
		mode = settings_previous_mode
		_block_ui_input()
	else:
		_go_to_menu()


func _activate_settings_option(index: int, viewport: Vector2) -> void:
	match index:
		0:
			_open_edit_layout(viewport)
		1:
			mode = "settings_gameplay"
			_block_ui_input()
		2:
			mode = "settings_audio"
			_block_ui_input()
		3:
			mode = "settings_graphics"
			_block_ui_input()
		_:
			_return_from_settings()


func _handle_settings_touch(pos: Vector2, viewport: Vector2) -> void:
	settings_buttons = _settings_rects(viewport)
	if settings_buttons["controls"].has_point(pos):
		settings_selected = 0
		_activate_settings_option(0, viewport)
	elif settings_buttons["gameplay"].has_point(pos):
		settings_selected = 1
		_activate_settings_option(1, viewport)
	elif settings_buttons["audio"].has_point(pos):
		settings_selected = 2
		_activate_settings_option(2, viewport)
	elif settings_buttons["graphics"].has_point(pos):
		settings_selected = 3
		_activate_settings_option(3, viewport)
	elif settings_buttons["back"].has_point(pos):
		settings_selected = 4
		_activate_settings_option(4, viewport)


func _handle_gameplay_settings_touch(pos: Vector2, viewport: Vector2) -> void:
	settings_buttons = _gameplay_preferences_rects(viewport)
	if settings_buttons["analog"].has_point(pos):
		analog_fixed = not analog_fixed
		_save_config()
	elif settings_buttons["shop_mode"].has_point(pos):
		_set_shop_auto_enabled(not shop_auto_enabled)
		_save_config()
	elif settings_buttons["shop_interval"].has_point(pos):
		if not shop_auto_enabled:
			return
		var interval_panel: Rect2 = settings_buttons["shop_interval"]
		if _shop_interval_minus_rect(interval_panel).has_point(pos):
			shop_auto_interval = max(180.0, shop_auto_interval - 60.0)
		elif _shop_interval_plus_rect(interval_panel).has_point(pos):
			shop_auto_interval = min(480.0, shop_auto_interval + 60.0)
		else:
			return
		shop_auto_elapsed = 0.0
		next_forced_shop_time = shop_auto_interval
		_save_config()
	elif settings_buttons["target_priority"].has_point(pos):
		auto_target_priority = _next_target_priority(auto_target_priority)
		_save_config()
	elif settings_buttons["damage_text"].has_point(pos):
		var damage_panel: Rect2 = settings_buttons["damage_text"]
		if _damage_text_minus_rect(damage_panel).has_point(pos):
			damage_text_scale = max(0.7, damage_text_scale - 0.1)
			_save_config()
		elif _damage_text_plus_rect(damage_panel).has_point(pos):
			damage_text_scale = min(1.8, damage_text_scale + 0.1)
			_save_config()
	elif settings_buttons["interface_text"].has_point(pos):
		var interface_panel: Rect2 = settings_buttons["interface_text"]
		if _interface_text_minus_rect(interface_panel).has_point(pos):
			interface_text_scale = max(0.9, snapped(interface_text_scale - 0.1, 0.1))
			_save_config()
		elif _interface_text_plus_rect(interface_panel).has_point(pos):
			interface_text_scale = min(1.6, snapped(interface_text_scale + 0.1, 0.1))
			_save_config()
	elif settings_buttons["haptics"].has_point(pos):
		haptics_enabled = not haptics_enabled
		if haptics_enabled:
			_vibrate(55, 0.25)
		_save_config()
	elif settings_buttons["back"].has_point(pos):
		_save_config()
		mode = "settings"
		_block_ui_input()


func _handle_audio_settings_touch(pos: Vector2, viewport: Vector2) -> void:
	settings_buttons = _gameplay_settings_rects(viewport)
	var panel = settings_buttons["analog"]
	var y_start = panel.position.y + 40
	for i in range(3):
		var y_off = y_start + i * 50
		var bar_rect = Rect2(panel.position.x + 110, y_off, panel.size.x - 170, 26)
		if Rect2(bar_rect.position.x - 38, y_off - 4, 34, 34).has_point(pos):
			if i == 0: vol_master = max(0.0, vol_master - 0.1)
			elif i == 1: vol_music = max(0.0, vol_music - 0.1)
			elif i == 2: vol_sfx = max(0.0, vol_sfx - 0.1)
			_update_audio_volumes()
			_save_config()
			return
		if Rect2(bar_rect.end.x + 4, y_off - 4, 34, 34).has_point(pos):
			if i == 0: vol_master = min(1.0, vol_master + 0.1)
			elif i == 1: vol_music = min(1.0, vol_music + 0.1)
			elif i == 2: vol_sfx = min(1.0, vol_sfx + 0.1)
			_update_audio_volumes()
			_save_config()
			return
	if settings_buttons["back"].has_point(pos):
		_save_config()
		mode = "settings"
		_block_ui_input()


func _active_joy_center(viewport: Vector2) -> Vector2:
	if not analog_fixed and move_touch_index != -1 and joystick_origin != Vector2.ZERO:
		return joystick_origin
	return _joy_center(viewport)


func _stop_move_touch() -> void:
	move_touch_index = -1
	touch_move = Vector2.ZERO
	pointer_down = false


func _claim_action_touch(index: int) -> void:
	if move_touch_index == index:
		_stop_move_touch()
	elif index >= 0 and move_touch_index != -1 and not active_screen_touches.has(move_touch_index):
		_stop_move_touch()


func _touch_index_has_action(index: int) -> bool:
	return index == attack_drag_touch_index or index == skill_touch_index or index == secondary_touch_index or index == dash_touch_index


func _try_start_move_touch(index: int, pos: Vector2, viewport: Vector2) -> bool:
	if move_touch_index != -1 or _touch_index_has_action(index):
		return false
	var joy = _joy_center(viewport)
	var joy_radius = 116.0 * _joy_scale()
	var fixed_hit = pos.distance_to(joy) < joy_radius
	var dynamic_hit = not analog_fixed and pos.x <= viewport.x * 0.48
	if not fixed_hit and not dynamic_hit:
		return false
	move_touch_index = index
	pointer_down = true
	joystick_origin = joy if analog_fixed or fixed_hit else pos
	touch_move = ((pos - joystick_origin) / (76.0 * _joy_scale())).limit_length(1.0)
	return true


func _handle_touch_press(index: int, pos: Vector2, viewport: Vector2) -> void:
	if mode != "game" and mode != "shop_countdown" and mode != "boss_call" and mode != "pause_countdown":
		_handle_press(pos, viewport)
		return
	if buttons["attack"].has_point(pos):
		_claim_action_touch(index)
		attack_drag_touch_index = index
		attack_holding = true
		attack_hold_timer = 0.0
		attack_dragging = false
		attack_drag_start_pos = pos
		attack_touch_pos = pos
		attack_drag_direction = _aim_direction()
		_try_attack()
		return
	if buttons["skill"].has_point(pos):
		_claim_action_touch(index)
		skill_touch_index = index
		skill_touch_pos = pos
		return
	if buttons["secondary"].has_point(pos):
		_claim_action_touch(index)
		secondary_touch_index = index
		secondary_touch_pos = pos
		return
	if buttons["dash"].has_point(pos):
		_claim_action_touch(index)
		dash_touch_index = index
		teleport_dragging = true
		teleport_drag_origin = pos
		teleport_drag_screen = pos
		return
	if buttons["pause"].has_point(pos):
		_start_pause_countdown()
		return
	if buttons.has("shop_manual") and buttons["shop_manual"].has_point(pos):
		_try_open_manual_shop()
		return
	if buttons["boss"].has_point(pos):
		_start_boss_call()
		return
	_try_start_move_touch(index, pos, viewport)


func _handle_touch_drag(index: int, pos: Vector2, viewport: Vector2) -> void:
	if index == attack_drag_touch_index:
		attack_touch_pos = pos
		var delta_vec = pos - attack_drag_start_pos
		if attack_lock_selecting:
			_update_attack_lock_candidate(pos, viewport)
		elif delta_vec.length() > 25.0:
			attack_dragging = true
		if not attack_lock_selecting and delta_vec.length() > 10.0:
			attack_drag_direction = delta_vec.normalized()
	elif index == skill_touch_index:
		skill_touch_pos = pos
	elif index == secondary_touch_index:
		secondary_touch_pos = pos
	elif index == dash_touch_index:
		teleport_drag_screen = pos
	elif index == move_touch_index:
		touch_move = ((pos - joystick_origin) / (76.0 * _joy_scale())).limit_length(1.0)


func _handle_touch_release(index: int, pos: Vector2, viewport: Vector2) -> void:
	var combat_active = mode == "game" or mode == "shop_countdown" or mode == "boss_call" or mode == "pause_countdown"
	if index == move_touch_index:
		_stop_move_touch()
	if index == attack_touch_index:
		attack_touch_index = -1
	if index == attack_drag_touch_index:
		if attack_lock_selecting and combat_active:
			_update_attack_lock_candidate(pos, viewport)
			_commit_attack_lock()
		attack_drag_touch_index = -1
		attack_dragging = false
		attack_holding = false
		attack_hold_timer = 0.0
		attack_lock_selecting = false
		attack_lock_candidate_kind = ""
		attack_lock_candidate_uid = -1
	if index == skill_touch_index:
		if _ability_cancel_has_point(pos, viewport):
			_add_text("CANCELADO", player_pos + Vector2(0, -84), Color(1.0, 0.30, 0.30), 0.55, 17)
		elif combat_active:
			var primary_profile = _ground_target_profile(false)
			if primary_profile.is_empty():
				_use_skill()
			else:
				_use_skill(_ground_target_world(pos, viewport, false))
		skill_touch_index = -1
	if index == secondary_touch_index:
		if _ability_cancel_has_point(pos, viewport):
			_add_text("CANCELADO", player_pos + Vector2(0, -84), Color(1.0, 0.30, 0.30), 0.55, 17)
		elif combat_active:
			var secondary_profile = _ground_target_profile(true)
			if secondary_profile.is_empty():
				_use_secondary_skill()
			else:
				_use_secondary_skill(_ground_target_world(pos, viewport, true))
		secondary_touch_index = -1
	if index == dash_touch_index:
		if _ability_cancel_has_point(pos, viewport):
			_add_text("CANCELADO", player_pos + Vector2(0, -84), Color(1.0, 0.30, 0.30), 0.55, 17)
		elif combat_active:
			_try_dash_to_screen(pos, viewport)
		dash_touch_index = -1
		teleport_dragging = false


func _handle_mouse_press(pos: Vector2, viewport: Vector2) -> void:
	if mode == "game" or mode == "shop_countdown" or mode == "boss_call" or mode == "pause_countdown":
		if buttons["attack"].has_point(pos):
			_claim_action_touch(-2)
			attack_drag_touch_index = -2
			attack_holding = true
			attack_hold_timer = 0.0
			attack_dragging = false
			attack_drag_start_pos = pos
			attack_touch_pos = pos
			attack_drag_direction = _aim_direction()
			_try_attack()
			return
		if buttons["dash"].has_point(pos):
			_claim_action_touch(-2)
			dash_touch_index = -2
			teleport_dragging = true
			teleport_drag_origin = pos
			teleport_drag_screen = pos
			return
		if buttons["skill"].has_point(pos):
			_claim_action_touch(-2)
			skill_touch_index = -2
			skill_touch_pos = pos
			return
		if buttons["secondary"].has_point(pos):
			_claim_action_touch(-2)
			secondary_touch_index = -2
			secondary_touch_pos = pos
			return
	_handle_press(pos, viewport)


func _handle_key(event: InputEventKey) -> void:
	if mode == "menu":
		if event.keycode == KEY_UP or event.keycode == KEY_W:
			menu_selected = (menu_selected - 1 + 4) % 4
		elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
			menu_selected = (menu_selected + 1) % 4
		elif event.keycode in [KEY_ENTER, KEY_SPACE]:
			match menu_selected:
				0:
					mode = "manifest"
				1:
					catalog_tab = 0
					catalog_selected = 0
					catalog_detail_open = false
					mode = "catalog"
				2:
					mode = "settings"
					settings_selected = 0
				3:
					get_tree().quit()
	elif mode == "settings":
		if event.keycode == KEY_ESCAPE:
			_go_to_menu()
		elif event.keycode == KEY_UP or event.keycode == KEY_W:
			settings_selected = (settings_selected - 1 + 4) % 4
		elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
			settings_selected = (settings_selected + 1) % 4
		elif event.keycode in [KEY_ENTER, KEY_SPACE]:
			_activate_settings_option(settings_selected, get_viewport_rect().size)
	elif mode == "settings_gameplay":
		if event.keycode == KEY_ESCAPE:
			_save_config()
			mode = "settings"
		elif event.keycode in [KEY_ENTER, KEY_SPACE]:
			analog_fixed = not analog_fixed
			_save_config()
	elif mode == "settings_audio":
		if event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
			mode = "settings"
	elif mode == "settings_graphics":
		if event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
			_save_config()
			mode = "settings"
	elif mode == "catalog":
		if event.keycode == KEY_ESCAPE:
			if catalog_detail_open:
				catalog_detail_open = false
			else:
				_go_to_menu()
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			catalog_tab = (catalog_tab + 1) % CATALOG_TABS.size()
			catalog_selected = 0
			catalog_detail_open = false
		elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
			catalog_tab = (catalog_tab - 1 + CATALOG_TABS.size()) % CATALOG_TABS.size()
			catalog_selected = 0
			catalog_detail_open = false
		elif event.keycode in [KEY_ENTER, KEY_SPACE]:
			catalog_detail_open = true
	elif mode == "manifest":
		if event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			_set_selected_manifestation(selected_manifestation + 1, true)
			manifest_scroll_pos = float(selected_manifestation)
		elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
			_set_selected_manifestation(selected_manifestation - 1, true)
			manifest_scroll_pos = float(selected_manifestation)
		elif event.keycode in [KEY_ENTER, KEY_SPACE]:
			_start_game()
	elif mode == "shop":
		if _shop_purchase_animating():
			return
		if event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			_set_shop_selection(min(shop_cards.size() - 1, shop_selected + 1))
		elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
			_set_shop_selection(max(0, shop_selected - 1))
		elif event.keycode in [KEY_ENTER, KEY_SPACE]:
			_buy_selected_card()
		elif event.keycode == KEY_Q:
			_reroll_shop()
		elif event.keycode == KEY_ESCAPE:
			_finish_shop()
	elif mode == "paused" and event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
		_resume_from_pause()
	elif mode == "pause_deck" and event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
		_return_from_deck()
	elif mode == "pause_deck":
		var owned = _owned_deck_cards()
		if owned.size() > 0 and (event.keycode == KEY_RIGHT or event.keycode == KEY_D):
			deck_selected = (deck_selected + 1) % owned.size()
			deck_scroll_pos = float(deck_selected)
		elif owned.size() > 0 and (event.keycode == KEY_LEFT or event.keycode == KEY_A):
			deck_selected = (deck_selected - 1 + owned.size()) % owned.size()
			deck_scroll_pos = float(deck_selected)
	elif mode == "game_over":
		if event.keycode in [KEY_ENTER, KEY_SPACE]:
			_start_game()
		elif event.keycode == KEY_ESCAPE:
			_go_to_menu()
	elif mode == "victory" and event.keycode in [KEY_ENTER, KEY_SPACE]:
		_go_to_menu()


func _handle_press(pos: Vector2, viewport: Vector2) -> void:
	if _ui_input_blocked() and (mode == "menu" or mode == "settings" or mode == "settings_gameplay" or mode == "settings_audio" or mode == "settings_graphics" or mode == "catalog" or mode == "manifest" or mode == "paused" or mode == "pause_deck"):
		return
	if mode == "menu":
		var rects = _menu_rects(viewport)
		if rects["start"].has_point(pos):
			menu_selected = 0
			mode = "manifest"
			_block_ui_input()
		elif rects["catalog"].has_point(pos):
			menu_selected = 1
			catalog_tab = 0
			catalog_selected = 0
			catalog_detail_open = false
			mode = "catalog"
			_block_ui_input()
		elif rects["settings"].has_point(pos):
			menu_selected = 2
			settings_selected = 0
			settings_previous_mode = "menu"
			mode = "settings"
			_block_ui_input()
		elif rects["exit"].has_point(pos):
			menu_selected = 3
			get_tree().quit()
		return
	if mode == "settings":
		_handle_settings_touch(pos, viewport)
		return
	if mode == "settings_gameplay":
		_handle_gameplay_settings_touch(pos, viewport)
		return
	if mode == "settings_audio":
		_handle_audio_settings_touch(pos, viewport)
		return
	if mode == "settings_graphics":
		_handle_graphics_settings_touch(pos, viewport)
		return
	if mode == "catalog":
		_handle_catalog_touch(pos, viewport)
		return
	if mode == "manifest":
		_handle_manifest_touch(pos, viewport)
		return
	if mode == "shop":
		_handle_shop_touch(pos, viewport)
		return
	if mode == "paused":
		if buttons.get("pause_resume", Rect2()).has_point(pos):
			_resume_from_pause()
		elif buttons.get("pause_deck", Rect2()).has_point(pos):
			_open_deck("paused")
		elif buttons.get("pause_settings", Rect2()).has_point(pos):
			settings_selected = 0
			settings_previous_mode = "paused"
			mode = "settings"
			_block_ui_input()
		elif buttons.get("pause_menu", Rect2()).has_point(pos):
			_go_to_menu()
		return
	if mode == "pause_deck":
		if buttons.get("pause_deck_back", Rect2()).has_point(pos):
			_return_from_deck()
		return
	if mode == "game_over":
		if buttons.get("end_retry", Rect2()).has_point(pos):
			_start_game()
		elif buttons.get("end_menu", Rect2()).has_point(pos):
			_go_to_menu()
		elif buttons.get("end_exit", Rect2()).has_point(pos):
			get_tree().quit()
		return
	if mode == "victory":
		if buttons.get("end_menu", Rect2()).has_point(pos):
			_go_to_menu()
		else:
			_go_to_menu()
		return
	if buttons["attack"].has_point(pos):
		_try_attack()
		return
	if buttons["skill"].has_point(pos):
		_use_skill()
		return
	if buttons["dash"].has_point(pos):
		teleport_dragging = true
		teleport_drag_screen = pos
		return
	if buttons["pause"].has_point(pos):
		_start_pause_countdown()
		return
	if buttons.has("shop_manual") and buttons["shop_manual"].has_point(pos):
		_try_open_manual_shop()
		return
	if buttons["boss"].has_point(pos):
		_start_boss_call()
		return
	_try_start_move_touch(-2, pos, viewport)


func _handle_catalog_touch(pos: Vector2, viewport: Vector2) -> void:
	var portrait = _is_portrait(viewport)
	if catalog_detail_open:
		if Rect2(viewport.x * 0.5 - 120, viewport.y - 72, 240, 48).has_point(pos):
			catalog_detail_open = false
		return
	var tab_w = viewport.x / CATALOG_TABS.size()
	if pos.y >= 92 and pos.y <= 140:
		catalog_tab = clamp(int(pos.x / tab_w), 0, CATALOG_TABS.size() - 1)
		catalog_selected = 0
		catalog_detail_open = false
		return
	var items = _catalog_items()
	var cols = 1 if portrait else 2
	var visible = 6 if portrait else 8
	var card_w = viewport.x * 0.86 if portrait else min(390.0, viewport.x * 0.42)
	var card_h = 126.0 if portrait else 118.0
	var start_x = viewport.x * 0.5 - card_w * 0.5 if portrait else viewport.x * 0.5 - card_w - 14
	var start_y = 164.0
	for i in range(min(items.size(), visible)):
		var row = int(i / cols)
		var col = i % cols
		var rect = Rect2(start_x + col * (card_w + 28), start_y + row * (card_h + 16), card_w, card_h)
		if rect.has_point(pos):
			catalog_selected = i
			catalog_detail_open = true
			return
	var back_rect = Rect2(viewport.x * 0.08, viewport.y - 72, viewport.x * 0.84, 48) if portrait else Rect2(viewport.x * 0.06, viewport.y - 68, 160, 44)
	if back_rect.has_point(pos):
		_go_to_menu()


func _manifest_carousel_spacing(viewport: Vector2) -> float:
	return 140.0 if _is_portrait(viewport) else 180.0


func _wrap_manifest_scroll(value: float) -> float:
	return fposmod(value, float(MANIFESTATIONS.size()))


func _nearest_manifest_index(value: float) -> int:
	var count = MANIFESTATIONS.size()
	var idx = int(round(_wrap_manifest_scroll(value))) % count
	return idx if idx >= 0 else idx + count


func _set_selected_manifestation(index: int, vibrate := true) -> void:
	var count = MANIFESTATIONS.size()
	if count <= 0:
		return
	var next_index = posmod(index, count)
	var changed = next_index != selected_manifestation
	selected_manifestation = next_index
	if changed and vibrate:
		manifest_last_vibrated_index = selected_manifestation
		_vibrate(36, 0.18)


func _start_manifest_drag(index: int, pos: Vector2, viewport: Vector2) -> void:
	manifest_drag_touch_index = index
	manifest_drag_start_x = pos.x
	manifest_drag_start_scroll = manifest_scroll_pos
	manifest_drag_moved = false
	manifest_is_dragging = true
	manifest_last_vibrated_index = selected_manifestation


func _update_manifest_drag(pos: Vector2, viewport: Vector2) -> void:
	if not manifest_is_dragging:
		return
	var dx = pos.x - manifest_drag_start_x
	if abs(dx) >= MANIFEST_DRAG_DEADZONE:
		manifest_drag_moved = true
	var spacing = max(80.0, _manifest_carousel_spacing(viewport))
	manifest_scroll_pos = _wrap_manifest_scroll(manifest_drag_start_scroll - dx / spacing)
	var nearest = _nearest_manifest_index(manifest_scroll_pos)
	if nearest != selected_manifestation:
		_set_selected_manifestation(nearest, nearest != manifest_last_vibrated_index)


func _finish_manifest_drag(pos: Vector2, viewport: Vector2) -> void:
	_update_manifest_drag(pos, viewport)
	if manifest_drag_moved:
		_set_selected_manifestation(_nearest_manifest_index(manifest_scroll_pos), false)
	else:
		_handle_manifest_touch(pos, viewport)
	manifest_scroll_pos = float(selected_manifestation)
	manifest_drag_touch_index = -999
	manifest_is_dragging = false
	manifest_drag_moved = false


func _handle_manifest_touch(pos: Vector2, viewport: Vector2) -> void:
	# 1. Verificar botÃµes de aÃ§Ã£o inferiores
	if buttons.has("manifest_start") and buttons["manifest_start"].has_point(pos):
		_start_game()
		return
	if buttons.has("manifest_back") and buttons["manifest_back"].has_point(pos):
		_go_to_menu()
		return

	# 2. Verificar clique direto nas cartas do carrossel
	var portrait = _is_portrait(viewport)
	var center_x = viewport.x * 0.5 if portrait else viewport.x * 0.28
	var center_y = viewport.y * 0.28 if portrait else viewport.y * 0.42
	var card_w = 140.0 if portrait else 168.0
	var card_h = 160.0 if portrait else 188.0
	var spacing = _manifest_carousel_spacing(viewport)

	for diff in [-1, 1]:
		var idx = (selected_manifestation + diff + MANIFESTATIONS.size()) % MANIFESTATIONS.size()
		var scale = 0.85
		var pos_x = center_x + diff * spacing
		var rect = Rect2(pos_x - card_w * scale * 0.5, center_y - card_h * scale * 0.5, card_w * scale, card_h * scale)
		if rect.has_point(pos):
			_set_selected_manifestation(idx, true)
			return


func _open_deck(from_mode: String) -> void:
	deck_previous_mode = from_mode
	var owned = _owned_deck_cards()
	_clamp_deck_selection(owned.size())
	mode = "pause_deck"
	_block_ui_input()


func _return_from_deck() -> void:
	mode = deck_previous_mode if deck_previous_mode != "" else "paused"
	_block_ui_input()


func _start_deck_drag(index: int, pos: Vector2, viewport: Vector2) -> void:
	deck_drag_touch_index = index
	deck_drag_start_x = pos.x
	deck_drag_start_scroll = deck_scroll_pos
	deck_drag_moved = false
	deck_is_dragging = true


func _update_deck_drag(pos: Vector2, viewport: Vector2) -> void:
	if not deck_is_dragging:
		return
	var owned = _owned_deck_cards()
	if owned.is_empty():
		return
	var dx = pos.x - deck_drag_start_x
	if abs(dx) >= MANIFEST_DRAG_DEADZONE:
		deck_drag_moved = true
	var spacing = max(90.0, _deck_carousel_spacing(viewport))
	deck_scroll_pos = clamp(deck_drag_start_scroll - dx / spacing, 0.0, float(owned.size() - 1))
	deck_selected = int(round(deck_scroll_pos))


func _finish_deck_drag(pos: Vector2, viewport: Vector2) -> void:
	_update_deck_drag(pos, viewport)
	var owned = _owned_deck_cards()
	if deck_drag_moved and not owned.is_empty():
		deck_selected = clamp(int(round(deck_scroll_pos)), 0, owned.size() - 1)
		deck_scroll_pos = float(deck_selected)
	else:
		_handle_deck_touch(pos, viewport)
	deck_drag_touch_index = -999
	deck_is_dragging = false
	deck_drag_moved = false


func _handle_deck_touch(pos: Vector2, viewport: Vector2) -> void:
	if buttons.get("pause_deck_back", Rect2()).has_point(pos):
		_return_from_deck()
		return
	var owned = _owned_deck_cards()
	if owned.is_empty():
		return
	var panel = Rect2(viewport.x * 0.08 if not _is_portrait(viewport) else viewport.x * 0.05, viewport.y * 0.08, viewport.x * 0.84 if not _is_portrait(viewport) else viewport.x * 0.90, viewport.y * 0.80)
	var center = Vector2(viewport.x * 0.5, panel.position.y + (245.0 if not _is_portrait(viewport) else 260.0))
	var spacing = _deck_carousel_spacing(viewport)
	var card_w = 154.0 if not _is_portrait(viewport) else min(160.0, viewport.x * 0.34)
	var card_h = 214.0 if not _is_portrait(viewport) else 224.0
	for i in range(owned.size()):
		var diff = _carousel_diff(float(i), deck_scroll_pos, owned.size())
		if abs(diff) > 2.15:
			continue
		var scale = clamp(1.0 - abs(diff) * 0.16, 0.66, 1.0)
		var rect = Rect2(center.x + diff * spacing - card_w * scale * 0.5, center.y - card_h * scale * 0.5 + abs(diff) * 18.0, card_w * scale, card_h * scale)
		if rect.has_point(pos):
			deck_selected = i
			deck_scroll_pos = float(i)
			return


func _handle_shop_touch(pos: Vector2, viewport: Vector2) -> void:
	if _shop_purchase_animating():
		return
	var portrait = _is_portrait(viewport)
	var round_r = _shop_round_button_radius(viewport) + 10.0
	if pos.distance_to(_shop_reroll_center(viewport)) <= round_r:
		_reroll_shop()
		return
	if pos.distance_to(_shop_deck_center(viewport)) <= round_r and _deck_total_cards() > 0:
		_open_deck("shop")
		return
	if portrait:
		var w = viewport.x * 0.74
		var h = min(242.0, viewport.y * 0.19)
		for i in range(shop_cards.size()):
			var x = viewport.x * 0.5 - w * 0.5
			var yy = 164.0 + i * (h + 22.0)
			if Rect2(x, yy, w, h).has_point(pos):
				_set_shop_selection(i)
				return

		var btn_h = 44.0
		var btn_w = viewport.x * 0.40
		var btn_y = viewport.y - btn_h - 24

		var btn_buy_rect = Rect2(viewport.x * 0.25 - btn_w * 0.5, btn_y, btn_w, btn_h)
		var btn_sair_rect = Rect2(viewport.x * 0.75 - btn_w * 0.5, btn_y, btn_w, btn_h)
		if btn_buy_rect.has_point(pos):
			_buy_selected_card()
		elif btn_sair_rect.has_point(pos):
			_finish_shop()
		return

	# LANDSCAPE LAYOUT
	var btn_w = 220.0
	var btn_h = 42.0
	var btn_y = viewport.y - btn_h - 24.0

	var btn_buy_rect = Rect2(viewport.x * 0.38 - btn_w * 0.5, btn_y, btn_w, btn_h)
	var btn_sair_rect = Rect2(viewport.x * 0.62 - btn_w * 0.5, btn_y, btn_w, btn_h)

	if btn_buy_rect.has_point(pos):
		_buy_selected_card()
		return
	if btn_sair_rect.has_point(pos):
		_finish_shop()
		return

	# Card carousel touch detection
	var w = 150.0
	var h = 200.0
	var y = 120.0

	for i in range(shop_cards.size()):
		var is_sel = (i == shop_selected)
		var scale = 1.15 if is_sel else 0.85
		var curr_w = w * scale
		var curr_h = h * scale
		var x = viewport.x * 0.5 + (i - 1) * 200 - curr_w * 0.5
		var curr_y = y - 10 if is_sel else y + 15
		var rect = Rect2(x, curr_y, curr_w, curr_h)
		if rect.has_point(pos):
			_set_shop_selection(i)
			return


func _joy_center(viewport: Vector2) -> Vector2:
	if hud_joy_pos != Vector2.ZERO: return hud_joy_pos
	return Vector2(viewport.x * 0.16, viewport.y * 0.76)


func _attack_center(viewport: Vector2) -> Vector2:
	if hud_attack_pos != Vector2.ZERO: return hud_attack_pos
	return Vector2(viewport.x * 0.88, viewport.y * 0.75)


func _secondary_center(viewport: Vector2) -> Vector2:
	if hud_secondary_pos != Vector2.ZERO: return hud_secondary_pos
	return Vector2(viewport.x * 0.76, viewport.y * 0.57)


func _dash_center(viewport: Vector2) -> Vector2:
	if hud_dash_pos != Vector2.ZERO: return hud_dash_pos
	return Vector2(viewport.x * 0.73, viewport.y * 0.82)


func _joy_scale() -> float:
	return hud_joy_scale


func _attack_scale() -> float:
	return hud_attack_scale


func _secondary_scale() -> float:
	return hud_secondary_scale


func _skill_scale() -> float:
	return hud_skill_scale


func _dash_scale() -> float:
	return hud_dash_scale


func _manifestation_base_damage() -> float:
	match manifestation_key:
		"lacerante":
			return PLAYER_BASE_DAMAGE * 1.12
		"prismatica":
			return PLAYER_BASE_DAMAGE * 0.86
		"retornante":
			return PLAYER_BASE_DAMAGE * 0.92
		"parasitica":
			return PLAYER_BASE_DAMAGE * 0.78
		"gravitante":
			return PLAYER_BASE_DAMAGE * 0.82
	return PLAYER_BASE_DAMAGE


func _manifestation_attack_interval() -> float:
	match manifestation_key:
		"lacerante":
			return 0.72
		"prismatica":
			return 0.42
		"retornante":
			return 0.62
		"gravitante":
			return 0.74
	return PLAYER_BASE_ATTACK_INTERVAL


func _current_attack_interval() -> float:
	var interval = player_attack_interval
	if manifestation_key == "ancorada":
		interval *= 1.0 - _secondary_ancorada_charge_at_player() * 0.22
	return max(0.14, interval)


func _skill_cooldown() -> float:
	match manifestation_key:
		"lacerante":
			return 10.0
		"parasitica":
			return PLAYER_BASE_SKILL_COOLDOWN + 0.5
		"gravitante":
			return PLAYER_BASE_SKILL_COOLDOWN + 0.8
		"ancorada":
			return PLAYER_BASE_SKILL_COOLDOWN + 0.2
	return PLAYER_BASE_SKILL_COOLDOWN


func _manifestation_color() -> Color:
	return MANIFESTATIONS[selected_manifestation]["color"]


func _damage_color(source: String) -> Color:
	match source:
		"lacerante":
			return Color(1.0, 0.12, 0.18)
		"veneno", "parasitica":
			return Color(0.55, 1.0, 0.24)
		"gravitante", "gravitante_orbital":
			return Color(0.55, 0.82, 1.0)
		"prismatica":
			return Color(0.44, 1.0, 0.96)
	return _manifestation_color()


func _damage_text_size(base_size: int) -> int:
	return int(clamp(round(float(base_size) * damage_text_scale), 10.0, 34.0))


func _sanitize_target_priority(value: String) -> String:
	if value in ["max_hp_low", "hp_low", "nearest"]:
		return value
	return "nearest"


func _next_target_priority(value: String) -> String:
	match _sanitize_target_priority(value):
		"nearest":
			return "max_hp_low"
		"max_hp_low":
			return "hp_low"
	return "nearest"


func _target_priority_label() -> String:
	match auto_target_priority:
		"max_hp_low":
			return "VIDA MAX. MENOR"
		"hp_low":
			return "VIDA ATUAL MENOR"
	return "MAIS PROXIMO"


func _enemy_radius(enemy: Dictionary) -> float:
	match enemy["type"]:
		ENEMY_AGGLOMERATOR:
			return 50.0
		ENEMY_LARAPIO:
			return 46.0
	return 40.0


func _nearest_enemy_dict() -> Dictionary:
	var best = {}
	var best_d = INF
	for enemy in enemies:
		var d = player_pos.distance_squared_to(enemy["pos"])
		if d < best_d:
			best_d = d
			best = enemy
	return best


func _nearest_enemy_near(origin: Vector2, max_distance: float) -> Dictionary:
	var best = {}
	var best_d = max_distance * max_distance
	for enemy in enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var d = origin.distance_squared_to(Vector2(enemy["pos"]))
		if d < best_d:
			best_d = d
			best = enemy
	return best


func _enemy_by_uid(uid: int):
	for enemy in enemies:
		if int(enemy["uid"]) == uid:
			return enemy
	return null


func _anchor_bonus() -> float:
	var bonus = 1.0
	for anchor in anchors:
		if anchor["pos"].distance_to(player_pos) < 145.0:
			bonus += 0.14
	return min(1.75, bonus)


func _secondary_ancorada_charge_at_player() -> float:
	var best = 0.0
	for secondary in manifestation_secondaries:
		if String(secondary.get("kind", "")) != "ancorada":
			continue
		var center: Vector2 = secondary.get("center", player_pos)
		if player_pos.distance_to(center) <= 220.0:
			best = max(best, clamp(float(secondary.get("charge", 0.0)) / SECONDARY_ANCORADA_DURATION, 0.0, 1.0))
	return best


func _secondary_ancorada_projectile_slow_at(pos: Vector2) -> float:
	var slow = 1.0
	for secondary in manifestation_secondaries:
		if String(secondary.get("kind", "")) != "ancorada":
			continue
		var center: Vector2 = secondary.get("center", player_pos)
		if pos.distance_to(center) <= 220.0:
			var charge = clamp(float(secondary.get("charge", 0.0)) / SECONDARY_ANCORADA_DURATION, 0.0, 1.0)
			slow = min(slow, 0.55 - charge * 0.18)
	return max(0.28, slow)


func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var denom = ab.length_squared()
	if denom <= 0.001:
		return p.distance_to(a)
	var t = clamp((p - a).dot(ab) / denom, 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _distance_to_polyline(p: Vector2, points: Array) -> float:
	if points.is_empty():
		return INF
	if points.size() == 1:
		return p.distance_to(points[0])
	var best = INF
	for i in range(points.size() - 1):
		best = min(best, _distance_to_segment(p, points[i], points[i + 1]))
	return best


func _lacerante_stage_points(origin: Vector2, dir: Vector2, stage: int) -> Array:
	var forward = dir.normalized()
	if forward.length() <= 0.05:
		forward = Vector2.RIGHT
	var normal = Vector2(-forward.y, forward.x)
	var points = []
	var total = 11 if stage in [0, 1] else 9
	for i in range(total):
		var t = float(i) / float(total - 1)
		var advance = 18.0 + 120.0 * t
		var lateral = 0.0
		if stage == 2:
			lateral = sin(t * PI * 2.0) * 3.0
		else:
			lateral = -24.0 + 48.0 * t - sin(t * PI) * 10.0
			if stage == 1:
				lateral *= -1.0
		points.append(origin + forward * advance + normal * lateral)
	return points


func _manifestation_details(key: String) -> Dictionary:
	match key:
		"eletrica":
			return {
				"funcao": "Mais facil de entender e jogar. Boa para primeira partida, fase cheia e troca rapida de alvo.",
				"disparo": "ATK: tiro eletrico reto. A cada 4 tiros, sai uma Sobrecarga mais forte que explode em area pequena.",
				"habilidade": "Q - Onda Cinetica",
				"desc_hab": "Empurra inimigos proximos, causa dano em area e abre espaco quando a tela fecha.",
				"traco": "E - Anel de Tesla: permanece ativo enquanto encontra alvos. Aperte E novamente para cancelar; o cooldown so comeca quando o anel termina.",
				"risco": "Depois de 10s ativo, drena 0,5% da vida maxima por segundo. Sem alvos por 3s, o anel desliga sozinho."
			}
		"lacerante":
			return {
				"funcao": "Agressiva e curta. Funciona melhor quando voce aceita chegar perto para cortar varios inimigos.",
				"disparo": "ATK: corte em linha curta. Atravessa alvos, causa bom dano e aplica Laceracao.",
				"habilidade": "Q - Circulo Lacerante",
				"desc_hab": "Corte em 360 graus ao redor da Geovana. Acerta tudo perto e causa dano extra baseado na vida maxima do alvo.",
				"traco": "E - Carnificina Temporal: Geovana salta para a direcao mirada, fica travada e invulneravel enquanto varios cortes surgem na area.",
				"risco": "Alcance baixo. Se entrar mal posicionada, pode ficar cercada depois que a ultimate acabar."
			}
		"prismatica":
			return {
				"funcao": "Tecnica de mira. Recompensa angulo, ricochete e preparo antes de apertar os botoes.",
				"disparo": "ATK: feixe rapido e fino. Ricocheteia em parede ou inimigo e pode acertar mais de uma vez.",
				"habilidade": "Q - Prisma de Refracao",
				"desc_hab": "Coloca um prisma na posicao da Geovana. Tiros que atravessam o prisma se dividem em 3 feixes.",
				"traco": "E - Coroa Espectral: Geovana fica invulneravel; linhas de luz giram e causam dano. Aperte E novamente para cancelar.",
				"risco": "Aperte E novamente para encerrar antes do tempo. A recarga da Coroa comeca na ativacao."
			}
		"retornante":
			return {
				"funcao": "Dano atrasado. O tiro vai mais fraco e volta mais perigoso para perto da Geovana.",
				"disparo": "ATK: pulso que sai, atravessa o campo e depois retorna. A volta causa mais dano que a ida.",
				"habilidade": "Q - Memoria Instavel",
				"desc_hab": "Marca um pulso ativo para procurar alvos e voltar fortalecido. Se nao houver pulso, o proximo tiro recebe a memoria.",
				"traco": "E - Paradoxo de Retorno: prolonga os retornos ativos e cria linhas temporais que causam dano entre Geovana e os pulsos.",
				"risco": "Depende de timing. Apertar Q ou E sem pulsos ativos reduz bastante o valor da manifestacao."
			}
		"parasitica":
			return {
				"funcao": "Infestacao com janela curta. Cada acerto mantem larvas visiveis no alvo por 6 segundos.",
				"disparo": "ATK: verme parasita reforcado. Causa dano e adiciona larvas; novos acertos renovam a marca de 6s.",
				"habilidade": "Q - Cuspe Infestante",
				"desc_hab": "Cospe um bolo de vermes na direcao da mira. O impacto cria uma area viva que causa dano e contamina inimigos dentro dela.",
				"traco": "E - Enxame Subterraneo: vermes entram pelas bordas, escavam ate cada alvo marcado e devoram por 8s, causando 5% da vida atual por segundo.",
				"risco": "A ultimate exige uma marca ativa. Se os 6s expirarem, as larvas morrem e o alvo deixa de ser valido. Alvos devorados perdem 20% de velocidade."
			}
		"gravitante":
			return {
				"funcao": "Controle automatico. Ajuda quando a tela esta cheia porque parte do dano segue os alvos sozinho.",
				"disparo": "ATK: orbe gravitante. Ao acertar, cria uma orbita no alvo e causa pequenos ticks de dano.",
				"habilidade": "Q - Colapso Orbital",
				"desc_hab": "Cria 3 orbitais extras em inimigos proximos. Eles continuam dando dano enquanto duram.",
				"traco": "E - Nucleo Gravitante: cria um centro de gravidade que puxa inimigos, reduz mobilidade e explode no fim.",
				"risco": "Leva tempo para render. Contra poucos alvos, pode parecer mais lenta que Eletrica ou Lacerante."
			}
		"ancorada":
			return {
				"funcao": "Controle de territorio. Escolha uma area boa e lute perto das ancoras.",
				"disparo": "ATK: planta uma ancora e dispara. Perto das ancoras, seus tiros ficam mais fortes.",
				"habilidade": "Q - Onda Ancorada",
				"desc_hab": "Solta uma onda a partir da Geovana, causando dano nos inimigos ao redor.",
				"traco": "E - Dominio Fixo: cria uma area fixa. Dentro dela, sua cadencia melhora e projeteis inimigos ficam mais lentos.",
				"risco": "Perde forca se voce for obrigada a fugir o tempo todo ou sair do territorio preparado."
			}
	return {
		"funcao": "Forma em leitura.",
		"disparo": "Sinal incompleto.",
		"habilidade": "Indefinida",
		"desc_hab": "Eco ainda nao dominado.",
		"traco": "Aguardando dominio.",
		"risco": "Instavel demais para combate."
	}


func _current_map_texture() -> Texture2D:
	if current_phase == 3:
		return textures.get("map_phase_3")
	if current_phase == 2:
		return textures.get("map_phase_2")
	return textures.get("map_phase_1")


func _desktop_stage_draw_rect(camera: Vector2) -> Rect2:
	var stage_aspect = DESKTOP_STAGE_SIZE.x / DESKTOP_STAGE_SIZE.y
	var draw_size = Vector2(WORLD_SIZE.y * stage_aspect, WORLD_SIZE.y)
	if draw_size.x < WORLD_SIZE.x:
		draw_size = Vector2(WORLD_SIZE.x, WORLD_SIZE.x / stage_aspect)
	var origin = Vector2(-camera.x, -camera.y) + (WORLD_SIZE - draw_size) * 0.5
	return Rect2(origin, draw_size)


func _spawn_custom_collision(pos: Vector2, kind: String) -> void:
	if not gfx_particles: return
	match kind:
		"eletrica", "eletrica_charged":
			for i in range(8):
				var angle = rng.randf_range(0, TAU)
				var speed = rng.randf_range(60.0, 180.0)
				effects.append({
					"pos": pos,
					"vel": Vector2.from_angle(angle) * speed,
					"life": rng.randf_range(0.1, 0.3),
					"max": 0.3,
					"color": Color(0.0, 0.88, 1.0),
					"size": rng.randf_range(2.0, 5.0),
					"kind": "spark"
				})
		"lacerante":
			for i in range(3):
				var angle = rng.randf_range(0, TAU)
				effects.append({
					"pos": pos,
					"vel": Vector2.from_angle(angle) * rng.randf_range(20.0, 50.0),
					"life": rng.randf_range(0.2, 0.4),
					"max": 0.4,
					"color": Color(1.0, 0.12, 0.18),
					"size": rng.randf_range(4.0, 12.0),
					"kind": "slash_mark",
					"angle": angle
				})
		"prismatica":
			for i in range(5):
				var angle = rng.randf_range(0, TAU)
				effects.append({
					"pos": pos,
					"vel": Vector2.from_angle(angle) * rng.randf_range(40.0, 100.0),
					"life": rng.randf_range(0.2, 0.5),
					"max": 0.5,
					"color": Color(0.32, 1.0, 0.96),
					"size": rng.randf_range(3.0, 7.0),
					"kind": "shard",
					"rot": rng.randf_range(-10, 10)
				})
		"parasitica":
			_spawn_radial_particles(pos, Color(0.38, 1.0, 0.50), 12)
		"gravitante":
			_spawn_radial_particles(pos, Color(0.46, 0.78, 1.0), 8)
		"retornante":
			_spawn_radial_particles(pos, Color(0.58, 0.38, 1.0), 10)
		"ancorada":
			_spawn_radial_particles(pos, Color(0.30, 0.88, 1.0), 8)
		_:
			_spawn_radial_particles(pos, Color(1.0, 1.0, 1.0), 5)


func _start_boss1_rain() -> void:
	if current_phase != 1 or boss_dead or boss_hp <= 0.0:
		return
	if boss1_rain_active and weather_kind == "rain":
		return
	boss1_rain_active = true
	weather_kind = "rain"
	weather_rain_intro_timer = 0.0
	raindrops.clear()
	rain_splashes.clear()
	snowflakes.clear()
	_seed_rain_puddles()
	_start_rain_audio()
	_add_text("CHUVA CRONAL", boss_pos + Vector2(0, -138), Color(0.62, 0.90, 1.0), 1.8, 25)
	_spawn_radial_particles(boss_pos, Color(0.48, 0.86, 1.0), 20)


func _clear_environment_weather() -> void:
	boss1_rain_active = false
	weather_kind = ""
	raindrops.clear()
	rain_splashes.clear()
	snowflakes.clear()
	puddles.clear()
	weather_rain_intro_timer = 0.0
	_stop_rain_audio()


func _convert_rain_to_snow() -> void:
	boss1_rain_active = true
	weather_kind = "snow"
	raindrops.clear()
	rain_splashes.clear()
	puddles.clear()
	snowflakes.clear()
	weather_rain_intro_timer = 0.0
	_stop_rain_audio()
	for i in range(80):
		_spawn_snowflake(true)
	_add_text("A CHUVA VIROU NEVE", player_pos + Vector2(0, -112), Color(0.72, 0.94, 1.0), 1.8, 24)


func _seed_rain_puddles() -> void:
	puddles.clear()
	var attempts = 0
	while puddles.size() < WEATHER_MAX_PUDDLES and attempts < WEATHER_MAX_PUDDLES * 5:
		attempts += 1
		var pos = Vector2(rng.randf_range(110.0, WORLD_SIZE.x - 110.0), rng.randf_range(110.0, WORLD_SIZE.y - 95.0))
		if pos.distance_to(player_pos) < 86.0:
			continue
		_add_rain_puddle(pos, rng.randf_range(WEATHER_PUDDLE_MIN_SIZE, WEATHER_PUDDLE_MAX_SIZE), rng.randf_range(18.0, 34.0))


func _add_rain_puddle(pos: Vector2, radius: float, life: float) -> void:
	puddles.append({
		"pos": pos.clamp(Vector2(45.0, 55.0), WORLD_SIZE - Vector2(45.0, 55.0)),
		"r": clamp(radius, WEATHER_PUDDLE_MIN_SIZE, WEATHER_PUDDLE_MAX_SIZE),
		"life": life,
		"max_life": life,
		"grow": 0.0,
		"grow_time": rng.randf_range(1.15, 2.25),
		"phase": rng.randf_range(0.0, TAU),
		"shine": rng.randf_range(0.65, 1.15),
		"tilt": rng.randf_range(-0.16, 0.16)
	})
	if puddles.size() > WEATHER_MAX_PUDDLES:
		puddles.pop_front()


func _update_environment_weather(delta: float) -> void:
	if not boss1_rain_active:
		return
	if weather_kind == "snow":
		_update_snow(delta)
	else:
		weather_rain_intro_timer = min(WEATHER_RAIN_FADE_TIME, weather_rain_intro_timer + delta)
		_update_rain(delta)


func _rain_intensity() -> float:
	return clamp(weather_rain_intro_timer / WEATHER_RAIN_FADE_TIME, 0.0, 1.0)


func _spawn_raindrop() -> void:
	var around = player_pos + Vector2(rng.randf_range(-820.0, 820.0), rng.randf_range(-520.0, 520.0))
	raindrops.append({
		"ground": around.clamp(Vector2(20.0, 20.0), WORLD_SIZE - Vector2(20.0, 20.0)),
		"height": rng.randf_range(260.0, 560.0),
		"speed": rng.randf_range(760.0, 1040.0),
		"wind": rng.randf_range(-150.0, -70.0),
		"len": rng.randf_range(22.0, 42.0),
		"size": rng.randf_range(1.2, 2.2),
		"phase": rng.randf_range(0.0, TAU)
	})


func _update_rain(delta: float) -> void:
	var rain_rate = WEATHER_RAIN_DROP_RATE * lerp(0.22, 1.0, _rain_intensity())
	var spawn_count = int(rain_rate * delta)
	if rng.randf() < fmod(rain_rate * delta, 1.0):
		spawn_count += 1
	for i in range(spawn_count):
		_spawn_raindrop()
	while raindrops.size() > WEATHER_MAX_RAIN_DROPS:
		raindrops.pop_front()

	var kept_drops = []
	var t = float(Time.get_ticks_msec()) * 0.001
	for drop in raindrops:
		drop["height"] = float(drop["height"]) - float(drop["speed"]) * delta
		var ground = Vector2(drop["ground"])
		ground += Vector2(float(drop["wind"]) * 0.10 + sin(t * 2.5 + float(drop["phase"])) * 8.0, float(drop["speed"]) * 0.018) * delta
		drop["ground"] = ground.clamp(Vector2(20.0, 20.0), WORLD_SIZE - Vector2(20.0, 20.0))
		if float(drop["height"]) <= 0.0:
			_spawn_rain_splash(Vector2(drop["ground"]))
			if rng.randf() < 0.055:
				_add_rain_puddle(Vector2(drop["ground"]), rng.randf_range(WEATHER_PUDDLE_MIN_SIZE, WEATHER_PUDDLE_MAX_SIZE), rng.randf_range(12.0, 24.0))
		else:
			kept_drops.append(drop)
	raindrops = kept_drops

	for splash in rain_splashes:
		splash["life"] = float(splash["life"]) - delta
		var droplets = Array(splash.get("droplets", []))
		for bit in droplets:
			bit["pos"] = Vector2(bit["pos"]) + Vector2(bit["vel"]) * delta
			bit["vel"] = Vector2(bit["vel"]) + Vector2(0.0, 260.0) * delta
		splash["droplets"] = droplets
	rain_splashes = rain_splashes.filter(func(s): return float(s["life"]) > 0.0)

	for puddle in puddles:
		puddle["life"] = float(puddle["life"]) - delta * rng.randf_range(0.18, 0.32)
		puddle["grow"] = min(float(puddle.get("grow_time", 1.4)), float(puddle.get("grow", 0.0)) + delta)
		puddle["phase"] = float(puddle["phase"]) + delta * 0.85
	puddles = puddles.filter(func(p): return float(p["life"]) > 0.0)
	while puddles.size() < WEATHER_MAX_PUDDLES and rng.randf() < 0.22:
		_add_rain_puddle(Vector2(rng.randf_range(90.0, WORLD_SIZE.x - 90.0), rng.randf_range(90.0, WORLD_SIZE.y - 90.0)), rng.randf_range(WEATHER_PUDDLE_MIN_SIZE, WEATHER_PUDDLE_MAX_SIZE), rng.randf_range(16.0, 30.0))


func _spawn_rain_splash(pos: Vector2) -> void:
	var droplets = []
	for i in range(rng.randi_range(2, 5)):
		var angle = rng.randf_range(-PI * 0.92, -PI * 0.08)
		droplets.append({
			"pos": pos,
			"vel": Vector2.from_angle(angle) * rng.randf_range(28.0, 72.0),
			"size": rng.randf_range(1.0, 2.0)
		})
	rain_splashes.append({
		"pos": pos,
		"life": rng.randf_range(0.16, 0.28),
		"max_life": 0.28,
		"radius": rng.randf_range(5.0, 12.0),
		"droplets": droplets
	})
	if rain_splashes.size() > 90:
		rain_splashes.pop_front()


func _spawn_snowflake(prewarm := false) -> void:
	var pos = player_pos + Vector2(rng.randf_range(-850.0, 850.0), rng.randf_range(-560.0, 500.0))
	if prewarm:
		pos.y = rng.randf_range(20.0, WORLD_SIZE.y - 20.0)
	else:
		pos.y = player_pos.y - rng.randf_range(410.0, 560.0)
	snowflakes.append({
		"pos": pos.clamp(Vector2(12.0, -80.0), WORLD_SIZE + Vector2(-12.0, 80.0)),
		"speed": rng.randf_range(30.0, 88.0),
		"drift": rng.randf_range(-34.0, 34.0),
		"size": rng.randf_range(1.8, 4.6),
		"phase": rng.randf_range(0.0, TAU),
		"life": rng.randf_range(3.0, 7.0)
	})


func _update_snow(delta: float) -> void:
	var spawn_count = int(WEATHER_SNOW_DROP_RATE * delta)
	if rng.randf() < fmod(WEATHER_SNOW_DROP_RATE * delta, 1.0):
		spawn_count += 1
	for i in range(spawn_count):
		_spawn_snowflake(false)
	while snowflakes.size() > WEATHER_MAX_SNOW_FLAKES:
		snowflakes.pop_front()
	var kept_flakes = []
	for flake in snowflakes:
		flake["phase"] = float(flake["phase"]) + delta * 2.1
		flake["life"] = float(flake["life"]) - delta
		var pos = Vector2(flake["pos"])
		pos += Vector2(float(flake["drift"]) + sin(float(flake["phase"])) * 24.0, float(flake["speed"])) * delta
		flake["pos"] = pos
		if float(flake["life"]) > 0.0 and pos.y < WORLD_SIZE.y + 90.0:
			kept_flakes.append(flake)
	snowflakes = kept_flakes


func _draw_rain_puddles(camera: Vector2) -> void:
	var t = float(Time.get_ticks_msec()) * 0.001
	for puddle in puddles:
		var life_alpha = clamp(float(puddle["life"]) / max(0.01, float(puddle["max_life"])), 0.0, 1.0)
		var grow_alpha = clamp(float(puddle.get("grow", 0.0)) / max(0.01, float(puddle.get("grow_time", 1.4))), 0.0, 1.0)
		var alpha = min(life_alpha, grow_alpha)
		var center = Vector2(puddle["pos"]) - camera
		var radius = float(puddle["r"])
		var phase = float(puddle["phase"])
		var shine = float(puddle["shine"])
		var glow = 0.52 + sin(t * 2.4 + phase) * 0.18
		draw_set_transform(center, float(puddle["tilt"]), Vector2(1.0 + sin(phase) * 0.08, 0.38 + cos(phase * 0.7) * 0.05))
		draw_circle(Vector2.ZERO, radius + 4.0, Color(0.02, 0.05, 0.08, 0.22 * alpha))
		draw_circle(Vector2.ZERO, radius, Color(0.28, 0.52, 0.68, 0.20 * alpha))
		draw_circle(Vector2.ZERO, radius * 0.72, Color(0.74, 0.92, 1.0, 0.13 * alpha * shine))
		draw_arc(Vector2.ZERO, radius * 0.86, -PI * 0.78, -PI * 0.16, 18, Color(0.96, 1.0, 1.0, 0.35 * alpha * glow), 1.6)
		draw_arc(Vector2.ZERO, radius * 0.54, PI * 0.10, PI * 0.62, 14, Color(0.88, 0.36, 1.0, 0.16 * alpha), 1.2)
		draw_line(Vector2(-radius * 0.44, -radius * 0.08), Vector2(radius * 0.38, -radius * 0.20), Color(0.92, 1.0, 1.0, 0.26 * alpha * shine), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if player_pos.distance_to(Vector2(puddle["pos"])) <= radius:
			draw_arc(center, radius + 7.0, 0.0, TAU, 34, Color(0.70, 0.94, 1.0, 0.42), 1.8)


func _draw_weather_precipitation(camera: Vector2) -> void:
	if weather_kind == "snow":
		_draw_snowflakes(camera)
	else:
		_draw_raindrops(camera)
		_draw_rain_splashes(camera)


func _draw_raindrops(camera: Vector2) -> void:
	for drop in raindrops:
		var ground = Vector2(drop["ground"])
		var pos = Vector2(ground.x, ground.y - float(drop["height"])) - camera
		var streak = Vector2(float(drop["wind"]) * 0.055, float(drop["len"]))
		draw_line(pos - streak * 0.5, pos + streak * 0.5, Color(0.78, 0.92, 1.0, 0.56), float(drop["size"]))
		draw_line(pos + streak * 0.12, pos + streak * 0.34, Color(1.0, 1.0, 1.0, 0.34), max(1.0, float(drop["size"]) * 0.55))


func _draw_rain_splashes(camera: Vector2) -> void:
	for splash in rain_splashes:
		var alpha = clamp(float(splash["life"]) / max(0.01, float(splash["max_life"])), 0.0, 1.0)
		var center = Vector2(splash["pos"]) - camera
		var radius = float(splash["radius"]) * (1.0 + (1.0 - alpha) * 1.4)
		draw_set_transform(center, 0.0, Vector2(1.0, 0.36))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, Color(0.86, 0.96, 1.0, 0.42 * alpha), 1.2)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for bit in Array(splash.get("droplets", [])):
			draw_circle(Vector2(bit["pos"]) - camera, float(bit["size"]) * alpha, Color(0.90, 0.98, 1.0, 0.64 * alpha))


func _draw_snowflakes(camera: Vector2) -> void:
	for flake in snowflakes:
		var pos = Vector2(flake["pos"]) - camera
		var size = float(flake["size"])
		var alpha = clamp(float(flake["life"]) / 2.0, 0.18, 0.82)
		draw_circle(pos, size, Color(0.88, 0.96, 1.0, alpha))
		draw_line(pos + Vector2(-size * 1.5, 0.0), pos + Vector2(size * 1.5, 0.0), Color(1.0, 1.0, 1.0, alpha * 0.58), 1.0)
		draw_line(pos + Vector2(0.0, -size * 1.5), pos + Vector2(0.0, size * 1.5), Color(1.0, 1.0, 1.0, alpha * 0.48), 1.0)


func _draw_graphics_settings(viewport: Vector2) -> void:
	_draw_holo_background(viewport, null, Color(0.6, 0.8, 1.0))
	var portrait = _is_portrait(viewport)
	_draw_glitch_title("GRAFICOS", Vector2(viewport.x * 0.5, 56 if not portrait else 48), 34 if not portrait else 30, Color(0.6, 0.8, 1.0))
	settings_buttons = _gameplay_settings_rects(viewport)
	var panel = settings_buttons["analog"]
	_draw_holo_panel(panel, Color(0.6, 0.8, 1.0), true, 0.62)
	var titles = ["PARTICULAS", "SOMBRAS", "TREMOR DE TELA"]
	var flags = [gfx_particles, gfx_shadows, gfx_screen_shake]
	var y_start = panel.position.y + 40
	for i in range(3):
		var y_off = y_start + i * 50
		draw_string(font, Vector2(panel.position.x + 20, y_off + 24), titles[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
		var toggle = Rect2(panel.end.x - 120, y_off - 4, 100, 36)
		var t_color = Color(0.6, 0.8, 1.0) if flags[i] else Color(0.5, 0.5, 0.5)
		draw_rect(toggle, Color(t_color.r, t_color.g, t_color.b, 0.2), true)
		draw_rect(toggle, t_color, false, 2)
		_draw_centered("ON" if flags[i] else "OFF", toggle.get_center() + Vector2(0, 6), 16, Color.WHITE)
	_draw_settings_card(settings_buttons["back"], "VOLTAR", "retornar as configuracoes", Color(1.0, 0.26, 0.36), false)

func _handle_graphics_settings_touch(pos: Vector2, viewport: Vector2) -> void:
	settings_buttons = _gameplay_settings_rects(viewport)
	var panel = settings_buttons["analog"]
	var y_start = panel.position.y + 40
	for i in range(3):
		var y_off = y_start + i * 50
		var toggle = Rect2(panel.end.x - 120, y_off - 4, 100, 36)
		if toggle.has_point(pos):
			if i == 0: gfx_particles = not gfx_particles
			elif i == 1: gfx_shadows = not gfx_shadows
			elif i == 2: gfx_screen_shake = not gfx_screen_shake
			_save_config()
			return
	if settings_buttons["back"].has_point(pos):
		_save_config()
		mode = "settings"
		_block_ui_input()

func _left_panel_pos(viewport: Vector2) -> Vector2:
	if hud_left_panel_pos != Vector2(-1, -1): return hud_left_panel_pos
	return Vector2(16, 14)

func _right_panel_pos(viewport: Vector2) -> Vector2:
	if hud_right_panel_pos != Vector2(-1, -1): return hud_right_panel_pos
	var portrait = _is_portrait(viewport)
	var right_w = 220.0 if not portrait else min(220.0, viewport.x * 0.44)
	return Vector2(viewport.x - right_w - 16.0, 14)

func _boss_panel_pos(viewport: Vector2) -> Vector2:
	if hud_boss_panel_pos != Vector2(-1, -1): return hud_boss_panel_pos
	return Vector2(viewport.x * 0.5 - 190, 16)

func _skill_pos(viewport: Vector2) -> Vector2:
	if hud_skill_pos != Vector2(-1, -1): return hud_skill_pos
	var radius = 46.0 * _skill_scale()
	return Vector2(viewport.x * 0.79 - radius, viewport.y * 0.68 - radius)

func _pause_pos(viewport: Vector2) -> Vector2:
	if hud_pause_pos != Vector2(-1, -1): return hud_pause_pos
	return Vector2(viewport.x - 72, 18)

func _boss_call_pos(viewport: Vector2) -> Vector2:
	if hud_boss_call_pos != Vector2(-1, -1): return hud_boss_call_pos
	return Vector2(viewport.x * 0.5 - 48, 58)


func _manual_shop_pos(viewport: Vector2) -> Vector2:
	return Vector2(viewport.x * 0.5 + 62.0, 58.0)
