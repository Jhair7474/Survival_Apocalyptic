extends Node3D

func _ready():
	# 1. Obtenemos referencias a los nodos instanciados
	# Estos nombres deben coincidir EXACTAMENTE con los nombres de los nodos en la escena Main_3D
	var player_node = $Player 
	var enemy_node = $Enemy 

	# 2. Conectamos la referencia del jugador al script del enemigo
	if enemy_node and player_node:
		enemy_node.player = player_node
		print("Conexión Player-Enemy establecida. El enemigo debe perseguir al jugador.")
	else:
		print("ERROR: Verifique que Player y Enemy estén instanciados en Main_3D.")
