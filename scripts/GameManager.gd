# GameManager.gd - El cerebro del juego (Singleton) - CORREGIDO ERROR UNIX
extends Node

# Variables principales del juego
var player_points: int = 10
var total_points_per_second: float = 0.0
var is_placing_building: bool = false
var building_to_place: String = ""
var is_placing_mode: bool = false

# Variables para estadísticas del juego (Sprint 4)
var total_buildings_built: int = 0
var total_points_earned: int = 0
var total_points_spent: int = 0
var game_start_time: float = 0.0
var buildings_by_type: Dictionary = {}

# Timer para puntos automáticos
var points_timer: Timer

# Señales para comunicar cambios
signal points_changed(new_points: int)
signal points_per_second_changed(new_pps: float)
signal building_placement_started(building_scene: String)
signal building_placement_cancelled()
signal building_built(building_name: String)
signal milestone_reached(milestone_name: String, description: String)

func _ready():
	print("GameManager inicializado con ", player_points, " puntos")
	
	# Crear y configurar el timer para puntos automáticos
	points_timer = Timer.new()
	points_timer.wait_time = 1.0  # Cada segundo
	points_timer.timeout.connect(_on_points_timer_timeout)
	add_child(points_timer)
	points_timer.start()
	
	# CORRECCIÓN: Usar Time.get_unix_time_from_system() en lugar de dictionary
	game_start_time = Time.get_unix_time_from_system()
	
	print("Timer de puntos automáticos iniciado")

# Función para añadir puntos (mejorada para Sprint 4)
func add_points(amount: int):
	player_points += amount
	total_points_earned += amount
	points_changed.emit(player_points)
	
	# Verificar hitos
	check_milestones()
	
	if amount > 1:  # Solo mostrar para puntos automáticos
		print("Puntos automáticos añadidos: ", amount, " | Total: ", player_points)

# Función para quitar puntos (mejorada para Sprint 4)
func subtract_points(amount: int) -> bool:
	if player_points >= amount:
		player_points -= amount
		total_points_spent += amount
		points_changed.emit(player_points)
		print("Puntos gastados: ", amount, " | Total restante: ", player_points)
		return true
	else:
		print("No tienes suficientes puntos. Tienes: ", player_points, " necesitas: ", amount)
		return false

# Función para recalcular el total de puntos por segundo - MEJORADA
func recalculate_total_points_per_second():
	var old_pps = total_points_per_second
	total_points_per_second = 0.0
	
	# Limpiar conteo de edificios
	buildings_by_type.clear()
	
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
					
					# Contar edificios por tipo
					var building_name = building.building_name
					if buildings_by_type.has(building_name):
						buildings_by_type[building_name] += 1
					else:
						buildings_by_type[building_name] = 1
					
					print("  Edificio ", building_name, " en ", cell_key, " aporta: ", building_pps, " PPS")
			
			# Si el terreno en sí es una estructura
			elif terrain.has_method("get_total_points_per_second"):
				var structure_pps = terrain.get_total_points_per_second()
				total_points_per_second += structure_pps
				print("  Estructura en ", cell_key, " aporta: ", structure_pps, " PPS")
	else:
		print("Error: No se encontró GridManager en el grupo 'grid_manager'")
	
	# Emitir señal solo si cambió
	if abs(old_pps - total_points_per_second) > 0.001:
		points_per_second_changed.emit(total_points_per_second)
	
	print("=== Total puntos por segundo recalculado: ", total_points_per_second, " ===")

# Función para verificar hitos del juego
func check_milestones():
	# Hito de puntos acumulados
	if total_points_earned >= 1000 and not has_milestone("first_thousand"):
		milestone_reached.emit("first_thousand", "¡Has ganado tus primeros 1,000 puntos!")
		add_milestone("first_thousand")
	
	elif total_points_earned >= 10000 and not has_milestone("ten_thousand"):
		milestone_reached.emit("ten_thousand", "¡Impresionante! 10,000 puntos ganados.")
		add_milestone("ten_thousand")
	
	# Hito de PPS
	if total_points_per_second >= 10.0 and not has_milestone("ten_pps"):
		milestone_reached.emit("ten_pps", "¡Tu ciudad genera 10+ puntos por segundo!")
		add_milestone("ten_pps")
	
	elif total_points_per_second >= 50.0 and not has_milestone("fifty_pps"):
		milestone_reached.emit("fifty_pps", "¡Ciudad próspera! 50+ PPS alcanzados.")
		add_milestone("fifty_pps")

# Sistema de hitos
var milestones_achieved: Array = []

func add_milestone(milestone_name: String):
	if not milestones_achieved.has(milestone_name):
		milestones_achieved.append(milestone_name)

func has_milestone(milestone_name: String) -> bool:
	return milestones_achieved.has(milestone_name)

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

# Función que se llama cuando se construye un edificio (NUEVA)
func on_building_built(building_name: String):
	total_buildings_built += 1
	building_built.emit(building_name)
	
	# Verificar hitos de construcción
	if total_buildings_built == 5 and not has_milestone("five_buildings"):
		milestone_reached.emit("five_buildings", "¡Has construido 5 edificios!")
		add_milestone("five_buildings")
	elif total_buildings_built == 20 and not has_milestone("twenty_buildings"):
		milestone_reached.emit("twenty_buildings", "¡Una verdadera ciudad! 20 edificios.")
		add_milestone("twenty_buildings")

# Timer callback - MEJORADO
func _on_points_timer_timeout():
	var current_pps = total_points_per_second
	if current_pps > 0:
		var points_to_add = int(ceil(current_pps))
		add_points(points_to_add)

# Función para obtener estadísticas del juego - CORREGIDA
func get_game_stats() -> Dictionary:
	var current_time = Time.get_unix_time_from_system()
	var play_time = current_time - game_start_time
	
	return {
		"player_points": player_points,
		"total_points_per_second": total_points_per_second,
		"total_buildings_built": total_buildings_built,
		"total_points_earned": total_points_earned,
		"total_points_spent": total_points_spent,
		"buildings_by_type": buildings_by_type,
		"play_time_seconds": play_time,
		"milestones_achieved": milestones_achieved.size()
	}

# Función para verificar si el juego ha terminado (todos los edificios construidos)
func check_game_completion() -> bool:
	var required_buildings = [
		"House", "Tavern", "Inn", "Castle", "BaseMilitar", 
		"Chapel", "Clock", "Villa", "Thayched", "TreeHouse"
	]
	
	for building_type in required_buildings:
		if not buildings_by_type.has(building_type) or buildings_by_type[building_type] == 0:
			return false
	
	return true
