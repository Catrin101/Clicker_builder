# GameManager.gd - El cerebro del juego (Singleton) - CORREGIDO
extends Node

# Variables principales del juego
var player_points: int = 10  # Empezamos con 10 puntos para poder comprar el primer terreno
var total_points_per_second: float = 0.0
var is_placing_building: bool = false
var building_to_place: String = ""  # Ruta de la escena del edificio a colocar
var is_placing_mode: bool = false

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
	
	# NUEVO: Registrar puntos ganados en StatsManager
	StatsManager.register_points_earned(amount)
	
	print("Puntos añadidos: ", amount, " | Total: ", player_points)

# Función para quitar puntos (cuando se compra algo)
func subtract_points(amount: int) -> bool:
	if player_points >= amount:
		player_points -= amount
		points_changed.emit(player_points)
		
		# NUEVO: Registrar puntos gastados en StatsManager
		StatsManager.register_points_spent(amount)
		
		print("Puntos gastados: ", amount, " | Total restante: ", player_points)
		return true
	else:
		print("No tienes suficientes puntos. Tienes: ", player_points, " necesitas: ", amount)
		return false

# Función para recalcular el total de puntos por segundo - CORREGIDA
func recalculate_total_points_per_second():
	total_points_per_second = 0.0
	
	# Obtener referencia al GridManager
	var grid_manager = get_tree().get_first_node_in_group("grid_manager")
	if grid_manager:
		print("Recalculando PPS - Terrenos en cuadrícula: ", grid_manager.grid_cells.size())
		
		# Iterar sobre todos los terrenos en la cuadrícula
		for cell_key in grid_manager.grid_cells:
			var terrain = grid_manager.grid_cells[cell_key]
			
			# Si el terreno tiene un edificio
			if terrain.has_building and terrain.building_node:
				var building = terrain.building_node
				if building.has_method("get_total_points_per_second"):
					var building_pps = building.get_total_points_per_second()
					total_points_per_second += building_pps
					print("  Edificio ", building.building_name, " en ", cell_key, " aporta: ", building_pps, " PPS")
			
			# Si el terreno en sí es una estructura (como árboles, cultivos, etc.)
			elif terrain.has_method("get_total_points_per_second"):
				var structure_pps = terrain.get_total_points_per_second()
				total_points_per_second += structure_pps
				print("  Estructura ", terrain.structure_name if terrain.has_method("get_structure_name") else "Desconocida", " en ", cell_key, " aporta: ", structure_pps, " PPS")
	else:
		print("Error: No se encontró GridManager en el grupo 'grid_manager'")
	
	points_per_second_changed.emit(total_points_per_second)
	print("=== Total puntos por segundo recalculado: ", total_points_per_second, " ===")
	
	# NUEVO: Actualizar el PPS más alto alcanzado
	StatsManager.update_highest_pps(total_points_per_second)

# Función para iniciar el modo de colocación de edificios
func start_placing_mode(building_scene_path: String):
	is_placing_building = true
	is_placing_mode = true
	building_to_place = building_scene_path
	building_placement_started.emit(building_scene_path)
	print("Modo colocación iniciado para: ", building_scene_path)

# Función para cancelar el modo de colocación
func cancel_placing_mode():
	is_placing_building = false
	is_placing_mode = false
	building_to_place = ""
	building_placement_cancelled.emit()
	print("Modo colocación cancelado")

# Función para verificar si se puede comprar algo
func can_afford(cost: int) -> bool:
	return player_points >= cost

# Función que se llama cada segundo para añadir puntos automáticos
func _on_points_timer_timeout():
	var current_pps = total_points_per_second
	if current_pps > 0:
		var points_to_add = int(ceil(current_pps))
		add_points(points_to_add)
		print("GameManager Timer: +", points_to_add, " puntos automáticos (PPS: ", current_pps, ")")
	else:
		print("GameManager Timer: Sin PPS activos")
