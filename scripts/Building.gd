# Building.gd - Clase base para todos los edificios
class_name Building
extends Node2D

# Variables exportadas (configurables desde el editor)
@export var building_name: String = ""
@export var cost: int = 100
@export var points_per_second: float = 1.0
@export var description: String = ""

# Diccionario de sinergias: edificio_vecino -> porcentaje_de_cambio
# Ejemplo: {"House": 10, "Tavern": -5} significa +10% con Casa, -5% con Taberna
@export var synergies: Dictionary = {}

# Variables de posición en cuadrícula
var grid_x: int = 0
var grid_y: int = 0

# Variables de sinergia calculada
var synergy_multipliers: Dictionary = {}  # Dirección -> multiplicador
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
	
	# Calcular sinergias iniciales
	call_deferred("calculate_synergies")

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_building_clicked()

func _on_mouse_entered():
	# Efecto visual al pasar el mouse
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2)
	
func _on_mouse_exited():
	# Volver al tamaño normal
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

func _on_building_clicked():
	print("Edificio clickeado: ", building_name, " en (", grid_x, ", ", grid_y, ")")
	# Aquí se podría mostrar información del edificio o menú contextual

# Función para iniciar la animación de balanceo
func start_bobble_animation():
	if not tween:
		tween = create_tween()
	
	tween.set_loops()
	# Animación sutil de balanceo
	tween.tween_property(sprite, "rotation", deg_to_rad(2), 2.0)
	tween.tween_property(sprite, "rotation", deg_to_rad(-2), 2.0)

# Función principal para calcular sinergias
func calculate_synergies():
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
	
	# Calcular multiplicador para cada dirección
	for direction in ["right", "left", "up", "down"]:
		var multiplier = 1.0
		
		if neighbors.has(direction):
			var neighbor = neighbors[direction]
			multiplier = calculate_synergy_with_neighbor(neighbor)
		
		synergy_multipliers[direction] = multiplier
	
	# Calcular multiplicador total (promedio de todas las direcciones)
	var total_multiplier = 0.0
	var count = 0
	
	for direction in synergy_multipliers:
		total_multiplier += synergy_multipliers[direction]
		count += 1
	
	if count > 0:
		total_synergy_multiplier = total_multiplier / count
	
	# Actualizar visualización
	update_synergy_display()
	
	# Notificar al GameManager para recalcular puntos totales
	GameManager.recalculate_total_points_per_second()
	
	print("Sinergias recalculadas para ", building_name, " - Multiplicador total: ", total_synergy_multiplier)

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
			print("Sinergia encontrada: ", building_name, " + ", neighbor_name, " = ", synergy_percent, "%")
	
	# Verificar si el vecino es una estructura que modifica sinergias
	elif neighbor.has_method("modify_synergy"):
		base_multiplier = neighbor.modify_synergy(self, base_multiplier)
	
	return base_multiplier

# Función para actualizar la visualización de sinergias
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
		
		if multiplier != 1.0:
			var percentage = int((multiplier - 1.0) * 100)
			if percentage > 0:
				label.text = "+" + str(percentage) + "%"
				label.modulate = Color.GREEN
			else:
				label.text = str(percentage) + "%"
				label.modulate = Color.RED
		else:
			label.text = ""

# Función para obtener el nombre del edificio (usado por otros edificios)
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

# Función que se llama cuando un vecino cambia (para recalcular sinergias)
func on_neighbor_changed():
	call_deferred("calculate_synergies")
