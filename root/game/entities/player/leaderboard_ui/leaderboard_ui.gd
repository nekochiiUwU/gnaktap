extends Control

var Game


func _ready():
	Game = get_node("../../../..") #enfant de player ? à voir
	#pseudo-code :
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
