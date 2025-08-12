extends Control

# --- REFERÊNCIAS PARA AS "TELAS" (VIEWS) ---
@onready var main_view = $CenterContainer/MainView
@onready var offline_view = $CenterContainer/OfflineView
@onready var online_view = $CenterContainer/OnlineView
@onready var host_game_selection_view = $CenterContainer/HostGameSelectionView

# A função _ready é chamada quando o nó e seus filhos entram na árvore da cena.
func _ready():
	# Garante que o menu sempre comece na tela principal
	show_main_view()

	# Configura o pivô de todos os botões para a animação de escala funcionar corretamente.
	# Lembre-se de adicionar TODOS os novos botões ao grupo "menu_buttons" no editor.
	var buttons = get_tree().get_nodes_in_group("menu_buttons")
	for button in buttons:
		button.pivot_offset = button.size / 2.0


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


# --- SINAIS DA TELA OFFLINE (OfflineView) ---
func _on_botao_classico_offline_pressed():
	get_tree().change_scene_to_file("res://scenes/board.tscn")

func _on_botao_burrinho_offline_pressed():
	get_tree().change_scene_to_file("res://caminho/para/modo_burrinho.tscn")

func _on_botao_gato_lebre_offline_pressed():
	get_tree().change_scene_to_file("res://caminho/para/modo_gato_lebre.tscn")

func _on_botao_voltar_de_offline_pressed():
	show_main_view()


# --- SINAIS DA TELA ONLINE (OnlineView) ---
func _on_botao_host_pressed():
	#var player_name = online_view.get_node("InputNome").text
	#if player_name.is_empty():
	#	print("Erro: Por favor, digite seu nome antes de criar uma sala.")
	#	return
		
	# --- CHAME SUA LÓGICA DE REDE AQUI PARA CRIAR O SERVIDOR ---
	# Ex: NetworkManager.create_server(player_name)
	#print("Servidor criado! Nome do Host: %s" % player_name)
	
	# Após criar a sala, mostre a tela de seleção de modo para o host
	show_host_game_selection_view()

func _on_botao_join_pressed():
	#var player_name = online_view.get_node("InputNome").text
	#var ip_address = online_view.get_node("InputIP").text
	#if player_name.is_empty() or ip_address.is_empty():
	#	print("Erro: Preencha seu nome e o IP do servidor.")
	#	return

	# --- CHAME SUA LÓGICA DE REDE AQUI PARA ENTRAR EM UM SERVIDOR ---
	# Ex: NetworkManager.join_server(ip_address, player_name)
	#print("Tentando entrar no servidor %s como %s" % [ip_address, player_name])
	pass

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
