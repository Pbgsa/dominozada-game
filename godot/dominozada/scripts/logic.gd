extends Node

var turn := 1
var heads := []
var game := []  
var players := []

# Declare the variable
@export var player_hand : PackedScene = preload("res://scenes/player_hand.tscn")

func on_piece_played(piece_data: Dictionary):
	print("piece_dat")
	var piece = {
		"code": Vector2i(piece_data.a, piece_data.b),
	}
	if check_validity(piece):
		update_heads(piece)
		# Adicione lógica para atualizar o tabuleiro, pontuação, etc.
		print("Jogada válida: ", piece_data)
	else:
		print("Jogada inválida: ", piece_data)

func check_validity(piece: Dictionary) -> bool:
	return check_logic_validity(piece)

func check_logic_validity(piece: Dictionary) -> bool:
	# Checa se a peça pode ser jogada em alguma das cabeças.
	if heads.is_empty():
		return true  # Primeira peça sempre válida

	for head in heads:
		if piece.code.x == head or piece.code.y == head:
			return true  # Combina com alguma cabeça existente

	return false  # Não combina com nenhuma cabeça

func update_heads(piece: Dictionary):
	# Atualiza as cabeças após a jogada.
	# Assumindo que a jogada já foi validada antes de chamar esta função.

	var a = piece.code.x
	var b = piece.code.y

	if heads.is_empty():
		# Primeira peça define as duas cabeças
		heads.append(a)
		heads.append(b)
		print("Primeira jogada, cabeças definidas: ", heads)
		return

	# Verifica qual lado foi conectado a alguma cabeça e atualiza
	var updated = false
	for i in range(heads.size()):
		if a == heads[i]:
			heads[i] = b
			updated = true
			break
		elif b == heads[i]:
			heads[i] = a
			updated = true
			break

	if not updated:
		print("⚠️ Nenhuma cabeça foi atualizada. Jogada inválida ou lógica incorreta.")

	print("Cabeças atuais: ", heads)
