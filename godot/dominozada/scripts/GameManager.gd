# res://scripts/GameManager.gd
extends Node

# Singleton GameManager - Gerencia o estado geral do jogo offline

# Preload dos scripts de jogador
const PlayerScript = preload("res://scripts/player.gd")
const HumanPlayerScript = preload("res://scripts/human_player.gd")
const BotPlayerScript = preload("res://scripts/bot_player.gd")
const DominoSetScript = preload("res://scripts/domino_set.gd")

signal game_started
signal hand_updated(my_hand)
signal player_hand_count_changed(player_id, count)
signal turn_changed(player_id)
signal piece_played_on_board(piece_data, side, player_id)
signal game_over(winner_id, reason)
signal piece_distributed
signal player_passed(player_id: int)
signal piece_played(player_id: int, piece: Dictionary)
signal bot_action_message(message: String)
signal remove_piece_from_board(last_invalid_move: Dictionary)

enum GameState {
	MENU,
	PLAYING,
	GAME_OVER,
	PAUSED
}

enum GameOverReason {
	EMPTY_HAND,
	ALL_PASSED
}

enum GameMode {
	CLASSICO,
	PUXANDO_DO_MORTO,
	GATO_COM_LEBRE
}

var current_state: GameState = GameState.MENU
var current_mode: GameMode = GameMode.CLASSICO
var domino_set: RefCounted
var players_objects: Array[RefCounted] = []  # Array de objetos Player para sistema avançado
var players = {
	1: {"name": "Jogador", "hand": [], "is_bot": false},
	2: {"name": "Bot 1", "hand": [], "is_bot": true},
	3: {"name": "Bot 2", "hand": [], "is_bot": true},
	4: {"name": "Bot 3", "hand": [], "is_bot": true},
}
var turn_order = [1, 2, 3, 4]
var current_turn_index = 0
var players_count: int = 4
# REMOVIDO: board_left_value, board_right_value, board_is_empty - agora usa o board como fonte da verdade
var passes_in_a_row := 0
var consecutive_passes: int = 0
var board: Node
var last_invalid_move: Dictionary = {}  # { player_id, piece, side, round }
var current_round: int = 0

func _ready():
	domino_set = DominoSetScript.new()
	setup_players()
	
func register_board(board_node: Node):
	if is_instance_valid(board_node) and board_node.has_method("get_board_left_value"):
		self.board = board_node
		print("GameManager: Board registrado com sucesso!")

		# Movemos a conexão do sinal para cá, garantindo que ela só aconteça quando o board existe.
		if self.board.has_signal("board_state_changed"):
			if not self.board.board_state_changed.is_connected(_on_board_state_changed):
				self.board.board_state_changed.connect(_on_board_state_changed)
	else:
		self.board = null
		print("GameManager ERRO: Tentativa de registrar um board inválido.")

func _on_board_state_changed(left_value: int, right_value: int, is_empty: bool):
	"""Callback quando o estado do board muda"""
	print("DEBUG: GameManager recebeu mudança do board - Esquerda: %d, Direita: %d, Vazio: %s" % [left_value, right_value, is_empty])

func setup_players():
	"""Configura os jogadores do jogo"""
	players_objects.clear()
	
	# Jogador humano (ID 0, mas mapeado para 1 no sistema atual)
	var human_player = HumanPlayerScript.new()
	human_player.player_id = 1
	human_player.player_name = "Jogador"
	players_objects.append(human_player)
	
	# Bots (ID 2-4)
	for i in range(2, players_count + 1):
		var bot = BotPlayerScript.new()
		bot.player_id = i
		bot.player_name = "Bot " + str(i - 1)
		players_objects.append(bot)

func set_next_game_mode(mode: GameMode):
	current_mode = mode

func start_new_game():
	"""Inicia uma nova partida"""
	print("Iniciando novo jogo...")
	print("Iniciando novo jogo no modo: ", GameMode.keys()[current_mode])
	current_state = GameState.PLAYING
	current_turn_index = 0
	consecutive_passes = 0
	passes_in_a_row = 0
	
	# Resetar conjunto de dominó
	domino_set.generate_full_set()
	domino_set.shuffle()
	
	# Limpar board se existir
	if board and board.has_method("clear_board"):
		board.clear_board()
	
	# Distribuir peças
	distribute_pieces()
	
	# O estado do board será gerenciado pelo próprio board.gd
	# Não precisamos mais resetar aqui
	
	print("Primeiro jogador: ", players[turn_order[current_turn_index]].name)
	
	game_started.emit()
	turn_changed.emit(turn_order[current_turn_index])

func distribute_pieces():
	"""Distribui 7 peças para cada jogador"""
	if GameMode.PUXANDO_DO_MORTO == current_mode:
		"""Distribui 3 peças para cada jogador e deixa o restante no morto"""
		for i in turn_order:
			players[i].hand.clear()
			for _j in range(3):
				var piece = domino_set.draw_piece()
				if piece:
					players[i].hand.append(piece)
	else:
		for i in turn_order:
			players[i].hand.clear()
			for _j in range(7):
				var piece = domino_set.draw_piece()
				if piece:
					players[i].hand.append(piece)
	
	# Sincronizar com objetos Player se existirem
	for player_obj in players_objects:
		if player_obj.player_id in players:
			player_obj.clear_hand()
			for piece in players[player_obj.player_id].hand:
				player_obj.add_piece_to_hand(piece)
	
	hand_updated.emit.call_deferred(players[1].hand)
	piece_distributed.emit()
	
	# Atualizar contadores de peças na UI
	call_deferred("update_all_hand_counts")

func update_all_hand_counts():
	"""Emite sinais de atualização para todas as mãos dos jogadores"""
	for i in turn_order:
		player_hand_count_changed.emit(i, players[i].hand.size())

func play_piece(piece_data: Dictionary, side: String):
	"""Versão simplificada para compatibilidade com sistema atual"""
	if(current_turn_index > 0): return
	var valid_sides = get_valid_sides_for_piece(piece_data)

	if current_mode == GameMode.GATO_COM_LEBRE:
		if not side in valid_sides:
			last_invalid_move = {
				"player_id": 1,
				"piece": piece_data,
				"side": side,
				"round": current_round
			}
	elif not side in valid_sides:
		return
	
	for i in range(players[1].hand.size()):
		var p = players[1].hand[i]
		if p.a == piece_data.a and p.b == piece_data.b:
			players[1].hand.remove_at(i)
			break
	
	piece_played_on_board.emit(piece_data, side, 1)
	piece_played.emit(1, piece_data)
	player_hand_count_changed.emit(1, players[1].hand.size())
	passes_in_a_row = 0
	consecutive_passes = 0
	
	if players[1].hand.is_empty():
		if current_mode == GameMode.GATO_COM_LEBRE:
			#roda 3 vezes
			for i in range(3):
				report_invalid_move()
			if not players[1].hand.is_empty():
				_next_turn()
		end_game(1, GameOverReason.EMPTY_HAND)
	else:
		_next_turn()

func play_piece_advanced(player_id: int, piece: Dictionary, side: String) -> bool:
	"""Versão avançada usando objetos Player - para compatibilidade futura"""
	if current_turn_index != (player_id - 1) or current_state != GameState.PLAYING:
		print("Jogada rejeitada: não é o turno do jogador ou jogo não está ativo")
		return false
	
	var player_dict = players[player_id]
	var has_piece = false
	
	# Verificar se o jogador tem a peça
	for p in player_dict.hand:
		if p.a == piece.a and p.b == piece.b:
			has_piece = true
			break
	
	if not has_piece:
		print("Jogada rejeitada: jogador não tem a peça")
		return false
	
	# Validar jogada
	var valid_sides = get_valid_sides_for_piece(piece)

	if current_mode == GameMode.GATO_COM_LEBRE:
		if not side in valid_sides:
			last_invalid_move = {
				"player_id": 1,
				"piece": piece,
				"side": side,
				"round": current_round
			}
	elif not side in valid_sides:
		print("Jogada rejeitada: peça não pode ser colocada no lado especificado")
		return false
	
	# Executar jogada
	for i in range(player_dict.hand.size()):
		var p = player_dict.hand[i]
		if p.a == piece.a and p.b == piece.b:
			player_dict.hand.remove_at(i)
			break
	
	# O board é responsável por atualizar seu próprio estado
	# _update_board_state(piece, side) - REMOVIDO
	piece_played_on_board.emit(piece, side, player_id)
	piece_played.emit(player_id, piece)
	player_hand_count_changed.emit(player_id, player_dict.hand.size())
	consecutive_passes = 0
	passes_in_a_row = 0
	
	# Verificar vitória
	if player_dict.hand.is_empty():
		if current_mode == GameMode.GATO_COM_LEBRE:
			#roda 3 vezes
			for i in range(3):
				report_invalid_move()
			if not players[1].hand.is_empty():
				_next_turn()
				return true
		end_game(player_id, GameOverReason.EMPTY_HAND)
		return true
	else:
		_next_turn()
		return true

func get_valid_sides_for_piece(piece_data: Dictionary) -> Array[String]:
	var valid_sides: Array[String] = []
	
	# Usar o board como fonte da verdade
	if not board:
		print("AVISO: Board não encontrado - retornando lado esquerdo como padrão")
		return ["left"]
	
	var board_is_empty = board.get_board_is_empty()
	if board_is_empty: 
		return ["left"]
	
	var board_left_value = board.get_board_left_value()
	var board_right_value = board.get_board_right_value()
	
	# print("DEBUG: get_valid_sides_for_piece [%d,%d] - Board: esquerda=%d, direita=%d" % [piece_data.a, piece_data.b, board_left_value, board_right_value])
	
	# Verificar se pode conectar na esquerda
	if piece_data.a == board_left_value or piece_data.b == board_left_value:
		valid_sides.append("left")
	
	# Verificar se ambas as pontas são iguais e a peça é double
	if board_left_value == board_right_value and piece_data.a == piece_data.b: 
		return valid_sides
	
	# Verificar se pode conectar na direita
	if piece_data.a == board_right_value or piece_data.b == board_right_value:
		valid_sides.append("right")
		
	# print("DEBUG: Lados válidos encontrados: %s" % str(valid_sides))
	return valid_sides

func pass_turn():
	"""Versão simplificada para compatibilidade"""
	var current_player_id = turn_order[current_turn_index]
	pass_turn_advanced(current_player_id)

func pass_turn_advanced(player_id: int):
	"""Jogador passa a vez - versão avançada"""
	var expected_player = turn_order[current_turn_index]
	if player_id != expected_player or current_state != GameState.PLAYING:
		return
	
	consecutive_passes += 1
	passes_in_a_row += 1
	# var player_name = players[player_id].name if player_id in players else "Jogador " + str(player_id)
	# print("DEBUG OFFLINE: %s passou a vez (%d/%d passadas)" % [player_name, consecutive_passes, players_count])
	player_passed.emit(player_id)
	
	# Verificar se todos passaram
	if consecutive_passes >= players_count:
		# print("DEBUG OFFLINE: Todos passaram - calculando vencedor por pontos")
		end_game_by_points()
		return
	
	_next_turn()

# REMOVIDO: _update_board_state() - agora o board gerencia seu próprio estado

# ===== FUNÇÕES AVANÇADAS ADICIONADAS =====

func end_game(winner_id: int, reason: GameOverReason):
	"""Termina o jogo"""
	current_state = GameState.GAME_OVER
	
	var winner_name = players[winner_id].name if winner_id in players else "Jogador " + str(winner_id)
	var reason_text = ""
	
	match reason:
		GameOverReason.EMPTY_HAND:
			reason_text = "%s venceu! Ficou sem peças." % winner_name
		GameOverReason.ALL_PASSED:
			reason_text = get_game_over_reason_text(reason)
		_:
			reason_text = get_game_over_reason_text(reason)
	
	# print("DEBUG OFFLINE: Game over - Winner: %s, Reason: %s" % [winner_name, reason_text])
	game_over.emit(winner_id, reason_text)

func end_game_by_points():
	"""Termina jogo e calcula vencedor por pontos"""
	var lowest_points = 999
	var winner_id = turn_order[0]
	
	# print("DEBUG OFFLINE: Calculando vencedor por pontos...")
	
	for player_id in turn_order:
		var points = calculate_hand_points(player_id)
		# print("DEBUG OFFLINE: %s tem %d pontos" % [players[player_id].name, points])
		
		if points < lowest_points:
			lowest_points = points
			winner_id = player_id
	
	var winner_name = players[winner_id].name
	var reason = "Jogo travado! %s venceu por menor pontuação (%d pontos)" % [winner_name, lowest_points]
	# print("DEBUG OFFLINE: Vencedor: %s" % winner_name)
	
	current_state = GameState.GAME_OVER
	game_over.emit(winner_id, reason)

func calculate_hand_points(player_id: int) -> int:
	"""Calcula pontos na mão do jogador"""
	var total_points = 0
	if player_id in players:
		for piece in players[player_id].hand:
			total_points += piece.a + piece.b
	return total_points

func get_game_over_reason_text(reason: GameOverReason) -> String:
	match reason:
		GameOverReason.EMPTY_HAND:
			return "Mão vazia!"
		GameOverReason.ALL_PASSED:
			return "Todos passaram - vencedor por pontos!"
		_:
			return "Jogo terminado!"

func get_current_player_id() -> int:
	"""Retorna o ID do jogador atual"""
	if current_turn_index < turn_order.size():
		return turn_order[current_turn_index]
	return 1

func is_human_turn() -> bool:
	"""Verifica se é o turno do jogador humano"""
	return get_current_player_id() == 1

func find_first_player() -> int:
	"""Encontra o jogador com a peça dupla mais alta (funcionalidade para futura implementação)"""
	var highest_double = -1
	var first_player = 1
	
	for player_id in turn_order:
		var player_hand = players[player_id].hand
		for piece in player_hand:
			if piece.a == piece.b and piece.a > highest_double:
				highest_double = piece.a
				first_player = player_id
	
	return first_player

func _next_turn():
	current_turn_index = (current_turn_index + 1) % turn_order.size()
	current_round += 1
	if not last_invalid_move.is_empty() and last_invalid_move.round + 1 < current_round:
		last_invalid_move.clear()  # Limpar jogada inválida se for de rodada anterior
	var current_player_id = turn_order[current_turn_index]
	turn_changed.emit(current_player_id)
	
	if players[current_player_id].is_bot:
		call_deferred("execute_bot_turn")

func execute_bot_turn():
	"""Executa o turno do bot com sistema melhorado"""
	var current_player_id = turn_order[current_turn_index]
	var bot_data = players[current_player_id]
	
	# Adicionar delay para tornar o jogo mais natural
	await get_tree().create_timer(1.0).timeout
	bot_action_message.emit("%s está pensando..." % bot_data.name)
	
	# Verificar se o jogo ainda está ativo após o delay
	if current_state != GameState.PLAYING:
		return
	
	report_invalid_move()

	# Tentar encontrar uma jogada válida
	var bot_hand = bot_data.hand
	var move_found = false
	
	for piece in bot_hand:
		var valid_sides = get_valid_sides_for_piece(piece)
		if not valid_sides.is_empty():
			var side_to_play = valid_sides[0]
			
			await get_tree().create_timer(1.0).timeout
			var side_text = "esquerda" if side_to_play == "left" else "direita"
			bot_action_message.emit("%s jogou na %s" % [bot_data.name, side_text])
			
			piece_played_on_board.emit(piece, side_to_play, current_player_id)
			piece_played.emit(current_player_id, piece)
			bot_hand.erase(piece)
			player_hand_count_changed.emit(current_player_id, bot_hand.size())
			passes_in_a_row = 0
			consecutive_passes = 0
			move_found = true
			
			if bot_hand.is_empty():
				end_game(current_player_id, GameOverReason.EMPTY_HAND)
			else:
				_next_turn()
			return
	
	# Se não encontrou jogada, passa
	if not move_found:
		if GameMode.GATO_COM_LEBRE == current_mode and randf() < 1: #debug
			var chosen_side = "left" if randf() < 0.5 else "right"

			var piece_to_play = bot_hand[0]
			var side_text = "esquerda" if chosen_side == "left" else "direita"
			bot_action_message.emit("%s jogou na %s" % [bot_data.name, side_text])
			
			last_invalid_move = {
				"player_id": current_player_id,
				"piece": piece_to_play,
				"side": chosen_side,
				"round": current_round
			}

			piece_played_on_board.emit(piece_to_play, chosen_side, current_player_id)
			piece_played.emit(current_player_id, piece_to_play)
			bot_hand.erase(piece_to_play)
			player_hand_count_changed.emit(current_player_id, bot_hand.size())
			passes_in_a_row = 0
			consecutive_passes = 0

			print("DEBUG: Jogada na sacanagem: ", piece_to_play, chosen_side)

		if GameMode.PUXANDO_DO_MORTO == current_mode:
			while domino_set.get_remaining_count() > 0:
				var piece = domino_set.draw_piece()
				if piece:
					players[current_player_id].hand.append(piece)
					add_a_purchased_piece_to_bot(piece)
					var playable_sides = get_valid_sides_for_piece(piece)
					if not playable_sides.is_empty():
						var side_to_play = playable_sides[0]
						await get_tree().create_timer(1.0).timeout
						var side_text = "esquerda" if side_to_play == "left" else "direita"
						bot_action_message.emit("%s jogou na %s" % [bot_data.name, side_text])
						piece_played_on_board.emit(piece, side_to_play, current_player_id)
						piece_played.emit(current_player_id, piece)
						bot_hand.erase(piece)
						player_hand_count_changed.emit(current_player_id, bot_hand.size())
						passes_in_a_row = 0
						consecutive_passes = 0
						_next_turn()
						return
					else:
						bot_action_message.emit("%s comprou uma peça, mas não pode jogar." % bot_data.name)

			bot_action_message.emit("%s tentou comprar, mas o morto está vazio." % bot_data.name)
			await get_tree().create_timer(1.0).timeout
			bot_action_message.emit("%s passou a vez" % bot_data.name)
			pass_turn_advanced(current_player_id)
		else:
			await get_tree().create_timer(1.0).timeout
			bot_action_message.emit("%s passou a vez" % bot_data.name)
			pass_turn_advanced(current_player_id)

func _execute_bot_turn(bot_id: int):
	"""Versão antiga mantida para compatibilidade"""
	var bot_hand = players[bot_id].hand
	for piece in bot_hand:
		var valid_sides = get_valid_sides_for_piece(piece)
		if not valid_sides.is_empty():
			var side_to_play = valid_sides[0]
			# O board é responsável por atualizar seu próprio estado
			# _update_board_state(piece, side_to_play) - REMOVIDO
			piece_played_on_board.emit(piece, side_to_play, bot_id)
			bot_hand.erase(piece)
			print(bot_id)
			player_hand_count_changed.emit(bot_id, bot_hand.size())
			passes_in_a_row = 0
			if bot_hand.is_empty():
				game_over.emit(bot_id, "O Bot %d venceu!" % bot_id)
			else:
				_next_turn()
			return
	pass_turn()

func add_a_purchased_piece_to_hand(piece: Dictionary):
	var current_player_id = turn_order[current_turn_index]
	for player in players_objects:
		if player.player_id == current_player_id:
			player.add_piece_to_hand(piece)
			update_all_hand_counts()
			return

func add_a_purchased_piece_to_bot(piece: Dictionary):
	var current_player_id = turn_order[current_turn_index]
	for player in players_objects:
		if player.player_id == current_player_id:
			player.add_piece_to_hand(piece)
			update_all_hand_counts()
			return

func buy_piece():
	"""Compra de peça"""
	var current_player_id = turn_order[current_turn_index]
	var piece = domino_set.draw_piece()
	if piece:
		players[current_player_id].hand.append(piece)
		add_a_purchased_piece_to_hand(piece)
		hand_updated.emit.call_deferred(players[1].hand)
		call_deferred("update_all_hand_counts")
		print(players[current_player_id].hand)
		bot_action_message.emit("Você comprou a peça [%d,%d]" % [piece.a, piece.b])
	else:
		bot_action_message.emit("Não há peças para comprar.")

func report_invalid_move():
	"""Tenta reportar a última jogada inválida"""
	if randf() > 1 and not is_human_turn(): #Debugggggg
		return
	else:
		if not last_invalid_move.is_empty():
			bot_action_message.emit("Jogada inválida detectada: %s" % last_invalid_move)

			var piece = last_invalid_move.piece
			var side = last_invalid_move.side
			var player_id = last_invalid_move.player_id

			# Remover a peça do board
			remove_piece_from_board.emit(last_invalid_move)

			# Adicionar a peça de volta à mão do jogador
			players[player_id].hand.append(piece)
			add_a_purchased_piece_to_bot(piece)
			hand_updated.emit.call_deferred(players[1].hand)
			call_deferred("update_all_hand_counts")
			bot_action_message.emit("A peça [%d,%d] foi devolvida à mão do jogador %d" % [piece.a, piece.b, player_id])

			last_invalid_move.clear()

func is_board_empty() -> bool:
	return board.board_left_value == -1 and board.board_right_value == -1
