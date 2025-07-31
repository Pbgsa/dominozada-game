# scripts/game_ui.gd
extends CanvasLayer

@onready var turn_label := $MainContainer/TurnInfo/TurnLabel
@onready var pass_button := $MainContainer/ActionButtons/PassButton
@onready var start_button := $MainContainer/ActionButtons/StartButton if has_node("MainContainer/ActionButtons/StartButton") else null
@onready var game_over_panel := $MainContainer/GameOverPanel
@onready var winner_label := $MainContainer/GameOverPanel/GameOverContent/WinnerLabel
@onready var reason_label := $MainContainer/GameOverPanel/GameOverContent/ReasonLabel
@onready var new_game_button := $MainContainer/GameOverPanel/GameOverContent/NewGameButton if has_node("MainContainer/GameOverPanel/GameOverContent/NewGameButton") else null

var game_manager: Node

func _ready():
	# Conectar ao GameManager apropriado baseado no modo
	if NetworkManager.is_online_mode:
		game_manager = GameManagerMultiplayer
	else:
		# Tentar diferentes caminhos para encontrar o GameManager offline
		game_manager = get_node("/root/Board/GameManager") if has_node("/root/Board/GameManager") else null
		if not game_manager:
			game_manager = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	
	if game_manager:
		# Conectar sinais comuns a ambos os modos
		game_manager.turn_changed.connect(_on_turn_changed)
		game_manager.game_over.connect(_on_game_over)
		game_manager.game_started.connect(_on_game_started)
		
		# Conectar sinais específicos do modo offline (se existirem)
		if not NetworkManager.is_online_mode and game_manager.has_signal("player_passed"):
			game_manager.player_passed.connect(_on_player_passed)
		if not NetworkManager.is_online_mode and game_manager.has_signal("bot_action_message"):
			game_manager.bot_action_message.connect(_on_bot_action_message)
	
	# Conectar botões
	pass_button.pressed.connect(_on_pass_button_pressed)
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_button_pressed)
	
	# UI inicial - permitir inputs passarem através por padrão
	if has_node("MainContainer"):
		$MainContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Configurar estado inicial
	game_over_panel.visible = false
	pass_button.visible = false
	turn_label.text = "Aguardando início do jogo..."
	
	# Configurar botões baseado no modo
	if NetworkManager.is_online_mode:
		if start_button:
			start_button.visible = false  # No multiplayer, o host controla o início
	else:
		update_ui_state()

func _on_turn_changed(player_id: int):
	"""Atualiza UI quando muda de turno - compatível com ambos os modos"""
	var my_id = 1
	if NetworkManager.is_online_mode:
		my_id = multiplayer.get_unique_id()
		
	if player_id == my_id:
		turn_label.text = "É a sua vez!"
		pass_button.disabled = false
		pass_button.visible = true
	else:
		var player_name = "Jogador " + str(player_id)
		
		# Tentar obter nome mais descritivo baseado no modo
		if NetworkManager.is_online_mode:
			# No modo multiplayer, usar informações do NetworkManager se disponível
			if player_id in NetworkManager.players:
				player_name = NetworkManager.players[player_id]
		else:
			# No modo offline, usar informações do GameManager
			if game_manager and game_manager.has_method("get_current_player"):
				var current_player = game_manager.get_current_player()
				if current_player and current_player.has_method("get") and "player_name" in current_player:
					player_name = current_player.player_name
			elif game_manager and "players" in game_manager and player_id in game_manager.players:
				player_name = game_manager.players[player_id].name
		
		turn_label.text = "Vez de: " + player_name
		pass_button.disabled = true
		pass_button.visible = true

func _on_game_over(winner_id: int, reason: String):
	"""Mostra tela de game over - compatível com ambos os modos"""
	# print("DEBUG GAME_UI: Game over recebido - Winner ID: %d, Reason: %s" % [winner_id, reason])
	
	if winner_id == -1:
		winner_label.text = "Empate!"
	else:
		var winner_name = "Jogador " + str(winner_id)
		
		# Tentar obter nome mais descritivo baseado no modo
		if NetworkManager.is_online_mode:
			if winner_id in NetworkManager.players:
				winner_name = NetworkManager.players[winner_id]
				# print("DEBUG GAME_UI: Nome do vencedor encontrado no NetworkManager: %s" % winner_name)
			# else:
				# print("DEBUG GAME_UI: Winner ID %d não encontrado no NetworkManager.players: %s" % [winner_id, NetworkManager.players])
		else:
			# No modo offline, usar informações do GameManager
			if game_manager and "players" in game_manager and winner_id in game_manager.players:
				if typeof(game_manager.players[winner_id]) == TYPE_DICTIONARY:
					winner_name = game_manager.players[winner_id].name
				else:
					winner_name = game_manager.players[winner_id].player_name if "player_name" in game_manager.players[winner_id] else winner_name
		
		# Verificar se a razão já contém o nome do vencedor
		if winner_name in reason:
			winner_label.text = "Vencedor!"
		else:
			winner_label.text = winner_name + " venceu!"
	
	reason_label.text = reason
	game_over_panel.visible = true
	pass_button.visible = false
	
	# print("DEBUG GAME_UI: Game over configurado - Winner: '%s', Reason: '%s'" % [winner_label.text, reason_label.text])
	
	# Quando game over está visível, interceptar inputs para modal
	if has_node("MainContainer"):
		$MainContainer.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_game_started():
	"""Jogo iniciado - compatível com ambos os modos"""
	game_over_panel.visible = false
	if start_button:
		start_button.visible = false
	
	# Permitir inputs passarem através quando não em game over
	if has_node("MainContainer"):
		$MainContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Atualizar estado da UI no modo offline
	if not NetworkManager.is_online_mode:
		update_ui_state()

func _on_player_passed(player_id: int):
	"""Jogador passou a vez - apenas modo offline"""
	if NetworkManager.is_online_mode:
		return
		
	var player_name = "Jogador " + str(player_id)
	if game_manager and "players" in game_manager and player_id in game_manager.players:
		player_name = game_manager.players[player_id].name if typeof(game_manager.players[player_id]) == TYPE_DICTIONARY else game_manager.players[player_id].player_name
	
	if player_id == 1:  # Jogador humano (ID 1 no sistema atual)
		show_temporary_message("Você passou a vez")
	else:
		show_temporary_message(player_name + " passou a vez")

func _on_pass_button_pressed():
	"""Jogador passa a vez - compatível com ambos os modos"""
	if NetworkManager.is_online_mode:
		game_manager.server_pass_turn.rpc()
	else:
		# Modo offline - usar função de passar do GameManager
		if game_manager.has_method("pass_turn_advanced"):
			var current_player_id = game_manager.get_current_player_id() if game_manager.has_method("get_current_player_id") else 1
			game_manager.pass_turn_advanced(current_player_id)
		else:
			game_manager.pass_turn()

	pass_button.disabled = true

func _on_start_button_pressed():
	"""Inicia novo jogo - apenas modo offline"""
	if NetworkManager.is_online_mode:
		return  # No multiplayer, o host controla o início
		
	if game_manager:
		game_manager.start_new_game()

func _on_new_game_button_pressed():
	"""Reinicia o jogo após game over - compatível com ambos os modos"""
	if NetworkManager.is_online_mode:
		# No multiplayer, apenas o host pode iniciar um novo jogo
		if multiplayer.is_server():
			game_manager.host_requests_start_game()
	else:
		if game_manager:
			game_manager.start_new_game()
			# Permitir inputs passarem através
			if has_node("MainContainer"):
				$MainContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE

func update_ui_state():
	"""Atualiza estado geral da UI - apenas modo offline"""
	if NetworkManager.is_online_mode:
		return
		
	if not game_manager or not game_manager.has_method("get") or not "current_state" in game_manager:
		return
		
	var current_state = game_manager.current_state
	match current_state:
		0:  # MENU
			if start_button:
				start_button.visible = true
			pass_button.visible = false
			game_over_panel.visible = false
			turn_label.text = "Pressione Iniciar Jogo"
			# No menu, permitir inputs passarem através
			if has_node("MainContainer"):
				$MainContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
		1:  # PLAYING
			if start_button:
				start_button.visible = false
			pass_button.visible = game_manager.is_human_turn() if game_manager.has_method("is_human_turn") else true
			game_over_panel.visible = false
			# Durante o jogo, permitir inputs passarem através
			if has_node("MainContainer"):
				$MainContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
		2:  # GAME_OVER
			pass_button.visible = false
			game_over_panel.visible = true
			# No game over, interceptar inputs para modal
			if has_node("MainContainer"):
				$MainContainer.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_bot_action_message(message: String):
	"""Mostra mensagem temporária das ações dos bots - apenas modo offline"""
	if NetworkManager.is_online_mode:
		return
		
	show_temporary_message(message)

func show_temporary_message(message: String):
	"""Mostra uma mensagem temporária no canto superior esquerdo"""
	# Criar label temporário se não existir
	var temp_label = get_node_or_null("MainContainer/TempMessage")
	if not temp_label:
		temp_label = Label.new()
		temp_label.name = "TempMessage"
		temp_label.position = Vector2(20, 20)
		temp_label.add_theme_font_size_override("font_size", 16)
		temp_label.add_theme_color_override("font_color", Color.WHITE)
		temp_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		temp_label.add_theme_constant_override("shadow_offset_x", 2)
		temp_label.add_theme_constant_override("shadow_offset_y", 2)
		if has_node("MainContainer"):
			$MainContainer.add_child(temp_label)
		else:
			add_child(temp_label)
	
	# Configurar mensagem
	temp_label.text = message
	temp_label.visible = true
	
	# Animar fade in
	temp_label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(temp_label, "modulate:a", 1.0, 0.2)
	
	# Aguardar e fade out
	tween.tween_interval(1.5)  # Mensagem visível por 1.5 segundo
	tween.tween_property(temp_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): temp_label.visible = false)

func show_pass_message(message: String):
	"""Mostra mensagem temporária quando alguém passa - apenas modo offline"""
	if NetworkManager.is_online_mode:
		return
		
	show_temporary_message(message)
