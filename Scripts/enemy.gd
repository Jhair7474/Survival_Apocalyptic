extends CharacterBody3D

# Referencia al jugador (asignada desde Main.gd)
var player = null

@export var speed: float = 2.0 
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") 

# --- ESTADÍSTICAS ---
# Aumentamos la vida a 50. Si tu proyectil hace 10 de daño, morirá en 5 tiros.
@export var health: int = 50 
var xp_value: int = 1 

# --- ANIMACIONES ---
# ¡OJO! Cambia "$Demon" por "$Zombie" si estás en el script del zombi.
@onready var anim_player: AnimationPlayer = $Demon/AnimationPlayer 

const ANIM_IDLE = "Idle"
const ANIM_RUN = "Run"
# Usamos tus nombres exactos:
const ANIM_HIT = "HitRecieve" 
const ANIM_DEATH = "Death"

# Variable para controlar si el enemigo está muerto (para dejar de moverse)
var is_dead: bool = false
var is_hurting: bool = false # Para saber si está en la animación de impacto

func _physics_process(delta: float) -> void:
	# 1. Si está muerto, aplicamos gravedad pero NO calculamos movimiento ni rotación
	if is_dead:
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return # Salimos de la función aquí para que no persiga

	# 2. Si está recibiendo daño ("aturdido"), esperamos a que termine
	if is_hurting:
		# Si la animación de golpe terminó, volvemos a la normalidad
		if not anim_player.is_playing() or anim_player.current_animation != ANIM_HIT:
			is_hurting = false
		else:
			# Mientras le duele, aplicamos gravedad y frenamos, pero no persigue
			if not is_on_floor():
				velocity.y -= gravity * delta
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			move_and_slide()
			return

	# --- 3. COMPORTAMIENTO NORMAL (PERSECUCIÓN) ---
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	if player:
		var direction_to_player = (player.global_position - global_position).normalized()
		direction_to_player.y = 0 
		
		velocity.x = direction_to_player.x * speed
		velocity.z = direction_to_player.z * speed
		
		# Solo animamos a correr si NO se está reproduciendo ya
		if anim_player and anim_player.current_animation != ANIM_RUN:
			anim_player.play(ANIM_RUN)
		
		look_at(player.global_position, Vector3.UP)
		
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		
		if anim_player and anim_player.current_animation != ANIM_IDLE:
			anim_player.play(ANIM_IDLE)
		
	move_and_slide()

# Función llamada por el proyectil
func take_damage(amount: int):
	# Si ya está muerto, ignoramos más daño
	if is_dead:
		return

	health -= amount
	print(name, " Vida restante: ", health)
	
	if health <= 0:
		die()
	else:
		# --- LÓGICA DE RECIBIR GOLPE ---
		is_hurting = true
		if anim_player.has_animation(ANIM_HIT):
			# Stop() fuerza a reiniciar la animación si recibe dos balas seguidas
			anim_player.stop() 
			anim_player.play(ANIM_HIT)

func die():
	is_dead = true
	print(name, " ha muerto.")
	
	# Detenemos el movimiento en seco
	velocity = Vector3.ZERO
	
	# Desactivamos la colisión para que el jugador no choque con el cadáver
	# Asume que tienes un CollisionShape3D como hijo directo
	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred("disabled", true)
	
	# Reproducir animación de muerte
	if anim_player.has_animation(ANIM_DEATH):
		anim_player.play(ANIM_DEATH)
		
		# Opción A: Esperar lo que dure la animación exacta
		# await anim_player.animation_finished
		
		# Opción B: Esperar un tiempo fijo (ej. 3 segundos) para ver el cuerpo tirado
		await get_tree().create_timer(3.0).timeout
	else:
		# Si no hay animación, esperamos un poco igual
		await get_tree().create_timer(0.5).timeout

	# Adiós definitivo
	queue_free()
