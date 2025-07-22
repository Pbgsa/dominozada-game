extends HBoxContainer

@onready var piece_button_scene: PackedScene = preload("res://scenes/domino_piece_button.tscn")

var hand_pieces: Array[Dictionary] = []  # [{a: int, b: int, dir: String}]
var piece_buttons: Array[Control] = []  # References to piece buttons

signal piece_played(piece_data: Dictionary)
signal passed_turn()

func _ready():
	# Fixed pieces for testing
	var test_hand = [
		{ "a": 6, "b": 6 },
		{ "a": 6, "b": 5 },
		{ "a": 5, "b": 2 },
		{ "a": 2, "b": 1 },
		{ "a": 1, "b": 3 },
		{ "a": 6, "b": 4 },
		{ "a": 4, "b": 5 },
	]
	for piece in test_hand:
		add_piece(piece.a, piece.b)

func add_piece(a: int, b: int):
	var button = piece_button_scene.instantiate()
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(button)

	await get_tree().process_frame
	button.set_piece_values(a, b, "up")
	button.pressed.connect(func(): _on_piece_selected(button))
	
	var piece_data = {"a": a, "b": b, "dir": "up"}
	hand_pieces.append(piece_data)
	piece_buttons.append(button)

func _on_piece_selected(button):
	var piece_data = button.get_piece_values()
	
	# Check if piece can be played before emitting signal
	# Board will validate and return if move was accepted
	piece_played.emit(piece_data)
	
	# Don't remove piece immediately - wait for board confirmation

func remove_piece_from_hand(piece_data: Dictionary):
	"""Removes a piece from hand after valid move confirmation"""
	for i in range(hand_pieces.size()):
		var hand_piece = hand_pieces[i]
		if hand_piece.a == piece_data.a and hand_piece.b == piece_data.b:
			# Remove visual button
			if i < piece_buttons.size():
				var button = piece_buttons[i]
				if is_instance_valid(button):
					button.queue_free()
				piece_buttons.remove_at(i)
			
			# Remove from pieces list
			hand_pieces.remove_at(i)
			break

func show_invalid_move_message(piece_data: Dictionary):
	"""Shows message when a move is invalid"""
	print("❌ INVALID MOVE: Piece [%d,%d] cannot be placed on the board!" % [piece_data.a, piece_data.b])

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
