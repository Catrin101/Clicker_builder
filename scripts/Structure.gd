# Structure.gd - Clase base para todas las estructuras
class_name Structure
extends Node2D

# Variables exportadas
@export var structure_name: String = ""
@export var cost: int = 50
@export var points_per_second: float = 0.5
@export var description: String = ""

# Tipo de efecto que produce esta estructura
@export_enum("None", "Synergy_Multiplier", "Synergy_Nullifier", "Conditional_Multiplier") var effect_type: String = "None"

# Variables específicas del efecto
@export var multiplier_bonus: float = 0.0  # Bonus en porcentaje (ej: 10.0 para +10%)
@export var affects_buildings: Array[String] = []  # Qué edificios se ven afectados
@export var nullifies_negative: bool = false  # Si anula efectos negativos

# Variables de posición
var grid_x: int = 0
var grid_y: int = 0

# Referencias a nodos
@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D

func _ready():
	# Conectar señales del área
	area.input_event.connect(_on_area_input_event)
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)

func _on_area_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_structure_clicked()

func _on_mouse_entered():
	# Efecto visual al pasar el mouse
	sprite.modulate = Color.LIGHT_GREEN

func _on_mouse_exited():
	# Volver al color normal
	sprite.modulate = Color.WHITE

func _on_structure_clicked():
	print("Estructura clickeada: ", structure_name, " en (", grid_x, ", ", grid_y, ")")

# Función principal para modificar sinergia (llamada por edificios vecinos)
func modify_synergy(building: Building, base_multiplier: float) -> float:
	match effect_type:
		"Synergy_Multiplier":
			return apply_synergy_multiplier(building, base_multiplier)
		"Synergy_Nullifier":
			return apply_synergy_nullifier(building, base_multiplier)
		"Conditional_Multiplier":
			return apply_conditional_multiplier(building, base_multiplier)
		_:
			return base_multiplier

# Aplicar multiplicador de sinergia
func apply_synergy_multiplier(building: Building, base_multiplier: float) -> float:
	# Verificar si esta estructura afecta a este tipo de edificio
	if affects_buildings.is_empty() or affects_buildings.has(building.building_name):
		# Solo multiplicar si la sinergia es positiva
		if base_multiplier > 1.0:
			var additional_bonus = multiplier_bonus / 100.0
			return base_multiplier + additional_bonus
	
	return base_multiplier

# Anular sinergias negativas
func apply_synergy_nullifier(building: Building, base_multiplier: float) -> float:
	# Verificar si esta estructura afecta a este tipo de edificio
	if affects_buildings.is_empty() or affects_buildings.has(building.building_name):
		if nullifies_negative and base_multiplier < 1.0:
			return 1.0  # Neutralizar el efecto negativo
		elif not nullifies_negative and base_multiplier < 1.0:
			# Reducir el efecto negativo a la mitad
			var negative_amount = 1.0 - base_multiplier
			return 1.0 - (negative_amount * 0.5)
	
	return base_multiplier

# Aplicar multiplicador condicional
func apply_conditional_multiplier(building: Building, base_multiplier: float) -> float:
	# Esta función se puede personalizar en estructuras específicas
	# Por ejemplo, el Sastre anula negativas en Tabernas/Posadas
	# y multiplica positivas en Villas
	
	if affects_buildings.has(building.building_name):
		if building.building_name in ["Tavern", "Inn"] and base_multiplier < 1.0:
			# Anular efectos negativos
			return 1.0
		elif building.building_name == "Villa" and base_multiplier > 1.0:
			# Multiplicar efectos positivos
			var additional_bonus = multiplier_bonus / 100.0
			return base_multiplier + additional_bonus
	
	return base_multiplier

# Función para obtener el nombre de la estructura
func get_structure_name() -> String:
	return structure_name

# Función para obtener los puntos por segundo (las estructuras también generan puntos)
func get_total_points_per_second() -> float:
	return points_per_second

# Función para obtener información de la estructura
func get_structure_info() -> Dictionary:
	return {
		"name": structure_name,
		"cost": cost,
		"points_per_second": points_per_second,
		"effect_type": effect_type,
		"description": description
	}
	
