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
	if _owner == str(multiplayer.get_unique_id()):
		get_node("Collision").queue_free()
		#var blink = load("res://root/game/entities/bullet/blink.tscn").instantiate()
		#blink.position = position
		#get_parent().add_child(blink)
	game = get_node("../..")
	spawntime = game.time
	damages = _damages
	lifetime = _speed
	velocity = Vector3()
	max_slides = 1


func _physics_process(delta):
	#$Light.light_energy /= 1+delta*60
	
	if game.time - spawntime > lifetime:
		var laser = load("res://root/game/entities/player/weapons/spell/misc/lightlaser.tscn").instantiate()
		get_parent().add_child(laser)
		laser.global_position = global_position
		laser.global_rotation = global_rotation
		laser.init(_owner, damages)
		queue_free()
