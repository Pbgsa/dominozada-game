extends Node

# Singleton GameManager - Gerencia o estado geral do jogo

# Preload dos scripts de jogador
const PlayerScript = preload("res://scripts/player.gd")
const HumanPlayerScript = preload("res://scripts/human_player.gd")
const BotPlayerScript = preload("res://scripts/bot_player.gd")
const DominoSetScript = preload("res://scripts/domino_set.gd")

signal game_started
signal turn_changed(player_id: int)
signal game_over(winner_id: int, reason: String)
signal piece_distributed
signal player_passed(player_id: int)
signal piece_played(player_id: int, piece: Dictionary)
signal player_hand_changed(player_id: int, new_count: int)
signal bot_action_message(message: String)

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
	PUXANDO_DO_MORTO
}

var current_state: GameState = GameState.MENU
var current_mode: GameMode = GameMode.CLASSICO
var current_player: int = 0  # 0 = jogador humano, 1-3 = bots
var players_count: int = 4
var domino_set: RefCounted
var players: Array[RefCounted] = []
var board: Node
var consecutive_passes: int = 0

func _ready():
	# Inicializar componentes do jogo
	domino_set = DominoSetScript.new()
	setup_players()
	
	# Aguardar um frame para garantir que a cena esteja carregada
	await get_tree().process_frame
	
	# Obter referência ao board
	board = get_tree().current_scene if get_tree().current_scene.has_method("can_place_piece") else null
	
	if board:
		print("Board encontrado com sucesso!")
	else:
		print("Board não encontrado - tentando localizar...")
		# Tentar encontrar o board na cena atual
		var scene_root = get_tree().current_scene
		for child in scene_root.get_children():
			if child.has_method("can_place_piece"):
				board = child
				print("Board encontrado:", child.name)
				break

func setup_players():
	"""Configura os jogadores do jogo"""
	players.clear()
	
	# Jogador humano (ID 0)
	var human_player = HumanPlayerScript.new()
	human_player.player_id = 0
	human_player.player_name = "Jogador"
	players.append(human_player)
	
	# Bots (ID 1-3)
	for i in range(1, players_count):
		var bot = BotPlayerScript.new()
		bot.player_id = i
		bot.player_name = "Bot " + str(i)
		players.append(bot)

func start_new_game():
	"""Inicia uma nova partida"""
	print("Iniciando novo jogo...")
	current_state = GameState.PLAYING
	current_mode = GameMode.PUXANDO_DO_MORTO
	current_player = 0
	consecutive_passes = 0
	
	# Resetar conjunto de dominó
	domino_set.reset()
	
	# Limpar board se existir
	if board and board.has_method("clear_board"):
		board.clear_board()
	
	# Distribuir peças
	distribute_pieces()
		
	# Jogador humano sempre começa
	current_player = 0
	
	print("Primeiro jogador: ", players[current_player].player_name)
	
	game_started.emit()
	turn_changed.emit(current_player)

func distribute_pieces():
	if GameMode.PUXANDO_DO_MORTO == current_mode:
		"""Distribui 3 peças para cada jogador e deixa o restante no morto"""
		for player in players:
			player.clear_hand()
			for i in range(3):
				var piece = domino_set.draw_piece()
				if piece:
					player.add_piece_to_hand(piece)
	else:
		
		"""Distribui 7 peças para cada jogador"""
		for player in players:
			player.clear_hand()
			for i in range(7):
				var piece = domino_set.draw_piece()
				if piece:
					player.add_piece_to_hand(piece)
	
	piece_distributed.emit()

	var restante = domino_set.get_remaining_count()
	print("Peças restantes no boneyard: ", restante)
	# Atualizar contadores de peças na UI
	call_deferred("update_all_hand_counts")

func find_first_player() -> int:
	"""Encontra o jogador com a peça dupla mais alta (não usado atualmente)"""
	var highest_double = -1
	var first_player = 0
	
	for i in range(players.size()):
		var player = players[i]
		var highest_player_double = player.get_highest_double()
		if highest_player_double > highest_double:
			highest_double = highest_player_double
			first_player = i
	
	return first_player

func play_piece(player_id: int, piece: Dictionary, side: String) -> bool:
	"""Tenta jogar uma peça"""
	if current_player != player_id or current_state != GameState.PLAYING:
		print("Jogada rejeitada: não é o turno do jogador ou jogo não está ativo")
		return false
	
	var player = players[player_id]
	if not player.has_piece(piece):
		print("Jogada rejeitada: jogador não tem a peça")
		return false
	
	# Validar jogada no tabuleiro
	if not board:
		print("Erro: Board não encontrado!")
		return false
		
	if board.can_place_piece(piece, side):
		print("Jogando peça [%d,%d] no lado %s" % [piece.a, piece.b, side])
		board.place_piece(piece, side)
		player.remove_piece_from_hand(piece)
		consecutive_passes = 0
		
		# Emitir sinal de peça jogada
		piece_played.emit(player_id, piece)
		
		# Emitir sinal de mudança na mão do jogador
		player_hand_changed.emit(player_id, player.get_hand_count())
		
		# Verificar vitória
		if player.get_hand_count() == 0:
			end_game(player_id, GameOverReason.EMPTY_HAND)
			return true
		
		# Próximo turno
		next_turn()
		return true
	else:
		print("Jogada rejeitada: peça não pode ser colocada no lado especificado")
	
	return false

func pass_turn(player_id: int):
	"""Jogador passa a vez"""
	if current_player != player_id or current_state != GameState.PLAYING:
		return
	
	consecutive_passes += 1
	player_passed.emit(player_id)
	
	# Verificar se todos passaram
	if consecutive_passes >= players_count:
		end_game_by_points()
		return
	
	next_turn()

func next_turn():
	"""Avança para o próximo jogador"""
	current_player = (current_player + 1) % players_count
	turn_changed.emit(current_player)
	
	# Se for bot, executar jogada automaticamente
	if current_player != 0:  # Bot players têm ID > 0
		call_deferred("execute_bot_turn")

func execute_bot_turn():
	"""Executa o turno do bot"""
	var bot = players[current_player]
	
	# Adicionar delay para tornar o jogo mais natural
	await get_tree().create_timer(2).timeout
	bot_action_message.emit("%s está pensando..." % bot.player_name)
	
	# Verificar se o jogo ainda está ativo após o delay
	if current_state != GameState.PLAYING:
		return

	var move = bot.decide_move(board)
	var playable_pieces = bot.get_playable_pieces(board)

	if GameMode.PUXANDO_DO_MORTO == current_mode:
		if move.has("piece") and move.has("side"):
			await get_tree().create_timer(2).timeout
			var side_text = "esquerda" if move.side == "left" else "direita"
			bot_action_message.emit("%s jogou na %s" % [bot.player_name, side_text])
			play_piece(current_player, move.piece, move.side)
		else:
			# Bot pode comprar do morto
			while playable_pieces.is_empty() and domino_set.get_remaining_count() > 0:
				var piece = domino_set.draw_piece()
				if piece:
					board.add_a_purchased_piece_to_bot(current_player, piece)
					player_hand_changed.emit(current_player, bot.get_hand_count())
					playable_pieces = bot.get_playable_pieces(board)
				else:
					bot_action_message.emit("%s tentou comprar, mas o morto está vazio." % bot.player_name)
			move = bot.decide_move(board)
			if move.has("piece") and move.has("side"):
				await get_tree().create_timer(2).timeout
				var side_text = "esquerda" if move.side == "left" else "direita"
				bot_action_message.emit("%s jogou na %s" % [bot.player_name, side_text])
				play_piece(current_player, move.piece, move.side)
			pass_turn(current_player)	
	else:
		if move.has("piece") and move.has("side"):
			await get_tree().create_timer(2).timeout
			var side_text = "esquerda" if move.side == "left" else "direita"
			bot_action_message.emit("%s jogou na %s" % [bot.player_name, side_text])
			play_piece(current_player, move.piece, move.side)
		else:
			await get_tree().create_timer(2).timeout
			bot_action_message.emit("%s passou a vez" % bot.player_name)
			pass_turn(current_player)

func end_game(winner_id: int, reason: GameOverReason):
	"""Termina o jogo"""
	current_state = GameState.GAME_OVER
	var reason_text = get_game_over_reason_text(reason)
	game_over.emit(winner_id, reason_text)

func end_game_by_points():
	"""Termina jogo e calcula vencedor por pontos"""
	var lowest_points = 999
	var winner_id = 0
	
	for i in range(players.size()):
		var points = players[i].calculate_hand_points()
		if points < lowest_points:
			lowest_points = points
			winner_id = i
	
	end_game(winner_id, GameOverReason.ALL_PASSED)

func get_game_over_reason_text(reason: GameOverReason) -> String:
	match reason:
		GameOverReason.EMPTY_HAND:
			return "Mão vazia!"
		GameOverReason.ALL_PASSED:
			return "Todos passaram - vencedor por pontos!"
		_:
			return "Jogo terminado!"

func get_current_player() -> RefCounted:
	"""Retorna o jogador atual"""
	if current_player < players.size():
		return players[current_player]
	return null

func is_human_turn() -> bool:
	"""Verifica se é o turno do jogador humano"""
	return current_player == 0

func update_all_hand_counts():
	"""Emite sinais de atualização para todas as mãos dos jogadores"""
	for i in range(players.size()):
		player_hand_changed.emit(i, players[i].get_hand_count())

func buy_piece():
	"""Compra de peça"""
	var piece = domino_set.draw_piece()
	if piece:
		var player = players[0] 
		player.add_piece_to_hand(piece)
		board.add_a_purchased_piece_to_hand(0,piece)
		player_hand_changed.emit(0, player.get_hand_count())
		bot_action_message.emit("Você comprou a peça [%d,%d]" % [piece.a, piece.b])
	else:
		bot_action_message.emit("Não há peças para comprar.")
