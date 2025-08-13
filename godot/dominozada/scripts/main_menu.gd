extends Control

# --- REFERÊNCIAS PARA AS "TELAS" (VIEWS) ---
@onready var main_view = $CenterContainer/MainView
@onready var offline_view = $CenterContainer/OfflineView
@onready var online_view = $CenterContainer/OnlineView
@onready var host_game_selection_view = $CenterContainer/HostGameSelectionView

# Variável para o OptionButton de seleção de modo online
var online_mode_option: OptionButton

# A função _ready é chamada quando o nó e seus filhos entram na árvore da cena.
func _ready():
	# Garante que o menu sempre comece na tela principal
	show_main_view()

	# Configura o pivô de todos os botões para a animação de escala funcionar corretamente.
	# Lembre-se de adicionar TODOS os novos botões ao grupo "menu_buttons" no editor.
	var buttons = get_tree().get_nodes_in_group("menu_buttons")
	for button in buttons:
		button.pivot_offset = button.size / 2.0
	
	# Configurar OptionButton do modo online
	setup_online_mode_option()


# --- FUNÇÕES DE CONTROLE DE VISIBILIDADE ---
func show_main_view():
	main_view.visible = true
	offline_view.visible = false
	online_view.visible = false
	host_game_selection_view.visible = false

func show_offline_view():
	main_view.visible = false
	offline_view.visible = true
	online_view.visible = false
	host_game_selection_view.visible = false

func show_online_view():
	main_view.visible = false
	offline_view.visible = false
	online_view.visible = true
	host_game_selection_view.visible = false
	
func show_host_game_selection_view():
	main_view.visible = false
	offline_view.visible = false
	online_view.visible = false
	host_game_selection_view.visible = true


# --- SINAIS DA TELA PRINCIPAL (MainView) ---
func _on_botao_online_pressed():
	show_online_view()

func _on_botao_offline_pressed():
	show_offline_view()

func _on_botao_sair_pressed():
	get_tree().quit()

func go_to_board():
	# Garantir que estamos no modo offline antes de ir para o board
	NetworkManager.is_online_mode = false
	print("MENU: Definindo modo offline, is_online_mode = ", NetworkManager.is_online_mode)
	get_tree().change_scene_to_file("res://scenes/board.tscn")
# --- SINAIS DA TELA OFFLINE (OfflineView) ---
func _on_botao_classico_offline_pressed():
	GameManager.set_next_game_mode(GameManager.GameMode.CLASSICO)
	go_to_board()

func _on_botao_puxando_morto_offline_pressed():
	GameManager.set_next_game_mode(GameManager.GameMode.PUXANDO_DO_MORTO)
	go_to_board()

func _on_botao_gato_lebre_offline_pressed():
	GameManager.set_next_game_mode(GameManager.GameMode.GATO_COM_LEBRE)
	go_to_board()

func _on_botao_voltar_de_offline_pressed():
	show_main_view()


# --- SINAIS DA TELA ONLINE (OnlineView) ---
# NOTA: As funções de host/join agora estão no Hub.tscn/hub.gd
# O OptionButton continua sendo configurado aqui no menu principal

func _on_botao_voltar_de_online_pressed():
	show_main_view()


# --- SINAIS DA TELA DE SELEÇÃO DO HOST (HostGameSelectionView) ---
func _on_botao_classico_host_pressed():
	# --- CHAME SUA LÓGICA DE REDE AQUI PARA INICIAR O JOGO PARA TODOS ---
	# Você precisa enviar um sinal para todos os clientes carregarem a cena correta.
	# Ex: NetworkManager.start_game("res://caminho/para/modo_classico.tscn")
	print("Host iniciou o jogo: MODO CLÁSSICO")

func _on_botao_burrinho_host_pressed():
	# Ex: NetworkManager.start_game("res://caminho/para/modo_burrinho.tscn")
	print("Host iniciou o jogo: MODO BURRINHO")

func _on_botao_gato_lebre_host_pressed():
	# Ex: NetworkManager.start_game("res://caminho/para/modo_gato_lebre.tscn")
	print("Host iniciou o jogo: MODO GATO COM LEBRE")

func _on_botao_voltar_de_host_pressed():
	# --- CHAME SUA LÓGICA DE REDE AQUI PARA FECHAR O SERVIDOR ---
	# Ex: NetworkManager.close_server()
	print("Host cancelou a sala.")
	show_online_view()


# --- ANIMAÇÃO DE HOVER (continua a mesma) ---
func _animate_button_scale(button: Button, target_scale: Vector2):
	var tween = create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(button, "scale", target_scale, 0.15)

# Não se esqueça de conectar os sinais de mouse_entered e mouse_exited
# para cada um dos novos botões para que a animação funcione!


# --- SISTEMA DE SELEÇÃO DE MODO ONLINE ---
func setup_online_mode_option():
	"""Configura o OptionButton com os modos de jogo disponíveis"""
	# Tentar encontrar o OptionButton na tela online
	if online_view:
		online_mode_option = online_view.find_child("*ModeOption*", true, false)
		if not online_mode_option:
			online_mode_option = online_view.find_child("OptionButton", true, false)
	
	if online_mode_option:
		# Limpar opções existentes
		online_mode_option.clear()
		
		# Adicionar os modos de jogo
		online_mode_option.add_item("Clássico", GameManagerMultiplayer.GameMode.CLASSICO)
		online_mode_option.add_item("Puxando do Morto", GameManagerMultiplayer.GameMode.PUXANDO_DO_MORTO)
		online_mode_option.add_item("Gato com Lebre", GameManagerMultiplayer.GameMode.GATO_COM_LEBRE)
		
		# Definir o modo padrão como Clássico
		online_mode_option.selected = 0
		
		# Conectar o sinal de mudança de seleção
		if not online_mode_option.item_selected.is_connected(_on_online_mode_selected):
			online_mode_option.item_selected.connect(_on_online_mode_selected)
		
		print("MENU: OptionButton configurado com sucesso!")
	else:
		print("MENU: AVISO - OptionButton não encontrado na tela online.")

func configure_option_button_manually(option_button: OptionButton):
	"""Função alternativa para configurar o OptionButton manualmente"""
	online_mode_option = option_button
	if online_mode_option:
		# Limpar opções existentes
		online_mode_option.clear()
		
		# Adicionar os modos de jogo
		online_mode_option.add_item("Clássico", GameManagerMultiplayer.GameMode.CLASSICO)
		online_mode_option.add_item("Puxando do Morto", GameManagerMultiplayer.GameMode.PUXANDO_DO_MORTO)
		online_mode_option.add_item("Gato com Lebre", GameManagerMultiplayer.GameMode.GATO_COM_LEBRE)
		
		# Definir o modo padrão como Clássico
		online_mode_option.selected = 0
		
		# Conectar o sinal de mudança de seleção
		if not online_mode_option.item_selected.is_connected(_on_online_mode_selected):
			online_mode_option.item_selected.connect(_on_online_mode_selected)
		
		print("MENU: OptionButton configurado manualmente com sucesso!")

func get_selected_online_mode() -> GameManagerMultiplayer.GameMode:
	"""Retorna o modo de jogo selecionado no OptionButton"""
	if online_mode_option and online_mode_option.selected >= 0:
		return online_mode_option.get_item_id(online_mode_option.selected)
	else:
		# Valor padrão se não houver seleção
		print("MENU: Usando modo padrão (Clássico)")
		return GameManagerMultiplayer.GameMode.CLASSICO

func get_selected_online_mode_name() -> String:
	"""Retorna o nome do modo de jogo selecionado"""
	if online_mode_option and online_mode_option.selected >= 0:
		return online_mode_option.get_item_text(online_mode_option.selected)
	else:
		return "Clássico"

func _on_online_mode_selected(index: int):
	"""Callback quando um modo é selecionado no OptionButton"""
	if online_mode_option:
		var mode_id = online_mode_option.get_item_id(index)
		var mode_name = online_mode_option.get_item_text(index)
		print("MENU: Modo selecionado: %s (ID: %d)" % [mode_name, mode_id])
		print("MENU: ⚠️  Lembre-se: O modo será aplicado quando INICIAR o jogo, não ao criar o servidor!")
