# Building.gd - Clase base para todos los edificios - CORREGIDA
class_name Building
extends Node2D

# Variables exportadas (configurables desde el editor)
@export var building_name: String = ""
@export var cost: int = 100
@export var points_per_second: float = 1.0
@export var description: String = ""

# Diccionario de sinergias: edificio_vecino -> porcentaje_de_cambio
@export var synergies: Dictionary = {}

# Variables de posición en cuadrícula
var grid_x: int = 0
var grid_y: int = 0

# Variables de sinergia calculada
var synergy_multipliers: Dictionary = {}
var total_synergy_multiplier: float = 1.0

# Referencias a nodos
@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D
@onready var synergy_labels: Node2D = $SynergyLabels
@onready var right_synergy: Label = $SynergyLabels/RightSynergy
@onready var left_synergy: Label = $SynergyLabels/LeftSynergy
@onready var up_synergy: Label = $SynergyLabels/UpSynergy
@onready var down_synergy: Label = $SynergyLabels/DownSynergy

# Tween para animaciones
var tween: Tween

func _ready():
	# Conectar señales del área
	area.input_event.connect(_on_area_input_event)
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	
	# Configurar animación de balanceo inicial
	call_deferred("start_bobble_animation")
	
	print("Building _ready - Nombre: ", building_name, ", PPS base: ", points_per_second)

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_building_clicked()

func _on_mouse_entered():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2)
	
func _on_mouse_exited():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

func _on_building_clicked():
	print("Edificio clickeado: ", building_name, " en (", grid_x, ", ", grid_y, ")")
	print("  PPS base: ", points_per_second, ", PPS total: ", get_total_points_per_second())
	print("  Multiplicador de sinergia: ", total_synergy_multiplier)

# Función para iniciar la animación de balanceo
func start_bobble_animation():
	if not tween:
		tween = create_tween()
	
	tween.set_loops()
	tween.tween_property(sprite, "rotation", deg_to_rad(2), 2.0)
	tween.tween_property(sprite, "rotation", deg_to_rad(-2), 2.0)

# Función principal para calcular sinergias - CORREGIDA
func calculate_synergies():
	print("\n=== Calculando sinergias para ", building_name, " en (", grid_x, ", ", grid_y, ") ===")
	
	# Limpiar multiplicadores anteriores
	synergy_multipliers.clear()
	total_synergy_multiplier = 1.0
	
	# Obtener referencia al GridManager
	var grid_manager = get_parent()
	if not grid_manager:
		print("Error: No se pudo obtener referencia al GridManager")
		return
	
	# Obtener vecinos
	var neighbors = grid_manager.get_neighbors(grid_x, grid_y)
	print("Vecinos encontrados: ", neighbors.size())
	
	# Arrays para almacenar multiplicadores
	var positive_multipliers = []
	var negative_multipliers = []
	
	# Calcular multiplicador para cada dirección
	for direction in ["right", "left", "up", "down"]:
		var multiplier = 1.0
		
		if neighbors.has(direction):
			var neighbor = neighbors[direction]
			multiplier = calculate_synergy_with_neighbor(neighbor)
			var neighbor_name = ""
			if neighbor.has_method("get_building_name"):
				neighbor_name = neighbor.get_building_name()
			elif neighbor.has_method("get_structure_name"):
				neighbor_name = neighbor.get_structure_name()
			elif "building_name" in neighbor:
				neighbor_name = neighbor.building_name
			elif "structure_name" in neighbor:
				neighbor_name = neighbor.structure_name
			else:
				neighbor_name = "Desconocido"
			print("  ", direction, ": ", neighbor_name, " -> multiplicador: ", multiplier)
		else:
			print("  ", direction, ": Sin vecino")
		
		synergy_multipliers[direction] = multiplier
		
		# Separar multiplicadores positivos y negativos
		if multiplier > 1.0:
			positive_multipliers.append(multiplier)
		elif multiplier < 1.0:
			negative_multipliers.append(multiplier)
	
	# Calcular multiplicador total
	# Aplicar todos los multiplicadores positivos
	for mult in positive_multipliers:
		total_synergy_multiplier *= mult
	
	# Aplicar todos los multiplicadores negativos
	for mult in negative_multipliers:
		total_synergy_multiplier *= mult
	
	# Actualizar visualización
	update_synergy_display()
	
	# Notificar al GameManager para recalcular puntos totales
	call_deferred("notify_gamemanager_recalculate")
	
	print("  Multiplicador total final: ", total_synergy_multiplier)
	print("  PPS final: ", get_total_points_per_second())
	print("=== Fin cálculo sinergias ===\n")

# Función separada para notificar al GameManager (evita problemas de dependencias circulares)
func notify_gamemanager_recalculate():
	GameManager.recalculate_total_points_per_second()

# Función para calcular la sinergia con un vecino específico
func calculate_synergy_with_neighbor(neighbor: Node) -> float:
	var base_multiplier = 1.0
	
	# Verificar si el vecino es un edificio
	if neighbor.has_method("get_building_name"):
		var neighbor_name = neighbor.get_building_name()
		
		# Buscar sinergia definida
		if synergies.has(neighbor_name):
			var synergy_percent = synergies[neighbor_name]
			base_multiplier = 1.0 + (synergy_percent / 100.0)
			print("    Sinergia encontrada: ", building_name, " + ", neighbor_name, " = ", synergy_percent, "% (multiplicador: ", base_multiplier, ")")
		else:
			print("    Sin sinergia definida con: ", neighbor_name)
	
	# Verificar si el vecino es una estructura que modifica sinergias
	elif neighbor.has_method("modify_synergy"):
		var old_multiplier = base_multiplier
		base_multiplier = neighbor.modify_synergy(self, base_multiplier)
		print("    Estructura modifica sinergia: ", old_multiplier, " -> ", base_multiplier)
	
	return base_multiplier

# Función para actualizar la visualización de sinergias - CORREGIDA
func update_synergy_display():
	var directions = [
		{"label": right_synergy, "key": "right"},
		{"label": left_synergy, "key": "left"},
		{"label": up_synergy, "key": "up"},
		{"label": down_synergy, "key": "down"}
	]
	
	for dir in directions:
		var label = dir.label
		var multiplier = synergy_multipliers.get(dir.key, 1.0)
		
		if abs(multiplier - 1.0) > 0.001:  # Usar comparación con tolerancia para floats
			var percentage = int(round((multiplier - 1.0) * 100))
			if percentage > 0:
				label.text = "+" + str(percentage) + "%"
				label.modulate = Color.GREEN
				label.visible = true
			else:
				label.text = str(percentage) + "%"
				label.modulate = Color.RED
				label.visible = true
		else:
			label.text = ""
			label.visible = false

# Función para obtener el nombre del edificio
func get_building_name() -> String:
	return building_name

# Función para obtener los puntos por segundo totales (con sinergias aplicadas)
func get_total_points_per_second() -> float:
	return points_per_second * total_synergy_multiplier

# Función para obtener información del edificio
func get_building_info() -> Dictionary:
	return {
		"name": building_name,
		"cost": cost,
		"base_pps": points_per_second,
		"total_pps": get_total_points_per_second(),
		"synergy_multiplier": total_synergy_multiplier,
		"description": description
	}

# Función que se llama cuando un vecino cambia
func on_neighbor_changed():
	call_deferred("calculate_synergies")

# Función que se llama después de ser colocado en la cuadrícula
func on_placed_in_grid(x: int, y: int):
	grid_x = x
	grid_y = y
	print("Edificio ", building_name, " colocado en cuadrícula en (", x, ", ", y, ")")
	call_deferred("calculate_synergies")
