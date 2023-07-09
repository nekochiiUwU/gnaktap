extends Node3D


func _ready():
	spawn_map(0)

func spawn_map(_id):
	var map = load("res://map.tscn").instantiate()
	add_child(map)

func _process(_delta):
	if Input.is_action_just_pressed("quit"):
		get_node("/root/Main Menu").visible = true
		get_node("/root/Main Menu").process_mode = Node.PROCESS_MODE_INHERIT
		if get_node("/root/").has_node("Network"):
			get_node("/root/Network").start_lobby()
		queue_free()
