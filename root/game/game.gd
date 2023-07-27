extends Node3D

@onready var Target: Object = preload("res://root/game/entities/target/target.tscn")
@onready var Death_Ui: Node = preload("res://root/game/entities/player/death_ui/death_ui.tscn").instantiate()

var spawnpoints = []
var time = 0

var local_player: Player

var memo = ["dmg","msp","rpm","acc","rcl","amm","rld","bsp"] #[[flat],[%]]
var conversion = ["damages","speed","fire_rate","accuracy","recoil","max_ammo","reload_speed","bullet_speed"] #[[flat],[%]]
var stats_items = {
	"base":[[200, 150, 300, 250, 200, 25, 100, 100], [0, 0, 0, 0, 0, 0, 0, 0], 0],
	"smg kit":[[-40, 50, 200, -50, 0, 10, 30, -20], [0, 0, 0, 0, 0, 0, 0, 0], 5],
	"AR kit":[[60, -10, 30, 0, 10, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], 5],
	"sniper kit":[[200, -40, -100, 100, -100, -15, 0, 60], [0, 0, 0, 0, 0, 0, 0, 0], 5],
	"runNgun":[[0, 50, 0, -100, 0, 0, 25, -20], [0, 10, 0, 0, 0, 0, 0, 0], 15],
	"sprayNpray":[[-40, 0, 300, -75, 25, 0, 25, 0], [-2, 0, 20, 0, 0, 0, 5, 0], 15],
	"destruction":[[40, 0, 0, 0, 0, 0, 0, 0], [30, -10, -20, 0, -10, 0, 0, 0], 18],
	"farmin'":[[0, 20, 0, 20, -30, -4, 0, 30], [0, 0, 0, 0, 0, 0, 0, 0], 12],
	"spammin'":[[0, 0, 0, -10, 0, 30, 0, 0], [0, 0, 0, -5, 0, 20, 0, 0], 12],
	"no jhons":[[0, -5, 0, 120, 0, -8, 0, 0], [0, 0, 0, 40, 0, -10, 0, 0], 18],
	"ranger":[[0, 5, 100, 10, 10, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], 22],
	"la bagarre":[[150, 0, 10, -10, -10, -10, 10, -10], [0, 0, 0, 0, 0, 0, 0, 0], 10],
	"habile":[[0, 0, 0, 0, 0, 0, 400, 0], [0, 0, 0, 0, 0, 0, 0, 0], 15],
	"vietnam":[[-200, 0, 1000, -50, 0, 50, -20, 0], [0, 0, 0, 0, 0, 0, 0, 0], 10],
	"cut player":[[0, 0, 0, 0, 0, 0, 0, 0], [-50, 150, -50, -50, -50, -50, -50, -50], -10],
	"belle poignée":[[0, 0, 0, 0, 50, 0, 0, 0], [0, 0, 0, 0, 50, 0, 0, 0], 15],
	"balles légères":[[-100, 5, 100, -10, -10, 10, 100, 100], [0, 0, 0, 0, 0, 0, 0, 0], 15],
	"prayge":[[50, 0, 0, -50, 0, 0, 0, 0], [0, 0, 0, -5, 0, 0, 0, 0], 10],
	"slighlty faster":[[0, 10, 10, 0, 0, 0, 10, 10], [0, 2, 2, 0, 0, 0, 2, 2], 12],
	"hitscan":[[0, -20, -20, 0, -30, -5, 0, 300], [0, 0, 0, 0, -10, -15, 0, 50], 15],
	"shakin'":[[20, 0, 40, 40, -120, 0, 0, 20], [0, 0, 5, 10, -30, 0, 0, 10], 10],
	"chevrex":[[-6, -6, -6, -6, -6, -6, -6, -6], [3, 3, 3, 3, 3, 3, 3, 3], 6],
	"easy mode":[[-20, -10, 0, 30, -40, 5, 20, 30], [-5, 0, 0, 0, 10, 2, 2, 2], 12],
	"sample":[[0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], 0]
}
#25 recoil

func _ready():
	spawn_map(0)
	calibrate_ui()
	get_viewport().size_changed.connect(calibrate_ui)
	get_node("Pause/VolumeSlider").connect("value_changed", update_volume)
	get_node("Pause/SensiSlider").connect("value_changed", update_sensi)
	get_node("Pause/Resume").connect("pressed", resume)
	get_node("Pause/Quit").connect("pressed", quit)


func _exit_tree():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func spawn_map(_id):
	var map = load("res://root/game/maps/map.tscn").instantiate()
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
	if Input.is_action_just_pressed("escape"):
		get_node("Pause").visible = !get_node("Pause").visible
		Input.mouse_mode = (int(!get_node("Pause").visible) * 2) as Input.MouseMode
	if Input.is_action_just_pressed("lock_mouse"):
		Input.mouse_mode = (int(!Input.mouse_mode) * 2) as Input.MouseMode
	if Input.is_action_just_pressed("fullscreen"):
		get_viewport().get_window().mode = int(!get_viewport().get_window().mode)*3 as Window.Mode


func update_sensi(sensi):
	get_node("Pause/SensiSlider/Title").text = "Sensitivity : " + str(float(int(sensi*10000))/100)
	local_player.sensi = Vector2(1,1)*-sensi/100


func update_volume(volume):
	get_node("Pause/VolumeSlider/Title").text = "Volume : " + str(volume)
	AudioServer.set_bus_volume_db(0, volume-64)
	if volume < 11:
		get_node("Pause/VolumeSlider/Title").text = "Volume : " + str(0)
		AudioServer.set_bus_volume_db(0, -INF)


func quit():
	get_node("/root/Main Menu/Lobby")._on_quit_pressed()
	get_node("/root/Main Menu").visible = true
	get_node("/root/Main Menu").process_mode = Node.PROCESS_MODE_INHERIT
	get_node("/root/Main Menu/Lobby/Ready").button_pressed = false
	queue_free()


func resume():
	get_node("Pause").visible = 0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func calibrate_ui():
	var window_size = get_viewport().size
	get_node("Pause").scale.x = float(window_size.x) / 1152
	get_node("Pause").scale.y = float(window_size.y) / 648
	get_node("Pause").position = Vector2()
