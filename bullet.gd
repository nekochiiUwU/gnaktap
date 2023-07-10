extends CharacterBody3D

var spawntime
var game
var damages
var speed:       float =  50.
var grav:        float =  1.2
var lifetime = 1

func _ready():
	game = get_node("../..")
	spawntime = game.time
	velocity = -transform.basis.z * speed

func _physics_process(delta):
	velocity.y -= grav*delta
	var collision = move_and_collide(velocity*delta)
	if game.time - spawntime > lifetime:
		queue_free()
	
	if collision and collision.get_collision_count():
		for i in collision.get_collision_count():
			var object = collision.get_collider(i)
			if object is Player:
				object.get_hit(damages)
		queue_free()
