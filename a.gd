extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotation += delta * 2 * (1.5 - abs(rotation) / PI)
	if rotation > PI:
		rotation -= 2 * PI
