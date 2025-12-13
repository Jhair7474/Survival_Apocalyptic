extends CharacterBody3D

# Esta variable es asignada desde Main.gd
var player = null

@export var speed: float = 2.0 
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") 

# Estadísticas de Contenido (requisito: vida y XP)
var health: int = 10 
var xp_value: int = 1 

# --- ANIMACIONES: ¡VERIFICA ESTAS LÍNEAS! ---
# Reemplaza con la ruta exacta del AnimationPlayer de tu enemigo.
@onready var anim_player: AnimationPlayer = $Skeleton/AnimationPlayer # Usando Skeleton como ejemplo
const ANIM_IDLE = "Idle" 
const ANIM_RUN = "Run"   
# ---------------------------------------------


func _physics_process(delta: float) -> void:
	# Aplicar la gravedad (para que se mantenga en el suelo)
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Lógica de persecución
	if player:
		# 1. Calcular la dirección hacia el jugador
		var direction_to_player = (player.global_position - global_position).normalized()
		
		# 2. Ignoramos la altura (eje Y) para que no intenten subir
		direction_to_player.y = 0 
		
		# 3. Aplicar movimiento
		velocity.x = direction_to_player.x * speed
		velocity.z = direction_to_player.z * speed
		
		# Control de Animación: Correr/Caminar (mientras persigue)
		if anim_player and anim_player.current_animation != ANIM_RUN:
			anim_player.play(ANIM_RUN)
		
		# Rotar para que el enemigo mire hacia donde se mueve
		look_at(player.global_position, Vector3.UP)
		
	else:
		# Si no encuentra al jugador, desacelera suavemente
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		
		# Control de Animación: Detenerse
		if anim_player and anim_player.current_animation != ANIM_IDLE:
			anim_player.play(ANIM_IDLE)
		
	move_and_slide()


# Función llamada por el proyectil del jugador
func take_damage(amount: int):
	health -= amount
	print(name, " ha recibido ", amount, " de daño. Vida restante: ", health)
	
	if health <= 0:
		die()

func die():
	print(name, " ha sido destruido.")
	queue_free() # Destruye el enemigo
