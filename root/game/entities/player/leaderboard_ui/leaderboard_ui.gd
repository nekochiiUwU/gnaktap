extends Control

var _Score = load("res://root/game/entities/player/leaderboard_ui/score.tscn")

var disabled = false

var Game

func _enter_tree():
	if disabled:
		get_node("Légende/Timer").visible = false
	Game = get_node("../../../../../..")
	var Players = get_node("../../../..")
	if Players:
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

func _process(_delta):
	if !disabled and is_inside_tree():
		get_node("Légende/Timer/RichTextLabel").text = "[center]"
		get_node("Légende/Timer/RichTextLabel").text += str(int((Game.match_duration - Game.time) / 60)) + ":"
		get_node("Légende/Timer/RichTextLabel").text += str(int(Game.match_duration - Game.time) % 60)
		_enter_tree()
