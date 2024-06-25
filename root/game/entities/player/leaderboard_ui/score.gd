extends ColorRect

var Players

func update():
	var player: Player = Players.get_node(str(name))
	get_node("Name").text = str(name)
	get_node("Kills").text = str(player.kills)
	get_node("Deaths").text = str(player.deaths)
	get_node("Weapons").clear()
	var weapons = player.inventory["weapons"]
	for weapon in weapons:
		get_node("Weapons").add_item(weapon.base+" |")
	get_node("Points").text = str(player.score) #faudra rename cette variable un jour, REEL

func lobby_update(data: Array):
	get_node("Name").text = str(name)
	get_node("Kills").text = str(data[0])
	get_node("Deaths").text = str(data[1])
	get_node("Weapons").clear()
	var items = data[2]
	for item in items:
		if item != "base":
			get_node("Items").add_item(item+" |")
	get_node("Points").text = str(data[3])
