extends Control

# Ruta a la escena principal del juego que ya tienes.
const GAME_SCENE = "res://Entities/main_3d.tscn"

# Se llama cuando el botón "Play" es presionado
func _on_play_button_pressed():
	# Carga la escena principal del juego
	get_tree().change_scene_to_file(GAME_SCENE)
