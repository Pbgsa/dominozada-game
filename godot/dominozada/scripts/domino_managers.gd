extends Node

@export var piece_scene: PackedScene
@export var screen_size := Vector2(1152, 648)
@export var spacing := 90
@export var vertical_spacing := 50

var available_pieces := []
var total_pieces := 28

func _ready():
	available_pieces = range(total_pieces)
	available_pieces.shuffle()

	spawn_player_pieces("down", 6)
	spawn_player_pieces("up", 6)
	spawn_player_pieces("left", 6)
	spawn_player_pieces("right", 6)

func spawn_player_pieces(direction: String, amount: int):
	for i in range(amount):
		if available_pieces.is_empty():
			break
		var index = available_pieces.pop_front()
		var piece = piece_scene.instantiate()
		
		piece.piece_index = index  # De 0 a 27
		piece.current_direction_index = piece.directions.find(direction)

		var texture_path = "res://assets/textures/domino_pixelart_asset_pack/%s/Domino_%s_%d.png" % [
			direction, direction.capitalize(), (index + 1)
		]

		var sprite := piece.find_child("domino_piece", true, false)
		if sprite and sprite is Sprite2D:
			sprite.texture = load(texture_path)
		else:
			push_error("Sprite2D 'domino_piece' not found or wrong type.")

		var pos := Vector2.ZERO
		match direction:
			"down":
				pos = Vector2(screen_size.x / 2 - (amount / 2.0 * spacing) + i * spacing, screen_size.y - 100)
			"up":
				pos = Vector2(screen_size.x / 2 - (amount / 2.0 * spacing) + i * spacing, 100)
			"left":
				pos = Vector2(100, screen_size.y / 2 - (amount / 2.0 * vertical_spacing) + i * vertical_spacing)
			"right":
				pos = Vector2(screen_size.x - 100, screen_size.y / 2 - (amount / 2.0 * vertical_spacing) + i * vertical_spacing)
		
		piece.rotate_colision_area(direction)
		piece.position = pos
		add_child(piece)
