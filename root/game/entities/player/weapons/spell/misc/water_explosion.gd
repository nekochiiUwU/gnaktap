extends Node3D

var spawntime
var game
var damages:     float = 20.
var _owner:     String
var speed:       float =  50.
var grav:        float =  12.
var lifetime = 2
var distmax = 5
var dist = 0
var has_collided: Array = []

func init(__owner, _damages):
	_owner = __owner
	if _owner == str(multiplayer.get_unique_id()):
		get_node("Area3D/Collision").queue_free()
		#var blink = load("res://root/game/entities/bullet/blink.tscn").instantiate()
		#blink.position = position
		#get_parent().add_child(blink)
	game = get_node("../..")
	spawntime = game.time
	damages = _damages
	scale = Vector3(1,1,1)
	print("bouh !")


func _physics_process(delta):
	#$Light.light_energy /= 1+delta*60
	scale += Vector3(5,5,5)*delta
	visible = true
	if scale.x > 3:
		queue_free()
	
	if len($Area3D.get_overlapping_bodies()) != 0:
		for body in $Area3D.get_overlapping_bodies():
			if body is Player and !(body in has_collided):
				var is_kill = body.get_hit(_owner, damages, "")
				get_node("../Players/" + _owner).rpc_id(int(_owner), "hitmarker", damages, "", is_kill)
				has_collided.append(body)
