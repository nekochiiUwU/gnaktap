extends CharacterBody3D

var spawntime
var game
var damages:     float = 20.
var _owner:      String
var speed:       float =  50.
var grav:        float =  12.
var lifetime = 2
var distmax = 5
var dist = 0
var has_collided: Array = []

func init(__owner, _damages):
	_owner = __owner
	if _owner == str(multiplayer.get_unique_id()):
		get_node("CollisionShape3D").queue_free()
		#var blink = load("res://root/game/entities/bullet/blink.tscn").instantiate()
		#blink.position = position
		#get_parent().add_child(blink)
	game = get_node("../..")
	spawntime = game.time
	damages = _damages
	velocity = Vector3()
	max_slides = 1
	scale = Vector3(1,1,1)


func _physics_process(delta):
	#$Light.light_energy /= 1+delta*60
	scale -= Vector3(5,5,0)*delta
	move_and_collide(velocity*delta)
	print(position)
	if scale.x <= 0.1:
		queue_free()
	
	if get_slide_collision_count() != 0:
		var object = get_slide_collision(0)
		if object.get_collider() is Player and !(object.get_collider() in has_collided):
			var is_kill = object.get_collider().get_hit(_owner, damages, object.get_collider_shape().name)
			get_node("../Players/" + _owner).rpc_id(int(_owner), "hitmarker", damages, object.get_collider_shape().name, is_kill)
			has_collided.append(object.get_collider())

