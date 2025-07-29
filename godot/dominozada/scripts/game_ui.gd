# scripts/game_ui.gd
extends CanvasLayer

@onready var turn_label := $MainContainer/TurnInfo/TurnLabel
@onready var pass_button := $MainContainer/ActionButtons/PassButton
@onready var game_over_panel := $MainContainer/GameOverPanel
@onready var winner_label := $MainContainer/GameOverPanel/GameOverContent/WinnerLabel
@onready var reason_label := $MainContainer/GameOverPanel/GameOverContent/ReasonLabel

var game_manager

func _ready():
	if NetworkManager.is_online_mode:
		game_manager = GameManagerMultiplayer
	else:
		game_manager = get_node("/root/Board/GameManager")
		
	game_manager.turn_changed.connect(_on_turn_changed)
	game_manager.game_over.connect(_on_game_over)
	game_manager.game_started.connect(_on_game_started)
	
	pass_button.pressed.connect(_on_pass_button_pressed)
	
	game_over_panel.visible = false
	pass_button.visible = false
	turn_label.text = "Aguardando início do jogo..."

func _on_turn_changed(player_id: int):
	var my_id = 1
	if NetworkManager.is_online_mode:
		my_id = multiplayer.get_unique_id()
		
	if player_id == my_id:
		turn_label.text = "É a sua vez!"
		pass_button.disabled = false
		pass_button.visible = true
	else:
		var player_name = "Jogador " + str(player_id)
		if not NetworkManager.is_online_mode:
			player_name = game_manager.players[player_id].name
		turn_label.text = "Vez de: " + player_name
		pass_button.disabled = true
		pass_button.visible = true

func _on_game_over(winner_id: int, reason: String):
	if winner_id == -1:
		winner_label.text = "Jogo Travado!"
	else:
		winner_label.text = "Jogador " + str(winner_id) + " venceu!"
	
	reason_label.text = reason
	game_over_panel.visible = true
	pass_button.visible = false

func _on_game_started():
	game_over_panel.visible = false
	pass_button.visible = true

func _on_pass_button_pressed():
	if NetworkManager.is_online_mode:
		game_manager.server_pass_turn.rpc()
	else:
		# CORREÇÃO: Chama a função de passar a vez no modo offline
		game_manager.pass_turn()

	pass_button.disabled = true
