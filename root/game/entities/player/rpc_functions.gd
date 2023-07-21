extends Node

@onready var s: Player = get_parent()


@rpc("authority", "call_local", "unreliable", 2)
func shoot_bullet(pos, rot, dmg, bspeed):
	var shoot_stream_player = s.get_node("Arm/Hand/Shoot Node/Weapon/Canon/AudioStreamPlayer3D")
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

@rpc("authority", "call_remote", "unreliable", 0)
func online_syncronisation(
		_position: Vector3, 
		_rotation: Vector3, 
		_head_rotation: Vector3, 
		_health: float, 
		_visible: bool,
		weapon_position: Vector3, 
		mesh_height: float):
	position = _position
	rotation = _rotation
	get_node("Head").rotation = _head_rotation
	get_node("%Weapon").position = weapon_position
	health = _health
	visible = _visible
	get_node("Mesh").mesh.height = mesh_height


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
