# StoreUI.gd - VERSIÓN CORREGIDA PARA EXPORTACIÓN
extends VBoxContainer

# Referencias a nodos
@onready var buildings_list: VBoxContainer = $BuildingsList

# Rutas de recursos (NO usar preload en @export)
var building_item_scene_path: String = "res://escenas/BuildingStoreItem.tscn"
var feedback_panel_scene_path: String = "res://escenas/Feedback_Panel.tscn"

# Escenas cargadas
var building_item_scene: PackedScene = null
var feedback_panel_scene: PackedScene = null

# Lista de edificios disponibles para comprar
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
		"name": "Capilla de la Luz",
		"scene_path": "res://escenas/Estructuras/Chapel.tscn",
		"cost": 800,
		"pps": 2.5,
		"description": "Un lugar de oración y reflexión que satisface las necesidades espirituales de tu gente.",
		"category": "Desarrollo y Satisfaccion"
	},
	{
		"name": "Torre del Reloj",
		"scene_path": "res://escenas/Estructuras/Clock.tscn",
		"cost": 1500,
		"pps": 4.0,
		"description": "El pináculo de la ingeniería local. La Torre del Reloj mejora la coordinación de los trabajadores",
		"category": "Desarrollo y Satisfaccion"
	},
	{
		"name": "Base Militar",
		"scene_path": "res://escenas/Estructuras/BaseMilitar.tscn",
		"cost": 2500,
		"pps": 6.0,
		"description": "Todo ciudad en crecimiento nesesita poteccion de una buena Milicia",
		"category": "Desarrollo y Satisfaccion"
	},
	{
		"name": "Villa del Comerciante",
		"scene_path": "res://escenas/Estructuras/Villa.tscn",
		"cost": 3000,
		"pps": 6.0,
		"description": "Una residencia opulenta para los más ricos de la sociedad.",
		"category": "Lujo y Unicos"
	},
	{
		"name": "Cabaña de Techo de Paja",
		"scene_path": "res://escenas/Estructuras/Thayched.tscn",
		"cost": 30,
		"pps": 0.25,
		"description": "Una vivienda rústica y primitiva. Aunque es más económica.",
		"category": "Lujo y Unicos"
	},
	{
		"name": "Casa del Árbol de Sylvan",
		"scene_path": "res://escenas/Estructuras/TreeHouse.tscn",
		"cost": 5000,
		"pps": 8.0,
		"description": "Un edificio mágico y único, escondido en la cima de los árboles.",
		"category": "Lujo y Unicos"
	},
]

# Variable para seguimiento de categorías
var current_category: String = "Todos"

# Array para mantener referencias a los elementos de la tienda
var building_items: Array[Panel] = []

# Referencia al panel de feedback activo
var active_feedback_panel: Control = null

func _ready():
	print("🏪 StoreUI iniciando...")
	
	# CRÍTICO: Verificar que buildings_list existe
	if not buildings_list:
		printerr("❌ ERROR CRÍTICO: BuildingsList no encontrado en StoreUI!")
		printerr("   Ruta esperada: $BuildingsList")
		printerr("   Nodos hijos disponibles:")
		for child in get_children():
			printerr("     - ", child.name, " (", child.get_class(), ")")
		return
	
	print("✅ BuildingsList encontrado correctamente")
	
	# Configurar el contenedor principal
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 5)
	
	# Configurar buildings_list
	buildings_list.add_theme_constant_override("separation", 8)
	
	# CRÍTICO: Cargar recursos de forma segura
	if not load_required_resources():
		printerr("❌ ERROR: No se pudieron cargar los recursos necesarios")
		return
	
	print("✅ Recursos cargados exitosamente")
	
	# Crear los elementos de la tienda
	await get_tree().process_frame  # Esperar un frame
	create_store_items()
	
	# Conectar señales del GameManager
	if GameManager:
		GameManager.points_changed.connect(_on_points_changed)
		GameManager.building_placement_started.connect(_on_building_placement_started)
		GameManager.building_placement_cancelled.connect(_on_building_placement_cancelled)
		print("✅ Señales de GameManager conectadas")
	else:
		printerr("❌ ERROR: GameManager no disponible")
	
	print("✅ StoreUI inicializado completamente")

# NUEVA FUNCIÓN: Cargar recursos de forma segura
func load_required_resources() -> bool:
	print("📦 Cargando recursos...")
	
	# Intentar cargar building_item_scene
	if ResourceLoader.exists(building_item_scene_path):
		building_item_scene = load(building_item_scene_path)
		if building_item_scene:
			print("  ✅ BuildingStoreItem.tscn cargado")
		else:
			printerr("  ❌ Error cargando BuildingStoreItem.tscn")
			return false
	else:
		printerr("  ❌ No existe: ", building_item_scene_path)
		return false
	
	# Intentar cargar feedback_panel_scene
	if ResourceLoader.exists(feedback_panel_scene_path):
		feedback_panel_scene = load(feedback_panel_scene_path)
		if feedback_panel_scene:
			print("  ✅ Feedback_Panel.tscn cargado")
		else:
			printerr("  ❌ Error cargando Feedback_Panel.tscn (no crítico)")
			# No es crítico, continuar sin él
	else:
		printerr("  ⚠️ No existe Feedback_Panel.tscn (no crítico)")
	
	return true

func create_store_items():
	print("🏗️ Creando elementos de la tienda...")
	print("   Edificios disponibles: ", available_buildings.size())
	
	if not building_item_scene:
		printerr("❌ ERROR: building_item_scene no está cargado")
		return
	
	if not buildings_list:
		printerr("❌ ERROR: buildings_list no existe")
		return
	
	# Limpiar la lista actual
	clear_building_items()
	
	# Crear secciones por categoría
	var categories = {}
	for building_data in available_buildings:
		var category = building_data.get("category", "Sin categoría")
		if not categories.has(category):
			categories[category] = []
		categories[category].append(building_data)
	
	print("   Categorías encontradas: ", categories.keys())
	
	# Crear elementos organizados por categoría
	var is_first_category = true
	var items_created = 0
	
	for category in categories:
		print("   📂 Procesando categoría: ", category)
		
		# Añadir separador antes de cada categoría (excepto la primera)
		if not is_first_category:
			var category_separator = create_category_separator()
			buildings_list.add_child(category_separator)
		
		# Añadir encabezado de categoría
		if categories.size() > 1:
			var category_header = create_category_header(category)
			buildings_list.add_child(category_header)
		
		# Añadir edificios de esta categoría
		for i in range(categories[category].size()):
			var building_data = categories[category][i]
			print("      🏢 Creando item para: ", building_data.name)
			
			var building_item = create_building_item_from_scene(building_data)
			
			if building_item:
				buildings_list.add_child(building_item)
				building_items.append(building_item)
				items_created += 1
				print("         ✅ Item creado exitosamente")
			else:
				printerr("         ❌ Error creando item para: ", building_data.name)
			
			# Añadir separador entre edificios
			if i < categories[category].size() - 1:
				var item_separator = create_item_separator()
				buildings_list.add_child(item_separator)
		
		is_first_category = false
	
	print("✅ Elementos de tienda creados: ", items_created, "/", available_buildings.size())
	
	# Forzar actualización visual
	await get_tree().process_frame
	buildings_list.queue_redraw()

func clear_building_items():
	building_items.clear()
	
	if buildings_list:
		for child in buildings_list.get_children():
			child.queue_free()

func create_category_separator() -> Control:
	var separator = Control.new()
	separator.custom_minimum_size = Vector2(0, 20)
	separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return separator

func create_item_separator() -> Control:
	var separator = Control.new()
	separator.custom_minimum_size = Vector2(0, 4)
	separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return separator

func create_category_header(category: String) -> Control:
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var separator_top = HSeparator.new()
	separator_top.custom_minimum_size.y = 2
	separator_top.add_theme_color_override("color", Color(0.6, 0.6, 0.6, 0.8))
	container.add_child(separator_top)
	
	var label_container = MarginContainer.new()
	label_container.add_theme_constant_override("margin_top", 8)
	label_container.add_theme_constant_override("margin_bottom", 8)
	label_container.add_theme_constant_override("margin_left", 10)
	label_container.add_theme_constant_override("margin_right", 10)
	
	var label = Label.new()
	label.text = "=== " + category.to_upper() + " ==="
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.GOLD)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	label_container.add_child(label)
	container.add_child(label_container)
	
	var separator_bottom = HSeparator.new()
	separator_bottom.custom_minimum_size.y = 2
	separator_bottom.add_theme_color_override("color", Color(0.6, 0.6, 0.6, 0.8))
	container.add_child(separator_bottom)
	
	return container

func create_building_item_from_scene(building_data: Dictionary) -> Panel:
	if not building_item_scene:
		printerr("❌ building_item_scene no está disponible")
		return null
	
	# Instanciar la escena
	var building_item = building_item_scene.instantiate()
	
	if not building_item:
		printerr("❌ Error al instanciar building_item_scene")
		return null
	
	# Configurar size flags
	building_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	building_item.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Añadir estilo visual
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style_box.border_color = Color(0.4, 0.4, 0.4, 0.6)
	style_box.border_width_left = 1
	style_box.border_width_right = 1
	style_box.border_width_top = 1
	style_box.border_width_bottom = 1
	style_box.corner_radius_top_left = 6
	style_box.corner_radius_top_right = 6
	style_box.corner_radius_bottom_left = 6
	style_box.corner_radius_bottom_right = 6
	style_box.content_margin_top = 4
	style_box.content_margin_bottom = 4
	style_box.content_margin_left = 4
	style_box.content_margin_right = 4
	
	building_item.add_theme_stylebox_override("panel", style_box)
	
	# CRÍTICO: Configurar datos INMEDIATAMENTE sin call_deferred
	# El item ya tendrá su _ready() llamado cuando se añada al árbol
	if building_item.has_method("setup_building_data"):
		# Esperar a que el item esté en el árbol
		building_item.ready.connect(func(): 
			building_item.setup_building_data(building_data)
		, CONNECT_ONE_SHOT)
	
	# Conectar señal de compra
	if building_item.has_signal("building_purchase_requested"):
		building_item.building_purchase_requested.connect(_on_building_purchase_requested)
	
	return building_item

func _on_building_purchase_requested(building_data: Dictionary):
	print("Edificio seleccionado: ", building_data.name)
	
	if not GameManager.can_afford(building_data.cost):
		print("No tienes suficientes puntos para comprar: ", building_data.name)
		show_cannot_afford_feedback(building_data.name)
		return
	
	if GameManager.subtract_points(building_data.cost):
		print("¡", building_data.name, " comprado por ", building_data.cost, " puntos!")
		show_purchase_feedback(building_data.name)
		GameManager.start_placing_mode(building_data.scene_path)
		
		for item in building_items:
			if item.get_building_data() == building_data:
				item.show_purchase_feedback(true, "✅ Comprado! Selecciona ubicación")
				break

func show_cannot_afford_feedback(building_name: String):
	create_temporary_feedback("❌ No tienes suficientes puntos para " + building_name + "!", Color.RED)
	
	for item in building_items:
		var item_data = item.get_building_data()
		if item_data.get("name", "") == building_name:
			item.show_purchase_feedback(false, "❌ Sin fondos suficientes")
			break

func show_purchase_feedback(building_name: String):
	create_temporary_feedback("✅ " + building_name + " comprado! Selecciona donde colocarlo.", Color.GREEN)

func create_temporary_feedback(message: String, color: Color):
	if active_feedback_panel and is_instance_valid(active_feedback_panel):
		active_feedback_panel.queue_free()
	
	# Solo crear feedback si la escena existe
	if not feedback_panel_scene:
		print("⚠️ Feedback visual no disponible (feedback_panel_scene no cargado)")
		return
	
	var feedback_panel = feedback_panel_scene.instantiate()
	
	add_child(feedback_panel)
	move_child(feedback_panel, 2)
	
	feedback_panel.setup(message, color, 2.5)
	active_feedback_panel = feedback_panel
	
	var tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(feedback_panel, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): 
		if active_feedback_panel == feedback_panel:
			active_feedback_panel = null
		if is_instance_valid(feedback_panel):
			feedback_panel.queue_free()
	)

func _on_points_changed(new_points: int):
	pass

func _on_building_placement_started(building_scene: String):
	var title_label = get_parent().get_node_or_null("StoreTitle")
	if title_label:
		title_label.text = "🗺️ MODO COLOCACIÓN"
		title_label.add_theme_color_override("font_color", Color.YELLOW)

func _on_building_placement_cancelled():
	print("Colocación de edificio cancelada.")
	
	var title_label = get_parent().get_node_or_null("StoreTitle")
	if title_label:
		title_label.text = "TIENDA DE EDIFICIOS"
		title_label.add_theme_color_override("font_color", Color.WHITE)

# Funciones auxiliares (mantenidas igual)
func add_building_to_store(building_data: Dictionary):
	available_buildings.append(building_data)
	call_deferred("create_store_items")

func remove_building_from_store(building_name: String):
	for i in range(available_buildings.size() - 1, -1, -1):
		if available_buildings[i].get("name", "") == building_name:
			available_buildings.remove_at(i)
			break
	call_deferred("create_store_items")

func filter_by_category(category: String):
	current_category = category
	create_store_items()

func highlight_building(building_name: String):
	for item in building_items:
		var item_data = item.get_building_data()
		if item_data.get("name", "") == building_name:
			item.highlight_item()
			break

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

func refresh_all_items():
	for item in building_items:
		item.update_button_state()

func get_building_by_name(building_name: String) -> Dictionary:
	for building in available_buildings:
		if building.get("name", "") == building_name:
			return building
	return {}

func clear_active_feedback():
	if active_feedback_panel and is_instance_valid(active_feedback_panel):
		active_feedback_panel.queue_free()
		active_feedback_panel = null
