extends Node2D
class_name NetPlayer


@export var pos: Vector2 = Vector2(-1000, -1000)
@export var hp: float = 100.0
@export var hp_max: float = 100.0
@export var is_dead: bool = false
@export var manifestation: int = 0
@export var sec_manifestation: int = 0
@export var last_dash_time: float = -100.0
@export var dash_start: Vector2 = Vector2.ZERO
@export var dash_end: Vector2 = Vector2.ZERO
@export var is_dashing: bool = false
@export var frame_idx: int = 0
@export var flip_h: bool = false

func _enter_tree() -> void :

	set_multiplayer_authority(name.to_int())


func play_portal_spawn_animation() -> void :
	var shader_path: = "res://shaders/player_portal_materialize.gdshader"
	if ResourceLoader.exists(shader_path):
		var mat: = ShaderMaterial.new()
		mat.shader = load(shader_path) as Shader
		mat.set_shader_parameter("spawn_progress", 0.0)
		material = mat
		var tween: = create_tween()
		tween.tween_property(mat, "shader_parameter/spawn_progress", 1.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tween.finished
		material = null
