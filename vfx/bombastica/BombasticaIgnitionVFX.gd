class_name BombasticaIgnitionVFX
extends Node2D

@onready var explosion_core: AnimatedSprite2D = $ExplosionCore
@onready var embers: GPUParticles2D = $Embers
@onready var quantum_sparks: GPUParticles2D = $QuantumSparks

var _life_timer: float = 0.0
var _max_lifetime: float = 0.8
var _is_playing: bool = false

func play_at(pos: Vector2, quality: String = "HIGH") -> void:
	position = pos
	set_meta("bombastica_world_origin", pos)
	set_meta("bombastica_origin_space", "world")
	_is_playing = true
	_life_timer = 0.0
	show()
	
	explosion_core.scale = Vector2(0.55, 0.55)
	explosion_core.play("default")
	
	if quality != "LOW":
		embers.amount = 8
		embers.restart()
		embers.emitting = true
		
		quantum_sparks.amount = 8
		quantum_sparks.restart()
		quantum_sparks.emitting = true
	else:
		embers.emitting = false
		quantum_sparks.emitting = false

func _process(delta: float) -> void:
	if not _is_playing:
		return
	_life_timer += delta
	if _life_timer >= _max_lifetime:
		_is_playing = false
		hide()
