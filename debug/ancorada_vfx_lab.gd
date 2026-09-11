extends Node2D

@export var counterweight_vfx_scene: PackedScene = preload("res://vfx/ancorada/AncoradaCounterweightVFX.tscn")

var current_quality: String = "HIGH"
var reduced_motion: bool = false
var selected_lastro: int = 5

@onready var spawn_center: Node2D = $SpawnCenter
@onready var label_status: Label = $CanvasLayer/UI/LabelStatus

func _ready() -> void:
	_update_status()

func _update_status() -> void:
	if label_status:
		label_status.text = "ANCORADA VFX LAB (Godot 4.6 Engine)\nLastro Level: L%d | Quality: %s | Reduced Motion: %s" % [
			selected_lastro,
			current_quality,
			str(reduced_motion)
		]

func spawn_hab1_l(lastro_lvl: int) -> void:
	selected_lastro = clamp(lastro_lvl, 0, 5)
	_update_status()
	if counterweight_vfx_scene:
		var inst = counterweight_vfx_scene.instantiate()
		add_child(inst)
		inst.global_position = spawn_center.global_position
		inst.setup(selected_lastro, current_quality, reduced_motion)

func spawn_current_lastro() -> void:
	spawn_hab1_l(selected_lastro)

func set_quality(q: String) -> void:
	current_quality = q
	_update_status()

func toggle_reduced_motion() -> void:
	reduced_motion = not reduced_motion
	_update_status()
