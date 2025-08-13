extends Button

@onready var piece_node: Node2D = $DominoPiece

# Create hover sound effect player
var hover_audio: AudioStreamPlayer

func _ready():
	# Create audio player for hover sound
	hover_audio = AudioStreamPlayer.new()
	add_child(hover_audio)
	
	# Load the hover sound and configure it
	var hover_sound = load("res://assets/sounds/mouse_over_piece.wav") as AudioStreamWAV
	if hover_sound:
		hover_sound.loop_mode = AudioStreamWAV.LOOP_DISABLED
		hover_audio.stream = hover_sound
		hover_audio.volume_db = -15.0  # Quieter than piece placement sound
		hover_audio.autoplay = false
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	if not disabled:
		modulate = Color(1.2, 1.2, 1.2, 1.0)
		# Play hover sound effect
		if hover_audio and hover_audio.stream:
			hover_audio.stop()  # Stop any previous playback
			hover_audio.play() 
	
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
