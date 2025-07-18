extends HBoxContainer

@onready var piece_button_scene: PackedScene = preload("res://scenes/domino_piece_button.tscn")

var hand_pieces: Array[Dictionary] = []  # [{a: int, b: int, dir: String}]

signal piece_played(piece_data: Dictionary)
signal passed_turn()

func _ready():
	# Placeholder 
	for i in range(6):
		var a = randi() % 7
		var b = randi() % 7
		add_piece(a, b)

func add_piece(a: int, b: int):
	var button = piece_button_scene.instantiate()
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(button)

	await get_tree().process_frame
	button.set_piece_values(a, b, "up")
	button.pressed.connect(func(): _on_piece_selected(button))
	hand_pieces.append({"a": a, "b": b, "dir": "up"})

func _on_piece_selected(button):
	var piece_data = button.get_piece_values()
	piece_played.emit(piece_data)
	button.queue_free()
	hand_pieces.erase(piece_data)
