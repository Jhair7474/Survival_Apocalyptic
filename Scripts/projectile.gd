extends Area3D

@export var speed: float = 15.0 
var direction: Vector3 = Vector3.FORWARD
var damage: int = 10 

func _ready() -> void:
	# Conectamos la señal de colisión body_entered
	# Esto es una alternativa a conectar manualmente en el editor
	body_entered.connect(_on_body_entered)
	# Autodestrucción tras 3 segundos si no golpea nada
	set_life_time(3.0) 

func set_life_time(seconds: float):
	var timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.start(seconds)
	await timer.timeout
	if is_instance_valid(self):
		queue_free()

# Esta función es llamada desde player.gd para configurar la dirección y el daño
func setup(dir: Vector3, dmg: int):
	direction = dir.normalized()
	damage = dmg
	# Para que el proyectil mire hacia donde se mueve
	look_at(global_position + direction) 

func _process(delta: float) -> void:
	# Mueve el proyectil
	global_position += direction * speed * delta

# Función de colisión (activada por la señal body_entered)
func _on_body_entered(body: Node3D) -> void:
	# Verificamos si el cuerpo que golpea tiene la función take_damage (solo los enemigos la tienen)
	if body.has_method("take_damage"):
		# Aplicamos el daño (llama a la función en enemy.gd)
		body.take_damage(damage)
		
		# Destruimos el proyectil después de impactar
		queue_free() 
	
	# Si golpea algo que no es enemigo, también se destruye.
	# Esta línea asegura que no se destruya al chocar con el jugador (self)
	elif body != get_parent(): 
		queue_free()
