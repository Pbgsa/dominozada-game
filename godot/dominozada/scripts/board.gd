extends Node2D

@onready var piece_spawner := $PieceSpawner
@onready var left_head := $Heads/LeftHead
@onready var right_head := $Heads/RightHead

var left_value: int = -1
var right_value: int = -1

func _ready():
	# Spawn one piece for demonstration purposes at the center of the board
	spawn_piece_at(Vector2.ZERO, 0)

func spawn_piece_at(pos: Vector2, index: int):
	var piece_scene = preload("res://scenes/domino_piece_2d.tscn")
	var piece = piece_scene.instantiate()
	piece.position = pos
	piece.set_values(index)
	piece_spawner.add_child(piece)
#dasdas
