# scripts/hub.gd
extends Node2D

const MAX_PLAYERS := 4

@onready var host_button: Button = $HostButton
@onready var join_button: Button = $JoinButton
@onready var start_button: Button = $StartButton
@onready var ip_input: LineEdit = $IPInput
@onready var player_list: VBoxContainer = $PlayerList
@onready var player_name_input: LineEdit = $PlayerNameInput

func _ready():
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	start_button.pressed.connect(_on_start_pressed)
	
	NetworkManager.player_list_changed.connect(update_player_list_ui)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	
	# NOVO: Conecta ao sinal do GameManager que manda mudar de cena
	GameManagerMultiplayer.change_scene_to_game.connect(_on_change_scene_to_game)
	
	# Configurar placeholder para o campo de nome
	if player_name_input:
		player_name_input.placeholder_text = "Digite seu nome..."

func _on_host_pressed():
	var player_name = player_name_input.text if player_name_input.text.strip_edges() != "" else "Host"
	NetworkManager.create_host(player_name)

func _on_join_pressed():
	var player_name = player_name_input.text if player_name_input.text.strip_edges() != "" else "Jogador"
	NetworkManager.join_server(ip_input.text, player_name)

func _on_connection_succeeded():
	host_button.disabled = true
	join_button.disabled = true
	ip_input.editable = false
	player_name_input.editable = false

func update_player_list_ui(players: Dictionary):
	for child in player_list.get_children():
		child.queue_free()
	
	for id in players:
		var label = Label.new()
		label.text = "%s" % players[id]  # Apenas mostra o nome, sem o ID
		player_list.add_child(label)
		
	if NetworkManager.is_host:
		start_button.disabled = players.size() != MAX_PLAYERS

func _on_start_pressed():
	# ALTERADO: Apenas pede para o GameManager iniciar o processo.
	if NetworkManager.is_host:
		GameManagerMultiplayer.host_requests_start_game()

# NOVO: Esta função é chamada pelo sinal do GameManager
func _on_change_scene_to_game():
	get_tree().change_scene_to_file("res://scenes/board.tscn")
