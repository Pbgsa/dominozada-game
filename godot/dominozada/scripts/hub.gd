extends Node2D

const PORT := 12345
const MAX_PLAYERS := 4

var is_host: bool = false
var peer: MultiplayerPeer = null
var players: Dictionary = {}  # peer_id -> nome

func _ready():
	$HostButton.pressed.connect(_on_host_pressed)
	$JoinButton.pressed.connect(_on_join_pressed)
	$StartButton.pressed.connect(_on_start_pressed)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	update_player_list()

func _on_host_pressed():
	var server := ENetMultiplayerPeer.new()
	server.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = server
	is_host = true
	players[multiplayer.get_unique_id()] = "Host"
	update_player_list()

func _on_join_pressed():
	var ip: String = $IPInput.text
	var client := ENetMultiplayerPeer.new()
	client.create_client(ip, PORT)
	multiplayer.multiplayer_peer = client

func _on_start_pressed():
	if is_host:
		rpc("start_game")
	else:
		print("Somente o host pode iniciar o jogo.")

@rpc("call_local")
func start_game():
	print("Jogo iniciado!")
	# Aqui você pode trocar de cena se quiser
	# get_tree().change_scene_to_file("res://Game.tscn")

func _on_peer_connected(id: int):
	players[id] = "Client %s" % str(id)
	update_player_list()
	rpc_id(id, "receive_player_list", players)

func _on_peer_disconnected(id: int):
	players.erase(id)
	update_player_list()

func _on_connected_to_server():
	players[multiplayer.get_unique_id()] = "Eu"
	update_player_list()
	rpc_id(1, "request_player_list")  # ID 1 é sempre o host

func _on_connection_failed():
	print("Falha ao conectar no servidor.")

func _on_server_disconnected():
	print("Desconectado do servidor.")
	players.clear()
	update_player_list()

@rpc("authority", "reliable")
func receive_player_list(new_players: Dictionary):
	players = new_players
	update_player_list()

@rpc("authority", "reliable")
func request_player_list():
	if is_host:
		var requester_id = multiplayer.get_remote_sender_id()
		rpc_id(requester_id, "receive_player_list", players)

func update_player_list():
	var container: VBoxContainer = $PlayerList

	# Remove filhos anteriores
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

	# Adiciona novos labels
	for id in players:
		var label := Label.new()
		label.text = "%s (ID: %s)" % [players[id], str(id)]
		container.add_child(label)
