extends Control

const MAX_PLAYERS := 4

@onready var player_item_scene: PackedScene = preload("res://scenes/player_list_item.tscn")

@onready var host_button: Button = $MainContainer/TopRow/HostButton
@onready var join_button: Button = $MainContainer/TopRow/JoinButton
@onready var start_button: Button = $MainContainer/TopRow/StartButton
@onready var lobby_exit_button: Button = $MainContainer/BottomRow/LobbyExitButton
@onready var ip_input: LineEdit = $MainContainer/TopRow/IPInput
@onready var player_list: VBoxContainer = $MainContainer/PlayerList
@onready var player_name_input: LineEdit = $MainContainer/TopRow/PlayerNameInput

# Referência ao menu principal para acessar a seleção de modo
var main_menu_ref: Node = null

func _ready():
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	start_button.pressed.connect(_on_start_pressed)
	lobby_exit_button.pressed.connect(_on_lobby_exit_pressed)
	
	NetworkManager.player_list_changed.connect(update_player_list_ui)
	NetworkManager.player_ready_status_changed.connect(update_player_ready_status_ui)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	
	GameManagerMultiplayer.change_scene_to_game.connect(_on_change_scene_to_game)
	
	if player_name_input:
		player_name_input.placeholder_text = "Digite seu nome..."
	start_button.disabled = true
	
	# Encontrar referência ao menu principal
	_find_main_menu_reference()

func _on_host_pressed():
	var player_name = player_name_input.text if player_name_input.text.strip_edges() != "" else "Host"
	
	# Configurar modo online
	NetworkManager.is_online_mode = true
	
	# Criar o servidor (sem definir o modo ainda)
	NetworkManager.create_host(player_name)
	
	print("HUB: Criando servidor como '%s'" % player_name)
	print("HUB: Modo será definido quando iniciar o jogo")

func _on_join_pressed():
	var player_name = player_name_input.text if player_name_input.text.strip_edges() != "" else "Jogador"
	
	# Configurar modo online
	NetworkManager.is_online_mode = true
	
	# Conectar ao servidor
	NetworkManager.join_server(ip_input.text, player_name)
	
func _on_lobby_exit_pressed():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_connection_succeeded():
	host_button.disabled = true
	join_button.disabled = true
	ip_input.editable = false
	player_name_input.editable = false

func update_player_list_ui(players: Dictionary):
	for child in player_list.get_children():
		child.queue_free()
	
	for id in players:
		var item = player_item_scene.instantiate()
		
		player_list.add_child(item)
		
		item.set_player_info(id, players[id])
		
	update_player_ready_status_ui(NetworkManager.players_ready_status)

func update_player_ready_status_ui(statuses: Dictionary):
	"""Atualiza os checkboxes de 'Pronto' para cada jogador."""
	for child in player_list.get_children():
		if child.has_method("set_ready_status") and child.player_id in statuses:
			child.set_ready_status(statuses[child.player_id])
	
	check_start_button_state()

func check_start_button_state():
	"""Habilita ou desabilita o botão Iniciar Jogo."""
	if NetworkManager.is_host:
		var all_ready = NetworkManager.are_all_players_ready()
		var can_start = all_ready and NetworkManager.players.size() >= 2
		
		start_button.disabled = not can_start
	else:
		start_button.disabled = true


func _on_start_pressed():
	if NetworkManager.is_host:
		# Obter o modo de jogo selecionado no menu principal AGORA
		var selected_mode = _get_selected_game_mode()
		var mode_name = _get_selected_game_mode_name()
		
		# Definir o modo no GameManagerMultiplayer
		GameManagerMultiplayer.set_next_game_mode(selected_mode)
		
		print("HUB: Iniciando jogo no modo: %s" % mode_name)
		
		# Iniciar o jogo
		GameManagerMultiplayer.host_requests_start_game()

func _on_change_scene_to_game():
	get_tree().change_scene_to_file("res://scenes/board.tscn")

func _find_main_menu_reference():
	"""Encontra a referência ao menu principal para acessar o OptionButton"""
	var current_node = self
	
	# Subir na hierarquia até encontrar o menu principal
	while current_node != null:
		if current_node.has_method("get_selected_online_mode"):
			main_menu_ref = current_node
			print("HUB: Referência ao menu principal encontrada!")
			break
		current_node = current_node.get_parent()
	
	if not main_menu_ref:
		print("HUB: AVISO - Não foi possível encontrar o menu principal")

func _get_selected_game_mode() -> GameManagerMultiplayer.GameMode:
	"""Obtém o modo de jogo selecionado no menu principal"""
	if main_menu_ref and main_menu_ref.has_method("get_selected_online_mode"):
		return main_menu_ref.get_selected_online_mode()
	else:
		print("HUB: Usando modo padrão (Clássico) - menu principal não encontrado")
		return GameManagerMultiplayer.GameMode.CLASSICO

func _get_selected_game_mode_name() -> String:
	"""Obtém o nome do modo de jogo selecionado"""
	if main_menu_ref and main_menu_ref.has_method("get_selected_online_mode_name"):
		return main_menu_ref.get_selected_online_mode_name()
	else:
		return "Clássico"
