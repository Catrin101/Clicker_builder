# GridManager.gd - Gestor de la cuadrícula (ACTUALIZADO PARA SPRINT 2)
extends Node2D

# Diccionario para almacenar las casillas (clave: "x,y", valor: nodo)
var grid_cells: Dictionary = {}

# Variables de configuración
var cell_size: int = 128  # Tamaño de cada casilla en píxeles
var land_cost: int = 10  # Costo inicial del terreno
var land_cost_multiplier: float = 1.2  # Multiplicador del costo por cada terreno comprado

# Señales
signal terrain_placed(x: int, y: int)
signal building_placed(x: int, y: int)

func _ready():
	# Añadir este nodo al grupo grid_manager para que GameManager lo pueda encontrar
	add_to_group("grid_manager")
	# Colocar el terreno inicial
	add_initial_terrain()

# Función para colocar el primer terreno en el centro
func add_initial_terrain():
	var terrain_scene = preload("res://escenas/terrain.tscn")
	var terrain_instance = terrain_scene.instantiate()
	
	# Posición inicial (0, 0)
	var x = 0
	var y = 0
	
	# Configurar la posición visual
	terrain_instance.position = Vector2(x * cell_size, y * cell_size)
	terrain_instance.grid_x = x
	terrain_instance.grid_y = y
	
	# Añadir al nodo y al diccionario
	add_child(terrain_instance)
	grid_cells[str(x) + "," + str(y)] = terrain_instance
	
	print("Terreno inicial colocado en (", x, ", ", y, ")")

# Función para verificar si se puede expandir en una posición
func can_expand(x: int, y: int) -> bool:
	# No se puede expandir si ya hay algo en esa posición
	if grid_cells.has(str(x) + "," + str(y)):
		return false
	
	# Verificar si está adyacente a un terreno existente
	var adjacent_positions = [
		Vector2i(x + 1, y),
		Vector2i(x - 1, y),
		Vector2i(x, y + 1),
		Vector2i(x, y - 1)
	]
	
	for pos in adjacent_positions:
		if grid_cells.has(str(pos.x) + "," + str(pos.y)):
			return true
	
	return false

# Función para comprar y colocar nuevo terreno
func buy_and_place_terrain(x: int, y: int) -> bool:
	if not can_expand(x, y):
		print("No se puede expandir a (", x, ", ", y, ")")
		return false
	
	if not GameManager.can_afford(land_cost):
		print("No tienes suficientes puntos para comprar terreno. Costo: ", land_cost)
		return false
	
	# Cobrar el costo
	if GameManager.subtract_points(land_cost):
		# Instanciar nuevo terreno
		var terrain_scene = preload("res://escenas/terrain.tscn")
		var terrain_instance = terrain_scene.instantiate()
		
		# Configurar posición
		terrain_instance.position = Vector2(x * cell_size, y * cell_size)
		terrain_instance.grid_x = x
		terrain_instance.grid_y = y
		
		# Añadir al nodo y al diccionario
		add_child(terrain_instance)
		grid_cells[str(x) + "," + str(y)] = terrain_instance
		
		# Aumentar el costo para la próxima compra
		land_cost = int(land_cost * land_cost_multiplier)
		
		terrain_placed.emit(x, y)
		print("Nuevo terreno colocado en (", x, ", ", y, "). Próximo costo: ", land_cost)
		return true
	
	return false

# NUEVA FUNCIÓN: Obtener los vecinos de una casilla (MEJORADA PARA EDIFICIOS)
func get_neighbors(x: int, y: int) -> Dictionary:
	var neighbors = {}
	var adjacent_positions = [
		{"dir": "right", "pos": Vector2i(x + 1, y)},
		{"dir": "left", "pos": Vector2i(x - 1, y)},
		{"dir": "down", "pos": Vector2i(x, y + 1)},
		{"dir": "up", "pos": Vector2i(x, y - 1)}
	]
	
	for adj in adjacent_positions:
		var key = str(adj.pos.x) + "," + str(adj.pos.y)
		if grid_cells.has(key):
			var terrain = grid_cells[key]
			# Si el terreno tiene un edificio, devolver el edificio
			if terrain.has_building and terrain.building_node:
				neighbors[adj.dir] = terrain.building_node
			# Si no tiene edificio pero es una estructura, devolver la estructura
			elif terrain.has_method("get_structure_name"):
				neighbors[adj.dir] = terrain
	
	return neighbors

# Función para verificar si una posición tiene terreno
func has_terrain(x: int, y: int) -> bool:
	var key = str(x) + "," + str(y)
	return grid_cells.has(key)

# FUNCIÓN MEJORADA: Colocar un edificio
func place_building(x: int, y: int, building_scene_path: String) -> bool:
	# Verificar que hay terreno en esa posición
	if not has_terrain(x, y):
		print("No hay terreno en (", x, ", ", y, ")")
		return false
	
	var key = str(x) + "," + str(y)
	var current_cell = grid_cells[key]
	
	# Verificar que el terreno no tenga ya un edificio
	if current_cell.has_building:
		print("Ya hay un edificio en (", x, ", ", y, ")")
		return false
	
	# Cargar y colocar el edificio
	var building_scene = load(building_scene_path)
	if not building_scene:
		print("Error: No se pudo cargar la escena del edificio: ", building_scene_path)
		return false
	
	var building_instance = building_scene.instantiate()
	
	# Configurar posición en la cuadrícula
	building_instance.position = Vector2(x * cell_size, y * cell_size)
	building_instance.grid_x = x
	building_instance.grid_y = y
	
	# Añadir como hijo del nodo actual
	add_child(building_instance)
	
	# Marcar el terreno como ocupado
	current_cell.has_building = true
	current_cell.building_node = building_instance
	
	building_placed.emit(x, y)
	print("Edificio colocado en (", x, ", ", y, "): ", building_instance.building_name)
	
	# NUEVO: Recalcular sinergias de edificios vecinos
	notify_neighbors_synergy_change(x, y)
	
	# Recalcular puntos por segundo
	GameManager.recalculate_total_points_per_second()
	
	return true

# NUEVA FUNCIÓN: Notificar a los vecinos que recalculen sus sinergias
func notify_neighbors_synergy_change(x: int, y: int):
	var adjacent_positions = [
		Vector2i(x + 1, y),
		Vector2i(x - 1, y),
		Vector2i(x, y + 1),
		Vector2i(x, y - 1)
	]
	
	for pos in adjacent_positions:
		var key = str(pos.x) + "," + str(pos.y)
		if grid_cells.has(key):
			var terrain = grid_cells[key]
			if terrain.has_building and terrain.building_node:
				if terrain.building_node.has_method("on_neighbor_changed"):
					terrain.building_node.on_neighbor_changed()

# Función para convertir coordenadas del mundo a coordenadas de cuadrícula
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(round(world_pos.x / cell_size)), 
		int(round(world_pos.y / cell_size))
	)

# Función para convertir coordenadas de cuadrícula a coordenadas del mundo
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * cell_size, grid_pos.y * cell_size)

# NUEVA FUNCIÓN: Obtener todos los edificios en la cuadrícula
func get_all_buildings() -> Array:
	var buildings = []
	for cell_key in grid_cells:
		var terrain = grid_cells[cell_key]
		if terrain.has_building and terrain.building_node:
			buildings.append(terrain.building_node)
	return buildings

# NUEVA FUNCIÓN: Obtener información de estadísticas
func get_grid_stats() -> Dictionary:
	var stats = {
		"total_cells": grid_cells.size(),
		"total_buildings": 0,
		"building_types": {}
	}
	
	for cell_key in grid_cells:
		var terrain = grid_cells[cell_key]
		if terrain.has_building and terrain.building_node:
			stats.total_buildings += 1
			var building_name = terrain.building_node.building_name
			if stats.building_types.has(building_name):
				stats.building_types[building_name] += 1
			else:
				stats.building_types[building_name] = 1
	
	return stats
