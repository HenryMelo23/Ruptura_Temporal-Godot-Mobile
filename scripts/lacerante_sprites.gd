extends RefCounted

const DRAW_HEIGHT := 92.0
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
			var frames: Array = host.textures.get(key, [])
			for index in spec[0][animation]:
				var frame := AtlasTexture.new()
				frame.atlas = spec[1]
				frame.region = Rect2((index % spec[2]) * 256, floori(float(index) / float(spec[2])) * 256, 256, 256)
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
	return PREFIX + "idle"
