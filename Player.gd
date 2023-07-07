extends CharacterBody3D


var gravity:   float = -ProjectSettings.get_setting("physics/3d/default_gravity")
var air_speed: float =  50.
var jump:      float =  7.
var speed:     float =  5.
var sensi:   Vector2 = -Vector2(.005, .005)


func _input(event):
	if event is InputEventMouseMotion:
		rotation.y += event.relative.x * sensi.x
		$Head.rotation.x = clamp(-1.57, $Head.rotation.x + event.relative.y * sensi.y, 1.57)
		$Head.rotation.z += event.relative.x * sensi.x / 10


func _physics_process(delta):
	#print(velocity.dot(transform.basis.x))
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").normalized()
	input = Vector3(input.x, 0, input.y)

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

	$Head.rotation.z += -velocity.dot(transform.basis.x) / 1000
	$Head.rotation.z /= 1.1

	#print("Speed: ", float(int(sqrt(pow(velocity.x, 2) + pow(velocity.z, 2)) * 1000)) / 1000)

	move_and_slide()
