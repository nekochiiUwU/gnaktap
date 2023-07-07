extends Node

# multiplayer.get_remote_sender_id() in an RPC give the ID of the client wich call the function
# ENet.get_connection_status() will get the connection status
# The server id is 1

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# ---  Global Network script  --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #

var TARGET_IP: String = "127.0.0.1" # Server IP adress used to connect client to the sever
var PORT: int = 21212 # Connection port used for the network connection

var ENet: ENetMultiplayerPeer # Multiplayer tool
var players = [] # Contain all connected players

func create_room(): # Server Function // Create an server and initialize it
	print("Server creation...")
	ENet = ENetMultiplayerPeer.new() # Create multiplayer instance
	ENet.create_server(PORT) # Create an server
	multiplayer.multiplayer_peer = ENet # Set multiplayer instance for godot networking processes

	##  The client isn't a player so this line is not used
	##      connect_peer(1) # Add the server to the list of players
	
	multiplayer.peer_connected.connect(self.connect_peer) # When an peer connect to this server it 
	# will execute the connect_peer function
	multiplayer.peer_disconnected.connect(self.disconnect_peer) # Same !
	print("Server creation established")

	state = STATE.LOBBY


func join_room(): # Client Function // Create an client and connect him to the server
	print("Connecting to the target server")
	ENet = ENetMultiplayerPeer.new() # Create multiplayer instance
	ENet.create_client(TARGET_IP, PORT) # Create an client by connecting him to the server
	multiplayer.multiplayer_peer = ENet # Set multiplayer instance for godot networking processes
	print("Server connection established")

	state = STATE.LOBBY


# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #

@onready var Player: Object = preload("res://player.tscn")


func connect_peer(id: int): # Server Function // Initialize each client on his connection
	players.append(id)
	instanciate_player(id)
	print("Client connection:\t", id)


func disconnect_peer(id: int): # Server Function // Clean up each client on his disconnect
	players.erase(id)
	uninstanciate_player(id)
	print("Client disconnection:\t", id)


func instanciate_player(id: int): # Server Function // Instanciate an Player node for his client
	print("Client ", id, "'s Player scene spawned")
	var player = Player.instantiate()
	player.name = str(id)
	get_node("/root/Game/Entities/Players").add_child(player) # Will instanciate an Player instance
	# The spawn on the other clients will be managed by the Player Spawner's node


func uninstanciate_player(id: int): # Server Function // Uninstanciate an Player node
	print("Client ", id, "'s Player scene unspawned")
	get_node("/root/Game/Entities/Players" + str(id)).queue_free() # Refair to instanciate_player()


# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #

enum STATE {
	STOPPED = 0, 
	LOBBY = 1, 
	GAME = 2
}

var IP_ADRESS: String = IP.get_local_addresses()[1]

var state: STATE = STATE.LOBBY

func _ready():
	if name == "Server":
		create_room()
	else:
		join_room()

func _process(_delta):
	if name == "Server":
		if state == STATE.LOBBY:
			print("Waiting players to be ready")
			print(players)
		elif state == STATE.GAME:
			print("Managing the game")
			print(players)
		else:
			print("Mhm")
	else:
		if state == STATE.LOBBY:
			print("Waiting server to start the game")
			print(players)
		elif state == STATE.GAME:
			print("Playing")
			print(players)
		else:
			print("Mhm")
