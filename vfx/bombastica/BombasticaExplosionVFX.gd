class_name BombasticaExplosionVFX
extends Node2D

@export var auto_start: bool = true
@export var quality_level: String = "HIGH" # "LOW", "MEDIUM", "HIGH"

@onready var scorch_decal: Sprite2D = $ScorchDecal
@onready var explosion_core: AnimatedSprite2D = $ExplosionCore
@onready var residual_flame: AnimatedSprite2D = $ResidualFlame
@onready var flame_fragments: GPUParticles2D = $FlameFragments
@onready var sparks: GPUParticles2D = $Sparks
@onready var embers: GPUParticles2D = $Embers
@onready var debris: GPUParticles2D = $Debris
@onready var smoke_hot: GPUParticles2D = $SmokeHot
@onready var smoke_cold: GPUParticles2D = $SmokeCold
@onready var quantum_sparks: GPUParticles2D = $QuantumSparks
@onready var heat_distortion: ColorRect = $HeatDistortion
@onready var flash_light: PointLight2D = $FlashLight

var _life_timer: float = 0.0
var _max_lifetime: float = 2.5
var _is_playing: bool = false
var _light_tween: Tween
var _scorch_tween: Tween

static var _scorch_textures: Array = []

func _ready() -> void:
	if _scorch_textures.is_empty():
		_load_scorch_textures()
	if auto_start and not _is_playing:
		play_at(global_position)

static func _load_scorch_textures() -> void:
	for i in range(1, 4):
		var path = "res://vfx/bombastica/textures/scorch_0%d.png" % i
		if ResourceLoader.exists(path):
			_scorch_textures.append(load(path))

func play_at(pos: Vector2, scale_mult: float = 1.0, quality: String = "HIGH", chain_depth: int = 0, seed_val: int = 0, reduced_flashes: bool = false, reduced_motion: bool = false) -> void:
	global_position = pos
	quality_level = quality
	_is_playing = true
	_life_timer = 0.0
	show()
	
	# Apply Seed for visual variation
	var rng = RandomNumberGenerator.new()
	if seed_val != 0:
		rng.seed = seed_val
	else:
		rng.randomize()
		
	# Select Scorch Decal texture
	if not _scorch_textures.is_empty():
		scorch_decal.texture = _scorch_textures[rng.randi() % _scorch_textures.size()]
		scorch_decal.rotation = rng.randf_range(0, TAU)
		scorch_decal.scale = Vector2.ONE * (0.8 + scale_mult * 0.4)
		scorch_decal.modulate = Color(1, 1, 1, 0.85)
		scorch_decal.show()
		
		# Fade scorch decal over 3.0s
		if _scorch_tween and _scorch_tween.is_valid():
			_scorch_tween.kill()
		_scorch_tween = create_tween()
		_scorch_tween.tween_property(scorch_decal, "modulate:a", 0.0, 3.2).set_delay(0.8)
	else:
		scorch_decal.hide()

	# Scale Core Animation
	var core_scale = scale_mult * (1.0 + chain_depth * 0.08)
	explosion_core.scale = Vector2.ONE * core_scale
	explosion_core.rotation = rng.randf_range(-0.2, 0.2)
	explosion_core.play("default")
	
	# Residual Flame
	if quality != "LOW" and rng.randf() > 0.35:
		residual_flame.position = Vector2(rng.randf_range(-12, 12), rng.randf_range(-8, 8))
		residual_flame.scale = Vector2.ONE * (0.6 + rng.randf() * 0.4)
		residual_flame.show()
		residual_flame.play("default")
	else:
		residual_flame.hide()

	# Adjust Particle Amounts & Behavior per Quality
	var q_mult = 1.0
	if quality == "MEDIUM":
		q_mult = 0.65
	elif quality == "LOW":
		q_mult = 0.35
		
	var chain_mult = 1.0 + minf(0.5, chain_depth * 0.1)
	
	_trigger_particles(sparks, int(26 * q_mult * chain_mult), scale_mult)
	_trigger_particles(embers, int(22 * q_mult * chain_mult), scale_mult)
	_trigger_particles(debris, int(12 * q_mult * chain_mult), scale_mult)
	
	if quality != "LOW":
		_trigger_particles(smoke_hot, int(16 * q_mult), scale_mult)
		_trigger_particles(smoke_cold, int(14 * q_mult), scale_mult)
		_trigger_particles(flame_fragments, int(10 * q_mult), scale_mult)
	else:
		smoke_hot.emitting = false
		smoke_cold.emitting = false
		flame_fragments.emitting = false
		
	if chain_depth > 0 or rng.randf() > 0.5:
		_trigger_particles(quantum_sparks, int((12 if chain_depth > 0 else 6) * q_mult), scale_mult)
	else:
		quantum_sparks.emitting = false

	# PointLight2D Flash
	if quality != "LOW" and not reduced_flashes:
		flash_light.show()
		var target_energy = (2.2 + chain_depth * 0.4) * (0.4 if reduced_flashes else 1.0)
		flash_light.energy = target_energy
		flash_light.texture_scale = scale_mult * (1.2 + chain_depth * 0.1)
		
		if _light_tween and _light_tween.is_valid():
			_light_tween.kill()
		_light_tween = create_tween()
		_light_tween.tween_property(flash_light, "energy", 0.0, 0.18)
	else:
		flash_light.hide()

	# Heat Distortion
	if quality == "HIGH" and not reduced_motion:
		heat_distortion.show()
		heat_distortion.size = Vector2(160, 160) * scale_mult
		heat_distortion.position = -heat_distortion.size / 2.0
		var mat = heat_distortion.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("progress", 0.0)
			var h_tween = create_tween()
			h_tween.tween_method(func(val): mat.set_shader_parameter("progress", val), 0.0, 1.0, 0.4)
	else:
		heat_distortion.hide()

func _trigger_particles(emitter: GPUParticles2D, amount: int, scale_mult: float) -> void:
	if not emitter:
		return
	if amount <= 0:
		emitter.emitting = false
		return
	emitter.amount = max(1, amount)
	emitter.scale = Vector2.ONE * scale_mult
	emitter.restart()
	emitter.emitting = true

func _process(delta: float) -> void:
	if not _is_playing:
		return
	_life_timer += delta
	if _life_timer >= _max_lifetime:
		_is_playing = false
		hide()
