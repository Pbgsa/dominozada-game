# scripts/player_hand.gd
extends HBoxContainer

@onready var piece_button_scene: PackedScene = preload("res://scenes/domino_piece_button.tscn")
@export var placement_options_scene: PackedScene = preload("res://scenes/placement_options.tscn")

var piece_buttons: Array[Button] = []
var placement_options_instance: CanvasLayer
var game_manager

func _ready():
	placement_options_instance = placement_options_scene.instantiate()
	add_child(placement_options_instance)
	placement_options_instance.side_selected.connect(_on_placement_side_selected)
	
	if NetworkManager.is_online_mode:
		game_manager = GameManagerMultiplayer
	else:
		game_manager = get_node("/root/Board/GameManager")

	game_manager.hand_updated.connect(_on_hand_updated)
	game_manager.game_started.connect(clear_hand)
	game_manager.piece_played_on_board.connect(_on_piece_played_on_board)

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
	var valid_sides = game_manager.get_valid_sides_for_piece(piece_data)
	
	if valid_sides.is_empty():
		# Debug: Mostrar informações das cabeças jogáveis
		print("Essa peça [%d,%d] não pode ser jogada." % [piece_data.a, piece_data.b])
		return
	elif valid_sides.size() == 1:
		_on_placement_side_selected(valid_sides[0], piece_data)
	else:
		placement_options_instance.show_options(piece_data, valid_sides)

func _on_placement_side_selected(side: String, piece_data: Dictionary):
	if NetworkManager.is_online_mode:
		game_manager.server_play_piece.rpc(piece_data, side)
	else:
		game_manager.play_piece(piece_data, side)

func _on_piece_played_on_board(piece_data: Dictionary, _side: String, player_id: int):
	var my_id = 1
	if NetworkManager.is_online_mode:
		my_id = multiplayer.get_unique_id()
	
	if player_id == my_id:
		for i in range(piece_buttons.size()):
			var button = piece_buttons[i]
			if not is_instance_valid(button): continue
			
			var button_piece_data = button.get_meta("piece_data")
			if button_piece_data.a == piece_data.a and button_piece_data.b == piece_data.b:
				piece_buttons.remove_at(i)
				button.queue_free()
				return

func clear_hand():
	for button in piece_buttons:
		if is_instance_valid(button):
			button.queue_free()
	piece_buttons.clear()
