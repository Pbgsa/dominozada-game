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
	
	if all_players.size() > 0: 
		ui_map[all_players[0]] = top_hand
		_update_opponent_label(top_hand, all_players[0])
	if all_players.size() > 1: 
		ui_map[all_players[1]] = left_hand  
		_update_opponent_label(left_hand, all_players[1])
	if all_players.size() > 2: 
		ui_map[all_players[2]] = right_hand
		_update_opponent_label(right_hand, all_players[2])

func _update_opponent_label(hand_node: Node, player_id: int):
	"""Atualiza o label do oponente com o nome do jogador"""
	var player_name = "Jogador " + str(player_id)
	
	if NetworkManager.is_online_mode and player_id in NetworkManager.players:
		player_name = NetworkManager.players[player_id]
	elif not NetworkManager.is_online_mode and game_manager and "players" in game_manager:
		if player_id in game_manager.players:
			var player_data = game_manager.players[player_id]
			if typeof(player_data) == TYPE_DICTIONARY and "name" in player_data:
				player_name = player_data.name
			elif player_data.has_method("get") and "player_name" in player_data:
				player_name = player_data.player_name
	
	# Tentar encontrar um label filho do hand_node para mostrar o nome
	if hand_node.has_method("set_player_name"):
		hand_node.set_player_name(player_name)
	elif hand_node.get_child_count() > 0:
		# Procurar por um Label nos filhos
		for child in hand_node.get_children():
			if child is Label:
				child.text = player_name
				break


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
