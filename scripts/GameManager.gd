# GameManager.gd - El cerebro del juego (Singleton)
extends Node

# Variables principales del juego
var player_points: int = 10  # Empezamos con 10 puntos para poder comprar el primer terreno
var total_points_per_second: float = 0.0
var is_placing_building: bool = false
var building_to_place: String = ""  # Ruta de la escena del edificio a colocar

# Señales para comunicar cambios
signal points_changed(new_points: int)
signal points_per_second_changed(new_pps: float)
signal building_placement_started(building_scene: String)
signal building_placement_cancelled()

func _ready():
	print("GameManager inicializado con ", player_points, " puntos")

# Función para añadir puntos (llamada por clic y por el timer)
func add_points(amount: int):
	player_points += amount
	points_changed.emit(player_points)
	print("Puntos añadidos: ", amount, " | Total: ", player_points)

# Función para quitar puntos (cuando se compra algo)
func subtract_points(amount: int) -> bool:
	if player_points >= amount:
		player_points -= amount
		points_changed.emit(player_points)
		print("Puntos gastados: ", amount, " | Total restante: ", player_points)
		return true
	else:
		print("No tienes suficientes puntos. Tienes: ", player_points, " necesitas: ", amount)
		return false

# Función para recalcular el total de puntos por segundo
func recalculate_total_points_per_second():
	total_points_per_second = 0.0
	
	# Obtener referencia al GridManager
	var grid_manager = get_tree().get_first_node_in_group("grid_manager")
	if grid_manager:
		# Iterar sobre todos los edificios en la cuadrícula
		for cell_key in grid_manager.grid_cells:
			var cell_content = grid_manager.grid_cells[cell_key]
			# Solo contar edificios (que tienen points_per_second)
			if cell_content.has_method("get_total_points_per_second"):
				total_points_per_second += cell_content.get_total_points_per_second()
	
	points_per_second_changed.emit(total_points_per_second)
	print("Total puntos por segundo recalculado: ", total_points_per_second)

# Función para iniciar el modo de colocación de edificios
func start_placing_mode(building_scene_path: String):
	is_placing_building = true
	building_to_place = building_scene_path
	building_placement_started.emit(building_scene_path)
	print("Modo colocación iniciado para: ", building_scene_path)

# Función para cancelar el modo de colocación
func cancel_placing_mode():
	is_placing_building = false
	building_to_place = ""
	building_placement_cancelled.emit()
	print("Modo colocación cancelado")

# Función para verificar si se puede comprar algo
func can_afford(cost: int) -> bool:
	return player_points >= cost

# Función que se llama cada segundo para añadir puntos automáticos
func _on_points_timer_timeout():
	if total_points_per_second > 0:
		add_points(int(total_points_per_second))
