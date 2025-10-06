# SaveSystem.gd - Sistema independiente de guardado y carga
extends Node

# Señales para notificar eventos de guardado/carga
signal save_started()
signal save_completed(success: bool, slot_name: String)
signal load_started()
signal load_completed(success: bool, slot_name: String)
signal save_deleted(slot_name: String)

# Configuración
const SAVE_VERSION = "1.0"
const SAVE_FOLDER = "user://saves/"
const SAVE_EXTENSION = ".save"
const MAX_SAVE_SLOTS = 3  # Número máximo de slots

# Cache de información de guardados
var save_slots_info: Dictionary = {}

func _ready():
	print("SaveSystem inicializado")
	# Crear carpeta de guardados si no existe
	create_save_folder()
	# Escanear slots existentes
	scan_save_slots()

# ============================================================================
# FUNCIONES PÚBLICAS PRINCIPALES
# ============================================================================

# Guardar el juego en un slot específico
func save_game(slot_name: String = "slot_1") -> bool:
	print("\n=== INICIANDO GUARDADO EN: ", slot_name, " ===")
	save_started.emit()
	
	var save_data = collect_game_data()
	if save_data.is_empty():
		printerr("Error: No se pudo recolectar datos del juego")
		save_completed.emit(false, slot_name)
		return false
	
	var success = write_save_file(slot_name, save_data)
	
	if success:
		print("✅ Guardado completado exitosamente")
		# Actualizar cache
		scan_save_slots()
	else:
		printerr("❌ Error al guardar")
	
	save_completed.emit(success, slot_name)
	print("=== FIN GUARDADO ===\n")
	return success

# Cargar el juego desde un slot específico
func load_game(slot_name: String = "slot_1") -> bool:
	print("\n=== INICIANDO CARGA DESDE: ", slot_name, " ===")
	load_started.emit()
	
	if not has_save_file(slot_name):
		printerr("Error: No existe guardado en ", slot_name)
		load_completed.emit(false, slot_name)
		return false
	
	var save_data = read_save_file(slot_name)
	if save_data.is_empty():
		printerr("Error: No se pudo leer el archivo de guardado")
		load_completed.emit(false, slot_name)
		return false
	
	# Validar versión
	if not validate_save_version(save_data):
		printerr("Error: Versión de guardado incompatible")
		load_completed.emit(false, slot_name)
		return false
	
	var success = apply_game_data(save_data)
	
	if success:
		print("✅ Carga completada exitosamente")
	else:
		printerr("❌ Error al aplicar datos")
	
	load_completed.emit(success, slot_name)
	print("=== FIN CARGA ===\n")
	return success

# Verificar si existe un guardado en un slot
func has_save_file(slot_name: String) -> bool:
	var file_path = get_save_path(slot_name)
	return FileAccess.file_exists(file_path)

# Eliminar un guardado
func delete_save(slot_name: String) -> bool:
	if not has_save_file(slot_name):
		print("No hay guardado para eliminar en ", slot_name)
		return false
	
	var file_path = get_save_path(slot_name)
	var dir = DirAccess.open("user://")
	var error = dir.remove(file_path)
	
	if error == OK:
		print("Guardado eliminado: ", slot_name)
		scan_save_slots()
		save_deleted.emit(slot_name)
		return true
	else:
		printerr("Error al eliminar guardado: ", error)
		return false

# Obtener información de un slot de guardado
func get_save_info(slot_name: String) -> Dictionary:
	if save_slots_info.has(slot_name):
		return save_slots_info[slot_name]
	return {}

# Obtener lista de todos los slots con información
func get_all_slots_info() -> Array:
	var slots = []
	for i in range(1, MAX_SAVE_SLOTS + 1):
		var slot_name = "slot_" + str(i)
		var info = get_save_info(slot_name)
		if info.is_empty():
			# Slot vacío
			info = {
				"slot_name": slot_name,
				"exists": false,
				"slot_number": i
			}
		else:
			info["slot_number"] = i
		slots.append(info)
	return slots

# ============================================================================
# FUNCIONES DE RECOLECCIÓN DE DATOS
# ============================================================================

func collect_game_data() -> Dictionary:
	var data = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"date_string": Time.get_datetime_string_from_system(),
	}
	
	# Recolectar datos del GameManager
	if GameManager:
		data["game_manager"] = {
			"player_points": GameManager.player_points,
			"total_points_per_second": GameManager.total_points_per_second
		}
		print("  ✓ Datos de GameManager recolectados")
	
	# Recolectar datos del GridManager
	var grid_data = collect_grid_data()
	if not grid_data.is_empty():
		data["grid_manager"] = grid_data
		print("  ✓ Datos de GridManager recolectados")
	
	# Recolectar datos del StatsManager
	if StatsManager:
		data["stats_manager"] = StatsManager.get_full_stats()
		print("  ✓ Datos de StatsManager recolectados")
	
	# Recolectar datos del GameCompletionManager
	if GameCompletionManager:
		data["completion_manager"] = GameCompletionManager.get_completion_state()
		print("  ✓ Datos de GameCompletionManager recolectados")
	
	return data

func collect_grid_data() -> Dictionary:
	var grid_manager = get_tree().get_first_node_in_group("grid_manager")
	if not grid_manager:
		printerr("Error: No se encontró GridManager")
		return {}
	
	var grid_data = {
		"land_cost": grid_manager.land_cost,
		"cells": [],
		"buildings": []
	}
	
	# Guardar todas las celdas de terreno
	for cell_key in grid_manager.grid_cells:
		var coords = cell_key.split(",")
		var cell_data = {
			"x": int(coords[0]),
			"y": int(coords[1])
		}
		grid_data.cells.append(cell_data)
	
	# Guardar todos los edificios
	var buildings = grid_manager.get_all_buildings()
	for building in buildings:
		if building and is_instance_valid(building):
			var building_data = {
				"building_name": building.building_name,
				"scene_path": building.scene_path,  # ← CORREGIDO
				"grid_x": building.grid_x,
				"grid_y": building.grid_y,
				"base_pps": building.points_per_second
			}
			grid_data.buildings.append(building_data)
	
	print("    - Celdas guardadas: ", grid_data.cells.size())
	print("    - Edificios guardados: ", grid_data.buildings.size())
	
	return grid_data

# ============================================================================
# FUNCIONES DE APLICACIÓN DE DATOS
# ============================================================================

func apply_game_data(data: Dictionary) -> bool:
	print("Aplicando datos cargados...")
	
	# Aplicar datos del GameManager (solo puntos, NO pps todavía)
	if data.has("game_manager"):
		apply_game_manager_data(data.game_manager, false)  # false = no cargar pps aún
	
	# Aplicar datos del StatsManager
	if data.has("stats_manager") and StatsManager:
		StatsManager.load_stats(data.stats_manager)
		print("  ✓ StatsManager actualizado")
	
	# Aplicar datos del GameCompletionManager
	if data.has("completion_manager") and GameCompletionManager:
		GameCompletionManager.load_completion_state(data.completion_manager)
		print("  ✓ GameCompletionManager actualizado")
	
	# Aplicar datos del GridManager (debe ser lo último)
	if data.has("grid_manager"):
		# Esto se hace con call_deferred para asegurar que el árbol de nodos esté listo
		call_deferred("apply_grid_data", data.grid_manager)
	
	return true

func apply_game_manager_data(data: Dictionary, load_pps: bool = true):
	if not GameManager:
		return
	
	if data.has("player_points"):
		GameManager.player_points = data.player_points
		GameManager.points_changed.emit(GameManager.player_points)
	
	# Solo cargar PPS si se especifica (lo recalcularemos después de cargar edificios)
	if load_pps and data.has("total_points_per_second"):
		GameManager.total_points_per_second = data.total_points_per_second
		GameManager.points_per_second_changed.emit(GameManager.total_points_per_second)
	
	print("  ✓ GameManager actualizado (puntos cargados)")

func apply_grid_data(data: Dictionary):
	var grid_manager = get_tree().get_first_node_in_group("grid_manager")
	if not grid_manager:
		printerr("Error: No se encontró GridManager para aplicar datos")
		return
	
	print("Reconstruyendo cuadrícula...")
	
	# Limpiar cuadrícula actual
	await clear_current_grid(grid_manager)
	
	# Restaurar costo de terreno
	if data.has("land_cost"):
		grid_manager.land_cost = data.land_cost
	
	# PASO 1: Recrear todas las celdas de terreno
	if data.has("cells"):
		for cell_data in data.cells:
			recreate_terrain(grid_manager, cell_data.x, cell_data.y)
	
	# Esperar a que todos los terrenos estén listos
	await grid_manager.get_tree().process_frame
	
	# PASO 2: Recrear todos los edificios
	if data.has("buildings"):
		for building_data in data.buildings:
			recreate_building(grid_manager, building_data)
	
	# Esperar a que todos los edificios estén colocados
	await grid_manager.get_tree().process_frame
	
	# PASO 3: Recalcular sinergias
	recalculate_all_synergies(grid_manager)
	
	# PASO 4: Recalcular PPS (esto actualizará el GameManager correctamente)
	GameManager.recalculate_total_points_per_second()
	
	# PASO 5: Forzar actualización visual de TODOS los terrenos
	await grid_manager.get_tree().process_frame
	for cell_key in grid_manager.grid_cells:
		var terrain = grid_manager.grid_cells[cell_key]
		if terrain and is_instance_valid(terrain):
			# Forzar actualización inmediata del sprite
			if terrain.has_building:
				if terrain.has_node("Sprite2D"):
					terrain.get_node("Sprite2D").modulate = Color.WHITE
			else:
				if terrain.has_node("Sprite2D"):
					terrain.get_node("Sprite2D").modulate = Color.LIGHT_BLUE
	
	print("  ✓ Cuadrícula reconstruida")
	print("  ✓ PPS total: ", GameManager.total_points_per_second)

func clear_current_grid(grid_manager: Node2D):
	print("Limpiando cuadrícula actual...")
	
	# Eliminar TODOS los hijos del GridManager
	var children_to_remove = []
	for child in grid_manager.get_children():
		children_to_remove.append(child)
	
	for child in children_to_remove:
		if is_instance_valid(child):
			child.queue_free()
	
	# Esperar a que se eliminen físicamente
	await grid_manager.get_tree().process_frame
	
	# Limpiar el diccionario
	grid_manager.grid_cells.clear()
	
	print("  Cuadrícula limpiada completamente")	

func recreate_terrain(grid_manager: Node2D, x: int, y: int):
	var terrain_scene = preload("res://escenas/terrain.tscn")
	var terrain_instance = terrain_scene.instantiate()
	
	terrain_instance.position = Vector2(x * grid_manager.cell_size, y * grid_manager.cell_size)
	terrain_instance.grid_x = x
	terrain_instance.grid_y = y
	
	grid_manager.add_child(terrain_instance)
	grid_manager.grid_cells[str(x) + "," + str(y)] = terrain_instance

func recreate_building(grid_manager: Node2D, building_data: Dictionary):
	var x = building_data.grid_x
	var y = building_data.grid_y
	var scene_path = building_data.scene_path
	
	# Cargar y colocar el edificio
	var building_scene = load(scene_path)
	if not building_scene:
		printerr("Error: No se pudo cargar escena: ", scene_path)
		return
	
	var building_instance = building_scene.instantiate()
	building_instance.position = Vector2(x * grid_manager.cell_size, y * grid_manager.cell_size)
	
	if building_instance.has_method("on_placed_in_grid"):
		# Le pasamos 'true' para indicar que estamos en modo carga
		building_instance.on_placed_in_grid(x, y, true) 
	else:
		building_instance.grid_x = x
		building_instance.grid_y = y
	
	grid_manager.add_child(building_instance)
	
	# Marcar terreno como ocupado
	var key = str(x) + "," + str(y)
	if grid_manager.grid_cells.has(key):
		var terrain = grid_manager.grid_cells[key]
		terrain.has_building = true
		terrain.building_node = building_instance
		
		# Actualizar estado visual del terreno (con call_deferred para asegurar que sprite existe)
		terrain.call_deferred("update_visual_state")

func recalculate_all_synergies(grid_manager: Node2D):
	var buildings = grid_manager.get_all_buildings()
	for building in buildings:
		if building and is_instance_valid(building):
			if building.has_method("calculate_synergies"):
				building.calculate_synergies()

# ============================================================================
# FUNCIONES DE ARCHIVO
# ============================================================================

func write_save_file(slot_name: String, data: Dictionary) -> bool:
	var file_path = get_save_path(slot_name)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		printerr("Error al crear archivo: ", FileAccess.get_open_error())
		return false
	
	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	
	print("Archivo guardado en: ", file_path)
	return true

func read_save_file(slot_name: String) -> Dictionary:
	var file_path = get_save_path(slot_name)
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		printerr("Error al abrir archivo: ", FileAccess.get_open_error())
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		printerr("Error al parsear JSON: ", json.get_error_message())
		return {}
	
	return json.data

func validate_save_version(data: Dictionary) -> bool:
	if not data.has("version"):
		printerr("Guardado sin versión")
		return false
	
	# Por ahora, solo verificamos que exista
	# En el futuro podrías hacer conversiones de versiones antiguas
	print("Versión de guardado: ", data.version)
	return true

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================

func create_save_folder():
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
		print("Carpeta de guardados creada")

func get_save_path(slot_name: String) -> String:
	return SAVE_FOLDER + slot_name + SAVE_EXTENSION

func scan_save_slots():
	save_slots_info.clear()
	
	for i in range(1, MAX_SAVE_SLOTS + 1):
		var slot_name = "slot_" + str(i)
		if has_save_file(slot_name):
			var save_data = read_save_file(slot_name)
			if not save_data.is_empty():
				var info = {
					"slot_name": slot_name,
					"exists": true,
					"timestamp": save_data.get("timestamp", 0),
					"date_string": save_data.get("date_string", "Desconocido"),
					"version": save_data.get("version", "Unknown")
				}
				
				# Añadir estadísticas resumidas
				if save_data.has("game_manager"):
					info["points"] = save_data.game_manager.get("player_points", 0)
					info["pps"] = save_data.game_manager.get("total_points_per_second", 0.0)
				
				if save_data.has("stats_manager"):
					var stats = save_data.stats_manager.get("general_stats", {})
					info["total_buildings"] = stats.get("total_buildings", 0)
					info["play_time"] = stats.get("play_time_formatted", "00:00:00")
				
				save_slots_info[slot_name] = info
	
	print("Slots escaneados: ", save_slots_info.size(), " guardados encontrados")

func get_formatted_date(timestamp: int) -> String:
	var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
	return "%02d/%02d/%04d %02d:%02d" % [
		datetime.day,
		datetime.month,
		datetime.year,
		datetime.hour,
		datetime.minute
	]

# Función de utilidad para debug
func print_save_data(data: Dictionary):
	print("\n=== CONTENIDO DEL GUARDADO ===")
	print(JSON.stringify(data, "\t"))
	print("=== FIN CONTENIDO ===\n")
