# scripts/game_manager_multiplayer.gd
extends Node

signal change_scene_to_game
signal game_started
signal hand_updated(my_hand)
signal player_hand_count_changed(player_id, count)
signal turn_changed(player_id)
signal piece_played_on_board(piece_data, side, player_id)
signal game_over(winner_id, reason)
signal player_passed_turn(player_id)

enum GameMode {
	CLASSICO,
	PUXANDO_DO_MORTO
}

var domino_set = DominoSet.new()
var players := {}
var turn_order := []
var current_turn_index := 0
# REMOVIDO: board_left_value, board_right_value, board_is_empty - usa o board como fonte da verdade
var passes_in_a_row := 0
var ready_players := []
var current_mode: GameMode = GameMode.CLASSICO
var board: Node  # Referência ao board

func _ready():
	# Aguardar um frame para garantir que a cena esteja carregada
	await get_tree().process_frame
	
	# Encontrar o board na árvore da cena
	_find_board()

func _find_board():
	# Tentar encontrar o board na cena atual
	board = get_tree().current_scene if get_tree().current_scene.has_method("get_board_left_value") else null
	
	if not board:
		# Procurar recursivamente na árvore da cena
		board = _search_for_board(get_tree().current_scene)
	
	if board:
		print("Board encontrado com sucesso no multiplayer!")
	else:
		print("AVISO: Board não encontrado no multiplayer - algumas funcionalidades podem não funcionar")

func _search_for_board(node: Node) -> Node:
	# Verificar se o nó atual é o board
	if node.has_method("get_board_left_value"):
		return node
	
	# Procurar nos filhos
	for child in node.get_children():
		var result = _search_for_board(child)
		if result:
			return result
	
	return null

func host_requests_start_game():
	if not multiplayer.is_server(): return
	ready_players.clear()
	ready_players.append(1)
	rpc("client_load_game_scene")

@rpc("authority", "call_local", "reliable")
func client_load_game_scene():
	change_scene_to_game.emit()

@rpc("any_peer", "reliable")
func server_player_is_ready():
	if not multiplayer.is_server(): return
	var sender_id = multiplayer.get_remote_sender_id()
	
	if sender_id == 0: sender_id = 1
	if not sender_id in ready_players: ready_players.append(sender_id)
	if ready_players.size() == NetworkManager.players.size():
		_start_actual_game()

func _start_actual_game():
	# print("DEBUG MULTIPLAYER: Iniciando jogo...")
	current_mode = GameMode.CLASSICO
	
	# Garantir que temos o board antes de iniciar o jogo
	if not board or not is_instance_valid(board):
		_find_board()
	
	# Configurar ordem dos turnos
	turn_order = multiplayer.get_peers()
	turn_order.push_front(1)
	turn_order.shuffle()
	
	# --- CORREÇÃO 1: Enviar a ordem dos turnos para todos os clientes ---
	rpc("client_set_turn_order", turn_order)
	
	# print("DEBUG MULTIPLAYER: turn_order configurado: %s" % turn_order)
	# print("DEBUG MULTIPLAYER: Jogadores no NetworkManager: %s" % NetworkManager.players)
	
	# Gerar e embaralhar dominós
	domino_set.generate_full_set()
	domino_set.shuffle()

	var initial_head_number
	if GameMode.PUXANDO_DO_MORTO == current_mode:
		initial_head_number = 3
	else:
		initial_head_number = 7
		
	
	# Distribuir peças para cada jogador
	for peer_id in turn_order:
		players[peer_id] = {"hand": []}
		for i in range(initial_head_number): 
			var piece = domino_set.draw_piece()
			if piece:
				players[peer_id].hand.append(piece)
		rpc_id(peer_id, "client_receive_hand", players[peer_id].hand)
		
	
		# print("DEBUG MULTIPLAYER: Distribuídas %d peças para jogador %d (%s)" % [players[peer_id].hand.size(), peer_id, NetworkManager.get_player_name(peer_id)])
	
	# --- CORREÇÃO 2: Mudar a ordem das chamadas RPC ---
	# Primeiro, iniciar o jogo em todos os clientes
	rpc("client_start_game")
	
	# Depois, atualizar os contadores de peças de cada um
	for peer_id in turn_order:
		rpc("client_update_player_hand_count", peer_id, initial_head_number)
	
	# Por último, definir de quem é o primeiro turno
	_set_turn(turn_order[current_turn_index]) 

@rpc("authority", "call_local", "reliable")
func client_set_turn_order(p_turn_order: Array):
	"""Recebe e define a ordem dos turnos vinda do servidor."""
	turn_order = p_turn_order

@rpc("any_peer", "call_local", "reliable")
func server_play_piece(piece_data: Dictionary, side: String):
	# Verificar se o servidor está ativo
	if not multiplayer.is_server():
		# print("DEBUG MULTIPLAYER: server_play_piece chamado em cliente - ignorando")
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0: sender_id = 1
	
	# Debug detalhado do estado do jogo
	# print("DEBUG MULTIPLAYER: server_play_piece - Sender: %d, Peça: [%d,%d], Lado: %s" % [sender_id, piece_data.a, piece_data.b, side])
	
	# Se houver problemas, mostrar estado completo
	# if turn_order.is_empty() or current_turn_index < 0 or current_turn_index >= turn_order.size():
	# 	debug_game_state()
	
	# Verificações robustas
	if turn_order.is_empty():
		push_error("ERRO MULTIPLAYER: turn_order está vazio! Jogo não foi inicializado corretamente.")
		# print("DEBUG MULTIPLAYER: Estado dos jogadores: %s" % players)
		# print("DEBUG MULTIPLAYER: Jogadores prontos: %s" % ready_players)
		return
		
	if current_turn_index < 0 or current_turn_index >= turn_order.size():
		push_error("ERRO MULTIPLAYER: current_turn_index (%d) fora do range! turn_order.size(): %d" % [current_turn_index, turn_order.size()])
		# print("DEBUG MULTIPLAYER: turn_order: %s" % turn_order)
		return
	
	# Verificar se é o turno do jogador
	var expected_player = turn_order[current_turn_index]
	if sender_id != expected_player:
		# print("DEBUG MULTIPLAYER: Não é o turno do jogador %d (esperado: %d)" % [sender_id, expected_player])
		return

	var valid_sides = get_valid_sides_for_piece(piece_data)
	if not side in valid_sides: 
		# print("DEBUG MULTIPLAYER: Lado inválido '%s' para peça [%d,%d]. Lados válidos: %s" % [side, piece_data.a, piece_data.b, valid_sides])
		return

	# Verificar se o jogador tem a peça
	if not sender_id in players:
		push_error("ERRO MULTIPLAYER: Jogador %d não encontrado em players!" % sender_id)
		return
		
	var player_hand = players[sender_id].hand
	var piece_found = false
	
	for i in range(player_hand.size()):
		if player_hand[i].a == piece_data.a and player_hand[i].b == piece_data.b:
			player_hand.remove_at(i)
			piece_found = true
			break
	
	if not piece_found:
		# print("DEBUG MULTIPLAYER: Jogador %d não tem a peça [%d,%d]" % [sender_id, piece_data.a, piece_data.b])
		return
	
	# Executar jogada
	# print("DEBUG MULTIPLAYER: Jogada válida executada por %s" % NetworkManager.get_player_name(sender_id))
	rpc("client_play_piece", piece_data, side, sender_id)
	rpc("client_update_player_hand_count", sender_id, player_hand.size())
	passes_in_a_row = 0
	
	if player_hand.is_empty():
		var winner_name = NetworkManager.get_player_name(sender_id)
		var reason = "%s venceu! Ficou sem peças." % winner_name
		# print("DEBUG MULTIPLAYER: Jogo terminado - %s" % reason)
		rpc("client_game_over", sender_id, reason)
	else:
		_next_turn()

func get_valid_sides_for_piece(piece_data: Dictionary) -> Array[String]:
	var valid_sides: Array[String] = []
	
	# Garantir que temos uma referência válida ao board
	if not board or not is_instance_valid(board):
		_find_board()
	
	# Usar o board como fonte da verdade
	if not board:
		print("ERRO: Board não encontrado no multiplayer - não é possível validar jogadas")
		return []
	
	var board_is_empty = board.get_board_is_empty()
	if board_is_empty: 
		return ["left"]
	
	var board_left_value = board.get_board_left_value()
	var board_right_value = board.get_board_right_value()
	
	# print("DEBUG MULTIPLAYER: get_valid_sides_for_piece [%d,%d] - Board: esquerda=%d, direita=%d" % [piece_data.a, piece_data.b, board_left_value, board_right_value])
	
	if piece_data.a == board_left_value or piece_data.b == board_left_value:
		valid_sides.append("left")
	if board_left_value == board_right_value and piece_data.a == piece_data.b: 
		return valid_sides
	if piece_data.a == board_right_value or piece_data.b == board_right_value:
		valid_sides.append("right")
	
	# print("DEBUG MULTIPLAYER: Lados válidos encontrados: %s" % str(valid_sides))
	return valid_sides

# REMOVIDO: _update_board_state() - agora o board gerencia seu próprio estado

@rpc("any_peer", "call_local", "reliable")
func server_pass_turn():
	# Verificar se o servidor está ativo
	if not multiplayer.is_server():
		# print("DEBUG MULTIPLAYER: server_pass_turn chamado em cliente - ignorando")
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0: sender_id = 1
	
	# Debug detalhado do estado do jogo
	# print("DEBUG MULTIPLAYER: server_pass_turn - Sender: %d, turn_order: %s, current_turn_index: %d" % [sender_id, turn_order, current_turn_index])
	
	# Verificações robustas
	if turn_order.is_empty():
		push_error("ERRO MULTIPLAYER: turn_order está vazio! Jogo não foi inicializado corretamente.")
		return
		
	if current_turn_index < 0 or current_turn_index >= turn_order.size():
		push_error("ERRO MULTIPLAYER: current_turn_index (%d) fora do range! turn_order.size(): %d" % [current_turn_index, turn_order.size()])
		return
	
	# Verificar se é o turno do jogador
	var expected_player = turn_order[current_turn_index]
	if sender_id != expected_player:
		print("DEBUG MULTIPLAYER: Não é o turno do jogador %d (esperado: %d)" % [sender_id, expected_player])
		return
	
	passes_in_a_row += 1

	# var player_name = NetworkManager.get_player_name(sender_id)
	# print("DEBUG MULTIPLAYER: %s passou a vez (%d/%d passadas)" % [player_name, passes_in_a_row, turn_order.size()])
	
	rpc("client_player_passed", sender_id)
	
	if passes_in_a_row >= turn_order.size():
		# Todos passaram - calcular vencedor por pontos
		# print("DEBUG MULTIPLAYER: Todos passaram - calculando vencedor por pontos")
		var winner_data = calculate_winner_by_points()
		var winner_name = NetworkManager.get_player_name(winner_data.winner_id)
		var reason = "Jogo travado! %s venceu por menor pontuação (%d pontos)" % [winner_name, winner_data.points]
		rpc("client_game_over", winner_data.winner_id, reason)
	else:
		_next_turn()

@rpc("any_peer", "call_local", "reliable")
func server_buy_piece():
	# Verificar se o servidor está ativo
	if not multiplayer.is_server():
		# print("DEBUG MULTIPLAYER: server_buy_piece chamado em cliente - ignorando")
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0: sender_id = 1
	
	# Verificações robustas
	if turn_order.is_empty():
		push_error("ERRO MULTIPLAYER: turn_order está vazio! Jogo não foi inicializado corretamente.")
		return
		
	if current_turn_index < 0 or current_turn_index >= turn_order.size():
		push_error("ERRO MULTIPLAYER: current_turn_index (%d) fora do range! turn_order.size(): %d" % [current_turn_index, turn_order.size()])
		return
	
	# Verificar se é o turno do jogador
	var expected_player = turn_order[current_turn_index]
	if sender_id != expected_player:
		print("DEBUG MULTIPLAYER: Não é o turno do jogador %d (esperado: %d)" % [sender_id, expected_player])
		return
	
	var piece = domino_set.draw_piece()
	if not piece:
		print("DEBUG MULTIPLAYER: Boneyard vazio - não é possível comprar peça")
		return
	
	players[sender_id].hand.append(piece)
	rpc_id(sender_id, "client_receive_hand", players[sender_id].hand)
	rpc("client_update_player_hand_count", sender_id, players[sender_id].hand.size())
	print(current_turn_index)
	
	# print("DEBUG MULTIPLAYER: Jogador %d comprou peça [%d,%d]" % [sender_id, piece.a, piece.b])

func _next_turn():
	if turn_order.is_empty():
		push_error("ERRO MULTIPLAYER: _next_turn chamado com turn_order vazio!")
		return
	
	current_turn_index = (current_turn_index + 1) % turn_order.size()
	var next_player = turn_order[current_turn_index]

	# var player_name = NetworkManager.get_player_name(next_player)
	# print("DEBUG MULTIPLAYER: Próximo turno - Index: %d, Jogador: %d (%s)" % [current_turn_index, next_player, player_name])
	
	_set_turn(next_player)


func calculate_winner_by_points() -> Dictionary:
	"""Calcula o vencedor quando todos passam - menor pontuação vence"""
	var lowest_points = 999
	var winner_id = turn_order[0]
	
	# print("DEBUG MULTIPLAYER: Calculando vencedor por pontos...")
	
	for player_id in turn_order:
		var hand = players[player_id].hand
		var points = 0
		
		# Calcular pontos na mão do jogador
		for piece in hand:
			points += piece.a + piece.b
		
		# print("DEBUG MULTIPLAYER: Jogador %s (%s) tem %d pontos" % [player_id, NetworkManager.get_player_name(player_id), points])
		
		if points < lowest_points:
			lowest_points = points
			winner_id = player_id
	
	# print("DEBUG MULTIPLAYER: Vencedor: %s com %d pontos" % [NetworkManager.get_player_name(winner_id), lowest_points])
	
	return {
		"winner_id": winner_id,
		"points": lowest_points
	}

# func debug_game_state():
# 	"""Função para debug do estado do jogo"""
# 	print("=== DEBUG MULTIPLAYER - Estado do Jogo ===")
# 	print("turn_order: %s" % turn_order)
# 	print("current_turn_index: %d" % current_turn_index)
# 	print("passes_in_a_row: %d" % passes_in_a_row)
# 	print("players: %s" % players.keys())
# 	print("ready_players: %s" % ready_players)
# 	print("NetworkManager.players: %s" % NetworkManager.players)
# 	if not turn_order.is_empty() and current_turn_index >= 0 and current_turn_index < turn_order.size():
# 		var current_player = turn_order[current_turn_index]
# 		print("Turno atual: %d (%s)" % [current_player, NetworkManager.get_player_name(current_player)])
# 	else:
# 		print("ERRO: Estado de turno inválido!")
# 	print("=========================================")

func _set_turn(player_id: int):
	rpc("client_set_turn", player_id)
@rpc("authority", "call_local", "reliable")
func client_receive_hand(hand: Array):
	hand_updated.emit.call_deferred(hand)
@rpc("authority", "call_local", "reliable")
func client_update_player_hand_count(player_id: int, count: int):
	player_hand_count_changed.emit(player_id, count)
@rpc("authority", "call_local", "reliable")
func client_start_game():
	game_started.emit()
@rpc("authority", "call_local", "reliable")
func client_set_turn(player_id: int):
	turn_changed.emit(player_id)
@rpc("authority", "call_local", "reliable")
func client_play_piece(piece_data: Dictionary, side: String, player_id: int):
	piece_played_on_board.emit(piece_data, side, player_id)
@rpc("authority", "call_local", "reliable")
func client_player_passed(player_id: int):
	player_passed_turn.emit(player_id)
@rpc("authority", "call_local", "reliable")
func client_game_over(winner_id: int, reason: String):
	game_over.emit(winner_id, reason)
