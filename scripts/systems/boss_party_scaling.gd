class_name RTBossPartyScaling
extends RefCounted

const MODEL_VERSION: String = "boss_party_scaling_v1"

const PARTY_PROFILES: Dictionary = {
	1: {"hp": 1.0, "pressure": 1.0},
	2: {"hp": 1.35, "pressure": 0.92},
	3: {"hp": 1.70, "pressure": 0.88}
}


static func profile_for_party_size(party_size: int, max_players: int = 3) -> Dictionary:
	var clamped_size: int = clampi(party_size, 1, maxi(1, max_players))
	var profile_key: int = 3 if clamped_size >= 3 else clamped_size
	var profile: Dictionary = Dictionary(PARTY_PROFILES.get(profile_key, PARTY_PROFILES[1]))
	return {
		"model": MODEL_VERSION,
		"party_size": clamped_size,
		"profile_size": profile_key,
		"hp": float(profile.get("hp", 1.0)),
		"pressure": float(profile.get("pressure", 1.0))
	}
