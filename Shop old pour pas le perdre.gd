
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
	calibrate_ui()
	get_viewport().size_changed.connect(calibrate_ui)
	Upgrade_Ui.visible = false
	var stat_buttons = Upgrade_Ui.get_children()
	var stats = inventory["points"].keys()
	for i in range(0, len(stat_buttons)-2):
		var button = stat_buttons[i]
		button.name = stats[i]
		button.text = button.name + "\n" + str(inventory["points"][button.name])
		button.pressed.connect(buy_stat.bind(button.name))


func update_upgrade_ui():
	var stat_buttons = Upgrade_Ui.get_children()
	Upgrade_Ui.get_node("Points").text = "Points : " + str(get_node("/root/Game").local_player.target_score)
	for button in stat_buttons:
		if button.name == "Points" or button.name == "Bg":
			continue
		button.get_node("Availablity").text = "Available :" + str(inventory["points"][button.name])
		button.text = button.name + "\n" + str(get_node("/root/Game").local_player.inventory["points"][button.name])


func buy_stat(stat):
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
	update_upgrade_ui()


func calibrate_ui():
	var window_size = get_viewport().size
	Upgrade_Ui.scale.x = float(window_size.x) / 1152
	Upgrade_Ui.scale.y = float(window_size.y) / 648
	Upgrade_Ui.position = Vector2()


func interact():
	update_upgrade_ui()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Upgrade_Ui.visible = true


func _on_area_3d_body_entered(body):
	if body is Player:
		body.new_interact(self)


func _on_area_3d_body_exited(body):
	if body is Player:
		body.lost_interact(self)
		stop_interact()


func stop_interact():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		Upgrade_Ui.visible = false