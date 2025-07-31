extends Button

@onready var piece_node: Node2D = $DominoPiece

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	if not disabled:
		modulate = Color(1.2, 1.2, 1.2, 1.0) 
	
func _on_mouse_exited():
	if not disabled:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func set_piece_values(a: int, b: int, dir: String):
	# --- ESTA É A CORREÇÃO ---
	# 1. PRIMEIRO, definimos os valores da peça. Isso calcula o índice correto do sprite.
	if piece_node.has_method("set_values"):
		piece_node.set_values(a, b)
		
	# 2. DEPOIS, definimos a direção. Isso chama update_sprite(), que agora usará o
	#    índice correto para carregar a imagem da peça virada para cima.
	if piece_node.has_method("set_direction"):
		piece_node.set_direction(dir)

func get_piece_values() -> Dictionary:
	return {
		"a": piece_node.value_a,
		"b": piece_node.value_b,
		"dir": piece_node.direction
	}
