extends Control

var player 
var Game
var slot


func update():
	pass


func _ready():
	if get_parent().name != "Lobby":
		player = get_node("../../..")
		Game = get_node("../../../../../..")
	for item in Data.shop.keys():
		$"Légende/Shop/ColorRect/Weapon_shop".add_item(item)
	slot = 0
	_on_weapon_selected(0)

func _on_weapon_selected(newslot):
	#if player.inventory["weapons"][newslot]["type"] == "nothing":
	#	return
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
	player.rpc("rpc_buy", $"Légende/Shop/ColorRect/Weapon_shop".get_item_text(index), slot)
	_on_weapon_selected(slot)
