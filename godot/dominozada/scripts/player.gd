extends RefCounted
# Evitando class_name para compatibilidade

var player_id: int
var player_name: String
var hand_pieces: Array[Dictionary] = []

func add_piece_to_hand(piece: Dictionary):
	"""Adiciona uma peça à mão"""
	hand_pieces.append(piece)

func remove_piece_from_hand(piece: Dictionary) -> bool:
	"""Remove uma peça da mão"""
	for i in range(hand_pieces.size()):
		if hand_pieces[i].a == piece.a and hand_pieces[i].b == piece.b:
			hand_pieces.remove_at(i)
			return true
	return false

func has_piece(piece: Dictionary) -> bool:
	"""Verifica se tem uma peça específica"""
	for hand_piece in hand_pieces:
		if hand_piece.a == piece.a and hand_piece.b == piece.b:
			return true
	return false

func get_hand_count() -> int:
	"""Retorna quantidade de peças na mão"""
	return hand_pieces.size()

func get_hand_pieces() -> Array[Dictionary]:
	"""Retorna cópia das peças na mão"""
	return hand_pieces.duplicate()

func clear_hand():
	"""Limpa a mão do jogador"""
	hand_pieces.clear()

func get_highest_double() -> int:
	"""Retorna o valor da peça dupla mais alta (-1 se não tiver)"""
	var highest = -1
	for piece in hand_pieces:
		if piece.a == piece.b and piece.a > highest:
			highest = piece.a
	return highest

func calculate_hand_points() -> int:
	"""Calcula pontos das peças na mão"""
	var total = 0
	for piece in hand_pieces:
		total += piece.a + piece.b
	return total

func get_playable_pieces(board: Node) -> Array[Dictionary]:
	"""Retorna peças que podem ser jogadas no tabuleiro atual"""
	var playable: Array[Dictionary] = []
	
	if not board:
		return hand_pieces.duplicate()  # Primeira jogada, qualquer peça
	
	for piece in hand_pieces:
		if board.can_place_piece(piece, "left") or board.can_place_piece(piece, "right"):
			playable.append(piece)
	
	return playable

func has_playable_pieces(board: Node) -> bool:
	"""Verifica se tem peças jogáveis"""
	return get_playable_pieces(board).size() > 0
