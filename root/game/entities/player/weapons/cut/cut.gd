extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	if is_multiplayer_authority():
		get_node("Area3D/Collision").disabled = true


func _on_area_3d_body_entered(body):
	var _owner = str(get_node("../../..").name)
	var damages
	if get_node("AnimationPlayer").current_animation == "slash":
		damages = 50
	elif get_node("AnimationPlayer").current_animation == "stab":
		damages = 34
	else:
		damages = 0 # ?????
	if body is Player:
		body.get_hit(_owner, damages, "Collision")
		get_node("../../..").rpc_id(int(_owner), "hitmarker", damages, "Collision")
	elif body is Target:
		if multiplayer.get_unique_id() == 1:
			body.get_hit(_owner, damages)
			get_node("../../..").rpc_id(int(_owner), "hitmarker", damages, "Collision")
	get_node("Area3D").set_deferred("monitoring", false)

