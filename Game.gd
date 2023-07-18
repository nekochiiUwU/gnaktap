extends Node3D

@onready var Target: Object = preload("res://target.tscn")
@onready var Death_Ui: Node = preload("res://death_ui.tscn").instantiate()

var spawnpoints = []
var time = 0

var local_player: Player

var memo = ["dmg","msp","rpm","acc","rcl","amm","rld","bsp"] #[[flat],[%]]
var conversion = ["damages","speed","fire_rate","accuracy","recoil","max_ammo","reload_speed","bullet_speed"] #[[flat],[%]]
var stats_items = {
	"base":[[20, 100, 300, 250, 200, 25, 100, 100], [0, 0, 0, 0, 0, 0, 0, 0], 0],
	"smg kit":[[-4, 50, 200, -50, 0, 10, 30, -20], [0, 0, 0, 0, 0, 0, 0, 0], 5],
	"AR kit":[[6, -10, 30, 0, 10, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], 5],
	"sniper kit":[[20, -40, -100, 100, -100, -15, 0, 60], [0, 0, 0, 0, 0, 0, 0, 0], 5],
	"runNgun":[[0, 100, 0, -100, 0, 0, 25, -20], [0, 20, 0, 0, 0, 0, 0, 0], 15],
	"sprayNpray":[[-4, 0, 300, -75, 25, 0, 25, 0], [-2, 20, 0, 0, 0, 0, 5, 0], 15],
	"destruction":[[4, 0, 0, 0, 0, 0, 0, 0], [30, -10, -20, 0, -10, 0, 0, 0], 18],
	"farmin":[[0, 20, 0, 20, -30, -4, 0, 30], [0, 0, 0, 0, 0, 0, 0, 0], 12],
	"spammin":[[0, 0, 0, -10, 0, 30, 0, 0], [0, 0, 0, -5, 0, 20, 0, 0], 12],
	"nojhons":[[0, -5, 0, 120, 0, -8, 0, 0], [0, 0, 0, 40, 0, -10, 0, 0], 18],
	"sample":[[0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], 0],
}
#25 recoil

func _ready():
	spawn_map(0)


func _exit_tree():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func spawn_map(_id):
	var map = load("res://map.tscn").instantiate()
	add_child(map)
	spawnpoints = map.get_node("Spawnpoints").get_children()
	for i in range(2):
		instanciate_target(str(i))


func instanciate_target(id: String): # Server Function // Instanciate a Target node for his client
	var target = Target.instantiate()
	target.name = "Target" + id
	target.set_multiplayer_authority(1)
	get_node("/root/Game/Entities").add_child(target) # Will instanciate a Target instance
	# The spawn on the other clients will be managed by the Target Spawner's node


func _process(delta):
	"""
	stats_items = {
	"base":[[20, 5, 300, 20, 20, 25, 20, 25], [0, 0, 0, 0, 0, 0, 0, 0], 5],
	"test":[[0,0,1000,0,20,0,0,0], [0,0,3,0,0,0,-61,0], 5],
	"test2":[[0,0,0,0,0,0,0,0], [0,0,0,0,0,0,0,0], 5]
}"""
	time += delta
	if Input.is_action_just_pressed("quit"):
		get_node("/root/Main Menu").visible = true
		get_node("/root/Main Menu").process_mode = Node.PROCESS_MODE_INHERIT
		if get_node("/root/").has_node("Network"):
			get_node("/root/Network").start_lobby()
		queue_free()
	if Input.is_action_just_pressed("lock_mouse"):
		Input.mouse_mode = (int(!Input.mouse_mode) * 2) as Input.MouseMode
