extends Node3D

# --- CONFIGURACIÓN DE HORDAS ---
@export_group("Configuración de Enemigos")
# Arrastra aquí tus archivos .tscn (enemy.tscn y enemy2.tscn) desde el sistema de archivos
@export var demon_scene: PackedScene 
@export var zombie_scene: PackedScene 

@export_group("Configuración de Olas")
@export var spawn_radius_min: float = 5.0  # Distancia mínima del jugador
@export var spawn_radius_max: float = 10.0 # Distancia máxima del jugador
@export var initial_enemy_count: int = 3   # Enemigos en la ronda 1

var current_wave: int = 0
var enemies_alive: int = 0
var player_ref: CharacterBody3D = null

func _ready():
	# 1. Encontrar al jugador
	player_ref = $Player
	if not player_ref:
		print("ERROR: No se encuentra al nodo Player.")
		return
	
	# 2. Iniciar la primera horda después de 2 segundos
	await get_tree().create_timer(2.0).timeout
	start_new_wave()

func start_new_wave():
	current_wave += 1
	print("--- INICIANDO HORDA ", current_wave, " ---")
	
	# --- FÓRMULA DE DIFICULTAD ---
	# Cantidad: Aumenta 2 enemigos por cada horda nueva
	var amount_to_spawn = initial_enemy_count + ((current_wave - 1) * 2)
	
	# Daño: Aumenta 5 puntos de daño cada 2 hordas
	var extra_damage = (current_wave - 1) * 5
	
	spawn_horde(amount_to_spawn, extra_damage)

func spawn_horde(count: int, bonus_damage: int):
	enemies_alive = count
	
	for i in range(count):
		spawn_random_enemy(bonus_damage)
		# Esperar un poquito entre cada spawn para que no aparezcan todos de golpe exacto
		await get_tree().create_timer(0.2).timeout

func spawn_random_enemy(bonus_damage: int):
	if not player_ref: return
	
	# 1. Elegir aleatoriamente entre Demonio o Zombi
	var chosen_scene = demon_scene
	if randf() > 0.5: # 50% de probabilidad
		chosen_scene = zombie_scene
		
	# Verificar que asignaste las escenas en el Inspector
	if chosen_scene == null:
		print("ERROR: No has asignado las escenas de los enemigos en el Inspector de Main3D")
		return

	# 2. Instanciar (Crear) el enemigo
	var enemy_instance = chosen_scene.instantiate()
	
	# 3. Calcular posición aleatoria alrededor del jugador
	var angle = randf() * TAU # Un ángulo aleatorio (0 a 360 grados)
	var distance = randf_range(spawn_radius_min, spawn_radius_max)
	
	# Matemáticas para obtener la posición X y Z
	var spawn_pos = player_ref.global_position
	spawn_pos.x += sin(angle) * distance
	spawn_pos.z += cos(angle) * distance
	# Mantenemos la misma altura que el jugador para que no aparezcan bajo tierra
	spawn_pos.y = player_ref.global_position.y 
	
	enemy_instance.global_position = spawn_pos
	
	# 4. Configurar al enemigo (Darle la referencia del jugador y aumentar daño)
	enemy_instance.player = player_ref
	
	# Aumentamos el daño base del enemigo según la horda
	if "attack_damage" in enemy_instance:
		enemy_instance.attack_damage += bonus_damage
	
	# 5. Conectar la señal de muerte
	enemy_instance.enemy_died.connect(_on_enemy_died)
	
	# 6. Añadir a la escena
	add_child(enemy_instance)

func _on_enemy_died():
	enemies_alive -= 1
	print("Enemigo derrotado. Restantes: ", enemies_alive)
	
	if enemies_alive <= 0:
		print("¡Horda completada!")
		# Esperar unos segundos antes de la siguiente horda
		await get_tree().create_timer(3.0).timeout
		start_new_wave()
