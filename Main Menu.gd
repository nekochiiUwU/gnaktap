extends Node2D


func _ready():
	calibrate_ui()
	get_viewport().size_changed.connect(calibrate_ui)


func _process(_delta):
	pass


func calibrate_ui():
	var window_size = get_viewport().size
	scale.x = float(window_size.x) / 1152
	scale.y = float(window_size.y) / 648


func _on_start_client_pressed():
	get_node("Network/Start").visible = false
	var network = load("res://network.tscn").instantiate()
	network.init(get_node("Network/Start/IP").text, get_node("Network/Start/Port").value, false)
	get_node("/root/").add_child(network)
	get_node("Network/Stop").visible = true


func _on_start_server_pressed():
	get_node("Network/Start").visible = false
	var network = load("res://network.tscn").instantiate()
	network.init(get_node("Network/Start/IP").text, get_node("Network/Start/Port").value, true)
	get_node("/root/").add_child(network)
	get_node("Network/Stop").visible = true


func _on_stop_network_pressed():
	get_node("Network/Stop").visible = false
	if get_node("/root/").has_node("Network"):
		get_node("/root/Network").queue_free()
	get_node("Network/Start").visible = true


func _on_start_game_pressed():
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	get_node("/root/").add_child(load("res://game.tscn").instantiate())
	if get_node("/root/").has_node("Network"):
		get_node("/root/Network").start_game()
