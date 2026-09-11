extends RefCounted

const DRAW_HEIGHT := 104.0
const CELL_SIZE := Vector2i(320, 256)
const ATTACK_RECOVERY_SECONDS := 0.24
const PREFIX := "player_lacerante_"
const CORE := {
	"idle": [0, 1, 2, 3], "down": [4, 5], "right": [6, 7, 8],
	"left": [9, 10, 11], "up": [12, 13], "damage": [14, 15, 16, 17],
	"attack_right": [18, 19, 20, 21, 22, 23]
}
const EXTRA := {
	"start_down": [0, 1, 2, 3, 4, 5], "frozen": [6, 7],
	"attack_left": [8, 9, 10, 11, 12, 13], "idle_extra": [14, 15]
}


static func register(host: Node) -> void:
	var core: Texture2D = load("res://assets/sprites/player/lacerante/core.png")
	var extra: Texture2D = load("res://assets/sprites/player/lacerante/extra.png")
	host.textures[PREFIX + "core"] = core
	host.textures[PREFIX + "extra"] = extra
	for spec in [[CORE, core, 6], [EXTRA, extra, 4]]:
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
	# Direction lives in the existing frame index, without adding network fields.
	host.textures[PREFIX + "side_network"] = host.textures[PREFIX + "right"] + host.textures[PREFIX + "left"]
	host.textures[PREFIX + "attack_network"] = host.textures[PREFIX + "attack_right"] + host.textures[PREFIX + "attack_left"]


static func is_manifestation(host: Node, index: int) -> bool:
	return index >= 0 and index < host.MANIFESTATIONS.size() and String(host.MANIFESTATIONS[index]["key"]) == "lacerante"


static func remote_key(host: Node, state: int) -> String:
	match state:
		host.NET_ANIM_FROZEN: return PREFIX + "frozen"
		host.NET_ANIM_DAMAGE: return PREFIX + "damage"
		host.NET_ANIM_UP: return PREFIX + "up"
		host.NET_ANIM_DOWN: return PREFIX + "down"
		host.NET_ANIM_RIGHT: return PREFIX + "side_network"
		host.NET_ANIM_LACERANTE: return PREFIX + "attack_network"
		host.NET_ANIM_FIRE: return PREFIX + "attack_network"
	return PREFIX + "idle"


static func snapshot(host: Node, now_ms: int) -> Vector2i:
	# Share the exact state/frame selection between local drawing and replication.
	if host.player_freeze_visual_timer > 0.0:
		return Vector2i(host.NET_ANIM_FROZEN, clampi(host._frozen_player_frame_index(), 0, 1))
	var damage_elapsed: float = host.time_alive - host.last_damage_time
	if damage_elapsed >= 0.0 and damage_elapsed < 0.35:
		return Vector2i(host.NET_ANIM_DAMAGE, clampi(int(damage_elapsed / 0.07), 0, 3))
	var move: Vector2 = host._read_move()
	if move.length() <= 0.12:
		if host.lacerante_preparing:
			var offset: int = 6 if host.lacerante_prepare_dir.x < -0.1 else 0
			# The second pose contains the slash. Hold anticipation until damage fires.
			return Vector2i(host.NET_ANIM_LACERANTE, offset + posmod(host.lacerante_prepare_stage, 3) * 2)
		var attack_elapsed: float = host.time_alive - host.last_attack_time
		if attack_elapsed >= 0.0 and attack_elapsed < ATTACK_RECOVERY_SECONDS:
			var offset: int = 6 if host.player_attack_visual_dir.x < -0.1 else 0
			return Vector2i(host.NET_ANIM_LACERANTE, offset + posmod(host.lacerante_combo_visual, 3) * 2 + 1)
		return Vector2i(host.NET_ANIM_IDLE, int(now_ms / 145) % 4)
	if move.y < -0.1:
		return Vector2i(host.NET_ANIM_UP, int(now_ms / 120) % 2)
	if move.y > 0.1:
		return Vector2i(host.NET_ANIM_DOWN, int(now_ms / 120) % 2)
	return Vector2i(host.NET_ANIM_RIGHT, (3 if move.x < 0.0 else 0) + int(now_ms / 105) % 3)
