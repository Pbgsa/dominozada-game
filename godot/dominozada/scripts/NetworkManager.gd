# scripts/NetworkManager.gd
extends Node

const PORT := 12345
const MAX_PLAYERS := 4

# NOVO: Variável para controlar o modo de jogo
var is_online_mode: bool = false

# NOVO: Variável para armazenar o nome do jogador local
var local_player_name: String = ""

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

func create_host(player_name: String = "Host"):
	local_player_name = player_name if not player_name.is_empty() else "Host"
	
	var server := ENetMultiplayerPeer.new()
	var error = server.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		print("Falha ao criar o servidor.")
		return
		
	multiplayer.multiplayer_peer = server
	is_host = true
	
	players[1] = local_player_name
	player_list_changed.emit(players)
	connection_succeeded.emit()
	print("Servidor criado. Meu ID: ", multiplayer.get_unique_id(), " Nome: ", local_player_name)

func join_server(ip: String, player_name: String = ""):
	local_player_name = player_name if not player_name.is_empty() else "Jogador %d" % multiplayer.get_unique_id()

	if ip.is_empty():
		ip = "127.0.0.1"
		
	var client := ENetMultiplayerPeer.new()
	client.create_client(ip, PORT)
	multiplayer.multiplayer_peer = client
	print("Tentando conectar em ", ip, " como ", local_player_name)

func _on_peer_connected(id: int):
	print("Jogador conectado: ", id)
	if is_host:
		# Temporariamente adiciona com ID, será atualizado quando receber o nome
		players[id] = "Cliente %s" % str(id)
		rpc("update_player_list_rpc", players)

func _on_peer_disconnected(id: int):
	print("Jogador desconectado: ", id)
	if is_host:
		players.erase(id)
		rpc("update_player_list_rpc", players)

func _on_connected_to_server():
	print("Conectado ao servidor com sucesso! Meu ID: ", multiplayer.get_unique_id())
	# Enviar o nome do jogador para o servidor
	rpc_id(1, "receive_player_name", multiplayer.get_unique_id(), local_player_name)
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

@rpc("any_peer", "reliable")
func receive_player_name(player_id: int, player_name: String):
	# Apenas o host deve processar este RPC
	if not is_host:
		return
	
	print("Recebido nome do jogador ", player_id, ": ", player_name)
	players[player_id] = player_name
	# Atualizar a lista para todos os jogadores
	rpc("update_player_list_rpc", players)

# Função para obter o nome de um jogador pelo ID
func get_player_name(player_id: int) -> String:
	return players.get(player_id, "Jogador %s" % str(player_id))

# Função para obter o nome do jogador local
func get_local_player_name() -> String:
	return local_player_name
	
func _reset_network():
	players.clear()
	is_host = false
	multiplayer.multiplayer_peer = null
	is_online_mode = false # Reseta o modo de jogo
	local_player_name = "" # Reseta o nome do jogador
