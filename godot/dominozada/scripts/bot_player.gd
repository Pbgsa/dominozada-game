extends "res://scripts/player.gd"
# Evitando class_name para compatibilidade

enum BotDifficulty {
	EASY,
	MEDIUM,
	HARD
}

var difficulty: BotDifficulty = BotDifficulty.EASY

func decide_move(board: Node) -> Dictionary:
	"""Decide qual jogada fazer"""
	var playable_pieces = get_playable_pieces(board)
	
	if playable_pieces.is_empty():
		return {}  # Sem jogadas possíveis - vai passar a vez
	
	match difficulty:
		BotDifficulty.EASY:
			return decide_easy_move(board, playable_pieces)
		BotDifficulty.MEDIUM:
			return decide_medium_move(board, playable_pieces)
		BotDifficulty.HARD:
			return decide_hard_move(board, playable_pieces)
		_:
			return decide_easy_move(board, playable_pieces)

func decide_easy_move(board: Node, playable_pieces: Array[Dictionary]) -> Dictionary:
	"""Estratégia simples: joga a primeira peça possível"""
	var piece = playable_pieces[0]
	var side = get_preferred_side(board, piece)
	
	return {"piece": piece, "side": side}

func decide_medium_move(board: Node, playable_pieces: Array[Dictionary]) -> Dictionary:
	"""Estratégia média: prioriza peças com maior pontuação"""
	var best_piece = playable_pieces[0]
	var best_points = best_piece.a + best_piece.b
	
	for piece in playable_pieces:
		var points = piece.a + piece.b
		if points > best_points:
			best_points = points
			best_piece = piece
	
	var side = get_preferred_side(board, best_piece)
	return {"piece": best_piece, "side": side}

func decide_hard_move(board: Node, playable_pieces: Array[Dictionary]) -> Dictionary:
	"""Estratégia avançada: considera bloqueio e controle"""
	# Por agora, usa a estratégia média
	# Pode ser expandida com lógica mais complexa
	return decide_medium_move(board, playable_pieces)

func get_preferred_side(board: Node, piece: Dictionary) -> String:
	"""Decide qual lado é preferível para jogar a peça"""
	if not board:
		return "left"  # Primeira peça, tanto faz
	
	var can_left = board.can_place_piece(piece, "left")
	var can_right = board.can_place_piece(piece, "right")
	
	if can_left and can_right:
		# Se pode jogar dos dois lados, escolhe aleatoriamente
		return "left" if randf() < 0.5 else "right"
	elif can_left:
		return "left"
	elif can_right:
		return "right"
	else:
		return "left"  # Fallback

func set_difficulty(new_difficulty: BotDifficulty):
	"""Define dificuldade do bot"""
	difficulty = new_difficulty
