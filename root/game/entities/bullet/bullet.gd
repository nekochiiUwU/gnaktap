extends CharacterBody3D

var spawntime
var game
var damages:     float = 20.
var _owner:     String
var speed:       float =  50.
var grav:        float =  12.
var lifetime = 1

func init(__owner, _damages, _speed):
	_owner = __owner
	if _owner == str(multiplayer.get_unique_id()):
		get_node("Collision").queue_free()
	game = get_node("../..")
	spawntime = game.time
	damages = _damages
	speed = _speed
	velocity = -transform.basis.z * speed
	max_slides = 1


func _physics_process(delta):
	#$Light.light_energy /= 1+delta*60
	velocity.y -= grav*delta
	move_and_slide()
	
	var collision = move_and_collide(velocity*delta)
	if game.time - spawntime > lifetime:
		queue_free()
	
	if get_slide_collision_count() != 0:
		var object = get_slide_collision(0).get_collider()
		if object is Player:
			object.get_hit(_owner, damages, collision.get_collider_shape().name)
			get_node("../Players/" + _owner).rpc_id(int(_owner), "hitmarker", damages, collision.get_collider_shape().name)
		queue_free()
