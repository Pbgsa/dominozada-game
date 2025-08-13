# scripts/placement_options.gd
extends CanvasLayer

@onready var left_button := $Control/OptionsContainer/ButtonsContainer/LeftButton
@onready var right_button := $Control/OptionsContainer/ButtonsContainer/RightButton
@onready var cancel_button := $Control/OptionsContainer/CancelButton
@onready var title_label := $Control/OptionsContainer/Title
@onready var background := $Control/Background

var selected_piece: Dictionary
var available_sides: Array = [] # Alterado para Array genérico

signal side_selected(side: String, piece_data: Dictionary)
signal placement_cancelled

func _ready():
	visible = false
	background.gui_input.connect(_on_background_clicked)

# CORREÇÃO: A assinatura da função agora usa "Array" em vez de "Array[String]"
# para evitar o erro de tipo.
func show_options(piece_data: Dictionary, sides: Array):
	"""Show placement options for the selected piece"""
	selected_piece = piece_data
	available_sides = sides
	
	if "first" in sides:
		side_selected.emit("first", piece_data)
		return
	
	left_button.visible = "left" in sides
	right_button.visible = "right" in sides
	
	var piece_text = "[%d,%d]" % [piece_data.a, piece_data.b]
	title_label.text = "Onde colocar a peça " + piece_text + "?"
	if left_button.visible:
		left_button.text = "← Lado Esquerdo"
	if right_button.visible:
		right_button.text = "Lado Direito →"
	
	visible = true

func hide_options():
	"""Hide the placement options"""
	visible = false

func _on_left_button_pressed():
	side_selected.emit("left", selected_piece)
	hide_options()

func _on_right_button_pressed():
	side_selected.emit("right", selected_piece)
	hide_options()

func _on_cancel_button_pressed():
	placement_cancelled.emit()
	hide_options()

func _on_background_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		placement_cancelled.emit()
		hide_options()
