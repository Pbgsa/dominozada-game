extends Control

@export var piece_scene: PackedScene
@onready var game_logic = get_node("/root/GameLogic")

var hand: Array = []
var can_play: bool = false
var points: int = 0
var id: int = 0

func play_piece(piece):
	if can_play:
		if game_logic.check_logic_validity(piece):
			game_logic.update_heads(piece)
			hand.erase(piece)
			print("%s jogou peça %s" % [name, piece.code])
			can_play = false
		else:
			print("Jogada inválida para %s." % name)
