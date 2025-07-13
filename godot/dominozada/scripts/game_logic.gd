extends Node

var screen_size := Vector2(1152, 648)
var tolerance := 200
var turn = 1
var heads := []
var game := []  

func is_piece_near_center(piece_pos: Vector2) -> bool:
	var center = screen_size / 2
	return piece_pos.distance_to(center) < tolerance

func print_piece_if_near_center(piece: Node):
	if is_piece_near_center(piece.position):
		print("Peça %dx%d do jogador %d posicionada" % [piece.code.x, piece.code.y, piece.belongsTo])
		

func set_turn():
	if(turn == 4):
		turn = 1
	else:
		turn = (turn + 1)
		 	
func play_piece_standard(piece: Node):
	if is_piece_near_center(piece.position):
		if(check_validity(piece)):
			print("Peça %dx%d do jogador %d posicionada" % [piece.code.x, piece.code.y, piece.belongsTo])
			game.append(piece.code)
			update_heads(piece)
			set_turn()

		
func check_validity(piece: Node) -> bool:
	return check_turn_validity(piece) and check_logic_validity(piece)

	

func check_turn_validity(piece: Node) -> bool:
	if(piece.belongsTo == turn):
		return true
	
	print("Não é a vez de player %d." %piece.belongsTo)
	return false

func check_logic_validity(piece: Node) -> bool:
	# Checa se a peça pode ser jogada em alguma das cabeças.
	if heads.is_empty():
		return true  # Primeira peça sempre válida

	for head in heads:
		if piece.code.x == head or piece.code.y == head:
			return true  # Combina com alguma cabeça existente

	return false  # Não combina com nenhuma cabeça


func update_heads(piece: Node):
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
		#no momento o lado em que a peça é jogada é definida pela primeira cabeça
		#TO DO: implementar escolha do lado
		if a == heads[i]:
			# Remove cabeça conectada e adiciona outro lado
			print("Conectado lado ", a, ". Substituindo por ", b)
			heads[i] = b
			updated = true
			break
		elif b == heads[i]:
			print("Conectado lado ", b, ". Substituindo por ", a)
			heads[i] = a
			updated = true
			break

	if not updated:
		print("⚠️ Nenhuma cabeça foi atualizada. Jogada inválida ou lógica incorreta.")

	print("Cabeças atuais: ", heads)
