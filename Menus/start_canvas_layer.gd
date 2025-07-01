extends CanvasLayer

@onready var label: Label = $Label

func _ready() -> void:
	label.show()
	await get_tree().create_timer(0.56).timeout
	label.hide()
	await get_tree().create_timer(0.56).timeout
	label.show()
	await get_tree().create_timer(0.56).timeout
	label.hide()
	await get_tree().create_timer(0.56).timeout
	label.show()
	await get_tree().create_timer(0.56).timeout
	label.hide()
	await get_tree().create_timer(0.56).timeout
	label.show()
	await get_tree().create_timer(0.56).timeout
	label.hide()
	await get_tree().create_timer(0.56).timeout
	label.show()
	await get_tree().create_timer(0.56).timeout
	label.hide()
