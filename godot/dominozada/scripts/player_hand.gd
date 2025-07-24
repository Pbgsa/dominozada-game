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

signal piece_played(piece_data: Dictionary, placement_side: String)
signal passed_turn()

func _ready():
	# Create UI elements using deferred call to avoid busy parent error
	call_deferred("_setup_ui")
	
	# Get board reference - try different paths
	board_reference = get_tree().current_scene
	if not board_reference.has_method("get_connection_info"):
		# Try parent node if current scene doesn't have the method
		board_reference = get_parent().get_parent()
	
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
	
	# Clear previous selection visual
	clear_selection_visual()
	
	# Check if piece can be played and get available sides
	var connection_info = board_reference.get_connection_info(piece_data.a, piece_data.b)
	
	if not connection_info.can_connect:
		show_invalid_move_message(piece_data)
		return
	
	# Set visual selection
	selected_button = button
	set_selection_visual(button)
	
	# Determine available placement sides
	var available_sides = get_available_sides(piece_data)
	
	if available_sides.size() == 0:
		show_invalid_move_message(piece_data)
		clear_selection_visual()
	elif available_sides.size() == 1:
		# Only one option, place directly
		_on_placement_side_selected(available_sides[0], piece_data)
	else:
		# Multiple options, show placement UI
		placement_options.show_options(piece_data, available_sides)

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
	# Convert "first" to empty string for board compatibility
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

func show_invalid_move_message(piece_data: Dictionary):
	"""Shows message when a move is invalid"""
	var message = "❌ INVALID MOVE: Piece [%d,%d] cannot be placed on the board!" % [piece_data.a, piece_data.b]
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
	# Create placement options UI
	placement_options = placement_options_scene.instantiate()
	get_tree().current_scene.add_child(placement_options)
	placement_options.side_selected.connect(_on_placement_side_selected)
	placement_options.placement_cancelled.connect(_on_placement_cancelled)
	
	# Create invalid move message UI
	if invalid_message_scene:
		invalid_message = invalid_message_scene.instantiate() 
		get_tree().current_scene.add_child(invalid_message)
