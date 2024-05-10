extends Node3D

var last_shoot: float = 0.
var rps: float = 20.
var damages: float = 20.
func primary_process(_delta):
	var t = get_node("../../../").Game.time
	if t - last_shoot > 1/rps:
		rpc("shoot", $Lazer.global_position, $Lazer.global_rotation, damages)
		last_shoot = t
		var rot = Vector3(
			randf()*.04-.02+.02, 
			randf()*.04-.02,
			0
		)*2
		rotation += rot.x*-global_basis.x
		rotation += rot.y*global_basis.y
		rotation += rot.z*global_basis.z
		get_node("../../../Head/Camera").rotation += rot.x*.5*-global_basis.x
		get_node("../../../Head/Camera").rotation += rot.y*.5*global_basis.y
		get_node("../../../Head/Camera").rotation += rot.z*.5*global_basis.z
		get_node("../../../Head/Camera").position -= rot.y*global_basis.y
		#get_node("../../../Head/Camera").position.x += rot.x
		position.x += -rot.x
		position.y += -rot.y
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
	Bullet.init(str(get_node("../../..").name), _damages, 100)
	
	


func secondary_process(_delta):
	rotation.x /= 1+_delta*5
	rotation.y /= 1+_delta*5
	rotation.z /= 1+_delta*5
	position += Vector3(.0, 0., -0.75) * _delta*30
	position /= 1 + _delta*30
	get_node("../../../Head/Camera").fov *= .75
	get_node("../../../").speed_modifyer += .5 * _delta*60
	get_node("../../../").speed_modifyer /= 1 + _delta*60
	get_node("../../../Head/Camera").fov += log(rotation.length()*100+1)
	#get_node("../../../Head/Camera").fov /= 1+_delta*60


func _process(delta):
	if is_multiplayer_authority():
		rotation.x /= 1+delta*5
		rotation.y /= 1+delta*5
		rotation.z /= 1+delta*5
		if (int(str(name)) == get_node("../../../").active_weapon):
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				if Input.is_action_pressed("primary_attack"):
					primary_process(delta)
				if Input.is_action_pressed("secondary_attack"):
					secondary_process(delta)
				else:
					position += Vector3(0.25, -0.1, -0.667) * delta*10
					position /= 1 + delta*10
					get_node("../../../Head/Camera").fov *= 1.
					get_node("../../../").speed_modifyer += 1. * delta*30
					get_node("../../../").speed_modifyer /= 1 + delta*30
		else:
			get_node("../../../").speed_modifyer += 1. * delta*30
			get_node("../../../").speed_modifyer /= 1 + delta*30
