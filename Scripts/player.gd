extends CharacterBody3D

# Velocidad de movimiento del jugador
@export var speed: float = 8.0 
const JUMP_VELOCITY = 4.5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") 

# --- ANIMACIONES: ¡VERIFICA ESTAS LÍNEAS! ---
# Ruta para el AnimationPlayer. ESTA RUTA DEBE SER EXACTA
@onready var anim_player: AnimationPlayer = $Character_Male_1/AnimationPlayer 
const ANIM_IDLE = "Idle" 
const ANIM_RUN = "Run"   
# ---------------------------------------------

# --- ATAQUE AUTOMÁTICO (NUEVA LÓGICA) ---
# Cargamos la escena del proyectil 3D para instanciarlo.
const ProjectileScene = preload("res://Entities/projectile.tscn")
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.0 # Ataca cada 1.0 segundo
var time_until_next_attack: float = 0.0 


func _ready() -> void:
	time_until_next_attack = 0.0

func _physics_process(delta: float) -> void:
	# --------------------
	# 1. LÓGICA DE MOVIMIENTO
	# --------------------
	var input_dir = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		# Control de Animación: Correr/Caminar
		if anim_player and anim_player.current_animation != ANIM_RUN:
			anim_player.play(ANIM_RUN)

	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		
		# Control de Animación: Detenerse
		if anim_player and anim_player.current_animation != ANIM_IDLE:
			anim_player.play(ANIM_IDLE)

	move_and_slide()
	
	# --------------------
	# 2. LÓGICA DE ATAQUE AUTOMÁTICO
	# --------------------
	time_until_next_attack -= delta
	
	if time_until_next_attack <= 0:
		perform_auto_attack()
		time_until_next_attack = attack_cooldown

func perform_auto_attack():
	# (TO DO: En el futuro, esta función debe buscar el enemigo más cercano)
	
	var projectile = ProjectileScene.instantiate()
	
	# La posición inicial del proyectil (ligeramente por encima del jugador)
	projectile.global_position = global_position + Vector3(0, 0.5, 0)
	
	# Por ahora, disparamos hacia adelante (eje Z negativo)
	var attack_direction = Vector3.BACK 
	
	# Asumimos que la función setup() está en projectile.gd
	projectile.setup(attack_direction, attack_damage)
	
	# Añadimos el proyectil al nodo raíz (Main_3D) para que exista en el mundo
	get_parent().add_child(projectile)
