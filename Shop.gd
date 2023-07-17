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
	
	inventory = Game.stats_items
	calibrate_ui()
	get_viewport().size_changed.connect(calibrate_ui)
	var disp_items = inventory.keys()
	for i in disp_items:
		item_list.add_item(i)
	item_list.connect("item_selected", select)
	Items_Ui.get_node("Selected/Button").connect("pressed", buy_item)
	if item_list.item_count:
		item_list.deselect_all()
		item_list.select(0)

func select(selected_item):
	var s = Items_Ui.get_node("Selected")
	s.get_node("Name").text = item_list.get_item_text(selected_item)
	var stats:String
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


func update_Items_Ui():
	Items_Ui.get_node("Points").text = "Points : " + str(get_node("/root/Game").local_player.target_score)
	pass
	"""
	var stat_buttons = Items_Ui.get_children()
	Items_Ui.get_node("Points").text = "Points : " + str(get_node("/root/Game").local_player.target_score)
	for button in stat_buttons:
		if button.name == "Points" or button.name == "Bg":
			continue
		button.get_node("Availablity").text = "Available :" + str(inventory["points"][button.name])
		button.text = button.name + "\n" + str(get_node("/root/Game").local_player.inventory["points"][button.name])
	"""


func buy_item():
	var s = Items_Ui.get_node("Selected")
	var item = s.get_node("Name").text
	if item in item_list.get_item_text(item_list.get_selected_items()[0]) and \
			!Game.local_player.inventory["items"].has(item) and \
			Game.stats_items[item][2] <= Game.local_player.target_score:
		Game.local_player.target_score -= Game.stats_items[item][2]
		Game.local_player.inventory["items"].append(item)
		item_list.remove_item(item_list.get_selected_items()[0])
		Game.local_player.update_stats()
		if item_list.item_count:
			item_list.select(0)
		else:
			item_list.deselect_all()
			s.visible = false
	pass
	"""
	if inventory["points"][str(stat)] <= 0 or get_node("/root/Game/").local_player.target_score <= 0:
		return
	inventory["points"][str(stat)] -= 1
	for key in inventory["points"].keys():
		if key != str(stat):
			get_node("/root/Game").local_player.inventory["points"][str(key)] -= 1./8
		else:
			get_node("/root/Game").local_player.inventory["points"][str(key)] += 1
	get_node("/root/Game").local_player.update_stats()
	get_node("/root/Game").local_player.target_score -= 1
	update_Items_Ui()
	"""


func calibrate_ui():
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
