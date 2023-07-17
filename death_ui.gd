extends Node


var Game: Node3D

var can_respawn = false

var death_time: float = 0

# Called when the node enters the scene tree for the first time.
func _enter_tree():
	Game = get_node("/root/Game")
	death_time = Game.time
	can_respawn = false
	get_node("Control/Respawn").disabled = true
	await get_tree().create_timer(2.).timeout
	can_respawn = true
	get_node("Control/Respawn").disabled = false
	if get_node("Control/Auto Respawn").button_pressed:
		_on_respawn_button_down()

func _process(_delta):
	var time_remaining = max(death_time + 2 - Game.time, 0)
	if time_remaining:
		get_node("Control/Respawn").text = "Respawn in: " + str(float(int(time_remaining*10))/10)
	else:
		get_node("Control/Respawn").text = "Click to respawn"

func _on_respawn_button_down():
	Game.local_player.spawn()
	Game.local_player.process_mode = Node.PROCESS_MODE_INHERIT
	get_node("Control/Respawn").disabled = true
	get_parent().remove_child(self)
