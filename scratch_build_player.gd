extends SceneTree

func _init():
	var root = Node2D.new()
	root.name = "Player"
	root.set_script(load("res://scripts/player.gd"))
	
	var sync = MultiplayerSynchronizer.new()
	sync.name = "MultiplayerSynchronizer"
	root.add_child(sync)
	sync.owner = root
	
	var config = SceneReplicationConfig.new()
	var props = [
		":pos", ":hp", ":hp_max", ":is_dead", ":manifestation", ":sec_manifestation",
		":last_dash_time", ":dash_start", ":dash_end", ":is_dashing", ":frame_idx", ":flip_h"
	]
	
	for prop in props:
		config.add_property(prop)
		config.property_set_replication_mode(prop, SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	
	sync.replication_config = config
	
	var packed_scene = PackedScene.new()
	packed_scene.pack(root)
	ResourceSaver.save(packed_scene, "res://scenes/Player.tscn")
	
	print("Player.tscn created successfully.")
	quit()
