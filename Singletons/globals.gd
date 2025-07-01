extends Node

signal eaten


func restart_game():
	call_deferred("_restart_scene")

func _restart_scene():
	get_tree().reload_current_scene()
