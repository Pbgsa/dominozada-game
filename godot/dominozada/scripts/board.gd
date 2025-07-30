# scripts/board.gd
extends Node2D

@onready var played_pieces_container := $PlayedPieces
@onready var offline_game_manager = $GameManager
@export var domino_piece_scene: PackedScene = preload("res://scenes/domino_piece.tscn")

var visual_pieces: Array[Node2D] = []
var left_head_pos := Vector2.ZERO
var right_head_pos := Vector2.ZERO

# --- ADIÇÃO: Variáveis para controlar a lógica visual do tabuleiro ---
var board_left_value := -1
var board_right_value := -1
var board_is_empty := true
var pieces_sequence: Array[Dictionary] = []
# --------------------------------------------------------------------

func _ready():
	var game_manager
	if NetworkManager.is_online_mode:
		game_manager = GameManagerMultiplayer
		game_manager.server_player_is_ready.rpc()
	else:
		game_manager = offline_game_manager

	game_manager.game_started.connect(clear_board)
	game_manager.piece_played_on_board.connect(_on_piece_played_on_board)

# --- CORREÇÃO: Função de posicionamento de peças reescrita ---
func _on_piece_played_on_board(piece_data: Dictionary, side: String, _player_id: int):
	add_piece_to_board(piece_data)

func add_piece_to_board(data: Dictionary):
	var piece_a = data.a
	var piece_b = data.b
	
	# Check if it's the first piece
	if pieces_sequence.is_empty():
		# First piece - set initial ends and place at center
		pieces_sequence.append({"a": piece_a, "b": piece_b})
		board_left_value = piece_a
		board_right_value = piece_b
		board_is_empty = false
		
		# Reset head positions to center
		left_head_pos = Vector2.ZERO
		right_head_pos = Vector2.ZERO
		
		create_visual_piece_at_center()
	else:
		# Check where the piece can be connected
		var placed = false
		var side = ""
		
		# Try to connect on the left end
		if piece_a == board_left_value:
			pieces_sequence.push_front({"a": piece_b, "b": piece_a})
			board_left_value = piece_b
			placed = true
			side = "left"
		elif piece_b == board_left_value:
			pieces_sequence.push_front({"a": piece_a, "b": piece_b})
			board_left_value = piece_a
			placed = true
			side = "left"
		# Try to connect on the right end
		elif piece_a == board_right_value:
			pieces_sequence.append({"a": piece_a, "b": piece_b})
			board_right_value = piece_b
			placed = true
			side = "right"
		elif piece_b == board_right_value:
			pieces_sequence.append({"a": piece_b, "b": piece_a})
			board_right_value = piece_a
			placed = true
			side = "right"
		
		if not placed:
			# This should never happen if validation is working correctly
			return
			
		create_visual_piece_at_side(side)
		update_head_positions()

func create_visual_piece_at_center():
	"""Creates the first visual piece at the center of the board"""
	var piece = domino_piece_scene.instantiate()
	played_pieces_container.add_child(piece)
	
	var sequence_piece = pieces_sequence[0]
	var piece_a = sequence_piece.a
	var piece_b = sequence_piece.b
	
	var direction = get_piece_orientation(piece_a, piece_b)
	# Para a primeira peça, se não for double, usa "right" como padrão
	if piece_a != piece_b:
		direction = "right"
	
	piece.set_values(piece_a, piece_b)
	piece.set_direction(direction)
	piece.position = Vector2.ZERO
	
	visual_pieces.append(piece)

func create_visual_piece_at_side(side: String):
	"""Creates a visual piece on the specified side"""
	var piece = domino_piece_scene.instantiate()
	played_pieces_container.add_child(piece)
	
	var sequence_piece: Dictionary
	
	if side == "left":
		sequence_piece = pieces_sequence[0]
	else:  # side == "right"
		sequence_piece = pieces_sequence[pieces_sequence.size() - 1]
	
	var piece_a = sequence_piece.a
	var piece_b = sequence_piece.b
	var direction = get_piece_orientation_for_side(piece_a, piece_b, side)
	
	piece.set_values(piece_a, piece_b)
	piece.set_direction(direction)
	
	var piece_position = calculate_piece_position_by_side(side)
	piece.position = piece_position
	
	if side == "left":
		visual_pieces.push_front(piece)
	else:
		visual_pieces.append(piece)

func get_piece_orientation(piece_a: int, piece_b: int) -> String:
	"""Determines piece orientation based on values a and b"""
	if piece_a == piece_b:
		return "up"
	elif piece_a > piece_b:
		return "left"
	else:  # piece_b > piece_a
		return "right"

func get_piece_orientation_for_side(piece_a: int, piece_b: int, side: String) -> String:
	"""Determines piece orientation based on values a and b and the side it's being placed"""
	if piece_a == piece_b:
		return "up"
	else:
		if side == "left":
			return "left" if piece_a > piece_b else "right"
		else: # side == "right"
			return "left" if piece_a > piece_b else "right"

func get_piece_width(orientation: String) -> int:
	"""Returns piece width based on orientation"""
	match orientation:
		"up", "down":
			return 22  # Vertical pieces width
		"left", "right":
			return 42  # Horizontal pieces width
		_:
			return 42  # Default width

func calculate_piece_position_by_side(side: String) -> Vector2:
	"""Calculates new piece position based on side with intelligent spacing"""
	var base_spacing = 2  # 2 pixels spacing between pieces
	
	if side == "left":
		if visual_pieces.size() > 0:
			var leftmost_piece = visual_pieces[0]
			var leftmost_position = leftmost_piece.position
			
			# Get orientation of current piece (to be added)
			var current_piece = pieces_sequence[0]
			var current_orientation = get_piece_orientation_for_side(current_piece.a, current_piece.b, side)
			
			# Get orientation of adjacent piece
			var adjacent_orientation = "right"  # default
			if pieces_sequence.size() > 1:
				var adjacent_piece = pieces_sequence[1]
				adjacent_orientation = get_piece_orientation(adjacent_piece.a, adjacent_piece.b)
			
			# Calculate spacing based on orientations
			var current_width = get_piece_width(current_orientation)
			var adjacent_width = get_piece_width(adjacent_orientation)
			var total_spacing = (current_width / 2.0) + (adjacent_width / 2.0) + base_spacing
			
			return leftmost_position - Vector2(total_spacing, 0)
		else:
			return Vector2.ZERO
			
	else:  # side == "right"
		if visual_pieces.size() > 0:
			var rightmost_piece = visual_pieces[visual_pieces.size() - 1]
			var rightmost_position = rightmost_piece.position
			
			# Get orientation of current piece (to be added)
			var current_piece = pieces_sequence[pieces_sequence.size() - 1]
			var current_orientation = get_piece_orientation_for_side(current_piece.a, current_piece.b, side)
			
			# Get orientation of adjacent piece
			var adjacent_orientation = "right"  # default
			if pieces_sequence.size() > 1:
				var adjacent_piece = pieces_sequence[pieces_sequence.size() - 2]
				adjacent_orientation = get_piece_orientation(adjacent_piece.a, adjacent_piece.b)
			
			# Calculate spacing based on orientations
			var current_width = get_piece_width(current_orientation)
			var adjacent_width = get_piece_width(adjacent_orientation)
			var total_spacing = (current_width / 2.0) + (adjacent_width / 2.0) + base_spacing
			
			return rightmost_position + Vector2(total_spacing, 0)
		else:
			return Vector2.ZERO

func update_head_positions():
	"""Updates the positions of the left and right heads after placing a piece"""
	if visual_pieces.is_empty():
		left_head_pos = Vector2.ZERO
		right_head_pos = Vector2.ZERO
		return
	
	# Get leftmost piece
	var leftmost_piece = visual_pieces[0]
	var leftmost_sequence = pieces_sequence[0]
	var leftmost_orientation = get_piece_orientation_for_side(leftmost_sequence.a, leftmost_sequence.b, "left")
	var leftmost_width = get_piece_width(leftmost_orientation)
	left_head_pos = leftmost_piece.position - Vector2(leftmost_width / 2.0, 0)
	
	# Get rightmost piece
	var rightmost_piece = visual_pieces[visual_pieces.size() - 1]
	var rightmost_sequence = pieces_sequence[pieces_sequence.size() - 1]
	var rightmost_orientation = get_piece_orientation_for_side(rightmost_sequence.a, rightmost_sequence.b, "right")
	var rightmost_width = get_piece_width(rightmost_orientation)
	right_head_pos = rightmost_piece.position + Vector2(rightmost_width / 2.0, 0)

# --- CORREÇÃO: Limpa também as variáveis de estado lógico ---
func clear_board():
	for piece_node in visual_pieces:
		if is_instance_valid(piece_node):
			piece_node.queue_free()
	visual_pieces.clear()
	pieces_sequence.clear()
	left_head_pos = Vector2.ZERO
	right_head_pos = Vector2.ZERO
	
	# Reseta o estado lógico do tabuleiro visual
	board_left_value = -1
	board_right_value = -1
	board_is_empty = true
