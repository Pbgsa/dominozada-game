# scripts/board.gd
extends Node2D

@onready var played_pieces_container := $PlayedPieces
@onready var offline_game_manager = $GameManager
@export var domino_piece_scene: PackedScene = preload("res://scenes/domino_piece.tscn")

var visual_pieces: Array = []
var left_head_pos := Vector2.ZERO
var right_head_pos := Vector2.ZERO

func _ready():
	var game_manager
	if NetworkManager.is_online_mode:
		game_manager = GameManagerMultiplayer
		game_manager.server_player_is_ready.rpc()
	else:
		game_manager = offline_game_manager

	game_manager.game_started.connect(clear_board)
	game_manager.piece_played_on_board.connect(_on_piece_played_on_board)

func _on_piece_played_on_board(piece_data: Dictionary, side: String, _player_id: int):
	var new_piece_node = domino_piece_scene.instantiate()
	played_pieces_container.add_child(new_piece_node)
	new_piece_node.set_values(piece_data.a, piece_data.b)

	var is_double = piece_data.a == piece_data.b
	var rotation_needed = PI / 2 if is_double else 0

	if visual_pieces.is_empty():
		# Primeira peça
		new_piece_node.position = Vector2.ZERO
		new_piece_node.rotation = rotation_needed
		var piece_width = 40.0 if not is_double else 20.0
		left_head_pos = Vector2(-piece_width / 2, 0)
		right_head_pos = Vector2(piece_width / 2, 0)
		visual_pieces.append(new_piece_node)
	else:
		var head_pos = right_head_pos if side == "right" else left_head_pos
		var offset = 40.0 if not is_double else 30.0 # Ajuste para duplas ficarem alinhadas
		var direction_vector = Vector2.RIGHT if side == "right" else Vector2.LEFT
		var connecting_value = (GameManagerMultiplayer if NetworkManager.is_online_mode else offline_game_manager).board_left_value if side == "left" else (GameManagerMultiplayer if NetworkManager.is_online_mode else offline_game_manager).board_right_value

		if not is_double:
			if piece_data.a != connecting_value:
				new_piece_node.set_values(piece_data.b, piece_data.a) # Garante que o lado conector esteja correto

		new_piece_node.rotation = rotation_needed
		new_piece_node.position = head_pos + (direction_vector * offset * 0.5) # Ajuste no offset

		if side == "right":
			right_head_pos = new_piece_node.position + (direction_vector * (40.0 if not is_double else 20.0))
			visual_pieces.append(new_piece_node)
		else:
			left_head_pos = new_piece_node.position + (direction_vector * (40.0 if not is_double else 20.0))
			visual_pieces.push_front(new_piece_node)

func clear_board():
	for piece_node in visual_pieces:
		if is_instance_valid(piece_node):
			piece_node.queue_free()
	visual_pieces.clear()
	left_head_pos = Vector2.ZERO
	right_head_pos = Vector2.ZERO
