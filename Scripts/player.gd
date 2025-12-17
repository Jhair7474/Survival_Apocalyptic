extends CharacterBody3D

# --- CONFIGURACIÓN DE MOVIMIENTO ---
@export var speed: float = 8.0
@export var rotation_speed: float = 5.0
const JUMP_VELOCITY = 4.5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- ESTADÍSTICAS DEL JUGADOR ---
@export var max_health: int = 100
var current_health: int

# --- ANIMACIONES ---
@onready var anim_player: AnimationPlayer = $Character_Male_2/AnimationPlayer
const ANIM_IDLE = "Idle"
const ANIM_RUN = "Run"
const ANIM_HIT_REACT = "HitReact"
const ANIM_DEATH = "Death"
const ANIM_ATTACK_RUN = "Run_Attack"
const ANIM_ATTACK_IDLE = "Idle_Attack"

# --- CONFIGURACIÓN DE ATAQUE (RÁFAGA) ---
const ProjectileScene = preload("res://Entities/projectile.tscn")
@export var damage: int = 10
@export var shots_per_burst: int = 3
@export var time_between_shots: float = 0.2
@export var reload_time: float = 1.5

@export_group("Ajustes de Disparo")
@export var projectile_offset: Vector3 = Vector3(0, 1.0, 0.8) 
@export var shoot_forward_vector: Vector3 = Vector3(0, 0, 1) 

# --- ESTADOS ---
var can_shoot: bool = true 
var is_dead: bool = false
var is_taking_damage: bool = false
var is_attacking_anim: bool = false # Para saber si estamos en animación de ataque

func _ready() -> void:
	current_health = max_health
	if anim_player:
		anim_player.play(ANIM_IDLE)
		# Conectamos la señal para saber cuándo terminan las animaciones de ataque/daño
		anim_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if is_dead:
		return # Si está muerto, no hace nada

	# 1. Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Si estamos recibiendo daño, podemos optar por bloquear el movimiento o permitirlo.
	# Aquí permitimos movernos un poco pero priorizamos la animación visual.
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var rotation_input = input_dir.x 
	var forward_input = input_dir.y   

	# Rotación
	if rotation_input != 0:
		rotate_y(-rotation_input * rotation_speed * delta)

	# Movimiento
	var direction = (transform.basis * Vector3(0, 0, forward_input)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	# 3. CONTROL DE ANIMACIONES DE MOVIMIENTO
	# Solo cambiamos a Idle/Run si NO estamos atacando ni recibiendo daño
	if not is_attacking_anim and not is_taking_damage:
		if direction:
			if anim_player.current_animation != ANIM_RUN:
				anim_player.play(ANIM_RUN)
		else:
			if anim_player.current_animation != ANIM_IDLE:
				anim_player.play(ANIM_IDLE)
	
	# 4. DISPARO AUTOMÁTICO
	if can_shoot and not is_taking_damage:
		start_auto_burst()

# --- SISTEMA DE COMBATE ---

func start_auto_burst():
	can_shoot = false
	is_attacking_anim = true
	
	# DECIDIR ANIMACIÓN DE ATAQUE
	# Si nos estamos moviendo (velocidad > 0.1), usamos Run_Attack
	if velocity.length() > 0.1:
		anim_player.play(ANIM_ATTACK_RUN)
	else:
		anim_player.play(ANIM_ATTACK_IDLE)
	
	# Disparar la ráfaga
	for i in range(shots_per_burst):
		fire_projectile()
		await get_tree().create_timer(time_between_shots).timeout
	
	# Esperar recarga
	await get_tree().create_timer(reload_time).timeout
	can_shoot = true

func fire_projectile():
	var projectile = ProjectileScene.instantiate()
	projectile.global_position = to_global(projectile_offset)
	var final_direction = (global_transform.basis * shoot_forward_vector).normalized()
	projectile.setup(final_direction, damage, self)
	get_parent().add_child(projectile)

# --- SISTEMA DE DAÑO Y MUERTE ---

func take_damage(amount: int):
	if is_dead: return
	
	current_health -= amount
	print("Jugador herido. Vida: ", current_health)
	
	if current_health <= 0:
		die()
	else:
		# Animación de recibir golpe
		is_taking_damage = true
		# Stop para reiniciar la animación si nos pegan dos veces rápido
		anim_player.stop() 
		anim_player.play(ANIM_HIT_REACT)

func die():
	is_dead = true
	print("El jugador ha muerto.")
	anim_player.play(ANIM_DEATH)
	# Desactivar colisiones o reiniciar escena después de un tiempo
	set_physics_process(false) # Dejar de procesar físicas

# Callback cuando termina una animación
func _on_animation_finished(anim_name: String):
	if anim_name == ANIM_ATTACK_RUN or anim_name == ANIM_ATTACK_IDLE:
		is_attacking_anim = false
	elif anim_name == ANIM_HIT_REACT:
		is_taking_damage = false
