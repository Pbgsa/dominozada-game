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

func _on_host_pressed():
	var player_name = player_name_input.text if player_name_input.text.strip_edges() != "" else "Host"
	NetworkManager.create_host(player_name)

func _on_join_pressed():
	var player_name = player_name_input.text if player_name_input.text.strip_edges() != "" else "Jogador"
	NetworkManager.join_server(ip_input.text, player_name)
	
func _on_lobby_exit_pressed():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

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
		GameManagerMultiplayer.host_requests_start_game()

func _on_change_scene_to_game():
	get_tree().change_scene_to_file("res://scenes/board.tscn")
