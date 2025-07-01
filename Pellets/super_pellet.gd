extends BasePellet


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.power_up()
	super._on_body_entered(body)
