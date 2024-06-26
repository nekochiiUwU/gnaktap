extends CharacterBody3D

var spawntime
var game
var damages:     float = 20.
var _owner:     String
var speed:       float =  50.
var grav:        float =  12.
var lifetime = 2
var distmax = 5
var dist = 0

func init(__owner, _damages, _speed, _player):
	_owner = __owner
	velocity = _player.velocity
	#if _owner == str(multiplayer.get_unique_id()):
		#get_node("CollisionShape3D").queue_free()
		#var blink = load("res://root/game/entities/bullet/blink.tscn").instantiate()
		#blink.position = position
		#get_parent().add_child(blink)
	game = get_node("../..")
	spawntime = game.time
	damages = _damages
	speed = _speed
	velocity = -transform.basis.z * speed
	max_slides = 1

func qfree():
	queue_free()


func _physics_process(delta):
	#$Light.light_energy /= 1+delta*60
	velocity.y -= grav*delta
	var collision = move_and_collide(velocity*delta)
	
	if game.time - spawntime > lifetime:
		queue_free()

	if collision and !collision.get_collider() is Player:
		velocity.y = 10
		var explosion = load("res://root/game/entities/player/weapons/spell/misc/water_explosion.tscn").instantiate()
		get_parent().add_child(explosion)
		explosion.global_position = global_position
		explosion.global_rotation = global_rotation
		explosion.init(_owner, damages)
		
		queue_free()
