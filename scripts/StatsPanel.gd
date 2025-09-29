# StatsPanel.gd - Panel de UI para mostrar estadísticas
extends Panel

# Referencias a nodos UI
@onready var toggle_button: Button = $MarginContainer/StatsContainer/StatsHeader/ToggleStatsButton
@onready var quick_stats: VBoxContainer = $MarginContainer/StatsContainer/QuickStatsContainer
@onready var detailed_stats: VBoxContainer = $MarginContainer/StatsContainer/DetailedStatsContainer

@onready var total_buildings_label: Label = $MarginContainer/StatsContainer/QuickStatsContainer/TotalBuildingsLabel
@onready var total_pps_label: Label = $MarginContainer/StatsContainer/QuickStatsContainer/TotalPPSLabel
@onready var total_points_label: Label = $MarginContainer/StatsContainer/QuickStatsContainer/TotalPointsLabel

@onready var building_types_list: VBoxContainer = $MarginContainer/StatsContainer/DetailedStatsContainer/BuildingTypesList
@onready var general_stats_list: VBoxContainer = $MarginContainer/StatsContainer/DetailedStatsContainer/GeneralStatsList

# Estado del panel expandido
var is_expanded: bool = false

# Escena para items de edificios individuales
var building_item_scene: PackedScene

func _ready():
	# Conectar señales del botón toggle
	toggle_button.pressed.connect(_on_toggle_button_pressed)
	
	# Conectar señales del StatsManager
	StatsManager.stats_updated.connect(_on_stats_updated)
	StatsManager.building_count_changed.connect(_on_building_count_changed)
	
	# Conectar señales del GameManager para PPS y puntos
	if GameManager.has_signal("points_per_second_changed"):
		GameManager.points_per_second_changed.connect(_on_pps_changed)
	if GameManager.has_signal("points_changed"):
		GameManager.points_changed.connect(_on_points_changed)
	
	# Crear escena para items de edificios dinámicamente
	create_building_item_scene()
	
	# Actualizar UI inicial
	update_quick_stats()
	update_detailed_stats()
	
	print("StatsPanel inicializado")

func create_building_item_scene():
	# Crear una escena simple para items de edificios
	building_item_scene = PackedScene.new()

func _on_toggle_button_pressed():
	is_expanded = !is_expanded
	detailed_stats.visible = is_expanded
	
	# Cambiar ícono del botón
	if is_expanded:
		toggle_button.text = "🔼"
		# Expandir el panel
		custom_minimum_size.y = 400
	else:
		toggle_button.text = "🔽"
		# Contraer el panel
		custom_minimum_size.y = 120
	
	# Actualizar stats cuando se expande
	if is_expanded:
		update_detailed_stats()

func _on_stats_updated():
	update_quick_stats()
	if is_expanded:
		update_detailed_stats()

func _on_building_count_changed(building_type: String, new_count: int):
	update_quick_stats()
	if is_expanded:
		update_building_type_item(building_type, new_count)

func _on_pps_changed(new_pps: float):
	total_pps_label.text = "⚡ PPS Total: %.1f" % new_pps
	StatsManager.update_highest_pps(new_pps)

func _on_points_changed(new_points: int):
	# Este label muestra los puntos totales ganados, no los actuales
	# Los puntos actuales ya se muestran en otro lugar
	pass

func update_quick_stats():
	var total_buildings = StatsManager.get_total_buildings()
	var general_stats = StatsManager.get_general_stats()
	
	total_buildings_label.text = "🏠 Edificios: %d" % total_buildings
	total_pps_label.text = "⚡ PPS Total: %.1f" % GameManager.total_points_per_second
	total_points_label.text = "💰 Puntos Ganados: %d" % general_stats.total_points_earned

func update_detailed_stats():
	update_building_types_list()
	update_general_stats_list()

func update_building_types_list():
	# Limpiar lista actual
	for child in building_types_list.get_children():
		child.queue_free()
	
	# Obtener todos los tipos de edificios ordenados
	var building_counts = StatsManager.get_all_building_counts()
	var sorted_types = building_counts.keys()
	sorted_types.sort()
	
	# Crear item para cada tipo
	for building_type in sorted_types:
		var count = building_counts[building_type]
		create_building_type_item(building_type, count)
	
	# Si no hay edificios, mostrar mensaje
	if sorted_types.is_empty():
		var empty_label = Label.new()
		empty_label.text = "  (No hay edificios aún)"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_label.add_theme_font_size_override("font_size", 12)
		building_types_list.add_child(empty_label)

func create_building_type_item(building_type: String, count: int):
	var item = HBoxContainer.new()
	
	# Label del nombre del edificio
	var name_label = Label.new()
	name_label.text = "  • " + format_building_name(building_type) + ":"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 12)
	
	# Label del conteo
	var count_label = Label.new()
	count_label.text = str(count)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.add_theme_color_override("font_color", Color(0, 1, 0.5))
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.custom_minimum_size.x = 40
	
	item.add_child(name_label)
	item.add_child(count_label)
	building_types_list.add_child(item)

func update_building_type_item(building_type: String, new_count: int):
	# Actualizar item existente o crear uno nuevo
	update_building_types_list()

func update_general_stats_list():
	# Limpiar lista actual
	for child in general_stats_list.get_children():
		child.queue_free()
	
	var general_stats = StatsManager.get_general_stats()
	
	# Crear labels para cada estadística
	create_stat_label("⏱️ Tiempo de Juego:", general_stats.play_time_formatted)
	create_stat_label("💸 Puntos Gastados:", str(general_stats.total_points_spent))
	create_stat_label("🚀 PPS Máximo:", "%.1f" % general_stats.highest_pps)
	
	# Obtener el edificio más construido
	var most_built = StatsManager.get_most_built_type()
	if most_built.type != "":
		create_stat_label("🏆 Más Construido:", format_building_name(most_built.type) + " (" + str(most_built.count) + ")")

func create_stat_label(label_text: String, value_text: String):
	var item = HBoxContainer.new()
	
	var label = Label.new()
	label.text = "  " + label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 12)
	
	var value = Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_color_override("font_color", Color(1, 1, 0.5))
	value.add_theme_font_size_override("font_size", 12)
	
	item.add_child(label)
	item.add_child(value)
	general_stats_list.add_child(item)

func format_building_name(building_type: String) -> String:
	# Convertir nombres de edificios a formato legible
	# Por ejemplo: "House" -> "Casa del Aldeano"
	var name_map = {
		"House": "Casa del Aldeano",
		"Tavern": "Taberna",
		"Inn": "Posada",
		"Castle": "Castillo",
		"Chapel": "Capilla",
		"Clock": "Torre del Reloj",
		"Villa": "Villa",
		"Thayched": "Cabaña",
		"TreeHouse": "Casa del Árbol",
		"BaseMilitar": "Base Militar"
	}
	
	return name_map.get(building_type, building_type)

# Función pública para refrescar todas las estadísticas
func refresh_all_stats():
	update_quick_stats()
	if is_expanded:
		update_detailed_stats()
