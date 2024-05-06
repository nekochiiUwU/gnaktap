extends Control

@onready var Players_List: ItemList = get_node("Players List")

var texture_ready = {
	true: load("res://assets/textures/check.png"), 
	false: load("res://assets/textures/waiting.png")
}

var players_ready = []

func init():
	print("init")
	visible = true
	get_node("Ready").disabled = true
	get_parent().visible = true
	get_parent().process_mode = Node.PROCESS_MODE_INHERIT
	players_ready = []


func set_last_round_leaderboard(data: Dictionary):
	if has_node("Scores"):
		remove_child(get_node("Scores"))
	var Leaderboard_UI = load("res://root/game/entities/player/leaderboard_ui/leaderboard_ui.tscn").instantiate()
	Leaderboard_UI.disabled = true
	add_child(Leaderboard_UI)
	Leaderboard_UI.name = "Scores"
	Leaderboard_UI.position.y = 80
	Leaderboard_UI.position.x = 0
	var _Score = load("res://root/game/entities/player/leaderboard_ui/score.tscn")
	for player_name in data.keys():
		var Score: Control = _Score.instantiate()
		Score.position.y = (get_node("Scores").get_child_count() - 1) * 40
		Score.name = player_name
		get_node("Scores").add_child(Score)
		Score.lobby_update(data[player_name])


func _process(_delta):
	if multiplayer.has_multiplayer_peer() and get_node("/root/").has_node("Network"):
		while len(get_node("/root/Network").players) > Players_List.item_count:
			Players_List.add_item("")
		while len(get_node("/root/Network").players) < Players_List.item_count:
			Players_List.remove_item(Players_List.item_count-1)
		
		for i in range(len(get_node("/root/Network").players)):
			Players_List.set_item_icon(i, 
				texture_ready[get_node("/root/Network").players[i] in players_ready]
			)
			Players_List.set_item_text(i, str(get_node("/root/Network").players[i]))
		
		if is_multiplayer_authority():
			$Ready.disabled = len(get_node("/root/Network").players) != len(players_ready)
			rpc("syncronise_ready", players_ready)
		else:
			$Ready.disabled = false


func _on_ready_pressed():
	if get_node("/root/").has_node("Game"):
		get_node("/root/Game").queue_free()

	if multiplayer.has_multiplayer_peer():
		if !multiplayer.is_server():
			if multiplayer.multiplayer_peer.get_connection_status() == 2:
				rpc_id(1, "set_ready", get_node("Ready").button_pressed)
		else:
			get_node("/root/Network").rpc("start_game", 2)

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
