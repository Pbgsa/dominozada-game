# scripts/menu.gd
extends Control

func _on_online_button_pressed() -> void:
	# Define o modo como online e vai para o Hub
	NetworkManager.is_online_mode = true
	get_tree().change_scene_to_file("res://scenes/Hub.tscn")

func _on_offline_button_pressed() -> void:
	# Define o modo como offline e vai direto para o tabuleiro
	NetworkManager.is_online_mode = false
	get_tree().change_scene_to_file("res://scenes/board.tscn")
