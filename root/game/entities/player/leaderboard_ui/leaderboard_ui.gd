extends Control

var _Score = load("res://root/game/entities/player/leaderboard_ui/score.tscn")

var disabled = false

func _enter_tree():
	if disabled:
		return
	var Players = get_node("../../../..")
	remove_child(get_child(1))
	var Scores = Control.new()
	add_child(Scores)
	Scores.name = "Control"
	Scores.position.y = 40
	
	for player in Players.get_children():
		var Score: Control = _Score.instantiate()
		Score.position.y = get_node("Control").get_child_count() * 40
		Score.name = player.name
		Score.Players = Players
		get_node("Control").add_child(Score)
		Score.update()
	# pseudo-code :
	"""
	pour chaque joueur de network:
		ajouter une scène de score en enfant
		la mettre où il faut (on descend de 40px à chaque fois)
		renommer la scène avec le nom du player
		update la scène
	"""

"""
func on_leaderboard_show():
	for score in get_children():
		if score.name != "Légende":
			score.update()
"""
