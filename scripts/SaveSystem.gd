# SaveSystem.gd - Sistema independiente de guardado y carga - COMPLETO
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
const SAVE_EXTENSION = ".tres"
const MAX_SAVE_SLOTS = 3

# Cache de información de guardados
var save_slots_info: Dictionary = {}

# NUEVO: Variable para almacenar datos temporalmente durante cambio de escena
var pending_load_data: GameSave = null

func _ready():
	print("SaveSystem inicializado")
	create_save_folder()
	scan_save_slots()

# ============================================================================
# FUNCIONES PÚBLICAS PRINCIPALES
# ============================================================================

func save_game(slot_name: String = "slot_1") -> bool:
	print("\n=== INICIANDO GUARDADO EN: ", slot_name, " ===")
	save_started.emit()

	# 1. Asegurarse de que la carpeta existe
	ensure_save_folder_exists()

	# 2. Crear el recurso principal
	var save_data = GameSave.new()
	save_data.version = SAVE_VERSION
	save_data.timestamp = Time.get_unix_time_from_system()

	# 3. Pedir a cada manager que llene su parte de los datos
	if GameManager:
		save_data.player_points = GameManager.player_points
	
	var grid_manager = get_tree().get_first_node_in_group("grid_manager")
	if grid_manager:
		save_data.grid_data = grid_manager.get_data_as_resource()
	else:
		printerr("⚠️ Advertencia: No se encontró GridManager para guardar")

	if StatsManager:
		save_data.stats_data = StatsManager.get_full_stats()
	
	if GameCompletionManager:
		save_data.completion_data = GameCompletionManager.get_completion_state()

	# 4. Obtener la ruta completa del archivo
	var file_path = get_save_path(slot_name)
	
	# 5. Guardar el recurso
	var error = ResourceSaver.save(save_data, file_path)

	if error == OK:
		print("✅ Guardado completado exitosamente en: ", file_path)
		scan_save_slots()
		save_completed.emit(true, slot_name)
		return true
	else:
		printerr("❌ Error al guardar el recurso. Código: ", error)
		printerr("   Ruta intentada: ", file_path)
		save_completed.emit(false, slot_name)
		return false


# VERSIÓN MEJORADA: load_game con soporte para cambio de escena
func load_game(slot_name: String = "slot_1") -> bool:
	print("\n=== INICIANDO CARGA DESDE: ", slot_name, " ===")
	load_started.emit()

	var file_path = get_save_path(slot_name)
	if not has_save_file(slot_name):
		printerr("❌ Error: No existe guardado en ", slot_name)
		load_completed.emit(false, slot_name)
		return false
	
	# 1. Cargar el recurso directamente
	var save_data: GameSave = ResourceLoader.load(file_path, "GameSave")
	if not is_instance_valid(save_data):
		printerr("❌ Error: No se pudo leer el archivo de guardado como recurso")
		load_completed.emit(false, slot_name)
		return false

	print("✅ Recurso cargado exitosamente:")
	print("   - Puntos: ", save_data.player_points)
	print("   - Versión: ", save_data.version)
	print("   - GridData válido: ", is_instance_valid(save_data.grid_data))

	# 2. Verificar si estamos en la escena del juego o en el menú
	var tree = get_tree()
	if not tree:
		printerr("❌ Error crítico: SceneTree no disponible")
		load_completed.emit(false, slot_name)
		return false
	
	var current_scene = tree.current_scene
	if not current_scene:
		printerr("❌ Error: No hay escena actual")
		load_completed.emit(false, slot_name)
		return false
	
	var current_scene_path = current_scene.scene_file_path
	print("📍 Escena actual: ", current_scene_path)
	
	if current_scene_path == "res://escenas/main.tscn":
		# Ya estamos en el juego, aplicar datos directamente
		print("📍 Ya estamos en main.tscn, aplicando datos inmediatamente...")
		await apply_save_data(save_data)
		print("✅ Carga completada exitosamente")
		load_completed.emit(true, slot_name)
		return true
	else:
		# Estamos en el menú, necesitamos cambiar de escena
		print("📍 Estamos en menú (", current_scene_path, "), preparando cambio...")
		
		# CRÍTICO: Guardar referencia ANTES de cambiar de escena
		pending_load_data = save_data
		
		# Verificar inmediatamente que se guardó
		if not is_instance_valid(pending_load_data):
			printerr("❌ Error CRÍTICO: No se pudo guardar pending_load_data")
			load_completed.emit(false, slot_name)
			return false
		
		print("✅ pending_load_data almacenado temporalmente")
		print("   - Puntos en pending: ", pending_load_data.player_points)
		
		# Cambiar de escena (NO usar await aquí)
		var error = get_tree().change_scene_to_file("res://escenas/main.tscn")
		if error != OK:
			printerr("❌ Error al cambiar de escena: ", error)
			pending_load_data = null
			load_completed.emit(false, slot_name)
			return false
		
		print("✅ Cambio de escena iniciado")
		print("   ⏳ Los datos se aplicarán cuando Main._ready() se ejecute...")
		
		# NO emitir load_completed aquí - se emitirá desde Main._ready()
		return true

# NUEVA FUNCIÓN: Aplicar datos de guardado
func apply_save_data(save_data: GameSave):
	# Validación crítica
	if not is_instance_valid(save_data):
		printerr("❌ Error crítico: save_data es null o inválido")
		return
	
	print("\n=== APLICANDO DATOS DE GUARDADO ===")
	
	# Aplicar datos de GameManager
	if GameManager:
		GameManager.player_points = save_data.player_points
		GameManager.points_changed.emit(GameManager.player_points)
		print("✅ GameManager actualizado: ", save_data.player_points, " puntos")
	else:
		printerr("⚠️ GameManager no encontrado")
	
	# Aplicar datos de StatsManager
	if StatsManager:
		StatsManager.load_stats(save_data.stats_data)
		print("✅ StatsManager actualizado")
	else:
		printerr("⚠️ StatsManager no encontrado")
	
	# Aplicar datos de GameCompletionManager
	if GameCompletionManager:
		GameCompletionManager.load_completion_state(save_data.completion_data)
		print("✅ GameCompletionManager actualizado")
	else:
		printerr("⚠️ GameCompletionManager no encontrado")
	
	# Aplicar datos de GridManager
	var grid_manager = get_tree().get_first_node_in_group("grid_manager")
	if grid_manager:
		if is_instance_valid(save_data.grid_data):
			print("✅ Cargando GridManager...")
			await grid_manager.load_data_from_resource(save_data.grid_data)
			print("✅ GridManager cargado completamente")
		else:
			printerr("⚠️ grid_data no es válido o está vacío")
	else:
		printerr("❌ Error crítico: No se encontró GridManager en grupo 'grid_manager'")
	
	print("=== FIN APLICAR DATOS ===\n")

func has_save_file(slot_name: String) -> bool:
	var file_path = get_save_path(slot_name)
	return FileAccess.file_exists(file_path)

func delete_save(slot_name: String) -> bool:
	if not has_save_file(slot_name):
		print("No hay guardado para eliminar en ", slot_name)
		return false
	
	var file_path = get_save_path(slot_name)
	var error = DirAccess.remove_absolute(file_path)
	
	if error == OK:
		print("Guardado eliminado: ", slot_name)
		scan_save_slots()
		save_deleted.emit(slot_name)
		return true
	else:
		printerr("Error al eliminar guardado: ", error)
		return false

func get_save_info(slot_name: String) -> Dictionary:
	if save_slots_info.has(slot_name):
		return save_slots_info[slot_name]
	return {}

func get_all_slots_info() -> Array:
	var slots = []
	for i in range(1, MAX_SAVE_SLOTS + 1):
		var slot_name = "slot_" + str(i)
		var info = get_save_info(slot_name)
		if info.is_empty():
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
# FUNCIONES AUXILIARES
# ============================================================================

func create_save_folder():
	ensure_save_folder_exists()

func ensure_save_folder_exists():
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("saves"):
			var error = dir.make_dir("saves")
			if error == OK:
				print("✅ Carpeta de guardados creada")
			else:
				printerr("❌ Error al crear carpeta de guardados: ", error)
	else:
		printerr("❌ No se pudo acceder al directorio user://")

func get_save_path(slot_name: String) -> String:
	return SAVE_FOLDER + slot_name + SAVE_EXTENSION

func scan_save_slots():
	save_slots_info.clear()
	
	for i in range(1, MAX_SAVE_SLOTS + 1):
		var slot_name = "slot_" + str(i)
		if has_save_file(slot_name):
			var save_data: GameSave = ResourceLoader.load(get_save_path(slot_name), "GameSave")
			
			if is_instance_valid(save_data):
				var info = {
					"slot_name": slot_name,
					"exists": true,
					"timestamp": save_data.timestamp,
					"date_string": get_formatted_date(save_data.timestamp),
					"version": save_data.version,
					"points": save_data.player_points
				}
				
				if not save_data.stats_data.is_empty():
					var stats = save_data.stats_data.get("general_stats", {})
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

func print_save_data(data: Dictionary):
	print("\n=== CONTENIDO DEL GUARDADO ===")
	print(JSON.stringify(data, "\t"))
	print("=== FIN CONTENIDO ===\n")
