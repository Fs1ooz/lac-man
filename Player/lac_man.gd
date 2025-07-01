extends CharacterBody2D
class_name Player


enum PlayerState {
	IDLE,
	MOVE,
	DEATH,
	POWER_UP,
}

@export var starting_scale: = Vector2(0.8, 0.8)
@export var collision: CollisionShape2D
@export var animation_player: AnimationPlayer


var eating = false

var speed: int = 30
var movement_direction: Vector2 = Vector2.ZERO
var current_state := PlayerState.IDLE

var animation_timer: float = 0.0
var animation_speed: float = 0.2
var mouth_open: bool = true

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var giulia_open: Polygon2D = $GiuliaOpen
@onready var giulia_closed: Polygon2D = $GiuliaClosed

func _ready() -> void:
	Globals.connect("eaten", waka)
	await get_tree().create_timer(4.10).timeout
	current_state = PlayerState.MOVE

func _physics_process(delta: float) -> void:
	if movement_direction != Vector2.ZERO:
		player_rotation(movement_direction)
		velocity = movement_direction * speed
		move_and_slide()
		player_animation(delta)
		if eating == true:
			await waka()
		print(eating)

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
	if current_state == PlayerState.MOVE:
		animation_timer += delta
		if animation_timer >= animation_speed:
			animation_timer = 0.0
			mouth_open = !mouth_open
			giulia_open.visible = mouth_open
			giulia_closed.visible = not mouth_open
			#if audio_stream_player_2d.playing:
				#return
			#audio_stream_player_2d.play()

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


func waka():
	if audio_stream_player_2d.playing:
		return
	audio_stream_player_2d.play()
	await audio_stream_player_2d.finished
	eating = false
	return

func death():
	current_state = PlayerState.DEATH
	speed = 2
	animation_player.play("death")
	await animation_player.animation_finished
	process_mode = ProcessMode.PROCESS_MODE_DISABLED
	Globals.restart_game()

func power_up():
	current_state = PlayerState.POWER_UP
	speed = 45
	var ghosts = get_tree().get_nodes_in_group("Ghost")
	for ghost in ghosts:
		ghost.set_frightened()
	await get_tree().create_timer(10).timeout
	speed = 40
