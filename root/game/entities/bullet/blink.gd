extends Node3D

var velocity: Basis = Basis()
#var t = 0.
#var b = false
func _ready():
	velocity[0] = Vector3(randf()-.5, randf()-.5, randf()-.5)
	velocity[1] = velocity[0]+Vector3(randf()-.5, randf()-.5, randf()-.5)/2
	velocity[2] = velocity[0]+Vector3(randf()-.5, randf()-.5, randf()-.5)/2
	#t = 0
	#b = false
	for i in range(2):
		get_child(i).position = velocity[i]/10
		get_child(i).modulate.a = 1
	get_child(2).modulate.a = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#if t > 1./8. and !b:
	#	var clone = duplicate()
	#	get_parent().add_child(clone)
	#	b = true
	#t += delta
	for i in range(3):
		get_child(i).position += velocity[i]*delta
		velocity[i] += Vector3(randf()-.5, randf()-.5+2.0, randf()-.5)*delta
		velocity[i] /= 1+delta
		get_child(i).modulate.a /= 1+delta*(float(pow(max(i, 1), 4))*4)
	if get_child(0).modulate.a < 0.001:
		queue_free()
	if has_node("Light"):
		$Light.light_energy -= delta*60
		if $Light.light_energy < 0:
			$Light.queue_free()
