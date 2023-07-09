extends CharacterBody3D


var gravity:   float = -ProjectSettings.get_setting("physics/3d/default_gravity")
var air_speed: float =  50.
var jump:      float =  7.
var speed:     float =  5.
var sensi:   Vector2 = -Vector2(.005, .005)


func _ready():
	if is_multiplayer_authority():
		get_node("Head/Camera").current = true
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


		#print("Speed: ", float(int(sqrt(pow(velocity.x, 2) + pow(velocity.z, 2)) * 1000)) / 1000)

	move_and_slide()

	if is_multiplayer_authority():
		$Head.rotation.z -= velocity.dot(transform.basis.x) / 1000
		$Head.rotation.z /= 1.1
		$Head/UI.scale = Vector3.ONE * .25 + Vector3.ONE * float(int(sqrt(pow(velocity.x, 2) + pow(velocity.z, 2)) * 1000)) / 1000 / 20
		$Head/UI.scale += abs(Vector3.ONE * velocity.y * .05)
		$Head/UI.scale += Vector3.ONE * float(!is_on_floor()) * .1
		$Head/UI.scale.z = 1 
		get_node("Head/Camera").fov = (get_node("Head/Camera").fov - 120) / 1.2 + 120
