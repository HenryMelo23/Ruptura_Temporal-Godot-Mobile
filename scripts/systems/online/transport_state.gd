class_name RTTransportState
extends RefCounted

const HEALTH_OK: String = "ok"
const HEALTH_DEGRADED: String = "degraded"
const HEALTH_STALLED: String = "stalled"
const HEALTH_WARMING: String = "warming"

static func adaptive_interval_ms(base_interval_ms: int, ping_ms: int, jitter_ms: float) -> int:
	var pressure: float = float(maxi(0, ping_ms)) + maxf(jitter_ms, 0.0) * 2.0
	var extra_ms: int = 0
	if pressure >= 190.0:
		extra_ms = 16
	elif pressure >= 100.0:
		extra_ms = 8
	return base_interval_ms + extra_ms


static func budget_interval_ms(payload_bytes: int, bytes_per_second: int, minimum_interval_ms: int) -> int:
	if payload_bytes <= 0 or bytes_per_second <= 0:
		return maxi(1, minimum_interval_ms)
	var interval_ms: int = int(ceil(float(payload_bytes) * 1000.0 / float(bytes_per_second)))
	return maxi(maxi(1, minimum_interval_ms), interval_ms)


static func health(now_ms: int, last_activity_ms: int, degraded_after_ms: int, stalled_after_ms: int, active: bool) -> String:
	if not active:
		return HEALTH_WARMING
	if last_activity_ms <= 0:
		return HEALTH_WARMING
	var age_ms: int = maxi(0, now_ms - last_activity_ms)
	if age_ms >= stalled_after_ms:
		return HEALTH_STALLED
	if age_ms >= degraded_after_ms:
		return HEALTH_DEGRADED
	return HEALTH_OK


static func configure_peer(peer: ENetPacketPeer, timeout_ms: int, timeout_min_ms: int, timeout_max_ms: int) -> bool:
	if peer == null:
		return false
	peer.set_timeout(timeout_ms, timeout_min_ms, timeout_max_ms)
	return true
