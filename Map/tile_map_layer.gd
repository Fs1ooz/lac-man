extends TileMapLayer

@onready var tunnel_1: Area2D = $Tunnel1
@onready var tunnel_2: Area2D = $Tunnel2



func _on_tunnel_1_body_entered(body: Node2D) -> void:
	body.position.x = 5



func _on_tunnel_2_body_entered(body: Node2D) -> void:
	body.position.x = 220
