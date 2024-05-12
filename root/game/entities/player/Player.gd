class_name Player
extends CharacterBody3D

var Game

var health:            float =  100.
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

var interact_objects: Array = []
var current_interact = null
var speed_modifyer: float = 1.

var inventory = {
	"weapons": [
		{
			"name": "M4A1", 
			"types": ["gun", "rifle"], 
			"state": "idle", 
			"ammo": 40, 
			"weight": 20.
		}, 
		{
			"name": "cut", 
			"types": ["melee", "dagger", "cut"], 
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


func _enter_tree():
	if is_multiplayer_authority():
		$Head/UI.add_child(load("res://root/game/entities/player/leaderboard_ui/leaderboard_ui.tscn").instantiate())


func calibrate_ui():
	var window_size = get_viewport().size
	get_node("Head/UI").scale.x = float(window_size.x) / 1152
	get_node("Head/UI").scale.y = float(window_size.y) / 648
	print(get_node("Head/UI").scale)
	get_node("Head/UI").position = window_size / 2


func _input(event):
	speed = 7.5
	if is_multiplayer_authority():
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if event is InputEventMouseMotion:
				rotation_process(event.relative*mouse_sensi)

var friction: float = 100
func _physics_process(delta):
	#joy_sensi = mouse_sensi * 10000
	if is_multiplayer_authority():
		var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").normalized()
		input *= speed*(1-crouch_value)+crouch_speed*crouch_value
		input *= speed_modifyer
		var x = 50/(inventory.weapons[active_weapon].weight+50)
		input *= x
		gravity = (2-x/2)*-ProjectSettings.get_setting("physics/3d/default_gravity")
		input = Vector3(input.x, 0, input.y)
		velocity += transform.basis * input * delta * (friction/2+50)
		if is_on_floor():
			friction += 100*delta
			friction /= 1+delta
			if Input.is_action_pressed("jump"):
				velocity.y = jump
		else:
			friction += 1*delta/10
			friction /= 1+delta/10
			velocity.y += gravity * delta
		velocity.x /= 1 + delta * friction
		velocity.z /= 1 + delta * friction
		#print(friction)
		move_and_slide()
		#print("Speed: ", round((velocity * Vector3(1, 0, 1)).length()*10)/10)
		#print("Gravity: ", round(-gravity*10)/10)
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


var dt: float = 0.
func _process(delta):
	if is_multiplayer_authority():
		if Input.is_key_pressed(KEY_0):
			velocity.y += 1
		crouch_process()
		hitmarker_process()
		rotation_process(Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")*delta*joy_sensi)
		get_node("Head/UI/HealthBar").value = health
		if Input.is_action_pressed("change_weapon"):
			switch_weapon((active_weapon+1)%len(inventory.weapons))
		$Head/UI.get_node("leaderboard_ui").visible = Input.is_action_pressed("show_leaderboard")
		if Input.is_action_pressed("change_to_primary_weapon"):
			switch_weapon(0)
		elif Input.is_action_pressed("change_to_secondary_weapon"):
			switch_weapon(1)
		rpc("online_synchronisation", get_online_synchronisation_data())
		if ProjectSettings.get_setting("custom/game/camera_rotation"):
			$Head.rotation.z -= velocity.dot(transform.basis.x) * delta*.04
		$Head.rotation.z /= 1 + delta*10
		get_node("Arm/Hand").rotation.y += -$Head.rotation.z*2
		get_node("Arm/Hand").rotation.y /= 2.
		get_node("%Camera").fov = (get_node("%Camera").fov - 100+crouch_value*20) / 1.2 + 100 - crouch_value*20
		$Arm/Hand.rotation.z = crouch_value/10
		get_node("Arm/Hand").rotation.z += $Head.rotation.z*2
		if ProjectSettings.get_setting("custom/game/camera_bounce"):
			var x = float(is_on_floor()) * min(abs(velocity.x)+abs(velocity.z), 1)*min(speed_modifyer, 1)*(1-crouch_value*.8)
			get_node("%Camera").position.x += (pow(sin(dt*.01 ), 2) *.4-.2      ) * delta * 10 * x
			get_node("%Camera").position.y -= (pow(cos(dt*.02 ), 2) *.4-.2      )    * delta * 10 * x
			get_node("%Camera").position.z += (pow(sin(dt*.02 ), 2) *.2-.1  -.4 ) * delta * 10 * x 
			get_node("%Camera").position   += Vector3(0, 0, -0.4) * delta * 10 * (1-x)
			get_node("%Camera").position   /= 1+delta*10
			$Head.rotation.z               -= (pow(cos(dt*.01 ), 2) *.01-.005   ) * delta * 10 * x
			$Head.rotation.z               += (pow(cos(dt*.005), 2) *.01-.005   ) * delta * 10 * x
			$Head.rotation.x               += (pow(cos(dt*.02 ), 2) *.02-.01    ) * delta * 10 * x
			$Arm/Hand.position.x           += (pow(sin(dt*.01 ), 2) *.35-.175   ) * delta * 10 * x
			$Arm/Hand.position.y           -= (pow(cos(dt*.02 ), 2) *.35-.175   ) * delta * 10 * x
			$Arm/Hand.position.z           += (pow(sin(dt*.02 ), 2) *.2 -.1  -.1) * delta * 10 * x 
			$Arm/Hand.position.x           += -velocity.dot($Head/Camera.global_basis.x)*.001 * delta * 10
			$Arm/Hand.position.z           += -velocity.dot($Head/Camera.global_basis.z)*.002 * delta * 10
			$Arm/Hand.position             += Vector3(0, -log(abs(velocity.y+1))*sign(velocity.y)*.02, -.1) * delta * 10 * (1-x)
			$Arm/Hand.position /= 1+delta*10
		else:
			get_node("%Camera").position = get_node("%Camera").position + Vector3(0, 0.45, 0.4)*delta*10
			get_node("%Camera").position /= 1+delta*10
			$Arm/Hand.position = $Arm/Hand.position + Vector3(0, 0, -5)*delta*10
			$Arm/Hand.position /= delta*10
		get_node("Head/UI/PostProcess").material.set_shader_parameter("rotation", 
			get_node("Head/UI/PostProcess").material.get_shader_parameter("rotation") / (1+delta*60)
		)
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


func get_hit(_owner, _damages, collision):
	if collision == "HeadCollision":
		health -= 2*_damages
	else:
		health -= _damages
	if health <= 0:
		get_node("../" + _owner).rpc_id(int(_owner), "kill")
		die() 


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
			get_node("Mesh").mesh.height]


@rpc("authority", "call_remote", "unreliable", 0)
func online_synchronisation(data: Array = [
		"position", 
		"rotation_y", 
		"head_rotation_x", 
		"health", 
		"visible", 
		"kills", 
		"deaths", 
		"mesh_height"
		]):
	position = data[0]
	rotation.y = data[1]
	get_node("Head").rotation.x = data[2]
	health = data[3]
	visible = data[4]
	kills = data[5]
	deaths = data[6]
	get_node("Mesh").mesh.height = data[7]


@rpc("authority", "call_remote", "reliable", 0)
func online_inventory_synchronisation(_inventory: Dictionary):
	inventory = _inventory


@rpc("any_peer", "call_local", "reliable", 5)
func hitmarker(_damages: float, type: String, is_kill: bool):
	get_node("Head/UI/Hitmarker").scale = Vector2(0.5,0.5)+(Vector2(0.8,0.8)*_damages)/20
	if type == "headshot":
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


func kill():
	kills += 1
	score += 5
