extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_3d_body_entered(body):
	var _owner = str(get_node("../../..").name)
	var damages = 50
	if body is Player:
		body.get_hit(_owner, damages, "Collision")
		get_node("../../..").rpc_id(int(_owner), "hitmarker", damages, "Collision")
	elif body is Target:
		if multiplayer.get_unique_id() == 1:
			body.get_hit(_owner, damages)
			get_node("../../..").rpc_id(int(_owner), "hitmarker", damages, "Collision")
	get_node("Area3D").set_deferred("monitoring", false)

