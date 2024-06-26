extends Control

var player 
var Game
var slot

var shop:Dictionary = {
		"AR": {
			"type": "gun", 
			"base": "AR", 
			"stats": {
				"damages": 25,
				"firerate": 10,
				"magsize": 30,
				"stability": 1,
				"dropoff": 10,
				"scope": 1.5
			},
			"upgrades":[],
			"state": "idle", 
			"weight": 20.
		}, 
		"cut": {
			"type": "melee", 
			"base": "cut", 
			"stats": {
				"damages": 40,
				"animspeed": 1,
				"size": 1,
				"movespeed": 1,
			},
			"upgrades":[],
			"state": "idle", 
			"weight": 2.
		},
		"fire": {
			"type": "spell", 
			"base": "fire", 
			"stats": {
				"damages": 25,
				"cooldown": 3,
				"manacost": 30,
				"speed": 3,
			},
			"upgrades":[],
			"state": "idle", 
			"weight": 20.
		},
		"nothing": {
			"type": "nothing", 
			"base": "nothing", 
			"stats": {},
			"upgrades":[],
			"state": "idle", 
			"weight": 20.
		}
}

func update():
	pass


func _ready():
	if get_parent().name != "Lobby":
		player = get_node("../../..")
		Game = get_node("../../../../../..")
	for item in shop.keys():
		$"Légende/Shop/ColorRect/Weapon_shop".add_item(item)
	slot = 0
	_on_weapon_selected(0)

func _on_weapon_selected(newslot):
	if player.inventory["weapons"][newslot]["type"] == "nothing":
		return
	slot = newslot
	var keys = player.inventory["weapons"][slot]["stats"].keys()
	for i in range(4):
		get_node("Légende/Shop/Stats/Stat"+str(i)+"/Titre").text = keys[i]
		get_node("Légende/Shop/Stats/Stat"+str(i)+"/Nombre").text = str(player.inventory["weapons"][slot]["stats"][keys[i]])
	

func _on_stat_set(value, stat):
	var key = (player.inventory["weapons"][slot]["stats"].keys())[stat]
	player.inventory["weapons"][slot]["stats"][key] = value
	_on_weapon_selected(slot)
	player.update_weapons()


func _on_weapon_bought(index):
	player.inventory["weapons"][slot] = shop[$"Légende/Shop/ColorRect/Weapon_shop".get_item_text(index)].duplicate(true)
	_on_weapon_selected(slot)
	player.update_weapons()
