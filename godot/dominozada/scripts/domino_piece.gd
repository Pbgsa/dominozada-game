extends TextureButton

var dragging := false
var offset := Vector2.ZERO

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = true
			offset = get_local_mouse_position()
			grab_focus()
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = false

func _process(delta):
	if dragging:
		global_position = get_global_mouse_position() - offset
