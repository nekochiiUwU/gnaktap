extends Node3D


func primary_process(_delta):
		pass


func secondary_process(_delta):
	position += Vector3(.02, -.12, -0.65) * _delta*10
	position /= 1 + _delta*10


func idle_process(_delta):
	position += Vector3(0.25, -0.2, -0.667) * _delta*10
	position /= 1 + _delta*10
