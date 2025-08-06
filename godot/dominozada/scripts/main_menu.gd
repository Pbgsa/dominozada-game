extends Control

# A função _ready é chamada quando o nó e seus filhos entram na árvore da cena.
func _ready():
	# Pega todos os nós que estão no grupo "menu_buttons".
	var buttons = get_tree().get_nodes_in_group("menu_buttons")
	for button in buttons:
		# Para cada botão, define o ponto de pivô para o seu centro exato.
		# O tamanho (size) é um Vector2(largura, altura). Dividir por 2 nos dá o centro.
		button.pivot_offset = button.size / 2.0

func _on_botao_modo_classico_pressed() -> void:
	# IMPORTANTE: Substitua "res://..." pelo caminho real da sua cena.
	get_tree().change_scene_to_file("res://scenes/board.tscn")
	pass


func _on_botao_modo_burrinho_pressed() -> void:
	# IMPORTANTE: Substitua "res://..." pelo caminho real da sua cena.
	#get_tree().change_scene_to_file("res://scenes/gameplay/modo_classico.tscn")
	pass


func _on_botao_modo_gato_com_lebre_pressed() -> void:
	# IMPORTANTE: Substitua "res://..." pelo caminho real da sua cena.
	#get_tree().change_scene_to_file("res://scenes/gameplay/modo_classico.tscn")
	pass


func _on_botao_multiplayer_pressed() -> void:
	# IMPORTANTE: Substitua "res://..." pelo caminho real da sua cena.
	#get_tree().change_scene_to_file("res://scenes/gameplay/modo_classico.tscn")
	pass

# Função reutilizável para animar os botões
func _animate_button_scale(button: Button, target_scale: Vector2):
	# Cria uma interpolação (Tween). Um Tween anima uma propriedade ao longo do tempo.
	var tween = create_tween()

	# Queremos uma animação suave. SetTrans(Tween.TRANS_SINE) faz uma curva de aceleração/desaceleração.
	tween.set_trans(Tween.TRANS_SINE)
	
	# O comando principal: animar a propriedade "scale" do 'button'
	# para 'target_scale' durante 0.15 segundos.
	tween.tween_property(button, "scale", target_scale, 0.15)


func _on_botao_modo_classico_mouse_entered() -> void:
	_animate_button_scale($CenterContainer/VBoxContainer/BotaoModoClassico, Vector2(1.1, 1.1))


func _on_botao_modo_classico_mouse_exited() -> void:
	_animate_button_scale($CenterContainer/VBoxContainer/BotaoModoClassico, Vector2(1.0, 1.0))


func _on_botao_modo_burrinho_mouse_entered() -> void:
	_animate_button_scale($CenterContainer/VBoxContainer/BotaoModoBurrinho, Vector2(1.1, 1.1))


func _on_botao_modo_burrinho_mouse_exited() -> void:
	_animate_button_scale($CenterContainer/VBoxContainer/BotaoModoBurrinho, Vector2(1.0, 1.0))


func _on_botao_modo_gato_com_lebre_mouse_entered() -> void:
	_animate_button_scale($CenterContainer/VBoxContainer/BotaoModoGatoComLebre, Vector2(1.1, 1.1))


func _on_botao_modo_gato_com_lebre_mouse_exited() -> void:
	_animate_button_scale($CenterContainer/VBoxContainer/BotaoModoGatoComLebre, Vector2(1.0, 1.0))


func _on_botao_multiplayer_mouse_entered() -> void:
	_animate_button_scale($CenterContainer/VBoxContainer/BotaoMultiplayer, Vector2(1.1, 1.1))


func _on_botao_multiplayer_mouse_exited() -> void:
	_animate_button_scale($CenterContainer/VBoxContainer/BotaoMultiplayer, Vector2(1.0, 1.0))
