extends Container  # Pode ser VBoxContainer ou HBoxContainer

@onready var piece_button_scene: PackedScene = preload("res://scenes/domino_piece_button.tscn")

var is_updating: bool = false  # Flag para evitar atualizações simultâneas

func set_piece_count(count: int, direction: String):
	# Evitar atualizações simultâneas
	if is_updating:
		return
	
	is_updating = true
	
	# Limpar mão existente e aguardar a limpeza completa
	clear_hand()
	await get_tree().process_frame

	for i in range(count):
		# Verificar se ainda estamos atualizando (pode ter sido cancelado)
		if not is_updating:
			break
			
		var button = piece_button_scene.instantiate()

		if direction == "up" or direction == "down":
			button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		else:
			button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		button.disabled = true
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(button)

		# Aguardar um frame para garantir que o botão esteja pronto
		await get_tree().process_frame
		
		# Verificar se o botão ainda existe antes de configurar
		if is_instance_valid(button) and button.has_method("set_piece_values"):
			button.set_piece_values(-1, -1, direction)
	
	is_updating = false

func clear_hand():
	# Remover todos os filhos de forma mais segura
	var children = get_children()
	for child in children:
		if is_instance_valid(child):
			child.queue_free()
	
	# Aguardar um frame para garantir que a remoção seja processada
	if children.size() > 0:
		await get_tree().process_frame
