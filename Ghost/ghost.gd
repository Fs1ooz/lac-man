extends Area2D
class_name Ghost

# Segnale per notificare quando un fantasma viene mangiato
signal ghost_eaten(points)

enum GhostStates {
	CHASE,
	SCATTER,
	FRIGHTENED,
	EATEN,
}

enum GhostType {
	BLINKY,    # Rosso - Aggressivo, insegue direttamente
	PINKY,     # Rosa - Cerca di tendere imboscate
	INKY,      # Azzurro - Comportamento imprevedibile
	CLYDE      # Arancione - Timido, scappa quando troppo vicino
}

# === VARIABILI ESPORTABILI ===
@export_category("Ghost Identity")
@export var ghost_type: GhostType = GhostType.BLINKY
@export var ghost_name: String = "Blinky"
@export var ghost_color: Color = Color.RED

@export_category("Movement Settings")
@export var speed: int = 30
@export var frightened_speed: int = 20
@export var eaten_speed: int = 40
@export var tunnel_speed_multiplier: float = 0.5  # Velocità ridotta nei tunnel

@export_category("Behavior Timing")
@export var chase_duration: float = 15.0
@export var scatter_duration: float = 5.0
@export var frightened_duration: float = 10.0

@export_category("AI Behavior")
@export var chase_offset: Vector2 = Vector2.ZERO  # Offset per strategie diverse
@export var scatter_corner: Vector2 = Vector2(50, 50)  # Angolo di scatter preferito
@export var aggressiveness: float = 1.0  # Moltiplicatore aggressività (0.5 = timido, 2.0 = molto aggressivo)
@export var prediction_tiles: int = 4  # Quante tile predire per Pinky
@export var flee_distance: float = 80.0  # Distanza minima per Clyde prima di scappare

@export_category("Visual Settings")
@export var normal_sprite: Texture2D
@export var frightened_sprite: Texture2D
@export var eaten_sprite: Texture2D
@export var flash_warning_time: float = 3.0  # Secondi prima della fine frightened per lampeggiare

@export_category("Spawn Settings")
@export var spawn_delay: float = 0.0  # Ritardo spawn iniziale
@export var home_exit_delay: float = 5.0  # Tempo prima di uscire dalla casa
@export var sprite: Sprite2D  # Assumendo che tu abbia uno Sprite2D
# === VARIABILI INTERNE ===
var current_state = GhostStates.CHASE
var home_position: Vector2
var state_timer = 0.0
var spawn_timer = 0.0
var is_in_tunnel = false
var has_spawned = false

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var agent = $NavigationAgent2D


func _ready():
	# Imposta la posizione home del fantasma
	home_position = global_position

	# Applica le impostazioni del tipo di fantasma
	setup_ghost_type()

	# Applica il colore
	modulate = ghost_color

	# Connetti i segnali di Area2D
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Imposta sprite iniziale
	if normal_sprite and sprite:
		sprite.texture = normal_sprite

func setup_ghost_type():
	"""Configura automaticamente le proprietà base in base al tipo di fantasma"""
	match ghost_type:
		GhostType.BLINKY:
			ghost_name = "Blinky"
			ghost_color = Color.RED
			scatter_corner = Vector2(950, 50)  # Angolo in alto a destra
			aggressiveness = 1.2

		GhostType.PINKY:
			ghost_name = "Pinky"
			ghost_color = Color.VIOLET
			scatter_corner = Vector2(50, 50)   # Angolo in alto a sinistra
			aggressiveness = 1.0
			prediction_tiles = 4
			chase_offset = Vector2(0, -64)  # Tende imboscate davanti

		GhostType.INKY:
			ghost_name = "Inky"
			ghost_color = Color.CYAN
			scatter_corner = Vector2(950, 550) # Angolo in basso a destra
			aggressiveness = 0.8
			chase_offset = Vector2(32, 32)  # Comportamento più erratico

		GhostType.CLYDE:
			ghost_name = "Clyde"
			ghost_color = Color.ORANGE
			scatter_corner = Vector2(50, 550)  # Angolo in basso a sinistra
			aggressiveness = 0.6
			flee_distance = 100.0
			speed = 28

func _process(delta):
	# Gestisci spawn delay
	if not has_spawned:
		spawn_timer += delta
		if spawn_timer >= spawn_delay:
			has_spawned = true
		else:
			return

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
			current_speed = get_adjusted_speed(speed)
			# Cambia a scatter dopo il tempo stabilito
			if state_timer >= chase_duration:
				change_state(GhostStates.SCATTER)

		GhostStates.SCATTER:
			target_pos = scatter_corner
			current_speed = get_adjusted_speed(speed)
			# Cambia a chase dopo il tempo stabilito
			if state_timer >= scatter_duration:
				change_state(GhostStates.CHASE)

		GhostStates.FRIGHTENED:
			target_pos = get_frightened_target(player)
			current_speed = get_adjusted_speed(frightened_speed)
			# Ritorna a chase dopo il tempo stabilito
			if state_timer >= frightened_duration:
				change_state(GhostStates.CHASE)

		GhostStates.EATEN:
			target_pos = home_position
			current_speed = eaten_speed  # Non rallentare quando eaten
			# Controlla se è tornato a casa
			if global_position.distance_to(home_position) < 5:
				change_state(GhostStates.CHASE)

	# Navigazione
	navigate_to_target(target_pos, current_speed, delta)

func get_adjusted_speed(base_speed: int) -> int:
	"""Applica modificatori di velocità (tunnel, aggressività, ecc.)"""
	var final_speed = base_speed * aggressiveness

	if is_in_tunnel:
		final_speed *= tunnel_speed_multiplier

	return int(final_speed)

func get_chase_target(player) -> Vector2:
	"""Comportamento di inseguimento specifico per tipo di fantasma"""
	var player_pos = player.global_position

	match ghost_type:
		GhostType.BLINKY:
			# Inseguimento diretto aggressivo
			return player_pos

		GhostType.PINKY:
			# Cerca di tendere un'imboscata davanti al player
			var player_direction = Vector2.ZERO
			if player.has_method("get_current_direction"):
				player_direction = player.get_current_direction()
			return player_pos + (player_direction * prediction_tiles * 32) + chase_offset

		GhostType.INKY:
			# Comportamento complesso basato su Blinky e player
			var blinky = get_tree().get_nodes_in_group("Blinky").slice(-1)[0] if get_tree().get_nodes_in_group("Blinky").size() > 0 else null
			if blinky:
				var vector_to_player = player_pos - blinky.global_position
				return blinky.global_position + (vector_to_player * 2) + chase_offset
			else:
				return player_pos + chase_offset

		GhostType.CLYDE:
			# Insegue direttamente solo se lontano, altrimenti scappa
			var distance_to_player = global_position.distance_to(player_pos)
			if distance_to_player > flee_distance:
				return player_pos
			else:
				return scatter_corner

	return player_pos

func get_frightened_target(player) -> Vector2:
	# Comportamento di fuga - si allontana dal giocatore
	var direction_away = global_position.direction_to(player.global_position) * -1
	return global_position + direction_away * 200

func navigate_to_target(target_pos: Vector2, current_speed: int, delta: float):
	# Imposta la destinazione
	agent.set_target_position(target_pos)

	# Ottieni la prossima posizione nel path
	var next_path_pos = agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)

	# Muovi direttamente l'Area2D
	global_position += direction * current_speed * delta

func _on_body_entered(body):
	if body.is_in_group("Player"):
		match current_state:
			GhostStates.CHASE, GhostStates.SCATTER:
				# Il fantasma uccide il giocatore
				body.death()
			GhostStates.FRIGHTENED:
				# Il giocatore mangia il fantasma
				get_eaten_by_player()
			GhostStates.EATEN:
				# Nessuna interazione quando è già mangiato
				pass

func _on_body_exited(body):
	# Opzionale: gestisci quando il player esce dall'area
	pass

func get_eaten_by_player():
	# Emetti segnale per il punteggio (200, 400, 800, 1600 punti in sequenza)
	ghost_eaten.emit(200)

	# Cambia stato a EATEN
	change_state(GhostStates.EATEN)

	# Feedback visivo/audio opzionale
	# AudioManager.play_sound("ghost_eaten")
	# EffectManager.show_points_popup(global_position, 200)

func change_state(new_state: GhostStates):
	current_state = new_state
	state_timer = 0.0

	# Azioni specifiche per cambio stato
	match new_state:
		GhostStates.SCATTER:
			# Usa l'angolo di scatter specifico
			modulate = ghost_color
			if normal_sprite and sprite:
				sprite.texture = normal_sprite

		GhostStates.FRIGHTENED:
			# Cambia aspetto per lo stato frightened
			modulate = Color.BLUE
			if frightened_sprite and sprite:
				sprite.texture = frightened_sprite

			# Avvia lampeggio negli ultimi secondi
			var time_left = frightened_duration - state_timer
			if time_left <= flash_warning_time:
				start_flashing()

		GhostStates.EATEN:
			# Cambia aspetto per indicare che è stato mangiato
			modulate = Color.GRAY
			if eaten_sprite and sprite:
				sprite.texture = eaten_sprite
			# Disabilita le collisioni con il player
			set_collision_mask_value(1, false)

		GhostStates.CHASE:
			# Ripristina aspetto normale
			modulate = ghost_color
			if normal_sprite and sprite:
				sprite.texture = normal_sprite
			# Ripristina le collisioni
			set_collision_mask_value(1, true)

func start_flashing():
	"""Inizia il lampeggio di avvertimento prima che finisca lo stato frightened"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	tween.tween_property(self, "modulate", Color.BLUE, 0.2)

# Funzione pubblica per attivare lo stato frightened (chiamata quando il player prende un power pellet)
func set_frightened():
	if current_state != GhostStates.EATEN:
		change_state(GhostStates.FRIGHTENED)

# Funzione per controllare se il fantasma può essere mangiato
func is_edible() -> bool:
	return current_state == GhostStates.FRIGHTENED

# Funzioni utility per gestire tunnel e zone speciali
func enter_tunnel():
	is_in_tunnel = true

func exit_tunnel():
	is_in_tunnel = false
