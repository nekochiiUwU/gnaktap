class_name Player
extends CharacterBody3D

@onready var bullet = preload("res://bullet.tscn")

var Game

var health:      float =  100.
var gravity:     float = -ProjectSettings.get_setting("physics/3d/default_gravity")
var air_speed:   float =  50.
var jump:        float =  7.
var sensi:     Vector2 = -Vector2(.005, .005)
var joy_sensi: Vector2 = -Vector2(.1, .1)
var hitmarker_time: float = 0
var shot_time:      float = 0
var reloading:      bool = false
var target_score:   int = 0
var incoming_recoil: Vector2 = Vector2()

#weapon stats
var weapon_type:  String = "full auto"
var scope:        String = "none" #pour plus tard
var accessory:    String = "none" #pour plus tard
var speed:        float  =  5.
var damages:      float  = 34.
var fire_rate:    float  = 600 #en RPM -> tir tous les 60/fire_rate
var accuracy:     float  = 5 #en degres
var recoil:       float  = 5 #en degres, a voir
var max_ammo:     int    = 30
var ammo:         int    = max_ammo
var reload_speed:  float  = 1.2
var bullet_speed: float  = 50. #stat ennuyeuse un peu ?



func _ready():
	Game = get_node("../../..")
	if is_multiplayer_authority():
		calibrate_ui()
		get_viewport().size_changed.connect(calibrate_ui)
		spawn()
	else:
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
		if event is InputEventMouseMotion:
			rotation.y += event.relative.x * sensi.x
			$Head.rotation.x = clamp(-1.57, $Head.rotation.x + event.relative.y * sensi.y, 1.57)
			$Head.rotation.z += event.relative.x * sensi.x / 10
			get_node("%Camera").fov = min(get_node("%Camera").fov + abs(event.relative.x * sensi.x * 5), 160)
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				if event.is_pressed():
					if get_node("%Weapon/Animation").current_animation != "scope":
						get_node("%Weapon/Animation").current_animation = "scope"
						get_node("%Weapon/Animation").play()
				else:
					get_node("%Weapon/Animation").current_animation = "no_scope"
					get_node("%Weapon/Animation").play()


func _physics_process(delta):
	if is_multiplayer_authority():

		if hitmarker_time:
			var x = 1 - ((Game.time - hitmarker_time) / .3)
			# 1 > 0 // 0.3s
			if x <= 0 or hitmarker_time > Game.time:
				get_node("Head/UI/Hitmarker").visible = false
				hitmarker_time = 0
			get_node("Head/UI/Hitmarker").modulate = Color(x, x, x)
			get_node("Head/UI/Hitmarker").scale = Vector2(x, x)

		if incoming_recoil:
			get_node("Head").rotation_degrees.x += incoming_recoil.y / 2
			rotation_degrees.y += incoming_recoil.x / 2
			incoming_recoil /= 2

		if get_node("Arm/Hand/Shoot Node").position:
			get_node("Arm/Hand/Shoot Node").position /= 1.05
		if get_node("Arm/Hand/Shoot Node").rotation:
			get_node("Arm/Hand/Shoot Node").rotation /= 1.05

		health += delta
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
		
		if Input.is_action_pressed("shoot"):
			try_shoot()
		
		if is_on_floor():
			if Input.is_action_pressed("jump"):
				velocity.y = jump
			input *= speed
		else:
			velocity.y += gravity * delta
			input *= air_speed

		velocity += transform.basis * input

		if is_on_floor():
			velocity.x *= .5
			velocity.z *= .5
		else:
			velocity.x /= 11
			velocity.z /= 11

		#print("Speed: ", float(int(sqrt(pow(velocity.x, 2) + pow(velocity.z, 2)) * 1000)) / 1000)

		move_and_slide()
		$Head.rotation.z -= velocity.dot(transform.basis.x) / 1000
		$Head.rotation.z /= 1.1
		get_node("Arm/Hand").rotation.z = ($Head.rotation.z + get_node("Arm/Hand").rotation.z*1) / 2
		get_node("Arm/Hand").position.x = get_node("Arm/Hand").rotation.z / 4
		get_node("%Camera").fov = (get_node("%Camera").fov - 120) / 1.2 + 120

func _process(_delta):
	if is_multiplayer_authority():
		rpc("online_syncronisation", position, rotation, get_node("Head").rotation, health, get_node("%Weapon").position)


func update_ammo():
	get_node("Head/UI/Ammo").text = str(ammo)+"/"+str(max_ammo)


func try_shoot():
	if shot_time - Game.time + 60/fire_rate > 0:
		return
	if reloading:
		return
	if ammo == 0:
		if !reloading and !Input.is_action_just_pressed("shoot"):
			reload() #ou pas, au choix
		return
	if weapon_type == "full auto": 
		#aucun check en plus
		pass
	elif weapon_type == "semi-auto": 
		if !Input.is_action_just_pressed("shoot"):
			return
	elif weapon_type == "autre chose":
		#a completer avec burst, shotgun, verrou...
		pass
	ammo -= 1
	accuracy = 5
	update_ammo()
	var ori = get_node("Head").global_rotation_degrees
	ori.x += randf_range(0, accuracy) - accuracy / 2
	ori.y += randf_range(0, accuracy) - accuracy / 2
	shot_time = Game.time
	incoming_recoil.y += randf_range(0, recoil)
	incoming_recoil.x += randf_range(-recoil/2, recoil/2)
	get_node("Arm/Hand/Shoot Node").position.z += 0* -0.02 * (get_node("%Weapon").position.z + 0.45) + incoming_recoil.x * 0.0
	get_node("Arm/Hand/Shoot Node").position.y += 0*(get_node("%Weapon").position.y + 0.09) * -.03 + incoming_recoil.y * 0.0
	#get_node("Arm/Hand/Shoot Node").position.x += sign(get_node("%Weapon").position.x) + .1 * incoming_recoil.y * 0.01
	#get_node("Arm/Hand/Shoot Node").rotation.x += .05
	rpc("shoot", get_node("%Camera").global_position, ori)


func reload():
	print("reloading...")
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

	get_node("%Camera").current = true
	if Game:
		transform = Game.spawnpoints[randi() % len(Game.spawnpoints)].transform
	health = 100


func get_hit(damages):
	health -= damages
	print(health)
	if health < 0:
		die() 


func die():
	process_mode = Node.PROCESS_MODE_DISABLED
	rotation.z += 90
	position.y -= 0.8
	rpc("online_syncronisation", position, rotation, get_node("Head").rotation, health, get_node("%Weapon").position)
	await get_tree().create_timer(2.0).timeout
	spawn()
	process_mode = Node.PROCESS_MODE_INHERIT


@rpc("authority", "call_local", "unreliable", 2)
func shoot(pos, rot):
	var new_bullet = bullet.instantiate()
	new_bullet.position = pos
	new_bullet.rotation_degrees = rot
	new_bullet.set_script(load("res://bullet.gd"))
	new_bullet.damages = damages
	new_bullet.speed = bullet_speed
	new_bullet._owner = name
	if is_multiplayer_authority():
		new_bullet.collision_mask = 0b110
	Game.get_node("Entities").add_child(new_bullet)


@rpc("authority", "call_remote", "unreliable", 0)
func online_syncronisation(_position: Vector3, _rotation: Vector3, _head_rotation: Vector3, _health: float, weapon_position: Vector3):
	position = _position
	rotation = _rotation
	get_node("Head").rotation = _head_rotation
	get_node("%Weapon").position = weapon_position
	health = _health

@rpc("any_peer", "call_local", "unreliable", 5)
func hitmarker(damages: float):
	get_node("hitmarker_sfx").stream = load("res://hitmarker.mp3")
	get_node("hitmarker_sfx").play()
	get_node("Head/UI/Hitmarker").visible = true
	hitmarker_time = Game.time

@rpc("any_peer", "call_local", "unreliable", 6)
func target(score: int):
	target_score += score
	print("target hit ! score : ",target_score)
