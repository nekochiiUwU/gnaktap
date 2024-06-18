extends Node3D

var last_shoot: float = 0.
var rps: float = 20.
var damages: float = 20.


func primary_process(_delta):
	var t = get_node("../../../").Game.time
	rps = 12.
	if t - last_shoot > 1/rps:
		rpc("shoot", $Lazer.global_position, $Lazer.global_rotation, damages)
		last_shoot = t
		var rot = Vector3(
			randf()*1-.5+.5, 
			randf()*1-.5,
			0
		).normalized()*0.025*1*(1+get_node("../../..").velocity.length()/4)
		rotation += rot
		get_node("../../../Head/Camera").rotation += rot/2
		get_node("../../../Head/Camera").rotation.x += rot.x*.75
		#get_node("../../../Head/Camera").position.y -= rot.x*.25
		position.x -= rot.y
		position.y += rot.x/2
		position.z += .04


@rpc("authority", "call_local", "unreliable")
func shoot(_position, _rotation, _damages):
	get_node("Canon/AudioStreamPlayer3D").pitch_scale = randf()*.1+.2
	get_node("Canon/AudioStreamPlayer3D").pitch_scale = 1
	get_node("Canon/AudioStreamPlayer3D").play()
	var Bullet = load("res://root/game/entities/bullet/bullet.tscn").instantiate()
	get_node("../../../../..").add_child(Bullet)
	Bullet.global_position = _position
	Bullet.global_rotation = _rotation
	Bullet.init(str(get_node("../../..").name), _damages, 50)


func secondary_process(_delta):
	rotation.x /= 1+_delta*2.5
	rotation.y /= 1+_delta*5
	rotation.z /= 1+_delta*5
	position += Vector3(.0, 0., -0.75) * _delta*30
	position /= 1 + _delta*30
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
		rotation.x /= 1+delta*2.5
		rotation.y /= 1+delta*5
		rotation.z /= 1+delta*5
		if (int(str(name)) == get_node("../../../").active_weapon):
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				#if Input.is_action_pressed("primary_attack"):
				#	primary_process(delta)
					
				if Input.is_action_pressed("secondary_attack"):
					secondary_process(delta)
					get_node("../../../").target_fov = get_node("../../../").user_fov/2
				else:
					get_node("../../../").target_fov = get_node("../../../").user_fov
					position += Vector3(0.25, -0.1, -0.667) * delta*15
					position /= 1 + delta*15
					get_node("../../../").speed_modifyer += 1. * delta*30
					get_node("../../../").speed_modifyer /= 1 + delta*30
		else:
			get_node("../../../").speed_modifyer += 1. * delta*30
			get_node("../../../").speed_modifyer /= 1 + delta*30
