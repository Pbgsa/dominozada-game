extends CanvasLayer

@onready var turn_label := $Control/TurnInfo/TurnLabel
@onready var pass_button := $Control/ActionButtons/PassButton
@onready var start_button := $Control/ActionButtons/StartButton
@onready var game_over_panel := $Control/GameOverPanel
@onready var winner_label := $Control/GameOverPanel/VBox/WinnerLabel
@onready var reason_label := $Control/GameOverPanel/VBox/ReasonLabel
@onready var new_game_button := $Control/GameOverPanel/VBox/NewGameButton

var game_manager: Node

func _ready():
	# Conectar ao GameManager
	game_manager = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	
	if game_manager:
		game_manager.turn_changed.connect(_on_turn_changed)
		game_manager.game_over.connect(_on_game_over)
		game_manager.game_started.connect(_on_game_started)
		game_manager.player_passed.connect(_on_player_passed)
	
	# Conectar botões
	pass_button.pressed.connect(_on_pass_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	
	# UI inicial - permitir inputs passarem através por padrão
	$Control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	update_ui_state()

func _on_turn_changed(player_id: int):
	"""Atualiza UI quando muda de turno"""
	var player = game_manager.get_current_player()
	if player:
		turn_label.text = "Turno: " + player.player_name
		
		# Habilitar/desabilitar botão de passar baseado no turno
		pass_button.visible = game_manager.is_human_turn()
		pass_button.disabled = not game_manager.is_human_turn()

func _on_game_over(winner_id: int, reason: String):
	"""Mostra tela de game over"""
	var winner = game_manager.players[winner_id]
	winner_label.text = winner.player_name + " venceu!"
	reason_label.text = reason
	
	game_over_panel.visible = true
	pass_button.visible = false
	
	# Quando game over está visível, interceptar inputs para modal
	$Control.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_game_started():
	"""Jogo iniciado"""
	game_over_panel.visible = false
	start_button.visible = false
	update_ui_state()
	
	# Permitir inputs passarem através quando não em game over
	$Control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_player_passed(player_id: int):
	"""Jogador passou a vez"""
	var player = game_manager.players[player_id]
	show_pass_message(player.player_name + " passou a vez!")

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
		$Control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func update_ui_state():
	"""Atualiza estado geral da UI"""
	var current_state = game_manager.current_state if game_manager else 0  # 0 = MENU
	match current_state:
		0:  # MENU
			start_button.visible = true
			pass_button.visible = false
			game_over_panel.visible = false
			turn_label.text = "Pressione Iniciar Jogo"
			# No menu, permitir inputs passarem através
			$Control.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
		1:  # PLAYING
			start_button.visible = false
			pass_button.visible = game_manager.is_human_turn()
			game_over_panel.visible = false
			# Durante o jogo, permitir inputs passarem através
			$Control.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
		2:  # GAME_OVER
			pass_button.visible = false
			game_over_panel.visible = true
			# No game over, interceptar inputs para modal
			$Control.mouse_filter = Control.MOUSE_FILTER_STOP

func show_pass_message(message: String):
	"""Mostra mensagem temporária quando alguém passa"""
	print(message)  # Por enquanto só print, pode implementar UI visual depois
