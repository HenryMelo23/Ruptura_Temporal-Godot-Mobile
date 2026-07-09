extends SceneTree

func _init():
	var node = Node2D.new()
	node.position = Vector2(10, 20)
	print("Position via brackets: ", node["position"])
	
	node["position"] = Vector2(30, 40)
	print("New Position: ", node.position)
	
	quit()
