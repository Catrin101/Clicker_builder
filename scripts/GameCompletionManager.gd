# GameCompletionManager.gd - Sistema independiente para gestionar el completado del juego
extends Node

# Señales
signal welcome_shown()
signal welcome_closed()
signal game_completed()
signal progress_updated(buildings_progress: float, achievements_progress: float)

# Lista de todos los tipos de edificios requeridos para completar el juego
var required_building_types: Array[String] = [
	"House",
	"Tavern",
	"Inn",
	"Castle",
	"Chapel",
	"Clock",
	"Villa",
	"Thayched",
	"TreeHouse",
	"BaseMilitar"
]

# Estado del juego
var has_shown_welcome: bool = false
var has_completed_game: bool = false
var is_first_session: bool = true

# Progreso actual
var buildings_completed: int = 0
var total_buildings_required: int = 0
var achievements_completed: int = 0
var total_achievements_required: int = 0

# Flag de tracking
var is_tracking: bool = false

func _ready():
	print("GameCompletionManager inicializado")
	total_buildings_required = required_building_types.size()
	
	# TODO: Cuando se implemente el sistema de logros, inicializar total_achievements_required
	total_achievements_required = 0  # Por ahora 0, se actualizará con el sistema de logros
	
	is_tracking = true
	
	# Conectar con StatsManager para escuchar cuando se coloquen edificios
	StatsManager.building_count_changed.connect(_on_building_placed)

func _on_building_placed(building_type: String, count: int):
	if not is_tracking:
		return
	
	# Solo nos importa si es el primer edificio de este tipo
	if count == 1:
		check_game_progress()

# Verificar el progreso del juego
func check_game_progress():
	var old_buildings_completed = buildings_completed
	buildings_completed = 0
	
	# Contar cuántos tipos de edificios requeridos se han construido
	for building_type in required_building_types:
		if StatsManager.get_building_count(building_type) > 0:
			buildings_completed += 1
	
	# Calcular porcentajes de progreso
	var buildings_progress = 0.0
	if total_buildings_required > 0:
		buildings_progress = (float(buildings_completed) / float(total_buildings_required)) * 100.0
	
	var achievements_progress = 0.0
	# TODO: Cuando se implemente el sistema de logros, calcular achievements_progress
	# if total_achievements_required > 0:
	#     achievements_progress = (float(achievements_completed) / float(total_achievements_required)) * 100.0
	
	# Emitir señal de progreso actualizado
	progress_updated.emit(buildings_progress, achievements_progress)
	
	# Si hubo cambio en edificios, mostrar mensaje de progreso
	if buildings_completed > old_buildings_completed:
		print("¡Progreso! Tipos de edificios completados: ", buildings_completed, "/", total_buildings_required)
	
	# Verificar si se completó el juego
	check_completion()

# Verificar si se completaron todos los objetivos
func check_completion():
	# Verificar edificios
	var all_buildings_built = (buildings_completed >= total_buildings_required)
	
	# Verificar logros (por ahora siempre true porque no hay sistema de logros)
	var all_achievements_unlocked = true
	# TODO: Cuando se implemente el sistema de logros:
	# all_achievements_unlocked = (achievements_completed >= total_achievements_required)
	
	# Si ya estaba completado, no hacer nada
	if has_completed_game:
		return
	
	# Si se completaron todos los objetivos
	if all_buildings_built and all_achievements_unlocked:
		has_completed_game = true
		game_completed.emit()
		print("🎉 ¡JUEGO COMPLETADO! 🎉")

# Obtener progreso de edificios
func get_buildings_progress() -> Dictionary:
	return {
		"completed": buildings_completed,
		"total": total_buildings_required,
		"percentage": (float(buildings_completed) / float(total_buildings_required)) * 100.0 if total_buildings_required > 0 else 0.0
	}

# Obtener progreso de logros
func get_achievements_progress() -> Dictionary:
	return {
		"completed": achievements_completed,
		"total": total_achievements_required,
		"percentage": (float(achievements_completed) / float(total_achievements_required)) * 100.0 if total_achievements_required > 0 else 0.0
	}

# Obtener lista de edificios faltantes
func get_missing_buildings() -> Array[String]:
	var missing: Array[String] = []
	
	for building_type in required_building_types:
		if StatsManager.get_building_count(building_type) == 0:
			missing.append(building_type)
	
	return missing

# Obtener lista de edificios completados
func get_completed_buildings() -> Array[String]:
	var completed: Array[String] = []
	
	for building_type in required_building_types:
		if StatsManager.get_building_count(building_type) > 0:
			completed.append(building_type)
	
	return completed

# Verificar si es la primera vez que se juega
func is_first_time() -> bool:
	return is_first_session and not has_shown_welcome

# Marcar que se mostró el mensaje de bienvenida
func mark_welcome_shown():
	has_shown_welcome = true
	welcome_shown.emit()
	print("Bienvenida mostrada")

# Marcar que se cerró el mensaje de bienvenida
func mark_welcome_closed():
	welcome_closed.emit()
	print("Bienvenida cerrada")

# Verificar si el juego está completado
func is_game_completed() -> bool:
	return has_completed_game

# Obtener información completa del estado del juego (para guardado)
func get_completion_state() -> Dictionary:
	return {
		"has_shown_welcome": has_shown_welcome,
		"has_completed_game": has_completed_game,
		"is_first_session": is_first_session,
		"buildings_completed": buildings_completed,
		"achievements_completed": achievements_completed
	}

# Cargar estado del juego (para sistema de guardado)
func load_completion_state(data: Dictionary):
	if data.has("has_shown_welcome"):
		has_shown_welcome = data.has_shown_welcome
	
	if data.has("has_completed_game"):
		has_completed_game = data.has_completed_game
	
	if data.has("is_first_session"):
		is_first_session = data.is_first_session
	
	if data.has("buildings_completed"):
		buildings_completed = data.buildings_completed
	
	if data.has("achievements_completed"):
		achievements_completed = data.achievements_completed
	
	print("GameCompletionManager: Estado cargado")
	
	# Recalcular progreso después de cargar
	call_deferred("check_game_progress")

# Resetear el estado (para nueva partida)
func reset_completion_state():
	has_shown_welcome = false
	has_completed_game = false
	is_first_session = true
	buildings_completed = 0
	achievements_completed = 0
	
	print("GameCompletionManager: Estado reseteado")

# TODO: Función para registrar logros desbloqueados (implementar cuando exista el sistema)
func register_achievement_unlocked(achievement_id: String):
	# achievements_completed += 1
	# check_game_progress()
	pass

# Pausar/reanudar tracking
func set_tracking(enabled: bool):
	is_tracking = enabled
