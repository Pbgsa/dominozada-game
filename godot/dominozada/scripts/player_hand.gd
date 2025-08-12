# scripts/player_hand.gd
extends HBoxContainer

@onready var piece_button_scene: PackedScene = preload("res://scenes/domino_piece_button.tscn")
@export var placement_options_scene: PackedScene = preload("res://scenes/placement_options.tscn")
@export var invalid_message_scene: PackedScene = preload("res://scenes/invalid_move_message.tscn")

var piece_buttons: Array[Button] = []
var placement_options_instance: CanvasLayer
var invalid_message_instance: CanvasLayer = null  # Nova instância para mensagens
var selected_button: Control = null  # Botão atualmente selecionado
var game_manager

func _ready():
	# Configurar UI - usar call_deferred para evitar erros de parent ocupado
	call_deferred("_setup_ui")
	
	# Conectar ao GameManager apropriado
	if NetworkManager.is_online_mode:
		game_manager = GameManagerMultiplayer
	else:
		game_manager = GameManager  # Usar o GameManager global

	# Conectar sinais
	game_manager.hand_updated.connect(_on_hand_updated)
	game_manager.game_started.connect(clear_hand)
	game_manager.piece_played_on_board.connect(_on_piece_played_on_board)
	
	# Conectar sinais específicos do modo offline (se existirem)
	if not NetworkManager.is_online_mode and game_manager.has_signal("piece_played"):
		game_manager.piece_played.connect(_on_piece_played_by_game_manager)

func _setup_ui():
	"""Configura elementos de UI após a cena estar pronta"""
	print("Configurando UI do player_hand...")
	
	# Criar placement options UI
	placement_options_instance = placement_options_scene.instantiate()
	get_tree().current_scene.add_child(placement_options_instance)
	placement_options_instance.side_selected.connect(_on_placement_side_selected)
	
	# Verificar se placement_options tem sinal de cancelamento
	if placement_options_instance.has_signal("placement_cancelled"):
		placement_options_instance.placement_cancelled.connect(_on_placement_cancelled)
	
	print("placement_options criado e conectado")
	
	# Criar invalid move message UI
	if invalid_message_scene:
		invalid_message_instance = invalid_message_scene.instantiate()
		get_tree().current_scene.add_child(invalid_message_instance)
		print("invalid_message criado")
	else:
		print("AVISO: invalid_message_scene não encontrado - mensagens não serão exibidas")

func _on_hand_updated(my_hand: Array):
	clear_hand()
	for piece_data in my_hand:
		var button = piece_button_scene.instantiate()
		add_child(button)
		button.set_piece_values(piece_data.a, piece_data.b, "up")
		button.set_meta("piece_data", piece_data)
		button.pressed.connect(func(): _on_piece_selected(button))
		piece_buttons.append(button)

func _on_piece_selected(button: Button):
	var piece_data = button.get_meta("piece_data")
	print("Peça selecionada: [%d,%d]" % [piece_data.a, piece_data.b])
	
	# Verificar se é o turno do jogador
	if not _is_player_turn():
		show_invalid_move_message(piece_data, "Não é seu turno!")
		return
	
	# Limpar seleção visual anterior
	clear_selection_visual()
	
	# Verificar lados válidos
	var valid_sides = game_manager.get_valid_sides_for_piece(piece_data)
	
	if valid_sides.is_empty():
		# Mostrar informações de debug das cabeças jogáveis  
		# print("Essa peça [%d,%d] não pode ser jogada." % [piece_data.a, piece_data.b])
		# _print_board_debug_info()
		show_invalid_move_message(piece_data, "Esta peça não pode ser jogada!")
		return
	
	# Definir seleção visual
	selected_button = button
	set_selection_visual(button)
	
	if valid_sides.size() == 1:
		print("Apenas um lado disponível, jogando automaticamente...")
		_on_placement_side_selected(valid_sides[0], piece_data)
	else:
		print("Múltiplas opções, mostrando UI de seleção...")
		placement_options_instance.show_options(piece_data, valid_sides)

func _is_player_turn() -> bool:
	"""Verifica se é o turno do jogador atual"""
	if NetworkManager.is_online_mode:
		# TODO: no multiplayer, verificar se é nosso turno baseado no ID
		print("AVISO: GameManager não tem método is_player_turn, assumindo que é sempre o turno do jogador.")
		# Se não tiver método, assumir que é sempre o turno do jogador
		return true
	else:
		# No modo offline, usar a função do GameManager
		if game_manager.has_method("is_human_turn"):
			return game_manager.is_human_turn()
		else:
			return true  # Fallback

# func _print_board_debug_info():
# 	"""Imprime informações de debug das cabeças do tabuleiro"""
# 	# Tentar obter referência ao board para informações de debug
# 	var board = null
# 	if NetworkManager.is_online_mode:
# 		# No multiplayer, tentar encontrar o board
# 		board = get_tree().current_scene if get_tree().current_scene.has_method("get_board_left_value") else null
# 	else:
# 		# No offline, usar a referência do GameManager
# 		if game_manager.has_method("board") and game_manager.board:
# 			board = game_manager.board
	
# 	if board and board.has_method("get_board_is_empty"):
# 		var is_empty = board.get_board_is_empty()
# 		if is_empty:
# 			print("DEBUG: Tabuleiro está vazio - qualquer peça deveria ser válida")
# 		else:
# 			var left_value = board.get_board_left_value()
# 			var right_value = board.get_board_right_value()
# 			print("DEBUG: Cabeças jogáveis no tabuleiro - Esquerda: %d, Direita: %d" % [left_value, right_value])
# 			print("DEBUG: Para jogar, a peça precisa ter %d ou %d em algum dos lados" % [left_value, right_value])
# 	else:
# 		print("DEBUG: Não foi possível obter informações do tabuleiro")

func set_selection_visual(button: Control):
	"""Define indicação visual para peça selecionada"""
	if button:
		button.modulate = Color(1.0, 1.0, 0.8, 1.0)  # Tonalidade amarelada

func clear_selection_visual():
	"""Remove seleção visual de todos os botões"""
	if selected_button:
		selected_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	selected_button = null

func _on_placement_side_selected(side: String, piece_data: Dictionary):
	print("Lado selecionado: %s para peça [%d,%d]" % [side, piece_data.a, piece_data.b])
	
	# Executar jogada baseado no modo
	if NetworkManager.is_online_mode:
		game_manager.server_play_piece.rpc(piece_data, side)
	else:
		# No modo offline, usar função avançada se disponível
		var success = false
		if game_manager.has_method("play_piece_advanced"):
			success = game_manager.play_piece_advanced(1, piece_data, side)  # 1 = jogador humano
		else:
			game_manager.play_piece(piece_data, side)
			success = true  # Assumir sucesso no método antigo
		
		if not success:
			show_invalid_move_message(piece_data, "Jogada inválida!")
			return
	
	# Limpar seleção visual
	clear_selection_visual()

func _on_placement_cancelled():
	"""Lidar com cancelamento de posicionamento"""
	print("Posicionamento cancelado")
	clear_selection_visual()

func _on_piece_played_on_board(piece_data: Dictionary, _side: String, player_id: int):
	var my_id = 1
	if NetworkManager.is_online_mode:
		my_id = multiplayer.get_unique_id()
	
	if player_id == my_id:
		print("Removendo peça [%d,%d] da UI após jogada" % [piece_data.a, piece_data.b])
		remove_piece_from_hand(piece_data)

func _on_piece_played_by_game_manager(player_id: int, piece: Dictionary):
	"""Chamada quando uma peça é jogada pelo GameManager (modo offline)"""
	if player_id == 1:  # Jogador humano no modo offline
		print("Removendo peça [%d,%d] da UI após jogada do GameManager" % [piece.a, piece.b])
		remove_piece_from_hand(piece)

func remove_piece_from_hand(piece_data: Dictionary):
	"""Remove uma peça da mão após confirmação de jogada válida"""
	for i in range(piece_buttons.size()):
		var button = piece_buttons[i]
		if not is_instance_valid(button): 
			continue
			
		var button_piece_data = button.get_meta("piece_data")
		if button_piece_data.a == piece_data.a and button_piece_data.b == piece_data.b:
			# Limpar seleção se esta peça estava selecionada
			if button == selected_button:
				clear_selection_visual()
			
			# Remover botão visual
			piece_buttons.remove_at(i)
			button.queue_free()
			print("Peça [%d,%d] removida da mão" % [piece_data.a, piece_data.b])
			return

func show_invalid_move_message(piece_data: Dictionary, custom_message: String = ""):
	"""Mostra mensagem quando um movimento é inválido"""
	var message = custom_message
	if custom_message.is_empty():
		message = "JOGADA INVÁLIDA: Peça [%d,%d] não pode ser colocada no tabuleiro!" % [piece_data.a, piece_data.b]
	
	print(message)
	
	# Mostrar notificação visual
	if invalid_message_instance and invalid_message_instance.has_method("show_message"):
		invalid_message_instance.show_message(message)
	else:
		print("AVISO: Sistema de mensagens não disponível")

func get_hand_count() -> int:
	"""Retorna o número de peças na mão"""
	return piece_buttons.size()

func clear_hand():
	"""Remove todas as peças da mão"""
	# Limpar seleção visual
	clear_selection_visual()
	
	# Remover todos os botões
	for button in piece_buttons:
		if is_instance_valid(button):
			button.queue_free()
	
	piece_buttons.clear()
	print("Mão limpa")

# ===== FUNÇÕES AUXILIARES PARA COMPATIBILIDADE =====

func add_piece(a: int, b: int):
	"""Adiciona uma peça à mão (compatibilidade com código antigo)"""
	print("Adicionando peça [%d,%d] à mão" % [a, b])
	var button = piece_button_scene.instantiate()
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(button)

	await get_tree().process_frame
	button.set_piece_values(a, b, "up")
	button.set_meta("piece_data", {"a": a, "b": b})
	button.pressed.connect(func(): _on_piece_selected(button))
	piece_buttons.append(button)
	print("Botão da peça [%d,%d] conectado" % [a, b])

func update_hand_from_array(hand_array: Array):
	"""Atualiza a mão a partir de um array de peças"""
	clear_hand()
	for piece_data in hand_array:
		add_piece(piece_data.a, piece_data.b)
