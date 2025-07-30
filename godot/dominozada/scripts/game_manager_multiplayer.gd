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

var domino_set = DominoSet.new()
var players := {}
var turn_order := []
var current_turn_index := 0
# REMOVIDO: board_left_value, board_right_value, board_is_empty - usa o board como fonte da verdade
var passes_in_a_row := 0
var ready_players := []
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
	# Garantir que temos o board antes de iniciar o jogo
	if not board or not is_instance_valid(board):
		_find_board()
	
	turn_order = multiplayer.get_peers()
	turn_order.push_front(1)
	turn_order.shuffle()
	domino_set.generate_full_set()
	domino_set.shuffle()
	for peer_id in turn_order:
		players[peer_id] = {"hand": []}
		for i in range(7): players[peer_id].hand.append(domino_set.draw_piece())
		rpc_id(peer_id, "client_receive_hand", players[peer_id].hand)
	for peer_id in turn_order:
		rpc("client_update_player_hand_count", peer_id, 7)
	# O estado do board será gerenciado pelo próprio board.gd
	passes_in_a_row = 0
	current_turn_index = 0
	rpc("client_start_game")
	_set_turn(turn_order[current_turn_index])

@rpc("any_peer", "call_local", "reliable")
func server_play_piece(piece_data: Dictionary, side: String):
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0: sender_id = 1
	if turn_order.is_empty() or current_turn_index < 0 or current_turn_index >= turn_order.size():
		push_error("turn_order está vazio ou current_turn_index fora do range!")
		return
	if sender_id != turn_order[current_turn_index]: return

	var valid_sides = get_valid_sides_for_piece(piece_data)
	if not side in valid_sides: return

	var player_hand = players[sender_id].hand
	for i in range(player_hand.size()):
		if player_hand[i].a == piece_data.a and player_hand[i].b == piece_data.b:
			player_hand.remove_at(i)
			break
	# O board é responsável por atualizar seu próprio estado via sinal
	# rpc("_update_board_state",piece_data, side) - REMOVIDO
	rpc("client_play_piece", piece_data, side, sender_id)
	rpc("client_update_player_hand_count", sender_id, player_hand.size())
	passes_in_a_row = 0
	if player_hand.is_empty():
		rpc("client_game_over", sender_id, "O jogador não tem mais peças!")
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
	
	print("DEBUG MULTIPLAYER: get_valid_sides_for_piece [%d,%d] - Board: esquerda=%d, direita=%d" % [piece_data.a, piece_data.b, board_left_value, board_right_value])
	
	if piece_data.a == board_left_value or piece_data.b == board_left_value:
		valid_sides.append("left")
	if board_left_value == board_right_value and piece_data.a == piece_data.b: 
		return valid_sides
	if piece_data.a == board_right_value or piece_data.b == board_right_value:
		valid_sides.append("right")
	
	print("DEBUG MULTIPLAYER: Lados válidos encontrados: %s" % str(valid_sides))
	return valid_sides

# REMOVIDO: _update_board_state() - agora o board gerencia seu próprio estado

@rpc("any_peer", "call_local", "reliable")
func server_pass_turn():
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0: sender_id = 1
	if turn_order.is_empty() or current_turn_index < 0 or current_turn_index >= turn_order.size():
		push_error("turn_order está vazio ou current_turn_index fora do range!")
		return
	if sender_id != turn_order[current_turn_index]: return
	passes_in_a_row += 1
	rpc("client_player_passed", sender_id)
	if passes_in_a_row >= turn_order.size():
		rpc("client_game_over", -1, "Jogo travado!")
	else:
		_next_turn()

func _next_turn():
	current_turn_index = (current_turn_index + 1) % turn_order.size()
	_set_turn(turn_order[current_turn_index])
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
