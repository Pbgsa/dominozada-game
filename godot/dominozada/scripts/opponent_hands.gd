extends Control

@onready var top_hand = $TopHand
@onready var left_hand = $LeftHand
@onready var right_hand = $RightHand

func _ready():
	# Debug initialization
	await get_tree().process_frame  # Wait for hands to be ready
	update_hands({"top": 6, "left": 6, "right": 6})

func update_hands(pieces_by_player: Dictionary):
	# Correct orientations for each position
	if top_hand:
		top_hand.set_piece_count(pieces_by_player.get("top", 0), "up")  # Top uses "up" orientation
	if left_hand:
		left_hand.set_piece_count(pieces_by_player.get("left", 0), "left")  # Left uses "left" orientation
	if right_hand:
		right_hand.set_piece_count(pieces_by_player.get("right", 0), "right")  # Right uses "right" orientation
