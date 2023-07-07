extends Node3D


func _ready():
	spawn_map(0)

func spawn_map(id):
	var map = load("res://map.tscn").instantiate()
	add_child(map)

func _process(delta):
	pass
