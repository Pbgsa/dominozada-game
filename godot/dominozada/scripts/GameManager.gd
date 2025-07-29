# res://scripts/GameManager.gd
extends Node

signal game_started
signal hand_updated(my_hand)
signal player_hand_count_changed(player_id, count)
signal turn_changed(player_id)
signal piece_played_on_board(piece_data, side, player_id)
signal game_over(winner_id, reason)

var domino_set = DominoSet.new()
var players = {
	1: {"name": "Jogador", "hand": [], "is_bot": false},
	2: {"name": "Bot 1", "hand": [], "is_bot": true},
	3: {"name": "Bot 2", "hand": [], "is_bot": true},
	4: {"name": "Bot 3", "hand": [], "is_bot": true},
}
var turn_order = [1, 2, 3, 4]
var current_turn_index = 0
var board_left_value := -1
var board_right_value := -1
var board_is_empty := true
var passes_in_a_row := 0

func _ready():
	start_new_game()

func start_new_game():
	domino_set.generate_full_set()
	domino_set.shuffle()
	for i in turn_order:
		players[i].hand.clear()
		for _j in range(7):
			players[i].hand.append(domino_set.draw_piece())
	hand_updated.emit.call_deferred(players[1].hand)
	for i in turn_order:
		player_hand_count_changed.emit(i, players[i].hand.size())
	board_is_empty = true
	board_left_value = -1
	board_right_value = -1
	passes_in_a_row = 0
	game_started.emit()
	turn_changed.emit(turn_order[current_turn_index])

func play_piece(piece_data: Dictionary, side: String):
	var valid_sides = get_valid_sides_for_piece(piece_data)
	if not side in valid_sides: return
	
	for i in range(players[1].hand.size()):
		var p = players[1].hand[i]
		if p.a == piece_data.a and p.b == piece_data.b:
			players[1].hand.remove_at(i)
			break
			
	_update_board_state(piece_data, side)
	piece_played_on_board.emit(piece_data, side, 1)
	player_hand_count_changed.emit(1, players[1].hand.size())
	passes_in_a_row = 0
	
	if players[1].hand.is_empty():
		game_over.emit(1, "Você não tem mais peças!")
	else:
		_next_turn()

func get_valid_sides_for_piece(piece_data: Dictionary) -> Array[String]:
	var valid_sides: Array[String] = []
	if board_is_empty: return ["left"]
	
	# CORREÇÃO: Usando os nomes corretos das variáveis
	if piece_data.a == board_left_value or piece_data.b == board_left_value:
		valid_sides.append("left")
	
	if board_left_value == board_right_value and piece_data.a == piece_data.b: return valid_sides
	
	# CORREÇÃO: Usando os nomes corretos das variáveis
	if piece_data.a == board_right_value or piece_data.b == board_right_value:
		valid_sides.append("right")
		
	return valid_sides

func pass_turn():
	passes_in_a_row += 1
	if passes_in_a_row >= 4:
		game_over.emit(-1, "Jogo travado! Ninguém pode jogar.")
	else:
		_next_turn()

func _update_board_state(piece_data: Dictionary, side: String):
	# CORREÇÃO: Usando os nomes corretos das variáveis
	var connecting_value = board_left_value if side == "left" else board_right_value
	if board_is_empty:
		board_left_value = piece_data.a
		board_right_value = piece_data.b
		board_is_empty = false
	else:
		var new_head = piece_data.b if piece_data.a == connecting_value else piece_data.a
		if side == "left":
			board_left_value = new_head
		else:
			board_right_value = new_head

func _next_turn():
	current_turn_index = (current_turn_index + 1) % turn_order.size()
	var current_player_id = turn_order[current_turn_index]
	turn_changed.emit(current_player_id)
	if players[current_player_id].is_bot:
		get_tree().create_timer(1.0).timeout.connect(func(): _execute_bot_turn(current_player_id))

func _execute_bot_turn(bot_id: int):
	var bot_hand = players[bot_id].hand
	for piece in bot_hand:
		var valid_sides = get_valid_sides_for_piece(piece)
		if not valid_sides.is_empty():
			var side_to_play = valid_sides[0]
			_update_board_state(piece, side_to_play)
			piece_played_on_board.emit(piece, side_to_play, bot_id)
			bot_hand.erase(piece)
			player_hand_count_changed.emit(bot_id, bot_hand.size())
			passes_in_a_row = 0
			if bot_hand.is_empty():
				game_over.emit(bot_id, "O Bot %d venceu!" % bot_id)
			else:
				_next_turn()
			return
	pass_turn()
