extends CharacterBody2D
class_name Ghost

enum GhostStates {
	CHASE,
	SCATTER,
	FRIGHTENED,
	EATEN,
}

@onready var agent = $NavigationAgent2D
var speed = 30
var frightened_speed = 15
var eaten_speed = 60
var current_state = GhostStates.CHASE
var scatter_target: Vector2
var home_position: Vector2
var state_timer = 0.0
var chase_duration = 15.0
var scatter_duration = 5.0
var frightened_duration = 8.0

func _ready():
	# Imposta la posizione home del fantasma
	home_position = global_position
	# Imposta un target di scatter casuale o fisso
	scatter_target = Vector2(randf_range(50, 950), randf_range(50, 550))

func _physics_process(delta):
	var player = get_tree().get_nodes_in_group("Player").slice(-1)[0] if get_tree().get_nodes_in_group("Player").size() > 0 else null

	if not player:
		return

	if player.current_state == player.PlayerState.DEATH:
		return

	# Aggiorna il timer dello stato
	state_timer += delta

	# Determina il comportamento in base allo stato
	var target_pos: Vector2
	var current_speed: int

	match current_state:
		GhostStates.CHASE:
			target_pos = get_chase_target(player)
			current_speed = speed
			# Cambia a scatter dopo il tempo stabilito
			if state_timer >= chase_duration:
				change_state(GhostStates.SCATTER)

		GhostStates.SCATTER:
			target_pos = scatter_target
			current_speed = speed
			# Cambia a chase dopo il tempo stabilito
			if state_timer >= scatter_duration:
				change_state(GhostStates.CHASE)

		GhostStates.FRIGHTENED:
			target_pos = get_frightened_target(player)
			current_speed = frightened_speed
			# Ritorna a chase dopo il tempo stabilito
			if state_timer >= frightened_duration:
				change_state(GhostStates.CHASE)

		GhostStates.EATEN:
			target_pos = home_position
			current_speed = eaten_speed
			# Controlla se è tornato a casa
			if global_position.distance_to(home_position) < 20:
				change_state(GhostStates.CHASE)

	# Navigazione
	navigate_to_target(target_pos, current_speed)
	move_and_slide()

	# Gestione collisioni
	handle_collisions()

func get_chase_target(player) -> Vector2:
	# Comportamento di inseguimento diretto
	return player.global_position

func get_frightened_target(player) -> Vector2:
	# Comportamento di fuga - si allontana dal giocatore
	var direction_away = global_position.direction_to(player.global_position) * -1
	return global_position + direction_away * 200

func navigate_to_target(target_pos: Vector2, current_speed: int):
	var current_pos = global_position

	# Imposta la destinazione
	agent.set_target_position(target_pos)

	# Ottieni la prossima posizione nel path
	var next_path_pos = agent.get_next_path_position()
	var new_velocity = current_pos.direction_to(next_path_pos) * current_speed

	# Navigazione con o senza avoidance
	if agent.avoidance_enabled:
		agent.set_velocity(new_velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(new_velocity)

func handle_collisions():
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider.is_in_group("Player"):
			match current_state:
				GhostStates.CHASE, GhostStates.SCATTER:
					# Il fantasma uccide il giocatore
					collider.death()
				GhostStates.FRIGHTENED:
					# Il giocatore mangia il fantasma
					change_state(GhostStates.EATEN)
				GhostStates.EATEN:
					# Nessuna interazione quando è già mangiato
					pass

func change_state(new_state: GhostStates):
	current_state = new_state
	state_timer = 0.0

	# Azioni specifiche per cambio stato
	match new_state:
		GhostStates.SCATTER:
			# Genera nuovo target di scatter
			scatter_target = Vector2(randf_range(50, 950), randf_range(50, 550))
		GhostStates.FRIGHTENED:
			# Cambia colore o sprite per indicare lo stato frightened
			modulate = Color.BLUE
		GhostStates.EATEN:
			# Cambia aspetto per indicare che è stato mangiato
			modulate = Color.GRAY
		GhostStates.CHASE:
			# Ripristina aspetto normale
			modulate = Color.WHITE

# Funzione pubblica per attivare lo stato frightened (chiamata quando il player prende un power pellet)
func set_frightened():
	if current_state != GhostStates.EATEN:
		change_state(GhostStates.FRIGHTENED)

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
