# scripts/domino_piece.gd
extends Node2D

@export var value_a: int = 0
@export var value_b: int = 0
@export var index: int = 1
@export var direction: String = "up"

@onready var sprite: Sprite2D = $DominoSprite

func set_values(a: int, b: int):
	value_a = a
	value_b = b
	index = get_piece_index(a, b)
	# A direção será definida quando a peça for colocada na mão ou no tabuleiro
	# então a atualização do sprite ocorrerá lá.

func set_direction(dir: String):
	direction = dir
	update_sprite()

func update_sprite():
	if not sprite: return
	var dir_cap = direction.capitalize()
	var path = "res://assets/textures/domino_pixelart_asset_pack/%s/Domino_%s_%d.png" % [direction, dir_cap, index]
	var texture = load(path)
	if texture:
		sprite.texture = texture
	else:
		print("Falha ao carregar textura: ", path)
	sprite.centered = true

func get_piece_index(a: int, b: int) -> int:
	# Lógica do seu projeto original para garantir compatibilidade
	if a < 0 or b < 0:
		return 0
	var min_val = min(a, b)
	var max_val = max(a, b)
	var count = 1
	for i in range(0, 7):
		for j in range(i, 7):
			if i == min_val and j == max_val:
				return count
			count += 1
	return 1
