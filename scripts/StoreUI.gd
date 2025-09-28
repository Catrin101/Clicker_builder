# StoreUI.gd - Interfaz de la tienda de edificios - VERSIÓN CORREGIDA
extends VBoxContainer

# Referencias a nodos
@onready var buildings_list: VBoxContainer = $BuildingsList

# Precargar la escena del elemento de tienda
@export var building_item_scene: PackedScene = preload("res://escenas/BuildingStoreItem.tscn")

# Lista de edificios disponibles para comprar - EXPANDIDA
var available_buildings = [
	# Edificios Esenciales
	{
		"name": "Casa del Aldeano",
		"scene_path": "res://escenas/Estructuras/House.tscn",
		"cost": 50,
		"pps": 0.5,
		"description": "Un hogar modesto para tus aldeanos. Es la base de todo asentamiento.",
		"category": "Esenciales"
	},
	{
		"name": "La Taberna del Ciervo",
		"scene_path": "res://escenas/Estructuras/Tavern.tscn",
		"cost": 250,
		"pps": 2.0,
		"description": "Un animado punto de encuentro para los aldeanos.",
		"category": "Esenciales"
	},
	{
		"name": "La Posada del Caminante",
		"scene_path": "res://escenas/Estructuras/Inn.tscn",
		"cost": 400,
		"pps": 3.5,
		"description": "Un lugar para descansar a los viajeros cansados.",
		"category": "Esenciales"
	},
	{
		"name": "Castillo",
		"scene_path": "res://escenas/Estructuras/Castle.tscn",
		"cost": 2000,
		"pps": 5.0,
		"description": "El corazón de tu reino. Protege y administra tu pueblo.",
		"category": "Esenciales"
	},
	{
		"name": "Base Militar",
		"scene_path": "res://escenas/Estructuras/BaseMilitar.tscn",
		"cost": 2500,
		"pps": 5.0,
		"description": "Toda gran naacon requiere de un cuerpo militar que le defienda.",
		"category": "Desarrollo y Satisfaccion"
	},
	{
		"name": "Capilla de la Luz",
		"scene_path": "res://escenas/Estructuras/Chapel.tscn",
		"cost": 800,
		"pps": 2.5,
		"description": "Un lugar de oración y reflexión que satisface las necesidades espirituales de tu gente, mejorando la moral y la estabilidad general del pueblo.",
		"category": "Desarrollo y Satisfaccion"
	},
	{
		"name": "Torre del Reloj",
		"scene_path": "res://escenas/Estructuras/Clock.tscn",
		"cost": 1500,
		"pps": 4.0,
		"description": "El pináculo de la ingeniería local. La Torre del Reloj mejora la coordinación de los trabajadores y es un símbolo del progreso de tu pueblo.",
		"category": "Desarrollo y Satisfaccion"
	},
	{
		"name": "Villa del Comerciante",
		"scene_path": "res://escenas/Estructuras/Villa.tscn",
		"cost": 3000,
		"pps": 6.0,
		"description": "Una residencia opulenta para los más ricos de la sociedad. La villa atrae a comerciantes influyentes y eleva el prestigio de tu pueblo.",
		"category": "Lujo y Unicos"
	},
	{
		"name": "Cabaña de Techo de Paja",
		"scene_path": "res://escenas/Estructuras/Thayched.tscn",
		"cost": 30,
		"pps": 0.25,
		"description": "Una vivienda rústica y primitiva. Aunque es más económica, su construcción es menos eficiente para el crecimiento de la población.",
		"category": "Lujo y Unicos"
	},
	{
		"name": "Casa del Árbol de Sylvan",
		"scene_path": "res://escenas/Estructuras/TreeHouse.tscn",
		"cost": 5000,
		"pps": 8.0,
		"description": "Un edificio mágico y único, escondido en la cima de los árboles. Proporciona una gran cantidad de monedas por su singularidad y encanto.",
		"category": "Lujo y Unicos"
	},
]

# Variable para seguimiento de categorías
var current_category: String = "Todos"

# Array para mantener referencias a los elementos de la tienda
var building_items: Array[Panel] = []

# Referencia al panel de feedback activo (solo uno a la vez)
var active_feedback_panel: Control = null

func _ready():
	# Configurar el contenedor principal
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Crear los elementos de la tienda
	create_store_items()
	
	# Conectar señales del GameManager
	GameManager.points_changed.connect(_on_points_changed)
	GameManager.building_placement_started.connect(_on_building_placement_started)
	GameManager.building_placement_cancelled.connect(_on_building_placement_cancelled)

func create_store_items():
	# Limpiar la lista actual
	clear_building_items()
	
	# Crear secciones por categoría
	var categories = {}
	for building_data in available_buildings:
		var category = building_data.get("category", "Sin categoría")
		if not categories.has(category):
			categories[category] = []
		categories[category].append(building_data)
	
	# Crear elementos organizados por categoría
	for category in categories:
		# Añadir encabezado de categoría
		if categories.size() > 1:  # Solo mostrar categorías si hay más de una
			var category_header = create_category_header(category)
			buildings_list.add_child(category_header)
		
		# Añadir edificios de esta categoría
		for building_data in categories[category]:
			var building_item = create_building_item_from_scene(building_data)
			buildings_list.add_child(building_item)
			building_items.append(building_item)

func clear_building_items():
	# Limpiar referencias
	building_items.clear()
	
	# Eliminar todos los hijos de la lista
	for child in buildings_list.get_children():
		child.queue_free()

func create_category_header(category: String) -> Control:
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Separador superior
	var separator_top = HSeparator.new()
	separator_top.custom_minimum_size.y = 10
	container.add_child(separator_top)
	
	# Etiqueta de categoría
	var label = Label.new()
	label.text = "=== " + category.to_upper() + " ==="
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.GOLD)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(label)
	
	# Separador inferior
	var separator_bottom = HSeparator.new()
	separator_bottom.custom_minimum_size.y = 5
	container.add_child(separator_bottom)
	
	return container

func create_building_item_from_scene(building_data: Dictionary) -> Panel:
	# Instanciar la escena del elemento de tienda
	var building_item = building_item_scene.instantiate()
	
	# Configurar size flags para que se ajuste correctamente
	building_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	building_item.custom_minimum_size = Vector2(0, 100)
	
	# IMPORTANTE: Llamar a _ready primero antes de setup_building_data
	# Esto se hace automáticamente cuando se añade al árbol de nodos
	
	# Configurar los datos del edificio usando call_deferred para asegurar que _ready se ejecute primero
	building_item.call_deferred("setup_building_data", building_data)
	
	# Conectar señal de compra
	building_item.building_purchase_requested.connect(_on_building_purchase_requested)
	
	return building_item

func _on_building_purchase_requested(building_data: Dictionary):
	print("Edificio seleccionado: ", building_data.name)
	
	# Verificar si el jugador puede comprarlo
	if not GameManager.can_afford(building_data.cost):
		print("No tienes suficientes puntos para comprar: ", building_data.name)
		show_cannot_afford_feedback(building_data.name)
		return
	
	# Restar los puntos
	if GameManager.subtract_points(building_data.cost):
		print("¡", building_data.name, " comprado por ", building_data.cost, " puntos!")
		show_purchase_feedback(building_data.name)
		# Iniciar modo de colocación
		GameManager.start_placing_mode(building_data.scene_path)
		
		# Encontrar el elemento que hizo la compra y mostrar feedback visual
		for item in building_items:
			if item.get_building_data() == building_data:
				item.show_purchase_feedback(true, "✅ Comprado! Selecciona ubicación")
				break

func show_cannot_afford_feedback(building_name: String):
	create_temporary_feedback("❌ No tienes suficientes puntos para " + building_name + "!", Color.RED)
	
	# También mostrar feedback en el elemento específico
	for item in building_items:
		var item_data = item.get_building_data()
		if item_data.get("name", "") == building_name:
			item.show_purchase_feedback(false, "❌ Sin fondos suficientes")
			break

func show_purchase_feedback(building_name: String):
	create_temporary_feedback("✅ " + building_name + " comprado! Selecciona donde colocarlo.", Color.GREEN)

func create_temporary_feedback(message: String, color: Color):
	# Remover feedback anterior si existe
	if active_feedback_panel and is_instance_valid(active_feedback_panel):
		active_feedback_panel.queue_free()
	
	# Crear un panel de retroalimentación temporal
	var feedback_panel = Panel.new()
	feedback_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_panel.custom_minimum_size.y = 60
	
	# Estilo del panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(color.r, color.g, color.b, 0.2)
	style_box.border_color = color
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	feedback_panel.add_theme_stylebox_override("panel", style_box)
	
	# Contenedor con márgenes
	var margin_container = MarginContainer.new()
	margin_container.anchors_preset = Control.PRESET_FULL_RECT
	margin_container.add_theme_constant_override("margin_left", 10)
	margin_container.add_theme_constant_override("margin_right", 10)
	margin_container.add_theme_constant_override("margin_top", 10)
	margin_container.add_theme_constant_override("margin_bottom", 10)
	
	var feedback_label = Label.new()
	feedback_label.text = message
	feedback_label.add_theme_color_override("font_color", color)
	feedback_label.add_theme_font_size_override("font_size", 14)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	margin_container.add_child(feedback_label)
	feedback_panel.add_child(margin_container)
	
	# CORRECCIÓN: Añadir al contenedor principal (VBoxContainer) en lugar de buildings_list
	# para que esté dentro del panel visible
	add_child(feedback_panel)
	move_child(feedback_panel, 2)  # Posición después del título y separador
	
	# Guardar referencia al panel activo
	active_feedback_panel = feedback_panel
	
	# Crear tween para efecto de desvanecimiento
	var tween = create_tween()
	tween.tween_interval(2.5)  # Mostrar por 2.5 segundos
	tween.tween_property(feedback_panel, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): 
		if active_feedback_panel == feedback_panel:
			active_feedback_panel = null
		feedback_panel.queue_free()
	)

func _on_points_changed(new_points: int):
	# Los elementos individuales se actualizan automáticamente
	# gracias a sus propias conexiones con GameManager
	pass

func _on_building_placement_started(building_scene: String):
	# Cambiar el texto del título para indicar el modo de colocación
	var title_label = get_parent().get_node("StoreTitle")
	if title_label:
		title_label.text = "🏗️ MODO COLOCACIÓN"
		title_label.add_theme_color_override("font_color", Color.YELLOW)

func _on_building_placement_cancelled():
	print("Colocación de edificio cancelada.")
	
	# Restaurar el texto del título
	var title_label = get_parent().get_node("StoreTitle")
	if title_label:
		title_label.text = "TIENDA DE EDIFICIOS"
		title_label.add_theme_color_override("font_color", Color.WHITE)

# Función para añadir más edificios dinámicamente
func add_building_to_store(building_data: Dictionary):
	available_buildings.append(building_data)
	# Recrear los elementos de la tienda
	call_deferred("create_store_items")

# Función para remover un edificio de la tienda
func remove_building_from_store(building_name: String):
	for i in range(available_buildings.size() - 1, -1, -1):
		if available_buildings[i].get("name", "") == building_name:
			available_buildings.remove_at(i)
			break
	# Recrear los elementos de la tienda
	call_deferred("create_store_items")

# Función para filtrar por categoría (para futuras expansiones)
func filter_by_category(category: String):
	current_category = category
	create_store_items()

# Función para destacar un edificio específico
func highlight_building(building_name: String):
	for item in building_items:
		var item_data = item.get_building_data()
		if item_data.get("name", "") == building_name:
			item.highlight_item()
			break

# Función para obtener estadísticas de la tienda
func get_store_stats() -> Dictionary:
	return {
		"total_buildings": available_buildings.size(),
		"categories": get_available_categories(),
		"price_range": get_price_range(),
		"affordable_buildings": count_affordable_buildings()
	}

func get_available_categories() -> Array:
	var categories = []
	for building in available_buildings:
		var category = building.get("category", "Sin categoría")
		if not categories.has(category):
			categories.append(category)
	return categories

func get_price_range() -> Dictionary:
	var prices = []
	for building in available_buildings:
		prices.append(building.cost)
	
	prices.sort()
	return {
		"min": prices[0] if prices.size() > 0 else 0,
		"max": prices[-1] if prices.size() > 0 else 0
	}

func count_affordable_buildings() -> int:
	var count = 0
	for building in available_buildings:
		if GameManager.can_afford(building.cost):
			count += 1
	return count

# Función para refrescar todos los elementos (útil para debugging)
func refresh_all_items():
	for item in building_items:
		item.update_button_state()

# Función para obtener un edificio por nombre
func get_building_by_name(building_name: String) -> Dictionary:
	for building in available_buildings:
		if building.get("name", "") == building_name:
			return building
	return {}

# Función para limpiar feedback activo (útil para transiciones)
func clear_active_feedback():
	if active_feedback_panel and is_instance_valid(active_feedback_panel):
		active_feedback_panel.queue_free()
		active_feedback_panel = null
