extends CharacterBody3D

var SPEED = 1
var JUMP_VELOCITY = 1
var gravity = 1

enum STATE {
	IDLE = 0
}

var state: STATE = STATE.IDLE
var head_rotation: Vector3 = Vector3()

func _input(event):
	if is_multiplayer_authority():
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if event is InputEventMouseMotion:
				head_rotation.x -= event.relative.y*0.005
				head_rotation.y -= event.relative.x*0.005


func _physics_process(delta):
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SPEED = 10
	JUMP_VELOCITY = 3
	gravity = 10
	if is_on_floor():
		if Input.is_action_pressed("jump"):velocity.y = JUMP_VELOCITY
	else:velocity.y -= gravity * delta
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	$B/H/Camera3D/Speed.text = "Speed: "+str(float(round(sqrt(pow(velocity.x, 2)+pow(velocity.z, 2))*10))/10)+"m/s"
	$B/H/Camera3D/Speed2.value = float(round(sqrt(pow(velocity.x, 2)+pow(velocity.z, 2))*10))/10
	if state == STATE.IDLE:
		if !velocity and !direction and 0:
			$B.rotation *= Vector3.UP
			
			$B/RH.rotation = Vector3()
			$B/RH/Sub/Sub.rotation.x = 0.
			
			$B/RL.rotation = Vector3()
			$B/RL/Sub.rotation.x = 0.
			
			$B/LH.rotation = Vector3()
			$B/LH/Sub/Sub.rotation.x = 0.
			
			$B/LL.rotation = Vector3()
			$B/LL/Sub.rotation.x = 0.
			
			$B/H.rotation *= Vector3.RIGHT
		else:
			if $Cast.is_colliding() and $Cast.get_collision_normal().dot(Vector3.UP) > 0.2:
				if direction:
					velocity.x = move_toward(velocity.x, SPEED*direction.x, SPEED*delta*30)
					velocity.z = move_toward(velocity.z, SPEED*direction.z, SPEED*delta*30)
				else:
					velocity.x = move_toward(velocity.x, 0, SPEED*delta*10)
					velocity.z = move_toward(velocity.z, 0, SPEED*delta*10)
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED*delta*1)
				velocity.z = move_toward(velocity.z, 0, SPEED*delta*1)
				
			move_and_slide()


func _process(delta):
	$B/H/Camera3D.global_rotation += head_rotation - $B/H/Camera3D.global_rotation
	
	$Cast.transform.basis.y.x = log(abs(velocity.x)+1)*sign(-velocity.x)/2
	$Cast.transform.basis.y.z = log(abs(velocity.z)+1)*sign(-velocity.z)/2
	var u = Vector3()# ($B/H/Camera3D.global_rotation*10 - $B.global_rotation)*delta*10
	var v = Vector3(
		log(abs(velocity.z)+1)*sign(velocity.z)/10, 
		log(abs(velocity.x)+1)*sign(-velocity.x)/10, 
		log(abs(velocity.x)+1)*sign(velocity.x)/5
	)*delta*10
	$B.rotation += u + v
	$B.rotation /= 1+delta*10
	$B/H/Camera3D.rotation += u/(delta*10)
	$B/H/Camera3D.position = $B/H/Camera3D.transform.basis.z * 2
	#$B/H.global_rotation.y = head_rotation.y
	$B/H/Camera3D/Speed.text = "\n"+str(head_rotation.y)
	$B/H/Camera3D/Speed.text += "\n"+str($B/H.global_rotation.y)
	
	var fov = $B/H/Camera3D.fov + 90*delta*10 + sqrt(pow(velocity.x, 2)+pow(velocity.z, 2))*2*delta*10
	$B/H/Camera3D.fov = fov/(1+delta*10)
