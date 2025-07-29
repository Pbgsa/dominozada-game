# scripts/NetworkManager.gd
extends Node

const PORT := 12345
const MAX_PLAYERS := 4

# NOVO: Variável para controlar o modo de jogo
var is_online_mode: bool = false

# SINAIS para a UI reagir
signal player_list_changed(players: Dictionary)
signal connection_succeeded
signal connection_failed_signal
signal server_disconnected_signal

var players: Dictionary = {} # peer_id -> nome
var is_host: bool = false

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func create_host():
	var server := ENetMultiplayerPeer.new()
	var error = server.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		print("Falha ao criar o servidor.")
		return
		
	multiplayer.multiplayer_peer = server
	is_host = true
	
	players[1] = "Host"
	player_list_changed.emit(players)
	connection_succeeded.emit()
	print("Servidor criado. Meu ID: ", multiplayer.get_unique_id())

func join_server(ip: String):
	if ip.is_empty():
		ip = "127.0.0.1"
		
	var client := ENetMultiplayerPeer.new()
	client.create_client(ip, PORT)
	multiplayer.multiplayer_peer = client
	print("Tentando conectar em ", ip)

func _on_peer_connected(id: int):
	print("Jogador conectado: ", id)
	if is_host:
		players[id] = "Cliente %s" % str(id)
		rpc("update_player_list_rpc", players)

func _on_peer_disconnected(id: int):
	print("Jogador desconectado: ", id)
	if is_host:
		players.erase(id)
		rpc("update_player_list_rpc", players)

func _on_connected_to_server():
	print("Conectado ao servidor com sucesso! Meu ID: ", multiplayer.get_unique_id())
	connection_succeeded.emit()

func _on_connection_failed():
	print("Falha ao conectar no servidor.")
	connection_failed_signal.emit()

func _on_server_disconnected():
	print("Desconectado do servidor.")
	server_disconnected_signal.emit()
	_reset_network()

@rpc("any_peer", "call_local", "reliable")
func update_player_list_rpc(new_players: Dictionary):
	players = new_players
	player_list_changed.emit(players)
	print("Lista de jogadores atualizada: ", players)
	
func _reset_network():
	players.clear()
	is_host = false
	multiplayer.multiplayer_peer = null
	is_online_mode = false # Reseta o modo de jogo
