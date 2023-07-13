class_name Target
extends CharacterBody3D

var Game
var health: float = 100

func _ready():
	Game = get_node("../..")
	spawn()


func _process(_delta):
	pass


func spawn():
	position = Vector3(randf_range(-12,12), randf_range(1, 6), randf_range(-6,6))
	health = 100
	visible = true
	rpc("online_syncronisation", position, rotation, health, visible)


func get_hit(damages):
	health -= damages
	if health < 0:
		die() 


func die():
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false
	rpc("online_syncronisation", position, rotation, health, visible)
	await get_tree().create_timer(2).timeout
	spawn()
	process_mode = Node.PROCESS_MODE_INHERIT


@rpc("any_peer", "call_remote", "unreliable", 0)
func online_syncronisation(_position: Vector3, _rotation: Vector3, _health: float, _visible: bool):
	position = _position
	rotation = _rotation
	health = _health
	visible = _visible
