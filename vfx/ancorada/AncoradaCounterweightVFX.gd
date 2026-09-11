extends Node2D

# AncoradaCounterweightVFX.gd
# Visual controller for HAB1 Queda de Contrapeso Celestial.

var L: int = 0
var quality_profile: String = "HIGH"
var reduced_motion: bool = false
var impact_radius: float = 105.0

var age: float = 0.0
var impacted: bool = false
var finished: bool = false

var telegraph_time: float = 0.10
var fall_time: float = 0.28
var total_fall_duration: float = 0.38
var remain_time: float = 0.90

func setup(p_L: int, p_profile: String = "HIGH", p_reduced: bool = false) -> void:
	L = clamp(p_L, 0, 5)
	quality_profile = p_profile
	reduced_motion = p_reduced
	impact_radius = 105.0 + 14.0 * float(L)
	remain_time = 0.90 + 0.12 * float(L)
	age = 0.0
	impacted = false
	finished = false
	queue_redraw()

func _process(delta: float) -> void:
	if finished:
		return
	age += delta
	if not impacted and age >= total_fall_duration:
		impacted = true
		_trigger_impact_vfx()
	if age >= total_fall_duration + remain_time + 2.4:
		finished = true
		queue_free()
	queue_redraw()

func _trigger_impact_vfx() -> void:
	# Triggers impact particles, light flash, and sound feedback if standalone
	pass

func _draw() -> void:
	var anchor_visual_size: float = 72.0 + 4.0 * float(L)
	var half_size: float = anchor_visual_size * 0.5

	if age < telegraph_time:
		# Telegraph Phase (0.0s - 0.10s)
		var p: float = clampf(age / telegraph_time, 0.0, 1.0)
		var tele_alpha: float = lerpf(0.12, 0.22, p)
		draw_arc(Vector2.ZERO, impact_radius, 0.0, TAU, 48, Color(0.28, 1.0, 0.36, tele_alpha), 2.2)
		draw_circle(Vector2.ZERO, 18.0 * p, Color(0.1, 0.4, 0.2, 0.15))
		
		# Pre-impact ground vibration motes
		if quality_profile != "LOW":
			for i in range(3 + L):
				var ang: float = float(i) * TAU / float(3 + L) + age * 12.0
				var r: float = impact_radius * (0.3 + 0.5 * sin(age * 20.0 + float(i)))
				draw_circle(Vector2.from_angle(ang) * r, 2.0, Color(0.4, 1.0, 0.5, 0.4))
	
	elif age < total_fall_duration:
		# Fall Phase (0.10s - 0.38s)
		var fall_p: float = clampf((age - telegraph_time) / fall_time, 0.0, 1.0)
		var eased_p: float = 1.0 - pow(1.0 - fall_p, 2.2) # Easing acceleration
		var start_y: float = -280.0
		var curr_y: float = lerpf(start_y, 0.0, eased_p)

		# Shadow scaling underneath
		var shadow_radius: float = lerpf(18.0, 40.0 + 4.0 * float(L), eased_p)
		var shadow_alpha: float = lerpf(0.20, 0.55, eased_p)
		draw_circle(Vector2.ZERO, shadow_radius, Color(0.01, 0.03, 0.015, shadow_alpha))
		draw_arc(Vector2.ZERO, impact_radius, 0.0, TAU, 48, Color(0.28, 1.0, 0.36, 0.25), 1.8)

		# Draw Overhead Falling Anchor
		var anchor_pos: Vector2 = Vector2(0.0, curr_y)
		_draw_anchor_sprite(anchor_pos, anchor_visual_size, 1.0)

		# Motion Smear Trail
		if quality_profile != "LOW":
			for trail_i in range(3):
				var trail_y: float = curr_y - float(trail_i + 1) * 24.0 * (1.0 - fall_p)
				if trail_y > start_y:
					_draw_anchor_sprite(Vector2(0.0, trail_y), anchor_visual_size * 0.9, 0.25 - float(trail_i) * 0.07)

	else:
		# Impact & Lingering Phase (age >= 0.38s)
		var post_age: float = age - total_fall_duration
		var remain_p: float = clampf(post_age / remain_time, 0.0, 1.0)
		var crack_p: float = clampf(post_age / 2.4, 0.0, 1.0)

		# 1. Ground Crack Decal (lasts 2.4s)
		if crack_p < 1.0:
			var crack_alpha: float = 1.0 - crack_p
			var crack_color: Color
			if post_age < 0.4:
				crack_color = Color(0.38, 1.0, 0.42, crack_alpha) # Incandescent emerald
			elif post_age < 1.2:
				crack_color = Color(0.08, 0.42, 0.16, crack_alpha) # Dark emerald
			else:
				crack_color = Color(0.22, 0.25, 0.22, crack_alpha * 0.6) # Soil gray
			
			var crack_r: float = impact_radius * 0.75
			for crack_line in range(6):
				var ang: float = float(crack_line) * TAU / 6.0 + 0.18
				var p1: Vector2 = Vector2.from_angle(ang) * (crack_r * 0.2)
				var p2: Vector2 = Vector2.from_angle(ang + 0.08) * (crack_r * 0.65)
				var p3: Vector2 = Vector2.from_angle(ang - 0.05) * crack_r
				draw_line(p1, p2, crack_color, 3.0 * (1.0 - crack_p * 0.5))
				draw_line(p2, p3, crack_color, 1.8 * (1.0 - crack_p * 0.5))

		# 2. Impact Shockwave & Flash (0.0s - 0.25s post impact)
		if post_age < 0.25:
			var flash_p: float = post_age / 0.25
			var wave_r: float = lerpf(12.0, impact_radius, 1.0 - pow(1.0 - flash_p, 2.0))
			var wave_alpha: float = 1.0 - flash_p
			draw_arc(Vector2.ZERO, wave_r, 0.0, TAU, 56, Color(0.84, 1.0, 0.72, wave_alpha * 0.9), 4.0)
			draw_arc(Vector2.ZERO, wave_r * 0.8, 0.0, TAU, 48, Color(0.28, 1.0, 0.36, wave_alpha * 0.6), 2.2)
			draw_circle(Vector2.ZERO, wave_r * 0.3, Color(1.0, 1.0, 1.0, wave_alpha * 0.7))

		# 3. Lingering Counterweight Anchor
		var anchor_alpha: float = 1.0 - remain_p
		if anchor_alpha > 0.0:
			var sink_y: float = remain_p * 14.0 # Slightly sinks into ground
			_draw_anchor_sprite(Vector2(0.0, sink_y), anchor_visual_size, anchor_alpha)

func _draw_anchor_sprite(pos: Vector2, sz: float, alpha: float) -> void:
	var s: float = sz / 32.0
	var outline: Color = Color(0.01, 0.03, 0.015, 0.95 * alpha)
	var body: Color = Color(0.07, 0.43, 0.16, 0.98 * alpha)
	var edge: Color = Color(0.32, 1.0, 0.38, 1.0 * alpha)
	var core: Color = Color(0.88, 1.0, 0.78, 0.95 * alpha)

	draw_set_transform(pos, 0.0, Vector2.ONE)
	# Heavy Celestial Anchor Crown Ring
	draw_arc(Vector2(0.0, -9.8) * s, 6.5 * s, 0.0, TAU, 28, outline, 5.2 * s, true)
	draw_arc(Vector2(0.0, -9.8) * s, 6.5 * s, 0.0, TAU, 28, edge, 2.5 * s, true)
	
	# Central Heavy Shaft
	draw_line(Vector2(0.0, -4.0) * s, Vector2(0.0, 12.0) * s, outline, 7.0 * s, true)
	draw_line(Vector2(0.0, -4.0) * s, Vector2(0.0, 12.0) * s, body, 4.2 * s, true)
	draw_line(Vector2(0.0, -4.0) * s, Vector2(0.0, 12.0) * s, core, 1.4 * s, true)
	
	# Crossbar
	draw_line(Vector2(-8.0, 1.5) * s, Vector2(8.0, 1.5) * s, outline, 6.0 * s, true)
	draw_line(Vector2(-8.0, 1.5) * s, Vector2(8.0, 1.5) * s, edge, 3.0 * s, true)

	# Massive Flukes
	var left_fluke: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 9.0) * s,
		Vector2(-10.0, 15.0) * s,
		Vector2(-15.0, 7.5) * s,
		Vector2(-10.5, 8.8) * s,
		Vector2(-5.0, 6.0) * s
	])
	var right_fluke: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 9.0) * s,
		Vector2(10.0, 15.0) * s,
		Vector2(15.0, 7.5) * s,
		Vector2(10.5, 8.8) * s,
		Vector2(5.0, 6.0) * s
	])
	draw_polyline(left_fluke, outline, 6.0 * s, true)
	draw_polyline(right_fluke, outline, 6.0 * s, true)
	draw_polyline(left_fluke, edge, 3.0 * s, true)
	draw_polyline(right_fluke, edge, 3.0 * s, true)

	draw_circle(Vector2.ZERO, 3.0 * s, core)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
