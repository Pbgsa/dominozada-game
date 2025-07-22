extends Node2D

@onready var piece_spawner := $PieceSpawner
@onready var left_head := $Heads/LeftHead
@onready var right_head := $Heads/RightHead
@onready var player_hand: HBoxContainer = $CanvasLayer/PlayerHand
@export var logic_node: Node

var left_value: int = -1
var right_value: int = -1

func _ready():
	# Se logic_node não foi atribuído no editor, busque manualmente
	if not logic_node:
		logic_node = get_parent().get_node("Logic")
	player_hand.piece_played.connect(_on_piece_played)
	player_hand.passed_turn.connect(_on_passed_turn)

func _on_piece_played(piece_data: Dictionary):
	if logic_node:
		print("Emitting piece_played signal with data:", piece_data)
		logic_node.on_piece_played(piece_data)

func _on_passed_turn():
	print("Jogador passou a vez")
