# BuildingStoreItem.gd - Elemento individual de la tienda de edificios
extends Panel

# Referencias a nodos
@onready var building_name_label: Label = $MarginContainer/HBoxContainer/InfoContainer/BuildingName
@onready var cost_label: Label = $MarginContainer/HBoxContainer/InfoContainer/StatsContainer/CostLabel
@onready var pps_label: Label = $MarginContainer/HBoxContainer/InfoContainer/StatsContainer/PPSLabel
@onready var description_label: Label = $MarginContainer/HBoxContainer/InfoContainer/DescriptionLabel
@onready var purchase_button: Button = $MarginContainer/HBoxContainer/ButtonContainer/PurchaseButton

# Datos del edificio
var building_data: Dictionary = {}

# Señal para cuando se presiona el botón de compra
signal building_purchase_requested(building_data: Dictionary)

func _ready():
	# Conectar señal del botón de compra
	if purchase_button:
		purchase_button.pressed.connect(_on_purchase_button_pressed)
	
	# Conectar a las señales del GameManager
	GameManager.points_changed.connect(_on_points_changed)
	GameManager.building_placement_started.connect(_on_building_placement_started)
	GameManager.building_placement_cancelled.connect(_on_building_placement_cancelled)

# Configurar los datos del edificio
func setup_building_data(data: Dictionary):
	building_data = data
	update_display()
	update_button_state()

func update_display():
	if building_data.is_empty():
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
	
	# Actualizar descripción
	if description_label:
		description_label.text = building_data.get("description", "Sin descripción")

func update_button_state():
	if not purchase_button or building_data.is_empty():
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
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.0, 1.0), 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func show_purchase_feedback(success: bool, message: String = ""):
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
