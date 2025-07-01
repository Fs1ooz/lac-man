extends Node2D

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	get_tree().paused = true
	await audio_stream_player_2d.finished
	if InputEvent:
		get_tree().paused = false
