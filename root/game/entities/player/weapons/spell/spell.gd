extends Node

var damages
var cooldown
var manacost
var speed
  

func initiate_weapon(weapon):
	var stats = weapon["stats"]
	damages = stats["damages"]
	cooldown = stats["cooldown"]
	manacost = stats["manacost"]
	speed = stats["speed"]


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
