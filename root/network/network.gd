extends Node

# multiplayer.get_remote_sender_id() in an RPC give the ID of the client who called the function

# ENet.get_connection_status() will give the current connection status

# The server ID is always 1

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# ---  1) Global Network script   --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #

var TARGET_IP: String = "127.0.0.1" # Server IP adress used to connect client to the sever
var PORT: int = 21212 # Connection port used for the network connection

var ENet: ENetMultiplayerPeer = ENetMultiplayerPeer.new() # Multiplayer tool
var players = [] # Contain all connected players

func create_room(): # Server Function // Create an server and initialize it
	print("Server creation started")

	players_ready = []

	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()

	ENet.create_server(PORT) # Create an server
	multiplayer.multiplayer_peer = ENet # Set multiplayer instance for godot networking processes

	##  The client isn't a player so this line is not used
	##      connect_peer(1) # Add the server to the list of players

	multiplayer.peer_connected.connect(self.connect_peer) # When an peer connect to this server it 
	# will execute the connect_peer function
	multiplayer.peer_disconnected.connect(self.disconnect_peer) # Same !

	var upnp = UPNP.new()
	upnp.discover(2000, 2, "InternetGatewayDevice")
	get_node("Net Status/Server help").text = "Server help
1) Do a port-forward on your firewall using the UDP protocol. (Needed: Port)
2) Do the same on your router with the UDP protocol. (Needed: Local IPv4, Port)
3) Give your IP to the players. (Needed: Public IPv4)

Just please... The Public IP and the Local one aren't the same !

Port: " + str(PORT) + "
Local IPv4 adress: " + IP.get_local_addresses()[-1] + "
Public IPv4 adress: " + upnp.query_external_address() + "

Don't forget to close the port that you opened on your router when you will close the server !"
	get_node("Net Status/Server help").visible = true

	start_lobby()


func join_room(): # Client Function // Create an client and connect him to the server
	print("Starting the server connection")

	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()

	ENet.create_client(TARGET_IP, PORT) # Create an client by connecting him to the server
	multiplayer.multiplayer_peer = ENet # Set multiplayer instance for godot networking processes

	start_lobby()


# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# ---  2) Random functions for 1) --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #

@onready var Player: Object = preload("res://root/game/entities/player/player.tscn")

var players_ready = []

@rpc("authority", "call_remote", "reliable", 1)
func synchronise_peers(_players: Array): # Server Function // Clean up each client on his disconnect
	players = _players


@rpc("authority", "call_local", "reliable", 0)
func start_game(map_id: int):
	ENet.refuse_new_connections = true
	state = States.GAME
	var Game: Node3D = load("res://root/game/game.tscn").instantiate()
	get_node("/root/").add_child(Game)
	Game.init(map_id)
	if is_server:
		while len(players_ready) != len(players):
			await get_tree().create_timer(.5).timeout
			print("Waiting for players to load the game")
		for id in players:
			rpc("instanciate_player", id)
		get_node("/root/Game").visible = false
	else:
		rpc_id(1, "client_ready")


@rpc("any_peer", "call_remote", "reliable", 1)
func client_ready():
	var sender = multiplayer.get_remote_sender_id()
	if !players_ready.has(sender):
		players_ready.append(sender)

@rpc("authority", "call_remote", "reliable", 1)
func connect_peer(id: int): # Server Function // Initialize each client on his connection
	print("Client connection:\t", id)
	if is_server:
		rpc_id(id, "synchronise_peers", players)
		rpc("connect_peer", id)
	players.append(id)
	#instanciate_player(id)
	get_node("Net Status").text = \
	CONNECTION_STATUS_MESSAGES[current_connection_status] + \
	"is server: " + str(is_server) + \
	", players: " + str(players)


@rpc("authority", "call_remote", "reliable", 1)
func disconnect_peer(id: int): # Server Function // Clean up each client on his disconnect
	print("Client disconnection:\t", id)
	if is_server:
		rpc("disconnect_peer", id)
	players.erase(id)
	if state == States.GAME:
		uninstanciate_player(id)
	get_node("Net Status").text = \
	CONNECTION_STATUS_MESSAGES[current_connection_status] + \
	"is server: " + str(is_server) + \
	", players: " + str(players)

	if players_ready.has(id):
		players_ready.erase(id)


@rpc("authority", "call_local", "reliable", 1)
func instanciate_player(id: int): # Server Function // Instanciate an Player node for his client
	print("Client ", id, "'s Player scene spawned")
	var player = Player.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	# The spawn on the other clients will be managed by the Player Spawner's node
	if id == multiplayer.get_unique_id():
		get_node("/root/Game").local_player = player
		get_node("/root/Main Menu").visible = false
		get_node("/root/Main Menu").process_mode = Node.PROCESS_MODE_DISABLED
		player.process_mode = Node.PROCESS_MODE_DISABLED
	get_node("/root/Game/Entities/Players").add_child(player) # Will instanciate a Player instance


@rpc("authority", "call_local", "reliable", 1)
func uninstanciate_player(id: int): # Server Function // Uninstanciate a Player node
	print("Client ", id, "'s Player scene unspawned")
	if get_node("/root/").has_node("/Game/Entities/Players/" + str(id)):
		get_node("/root/Game/Entities/Players/" + str(id)).queue_free() # Refair to instanciate_player()


# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #

"""

var rpc_return_functions: Dictionary = {}


func send_rpc_call_with_return(
		peer_id: int = 0, # 0 = all
		path: String = ".", # "." = /root/Network
		function: String = "print", # "print" = print(argv)
		argv: Array = [], # [] = 0 arguments
		return_function: Callable = func x(): return # func x(): return = Do nothing
		):
	var rpc_id = 0
	var assigned_rpc_ides = rpc_return_functions.keys()
	while rpc_id in assigned_rpc_ides:
		rpc_id += 1
	if peer_id == 0:
		rpc("rpc_call_with_return", function, path, argv)
	else:
		rpc_id(peer_id, "rpc_call_with_return", function, path, argv)


@rpc("any_peer", "call_remote", "reliable")
func rpc_call_reliable(path: String, function: String, argv: Array = []):
	var node = get_node(path)
	if node != null:
		if node.has_method(function):
			callv(function, argv)
		else:
			push_warning("Function " + function + "() not found on " + path + " (" + node + ")")
	else:
		push_warning("Node " + path + " not found (Relative to " + str(get_path()) + ")")


@rpc("any_peer", "call_remote", "unreliable")
func rpc_call_unreliable(path: String, function: String, argv: Array = []):
	var node = get_node(path)
	if node != null:
		if node.has_method(function):
			callv(function, argv)
		else:
			push_warning("Function " + function + "() not found on " + path + " (" + node + ")")
	else:
		push_warning("Node " + path + " not found (Relative to " + str(get_path()) + ")")


@rpc("any_peer", "call_remote", "reliable")
func rpc_call_with_return(rpc_id: int, path: String, function: String, argv: Array = []):
	var node = get_node(path)
	if node != null:
		if node.has_method(function):
			rpc_id(multiplayer.get_remote_sender_id(), "rpc_return", rpc_id, Array(callv(function, argv)))
		else:
			push_warning("Function " + function + "() not found on " + path + " (" + node + ")")
	else:
		push_warning("Node " + path + " not found (Relative to " + str(get_path()) + ")")


@rpc("any_peer", "call_remote", "reliable", 0)
func rpc_return(rpc_id: int, argv: Array):
	rpc_return_functions[rpc_id].callv(argv)


"""

enum States {
	STOPPED = 0, 
	LOBBY = 1, 
	GAME = 2
}

var CONNECTION_STATUS_MESSAGES = [
	"net status: [color=#FF1500]disconnected[/color],", 
	"net status: [color=#ADC090]connecting[/color], ",
	"net status: [color=#00FF00]connected[/color], "
]

var IP_ADRESS: String = IP.get_local_addresses()[1]

var state: States = States.LOBBY

var current_connection_status: int = 3

var is_server: bool = false

func init(_TARGET_IP: String, _PORT: int, _is_server: bool):
	is_server = _is_server
	if _TARGET_IP:
		TARGET_IP = _TARGET_IP
	if _PORT:
		PORT = _PORT

func _ready():
	calibrate_ui()
	get_viewport().size_changed.connect(calibrate_ui)
	if is_server:
		get_node("Net Status/Server help").visible = true
		create_room()
	else:
		join_room()
	set_multiplayer_authority(1)


func calibrate_ui():
	var window_size = get_viewport().size
	get_node("Net Status").scale.x = float(window_size.x) / 1152
	get_node("Net Status").scale.y = float(window_size.y) / 648


func _process(_delta):
	if ENet.get_connection_status() != current_connection_status:
		current_connection_status = ENet.get_connection_status()
		get_node("Net Status").text = \
		CONNECTION_STATUS_MESSAGES[current_connection_status] + \
		"is server: " + str(is_server) + \
		", players: " + str(players)

	if Input.is_action_just_pressed("switch_network_status_visibility"):
		get_node("Net Status").visible = !get_node("Net Status").visible

	if is_server:
		server_process()
	else:
		client_process()


func server_process():
	if 1:
		pass
	elif state == States.LOBBY:
		print("Waiting players to be ready")
		print(players)
	elif state == States.GAME:
		print("Managing the game")
		print(players)
	else:
		print("Mhm")


func client_process():
	if 1:
		pass
	elif state == States.LOBBY:
		print("Waiting server to start the game")
		print(players)
	elif state == States.GAME:
		print("Playing")
		print(players)
	else:
		print("Mhm")


func start_lobby():
	ENet.refuse_new_connections = false
	state = States.LOBBY

func _exit_tree():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
