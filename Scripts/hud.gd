
extends CanvasLayer

# Señales para comunicar al Main qué botón se presionó
signal retry_pressed
signal menu_pressed

# Referencias a los textos
@onready var label_score = $GameInfo/LabelScore
@onready var label_wave = $GameInfo/LabelWave
@onready var label_enemies = $GameInfo/LabelEnemies
@onready var health_bar = $GameInfo/HealthBar
# Referencia a la pantalla de Game Over
@onready var game_over_screen = $GameOverScreen

func _ready():
	# Asegurarnos de que la pantalla de Game Over esté oculta al iniciar
	game_over_screen.visible = false
	
	# Conectar botones (Asegúrate de que los nodos se llamen así o ajusta la ruta)
	$GameOverScreen/ButtonRetry.pressed.connect(_on_retry_pressed)
	$GameOverScreen/ButtonMenu.pressed.connect(_on_menu_pressed)

# Funciones para actualizar textos
func update_score(value: int):
	label_score.text = "Puntos: " + str(value)

func update_wave(value: int):
	label_wave.text = "Oleada: " + str(value)

func update_enemies(value: int):
	label_enemies.text = "Enemigos restantes: " + str(value)
	
func update_health(value: int):
	# Asignamos el valor a la barra
	health_bar.value = value

# Función para mostrar Game Over
func show_game_over():
	game_over_screen.visible = true
	# IMPORTANTE: Liberar el mouse para poder hacer click
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# Funciones internas de los botones
func _on_retry_pressed():
	retry_pressed.emit()

func _on_menu_pressed():
	menu_pressed.emit()
