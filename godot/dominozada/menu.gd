extends Node2D

func _on_online_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes//Hub.tscn")

func _on_offline_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes//board.tscn")
