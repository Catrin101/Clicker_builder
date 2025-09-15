# GridManager.gd - Gestor de la cuadrícula - CORREGIDO
extends Node2D

# Diccionario para almacenar las casillas (clave: "x,y", valor: nodo)
var grid_cells: Dictionary = {}

# Variables de configuración
var cell_size: int = 128
var land_cost: int = 10
var land_cost_multiplier: float = 1.2

# Señales
signal terrain_placed(x: int, y: int)
signal building_placed(x: int, y: int)

func _ready():
	add_to_group("grid_manager")
	add_initial_terrain()

func add_initial_terrain():
	var terrain_scene = preload("res://escenas/terrain.tscn")
	var terrain_instance = terrain_scene.instantiate()
	
	var x = 0
	var y = 0
	
	terrain_instance.position = Vector2(x * cell_size, y * cell_size)
	terrain_instance.grid_x = x
	terrain_instance.grid_y = y
	
	add_child(terrain_instance)
	grid_cells[str(x) + "," + str(y)] = terrain_instance
	
	print("Terreno inicial colocado en (", x, ", ", y, ")")

func can_expand(x: int, y: int) -> bool:
	if grid_cells.has(str(x) + "," + str(y)):
		return false
	
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

func buy_and_place_terrain(x: int, y: int) -> bool:
	if not can_expand(x, y):
		print("No se puede expandir a (", x, ", ", y, ")")
		return false
	
	if not GameManager.can_afford(land_cost):
		print("No tienes suficientes puntos para comprar terreno. Costo: ", land_cost)
		return false
	
	if GameManager.subtract_points(land_cost):
		var terrain_scene = preload("res://escenas/terrain.tscn")
		var terrain_instance = terrain_scene.instantiate()
		
		terrain_instance.position = Vector2(x * cell_size, y * cell_size)
		terrain_instance.grid_x = x
		terrain_instance.grid_y = y
		
		add_child(terrain_instance)
		grid_cells[str(x) + "," + str(y)] = terrain_instance
		
		land_cost = int(land_cost * land_cost_multiplier)
		
		terrain_placed.emit(x, y)
		print("Nuevo terreno colocado en (", x, ", ", y, "). Próximo costo: ", land_cost)
		return true
	
	return false

# Función para obtener vecinos - CORREGIDA
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
			# Si el terreno en sí es una estructura (como un árbol), devolverlo
			elif terrain.has_method("get_structure_name"):
				neighbors[adj.dir] = terrain
	
	return neighbors

func has_terrain(x: int, y: int) -> bool:
	var key = str(x) + "," + str(y)
	return grid_cells.has(key)

# Función para colocar edificios - CORREGIDA
func place_building(x: int, y: int, building_scene_path: String) -> bool:
	print("\n=== Colocando edificio en (", x, ", ", y, ") ===")
	
	if not has_terrain(x, y):
		print("Error: No hay terreno en (", x, ", ", y, ")")
		return false
	
	var key = str(x) + "," + str(y)
	var current_cell = grid_cells[key]
	
	if current_cell.has_building:
		print("Error: Ya hay un edificio en (", x, ", ", y, ")")
		return false
	
	var building_scene = load(building_scene_path)
	if not building_scene:
		print("Error: No se pudo cargar la escena del edificio: ", building_scene_path)
		return false
	
	var building_instance = building_scene.instantiate()
	
	# Configurar posición
	building_instance.position = Vector2(x * cell_size, y * cell_size)
	
	# IMPORTANTE: Llamar a on_placed_in_grid ANTES de añadir como hijo
	if building_instance.has_method("on_placed_in_grid"):
		building_instance.on_placed_in_grid(x, y)
	else:
		building_instance.grid_x = x
		building_instance.grid_y = y
	
	# Añadir como hijo
	add_child(building_instance)
	
	# Marcar el terreno como ocupado
	current_cell.has_building = true
	current_cell.building_node = building_instance
	
	print("Edificio ", building_instance.building_name, " colocado exitosamente")
	
	# Notificar a vecinos DESPUÉS de que el edificio esté completamente configurado
	call_deferred("notify_neighbors_synergy_change", x, y)
	
	building_placed.emit(x, y)
	print("=== Fin colocación edificio ===\n")
	
	return true

# Función para notificar cambios de sinergia a vecinos
func notify_neighbors_synergy_change(x: int, y: int):
	print("Notificando cambios de sinergia a vecinos de (", x, ", ", y, ")")
	
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
					print("  Notificando a ", terrain.building_node.building_name, " en (", pos.x, ", ", pos.y, ")")
					terrain.building_node.on_neighbor_changed()

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(round(world_pos.x / cell_size)), 
		int(round(world_pos.y / cell_size))
	)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * cell_size, grid_pos.y * cell_size)

func get_all_buildings() -> Array:
	var buildings = []
	for cell_key in grid_cells:
		var terrain = grid_cells[cell_key]
		if terrain.has_building and terrain.building_node:
			buildings.append(terrain.building_node)
	return buildings

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
