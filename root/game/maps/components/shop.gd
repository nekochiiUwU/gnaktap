class_name Shop
extends StaticBody3D

@onready var Items_Ui = get_node("Items UI")
@onready var item_list:ItemList = get_node("Items UI/ItemList")

var Game

var inventory = {
	#plus tard
}


func _ready():
	
	Game = get_node("/root/Game")
	calibrate_ui()
	get_viewport().size_changed.connect(calibrate_ui)
	
	if name == "Death Shop":
		inventory = {
			"smg kit":null,
			"AR kit":null,
			"sniper kit":null,
		}
	else:
		for i in range(6):
			var item = Game.stats_items.keys()[randi()%len(Game.stats_items)]
			while item in inventory.keys():
				item = Game.stats_items.keys()[randi()%len(Game.stats_items)]
			inventory[item] = Game.stats_items[item]
	var disp_items = inventory.keys()
	
	for i in disp_items:
		item_list.add_item(i)
	item_list.connect("item_selected", select)
	Items_Ui.get_node("Stats/Items").connect("item_selected", select_owned)
	Items_Ui.get_node("Selected/Button").connect("pressed", buy_or_sell)
	if item_list.item_count:
		item_list.deselect_all()
		item_list.select(0)
	Items_Ui.get_node("Mode/Select").selected = 0
	Items_Ui.get_node("Mode/Slider").visible = false
	Items_Ui.get_node("Mode/Select").connect("item_selected", update_mode)
	Items_Ui.get_node("Mode/Slider").connect("drag_ended", nb_shot_update)


func select(selected_item):
	var s = Items_Ui.get_node("Selected")
	item_list = get_node("Items UI/ItemList")
	s.get_node("Name").text = item_list.get_item_text(selected_item)
	var stats:String = ""
	var item = Game.stats_items[item_list.get_item_text(selected_item)]
	for i in range(len(item[0])):
		if item[0][i] != 0:
			stats += Game.conversion[i] + ": " + str(item[0][i]) + ", "
	stats += "\n"
	for i in range(len(item[1])):
		if item[1][i] != 0:
			stats += Game.conversion[i] + ": " + str(item[1][i]) + "%, "
	s.get_node("Stats").text = stats
	Items_Ui.get_node("Selected/Button").text = "Buy: " + str(item[2]) + "pts"
	s.visible = true


func select_owned(selected_item):
	var s = Items_Ui.get_node("Selected")
	item_list = Items_Ui.get_node("Stats/Items")
	s.get_node("Name").text = item_list.get_item_text(selected_item)
	var stats:String = ""
	var item = Game.stats_items[item_list.get_item_text(selected_item)]
	for i in range(len(item[0])):
		if item[0][i] != 0:
			stats += Game.conversion[i] + ": " + str(item[0][i]) + ", "
	stats += "\n"
	for i in range(len(item[1])):
		if item[1][i] != 0:
			stats += Game.conversion[i] + ": " + str(item[1][i]) + "%, "
	s.get_node("Stats").text = stats
	Items_Ui.get_node("Selected/Button").text = "Sell: " + str(item[2]) + "pts"
	s.visible = true


func update_Items_Ui():
	Items_Ui.get_node("Points").text = "Points : " + str(get_node("/root/Game").local_player.target_score)
	for stat in Game.conversion:
		Items_Ui.get_node("Stats/"+stat+"/Value").text = str(float(int(get_node("/root/Game").local_player.get(stat)*100))/100)
	item_list = Items_Ui.get_node("Stats/Items")
	item_list.clear()
	var items = get_node("/root/Game").local_player.inventory["items"]
	for i in items:
		item_list.add_item(i)


func buy_or_sell():
	if Items_Ui.get_node("Selected/Button").text.begins_with("Buy"):
		buy_item()
	else:
		sell_item()


func buy_item():
	var s = Items_Ui.get_node("Selected")
	var item = s.get_node("Name").text
	item_list = get_node("Items UI/ItemList")
	if item in item_list.get_item_text(item_list.get_selected_items()[0]) and \
			!Game.local_player.inventory["items"].has(item) and \
			Game.stats_items[item][2] <= Game.local_player.target_score and \
			len(Game.local_player.inventory["items"]) < 6:
		Game.local_player.target_score -= Game.stats_items[item][2]
		Game.local_player.inventory["items"].append(item)
		item_list.remove_item(item_list.get_selected_items()[0])
		Game.local_player.update_stats()
		update_Items_Ui()
		if item_list.item_count:
			item_list.select(0)
		else:
			item_list.deselect_all()
			s.visible = false


func sell_item():
	var s = Items_Ui.get_node("Selected")
	var item = s.get_node("Name").text
	item_list = Items_Ui.get_node("Stats/Items")
	if item in item_list.get_item_text(item_list.get_selected_items()[0]) and \
			Game.local_player.inventory["items"].has(item) and \
			!(item_list.get_item_text(item_list.get_selected_items()[0]) == "base"):
		Game.local_player.target_score += Game.stats_items[item][2]
		Game.local_player.inventory["items"].erase(item)
		get_node("Items UI/ItemList").add_item(item_list.get_item_text(item_list.get_selected_items()[0]))
		Game.local_player.update_stats()
		update_Items_Ui()
		if item_list.item_count:
			item_list.select(0)
		else:
			item_list.deselect_all()
			s.visible = false


func update_mode(mode):
	var new_mode = Items_Ui.get_node("Mode/Select").get_item_text(mode)
	if new_mode == "burst" or new_mode == "shotgun":
		var slider = Items_Ui.get_node("Mode/Slider")
		slider.visible = true
		slider.min_value = 2
		slider.max_value = (Game.local_player.max_ammo)/2
		slider.value = Game.local_player.nb_shot
		nb_shot_update(true)
	else:
		Items_Ui.get_node("Mode/Slider").visible = false
	Game.local_player.weapon_type = new_mode


func nb_shot_update(_has_changed):
	Game.local_player.nb_shot = Items_Ui.get_node("Mode/Slider").value
	Items_Ui.get_node("Mode/Slider/Nombre").text = str(Items_Ui.get_node("Mode/Slider").value)


func calibrate_ui():
	if !is_inside_tree():
		return
	var window_size = get_viewport().size
	Items_Ui.scale.x = float(window_size.x) / 1152
	Items_Ui.scale.y = float(window_size.y) / 648
	Items_Ui.position = Vector2()


func interact():
	update_Items_Ui()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Items_Ui.visible = true


func _on_area_3d_body_entered(body):
	if body is Player:
		body.new_interact(self)


func _on_area_3d_body_exited(body):
	if body is Player:
		body.lost_interact(self)
		stop_interact()


func stop_interact():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		Items_Ui.visible = false
