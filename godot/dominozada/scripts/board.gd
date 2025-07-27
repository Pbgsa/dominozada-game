extends Node2D

@onready var left_head := $Heads/LeftHead
@onready var right_head := $Heads/RightHead
@onready var player_hand: HBoxContainer = $CanvasLayer/PlayerHand
@onready var played_pieces := $PlayedPieces
@onready var table_background := $TableBackground

@export var domino_piece_scene: PackedScene = preload("res://scenes/domino_piece.tscn")

var left_value: int = -1  # Left end value of the domino sequence
var right_value: int = -1  # Right end value of the domino sequence
var pieces_sequence: Array[Dictionary] = []  # Sequence of pieces in format {a, b}
var visual_pieces: Array[Node2D] = []  # Corresponding visual pieces
var piece_spacing := Vector2(30, 0)  # Base spacing for fallback
var board_center := Vector2.ZERO

var game_manager: Node  # Referência ao gerenciador do jogo

func _ready():
	player_hand.piece_played.connect(_on_piece_played)
	player_hand.passed_turn.connect(_on_passed_turn)
	
	# Set board center based on table background position
	board_center = table_background.position
	
	# Conectar com o GameManager se existir
	game_manager = get_node("/root/GameManager") if has_node("/root/GameManager") else null

func _on_piece_played(piece_data: Dictionary, placement_side: String):
	# For first piece, ignore placement_side
	if pieces_sequence.is_empty():
		add_piece_to_board_on_side(piece_data, "first")
		player_hand.remove_piece_from_hand(piece_data)
		return
	
	# Validate if the move is possible on the specified side
	if not is_valid_move_on_side(piece_data.a, piece_data.b, placement_side):
		player_hand.show_invalid_move_message(piece_data)
		return
	
	# Valid move - process it
	add_piece_to_board_on_side(piece_data, placement_side)
	player_hand.remove_piece_from_hand(piece_data)

func _on_passed_turn():
	pass  # Could add turn logic here if needed

func add_piece_to_board(data: Dictionary):
	var piece_a = data.a
	var piece_b = data.b
	
	# Check if it's the first piece
	if pieces_sequence.is_empty():
		# First piece - set initial ends and place at center
		pieces_sequence.append({"a": piece_a, "b": piece_b})
		left_value = piece_a
		right_value = piece_b
		
		# Reset head positions to center
		left_head.position = Vector2.ZERO
		right_head.position = Vector2.ZERO
		
		create_visual_piece_at_center()
	else:
		# Check where the piece can be connected
		var placed = false
		var side = ""
		
		# Try to connect on the left end
		if piece_a == left_value:
			pieces_sequence.push_front({"a": piece_b, "b": piece_a})
			left_value = piece_b
			placed = true
			side = "left"
		elif piece_b == left_value:
			pieces_sequence.push_front({"a": piece_a, "b": piece_b})
			left_value = piece_a
			placed = true
			side = "left"
		# Try to connect on the right end
		elif piece_a == right_value:
			pieces_sequence.append({"a": piece_a, "b": piece_b})
			right_value = piece_b
			placed = true
			side = "right"
		elif piece_b == right_value:
			pieces_sequence.append({"a": piece_b, "b": piece_a})
			right_value = piece_a
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
	played_pieces.add_child(piece)
	
	var sequence_piece = pieces_sequence[0]
	var piece_a = sequence_piece.a
	var piece_b = sequence_piece.b
	
	var direction = get_piece_orientation(piece_a, piece_b)
	
	piece.set_values(piece_a, piece_b)
	piece.set_direction(direction)
	piece.position = Vector2.ZERO
	
	visual_pieces.append(piece)

func create_visual_piece_at_side(side: String):
	"""Creates a visual piece on the specified side"""
	var piece = domino_piece_scene.instantiate()
	played_pieces.add_child(piece)
	
	var sequence_piece: Dictionary
	
	if side == "left":
		sequence_piece = pieces_sequence[0]
	else:  # side == "right"
		sequence_piece = pieces_sequence[pieces_sequence.size() - 1]
	
	var piece_a = sequence_piece.a
	var piece_b = sequence_piece.b
	var direction = get_piece_orientation(piece_a, piece_b)
	
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
	if piece_a > piece_b:
		return "left"
	elif piece_b > piece_a:
		return "right"
	else:  # piece_a == piece_b
		return "up"

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
			var current_orientation = get_piece_orientation(current_piece.a, current_piece.b)
			
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
			var current_orientation = get_piece_orientation(current_piece.a, current_piece.b)
			
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
	"""Updates the positions of left_head and right_head markers"""
	if visual_pieces.size() == 0:
		return
	
	var base_spacing = 2
	
	# Update left_head position (first visual piece)
	var leftmost_piece = visual_pieces[0]
	var leftmost_orientation = get_piece_orientation(pieces_sequence[0].a, pieces_sequence[0].b)
	var leftmost_width = get_piece_width(leftmost_orientation)
	var left_offset = (leftmost_width / 2.0) + base_spacing
	left_head.position = leftmost_piece.position - Vector2(left_offset, 0)
	
	# Update right_head position (last visual piece)
	var rightmost_piece = visual_pieces[visual_pieces.size() - 1]
	var rightmost_index = pieces_sequence.size() - 1
	var rightmost_orientation = get_piece_orientation(pieces_sequence[rightmost_index].a, pieces_sequence[rightmost_index].b)
	var rightmost_width = get_piece_width(rightmost_orientation)
	var right_offset = (rightmost_width / 2.0) + base_spacing
	right_head.position = rightmost_piece.position + Vector2(right_offset, 0)

func calculate_dynamic_spacing() -> Vector2:
	"""Calculates intelligent spacing based on piece orientations and sizes"""
	# Piece dimensions based on orientation
	# up/down: y:44, x:22
	# left/right: y:24, x:42
	
	var base_spacing = 2  # 2 pixels spacing between pieces
	
	# For horizontal pieces (left/right), use width + spacing
	var horizontal_spacing = 42 + base_spacing  # 44 pixels total
	
	# For vertical pieces (up/down), use width + spacing  
	var vertical_spacing = 22 + base_spacing    # 24 pixels total
	
	# Return horizontal spacing (pieces are arranged in horizontal line)
	return Vector2(horizontal_spacing, vertical_spacing)

func clear_board():
	"""Remove all pieces from the board"""
	for piece_node in visual_pieces:
		if piece_node and is_instance_valid(piece_node):
			piece_node.queue_free()
	
	visual_pieces.clear()
	pieces_sequence.clear()
	left_value = -1
	right_value = -1
	
	# Reset marker positions
	left_head.position = Vector2.ZERO
	right_head.position = Vector2.ZERO

func get_board_piece_count() -> int:
	"""Returns the number of pieces on the board"""
	return pieces_sequence.size()

func is_valid_move(piece_a: int, piece_b: int) -> bool:
	"""Checks if a move is valid"""
	if pieces_sequence.is_empty():
		return true  # First piece is always valid
	
	# Check if piece can connect to any end
	return (piece_a == left_value or piece_b == left_value or 
			piece_a == right_value or piece_b == right_value)

func is_valid_move_on_side(piece_a: int, piece_b: int, placement_side: String) -> bool:
	"""Checks if a move is valid on a specific side"""
	if pieces_sequence.is_empty():
		return true  # First piece is always valid
	
	match placement_side:
		"left":
			return piece_a == left_value or piece_b == left_value
		"right":
			return piece_a == right_value or piece_b == right_value
		_:
			return false

func add_piece_to_board_on_side(data: Dictionary, placement_side: String):
	"""Add piece to board on specified side"""
	var piece_a = data.a
	var piece_b = data.b
	
	# Check if it's the first piece
	if pieces_sequence.is_empty() or placement_side == "first":
		# First piece - set initial ends and place at center
		pieces_sequence.append({"a": piece_a, "b": piece_b})
		left_value = piece_a
		right_value = piece_b
		
		# Reset head positions to center
		left_head.position = Vector2.ZERO
		right_head.position = Vector2.ZERO
		
		create_visual_piece_at_center()
		return
	
	print("DEEBBUUGG: [%d,%d] no lado %s" % [piece_a, piece_b, placement_side])
	# Place piece on specified side
	match placement_side:
		"left":
			if piece_a == left_value:
				pieces_sequence.push_front({"a": piece_b, "b": piece_a})
				left_value = piece_b
			elif piece_b == left_value:
				pieces_sequence.push_front({"a": piece_a, "b": piece_b})
				left_value = piece_a
			else: #GATO COM LEBRE
				#falta poder escolher que lado jogar
				pieces_sequence.push_front({"a": piece_a, "b": piece_b})
			create_visual_piece_at_side("left")
			
		"right":
			if piece_a == right_value:
				pieces_sequence.append({"a": piece_a, "b": piece_b})
				right_value = piece_b
			elif piece_b == right_value:
				pieces_sequence.append({"a": piece_b, "b": piece_a})
				right_value = piece_a
			else: #GATO COM LEBRE
				#falta poder escolher que lado jogar
				pieces_sequence.append({"a": piece_a, "b": piece_b})
			create_visual_piece_at_side("right")
	
	update_head_positions()

func get_connection_info(piece_a: int, piece_b: int) -> Dictionary:
	"""Returns information about where the piece can be connected"""
	var info = {"can_connect": false, "side": "", "connection_value": -1}
	
	if pieces_sequence.is_empty():
		info.can_connect = true
		info.side = "first"
		return info
	
	# Check connection on left end
	if piece_a == left_value:
		info.can_connect = true
		info.side = "left"
		info.connection_value = piece_a
		return info
	elif piece_b == left_value:
		info.can_connect = true
		info.side = "left"
		info.connection_value = piece_b
		return info
	
	# Check connection on right end
	if piece_a == right_value:
		info.can_connect = true
		info.side = "right"
		info.connection_value = piece_a
		return info
	elif piece_b == right_value:
		info.can_connect = true
		info.side = "right"
		info.connection_value = piece_b
		return info

	if game_manager.current_mode == game_manager.GameMode.GATO_COM_LEBRE:
		info.can_connect = true
		return info
	
	return info

func can_place_piece(piece: Dictionary, side: String) -> bool:
	"""Verifica se uma peça pode ser colocada em um lado específico"""
	if pieces_sequence.is_empty():
		return true  # Primeira peça sempre pode
	
	match side:
		"left":
			return piece.a == left_value or piece.b == left_value
		"right":
			return piece.a == right_value or piece.b == right_value
		_:
			return false

func place_piece(piece: Dictionary, side: String):
	"""Coloca uma peça no tabuleiro (usado pelo GameManager)"""
	if pieces_sequence.is_empty():
		add_piece_to_board_on_side(piece, "first")
	else:
		add_piece_to_board_on_side(piece, side)

func get_left_value() -> int:
	"""Retorna o valor da extremidade esquerda"""
	return left_value

func get_right_value() -> int:
	"""Retorna o valor da extremidade direita"""
	return right_value

func is_empty() -> bool:
	"""Verifica se o tabuleiro está vazio"""
	return pieces_sequence.is_empty()
