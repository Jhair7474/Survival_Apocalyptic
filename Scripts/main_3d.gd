extends Node3D

func _ready():
	# 1. Obtenemos la referencia del jugador
	var player_node = $Player 
	
	# --- 2. OBTENEMOS LAS REFERENCIAS DE CADA ENEMIGO ---
	# Asegúrate de que los nombres ($Enemy, $Zombie) coincidan con los nodos de tu escena.
	var demon_node = $Enemy # Si tu demonio se llama 'Enemy'
	var zombie_node = $Enemy2 # Si tu zombi se llama 'Zombie'
	# ----------------------------------------------------

	# 3. Conectamos la referencia del jugador a CADA script de enemigo
	if player_node:
		# Asignar al Demonio (o Enemy original)
		if demon_node:
			demon_node.player = player_node
			print("Conexión Player-Demon establecida.")

		# Asignar al Zombi
		if zombie_node:
			zombie_node.player = player_node
			print("Conexión Player-Zombi establecida.")
			
	else:
		print("ERROR: No se encontró el nodo Player en la escena.")
