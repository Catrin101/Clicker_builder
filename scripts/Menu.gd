# Menu.gd - Menú principal del juego
extends Control

# Referencias a nodos
@onready var new_game_button: Button = $MenuContainer/MenuVBox/ButtonsContainer/NewGameButton
@onready var load_game_button: Button = $MenuContainer/MenuVBox/ButtonsContainer/LoadGameButton
@onready var quit_button: Button = $MenuContainer/MenuVBox/ButtonsContainer/QuitButton

func _ready():
	# Conectar señales de botones
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Verificar si hay guardados disponibles
	update_load_button_state()
	
	print("Menú principal inicializado")

func update_load_button_state():
	# Verificar si existe al menos un guardado
	var has_saves = false
	for i in range(1, SaveSystem.MAX_SAVE_SLOTS + 1):
		if SaveSystem.has_save_file("slot_" + str(i)):
			has_saves = true
			break
	
	# Deshabilitar botón de cargar si no hay guardados
	load_game_button.disabled = not has_saves
	
	if not has_saves:
		load_game_button.text = "📂 Cargar Partida (Sin guardados)"

func _on_new_game_pressed():
	print("Nueva partida iniciada")
	
	# Resetear todos los managers antes de empezar
	reset_game_state()
	
	# Cambiar a la escena del juego
	get_tree().change_scene_to_file("res://escenas/main.tscn")

func _on_load_game_pressed():
	print("Abriendo selector de partidas guardadas")
	
	# TODO: Aquí puedes crear una escena de selección de slots
	# Por ahora, cargamos el slot_1 directamente si existe
	if SaveSystem.has_save_file("slot_1"):
		var success = SaveSystem.load_game("slot_1")
		if success:
			# Cambiar a la escena del juego
			get_tree().change_scene_to_file("res://escenas/main.tscn")
		else:
			print("Error al cargar partida")
	else:
		print("No hay guardados en slot_1")

func _on_quit_pressed():
	print("Saliendo del juego")
	get_tree().quit()

func reset_game_state():
	# Resetear GameManager
	if GameManager:
		GameManager.player_points = 10
		GameManager.total_points_per_second = 0.0
		GameManager.is_placing_building = false
		GameManager.building_to_place = ""
		GameManager.is_placing_mode = false
	
	# Resetear StatsManager
	if StatsManager:
		StatsManager.reset_stats()
	
	# Resetear GameCompletionManager
	if GameCompletionManager:
		GameCompletionManager.reset_completion_state()
	
	print("Estado del juego reseteado")
