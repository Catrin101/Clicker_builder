# StatsManager.gd - Sistema independiente de estadísticas del juego
extends Node

# Señales para notificar cambios en las estadísticas
signal stats_updated()
signal building_count_changed(building_type: String, new_count: int)
signal total_buildings_changed(total: int)

# Diccionario principal de estadísticas de edificios
# Estructura: { "building_type": count }
var building_counts: Dictionary = {}

# Estadísticas generales del juego
var total_buildings_placed: int = 0
var total_points_earned: int = 0
var total_points_spent: int = 0
var highest_pps_reached: float = 0.0
var game_start_time: int = 0
var total_play_time: int = 0

# Flags de control
var is_tracking: bool = false

func _ready():
	print("StatsManager inicializado")
	game_start_time = Time.get_ticks_msec()
	is_tracking = true

# Función principal para registrar un edificio colocado
func register_building_placed(building_type: String) -> void:
	if not is_tracking:
		return
	
	# Incrementar contador del tipo específico
	if building_counts.has(building_type):
		building_counts[building_type] += 1
	else:
		building_counts[building_type] = 1
	
	# Incrementar total
	total_buildings_placed += 1
	
	# Emitir señales
	building_count_changed.emit(building_type, building_counts[building_type])
	total_buildings_changed.emit(total_buildings_placed)
	stats_updated.emit()
	
	print("StatsManager: Edificio registrado - ", building_type, " (Total: ", building_counts[building_type], ")")

# Función para registrar puntos ganados
func register_points_earned(amount: int) -> void:
	if not is_tracking:
		return
	
	total_points_earned += amount
	stats_updated.emit()

# Función para registrar puntos gastados
func register_points_spent(amount: int) -> void:
	if not is_tracking:
		return
	
	total_points_spent += amount
	stats_updated.emit()

# Función para actualizar el PPS más alto alcanzado
func update_highest_pps(current_pps: float) -> void:
	if current_pps > highest_pps_reached:
		highest_pps_reached = current_pps
		stats_updated.emit()

# Obtener el conteo de un tipo específico de edificio
func get_building_count(building_type: String) -> int:
	return building_counts.get(building_type, 0)

# Obtener todos los tipos de edificios con sus conteos
func get_all_building_counts() -> Dictionary:
	return building_counts.duplicate()

# Obtener el total de edificios
func get_total_buildings() -> int:
	return total_buildings_placed

# Obtener tiempo de juego en segundos
func get_play_time_seconds() -> int:
	if not is_tracking:
		return total_play_time
	
	var current_time = Time.get_ticks_msec()
	var elapsed = (current_time - game_start_time) / 1000
	return int(elapsed)

# Obtener tiempo de juego formateado (HH:MM:SS)
func get_formatted_play_time() -> String:
	var seconds = get_play_time_seconds()
	var hours = seconds / 3600
	var minutes = (seconds % 3600) / 60
	var secs = seconds % 60
	
	return "%02d:%02d:%02d" % [hours, minutes, secs]

# Obtener todas las estadísticas generales
func get_general_stats() -> Dictionary:
	return {
		"total_buildings": total_buildings_placed,
		"total_points_earned": total_points_earned,
		"total_points_spent": total_points_spent,
		"highest_pps": highest_pps_reached,
		"play_time_seconds": get_play_time_seconds(),
		"play_time_formatted": get_formatted_play_time()
	}

# Obtener estadísticas completas (para guardado)
func get_full_stats() -> Dictionary:
	return {
		"building_counts": building_counts.duplicate(),
		"general_stats": get_general_stats()
	}

# Cargar estadísticas (para sistema de guardado futuro)
func load_stats(data: Dictionary) -> void:
	if data.has("building_counts"):
		building_counts = data.building_counts.duplicate()
	
	if data.has("general_stats"):
		var gen_stats = data.general_stats
		total_buildings_placed = gen_stats.get("total_buildings", 0)
		total_points_earned = gen_stats.get("total_points_earned", 0)
		total_points_spent = gen_stats.get("total_points_spent", 0)
		highest_pps_reached = gen_stats.get("highest_pps", 0.0)
	
	stats_updated.emit()
	print("StatsManager: Estadísticas cargadas")

# Resetear todas las estadísticas
func reset_stats() -> void:
	building_counts.clear()
	total_buildings_placed = 0
	total_points_earned = 0
	total_points_spent = 0
	highest_pps_reached = 0.0
	game_start_time = Time.get_ticks_msec()
	
	stats_updated.emit()
	print("StatsManager: Estadísticas reseteadas")

# Obtener lista de tipos de edificios ordenada alfabéticamente
func get_sorted_building_types() -> Array:
	var types = building_counts.keys()
	types.sort()
	return types

# Verificar si se ha construido al menos uno de cada tipo (para logros)
func has_built_all_types(required_types: Array) -> bool:
	for type in required_types:
		if get_building_count(type) == 0:
			return false
	return true

# Obtener el tipo de edificio más construido
func get_most_built_type() -> Dictionary:
	if building_counts.is_empty():
		return {"type": "", "count": 0}
	
	var max_type = ""
	var max_count = 0
	
	for type in building_counts:
		if building_counts[type] > max_count:
			max_count = building_counts[type]
			max_type = type
	
	return {"type": max_type, "count": max_count}

# Pausar/reanudar tracking
func set_tracking(enabled: bool) -> void:
	is_tracking = enabled
