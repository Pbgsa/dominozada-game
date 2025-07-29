# scripts/board.gd
extends Node2D

@onready var played_pieces_container := $PlayedPieces
@onready var offline_game_manager = $GameManager
@export var domino_piece_scene: PackedScene = preload("res://scenes/domino_piece.tscn")

var visual_pieces: Array[Node2D] = []
var left_head_pos := Vector2.ZERO
var right_head_pos := Vector2.ZERO

# --- ADIÇÃO: Variáveis para controlar a lógica visual do tabuleiro ---
var board_left_value := -1
var board_right_value := -1
var board_is_empty := true
# --------------------------------------------------------------------

func _ready():
	var game_manager
	if NetworkManager.is_online_mode:
		game_manager = GameManagerMultiplayer
		game_manager.server_player_is_ready.rpc()
	else:
		game_manager = offline_game_manager

	game_manager.game_started.connect(clear_board)
	game_manager.piece_played_on_board.connect(_on_piece_played_on_board)

# --- CORREÇÃO: Função de posicionamento de peças reescrita ---
func _on_piece_played_on_board(piece_data: Dictionary, side: String, _player_id: int):
	var new_piece_node = domino_piece_scene.instantiate()
	played_pieces_container.add_child(new_piece_node)
	new_piece_node.set_values(piece_data.a, piece_data.b)
	new_piece_node.set_direction("left") # Usa o sprite da peça "deitada"

	var is_double = piece_data.a == piece_data.b
	var rotation_needed = PI / 2 if is_double else 0

	if board_is_empty:
		# Lógica para a primeira peça do jogo
		board_left_value = piece_data.a
		board_right_value = piece_data.b
		board_is_empty = false
		
		new_piece_node.position = Vector2.ZERO
		new_piece_node.rotation = rotation_needed
		
		var piece_width = 40.0 if not is_double else 20.0
		left_head_pos = Vector2(-piece_width, 0)
		right_head_pos = Vector2(piece_width, 0)
		visual_pieces.append(new_piece_node)
	else:
		# Lógica para as peças seguintes
		var connecting_value = board_right_value if side == "right" else board_left_value
		
		# Se o valor 'b' da peça (na ordem {a, b}) é o que conecta,
		# precisamos girar 180 graus para que ela se alinhe corretamente.
		if not is_double and piece_data.b == connecting_value:
			rotation_needed = PI

		# Atualiza os valores lógicos das pontas *neste script*
		var new_head_value = piece_data.a if piece_data.b == connecting_value else piece_data.b
		if side == "right":
			board_right_value = new_head_value
		else:
			board_left_value = new_head_value
			
		# Lógica de cálculo de posição (mantida do original)
		var head_pos = right_head_pos if side == "right" else left_head_pos
		var offset = (40.0 / 2.0) + ( (40.0 if not is_double else 20.0) / 2.0 )
		var direction_vector = Vector2.RIGHT if side == "right" else Vector2.LEFT
		
		new_piece_node.rotation = rotation_needed
		new_piece_node.position = head_pos + (direction_vector * offset)

		var new_head_offset = (40.0 if not is_double else 20.0) / 2.0
		if side == "right":
			right_head_pos = new_piece_node.position + (direction_vector * new_head_offset)
			visual_pieces.append(new_piece_node)
		else:
			left_head_pos = new_piece_node.position + (direction_vector * new_head_offset)
			visual_pieces.push_front(new_piece_node)

# --- CORREÇÃO: Limpa também as variáveis de estado lógico ---
func clear_board():
	for piece_node in visual_pieces:
		if is_instance_valid(piece_node):
			piece_node.queue_free()
	visual_pieces.clear()
	left_head_pos = Vector2.ZERO
	right_head_pos = Vector2.ZERO
	
	# Reseta o estado lógico do tabuleiro visual
	board_left_value = -1
	board_right_value = -1
	board_is_empty = true
