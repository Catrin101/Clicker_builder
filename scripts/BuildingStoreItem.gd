# BuildingStoreItem.gd - Elemento individual de la tienda de edificios - VERSIÓN CON AJUSTE DINÁMICO
extends Panel

# Referencias a nodos
@onready var building_name_label: Label = $MarginContainer/HBoxContainer/InfoContainer/BuildingName
@onready var cost_label: Label = $MarginContainer/HBoxContainer/InfoContainer/StatsContainer/CostLabel
@onready var pps_label: Label = $MarginContainer/HBoxContainer/InfoContainer/StatsContainer/PPSLabel
@onready var description_label: Label = $MarginContainer/HBoxContainer/InfoContainer/DescriptionLabel
@onready var purchase_button: Button = $MarginContainer/HBoxContainer/ButtonContainer/PurchaseButton

# Datos del edificio
var building_data: Dictionary = {}

# Variable para controlar si ya se inicializó
var is_initialized: bool = false

# Señal para cuando se presiona el botón de compra
signal building_purchase_requested(building_data: Dictionary)

func _ready():
	# Configurar size flags para que se ajuste correctamente
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Cambiar a shrink center para ajuste dinámico
	
	# Remover custom_minimum_size fijo para permitir ajuste dinámico
	custom_minimum_size = Vector2(0, 0)
	
	# Conectar señal del botón de compra
	if purchase_button:
		purchase_button.pressed.connect(_on_purchase_button_pressed)
	
	# Conectar a las señales del GameManager
	GameManager.points_changed.connect(_on_points_changed)
	GameManager.building_placement_started.connect(_on_building_placement_started)
	GameManager.building_placement_cancelled.connect(_on_building_placement_cancelled)
	
	# Marcar como inicializado
	is_initialized = true
	
	# Si ya tenemos datos del edificio, actualizar la pantalla
	if not building_data.is_empty():
		update_display()
		update_button_state()
		call_deferred("adjust_panel_size")

# Configurar los datos del edificio
func setup_building_data(data: Dictionary):
	building_data = data
	
	# Si ya estamos listos, actualizar inmediatamente
	if is_initialized:
		update_display()
		update_button_state()
		call_deferred("adjust_panel_size")

func update_display():
	if building_data.is_empty() or not is_initialized:
		return
	
	# Actualizar nombre
	if building_name_label:
		building_name_label.text = building_data.get("name", "Edificio")
	
	# Actualizar costo
	if cost_label:
		cost_label.text = "💰 " + str(building_data.get("cost", 0))
	
	# Actualizar PPS
	if pps_label:
		var pps_value = building_data.get("pps", 0.0)
		pps_label.text = "⚡ +" + str(pps_value) + " PPS"
	
	# Actualizar descripción con ajuste automático
	if description_label:
		var description_text = building_data.get("description", "Sin descripción")
		description_label.text = description_text
		
		# Configurar el label para que se ajuste correctamente
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL

# Nueva función para ajustar el tamaño del panel dinámicamente
func adjust_panel_size():
	if not is_initialized or not description_label:
		return
	
	# Esperar un frame para que el texto se procese
	await get_tree().process_frame
	
	# Calcular la altura necesaria basada en el contenido del description_label
	var font = description_label.get_theme_font("font")
	var font_size = description_label.get_theme_font_size("font_size")
	
	if not font:
		font = ThemeDB.fallback_font
	if font_size <= 0:
		font_size = 12
	
	# Obtener el ancho disponible para el texto
	var available_width = description_label.size.x
	if available_width <= 0:
		available_width = 200  # Valor por defecto
	
	# Calcular las líneas necesarias
	var text_lines = font.get_multiline_string_size(
		description_label.text, 
		HORIZONTAL_ALIGNMENT_LEFT, 
		available_width, 
		font_size
	)
	
	# Calcular altura mínima necesaria
	var base_height = 60  # Altura base para nombre, costo, PPS, botón
	var description_height = max(text_lines.y, 30)  # Mínimo 30px para descripción
	var total_height = base_height + description_height + 20  # +20 para márgenes
	
	# Aplicar altura mínima calculada
	custom_minimum_size.y = max(total_height, 100)  # Mínimo absoluto de 100px
	
	# Forzar actualización del layout
	queue_redraw()

func update_button_state():
	if not purchase_button or building_data.is_empty() or not is_initialized:
		return
	
	var can_afford = GameManager.can_afford(building_data.get("cost", 0))
	var is_placing = GameManager.is_placing_mode
	
	# Deshabilitar si no puede permitirse o está en modo de colocación
	purchase_button.disabled = not can_afford or is_placing
	
	# Cambiar texto y color según el estado
	if is_placing:
		purchase_button.text = "COLOCANDO..."
		purchase_button.modulate = Color(0.7, 0.7, 0.7, 1.0)
	elif can_afford:
		purchase_button.text = "COMPRAR"
		purchase_button.modulate = Color.WHITE
	else:
		purchase_button.text = "SIN FONDOS"
		purchase_button.modulate = Color(0.6, 0.6, 0.6, 1.0)
	
	# Cambiar el estilo del panel también
	if can_afford and not is_placing:
		modulate = Color.WHITE
	else:
		modulate = Color(0.8, 0.8, 0.8, 1.0)

func _on_purchase_button_pressed():
	print("Botón de compra presionado para: ", building_data.get("name", "Desconocido"))
	building_purchase_requested.emit(building_data)

func _on_points_changed(new_points: int):
	update_button_state()

func _on_building_placement_started(building_scene: String):
	update_button_state()

func _on_building_placement_cancelled():
	update_button_state()

# Funciones para efectos visuales
func highlight_item():
	if not is_initialized:
		return
		
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.0, 1.0), 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func show_purchase_feedback(success: bool, message: String = ""):
	if not is_initialized or not purchase_button:
		return
		
	var color = Color.GREEN if success else Color.RED
	var feedback_text = message if not message.is_empty() else ("✅ Comprado!" if success else "❌ Error!")
	
	# Crear label temporal para feedback
	var feedback_label = Label.new()
	feedback_label.text = feedback_text
	feedback_label.add_theme_color_override("font_color", color)
	feedback_label.add_theme_font_size_override("font_size", 12)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.position = purchase_button.position + Vector2(0, -30)
	feedback_label.size = purchase_button.size
	
	add_child(feedback_label)
	
	# Animar feedback
	var tween = create_tween()
	tween.parallel().tween_property(feedback_label, "position:y", feedback_label.position.y - 20, 1.5)
	tween.parallel().tween_property(feedback_label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(feedback_label.queue_free)

# Función para obtener los datos del edificio
func get_building_data() -> Dictionary:
	return building_data

# Función para verificar si puede comprarse
func can_purchase() -> bool:
	return GameManager.can_afford(building_data.get("cost", 0)) and not GameManager.is_placing_mode

# Función que se llama cuando el tamaño del panel cambia
func _on_resized():
	if is_initialized:
		call_deferred("adjust_panel_size")
