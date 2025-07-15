extends Node2D

@onready var sprite := $domino_piece
@onready var collision := $Area2D/CollisionShape2D
@onready var area := $Area2D

var dragging := false
var offset := Vector2.ZERO

var directions := ["up", "right", "down", "left"]
var current_direction_index := 0
var piece_index := 0
var value = [0, 0]

func _ready():
	area.input_event.connect(_on_input_event)

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = true
			offset = get_local_mouse_position()
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = false
			
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			rotate_piece()

func set_values(index: int):
	var count = 0
	for i in range(7):
		for j in range(i, 7):
			if count == index:
				piece_index = i
				value = [i, j]
				break
			count += 1
	if count <= index:
		print("Index out of range for domino pieces.")
		return

	var dir = directions[current_direction_index]
	var path = "res://assets/textures/domino_pixelart_asset_pack/%s/Domino_%s_%d.png" % [
		dir, dir.capitalize(), piece_index + 1
	]
	sprite.texture = load(path)
	rotate_colision_area(dir)

func _process(_delta):
	if dragging:
		var new_pos = get_global_mouse_position() - offset
		global_position = new_pos
		if is_colliding():
			modulate = Color(1, 0.5, 0.5)
		else:
			modulate = Color(1, 1, 1)

func is_colliding() -> bool:
	var overlapping = area.get_overlapping_areas()
	for other in overlapping:
		if other != area:
			return true
	return false

func rotate_piece():
	current_direction_index = (current_direction_index + 1) % directions.size()
	var dir = directions[current_direction_index]
	var path = "res://assets/textures/domino_pixelart_asset_pack/%s/Domino_%s_%d.png" % [
		dir, dir.capitalize(), piece_index + 1
	]
	sprite.texture = load(path)
	rotate_colision_area(dir)

func rotate_colision_area(dir: String):
	if not area:
		area = $Area2D
	if not collision:
		collision = $Area2D/CollisionShape2D
		
	match dir:
		"up", "down":
			area.rotation_degrees = 0
			area.scale = Vector2(1, 1)
			collision.position = Vector2(0, 0.188)
		"right", "left":
			area.rotation_degrees = 90
			area.scale = Vector2(1, 1)
			collision.position = Vector2(0, -0.5)
	
	var new_shape := RectangleShape2D.new()
	match dir:
		"up", "down":
			new_shape.extents = Vector2(12, 22)
		"right", "left":
			new_shape.extents = Vector2(12.5, 21)
	
	collision.shape = new_shape
