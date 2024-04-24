extends Node3D


func primary_process(_delta):
	pass


func secondary_process(_delta):
	pass


func idle_process(_delta):
	pass


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
	get_node("Area3D").set_deferred("monitoring", false)
