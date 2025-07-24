extends RefCounted
class_name DominoSet

var pieces: Array[Dictionary] = []
var used_pieces: Array[Dictionary] = []

func _init():
	generate_full_set()

func generate_full_set():
	"""Gera o conjunto completo de dominó (0-0 até 6-6)"""
	pieces.clear()
	used_pieces.clear()
	
	for a in range(7):
		for b in range(a, 7):  # b >= a para evitar duplicatas
			pieces.append({"a": a, "b": b})

func shuffle():
	"""Embaralha as peças"""
	pieces.shuffle()

func draw_piece() -> Dictionary:
	"""Retira uma peça do conjunto"""
	if pieces.is_empty():
		return {}
	
	var piece = pieces.pop_back()
	used_pieces.append(piece)
	return piece

func return_pieces(pieces_to_return: Array[Dictionary]):
	"""Retorna peças ao conjunto (para reiniciar jogo)"""
	for piece in pieces_to_return:
		if piece in used_pieces:
			used_pieces.erase(piece)
			pieces.append(piece)

func get_remaining_count() -> int:
	"""Retorna quantidade de peças restantes"""
	return pieces.size()

func reset():
	"""Reinicia o conjunto completo"""
	generate_full_set()

func has_piece(piece: Dictionary) -> bool:
	"""Verifica se uma peça específica ainda está disponível"""
	return piece in pieces

func get_all_pieces() -> Array[Dictionary]:
	"""Retorna todas as peças (usadas e não usadas)"""
	var all_pieces: Array[Dictionary] = []
	all_pieces.append_array(pieces)
	all_pieces.append_array(used_pieces)
	return all_pieces
