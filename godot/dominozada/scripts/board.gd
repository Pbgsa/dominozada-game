extends Node2D

@onready var piece_spawner := $PieceSpawner
@onready var left_head := $Heads/LeftHead
@onready var right_head := $Heads/RightHead
@onready var player_hand: HBoxContainer = $CanvasLayer/PlayerHand

var left_value: int = -1
var right_value: int = -1

func _ready():
	player_hand.piece_played.connect(_on_piece_played)
	player_hand.passed_turn.connect(_on_passed_turn)

func _on_piece_played(piece_data: Dictionary):
	print("Jogador jogou:", piece_data)

func _on_passed_turn():
	print("Jogador passou a vez")
