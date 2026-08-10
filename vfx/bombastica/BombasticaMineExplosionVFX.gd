class_name BombasticaMineExplosionVFX
extends Node2D

@onready var explosion_core: AnimatedSprite2D = $ExplosionCore
@onready var sparks: GPUParticles2D = $Sparks
@onready var debris: GPUParticles2D = $Debris
@onready var embers: GPUParticles2D = $Embers
@onready var flash_light: PointLight2D = $FlashLight

var _life_timer: float = 0.0
var _max_lifetime: float = 1.2
var _is_playing: bool = false
var _light_tween: Tween

func play_at(pos: Vector2, quality: String = "HIGH", _seed_val: int = 0) -> void:
	global_position = pos
	_is_playing = true
	_life_timer = 0.0
	show()
	
	explosion_core.scale = Vector2(1.2, 0.75) # Flatter horizontal blast shape
	explosion_core.play("default")
	
	var q_mult = 1.0 if quality == "HIGH" else (0.6 if quality == "MEDIUM" else 0.3)
	
	sparks.amount = int(32 * q_mult)
	sparks.restart()
	sparks.emitting = true
	
	debris.amount = int(16 * q_mult)
	debris.restart()
	debris.emitting = true
	
	embers.amount = int(14 * q_mult)
	embers.restart()
	embers.emitting = true
	
	if quality != "LOW":
		flash_light.show()
		flash_light.energy = 1.6
		if _light_tween and _light_tween.is_valid():
			_light_tween.kill()
		_light_tween = create_tween()
		_light_tween.tween_property(flash_light, "energy", 0.0, 0.12)
	else:
		flash_light.hide()

func _process(delta: float) -> void:
	if not _is_playing:
		return
	_life_timer += delta
	if _life_timer >= _max_lifetime:
		_is_playing = false
		hide()
