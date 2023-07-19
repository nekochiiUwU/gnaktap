class_name Target
extends CharacterBody3D

var health: float = 100

func _ready():
	if is_multiplayer_authority():
		spawn()


func spawn():
	position = Vector3(randf_range(-6, 6), randf_range(4, 11), randf_range(-6, 6))
	health = 100
	visible = true


func _process(_delta):
	if is_multiplayer_authority():
		rpc("online_syncronisation", position, rotation, health, visible)


func get_hit(_owner, _damages):
	health -= _damages
	if health <= 0:
		get_node("../Players/" + _owner).rpc_id(int(_owner), "target", 2)
		die() 


func die():
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false
	rpc("online_syncronisation", position, rotation, health, visible)
	await get_tree().create_timer(2).timeout
	spawn()
	process_mode = Node.PROCESS_MODE_INHERIT


@rpc("any_peer", "call_remote", "unreliable", 3)
func online_syncronisation(_position: Vector3, _rotation: Vector3, _health: float, _visible: bool):
	position = _position
	rotation = _rotation
	health = _health
	visible = _visible
	if visible == false:
		process_mode = Node.PROCESS_MODE_DISABLED
	elif process_mode == Node.PROCESS_MODE_DISABLED:
		process_mode = Node.PROCESS_MODE_INHERIT
