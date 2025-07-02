extends Node2D

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var victory_canvas_layer: CanvasLayer = $VictoryCanvasLayer

func _ready() -> void:
	get_tree().paused = true
	await audio_stream_player_2d.finished
	get_tree().paused = false


func _process(delta: float) -> void:
	var pellets = get_tree().get_nodes_in_group("Pellet")
	print(pellets.size())
	if pellets.size() == 0:
		victory_canvas_layer.show()
		await get_tree().create_timer(4).timeout
		Globals.restart_game()
