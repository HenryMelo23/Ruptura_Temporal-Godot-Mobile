class_name RTBoss6StageController
extends RefCounted

const MAX_TEAM_TARGETS := 3

var core: Node
var _team_target_sequence := 0


func configure(p_core: Node) -> void:
	core = p_core


func reset_team_target_sequence() -> void:
	_team_target_sequence = 0


func attack_target_count(entries: Array) -> int:
	var peers: Dictionary = {}
	for value in entries:
		var peer_id := int(Dictionary(value).get("target_peer", 0))
		if peer_id > 0:
			peers[peer_id] = true
	return peers.size()


func next_team_targets() -> Array:
	if core == null:
		return []
	var available: Array = core._combat_targets()
	available.sort_custom(func(a, b): return int(Dictionary(a).get("peer_id", 0)) < int(Dictionary(b).get("peer_id", 0)))
	if available.size() <= MAX_TEAM_TARGETS:
		return available
	var selected: Array = []
	for offset in range(MAX_TEAM_TARGETS):
		selected.append(available[posmod(_team_target_sequence + offset, available.size())])
	_team_target_sequence = posmod(_team_target_sequence + MAX_TEAM_TARGETS, available.size())
	return selected


func build_vertebral_scythes(hp_pct: float, precise: bool) -> Array:
	var targets := next_team_targets()
	if targets.is_empty():
		targets.append({"peer_id": 0, "pos": core._boss_target_pos(true, 0.18), "local": true})
	var solo_count := 5 if hp_pct > 0.6 else (7 if hp_pct > 0.3 else 9)
	if precise:
		solo_count = maxi(solo_count, 8)
	var per_target := solo_count
	if targets.size() > 1:
		per_target = 3 if hp_pct > 0.3 else 4
		if precise:
			per_target = maxi(per_target, 4)
	var bones: Array = []
	for target_index in range(targets.size()):
		var target := Dictionary(targets[target_index])
		var target_pos := Vector2(target.get("pos", core.player_pos))
		var aim: float = (target_pos - core.boss_pos).angle()
		var fan: float = (0.42 if precise else 0.62) if targets.size() > 1 else (0.58 if precise else 1.22)
		for bone_index in range(per_target):
			var spread := (float(bone_index) - float(per_target - 1) * 0.5) * fan / maxf(1.0, float(per_target - 1))
			var direction := Vector2.from_angle(aim + spread).normalized()
			var side_range := 10.0 if precise else 28.0
			var reach := clampf(core.boss_pos.distance_to(target_pos) + core.rng.randf_range(45.0, 105.0), 390.0, 680.0)
			bones.append({
				"dir": direction,
				"distance": reach,
				"side": core.rng.randf_range(-side_range, side_range),
				"phase": core.rng.randf_range(0.0, TAU),
				"target_peer": int(target.get("peer_id", 0)),
				"target_index": target_index,
				"target_pos": target_pos,
				"hit_local_out": false,
				"hit_local_return": false,
			})
	return bones


func build_acid_bloom_spots() -> Array:
	var targets := next_team_targets()
	if targets.is_empty():
		targets.append({"peer_id": 0, "pos": core._boss_target_pos(true, 0.18), "local": true})
	var available_slots := maxi(0, core.BOSS6_POOL_MAX - core.boss6_lodarian_pools.size())
	var total := mini(available_slots, core.BOSS6_ACID_BLOOM_COUNT + core._boss_party_hazard_bonus(2))
	total = maxi(mini(targets.size(), available_slots), total)
	var spots: Array = []
	for spot_index in range(total):
		var target_index := spot_index % targets.size()
		var target := Dictionary(targets[target_index])
		var target_pos := Vector2(target.get("pos", core.player_pos))
		var ring_slot: int = floori(float(spot_index) / float(targets.size()))
		var best := target_pos
		var best_score := -INF
		for attempt in range(18):
			var radius: float = core.rng.randf_range(18.0, 92.0) if ring_slot == 0 else core.rng.randf_range(150.0, 310.0)
			var angle: float = core.rng.randf_range(0.0, TAU)
			var candidate: Vector2 = (target_pos + Vector2.from_angle(angle) * radius).clamp(Vector2(110, 110), core.WORLD_SIZE - Vector2(110, 110))
			var spacing := 9999.0
			for existing in spots:
				spacing = minf(spacing, candidate.distance_to(Vector2(Dictionary(existing).get("pos", candidate))))
			var preferred := 62.0 if ring_slot == 0 else 225.0
			var score := minf(spacing, 360.0) - absf(candidate.distance_to(target_pos) - preferred) * 0.72
			if score > best_score:
				best_score = score
				best = candidate
		spots.append({
			"pos": best,
			"target_peer": int(target.get("peer_id", 0)),
			"target_index": target_index,
		})
	return spots


func build_carnage_drop_batch() -> Array:
	var targets := next_team_targets()
	if targets.is_empty():
		targets.append({"peer_id": 0, "pos": core._boss_target_pos(true, 0.18), "local": true})
	var drops: Array = []
	for target_index in range(targets.size()):
		var target := Dictionary(targets[target_index])
		var target_pos := Vector2(target.get("pos", core.player_pos))
		var spread: Vector2 = Vector2.from_angle(core.rng.randf_range(0.0, TAU)) * core.rng.randf_range(0.0, 54.0)
		drops.append({
			"pos": (target_pos + spread).clamp(Vector2(80, 80), core.WORLD_SIZE - Vector2(80, 80)),
			"fall": 0.78,
			"max": 0.78,
			"spawned": false,
			"phase": core.rng.randf_range(0.0, TAU),
			"target_peer": int(target.get("peer_id", 0)),
			"target_index": target_index,
		})
	return drops


func update(delta: float) -> void:
	if core == null or not core._is_world_authority() or not core.boss_active or core.boss_dead:
		return
	var next_stage: int = core._boss6_stage_for_hp()
	if next_stage > core.boss6_stage:
		_enter_stage(next_stage)
	if core.boss6_relocating or core.boss6_state in [core.BOSS6_STATE_TRANSITION, core.BOSS6_STATE_SPECIAL, core.BOSS6_STATE_STUNNED]:
		return
	var target: Vector2 = core._boss_target_pos(true, 0.12)
	var offset: Vector2 = target - core.boss_pos
	var distance := offset.length()
	if distance <= 0.01:
		return
	var toward := offset / distance
	var tangent := toward.orthogonal()
	core.boss6_move_phase += delta * (0.78 + float(core.boss6_stage) * 0.24)
	var weave := sin(core.boss6_move_phase)
	var move_dir := Vector2.ZERO
	var speed: float = core.BOSS6_STAGE_1_MOVE_SPEED
	match core.boss6_stage:
		1:
			move_dir = toward * clampf((distance - 350.0) / 180.0, -0.55, 1.0) + tangent * weave * 0.18
		2:
			speed = core.BOSS6_STAGE_2_MOVE_SPEED
			move_dir = tangent * (0.82 if weave >= 0.0 else -0.82) + toward * clampf((distance - 300.0) / 150.0, -0.72, 0.72)
		_:
			speed = core.BOSS6_STAGE_3_MOVE_SPEED
			move_dir = toward * (0.92 if distance > 185.0 else -0.34) + tangent * weave * 0.34
	if move_dir.length_squared() <= 0.01:
		return
	var state_scale := 1.0
	if core.boss6_state == core.BOSS6_STATE_TELEGRAPH:
		state_scale = 0.34
	elif core.boss6_state == core.BOSS6_STATE_EXECUTING:
		state_scale = 0.52
	var margin := Vector2(150.0, 125.0)
	core.boss_pos = (core.boss_pos + move_dir.normalized() * speed * state_scale * delta).clamp(margin, core.WORLD_SIZE - margin)


func _enter_stage(stage: int) -> void:
	core.boss6_stage = clampi(stage, 1, 3)
	core._boss6_cancel_active_attacks()
	core.boss6_state = core.BOSS6_STATE_TRANSITION
	core.boss6_state_timer = core.BOSS6_STAGE_TRANSITION_TIME
	core.boss6_wait_timer = 0.0
	var title := "ESTAGIO II - FLORADA ACIDA"
	var color := Color(0.68, 1.0, 0.22)
	if core.boss6_stage >= 3:
		title = "ESTAGIO III - MARE DE CARNIFICINA"
		color = Color(1.0, 0.28, 0.12)
	core._add_text(title, core.boss_pos + Vector2(0.0, -168.0), color, 1.65, 24)
	core._spawn_radial_particles(core.boss_pos, color, 72)
	for ring in range(3):
		core.shockwaves.append({
			"pos": core.boss_pos,
			"radius": 34.0 + float(ring) * 18.0,
			"max": 250.0 + float(ring) * 76.0,
			"life": 0.68 + float(ring) * 0.14,
			"damage": 0.0,
			"hit": {},
			"visual_only": true,
			"color": color,
		})
	core._play_sfx("Boss-Onda.mp3", 0.04, 0.58, 0.74)
