extends HBoxContainer

@onready var piece_button_scene: PackedScene = preload("res://scenes/domino_piece_button.tscn")
@export var placement_options_scene: PackedScene = preload("res://scenes/placement_options.tscn")
@export var invalid_message_scene: PackedScene = preload("res://scenes/invalid_move_message.tscn")

var hand_pieces: Array[Dictionary] = []  # [{a: int, b: int, dir: String}]
var piece_buttons: Array[Control] = []  # References to piece buttons
var selected_button: Control = null  # Currently selected button
var placement_options: CanvasLayer = null  # Placement options UI
var invalid_message: CanvasLayer = null  # Invalid move message UI
var board_reference: Node2D = null  # Reference to board for validation
var game_manager: Node = null  # Reference to game manager

signal piece_played(piece_data: Dictionary, placement_side: String)
signal passed_turn()

func _ready():
	# Create UI elements using deferred call to avoid busy parent error
	call_deferred("_setup_ui")
	
	# Get references
	board_reference = get_tree().current_scene
	if not board_reference.has_method("get_connection_info"):
		# Try parent node if current scene doesn't have the method
		board_reference = get_parent().get_parent()
	
	# Get GameManager reference
	game_manager = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	if game_manager:
		game_manager.game_started.connect(_on_game_started)
		game_manager.piece_distributed.connect(_on_pieces_distributed)
		game_manager.piece_played.connect(_on_piece_played)

func add_piece(a: int, b: int):
	print("Adicionando peça [%d,%d] à mão" % [a, b])
	var button = piece_button_scene.instantiate()
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(button)

	await get_tree().process_frame
	button.set_piece_values(a, b, "up")
	button.pressed.connect(func(): _on_piece_selected(button))
	print("Botão da peça [%d,%d] conectado" % [a, b])
	
	var piece_data = {"a": a, "b": b, "dir": "up"}
	hand_pieces.append(piece_data)
	piece_buttons.append(button)

func _on_piece_selected(button):
	var piece_data = button.get_piece_values()
	print("Peça selecionada: [%d,%d]" % [piece_data.a, piece_data.b])
	
	# Verificar se é o turno do jogador humano (só se GameManager estiver ativo)
	if game_manager and game_manager.current_state == 1:  # 1 = PLAYING
		print("GameManager ativo, verificando turno...")
		if not game_manager.is_human_turn():
			show_invalid_move_message(piece_data, "Não é seu turno!")
			return
	else:
		print("Modo fallback (sem GameManager ou jogo não iniciado)")
	
	# Clear previous selection visual
	clear_selection_visual()
	
	# Check if piece can be played and get available sides
	var connection_info = board_reference.get_connection_info(piece_data.a, piece_data.b)
	print("Informação de conexão: ", connection_info)
	
	if not connection_info.can_connect:
		show_invalid_move_message(piece_data, "Esta peça não pode ser jogada!")
		return
	
	# Set visual selection
	selected_button = button
	set_selection_visual(button)
	
	# Determine available placement sides
	var available_sides = get_available_sides(piece_data)
	if available_sides.size() == 0 and game_manager.current_mode == game_manager.GameMode.GATO_COM_LEBRE:
		available_sides.append("left")
		available_sides.append("right")
	print("Lados disponíveis: ", available_sides)
	
	if available_sides.size() == 0:
		show_invalid_move_message(piece_data, "Nenhuma jogada possível!")
		clear_selection_visual()
	elif available_sides.size() == 1:
		print("Apenas um lado disponível, jogando automaticamente...")
		# Only one option, place directly
		await _on_placement_side_selected(available_sides[0], piece_data)
	else:
		print("Múltiplas opções, mostrando UI de seleção...")
		# Multiple options, show placement UI
		if placement_options:
			placement_options.show_options(piece_data, available_sides)
		else:
			print("Erro: placement_options não encontrado!")

func get_available_sides(piece_data: Dictionary) -> Array[String]:
	"""Get available placement sides for a piece"""
	var sides: Array[String] = []
	
	if board_reference.pieces_sequence.is_empty():
		sides.append("first")
		return sides
	
	var left_value = board_reference.left_value
	var right_value = board_reference.right_value
	
	# Check if can connect to left side
	if piece_data.a == left_value or piece_data.b == left_value:
		sides.append("left")
	
	# Check if can connect to right side  
	if piece_data.a == right_value or piece_data.b == right_value:
		sides.append("right")
	
	return sides

func set_selection_visual(button: Control):
	"""Set visual indication for selected piece"""
	if button:
		button.modulate = Color(1.0, 1.0, 0.8, 1.0)  # Yellowish tint

func clear_selection_visual():
	"""Clear visual selection from all buttons"""
	if selected_button:
		selected_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	selected_button = null

func _on_placement_side_selected(side: String, piece_data: Dictionary):
	"""Handle placement side selection"""
	if game_manager and game_manager.current_state == 1:  # 1 = PLAYING state
		var success = await game_manager.play_piece(0, piece_data, side)  # 0 = jogador humano
		if success:
			clear_selection_visual()
		else:
			show_invalid_move_message(piece_data, "Jogada inválida!")
	else:
		# Fallback para modo antigo (sem GameManager ou jogo não iniciado)
		var placement_side = side if side != "first" else ""
		piece_played.emit(piece_data, placement_side)
		clear_selection_visual()

func _on_placement_cancelled():
	"""Handle placement cancellation"""
	clear_selection_visual()

func remove_piece_from_hand(piece_data: Dictionary):
	"""Removes a piece from hand after valid move confirmation"""
	for i in range(hand_pieces.size()):
		var hand_piece = hand_pieces[i]
		if hand_piece.a == piece_data.a and hand_piece.b == piece_data.b:
			# Clear selection if this piece was selected
			if i < piece_buttons.size() and piece_buttons[i] == selected_button:
				clear_selection_visual()
			
			# Remove visual button
			if i < piece_buttons.size():
				var button = piece_buttons[i]
				if is_instance_valid(button):
					button.queue_free()
				piece_buttons.remove_at(i)
			
			# Remove from pieces list
			hand_pieces.remove_at(i)
			break

func show_invalid_move_message(piece_data: Dictionary, custom_message: String = ""):
	"""Shows message when a move is invalid"""
	var message = "JOGADA INVALIDA: Peça [%d,%d] não pode ser colocada no tabuleiro!" % [piece_data.a, piece_data.b]
	print(message)
	
	# Show visual notification
	if invalid_message:
		invalid_message.show_message(message)

func get_hand_count() -> int:
	"""Returns the number of pieces in hand"""
	return hand_pieces.size()

func clear_hand():
	"""Removes all pieces from hand"""
	for button in piece_buttons:
		if is_instance_valid(button):
			button.queue_free()
	
	piece_buttons.clear()
	hand_pieces.clear()

func _setup_ui():
	"""Setup UI elements after the scene is ready"""
	print("Configurando UI do player_hand...")
	
	# Create placement options UI
	placement_options = placement_options_scene.instantiate()
	get_tree().current_scene.add_child(placement_options)
	placement_options.side_selected.connect(_on_placement_side_selected)
	placement_options.placement_cancelled.connect(_on_placement_cancelled)
	print("placement_options criado e conectado")
	
	# Create invalid move message UI
	if invalid_message_scene:
		invalid_message = invalid_message_scene.instantiate() 
		get_tree().current_scene.add_child(invalid_message)
		print("invalid_message criado")
	else:
		print("invalid_message_scene não encontrado")

func _on_game_started():
	"""Limpa a mão quando o jogo inicia"""
	clear_hand()

func _on_pieces_distributed():
	"""Atualiza a mão com as peças do jogador humano"""
	if game_manager:
		var human_player = game_manager.players[0]  # Jogador humano é sempre 0
		update_hand_from_player(human_player)

func update_hand_from_player(player: RefCounted):
	"""Atualiza a UI da mão baseado nas peças do jogador"""
	clear_hand()
	for piece in player.get_hand_pieces():
		add_piece(piece.a, piece.b)

func _on_piece_played(player_id: int, piece: Dictionary):
	"""Chamada quando uma peça é jogada pelo GameManager"""
	if player_id == 0:  # Só remove da UI se for o jogador humano
		print("Removendo peça [%d,%d] da UI após jogada" % [piece.a, piece.b])
		remove_piece_from_hand(piece)

func return_piece_to_hand(player_id: int, piece: Dictionary):
	for player in game_manager.players:
		if player.player_id == player_id:
			print("Retornando peça [%d,%d] à mão do jogador %d" % [piece.a, piece.b, player_id])
			player.add_piece_to_hand(piece)

			if (player_id == 0):
				add_piece(piece.a, piece.b)
				
			game_manager.player_hand_changed.emit(player_id, player.get_hand_count())
