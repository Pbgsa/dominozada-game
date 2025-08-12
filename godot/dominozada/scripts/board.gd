# scripts/board.gd
extends Control

@onready var played_pieces_container := $GameArea/PlayedPieces
#@onready var offline_game_manager = $GameManager
@export var domino_piece_scene: PackedScene = preload("res://scenes/domino_piece.tscn")

var visual_pieces: Array[Node2D] = []
var left_head_pos := Vector2.ZERO
var right_head_pos := Vector2.ZERO

# --- FONTE ÚNICA DA VERDADE: Variáveis para controlar a lógica do tabuleiro ---
var board_left_value := -1
var board_right_value := -1
var up_left_increment := 0
var down_right_increment := 0
var board_is_empty := true
var pieces_sequence: Array[Dictionary] = []
var game_manager

# Sinal para notificar mudanças no estado do board
signal board_state_changed(left_value: int, right_value: int, is_empty: bool)
# --------------------------------------------------------------------

func _ready():
	print("BOARD: Iniciando board.gd")
	print("BOARD: NetworkManager.is_online_mode = ", NetworkManager.is_online_mode)
	
	# Primeiro, o board se registra no GameManager
	GameManager.register_board(self)
	print("BOARD: Board registrado no GameManager")

	if NetworkManager.is_online_mode:
		print("BOARD: Usando GameManagerMultiplayer")
		game_manager = GameManagerMultiplayer
		game_manager.server_player_is_ready.rpc()
	else:
		print("BOARD: Usando GameManager offline")
		# Agora que o board já se registrou, podemos continuar com segurança
		game_manager = GameManager
		
	# Conecta os sinais como antes
	print("BOARD: Conectando sinais")
	game_manager.game_started.connect(clear_board)
	game_manager.piece_played_on_board.connect(_on_piece_played_on_board)
	game_manager.remove_piece_from_board.connect(_on_piece_removed_from_board)
	
	# Inicia o jogo apenas no modo offline, após conectar os sinais
	# Usar call_deferred para garantir que tudo esteja inicializado
	if not NetworkManager.is_online_mode:
		print("BOARD: Agendando início do jogo offline")
		call_deferred("start_offline_game")

func start_offline_game():
	"""Inicia o jogo offline após garantir que tudo está inicializado"""
	print("BOARD: Iniciando jogo offline")
	if GameManager and GameManager.has_method("start_new_game"):
		print("BOARD: Chamando GameManager.start_new_game()")
		GameManager.start_new_game()
	else:
		print("ERRO: GameManager não encontrado ou método start_new_game não disponível")

# --- CORREÇÃO: Função de posicionamento de peças reescrita ---
func _on_piece_played_on_board(piece_data: Dictionary, side: String, _player_id: int):
	add_piece_to_board(piece_data, side)

func _on_piece_removed_from_board(last_invalid_move: Dictionary):
	remove_piece(last_invalid_move)

func add_piece_to_board(data: Dictionary, requested_side: String = ""):
	var piece_a = data.a
	var piece_b = data.b
	
	# print("DEBUG: Adicionando peça [%d,%d] ao tabuleiro no lado: %s" % [piece_a, piece_b, requested_side])
	
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
		
		# Notificar mudança de estado
		board_state_changed.emit(board_left_value, board_right_value, board_is_empty)
	else:
		# Use o lado solicitado para colocar a peça
		var placed = false
		var actual_side = ""
		
		if requested_side == "left" or requested_side.is_empty():
			# Try to connect on the left end
			if piece_a == board_left_value:
				pieces_sequence.push_front({"a": piece_b, "b": piece_a})
				board_left_value = piece_b
				placed = true
				actual_side = "left"
				# print("DEBUG: Peça conectada na ESQUERDA (piece_a=%d == left_value). Nova esquerda: %d" % [piece_a, board_left_value])
			elif piece_b == board_left_value:
				pieces_sequence.push_front({"a": piece_a, "b": piece_b})
				board_left_value = piece_a
				placed = true
				actual_side = "left"
				# print("DEBUG: Peça conectada na ESQUERDA (piece_b=%d == left_value). Nova esquerda: %d" % [piece_b, board_left_value])
			elif game_manager.current_mode == GameManager.GameMode.GATO_COM_LEBRE:
				pieces_sequence.push_front({"a": piece_b, "b": piece_a})
				board_left_value = piece_b
				placed = true
				actual_side = "left"
		
		if not placed and (requested_side == "right" or requested_side.is_empty()):
			# Try to connect on the right end
			if piece_a == board_right_value:
				pieces_sequence.append({"a": piece_a, "b": piece_b})
				board_right_value = piece_b
				placed = true
				actual_side = "right"
				# print("DEBUG: Peça conectada na DIREITA (piece_a=%d == right_value). Nova direita: %d" % [piece_a, board_right_value])
			elif piece_b == board_right_value:
				pieces_sequence.append({"a": piece_b, "b": piece_a})
				board_right_value = piece_a
				placed = true
				actual_side = "right"
				# print("DEBUG: Peça conectada na DIREITA (piece_b=%d == right_value). Nova direita: %d" % [piece_b, board_right_value])
			elif game_manager.current_mode == GameManager.GameMode.GATO_COM_LEBRE:
				pieces_sequence.append({"a": piece_b, "b": piece_a})
				board_right_value = piece_b
				placed = true
				actual_side = "right"
		
		if not placed:
			# print("ERRO: Peça [%d,%d] não pôde ser conectada no lado '%s'! Esquerda: %d, Direita: %d" % [piece_a, piece_b, requested_side, board_left_value, board_right_value])
			return
			
		# print("DEBUG: Estado final - Esquerda: %d, Direita: %d, Lado usado: %s" % [board_left_value, board_right_value, actual_side])
		
		create_visual_piece_at_side(actual_side)
		update_head_positions()
		
		# Notificar mudança de estado
		board_state_changed.emit(board_left_value, board_right_value, board_is_empty)

# Funções públicas para consulta do estado (para os GameManagers)
func get_board_left_value() -> int:
	return board_left_value

func get_board_right_value() -> int:
	return board_right_value

func get_board_is_empty() -> bool:
	return board_is_empty

func can_place_piece(piece_data: Dictionary, side: String) -> bool:
	"""Verifica se uma peça pode ser colocada no lado especificado"""
	if board_is_empty:
		return true  # Primeira peça pode ser colocada em qualquer lado
	
	var target_value = board_left_value if side == "left" else board_right_value
	return piece_data.a == target_value or piece_data.b == target_value

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
	var result = calculate_piece_position_by_side(side)
	piece.set_values(piece_a, piece_b)
	piece.set_direction(result.direction)
	piece.position = result.position
	
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

func get_piece_orientation_for_side_vertical(piece_a: int, piece_b: int, side: String) -> String:
	"""Determines piece orientation based on values a and b and the side it's being placed"""
	if piece_a == piece_b:
		return "right"
	else:
		if side == "up":
			return "up" if piece_a > piece_b else "down"
		else: # side == "right"
			return "up" if piece_a > piece_b else "down"


func get_piece_width(orientation: String) -> int:
	"""Returns piece width based on orientation"""
	match orientation:
		"up", "down":
			return 22  # Vertical pieces width
		"left", "right":
			return 42  # Horizontal pieces width
		_:
			return 42  # Default width

func calculate_piece_position_by_side(side: String) -> Dictionary:
	"""Calculates new piece position based on side with intelligent spacing"""
	var result = {
		"position": Vector2.ZERO,
		"direction": "up"
	}
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
				if up_left_increment == 1 and adjacent_piece.a == adjacent_piece.b:
					adjacent_orientation = "up"
				elif up_left_increment == 3 and adjacent_piece.a == adjacent_piece.b:
					adjacent_orientation = "right"
				else:
					adjacent_orientation = get_piece_orientation(adjacent_piece.a, adjacent_piece.b)
				if (leftmost_position.x < -180 and up_left_increment == 0) or up_left_increment == 2:
					adjacent_orientation = get_piece_orientation_for_side_vertical(adjacent_piece.a, adjacent_piece.b, side)
					if up_left_increment == 2 and (adjacent_orientation == "up" or adjacent_orientation == "down"):
						current_orientation = get_piece_orientation_for_side(current_piece.b, current_piece.a, side)
						if current_piece.a == current_piece.b:
							current_orientation = "right"

			if (adjacent_orientation == "up" or adjacent_orientation == "down") and up_left_increment == 0:
				if current_piece.a == current_piece.b:
					current_orientation = "up"
			
			# Calculate spacing based on orientations
			var current_width = get_piece_width(current_orientation)
			var adjacent_width = get_piece_width(adjacent_orientation)
			var total_spacing = (current_width / 2.0) + (adjacent_width / 2.0) + base_spacing

			if leftmost_position.x < -180 and up_left_increment < 2:
				# The piece now goes up to avoid off screen setting
				current_orientation = get_piece_orientation_for_side_vertical(current_piece.a, current_piece.b, side)
				if (adjacent_orientation == "up" or adjacent_orientation == "down") and up_left_increment == 0:
					result.position = leftmost_position - Vector2((adjacent_width / 2.0) - 1, total_spacing + 2)
					if current_piece.a == current_piece.b:
						current_orientation = "up"
						result.position = leftmost_position - Vector2((adjacent_width / 2.0), total_spacing + (adjacent_width / 2.0))
				elif (current_orientation == "up" or current_orientation == "down") and (adjacent_orientation == "up" or adjacent_orientation == "down") and up_left_increment == 1:
					result.position = leftmost_position - Vector2(0, total_spacing + (adjacent_width / 2.0))
					# Debug: Special case handling
				else:
					result.position = leftmost_position - Vector2(0, total_spacing)
				result.direction = current_orientation
				up_left_increment += 1
				# print("DEBUG: Piece a: %d, Piece b: %d" % [current_piece.a, current_piece.b])
				# print("DEBUG: Leftmost position: %s, Current orientation: %s, Adjacent orientation: %s, and result: %s" % [leftmost_position, current_orientation, adjacent_orientation, result])
				return result

			if up_left_increment >= 2:
				current_orientation = get_piece_orientation_for_side(current_piece.b, current_piece.a, side)
				if up_left_increment == 2 and (adjacent_orientation == "up" or adjacent_orientation == "down"):
					result.position = leftmost_position + Vector2(total_spacing, (-(adjacent_width / 2.0)) + 1)
					if current_piece.a == current_piece.b:
						current_orientation = "right"
					# print("DEBUG: Up left increment 2, position: %s, current orientation: %s, adjacent orientation: %s" % [result.position, current_orientation, adjacent_orientation])
				else:
					result.position = leftmost_position + Vector2(total_spacing, 0)
				result.direction = current_orientation
				up_left_increment += 1
				return result
			
			result.position = leftmost_position - Vector2(total_spacing, 0)
			result.direction = current_orientation
			return result
		else:
			return result  # No pieces yet, return default position and direction

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
				if down_right_increment == 1 and adjacent_piece.a == adjacent_piece.b:
					adjacent_orientation = "up"
				elif down_right_increment == 3 and adjacent_piece.a == adjacent_piece.b:
					adjacent_orientation = "right"
				else:
					adjacent_orientation = get_piece_orientation(adjacent_piece.a, adjacent_piece.b)
				if (rightmost_position.x > 180 and down_right_increment == 0) or down_right_increment == 2:
					adjacent_orientation = get_piece_orientation_for_side_vertical(adjacent_piece.a, adjacent_piece.b, side)
					if down_right_increment == 2 and (adjacent_orientation == "up" or adjacent_orientation == "down"):
						current_orientation = get_piece_orientation_for_side(current_piece.b, current_piece.a, side)
						if current_piece.a == current_piece.b:
							current_orientation = "right"

			if (adjacent_orientation == "up" or adjacent_orientation == "down") and down_right_increment == 0:
				if current_piece.a == current_piece.b:
					current_orientation = "up"
			
			# Calculate spacing based on orientations
			var current_width = get_piece_width(current_orientation)
			var adjacent_width = get_piece_width(adjacent_orientation)
			var total_spacing = (current_width / 2.0) + (adjacent_width / 2.0) + base_spacing

			if rightmost_position.x > 180 and down_right_increment < 2:
				# The piece now goes down to avoid off screen setting
				current_orientation = get_piece_orientation_for_side_vertical(current_piece.a, current_piece.b, side)
				if (adjacent_orientation == "up" or adjacent_orientation == "down") and down_right_increment == 0:
					result.position = rightmost_position + Vector2((adjacent_width / 2.0) - 1, total_spacing + 2)
					if current_piece.a == current_piece.b:
						current_orientation = "up"
						result.position = rightmost_position + Vector2((adjacent_width / 2.0) - 1, total_spacing + (adjacent_width / 2.0))
				elif (current_orientation == "up" or current_orientation == "down") and (adjacent_orientation == "up" or adjacent_orientation == "down") and down_right_increment == 1:
					result.position = rightmost_position + Vector2(0, total_spacing + (adjacent_width / 2.0))
					# Debug: Special case handling
				else:
					result.position = rightmost_position + Vector2(0, total_spacing)
				result.direction = current_orientation
				down_right_increment += 1
				# Print piece a and b for debugging
				# print("DEBUG: Piece a: %d, Piece b: %d" % [current_piece.a, current_piece.b])
				# print("DEBUG: Rightmost position: %s, Current orientation: %s, Adjacent orientation: %s, and result: %s" % [rightmost_position, current_orientation, adjacent_orientation, result])
				return result

			if down_right_increment >= 2:
				current_orientation = get_piece_orientation_for_side(current_piece.b, current_piece.a, side)
				if down_right_increment == 2 and (adjacent_orientation == "up" or adjacent_orientation == "down"):
					result.position = rightmost_position - Vector2(total_spacing, (-(adjacent_width / 2.0)) + 1)
					if current_piece.a == current_piece.b:
						current_orientation = "right"
					# print("DEBUG: Down right increment 2, position: %s, current orientation: %s, adjacent orientation: %s" % [result.position, current_orientation, adjacent_orientation])
				else:
					result.position = rightmost_position - Vector2(total_spacing, 0)
				result.direction = current_orientation
				down_right_increment += 1
				return result

			result.position = rightmost_position + Vector2(total_spacing, 0)
			result.direction = current_orientation
			return result
		else:
			return result

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
	up_left_increment = 0
	down_right_increment = 0
	board_is_empty = true

func remove_piece(last_invalid_move: Dictionary): # { player_id, piece, side, round }
	"""Remove uma peça do tabuleiro (usado para jogadas inválidas)"""
	print("Tentando remover peça inválida do tabuleiro: ", last_invalid_move.piece)

	if pieces_sequence.is_empty():
		print("Erro: Não há peças no tabuleiro para remover.")
		return

	var invalid_piece_player_id = last_invalid_move["player_id"]
	var invalid_piece = last_invalid_move["piece"]
	var invalid_piece_side = last_invalid_move["side"]

	remove_piece_from_a_side(invalid_piece, invalid_piece_side, invalid_piece_player_id)

func remove_piece_from_a_side(piece: Dictionary, side: String, _player_id: int):
	"""Remove uma peça de um lado específico do tabuleiro"""

	if side == "left":
		var piece_L = pieces_sequence[0]
		if (piece_L.a == piece.a and piece_L.b == piece.b) or (piece_L.a == piece.b and piece_L.b == piece.a):
			played_pieces_container.remove_child(visual_pieces[0])
			pieces_sequence.pop_front()
			board_left_value = pieces_sequence[0].a
			remove_visual_at_side("left")
		else:
			print("Erro: Peça não encontrada no lado esquerdo.")

	elif side == "right":
		var piece_R = pieces_sequence[pieces_sequence.size()-1]
		if (piece_R.a == piece.a and piece_R.b == piece.b) or (piece_R.a == piece.b and piece_R.b == piece.a):
			played_pieces_container.remove_child(visual_pieces[visual_pieces.size() - 1])
			pieces_sequence.pop_back()
			board_right_value = pieces_sequence[pieces_sequence.size()-1].b
			remove_visual_at_side("right")
		else:
			print("Erro: Peça não encontrada no lado direito.")

	else:
		print("Erro: Lado inválido, deve ser 'left' ou 'right'")

	update_head_positions()

func remove_visual_at_side(side: String):
	"""Remove a peça visual do lado especificado"""
	if side == "left":
		var leftmost_piece = visual_pieces[0]
		var leftmost_position = leftmost_piece.position
		if leftmost_position.x < -180 and up_left_increment > 0:
			up_left_increment -= 1
		visual_pieces.pop_front()
	else:
		var rightmost_piece = visual_pieces[visual_pieces.size() - 1]
		var rightmost_position = rightmost_piece.position
		if rightmost_position.x > 180 and down_right_increment > 0:
			down_right_increment -= 1
		visual_pieces.pop_back()
