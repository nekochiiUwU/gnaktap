extends Node

var Game
# Called when the node enters the scene tree for the first time.
func _ready():
	Game = get_node("..").Game #sus

func update():
	var player = get_node("../" + get_node("Name").text)
	get_node("Kills").text = str(player.kills)
	get_node("Deaths").text = str(player.deaths)
	get_node("Items").clear()
	var items = player.inventory["items"]
	for i in items:
		if items != "base":
			get_node("Items").add_item(i)
	get_node("Points").text = str(player.target_score) #faudra rename cette variable un jour
