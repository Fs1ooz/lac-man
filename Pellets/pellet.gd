extends Area2D
class_name BasePellet

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.eating = true
		Globals.emit_signal("eaten")
		queue_free()
