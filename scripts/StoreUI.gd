# StoreUI.gd - Interfaz de la tienda de edificios - SPRINT 3 COMPLETO
extends VBoxContainer

# Referencias a nodos
@onready var buildings_list: VBoxContainer = $BuildingsList

# Lista de edificios disponibles para comprar - EXPANDIDA
var available_buildings = [
	# Edificios Esenciales
	{
		"name": "Casa del Aldeano",
		"scene_path": "res://escenas/House.tscn",
		"cost": 50,
		"pps": 0.5,
		"description": "Un hogar modesto para tus aldeanos. Es la base de todo asentamiento.",
		"category": "Esenciales"
	},
	{
		"name": "La Taberna del Ciervo",
		"scene_path": "res://escenas/Tavern.tscn",
		"cost": 250,
		"pps": 2.0,
		"description": "Un animado punto de encuentro para los aldeanos.",
		"category": "Esenciales"
	},
	{
		"name": "La Posada del Caminante",
		"scene_path": "res://escenas/Inn.tscn",
		"cost": 400,
		"pps": 3.5,
		"description": "Un lugar para descansar a los viajeros cansados.",
		"category": "Esenciales"
	},
	{
		"name": "Castillo",
		"scene_path": "res://escenas/Castle.tscn",
		"cost": 2000,
		"pps": 5.0,
		"description": "El corazón de tu reino. Protege y administra tu pueblo.",
		"category": "Esenciales"
	}
]

# Variable para seguimiento de categorías
var current_category: String = "Todos"

func _ready():
	# Crear los elementos de la tienda
	create_store_items()
	
	# Conectar señales del GameManager
	GameManager.points_changed.connect(_on_points_changed)
	GameManager.building_placement_started.connect(_on_building_placement_started)
	GameManager.building_placement_cancelled.connect(_on_building_placement_cancelled)

func create_store_items():
	# Limpiar la lista actual
	for child in buildings_list.get_children():
		child.queue_free()
	
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
			var category_label = create_category_header(category)
			buildings_list.add_child(category_label)
		
		# Añadir edificios de esta categoría
		for building_data in categories[category]:
			var building_item = create_building_item(building_data)
			buildings_list.add_child(building_item)

func create_category_header(category: String) -> Control:
	var container = VBoxContainer.new()
	
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

func create_building_item(building_data: Dictionary) -> Control:
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Contenedor principal horizontal
	var main_container = HBoxContainer.new()
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Panel de información izquierdo
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_container.size_flags_stretch_ratio = 2.5
	
	# Nombre del edificio
	var name_label = Label.new()
	name_label.text = building_data.name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_container.add_child(name_label)
	
	# Estadísticas
	var stats_label = Label.new()
	stats_label.text = "💰 " + str(building_data.cost) + " | ⚡ +" + str(building_data.pps) + " PPS"
	stats_label.add_theme_font_size_override("font_size", 12)
	stats_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	info_container.add_child(stats_label)
	
	# Descripción
	var desc_label = Label.new()
	desc_label.text = building_data.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", Color.GRAY)
	desc_label.custom_minimum_size.y = 40
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	info_container.add_child(desc_label)
	
	# Botón de compra
	var button = Button.new()
	button.text = "COMPRAR"
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_stretch_ratio = 1.0
	button.custom_minimum_size = Vector2(80, 60)
	
	# Añadir componentes al contenedor principal
	main_container.add_child(info_container)
	main_container.add_child(VSeparator.new())  # Separador vertical
	main_container.add_child(button)
	
	# Panel contenedor con borde
	var panel = Panel.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 80
	panel.add_child(main_container)
	
	# Configurar márgenes
	main_container.position = Vector2(5, 5)
	main_container.size = panel.size - Vector2(10, 10)
	main_container.anchors_preset = Control.PRESET_FULL_RECT
	main_container.anchor_left = 0
	main_container.anchor_top = 0
	main_container.anchor_right = 1
	main_container.anchor_bottom = 1
	main_container.offset_left = 5
	main_container.offset_top = 5
	main_container.offset_right = -5
	main_container.offset_bottom = -5
	
	# Separador entre elementos
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 8
	
	# Añadir al contenedor final
	container.add_child(panel)
	container.add_child(separator)
	
	# Conectar señal del botón
	button.pressed.connect(_on_building_button_pressed.bind(building_data))
	
	# Guardar referencia al building_data en el botón
	button.set_meta("building_data", building_data)
	panel.set_meta("building_data", building_data)  # También en el panel
	
	return container

func _on_building_button_pressed(building_data: Dictionary):
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

func show_cannot_afford_feedback(building_name: String):
	create_temporary_feedback("❌ No tienes suficientes puntos para " + building_name + "!", Color.RED)

func show_purchase_feedback(building_name: String):
	create_temporary_feedback("✅ " + building_name + " comprado! Selecciona donde colocarlo.", Color.GREEN)

func create_temporary_feedback(message: String, color: Color):
	# Crear un panel de retroalimentación
	var feedback_panel = Panel.new()
	feedback_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_panel.custom_minimum_size.y = 50
	
	var feedback_label = Label.new()
	feedback_label.text = message
	feedback_label.modulate = color
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.anchors_preset = Control.PRESET_FULL_RECT
	
	feedback_panel.add_child(feedback_label)
	
	# Añadir temporalmente al inicio de la lista
	buildings_list.add_child(feedback_panel)
	buildings_list.move_child(feedback_panel, 0)
	
	# Crear tween para efecto de desvanecimiento
	var tween = create_tween()
	tween.tween_delay(1.5)  # Esperar 1.5 segundos
	tween.tween_property(feedback_panel, "modulate:a", 0.0, 1.0)  # Desvanecer en 1 segundo
	tween.tween_callback(feedback_panel.queue_free)

func _on_points_changed(new_points: int):
	# Actualizar el estado de los botones según los puntos disponibles
	update_buttons_state()

func _on_building_placement_started(building_scene: String):
	# Deshabilitar todos los botones durante la colocación
	set_buttons_enabled(false)
	
	# Cambiar el texto del título para indicar el modo de colocación
	var title_label = get_parent().get_node("StoreTitle")
	if title_label:
		title_label.text = "🏗️ MODO COLOCACIÓN"
		title_label.add_theme_color_override("font_color", Color.YELLOW)

func _on_building_placement_cancelled():
	print("Colocación de edificio cancelada.")
	# Rehabilitar los botones
	set_buttons_enabled(true)
	update_buttons_state()
	
	# Restaurar el texto del título
	var title_label = get_parent().get_node("StoreTitle")
	if title_label:
		title_label.text = "TIENDA DE EDIFICIOS"
		title_label.add_theme_color_override("font_color", Color.WHITE)

func set_buttons_enabled(enabled: bool):
	for container in buildings_list.get_children():
		# Buscar el panel dentro del contenedor
		for child in container.get_children():
			if child is Panel and child.has_meta("building_data"):
				var main_container = child.get_child(0)  # HBoxContainer
				if main_container.get_child_count() >= 3:
					var button = main_container.get_child(2)  # El botón es el tercer hijo
					if button is Button:
						button.disabled = !enabled

func update_buttons_state():
	for container in buildings_list.get_children():
		# Buscar el panel dentro del contenedor
		for child in container.get_children():
			if child is Panel and child.has_meta("building_data"):
				var building_data = child.get_meta("building_data")
				var can_afford = GameManager.can_afford(building_data.cost)
				
				var main_container = child.get_child(0)  # HBoxContainer
				if main_container.get_child_count() >= 3:
					var button = main_container.get_child(2)  # El botón es el tercer hijo
					if button is Button:
						button.disabled = !can_afford
						
						# Cambiar el color según si puede comprarse o no
						if can_afford:
							button.modulate = Color.WHITE
							button.text = "COMPRAR"
						else:
							button.modulate = Color(0.6, 0.6, 0.6, 1.0)
							button.text = "SIN FONDOS"
				
				# Cambiar el color del panel también
				if can_afford:
					child.modulate = Color.WHITE
				else:
					child.modulate = Color(0.8, 0.8, 0.8, 1.0)

# Función para añadir más edificios dinámicamente
func add_building_to_store(building_data: Dictionary):
	available_buildings.append(building_data)
	# Recrear los elementos de la tienda
	call_deferred("create_store_items")

# Función para filtrar por categoría (para futuras expansiones)
func filter_by_category(category: String):
	current_category = category
	create_store_items()

# Función para obtener estadísticas de la tienda
func get_store_stats() -> Dictionary:
	return {
		"total_buildings": available_buildings.size(),
		"categories": get_available_categories(),
		"price_range": get_price_range()
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
