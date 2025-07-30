extends CanvasLayer

@onready var turn_label := $MainContainer/TurnInfo/TurnLabel
@onready var pass_button := $MainContainer/ActionButtons/PassButton
@onready var buy_button := $MainContainer/ActionButtons/BuyButton
@onready var start_button := $MainContainer/ActionButtons/StartButton
@onready var game_over_panel := $MainContainer/GameOverPanel
@onready var winner_label := $MainContainer/GameOverPanel/GameOverContent/WinnerLabel
@onready var reason_label := $MainContainer/GameOverPanel/GameOverContent/ReasonLabel
@onready var new_game_button := $MainContainer/GameOverPanel/GameOverContent/NewGameButton
@onready var player_hand: HBoxContainer = $CanvasLayer/PlayerHand

var game_manager: Node
var domino_set: RefCounted

func _ready():
	# Conectar ao GameManager
	game_manager = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	domino_set = game_manager.domino_set

	if game_manager:
		game_manager.turn_changed.connect(_on_turn_changed)
		game_manager.game_over.connect(_on_game_over)
		game_manager.game_started.connect(_on_game_started)
		game_manager.player_passed.connect(_on_player_passed)
		game_manager.bot_action_message.connect(_on_bot_action_message)
	
	# Conectar botões
	buy_button.pressed.connect(_on_buy_button_pressed)
	pass_button.pressed.connect(_on_pass_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	
	# UI inicial - permitir inputs passarem através por padrão
	$MainContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	update_ui_state()

func _on_turn_changed(player_id: int):
	"""Atualiza UI quando muda de turno"""
	var player = game_manager.get_current_player()
	if player:
		turn_label.text = "Turno: " + player.player_name
		
		# Habilitar/desabilitar botão de passar baseado no turno
		buy_button.visible = game_manager.is_human_turn()
		buy_button.disabled = not game_manager.is_human_turn()
		pass_button.visible = game_manager.is_human_turn()
		pass_button.disabled = not game_manager.is_human_turn()

func _on_game_over(winner_id: int, reason: String):
	"""Mostra tela de game over"""
	var winner = game_manager.players[winner_id]
	winner_label.text = winner.player_name + " venceu!"
	reason_label.text = reason
	
	game_over_panel.visible = true
	pass_button.visible = false
	buy_button.visible = false
	
	# Quando game over está visível, interceptar inputs para modal
	$MainContainer.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_game_started():
	"""Jogo iniciado"""
	game_over_panel.visible = false
	start_button.visible = false
	update_ui_state()
	
	# Permitir inputs passarem através quando não em game over
	$MainContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_player_passed(player_id: int):
	"""Jogador passou a vez"""
	var player = game_manager.players[player_id]
	if player_id == 0:  # Jogador humano
		show_temporary_message("Você passou a vez")
	else:  # Bot (mas isso será tratado pelo bot_action_message)
		pass  # Mensagem será exibida via bot_action_message

func _on_pass_button_pressed():
	"""Jogador humano passa a vez"""
	if game_manager and game_manager.is_human_turn():
		game_manager.pass_turn(0)  # 0 = jogador humano

func _on_start_button_pressed():
	"""Inicia novo jogo"""
	if game_manager:
		game_manager.start_new_game()

func _on_new_game_button_pressed():
	"""Reinicia o jogo após game over"""
	if game_manager:
		game_manager.start_new_game()
		# Permitir inputs passarem através
		$MainContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
func _on_buy_button_pressed():
	"""Jogador humano compra uma peça do boneyard"""
	if game_manager and game_manager.is_human_turn():
		game_manager.buy_piece()

func update_ui_state():
	"""Atualiza estado geral da UI"""
	var current_state = game_manager.current_state if game_manager else 0  # 0 = MENU
	match current_state:
		0:  # MENU
			buy_button.visible = false
			start_button.visible = true
			pass_button.visible = false
			game_over_panel.visible = false
			turn_label.text = "Pressione Iniciar Jogo"
			# No menu, permitir inputs passarem através
			$MainContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
		1:  # PLAYING
			pass_button.visible = game_manager.is_human_turn()
			start_button.visible = false
			buy_button.visible = game_manager.is_human_turn()
			game_over_panel.visible = false
			# Durante o jogo, permitir inputs passarem através
			$MainContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
		2:  # GAME_OVER
			buy_button.visible = false
			pass_button.visible = false
			game_over_panel.visible = true
			# No game over, interceptar inputs para modal
			$Control.mouse_filter = Control.MOUSE_FILTER_STOP

func show_pass_message(message: String):
	"""Mostra mensagem temporária quando alguém passa"""
	print(message)  # Por enquanto só print, pode implementar UI visual depois

func _on_bot_action_message(message: String):
	"""Mostra mensagem temporária das ações dos bots"""
	show_temporary_message(message)

func show_temporary_message(message: String):
	"""Mostra uma mensagem temporária no canto superior esquerdo"""
	# Criar label temporário se não existir
	var temp_label = get_node_or_null("Control/TempMessage")
	if not temp_label:
		temp_label = Label.new()
		temp_label.name = "TempMessage"
		temp_label.position = Vector2(20, 20)
		temp_label.add_theme_font_size_override("font_size", 16)
		temp_label.add_theme_color_override("font_color", Color.WHITE)
		temp_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		temp_label.add_theme_constant_override("shadow_offset_x", 2)
		temp_label.add_theme_constant_override("shadow_offset_y", 2)
		$MainContainer.add_child(temp_label)
	
	# Configurar mensagem
	temp_label.text = message
	temp_label.visible = true
	
	# Animar fade in
	temp_label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(temp_label, "modulate:a", 1.0, 0.2)
	
	# Aguardar e fade out
	tween.tween_interval(1.0)  # Mensagem visível por 1 segundo
	tween.tween_property(temp_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): temp_label.visible = false)
