class_name Shop
extends StaticBody3D

@onready var Upgrade_Ui = get_node("Upgrade Ui")

var inventory = {
	"points": {
		"damages": 30,
		"speed": 30,
		"fire_rate": 30,
		"accuracy": 30,
		"recoil": 30,
		"max_ammo": 30,
		"reload_speed": 30,
		"bullet_speed": 30
	}
}


func _ready():
	Upgrade_Ui.visible = false
	var stat_buttons = Upgrade_Ui.get_children()
	var stats = inventory["points"].keys()
	for i in range(len(stat_buttons)):
		var button = stat_buttons[i]
		button.name = stats[i]
		button.text = button.name + "\n" + str(inventory["points"][button.name])
		button.pressed.connect(buy_stat.bind(button.name))


func update_upgrade_ui():
	var stat_buttons = Upgrade_Ui.get_children()
	for button in stat_buttons:
		button.text = button.name + "\n" + str(inventory["points"][button.name])


func buy_stat(stat):
	inventory["points"][str(stat)] -= 1
	update_upgrade_ui()
	get_node("/root/Game/Entities/Players/"+str(multiplayer.get_unique_id())).inventory["points"][str(stat)] += 1


func interact():
	update_upgrade_ui()
	Upgrade_Ui.visible = true


func _on_area_3d_body_entered(body):
	if body is Player:
		body.new_interact(self)


func _on_area_3d_body_exited(body):
	if body is Player:
		body.lost_interact(self)
	Upgrade_Ui.visible = false
