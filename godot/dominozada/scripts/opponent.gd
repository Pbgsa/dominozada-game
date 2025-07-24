extends Container  # Pode ser VBoxContainer ou HBoxContainer

@onready var piece_button_scene: PackedScene = preload("res://scenes/domino_piece_button.tscn")

func set_piece_count(count: int, direction: String):
	clear_hand()

	for i in range(count):
		var button = piece_button_scene.instantiate()

		if direction == "up" or direction == "down":
			button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		else:
			button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		button.disabled = true
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(button)

		await get_tree().process_frame
		button.set_piece_values(0, 0, direction)

func clear_hand():
	for child in get_children():
		child.queue_free()
