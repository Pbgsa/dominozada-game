extends Control

@onready var top_hand = $TopHand
@onready var left_hand = $LeftHand
@onready var right_hand = $RightHand

var game_manager: Node = null

func _ready():
	# Conectar com o GameManager
	game_manager = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	if game_manager:
		game_manager.player_hand_changed.connect(_on_player_hand_changed)
		game_manager.game_started.connect(_on_game_started)
		game_manager.piece_distributed.connect(_on_pieces_distributed)
	
	# Debug initialization (fallback se GameManager não estiver ativo)
	await get_tree().process_frame  # Wait for hands to be ready
	if not game_manager:
		update_hands({"top": 6, "left": 6, "right": 6})

func update_hands(pieces_by_player: Dictionary):
	# Correct orientations for each position
	if top_hand:
		top_hand.set_piece_count(pieces_by_player.get("top", 0), "up")  # Top uses "up" orientation
	if left_hand:
		left_hand.set_piece_count(pieces_by_player.get("left", 0), "left")  # Left uses "left" orientation
	if right_hand:
		right_hand.set_piece_count(pieces_by_player.get("right", 0), "right")  # Right uses "right" orientation

func _on_player_hand_changed(player_id: int, new_count: int):
	"""Atualiza a mão do oponente quando a quantidade de peças muda"""
	# player_id 0 = jogador humano (não exibido aqui)
	# player_id 1 = oponente do topo
	# player_id 2 = oponente da esquerda  
	# player_id 3 = oponente da direita
	
	match player_id:
		2:  # Top opponent
			if top_hand:
				top_hand.set_piece_count(new_count, "up")
		3:  # Left opponent
			if left_hand:
				left_hand.set_piece_count(new_count, "left")
		1:  # Right opponent
			if right_hand:
				right_hand.set_piece_count(new_count, "right")

func _on_game_started():
	"""Quando o jogo inicia, resetar todas as mãos para 7 peças"""
	update_hands({"top": 7, "left": 7, "right": 7})

func _on_pieces_distributed():
	"""Quando as peças são distribuídas, definir quantidade inicial"""
	if game_manager:
		var top_count = game_manager.players[1].get_hand_count() if game_manager.players.size() > 1 else 7
		var left_count = game_manager.players[2].get_hand_count() if game_manager.players.size() > 2 else 7
		var right_count = game_manager.players[3].get_hand_count() if game_manager.players.size() > 3 else 7
		
		update_hands({"top": top_count, "left": left_count, "right": right_count})
