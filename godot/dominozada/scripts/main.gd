extends Node2D

@onready var audio := AudioStreamPlayer.new()
@onready var button := $UI/Button

var sounds := [
	preload("res://assets/sounds/ambient-guitar-music.ogg"),
	preload("res://assets/sounds/sweet_home_alabama.ogg"),
	preload("res://assets/sounds/baroes_da_pisadinha.ogg")
]

var current_index := 0

func _ready():
	add_child(audio)
	audio.stream = sounds[current_index]
	audio.stream.loop = true
	audio.play()
	button.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	current_index = (current_index + 1) % sounds.size()
	audio.stream = sounds[current_index]
	audio.stream.loop = true
	audio.play()
