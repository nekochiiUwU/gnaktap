extends Node3D

var spawnpoints = []
var time = 0

func _ready():
	spawn_map(0)


func _exit_tree():
	spawn_map(0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func spawn_map(_id):
	var map = load("res://map.tscn").instantiate()
	add_child(map)
	spawnpoints = map.get_node("Spawnpoints").get_children()


func _process(delta):
	time += delta
	if Input.is_action_just_pressed("quit"):
		get_node("/root/Main Menu").visible = true
		get_node("/root/Main Menu").process_mode = Node.PROCESS_MODE_INHERIT
		if get_node("/root/").has_node("Network"):
			get_node("/root/Network").start_lobby()
		queue_free()
	if Input.is_action_just_pressed("lock_mouse"):
		Input.mouse_mode = int(!Input.mouse_mode)*2
