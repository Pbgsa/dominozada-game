extends "res://scripts/player.gd"
# Evitando class_name para compatibilidade

enum BotDifficulty {
	EASY,
	MEDIUM,
	HARD
}

var difficulty: BotDifficulty = BotDifficulty.EASY

func decide_move(board: Node, last_invalid_move: Dictionary, is_gato_com_lebre: bool) -> Dictionary:
	"""Decide qual jogada fazer"""
	var playable_pieces = get_playable_pieces(board)

	if last_invalid_move.has("piece"):
		# chama uma função para denunciar a jogada inválida
		if try_to_report_invalid_move(board, last_invalid_move):
			print("Jogada inválida denunciada com sucesso!")
			# aqui vai ter de adicionar uma punição ao jogador (ou bot) anterior
			board.remove_piece(last_invalid_move)
		else:
			print("A jogada inválida passou despercebida.")

	if playable_pieces.is_empty() and not is_gato_com_lebre:
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
	# se chegou até aqui, significa que pode tentar gato com lebre
	if playable_pieces.is_empty() and randf() < 1: # (100% pra debug) 25% chance de passar a vez
		var pieces_in_hand = get_hand_pieces()
		var side = "left" if randf() < 0.5 else "right"
		if pieces_in_hand.is_empty():
			return {}  # Sem peças na mão, não pode jogar
		else:
			return {"piece": pieces_in_hand[0], "side": side}


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

func try_to_report_invalid_move(board: Node, last_invalid_move: Dictionary) -> bool:
	"""Tenta denunciar uma jogada inválida"""

	match difficulty:
		BotDifficulty.EASY:
			if randf() < 1:  # (100% pra debug) 20% chance de denunciar
				return true
			else:
				return false
		BotDifficulty.MEDIUM:
			if randf() < 0.45:  # 45% chance de denunciar
				return true
			else:
				return false
		BotDifficulty.HARD:
			if randf() < 0.7:  # 70% chance de denunciar
				return true
			else:
				return false
		_:
			if randf() < 0.2:  # 20% chance de denunciar
				return true
			else:
				return false
