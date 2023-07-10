class_name Player
extends CharacterBody3D

@onready var bullet = preload("res://bullet.tscn")

var game

var health:      float =  100.
var damages:     float =  34.
var gravity:     float = -ProjectSettings.get_setting("physics/3d/default_gravity")
var air_speed:   float =  50.
var jump:        float =  7.
var speed:       float =  5.
var sensi:     Vector2 = -Vector2(.005, .005)
var joy_sensi: Vector2 = -Vector2(.1, .1)


func _ready():
	game = get_node("../../..")
	if is_multiplayer_authority():
		spawn()
	else:
		get_node("Collision").queue_free()
		get_node("Head/Light").queue_free()
		get_node("Head/UI").queue_free()
		get_node("Head/Camera").queue_free()


func _input(event):
	if is_multiplayer_authority():
		if event is InputEventMouseMotion:
			rotation.y += event.relative.x * sensi.x
			$Head.rotation.x = clamp(-1.57, $Head.rotation.x + event.relative.y * sensi.y, 1.57)
			$Head.rotation.z += event.relative.x * sensi.x / 10
			get_node("Head/Camera").fov = min(get_node("Head/Camera").fov + abs(event.relative.x * sensi.x * 5), 160)


func _physics_process(delta):
	if is_multiplayer_authority():
		var input_rotation = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
		if input_rotation:
			rotation.y += input_rotation.x * joy_sensi.x
			$Head.rotation.x = clamp(-1.57, $Head.rotation.x + input_rotation.y * joy_sensi.y, 1.57)
			$Head.rotation.z += input_rotation.x * joy_sensi.x / 10
			get_node("Head/Camera").fov = min(get_node("Head/Camera").fov + abs(input_rotation.x * sensi.x * 5), 160)
		#print(velocity.dot(transform.basis.x))
		var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").normalized()
		input = Vector3(input.x, 0, input.y)

		if is_on_floor():
			if Input.is_action_pressed("jump"):
				rpc("shoot", get_node("Head").global_position, get_node("Head").global_rotation)
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
		$Head/UI.scale = Vector3.ONE * .25 + Vector3.ONE * float(int(sqrt(pow(velocity.x, 2) + pow(velocity.z, 2)) * 1000)) / 1000 / 20
		$Head/UI.scale += abs(Vector3.ONE * velocity.y * .05)
		$Head/UI.scale += Vector3.ONE * float(!is_on_floor()) * .1
		$Head/UI.scale.z = 1 
		get_node("Head/Camera").fov = (get_node("Head/Camera").fov - 120) / 1.2 + 120
		
		rpc("online_syncronisation", position, rotation, get_node("Head").rotation)


func spawn():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_node("Head/Camera").current = true
	transform = game.spawnpoints[randi() % len(game.spawnpoints)].transform
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
	rpc("online_syncronisation", position, rotation, get_node("Head").rotation)
	await get_tree().create_timer(2.0).timeout
	spawn()
	process_mode = Node.PROCESS_MODE_INHERIT


@rpc("authority", "call_local", "unreliable", 0)
func shoot(pos, rot):
	var new_bullet = bullet.instantiate()
	new_bullet.position = pos
	new_bullet.rotation = rot
	new_bullet.damages = damages
	if is_multiplayer_authority():
		new_bullet.collision_mask = 0b10
	game.get_node("Entities").add_child(new_bullet)


@rpc("authority", "call_remote", "unreliable", 0)
func online_syncronisation(_position: Vector3, _rotation: Vector3, _head_rotation: Vector3):
	position = _position
	rotation = _rotation
	get_node("Head").rotation = _head_rotation
