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
	get_node("Connect").visible = false
	var network = load("res://root/network/network.tscn").instantiate()
	network.init(get_node("Connect/IP").text, get_node("Connect/Port").value, false)
	get_node("/root/").add_child(network)
	get_node("Lobby").visible = true


func _on_start_server_pressed():
	get_node("Connect").visible = false
	var network = load("res://root/network/network.tscn").instantiate()
	network.init(get_node("Connect/IP").text, get_node("Connect/Port").value, true)
	get_node("/root/").add_child(network)
	get_node("Lobby").visible = true
	get_node("Lobby/Ready").disabled = true
	get_node("Lobby").players_ready = []
