extends Node

const PORT := 12345
const MAX_PLAYERS := 4

var is_online_mode: bool = false
var local_player_name: String = ""

signal player_list_changed(players: Dictionary)
signal player_ready_status_changed(statuses: Dictionary)
signal connection_succeeded
signal connection_failed_signal
signal server_disconnected_signal

var players: Dictionary = {}
var players_ready_status: Dictionary = {} 
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
	players_ready_status[1] = false
	
	player_list_changed.emit(players)
	player_ready_status_changed.emit(players_ready_status)
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

func _on_peer_disconnected(id: int):
	print("Jogador desconectado: ", id)
	if is_host:
		players.erase(id)
		players_ready_status.erase(id)
		client_update_player_list.rpc(players)
		client_update_ready_status.rpc(players_ready_status)

func _on_connected_to_server():
	print("Conectado ao servidor com sucesso! Meu ID: ", multiplayer.get_unique_id())
	server_receive_player_info.rpc_id(1, multiplayer.get_unique_id(), local_player_name)
	connection_succeeded.emit()

func _on_connection_failed():
	print("Falha ao conectar no servidor.")
	connection_failed_signal.emit()

func _on_server_disconnected():
	print("Desconectado do servidor.")
	server_disconnected_signal.emit()
	_reset_network()


@rpc("any_peer", "call_local", "reliable")
func client_update_player_list(new_players: Dictionary):
	players = new_players
	player_list_changed.emit(players)

@rpc("any_peer", "call_local", "reliable")
func client_update_ready_status(new_statuses: Dictionary):
	players_ready_status = new_statuses
	player_ready_status_changed.emit(players_ready_status)

@rpc("any_peer", "reliable")
func server_receive_player_info(player_id: int, player_name: String):
	if not multiplayer.is_server(): return
	
	players[player_id] = player_name
	players_ready_status[player_id] = false
	
	client_update_player_list.rpc(players)
	client_update_ready_status.rpc(players_ready_status)

@rpc("any_peer", "call_local", "reliable")
func server_set_player_ready_status(is_ready: bool):
	if not multiplayer.is_server(): return
	
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	
	if sender_id in players_ready_status:
		players_ready_status[sender_id] = is_ready
		print("Jogador %d mudou status para: %s" % [sender_id, is_ready])
		client_update_ready_status.rpc(players_ready_status)


func get_player_name(player_id: int) -> String:
	return players.get(player_id, "Jogador %s" % str(player_id))

func get_local_player_name() -> String:
	return local_player_name

func are_all_players_ready() -> bool:
	if players.is_empty() or players.size() != players_ready_status.size():
		return false
	
	for id in players:
		if not players_ready_status.get(id, false):
			return false
	
	return true
	
func _reset_network():
	players.clear()
	players_ready_status.clear()
	is_host = false
	multiplayer.multiplayer_peer = null
	is_online_mode = false
	local_player_name = ""
