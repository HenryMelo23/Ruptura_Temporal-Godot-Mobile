extends RefCounted

const DRAW_HEIGHT := 104.0
const ATTACK_DRAW_HEIGHT := 112.0
const ULTIMATE_DRAW_HEIGHT := 126.0
const CELL_SIZE := Vector2i(320, 256)
const ATTACK_RECOVERY_SECONDS := 0.24
const Q_CAST_SECONDS := 0.72
const ULTIMATE_START_SECONDS := 0.32
const ULTIMATE_END_SECONDS := 0.36
const ULTIMATE_CUT_FRAME_SECONDS := 0.11
const PREFIX := "player_lacerante_"
const CORE := {
	"idle": [0, 1, 2, 3], "down": [4, 5], "right": [6, 7, 8],
	"left": [9, 10, 11], "up": [12, 13], "damage": [14, 15, 16, 17],
}
const ATTACK := {
	"attack_right": [0, 1, 2, 3, 4, 5, 6, 7, 8],
	"attack_left": [9, 10, 11, 12, 13, 14, 15, 16, 17]
}
const SUPPORT := {"frozen": [0, 1], "idle_extra": [2, 3]}
const Q_CAST := {"q_cast": [0, 1, 2, 3, 4, 5]}
const ULTIMATE := {"ultimate": [0, 1, 2, 3, 4, 5, 6, 7]}
const ENTRY_FRAME_PATHS := [
	"res://assets/sprites/player/lacerante/entry/lacerante_entry_0.png",
	"res://assets/sprites/player/lacerante/entry/lacerante_entry_1.png",
	"res://assets/sprites/player/lacerante/entry/lacerante_entry_2.png",
	"res://assets/sprites/player/lacerante/entry/lacerante_entry_3.png",
	"res://assets/sprites/player/lacerante/entry/lacerante_entry_4.png",
	"res://assets/sprites/player/lacerante/entry/lacerante_entry_5.png",
]


static func register(host: Node) -> void:
	var core: Texture2D = load("res://assets/sprites/player/lacerante/core.png")
	var attack: Texture2D = load("res://assets/sprites/player/lacerante/attacks.png")
	var support: Texture2D = load("res://assets/sprites/player/lacerante/support.png")
	var q_cast: Texture2D = load("res://assets/sprites/player/lacerante/q_cast.png")
	var ultimate: Texture2D = load("res://assets/sprites/player/lacerante/ultimate.png")
	host.textures[PREFIX + "core"] = core
	host.textures[PREFIX + "attack_sheet"] = attack
	host.textures[PREFIX + "support_sheet"] = support
	host.textures[PREFIX + "q_sheet"] = q_cast
	host.textures[PREFIX + "ultimate_sheet"] = ultimate
	for spec in [[CORE, core, 6], [ATTACK, attack, 3], [SUPPORT, support, 4], [Q_CAST, q_cast, 3], [ULTIMATE, ultimate, 4]]:
		for animation in spec[0]:
			var key: String = PREFIX + animation
			var frames: Array = []
			for index in spec[0][animation]:
				var frame := AtlasTexture.new()
				frame.atlas = spec[1]
				frame.region = Rect2((index % spec[2]) * CELL_SIZE.x, floori(float(index) / float(spec[2])) * CELL_SIZE.y, CELL_SIZE.x, CELL_SIZE.y)
				frame.filter_clip = true
				frames.append(frame)
			host.textures[key] = frames
	var entry_frames: Array = []
	for path in ENTRY_FRAME_PATHS:
		entry_frames.append(load(path))
	host.textures[PREFIX + "start_down"] = entry_frames
	# Direction lives in the existing frame index, without adding network fields.
	host.textures[PREFIX + "side_network"] = host.textures[PREFIX + "right"] + host.textures[PREFIX + "left"]
	host.textures[PREFIX + "attack_network"] = host.textures[PREFIX + "attack_right"] + host.textures[PREFIX + "attack_left"]
	# Q and ultimate frames follow the 18 attack frames, preserving legacy indices.
	host.textures[PREFIX + "action_network"] = host.textures[PREFIX + "attack_network"] + host.textures[PREFIX + "q_cast"] + host.textures[PREFIX + "ultimate"]


static func draw_height(host: Node, texture: Texture2D) -> float:
	if texture != null and texture in host.textures.get(PREFIX + "ultimate", []):
		return ULTIMATE_DRAW_HEIGHT
	if texture != null and texture in host.textures.get(PREFIX + "attack_network", []):
		return ATTACK_DRAW_HEIGHT
	return DRAW_HEIGHT


static func is_manifestation(host: Node, index: int) -> bool:
	return index >= 0 and index < host.MANIFESTATIONS.size() and String(host.MANIFESTATIONS[index]["key"]) == "lacerante"


static func remote_key(host: Node, state: int) -> String:
	match state:
		host.NET_ANIM_FROZEN: return PREFIX + "frozen"
		host.NET_ANIM_DAMAGE: return PREFIX + "damage"
		host.NET_ANIM_UP: return PREFIX + "up"
		host.NET_ANIM_DOWN: return PREFIX + "down"
		host.NET_ANIM_RIGHT: return PREFIX + "side_network"
		host.NET_ANIM_LACERANTE: return PREFIX + "action_network"
		host.NET_ANIM_FIRE: return PREFIX + "action_network"
	return PREFIX + "idle"


static func _q_cast_frame(host: Node) -> int:
	for slash_data in host.slashes:
		if not slash_data is Dictionary:
			continue
		var slash: Dictionary = slash_data
		if String(slash.get("kind", "")) != "lacerante_spin":
			continue
		var maximum := maxf(0.01, float(slash.get("max", host.LACERANTE_Q_DURATION)))
		var elapsed := maximum - maxf(0.0, float(slash.get("life", 0.0)))
		var duration := maxf(0.01, float(slash.get("visual_animation_duration", Q_CAST_SECONDS)))
		if elapsed <= duration:
			return clampi(int(floor(elapsed / duration * 6.0)), 0, 5)
	return -1


static func _ultimate_frame(host: Node) -> int:
	var secondary: Dictionary = host._active_lacerante_secondary()
	if secondary.is_empty():
		return -1
	var maximum := maxf(0.01, float(secondary.get("max", host.SECONDARY_LACERANTE_DURATION)))
	var life := clampf(float(secondary.get("life", maximum)), 0.0, maximum)
	var elapsed := maximum - life
	if elapsed < ULTIMATE_START_SECONDS:
		return clampi(int(elapsed / (ULTIMATE_START_SECONDS * 0.5)), 0, 1)
	if life <= ULTIMATE_END_SECONDS:
		return 6 + clampi(int((ULTIMATE_END_SECONDS - life) / (ULTIMATE_END_SECONDS * 0.5)), 0, 1)
	return 2 + posmod(int(floor((elapsed - ULTIMATE_START_SECONDS) / ULTIMATE_CUT_FRAME_SECONDS)), 4)


static func snapshot(host: Node, now_ms: int) -> Vector2i:
	# Share the exact state/frame selection between local drawing and replication.
	if host.player_freeze_visual_timer > 0.0:
		return Vector2i(host.NET_ANIM_FROZEN, clampi(host._frozen_player_frame_index(), 0, 1))
	var damage_elapsed: float = host.time_alive - host.last_damage_time
	if damage_elapsed >= 0.0 and damage_elapsed < 0.35:
		return Vector2i(host.NET_ANIM_DAMAGE, clampi(int(damage_elapsed / 0.07), 0, 3))
	var ultimate_frame := _ultimate_frame(host)
	if ultimate_frame >= 0:
		return Vector2i(host.NET_ANIM_LACERANTE, 24 + ultimate_frame)
	var q_frame := _q_cast_frame(host)
	if q_frame >= 0:
		return Vector2i(host.NET_ANIM_LACERANTE, 18 + q_frame)
	var move: Vector2 = host._read_move()
	if move.length() <= 0.12:
		if host.lacerante_preparing:
			var offset: int = 9 if host.lacerante_prepare_dir.x < -0.1 else 0
			var phase := clampi(host.lacerante_prepare_frame, 0, 1)
			return Vector2i(host.NET_ANIM_LACERANTE, offset + posmod(host.lacerante_prepare_stage, 3) * 3 + phase)
		var attack_elapsed: float = host.time_alive - host.last_attack_time
		if attack_elapsed >= 0.0 and attack_elapsed < ATTACK_RECOVERY_SECONDS:
			var offset: int = 9 if host.player_attack_visual_dir.x < -0.1 else 0
			return Vector2i(host.NET_ANIM_LACERANTE, offset + posmod(host.lacerante_combo_visual, 3) * 3 + 2)
		return Vector2i(host.NET_ANIM_IDLE, int(now_ms / 145) % 4)
	if move.y < -0.1:
		return Vector2i(host.NET_ANIM_UP, int(now_ms / 120) % 2)
	if move.y > 0.1:
		return Vector2i(host.NET_ANIM_DOWN, int(now_ms / 120) % 2)
	return Vector2i(host.NET_ANIM_RIGHT, (3 if move.x < 0.0 else 0) + int(now_ms / 105) % 3)
