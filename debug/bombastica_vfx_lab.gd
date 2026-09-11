extends Node2D

@export var explosion_vfx_scene: PackedScene = preload("res://vfx/bombastica/BombasticaExplosionVFX.tscn")
@export var mine_vfx_scene: PackedScene = preload("res://vfx/bombastica/BombasticaMineExplosionVFX.tscn")
@export var ignition_vfx_scene: PackedScene = preload("res://vfx/bombastica/BombasticaIgnitionVFX.tscn")

var current_quality: String = "HIGH"
var reduced_flashes: bool = false
var reduced_motion: bool = false
var is_old_vfx: bool = false

@onready var label_status: Label = $CanvasLayer/UI/LabelStatus
@onready var spawn_center: Node2D = $SpawnCenter

func _ready() -> void:
	_update_status()

func _update_status() -> void:
	if label_status:
		label_status.text = "BOMBASTICA VFX LAB\nQuality: %s | Mode: %s | Reduced Flashes: %s | Reduced Motion: %s" % [
			current_quality,
			"OLD_VFX (Canvas Draw)" if is_old_vfx else "NEW_VFX (Godot 4.6 2D Engine)",
			str(reduced_flashes),
			str(reduced_motion)
		]

func spawn_q_normal() -> void:
	_spawn_explosion(1.0, 0)

func spawn_q_long_fuse() -> void:
	_spawn_explosion(1.35, 0)

func spawn_mine() -> void:
	if mine_vfx_scene:
		var inst = mine_vfx_scene.instantiate()
		add_child(inst)
		inst.play_at(spawn_center.global_position, current_quality)

func spawn_ignition() -> void:
	if ignition_vfx_scene:
		var inst = ignition_vfx_scene.instantiate()
		add_child(inst)
		inst.play_at(spawn_center.global_position, current_quality)

func spawn_chain(depth: int) -> void:
	_spawn_explosion(1.0 + depth * 0.1, depth)

func spawn_total_detonation() -> void:
	for i in range(4):
		var offset = Vector2(sin(i * 1.5) * 60, cos(i * 1.5) * 40)
		get_tree().create_timer(i * 0.12).timeout.connect(func():
			_spawn_explosion(1.0 + i * 0.1, i)
		)

func _spawn_explosion(scale_mult: float, chain_depth: int) -> void:
	if explosion_vfx_scene:
		var inst = explosion_vfx_scene.instantiate()
		add_child(inst)
		inst.play_at(
			spawn_center.global_position,
			scale_mult,
			current_quality,
			chain_depth,
			randi(),
			reduced_flashes,
			reduced_motion
		)

func toggle_quality() -> void:
	if current_quality == "HIGH":
		current_quality = "MEDIUM"
	elif current_quality == "MEDIUM":
		current_quality = "LOW"
	else:
		current_quality = "HIGH"
	_update_status()

func toggle_old_vfx() -> void:
	is_old_vfx = not is_old_vfx
	_update_status()

func toggle_reduced_flashes() -> void:
	reduced_flashes = not reduced_flashes
	_update_status()

func toggle_reduced_motion() -> void:
	reduced_motion = not reduced_motion
	_update_status()
