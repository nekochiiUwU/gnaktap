extends Node3D
var animation = null

var damages = 40
var animspeed: float = 1
var size: float =  1
var movespeed = 1

func initiate_weapon(weapon):
	var stats = weapon["stats"]
	damages = stats["damages"]
	animspeed = stats["animspeed"]
	size = stats["size"]
	movespeed = stats["movespeed"]
	scale = Vector3(1,1,1)*size


func primary_process(_delta):
	if !animation:
		animation = {"s": $AnimationPlayer.get_animation("slash"), "t": 0.}


func secondary_process(_delta):
	animation = {"s": $AnimationPlayer.get_animation("slash"), "t": 0.}


func animation_process(delta):
	animation.t += delta*animspeed
	if animation.t > animation.s.length:
		animation = null
		return null
	position = get_animated_variable(animation.s, 0, animation.t)
	rotation = get_animated_variable(animation.s, 1, animation.t)
	print(animation.s.track_find_key(2, animation.t))
	$Area3D.monitoring = animation.s.track_get_key_value(2, animation.s.track_find_key(2, animation.t))

func get_animated_variable(anim, track, time):
	var key = anim.track_find_key(track, time)
	if anim.track_get_key_time(track, key) > time: key -= 1
	var from = anim.track_get_key_value(track, key)
	var to = anim.track_get_key_value(track, (key+1)%anim.track_get_key_count(track))
	var from_time = anim.track_get_key_time(track, key)
	time -= from_time
	var to_time = anim.track_get_key_time(track, (key+1)%anim.track_get_key_count(track))
	if to_time < from_time: to_time = anim.length
	time /= to_time-from_time
	return ((1.-time)*from + time*to)


func _physics_process(delta):
	if is_multiplayer_authority():
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and (int(str(name)) == get_node("../../../").active_weapon):
				if Input.is_action_just_pressed("primary_attack"):
					primary_process(delta)
				if Input.is_action_just_pressed("secondary_attack"):
					secondary_process(delta)

func _process(delta):
	if is_multiplayer_authority():
		if (int(str(name)) == get_node("../../../").active_weapon):
			if animation:
				animation_process(delta)

# Called when the node enters the scene tree for the first time.
func _ready():
	if is_multiplayer_authority():
		get_node("Area3D/Collision").disabled = true


func _on_area_3d_body_entered(body):
	var _owner = str(get_node("../../..").name)
	"""
	if get_node("AnimationPlayer").current_animation == "slash":
		damages = 50
	elif get_node("AnimationPlayer").current_animation == "stab":
		damages = 34
	else:
		damages = 0 # ?????
	"""
	if body is Player:
		body.get_hit(_owner, damages, "Collision")
		get_node("../../..").rpc_id(int(_owner), "hitmarker", damages, "Collision")
	get_node("Area3D").set_deferred("monitoring", false)
