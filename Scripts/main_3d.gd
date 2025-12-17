extends Node3D

# --- REFERENCIAS A NODOS ---
# Buscamos el nodo Player y el nodo HUD en la escena
@onready var player_ref = $Player
@onready var hud = $HUD # Asegúrate de que el nodo de la escena HUD se llame "HUD"

# --- CONFIGURACIÓN DE RUTAS ---
# Ajusta esta ruta si tu menú principal está en otra carpeta
const MENU_SCENE_PATH = "res://Entities/main_menu.tscn"

# --- CONFIGURACIÓN DE ENEMIGOS (Inspector) ---
@export_group("Configuración de Enemigos")
@export var demon_scene: PackedScene 
@export var zombie_scene: PackedScene 

# --- CONFIGURACIÓN DE OLEADAS (Inspector) ---
@export_group("Configuración de Olas")
@export var spawn_radius_min: float = 5.0  # Distancia mínima
@export var spawn_radius_max: float = 10.0 # Distancia máxima
@export var initial_enemy_count: int = 3   # Enemigos ronda 1

# --- VARIABLES INTERNAS DEL JUEGO ---
var current_wave: int = 0
var enemies_alive: int = 0
var score: int = 0

func _ready():
	# 1. Verificar Player
	if not player_ref:
		print("ERROR CRÍTICO: No se encuentra el nodo Player en Main3D.")
		return
	
	# Conectamos la señal de muerte del jugador (para el Game Over)
	if player_ref.has_signal("player_died"):
		player_ref.player_died.connect(_on_player_died)
	
	# 2. Configurar HUD
	if hud:
		
		player_ref.health_changed.connect(hud.update_health)
		# Conectamos las señales de los botones del HUD
		hud.update_health(player_ref.max_health)
		hud.retry_pressed.connect(_on_retry)
		hud.menu_pressed.connect(_on_menu)
		
		# Ponemos los contadores a cero visualmente
		hud.update_score(0)
		hud.update_wave(0)
		hud.update_enemies(0)
	else:
		print("ADVERTENCIA: No se encontró el nodo HUD. Arrastra HUD.tscn a la escena.")

	# 3. Iniciar el juego (primera horda) tras una pequeña espera
	await get_tree().create_timer(2.0).timeout
	# Verificamos que el jugador siga vivo antes de empezar
	if is_instance_valid(player_ref) and not player_ref.is_dead:
		start_new_wave()

func start_new_wave():
	current_wave += 1
	print("--- INICIANDO HORDA ", current_wave, " ---")
	
	# Actualizar HUD de Oleada
	if hud: hud.update_wave(current_wave)
	
	# FÓRMULA DE DIFICULTAD
	# Cantidad: Base + 2 por cada nueva oleada
	var amount_to_spawn = initial_enemy_count + ((current_wave - 1) * 2)
	# Daño: Aumenta 5 puntos cada oleada (ajustable)
	var extra_damage = (current_wave - 1) * 5
	
	spawn_horde(amount_to_spawn, extra_damage)

func spawn_horde(count: int, bonus_damage: int):
	enemies_alive = count
	
	# Actualizar HUD de Enemigos Restantes
	if hud: hud.update_enemies(enemies_alive)
	
	for i in range(count):
		# Si el jugador muere mientras spawnean, paramos
		if not is_instance_valid(player_ref) or player_ref.is_dead:
			break
			
		spawn_random_enemy(bonus_damage)
		# Pequeña pausa entre apariciones para que no salgan todos juntos
		await get_tree().create_timer(0.2).timeout

func spawn_random_enemy(bonus_damage: int):
	if not player_ref: return
	
	# 1. Elegir enemigo aleatorio
	var chosen_scene = demon_scene
	if randf() > 0.5: # 50% probabilidad
		chosen_scene = zombie_scene
		
	if chosen_scene == null:
		print("ERROR: Faltan asignar las escenas de enemigos en el Inspector.")
		return

	# 2. Instanciar
	var enemy_instance = chosen_scene.instantiate()
	
	# 3. Calcular posición en círculo alrededor del jugador
	var angle = randf() * TAU
	var distance = randf_range(spawn_radius_min, spawn_radius_max)
	
	var spawn_pos = player_ref.global_position
	spawn_pos.x += sin(angle) * distance
	spawn_pos.z += cos(angle) * distance
	spawn_pos.y = player_ref.global_position.y 
	
	enemy_instance.global_position = spawn_pos
	
	# 4. Configurar datos del enemigo
	enemy_instance.player = player_ref
	
	if "attack_damage" in enemy_instance:
		enemy_instance.attack_damage += bonus_damage
	
	# 5. Conectar señal de muerte para contar puntos y progreso
	enemy_instance.enemy_died.connect(_on_enemy_died)
	
	add_child(enemy_instance)

# --- CALLBACKS (Respuestas a señales) ---

func _on_enemy_died():
	# Reducir contador de enemigos vivos
	enemies_alive -= 1
	
	# Aumentar puntaje (+10 por enemigo)
	score += 10
	
	# Actualizar el HUD
	if hud:
		hud.update_enemies(enemies_alive)
		hud.update_score(score)
	
	print("Enemigo caído. Restantes: ", enemies_alive, " | Puntos: ", score)
	
	# Verificar fin de oleada
	if enemies_alive <= 0:
		print("¡Horda completada!")
		await get_tree().create_timer(3.0).timeout
		
		# Solo lanzamos la siguiente ola si el jugador sigue vivo
		if is_instance_valid(player_ref) and not player_ref.is_dead:
			start_new_wave()

func _on_player_died():
	print("GAME OVER - Iniciando secuencia de fin de juego")
	# Esperamos 2 segundos para ver la animación de muerte del jugador
	await get_tree().create_timer(2.0).timeout
	
	if hud:
		hud.show_game_over()

# Botón "Reintentar" presionado en el HUD
func _on_retry():
	get_tree().reload_current_scene()

# Botón "Menú" presionado en el HUD
func _on_menu():
	get_tree().change_scene_to_file(MENU_SCENE_PATH)
