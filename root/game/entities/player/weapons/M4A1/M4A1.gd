extends Node3D

var last_shoot: float = 0.
var rps: float = 20.
var damages: float = 20.
var a = 1.

func primary_process(_delta):
	var t = get_node("../../../").Game.time
	#rps = 10.
	#damages = 25.
	#a = 1.
	
	#rps = 1.
	#damages = 99.
	#a=.5
	
	rps = 20.
	damages = 15.
	a=1.05
	if t - last_shoot > 1/rps:
		#get_node("../../..").velocity += global_basis.z*Vector3(100, 10, 100)*5
		rpc("shoot", $Lazer.global_position, $Lazer.global_rotation, damages)
		last_shoot = t
		var rot = Vector3(
			randf()*1-.5+.5, 
			randf()*1-.5,
			0
		).normalized()*0.025*pow(1/a, 2.5)*(1+get_node("../../..").velocity.length()/4)
		rotation += rot
		get_node("../../../Head/Camera").rotation += rot/2
		get_node("../../../Head/Camera").rotation.x += rot.x*.75
		#get_node("../../../Head/Camera").position.y -= rot.x*.25
		position.x -= rot.y
		position.y += rot.x/2
		position.z += rot.x


@rpc("authority", "call_local", "unreliable")
func shoot(_position, _rotation, _damages):
	get_node("Canon/AudioStreamPlayer3D").pitch_scale = randf()*.1+.95#rotation.x*2
	print(rotation.x*2)
	#get_node("Canon/AudioStreamPlayer3D").pitch_scale = 1
	get_node("Canon/AudioStreamPlayer3D").play()
	var Bullet = load("res://root/game/entities/bullet/bullet.tscn").instantiate()
	get_node("../../../../..").add_child(Bullet)
	Bullet.global_position = _position
	Bullet.global_rotation = _rotation
	Bullet.init(str(get_node("../../..").name), _damages, 50)


func secondary_process(_delta):
	rotation.x /= 1+_delta*2*a
	rotation.y /= 1+_delta*4*a
	rotation.z /= 1+_delta*4*a
	position += Vector3(.0, 0., -0.5) * _delta*30*a
	position /= 1 + _delta*30*a
	get_node("../../../").speed_modifyer += .5 * _delta*60
	get_node("../../../").speed_modifyer /= 1 + _delta*60
	get_node("../../../Head/Camera").fov += log(rotation.length()*100+1)/2
	#get_node("../../../Head/Camera").fov += log(rotation.length()*100+1)
	#get_node("../../../Head/Camera").fov /= 1+_delta*60


func _physics_process(delta):
	if is_multiplayer_authority():
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and (int(str(name)) == get_node("../../../").active_weapon):
				if Input.is_action_pressed("primary_attack"):
					primary_process(delta)

func _process(delta):
	if is_multiplayer_authority():
		rotation.x /= 1+delta*2*a
		rotation.y /= 1+delta*4*a
		rotation.z /= 1+delta*4*a
		if (int(str(name)) == get_node("../../../").active_weapon):
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				#if Input.is_action_pressed("primary_attack"):
				#	primary_process(delta)
					
				if Input.is_action_pressed("secondary_attack"):
					secondary_process(delta)
					get_node("../../../").target_fov = get_node("../../../").user_fov/1.5
				else:
					get_node("../../../").target_fov = get_node("../../../").user_fov
					position += Vector3(0.25, -0.1, -0.667) * delta*15*a
					position /= 1 + delta*15*a
					get_node("../../../").speed_modifyer += 1. * delta*30
					get_node("../../../").speed_modifyer /= 1 + delta*30
		else:
			get_node("../../../").speed_modifyer += 1. * delta*30
			get_node("../../../").speed_modifyer /= 1 + delta*30
