extends Node

@export var piece_scene: PackedScene
@export var screen_size := Vector2(1152, 648)  # Ajuste conforme seu projeto
@export var spacing := 90
@export var vertical_spacing := 50

var available_pieces := []
var total_pieces := 27

func _ready():
	available_pieces = range(total_pieces)
	available_pieces.shuffle()

	# Gerar para 4 jogadores: bottom (down), top (up), left, right
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

		var texture_path = "res://assets/textures/domino_pixelart_asset_pack/%s/Domino_%s_%d.png" % [
			direction, direction.capitalize(), (index + 1)
		]
		piece.texture_normal = load(texture_path)

		# Posicionar as peças com base na direção
		var pos := Vector2.ZERO
		match direction:
			"down":
				pos = Vector2(
					screen_size.x / 2 - (amount / 2.0 * spacing) + i * spacing,
					screen_size.y - 100
				)
			"up":
				pos = Vector2(
					screen_size.x / 2 - (amount / 2.0 * spacing) + i * spacing,
					100
				)
			"left":
				pos = Vector2(
					100,
					screen_size.y / 2 - (amount / 2.0 * vertical_spacing) + i * vertical_spacing
				)
			"right":
				pos = Vector2(
					screen_size.x - 100,
					screen_size.y / 2 - (amount / 2.0 * vertical_spacing) + i * vertical_spacing
				)

		piece.position = pos
		add_child(piece)
