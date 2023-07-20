extends Control

@onready var Players_List: ItemList = get_node("Players List")

var texture_ready = {
	true: load("res://assets/textures/check.png"), 
	false: load("res://assets/textures/waiting.png")
}

var players_ready = []


func _process(_delta):
	if get_node("/root/").has_node("Network") and multiplayer.has_multiplayer_peer():
		while len(get_node("/root/Network").players) > Players_List.item_count:
			Players_List.add_item("")
		if is_multiplayer_authority():
			rpc("syncronise_ready", players_ready)
		for i in range(len(get_node("/root/Network").players)):
			Players_List.set_item_icon(i, 
				texture_ready[get_node("/root/Network").players[i] in players_ready]
			)
			Players_List.set_item_text(i, str(get_node("/root/Network").players[i]))
		while len(get_node("/root/Network").players) < Players_List.item_count:
			Players_List.remove_item(Players_List.item_count-1)
		if multiplayer.get_unique_id() == 1:
			$Ready.disabled = len(get_node("/root/Network").players) != len(players_ready)
			rpc("syncronise_ready", players_ready)
		else:
			$Ready.disabled = false


func _on_ready_pressed():
	if !get_node("Ready").button_pressed:
		get_node("/root/Game").queue_free()
	else:
		get_node("/root/").add_child(load("res://root/game/game.tscn").instantiate())
	if get_node("/root/").has_node("Network"):
		get_node("/root/Network").start_game()
	if !multiplayer.is_server():
		rpc_id(1, "set_ready", get_node("Ready").button_pressed)


func _on_quit_pressed():
	visible = false
	if get_node("/root/").has_node("Network"):
		get_node("/root/Network").queue_free()
	get_node("../Connect").visible = true


@rpc("any_peer", "call_remote", "reliable", 1)
func set_ready(is_ready: bool):
	var sender = multiplayer.get_remote_sender_id()
	if !(sender in players_ready) and is_ready:
		players_ready.append(sender)
	elif sender in players_ready and !is_ready:
		players_ready.erase(sender)


@rpc("authority", "call_remote", "unreliable", 2)
func syncronise_ready(_players_ready: Array):
	players_ready = _players_ready
