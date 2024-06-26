extends CharacterBody3D

var spawntime
var game
var damages:     float = 20.
var _owner:     String
var speed:       float =  50.
var grav:        float =  12.
var has_collided: Array = []
var lifetime = 2
var distmax = 5
var dist = 0

func init(__owner, _damages, _speed):
	_owner = __owner
	if _owner == str(multiplayer.get_unique_id()):
		get_node("Collision").queue_free()
		#var blink = load("res://root/game/entities/bullet/blink.tscn").instantiate()
		#blink.position = position
		#get_parent().add_child(blink)
	game = get_node("../..")
	spawntime = game.time
	damages = _damages
	speed = _speed
	velocity = -transform.basis.z * speed
	max_slides = 1


func _physics_process(delta):
	#$Light.light_energy /= 1+delta*60
	#velocity.y -= grav/10*delta
	move_and_slide()
	
	move_and_collide(velocity*delta)
	dist += (velocity*delta).length()
	if dist > distmax:
		queue_free()
	
	if get_slide_collision_count() != 0:
		var object = get_slide_collision(0)
		if object.get_collider() is Player and !(object.get_collider() in has_collided):
			var is_kill = object.get_collider().get_hit(_owner, damages, object.get_collider_shape().name)
			get_node("../Players/" + _owner).rpc_id(int(_owner), "hitmarker", damages, object.get_collider_shape().name, is_kill)
			has_collided.append(object.get_collider())
		#queue_free()
