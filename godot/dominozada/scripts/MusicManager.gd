# scripts/MusicManager.gd
extends Node

@onready var audio_player := AudioStreamPlayer.new()

var music_tracks := [
	preload("res://assets/sounds/halls-music.ogg"),
	preload("res://assets/sounds/ambient-guitar-music.ogg"),
	preload("res://assets/sounds/sweet_home_alabama.ogg"),
	preload("res://assets/sounds/baroes_da_pisadinha.ogg"),
	preload("res://assets/sounds/floating-on-bad-conscience.ogg")
]

var current_track_index := 0

func _ready():
	add_child(audio_player)
	audio_player.volume_db = -10.0  # Lower volume
	start_music()

func start_music():
	if music_tracks.size() > 0:
		play_track(current_track_index)

func play_track(index: int):
	if index >= 0 and index < music_tracks.size():
		current_track_index = index
		audio_player.stream = music_tracks[current_track_index]
		if audio_player.stream:
			audio_player.stream.loop = true
			audio_player.play()

func next_track():
	current_track_index = (current_track_index + 1) % music_tracks.size()
	play_track(current_track_index)

func get_current_track_name() -> String:
	if current_track_index < music_tracks.size():
		var track_path = music_tracks[current_track_index].resource_path
		var track_name = track_path.get_file().get_basename()
		return track_name.replace("_", " ").replace("-", " ").capitalize()
	return "Unknown Track"

func stop_music():
	audio_player.stop()

func set_volume(volume: float):
	audio_player.volume_db = volume
