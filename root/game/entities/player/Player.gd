class_name Player
extends CharacterBody3D

@onready var bullet = preload("res://root/game/entities/bullet/bullet.tscn")
var leaderboard

var Game

var health:      float =  100.
var gravity:     float = -ProjectSettings.get_setting("physics/3d/default_gravity")
var jump:        float =  7.
var sensi:     Vector2 = -Vector2(.001, .001)
var joy_sensi: Vector2 = -Vector2(.1, .1)
var hitmarker_time: float = 0
var shot_time:      float = 0
var reloading:      bool = false
var target_score:   int = 5
var kills:          int = 0
var deaths:         int = -1
var incoming_recoil: Vector2 = Vector2()
var active_weapon: int = 0 #emplacement dans l'equipement
var equipement = ["rifle","cut"] #[primary,secondary]
var crouch_height = 1.5
var normal_height = 1.8
var crouch_value = 0

var interact_objects: Array = []
var current_interact = null


var inventory = {
	"items":["base"],
	"points": {
		"damages": 30,
		"speed": 30,
		"fire_rate": 30,
		"accuracy": 30,
		"recoil": 30,
		"max_ammo": 30,
		"reload_speed": 30,
		"bullet_speed": 30
	}
}

#weapon stats
var weapon_type:  String = "semi auto"
var scope:        String = "none" #pour plus tard
var accessory:    String = "none" #pour plus tard
var speed:        float  =  5.
var damages:      float  = 34.
var fire_rate:    float  = 600 #en RPM -> tir tous les 60/fire_rate
var accuracy:     float  = 5 #en degres
var recoil:       float  = 5 #en degres, a voir
var max_ammo:     int    = 30
var ammo:         int    = max_ammo
var reload_speed:  float = 1.2
var bullet_speed: float  = 50. 
var nb_shot:       int = 2



func _ready():
	Game = get_node("../../..")
	visible = false
	get_node("Arm/Hand/Cut").visible = false
	if is_multiplayer_authority():
		leaderboard = load("res://root/game/entities/player/leaderboard_ui/leaderboard_ui.tscn").instantiate()
		get_node("Arm/Hand/Shoot Node/Weapon/Canon/AudioStreamPlayer3D").volume_db = -32
		get_node("Arm/Hand/Shoot Node/Weapon/Canon/AudioStreamPlayer3D").unit_size= 15
		calibrate_ui()
		get_viewport().size_changed.connect(calibrate_ui)
		spawn()
		update_stats()
		die()
	else:
		get_node("HeadCollision").queue_free()
		get_node("Collision").queue_free()
		get_node("Head/Light").queue_free()
		get_node("Head/UI").queue_free()
		get_node("%Camera").queue_free()



func calibrate_ui():
	var window_size = get_viewport().size
	get_node("Head/UI").scale.x = float(window_size.x) / 1152
	get_node("Head/UI").scale.y = float(window_size.y) / 648
	print(get_node("Head/UI").scale)
	get_node("Head/UI").position = window_size / 2


func _input(event):
	if is_multiplayer_authority():
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if event is InputEventMouseMotion:
				rotation.y += event.relative.x * sensi.x
				$Head.rotation.x = clamp(-PI/2, $Head.rotation.x + event.relative.y * sensi.y, PI/2)
				$Head.rotation.z += event.relative.x * sensi.x / 10
				get_node("%Camera").fov = min(get_node("%Camera").fov + abs(event.relative.x * sensi.x * 5), 160)


func _physics_process(delta):
	if is_multiplayer_authority():
		if Input.is_action_just_pressed("interact"):
			interact()

		if Input.is_action_just_pressed("reload") and ammo != max_ammo and !reloading:
			reload()

		var current_crouch_modifier
		if Input.is_action_pressed("crouch"):
			current_crouch_modifier = (crouch_height - get_node("Mesh").mesh.height) / 5
		else:
			current_crouch_modifier = (normal_height - get_node("Mesh").mesh.height) / 5
		get_node("Mesh").mesh.height += current_crouch_modifier
		get_node("Mesh").position.y -= current_crouch_modifier/2
		get_node("Collision").shape.height += current_crouch_modifier
		get_node("Collision").position.y -= current_crouch_modifier/2
		position.y += current_crouch_modifier
		crouch_value = float(get_node("Mesh").mesh.height-normal_height)/(crouch_height-normal_height)
		
		if hitmarker_time:
			var x = 1 - ((Game.time - hitmarker_time) / .3)
			# 1 > 0 // 0.3s
			if x <= 0 or hitmarker_time > Game.time:
				get_node("Head/UI/Hitmarker").visible = false
				hitmarker_time = 0
			get_node("Head/UI/Hitmarker").modulate = (get_node("Head/UI/Hitmarker").modulate/get_node("Head/UI/Hitmarker").modulate)*x
			get_node("Head/UI/Hitmarker").scale = (get_node("Head/UI/Hitmarker").scale)*x

		if incoming_recoil:
			#get_node("Head").rotation_degrees.x += incoming_recoil.y / 2
			get_node("Head").rotation_degrees.x = clamp(-90, get_node("Head").rotation_degrees.x + incoming_recoil.y / 2, 90)
			rotation_degrees.y += incoming_recoil.x / 2
			incoming_recoil /= 2

		if get_node("Arm/Hand/Shoot Node").position:
			get_node("Arm/Hand/Shoot Node").position /= 1.05
		if get_node("Arm/Hand/Shoot Node").rotation:
			get_node("Arm/Hand/Shoot Node").rotation /= 1.05

		get_node("Head/UI/HealthBar").value = health

		var input_rotation = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
		if input_rotation:
			rotation.y += input_rotation.x * joy_sensi.x
			$Head.rotation.x = clamp(-1.57, $Head.rotation.x + input_rotation.y * joy_sensi.y, 1.57)
			$Head.rotation.z += input_rotation.x * joy_sensi.x / 10
			get_node("%Camera").fov = min(get_node("%Camera").fov + abs(input_rotation.x * sensi.x * 5), 160)
		#print(velocity.dot(transform.basis.x))
		var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").normalized()
		input = Vector3(input.x, 0, input.y)

		if Input.is_action_pressed("switch weapon"):
			switch_weapon()

		if Input.is_action_pressed("show_leaderboard"):
			if !leaderboard.is_inside_tree():
				get_node("Head/UI").add_child(leaderboard)
		else:
			if leaderboard.is_inside_tree():
				get_node("Head/UI").remove_child(leaderboard)
			

		if Input.is_action_pressed("take cut") and !(active_weapon == 1):
			switch_weapon()
		elif Input.is_action_pressed("take main") and !(active_weapon == 0):
			switch_weapon()

		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if Input.is_action_pressed("shoot"):
				try_shoot()
		
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if Input.is_action_pressed("secondary fire"):
				if equipement[active_weapon] == "rifle" and reloading == false:
					if get_node("%Weapon/Animation").assigned_animation != "scope":
						get_node("%Weapon/Animation").current_animation = "scope"
						get_node("%Weapon/Animation").play()
				elif equipement[active_weapon] == "cut":
					rpc("stab")
				else:
					if get_node("%Weapon/Animation").assigned_animation != "no_scope":
						get_node("%Weapon/Animation").current_animation = "no_scope"
						get_node("%Weapon/Animation").play()
			else:
				if get_node("%Weapon/Animation").assigned_animation != "no_scope":
					get_node("%Weapon/Animation").current_animation = "no_scope"
					get_node("%Weapon/Animation").play()

		if is_on_floor():
			if Input.is_action_pressed("jump"):
				velocity.y = jump
		else:
			velocity.y += gravity * delta
		
		input *= (speed/(crouch_value*1.5+1))*(1+0.2*float(equipement[active_weapon] == "cut"))
		velocity += transform.basis * input

		velocity.x *= .5
		velocity.z *= .5
		#print("Speed: ", float(int(sqrt(pow(velocity.x, 2) + pow(velocity.z, 2)) * 1000)) / 1000)

		move_and_slide()
		$Head.rotation.z -= velocity.dot(transform.basis.x) / 1000
		$Head.rotation.z /= 1.1
		get_node("Arm/Hand").rotation.z = ($Head.rotation.z + get_node("Arm/Hand").rotation.z*1) / 2
		get_node("Arm/Hand").position.x = get_node("Arm/Hand").rotation.z / 4
		get_node("%Camera").fov = (get_node("%Camera").fov - 120) / 1.2 + 120
		
		if position.y < -30:
			die()


func _process(_delta):
	if multiplayer.get_unique_id() == int(str(name)):
		rpc("online_synchronisation", get_online_synchronisation_data())


func update_ammo():
	get_node("Head/UI/Ammo").text = str(ammo)+"/"+str(max_ammo)


func try_shoot():
	if equipement[active_weapon] == "cut":
		rpc("slash")
	elif equipement[active_weapon] == "rifle":
		if shot_time + 60/fire_rate - Game.time > 0:
			return
		if reloading:
			return
		if ammo <= 0:
			if !reloading and Input.is_action_just_pressed("shoot"):
				reload() #ou pas, au choix
			return
		if weapon_type == "full auto": 
			shoot()
			ammo -= 1
			update_ammo()
			shot_time = Game.time
		elif weapon_type == "semi auto" and Input.is_action_just_pressed("shoot"): 
			shoot()
			ammo -= 1
			update_ammo()
			shot_time = Game.time
		elif weapon_type == "burst" and Input.is_action_just_pressed("shoot"):
			shot_time = Game.time + (nb_shot-1)*(60/fire_rate)
			for i in range(nb_shot):
				if ammo > 0:
					shoot()
					ammo -= 1
					update_ammo()
					await get_tree().create_timer((60/fire_rate)/(2*nb_shot)).timeout #ca marche lol
		elif weapon_type == "shotgun" and Input.is_action_just_pressed("shoot"):
			for i in range(nb_shot):
				shoot()
			ammo -= 1
			update_ammo()
			shot_time = Game.time


func shoot():
	var ori = get_node("%Weapon/Canon").global_rotation_degrees
	var actual_acc = accuracy/(crouch_value*0.5+1)
	ori.x += randf_range(-actual_acc/2, actual_acc/2)
	ori.y += randf_range(-actual_acc/2, actual_acc/2)
	incoming_recoil.y += randf_range(0, recoil)
	incoming_recoil.x += randf_range(-recoil/2, recoil/2)
	
	get_node("Arm/Hand/Shoot Node").position.z += -0.02 * (get_node("%Weapon").position.z + 0.45) + abs(incoming_recoil.x) / 50
	get_node("Arm/Hand/Shoot Node").position.z = min(get_node("Arm/Hand/Shoot Node").position.z, 0.1)
	get_node("Arm/Hand/Shoot Node").position.y += 1*(get_node("%Weapon").position.y + 0.09) * -.03 + incoming_recoil.y * 0.0
	#get_node("Arm/Hand/Shoot Node").position.x += sign(get_node("%Weapon").position.x) + .1 * incoming_recoil.y * 0.01
	#get_node("Arm/Hand/Shoot Node").rotation.x += .05
	var bullet_dmg = damages/(1+int(weapon_type == "shotgun")*(nb_shot-1))
	rpc("shoot_bullet", get_node("%Weapon/Canon").global_position, ori, bullet_dmg, bullet_speed)


func reload():
	reloading = true
	get_node("%Weapon/RemoadAnimation").play("anim")
	get_node("%Weapon/RemoadAnimation").speed_scale = 1 / reload_speed
	await get_tree().create_timer(reload_speed).timeout
	ammo = max_ammo
	update_ammo()
	reloading = false


func spawn():
	var a = int(rotation.z) % 360 + abs(rotation.z - int(rotation.z))
	a /= 180
	if a > 1:
		a = 2 - a # (a e [0, 1])

	if Game:
		if Game.spawnpoints:
			transform = Game.spawnpoints[randi() % len(Game.spawnpoints)].transform
	get_node("%Camera").current = true
	get_node("Head/UI").visible = true
	visible = true
	health = 100
	ammo = max_ammo
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func new_interact(object):
	interact_objects.append(object)


func lost_interact(object):
	interact_objects.erase(object)
	if object == current_interact:
		current_interact = null


func interact():
	if current_interact:
		current_interact.stop_interact()
		current_interact = null
	elif interact_objects:
		var closest = interact_objects[0]
		for object in interact_objects:
			if position.distance_to(object.position) < position.distance_to(closest.position):
				closest = object
		closest.interact()
		current_interact = closest


func switch_weapon():
	if active_weapon == 0:
		#range main
		#prend cut
		get_node("Arm/Hand/Shoot Node").visible = false
		get_node("Arm/Hand/Cut").visible = true
		active_weapon = 1
	elif active_weapon == 1:
		#range cut
		#prend main
		get_node("Arm/Hand/Cut").visible = false
		get_node("Arm/Hand/Shoot Node").visible = true
		active_weapon = 0


func get_hit(_owner, _damages, collision):
	if collision == "HeadCollision":
		health -= 2*_damages
	else:
		health -= _damages
	if health <= 0:
		get_node("../" + _owner).rpc_id(int(_owner), "kill")
		die() 


func die():
	rotation.z += 90
	position.y -= 0.8
	deaths += 1
	process_mode = Node.PROCESS_MODE_DISABLED
	if is_multiplayer_authority():
		get_node("%Camera").current = false
		get_node("Head/UI").visible = false
		Game.add_child(Game.Death_Ui)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		rpc("online_synchronisation", get_online_synchronisation_data())


func update_stats():
	var items = inventory["items"]
	for v in Game.conversion:
		set(v, 0)
	for i in items: #flat
		for v in range(len(Game.conversion)):
			set(Game.conversion[v], get(Game.conversion[v]) + Game.stats_items[i][0][v])
	for v in range(len(Game.conversion)):
		var ptage = 0
		for i in items: #%ages
			ptage += float(Game.stats_items[i][1][v])/100
		set(Game.conversion[v], get(Game.conversion[v]) * (1+ptage))
	damages = damages/10
	speed = speed/30
	bullet_speed = bullet_speed/4
	recoil = (250-recoil)/10
	accuracy = (350-accuracy)/10
	reload_speed = 5*(150/(150+reload_speed))
	for v in Game.conversion:
		if !(v == "accuracy" or v == "reload_speed" or v == "recoil") and get(v) < 1:
			set(v, 1)
		elif get(v) < 0:
			set(v, 0)
	ammo = max_ammo
	update_ammo()
	print_stats()

func print_stats():
	for v in Game.conversion:
		print(v + ":" + str(get(v)))

@rpc("authority", "call_local", "unreliable", 2)
func shoot_bullet(pos, rot, dmg, bspeed):
	var shoot_stream_player = get_node("Arm/Hand/Shoot Node/Weapon/Canon/AudioStreamPlayer3D")
	shoot_stream_player.pitch_scale += randf_range(.95, 1.1)
	shoot_stream_player.pitch_scale /= 2
	get_node("Arm/Hand/Shoot Node/Weapon/Canon/AudioStreamPlayer3D").play(randf_range(0, .02))
	var new_bullet = bullet.instantiate()
	new_bullet.position = pos
	new_bullet.rotation_degrees = rot
	new_bullet.set_script(load("res://root/game/entities/bullet/bullet.gd"))
	new_bullet.damages = dmg
	new_bullet.speed = bspeed
	new_bullet._owner = name
	if is_multiplayer_authority():
		new_bullet.collision_mask = 0b110
	Game.get_node("Entities").add_child(new_bullet)


@rpc("any_peer", "call_local", "unreliable", 2)
func slash():
	if !get_node("Arm/Hand/Cut/AnimationPlayer").is_playing():
		get_node("Arm/Hand/Cut/AnimationPlayer").play("slash")

@rpc("any_peer", "call_local", "unreliable", 2)
func stab():
	if !get_node("Arm/Hand/Cut/AnimationPlayer").is_playing():
		get_node("Arm/Hand/Cut/AnimationPlayer").play("stab")


func get_online_synchronisation_data():
	return [position, rotation, get_node("Head").rotation, health, visible, kills, deaths, 
			get_node("%Weapon").position, get_node("Mesh").mesh.height, inventory["items"], target_score]


@rpc("authority", "call_remote", "unreliable", 0)
func online_synchronisation(data: Array = [
		"position", 
		"rotation", 
		"head_rotation", 
		"health", 
		"visible", 
		"kills", 
		"deaths", 
		"weapon_position", 
		"mesh_height", 
		"inventory_items"
		]):
	position = data[0]
	rotation = data[1]
	get_node("Head").rotation = data[2]
	health = data[3]
	visible = data[4]
	kills = data[5]
	deaths = data[6]
	get_node("%Weapon").position = data[7]
	get_node("Mesh").mesh.height = data[8]
	inventory["items"] = data[9]
	target_score = data[10]


@rpc("any_peer", "call_local", "reliable", 5)
func hitmarker(_damages: float, collision):
	get_node("Head/UI/Hitmarker").scale = Vector2(0.5,0.5)+(Vector2(0.8,0.8)*_damages)/20
	if collision == "HeadCollision":
		get_node("hitmarker_sfx").volume_db = 8+(16*_damages)/100
		get_node("hitmarker_sfx").stream = load("res://assets/audios/headshot_hitmarker.mp3")
		get_node("Head/UI/Hitmarker").scale *= 2
		get_node("Head/UI/Hitmarker").modulate = Color(1,0,0)
	else:
		get_node("hitmarker_sfx").volume_db = 8+(16*_damages)/100
		get_node("hitmarker_sfx").stream = load("res://assets/audios/hitmarker.mp3")
		get_node("Head/UI/Hitmarker").modulate = Color(1,1,1)
	get_node("hitmarker_sfx").play()
	get_node("Head/UI/Hitmarker").visible = true
	hitmarker_time = Game.time


@rpc("any_peer", "call_local", "unreliable", 6)
func target(score: int):
	target_score += score
	print("target hit ! score : ",target_score)

@rpc("any_peer", "call_local", "reliable", 6)
func kill():
	kills += 1
	target(5)
	print("kill !")
