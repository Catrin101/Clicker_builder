# Terrain.gd - Script para las casillas de terreno (CORREGIDO)
extends Node2D

# Variables para la posición en la cuadrícula
var grid_x: int = 0
var grid_y: int = 0

# Variables para gestión de edificios
var has_building: bool = false
var building_node: Node = null

# Referencias a los nodos hijos
@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D
@onready var collision: CollisionShape2D = $Area2D/CollisionShape2D

func _ready():
	# Conectar señales del área
	area.input_event.connect(_on_area_input_event)
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	
	# Configurar el color inicial (verde para terreno libre)
	update_visual_state()

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_terrain_clicked()

func _on_mouse_entered():
	# Resaltar cuando el mouse está encima
	if not has_building:
		sprite.modulate = Color.LIGHT_GREEN

func _on_mouse_exited():
	# Volver al color normal
	update_visual_state()

func _on_terrain_clicked():
	print("Terreno clickeado en (", grid_x, ", ", grid_y, ")")
	
	# Si estamos en modo colocación de edificios
	if GameManager.is_placing_building and not has_building:
		var grid_manager = get_parent()
		if grid_manager.place_building(grid_x, grid_y, GameManager.building_to_place):
			# Salir del modo colocación
			GameManager.cancel_placing_mode()
		return
	
	# Si no hay edificio, mostrar opciones para expandir o comprar edificio
	if not has_building:
		show_terrain_options()

func show_terrain_options():
	print("Mostrando opciones para terreno en (", grid_x, ", ", grid_y, ")")
	# Aquí podrías mostrar un menú contextual
	# Por ahora solo mostraremos información en consola

func update_visual_state():
	if has_building:
		sprite.modulate = Color.WHITE  # Color normal si tiene edificio
	else:
		sprite.modulate = Color.LIGHT_BLUE  # Color azul claro para terreno libre

# Función para colocar un edificio en este terreno
func set_building(building: Node):
	has_building = true
	building_node = building
	update_visual_state()

# Función para quitar un edificio de este terreno
func remove_building():
	has_building = false
	if building_node:
		building_node.queue_free()
		building_node = null
	update_visual_state()
