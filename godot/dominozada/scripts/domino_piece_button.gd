extends Button

@onready var piece_node: Node2D = $DominoPiece

func _ready():
	# Connect mouse enter and exit signals for visual feedback
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	# Only apply effect if the button is not disabled
	if not disabled:
		modulate = Color(1.2, 1.2, 1.2, 1.0) 
	
func _on_mouse_exited():
	# Remove the effect when the mouse leaves
	if not disabled:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func set_piece_values(a: int, b: int, dir: String):
	if piece_node == null:
		piece_node = $DominoPiece
	
	if piece_node != null:
		piece_node.set_values(a, b)
		piece_node.set_direction(dir)
	else:
		print("Erro: Piece not found!")

func get_piece_values() -> Dictionary:
	if piece_node == null:
		piece_node = $DominoPiece
	
	if piece_node != null:
		return {
			"a": piece_node.value_a,
			"b": piece_node.value_b,
			"dir": piece_node.direction
		}
	else:
		print("Erro: Piece not found!")
		return {"a": 0, "b": 0, "dir": "up"}
