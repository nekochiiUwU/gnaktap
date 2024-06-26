class_name Player
extends CharacterBody3D

var Game

var health:            float =  100.
var mana:              float =  100.
var regen:             float =  1.
var gravity:           float = -ProjectSettings.get_setting("physics/3d/default_gravity") * 1.5
var jump:              float =  10.
var speed:             float =  8.
var crouch_speed:      float =  4.
var mouse_sensi:     Vector2 = -Vector2(.001, .001)
var joy_sensi:       Vector2 = -Vector2(1, 1)
var hitmarker_time:    float =  0.
var reloading:          bool =  false
var score:               int =  10000
var kills:               int =  0
var deaths:              int = -1
var incoming_recoil: Vector2 =  Vector2()
var active_weapon:       int =  0 #emplacement dans l'equipement
var crouch_height:     float =  1.5
var normal_height:     float =  1.8
var crouch_value:      float =  0.
var user_fov:          float = 90.
var target_fov:        float = 90.
var interact_objects: Array = []
var current_interact = null
var speed_modifyer: float = 1.

var inventory = {
	"weapons": [
		{
			"type": "gun", 
			"base": "AR", 
			"stats": {
				"damages": 25,
				"firerate": 10,
				"magsize": 30,
				"stability": 1,
				"dropoff": 10,
				"scope": 1.5
			},
			"upgrades":[],
			"state": "idle", 
			"weight": 20.
		}, 
		{
			"type": "melee", 
			"base": "cut", 
			"stats": {
				"damages": 40,
				"animspeed": 1,
				"size": 1,
				"movespeed": 1,
			},
			"upgrades":[],
			"state": "idle", 
			"weight": 2.
		},
		{
			"type": "nothing", 
			"base": "nothing", 
			"stats": {},
			"upgrades":[],
			"state": "idle", 
			"weight": 2.
		}
	], #[primary,secondary]
	"items":[]
}

func _ready():
	Game = get_node("../../..")
	visible = false
	get_node("Arm/Hand/1").visible = true
	get_node("Arm/Hand/1").call_deferred("set", "visible", false)
	#get_node("Arm/Hand/1").visible = false
	if is_multiplayer_authority():
		calibrate_ui()
		get_viewport().size_changed.connect(calibrate_ui)
		spawn()
		die()
	else:
		get_node("HeadCollision").queue_free()
		get_node("Collision").queue_free()
		get_node("Head/Light").queue_free()
		get_node("Head/UI").queue_free()
		get_node("%Camera").queue_free()
	update_weapons()


func _enter_tree():
	if is_multiplayer_authority():
		$Head/UI.add_child(load("res://root/game/entities/player/leaderboard_ui/leaderboard_ui.tscn").instantiate())
		$Head/UI.add_child(load("res://root/game/entities/player/weapons_ui/weapons_ui.tscn").instantiate())
		$Head/UI.get_node("Weapons_ui").visible = false


func calibrate_ui():
	var window_size = get_viewport().size
	get_node("Head/UI").scale.x = float(window_size.x) / 1152
	get_node("Head/UI").scale.y = float(window_size.y) / 648
	print(get_node("Head/UI").scale)
	get_node("Head/UI").position = window_size / 2


func _input(event):
	speed = 9.
	if is_multiplayer_authority():
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if event is InputEventMouseMotion:
				rotation_process(event.relative*mouse_sensi)

var friction: float = 100
func _physics_process(delta):
	user_fov = 90.
	#joy_sensi = mouse_sensi * 10000
	if is_multiplayer_authority():
		var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").normalized()
		input *= speed*(1-crouch_value)+crouch_speed*crouch_value
		input *= speed_modifyer
		var x = 50/(inventory.weapons[active_weapon].weight+50)
		input *= x
		gravity = (2-x/2)*-ProjectSettings.get_setting("physics/3d/default_gravity")
		input = Vector3(input.x, 0, input.y)
		if is_on_floor():
			friction += 100*delta
			friction /= 1+delta
			if Input.is_action_pressed("jump"):
				velocity.y = jump
			velocity += (transform.basis * input * delta * (friction/2+50))
			velocity.x /= 1 + delta * friction
			velocity.z /= 1 + delta * friction
		else:
			velocity += (transform.basis * input * delta*.1*(friction/2+50))
			velocity.x /= 1 + delta*.1*friction
			velocity.z /= 1 + delta*.1*friction
			velocity.y += gravity * delta
		#print(friction)
		move_and_slide()
		#print("Speed: ", round((velocity * Vector3(1, 0, 1)).length()*10)/10)
		#print("Gravity: ", round(-gravity*10)/10)
		if Input.is_action_just_pressed("change_weapon"):
			friction = 25
		if is_on_floor():
			dt += (abs(velocity.x) + abs(velocity.z))*.75
			if ProjectSettings.get_setting("custom/game/dynamic_fov"):
				get_node("%Camera").fov += min((abs(get_real_velocity().x) + abs(get_real_velocity().z))*.1, 160)
		else:
			if ProjectSettings.get_setting("custom/game/dynamic_fov"):
				get_node("%Camera").fov += min(abs(get_real_velocity().length())*.05, 160)
		if position.y < -30:
			die()
		get_node("Head/UI/PostProcess").material.set_shader_parameter("velocity", Vector3(
			velocity.length()*velocity.dot($Head/Camera.global_basis.x), 
			velocity.length()*velocity.dot($Head/Camera.global_basis.y), 
			velocity.length()*velocity.dot($Head/Camera.global_basis.z)
		)*delta)
		get_node("Head/UI/PostProcess").material.set_shader_parameter("absolute_y", velocity.y*delta)
		get_node("Head/UI/Speed").text = str(int((get_real_velocity()*Vector3(1, 0, 1)).length()))
		get_node("Head/UI/Speed").text += "."+str(int((get_real_velocity()*Vector3(1, 0, 1)).length()*10)%10)
		get_node("Head/UI/Speed").text += "m/s"


var dt: float = 0.
func _process(delta):
	if is_multiplayer_authority():
		if Input.is_key_pressed(KEY_0):
			velocity.y += 1
		crouch_process()
		hitmarker_process()
		rotation_process(Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")*delta*joy_sensi)
		get_node("Head/UI/HealthBar").value = health
		get_node("Head/UI/ManaBar").value = mana
		health += regen*delta
		mana += regen*delta
		if Input.is_action_pressed("change_weapon"):
			switch_weapon((active_weapon+1)%len(inventory.weapons))
		$Head/UI.get_node("leaderboard_ui").visible = Input.is_action_pressed("show_leaderboard")
		if Input.is_action_just_pressed("debug"):
			$Head/UI.get_node("Weapons_ui").visible = !$Head/UI.get_node("Weapons_ui").visible
		if Input.is_action_pressed("change_to_primary_weapon"):
			switch_weapon(0)
		elif Input.is_action_pressed("change_to_secondary_weapon"):
			switch_weapon(1)
		elif Input.is_action_pressed("change_to_third_weapon"):
			switch_weapon(2)
		rpc("online_synchronisation", get_online_synchronisation_data())
		if ProjectSettings.get_setting("custom/game/camera_rotation"):
			$Head.rotation.z -= velocity.dot(transform.basis.x) * delta*.04
		$Head.rotation.z /= 1 + delta*10
		get_node("Arm/Hand").rotation.y += -$Head.rotation.z*delta*10*2
		get_node("%Camera").fov = (get_node("%Camera").fov - target_fov+crouch_value*20) / 1.2 + target_fov - crouch_value*20
		$Arm/Hand.rotation.z = crouch_value/10
		get_node("Arm/Hand").rotation.z += $Head.rotation.z*2
		if ProjectSettings.get_setting("custom/game/camera_bounce"):
			var x = float(is_on_floor()) * min(abs(velocity.x)+abs(velocity.z), 1)*min(speed_modifyer, 1)*(1-crouch_value*.8)
			get_node("%Camera").position.x += (pow(sin(dt*.01 ), 2) *.4-.2      ) * delta * 10 * x
			get_node("%Camera").position.y -= (pow(cos(dt*.02 ), 2) *.4-.2      )    * delta * 10 * x
			get_node("%Camera").position.z += (pow(sin(dt*.02 ), 2) *.2-.1  -.3 ) * delta * 10 * x 
			get_node("%Camera").position   += Vector3(0, 0, -.3) * delta * 10 * (1-x)
			get_node("%Camera").position   /= 1+delta*10
			$Head.rotation.z               -= (pow(cos(dt*.01 ), 2) *.01-.005   ) * delta * 10 * x
			$Head.rotation.z               += (pow(cos(dt*.005), 2) *.01-.005   ) * delta * 10 * x
			$Head.rotation.x               += (pow(cos(dt*.02 ), 2) *.02-.01    ) * delta * 10 * x
			$Arm/Hand.position.x           += (pow(sin(dt*.01 ), 2) *.35-.175   ) * delta * 10 * x
			$Arm/Hand.position.y           -= (pow(cos(dt*.02 ), 2) *.35-.175   ) * delta * 10 * x
			$Arm/Hand.position.z           += (pow(sin(dt*.02 ), 2) *.2 -.1  -.1) * delta * 10 * x 
			$Arm/Hand.rotation.x           += (pow(sin(dt*.02 ), 2) *.04-.02   ) * delta * 10 * x
			$Arm/Hand.rotation.y           -= (pow(sin(dt*.01 ), 2) *.05-.025   ) * delta * 10 * x
			$Arm/Hand.rotation.z           += (pow(sin(dt*.01 ), 2) *.35-.175   ) * delta * 10 * x
			$Arm/Hand.position.x           += -velocity.dot($Head/Camera.global_basis.x)*.001 * delta * 10
			$Arm/Hand.position.z           += -velocity.dot($Head/Camera.global_basis.z)*.002 * delta * 10
			$Arm/Hand.position             += Vector3(0, -log(abs(velocity.y+1))*sign(velocity.y)*.02, -.1) * delta * 10 * (1-x)
		else:
			get_node("%Camera").position = get_node("%Camera").position + Vector3(0, .45, -.3)*delta*10
			get_node("%Camera").position /= 1+delta*10
			$Arm/Hand.position += $Arm/Hand.position + Vector3(0, 0, -5)*delta*10
		get_node("Head/UI/PostProcess").material.set_shader_parameter("rotation", 
			get_node("Head/UI/PostProcess").material.get_shader_parameter("rotation") / (1+delta*60)
		)
		var breath = Vector3(
			sin(float(Time.get_ticks_msec())/600)/1000, 
			sin(float(Time.get_ticks_msec())/500)/1000, 
			sin(float(Time.get_ticks_msec())/500)/1000
		)*100
		get_node("Arm/Hand").rotation += breath*delta
		#get_node("Arm/Hand").position -= breath*Vector3(1, 1, 0)/6*delta
		get_node("Arm/Hand").rotation /= 1 + delta*20
		get_node("Arm/Hand").position /= 1+delta*10
		get_node("Head/Camera").rotation += breath*Vector3(1, 1, 0)*delta*.5
		get_node("Head/Camera").rotation /= 1+delta*5
		#get_node("Head/Camera").position += Vector3(0, 0, -.4)*delta*5
		#get_node("Head/Camera").position /= 1+delta*5


func crouch_process():
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
	get_node("Head/UI/PostProcess").material.set_shader_parameter("sneak_value", crouch_value/4)


func hitmarker_process():
	if hitmarker_time:
		var x = 1 - ((Game.time - hitmarker_time) / .3)
		# 1 > 0 // 0.3s
		if x <= 0 or hitmarker_time > Game.time:
			get_node("Head/UI/Hitmarker").visible = false
			hitmarker_time = 0
		get_node("Head/UI/Hitmarker").modulate = (get_node("Head/UI/Hitmarker").modulate/get_node("Head/UI/Hitmarker").modulate)*x
		get_node("Head/UI/Hitmarker").scale = (get_node("Head/UI/Hitmarker").scale)*x


func rotation_process(angle: Vector2):
	if angle:
		angle.x = clamp(-PI, angle.x, PI)
		angle.y = clamp(-PI, angle.y, PI)
		rotation.y += angle.x
		$Head.rotation.x = clamp(-PI/2, $Head.rotation.x + angle.y, PI/2)
		if ProjectSettings.get_setting("custom/game/camera_rotation"):
			$Head.rotation.z += angle.x / 10
		if ProjectSettings.get_setting("custom/game/dynamic_fov"):
			get_node("%Camera").fov = min(get_node("%Camera").fov + abs(angle.x * 5), 160)
		while abs(rotation.x) > 2*PI:
			rotation.x -= sign(rotation.x)*2*PI
		get_node("Head/UI/PostProcess").material.set_shader_parameter("rotation", 
			get_node("Head/UI/PostProcess").material.get_shader_parameter("rotation") - Vector3(angle.y, angle.x, 0)*60
		)
		get_node("Arm/Hand").rotation.x += -angle.y/4


func spawn():
	if Game:
		if Game.spawnpoints:
			transform = Game.spawnpoints[randi() % len(Game.spawnpoints)].transform
	get_node("%Camera").current = true
	get_node("Head/UI").visible = true
	visible = true
	health = 100
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


@rpc("authority", "call_local", "reliable", 0)
func switch_weapon(weapon: int):
	if weapon < len(inventory.weapons):
		#get_node("Arm/Hand/"+str(weapon)+"/Animator").play("switch_weapon_out")
		#get_node("Arm/Hand/"+str(active_weapon)+"/Animator").play("switch_weapon_in")
		#get_node("Arm/Hand/"+str(active_weapon)+"/Animator").get_animation().track_set_key_value(0, 0, get_node("Arm/Hand/"+str(active_weapon)), position)
		get_node("Arm/Hand/"+str(active_weapon)).visible = false
		get_node("Arm/Hand/"+str(weapon)).visible = true
		active_weapon = weapon
		print("active_weapon :", active_weapon) 


func get_hit(_owner, _damages, collision):
	if collision == "HeadCollision":
		health -= 2*_damages
	else:
		health -= _damages
	if health <= 0:
		# get_node("../" + _owner).rpc_id(int(_owner), "kill")
		die()
		return 1
	return 0


func die():
	rotation.z += PI/2
	position.y -= 0.8
	deaths += 1
	process_mode = Node.PROCESS_MODE_DISABLED
	if is_multiplayer_authority():
		get_node("%Camera").current = false
		get_node("Head/UI").visible = false
		Game.add_child(Game.DeathUi)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		rpc("online_synchronisation", get_online_synchronisation_data())


func get_online_synchronisation_data():
	return [position, rotation.y, get_node("Head").rotation.x, health, visible, kills, deaths, 
			get_node("Mesh").mesh.height, active_weapon]


@rpc("authority", "call_remote", "unreliable", 0)
func online_synchronisation(data: Array = [
		"position", 
		"rotation_y", 
		"head_rotation_x", 
		"health", 
		"visible", 
		"kills", 
		"deaths", 
		"mesh_height",
		"active_weapon"
		]):
	position = data[0]
	rotation.y = data[1]
	get_node("Head").rotation.x = data[2]
	health = data[3]
	visible = data[4]
	kills = data[5]
	deaths = data[6]
	get_node("Mesh").mesh.height = data[7]
	active_weapon = data[8]


@rpc("authority", "call_remote", "reliable", 0)
func online_inventory_synchronisation(_inventory: Dictionary):
	inventory = _inventory


@rpc("any_peer", "call_local", "reliable", 5)
func hitmarker(_damages: float, type: String, is_kill: bool):
	print(get_node("Head"))
	print(get_node("Head/UI"))
	print(get_node("Head/UI/Hitmarker"))
	print(name)
	print(multiplayer.get_unique_id())
	get_node("Head/UI/Hitmarker").scale = Vector2(0.5,0.5)+(Vector2(0.8,0.8)*_damages)/20
	if type == "HeadCollision":
		get_node("hitmarker_sfx").volume_db = 8+(16*_damages)/100
		get_node("hitmarker_sfx").stream = Game.audio_samples["headshot_hitmarker"]
		get_node("Head/UI/Hitmarker").scale *= 2
		get_node("Head/UI/Hitmarker").modulate = Color(1,0,0)
	else:
		get_node("hitmarker_sfx").volume_db = 8+(16*_damages)/100
		get_node("hitmarker_sfx").stream = Game.audio_samples["hitmarker"]
		get_node("Head/UI/Hitmarker").modulate = Color(1,1,1)
	get_node("hitmarker_sfx").play()
	get_node("Head/UI/Hitmarker").visible = true
	hitmarker_time = Game.time
	if is_kill:
		kill()


func update_weapons():
	for slot in len(inventory.weapons):
		var weapon = inventory.weapons[slot]
		if has_node("Arm/Hand/"+str(slot)):
			var old = get_node("Arm/Hand/"+str(slot))
			get_node("Arm/Hand/").remove_child(old) 
			old.queue_free()
		var new_weapon = load("res://root/game/entities/player/weapons/"+weapon["type"]+"/"+weapon["base"]+".tscn").instantiate()
		new_weapon.set_multiplayer_authority(get_multiplayer_authority())
		new_weapon.name = str(slot)
		get_node("Arm/Hand").add_child(new_weapon)
		new_weapon.initiate_weapon(weapon)
		new_weapon.visible = false
	get_node("Arm/Hand/"+str(active_weapon)).visible = true


@rpc("any_peer", "call_local", "reliable", 1)
func rpc_buy(item, slot):
	inventory["weapons"][slot] = Data.shop[item].duplicate(true)
	update_weapons()


func kill():
	kills += 1
	score += 5
