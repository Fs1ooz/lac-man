extends CharacterBody2D
class_name Player

enum PlayerState {
	IDLE,
	MOVE,
	DEATH,
	POWER_UP,
}

@export var starting_scale := Vector2(0.8, 0.8)
@export var collision: CollisionShape2D
@export var sprite_open: Polygon2D
@export var sprite_closed: Polygon2D
@export var sfx: AudioStreamPlayer2D
@export var speed: int = 35
@export var power_up_speed = 45

var eating = false

var movement_direction: Vector2 = Vector2.ZERO
var current_state := PlayerState.IDLE
var animation_timer: float = 0.0
var animation_speed: float = 0.1
var mouth_open: bool = true
var original_color: Color = modulate

@onready var no_lattosio: Sprite2D = $NoLattosio

func _ready() -> void:
	Globals.connect("eaten", waka)
	await get_tree().create_timer(4.10).timeout
	change_state(PlayerState.MOVE)

func _physics_process(delta: float) -> void:
	if movement_direction != Vector2.ZERO:
		player_rotation(movement_direction)
		velocity = movement_direction * speed
		move_and_slide()
		player_animation(delta)

		if eating:
			waka()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.keycode:
			KEY_UP:
				movement_direction = Vector2.UP
			KEY_DOWN:
				movement_direction = Vector2.DOWN
			KEY_LEFT:
				movement_direction = Vector2.LEFT
			KEY_RIGHT:
				movement_direction = Vector2.RIGHT

func player_animation(delta: float):
	var current_animation_speed = animation_speed
	if current_state == PlayerState.POWER_UP:
		current_animation_speed = animation_speed / 2

	if current_state == PlayerState.MOVE or current_state == PlayerState.POWER_UP:
		animation_timer += delta
		if animation_timer >= current_animation_speed:
			animation_timer = 0.0
			mouth_open = !mouth_open
			sprite_open.visible = mouth_open
			sprite_closed.visible = not mouth_open

func player_rotation(current_direction):
	rotation_degrees = 0
	scale = starting_scale

	match current_direction:
		Vector2.RIGHT:
			pass
		Vector2.LEFT:
			scale.x = -starting_scale.x
		Vector2.UP:
			rotation_degrees = -90
		Vector2.DOWN:
			rotation_degrees = 90

func change_state(new_state: PlayerState):
	current_state = new_state

	match current_state:
		PlayerState.IDLE:
			modulate = original_color
			sfx.pitch_scale = 1.0
			speed = 0
		PlayerState.MOVE:
			modulate = original_color
			no_lattosio.show()
			sfx.pitch_scale = 1.0
			speed = 35
		PlayerState.DEATH:
			speed = 2
		PlayerState.POWER_UP:
			modulate = Color.CORNSILK
			self_modulate = Color.CORNSILK
			no_lattosio.hide()
			sfx.pitch_scale = 2.0
			speed = power_up_speed

func waka():
	if sfx.playing:
		return

	sfx.play()
	await sfx.finished
	eating = false

func death():
	change_state(PlayerState.DEATH)
	scale = starting_scale

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.001, 0.001), 0.5)
	await tween.finished

	process_mode = ProcessMode.PROCESS_MODE_DISABLED
	Globals.restart_game()

func power_up():
	change_state(PlayerState.POWER_UP)

	var ghosts = get_tree().get_nodes_in_group("Ghost")
	for ghost in ghosts:
		ghost.set_frightened()

	await get_tree().create_timer(10).timeout
	change_state(PlayerState.MOVE)
