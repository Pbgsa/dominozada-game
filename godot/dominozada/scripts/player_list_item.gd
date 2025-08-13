# scripts/player_list_item.gd
extends HBoxContainer

@onready var player_name_label: Label = $PlayerNameLabel
@onready var ready_check_box: CheckBox = $ReadyCheckBox

var player_id: int

func _ready():
	ready_check_box.toggled.connect(_on_ready_check_box_toggled)

func set_player_info(id: int, name: String):
	"""Configura o nome e o ID do jogador para este item da lista."""
	player_id = id
	player_name_label.text = name
	
	if id != multiplayer.get_unique_id():
		ready_check_box.disabled = true

func set_ready_status(is_ready: bool):
	"""Atualiza o estado visual da checkbox sem disparar o sinal 'toggled' novamente."""
	ready_check_box.set_block_signals(true)
	ready_check_box.button_pressed = is_ready
	ready_check_box.set_block_signals(false)

func _on_ready_check_box_toggled(is_checked: bool):
	"""Chamado quando o jogador local clica na sua própria checkbox."""
	NetworkManager.server_set_player_ready_status.rpc(is_checked)
