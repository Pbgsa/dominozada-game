extends Node2D

@onready var piece_scene = preload("res://scenes/domino_piece.tscn")

func _ready():
	for i in range(4):  # Instanciar 4 peças como exemplo
		var piece = piece_scene.instantiate()
		piece.position = Vector2(150 + i * 80, 500)
		add_child(piece)
