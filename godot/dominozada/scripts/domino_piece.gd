extends Node2D

@export var value_a: int = 0
@export var value_b: int = 0
@export var index: int = 1
@export var direction: String = "up"

@onready var sprite: Sprite2D = $DominoSprite

func _ready():
	pass

func set_values(a: int, b: int):
	value_a = a
	value_b = b
	index = get_piece_index(a, b)

func set_direction(dir: String):
	direction = dir
	update_sprite()  # Update the sprite based on the new direction

func update_sprite():
	var dir_cap = direction.capitalize()
	var path = "res://assets/textures/domino_pixelart_asset_pack/%s/Domino_%s_%d.png" % [direction, dir_cap, index]
	if sprite and sprite is Sprite2D:
		sprite.texture = load(path)
	sprite.centered = true

func get_piece_index(a: int, b: int) -> int:
	var min_val = min(a, b)
	var max_val = max(a, b)
	var count = 1
	for i in range(0, 7):
		for j in range(i, 7):
			if i == min_val and j == max_val:
				return count
			count += 1
	return 1  # Fallback para 0-0
