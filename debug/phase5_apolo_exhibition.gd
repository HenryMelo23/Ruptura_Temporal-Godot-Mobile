extends Node2D

@export var manifestation_index: int = 0

var game: Node


func _ready() -> void:
	game = preload("res://scenes/Main.tscn").instantiate()
	game.name = "Phase5Main"
	add_child(game)
	call_deferred("_start_exhibition")


func _start_exhibition() -> void:
	if game != null and game.has_method("start_apolo_phase5_exhibition"):
		game.start_apolo_phase5_exhibition(manifestation_index)
