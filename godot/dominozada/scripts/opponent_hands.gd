# scripts/opponent_hands.gd
extends Control

@onready var top_hand = $TopHand
@onready var left_hand = $LeftHand
@onready var right_hand = $RightHand

var ui_map: Dictionary = {}
var game_manager

func _ready():
	if NetworkManager.is_online_mode:
		game_manager = GameManagerMultiplayer
	else:
		game_manager = get_node("/root/Board/GameManager")

	game_manager.game_started.connect(_on_game_started)
	game_manager.player_hand_count_changed.connect(_on_player_hand_count_changed)

func _on_game_started():
	var my_id = 1 # No offline, nosso ID é sempre 1
	if NetworkManager.is_online_mode:
		my_id = multiplayer.get_unique_id()
	
	var all_players = game_manager.turn_order.duplicate()
	all_players.erase(my_id)
	
	if all_players.size() > 0: ui_map[all_players[0]] = top_hand
	if all_players.size() > 1: ui_map[all_players[1]] = left_hand
	if all_players.size() > 2: ui_map[all_players[2]] = right_hand
	
	top_hand.set_piece_count(7, "up")
	left_hand.set_piece_count(7, "left")
	right_hand.set_piece_count(7, "right")


func _on_player_hand_count_changed(player_id: int, new_count: int):
	var my_id = 1
	if NetworkManager.is_online_mode:
		my_id = multiplayer.get_unique_id()
		
	if player_id == my_id:
		return

	if ui_map.has(player_id):
		var hand_node = ui_map[player_id]
		var direction = "up"
		if hand_node == left_hand: direction = "left"
		if hand_node == right_hand: direction = "right"
		
		hand_node.set_piece_count(new_count, direction)
