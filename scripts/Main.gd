# Main.gd - Script de la escena principal - SPRINT 4 ACTUALIZADO
extends Node2D

# Referencias a nodos UI
@onready var points_display: Label = $UI/Pontis/PointsDisplay
@onready var points_per_second_display: Label = $UI/Pontis/PointsPerSecondDisplay
@onready var click_button: Button = $UI/ClickButton
@onready var expand_land_button: Button = $UI/ExpandLandButton
@onready var grid_manager: Node2D = $GridManager
@onready var store_ui: VBoxContainer = $UI/StorePanel/StoreUI
@onready var cancel_placement_button: Button = $UI/CancelPlacementButton

# Variables para la expansión de terreno
var expansion_mode: bool = false
var expansion_indicators: Array[Node2D] = []

# Variables para la colocación de edificios
var building_placement_indicators: Array[Node2D] = []

# Variables para estadísticas (Sprint 4)
var buildings_built: int = 0
var total_spent: int = 0

# Nodos para el HUD mejorado (Sprint 4)
var buildings_count_label: Label
var expanded_view: VBoxContainer
var milestone_popup: Control

func _ready():
	# Crear elementos del HUD mejorado
	create_improved_hud()
	
	# Conectar señales de los botones
	click_button.pressed.connect(_on_click_button_pressed)
	expand_land_button.pressed.connect(_on_expand_land_button_pressed)
	
	# Conectar señales del GameManager (incluyendo las nuevas del Sprint 4)
	GameManager.points_changed.connect(_on_points_changed)
	GameManager.points_per_second_changed.connect(_on_points_per_second_changed)
	GameManager.building_placement_started.connect(_on_building_placement_started)
	GameManager.building_placement_cancelled.connect(_on_building_placement_cancelled)
	GameManager.building_built.connect(_on_building_built)
	GameManager.milestone_reached.connect(_on_milestone_reached)
	
	# Conectar señales del GridManager
	grid_manager.terrain_placed.connect(_on_terrain_placed)
	grid_manager.building_placed.connect(_on_building_placed)
	
	# Conectar el botón de cancelación
	cancel_placement_button.pressed.connect(_on_cancel_placement_pressed)
	cancel_placement_button.visible = false

	# Actualizar UI inicial
	_update_ui()

func create_improved_hud():
	"""Crear elementos adicionales del HUD para el Sprint 4"""
	
	# Crear label para conteo de edificios
	buildings_count_label = Label.new()
	buildings_count_label.text = "🏗️ Edificios: 0"
	buildings_count_label.add_theme_font_size_override("font_size", 14)
	
	# Añadir al panel de puntos
	$UI/Pontis.add_child(buildings_count_label)
	buildings_count_label.position = Vector2(4, 60)
	
	# Crear vista expandida (inicialmente oculta)
	expanded_view = VBoxContainer.new()
	expanded_view.name = "ExpandedView"
	expanded_view.visible = false
	
	# Crear panel para la vista expandida
	var expanded_panel = Panel.new()
	expanded_panel.size = Vector2(200, 300)
	expanded_panel.position = Vector2(530, 10)
	expanded_panel.add_child(expanded_view)
	$UI.add_child(expanded_panel)
	
	# Título para vista expandida
	var expanded_title = Label.new()
	expanded_title.text = "📊 ESTADÍSTICAS"
	expanded_title.add_theme_font_size_override("font_size", 14)
	expanded_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	expanded_view.add_child(expanded_title)
	
	# Separador
	expanded_view.add_child(HSeparator.new())
	
	# Botón para mostrar/ocultar vista expandida
	var toggle_stats_button = Button.new()
	toggle_stats_button.text = "📊"
	toggle_stats_button.custom_minimum_size = Vector2(40, 40)
	toggle_stats_button.position = Vector2(530, 320)
	toggle_stats_button.pressed.connect(_on_toggle_stats_pressed)
	$UI.add_child(toggle_stats_button)

func _process(delta):
	_update_ui()

func _update_ui():
	# Actualizar display de puntos con formato mejorado
	points_display.text = "💰 Puntos: " + format_number(GameManager.player_points)
	
	# Actualizar display de puntos por segundo con formato mejorado
	var pps_text = "⚡ PPS: " + str("%.1f" % GameManager.total_points_per_second)
	if GameManager.total_points_per_second > 0:
		pps_text += " (+%d/seg)" % int(ceil(GameManager.total_points_per_second))
	points_per_second_display.text = pps_text
	
	# Actualizar conteo de edificios
	if buildings_count_label:
		buildings_count_label.text = "🏗️ Edificios: " + str(GameManager.total_buildings_built)
	
	# Actualizar el botón de expandir terreno
	if not expansion_mode:
		expand_land_button.text = "🌱 Expandir Terreno (" + str(grid_manager.land_cost) + ")"
		expand_land_button.disabled = not GameManager.can_afford(grid_manager.land_cost)
	
	# Actualizar vista expandida si está visible
	update_expanded_view()

func update_expanded_view():
	"""Actualizar la vista expandida con estadísticas detalladas"""
	if not expanded_view or not expanded_view.visible:
		return
	
	# Limpiar contenido anterior (excepto título y separador)
	var children = expanded_view.get_children()
	for i in range(children.size() - 1, 1, -1):  # Mantener título y separador
		children[i].queue_free()
	
	var stats = GameManager.get_game_stats()
	
	# Tiempo de juego - CORREGIDO
	var play_time = max(0, stats.play_time_seconds)  # Asegurar que no sea negativo
	var minutes = int(play_time / 60)
	var seconds = int(play_time % 60)
	var time_label = Label.new()
	time_label.text = "⏱️ Tiempo: %dm %ds" % [minutes, seconds]
	time_label.add_theme_font_size_override("font_size", 12)
	expanded_view.add_child(time_label)
	
	# Puntos totales ganados
	var earned_label = Label.new()
	earned_label.text = "📈 Ganados: " + format_number(stats.total_points_earned)
	earned_label.add_theme_font_size_override("font_size", 12)
	expanded_view.add_child(earned_label)
	
	# Puntos gastados
	var spent_label = Label.new()
	spent_label.text = "💸 Gastados: " + format_number(stats.total_points_spent)
	spent_label.add_theme_font_size_override("font_size", 12)
	expanded_view.add_child(spent_label)
	
	# Separador
	expanded_view.add_child(HSeparator.new())
	
	# Edificios por tipo
	var buildings_title = Label.new()
	buildings_title.text = "🏢 Por Tipo:"
	buildings_title.add_theme_font_size_override("font_size", 12)
	buildings_title.add_theme_color_override("font_color", Color.GOLD)
	expanded_view.add_child(buildings_title)
	
	for building_type in stats.buildings_by_type:
		var count = stats.buildings_by_type[building_type]
		var building_label = Label.new()
		building_label.text = "  %s: %d" % [building_type, count]
		building_label.add_theme_font_size_override("font_size", 11)
		expanded_view.add_child(building_label)
	
	# Hitos
	var milestones_label = Label.new()
	milestones_label.text = "🏆 Hitos: " + str(stats.milestones_achieved)
	milestones_label.add_theme_font_size_override("font_size", 12)
	milestones_label.add_theme_color_override("font_color", Color.GOLD)
	expanded_view.add_child(milestones_label)

func _on_toggle_stats_pressed():
	"""Alternar visibilidad de la vista expandida"""
	if expanded_view:
		expanded_view.get_parent().visible = !expanded_view.get_parent().visible

# Función para formatear números grandes
func format_number(number: int) -> String:
	if number >= 1000000:
		return str("%.1f" % (number / 1000000.0)) + "M"
	elif number >= 1000:
		return str("%.1f" % (number / 1000.0)) + "K"
	else:
		return str(number)

func _on_click_button_pressed():
	GameManager.add_points(1)
	create_click_effect()

func create_click_effect():
	var effect_label = Label.new()
	effect_label.text = "+1"
	effect_label.add_theme_font_size_override("font_size", 24)
	effect_label.add_theme_color_override("font_color", Color.GOLD)
	effect_label.position = click_button.global_position + Vector2(randf_range(-30, 30), -20)
	
	get_tree().current_scene.add_child(effect_label)
	
	var tween = create_tween()
	tween.parallel().tween_property(effect_label, "position:y", effect_label.position.y - 50, 1.0)
	tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(effect_label.queue_free)

# Función para mostrar hitos alcanzados
func _on_milestone_reached(milestone_name: String, description: String):
	print("🏆 Hito alcanzado: ", milestone_name, " - ", description)
	create_milestone_popup(description)

func create_milestone_popup(message: String):
	"""Crear popup para mostrar hitos alcanzados"""
	var popup = Panel.new()
	popup.size = Vector2(350, 120)
	popup.position = Vector2(
		(get_viewport().size.x - popup.size.x) / 2,
		100
	)
	
	# Estilo del popup
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style_box.border_color = Color.GOLD
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	popup.add_theme_stylebox_override("panel", style_box)
	
	# Contenedor para el texto
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.add_theme_constant_override("separation", 10)
	
	# Título
	var title = Label.new()
	title.text = "🏆 ¡HITO ALCANZADO!"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Descripción
	var desc = Label.new()
	desc.text = message
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color.WHITE)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	vbox.add_child(title)
	vbox.add_child(desc)
	popup.add_child(vbox)
	
	get_tree().current_scene.add_child(popup)
	
	# Animación de entrada
	popup.modulate.a = 0.0
	popup.scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	tween.parallel().tween_property(popup, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(popup, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_interval(3.0)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(popup, "scale", Vector2(0.8, 0.8), 0.5)
	tween.tween_callback(popup.queue_free)

func _on_building_built(building_name: String):
	"""Callback cuando se construye un edificio"""
	print("🏗️ Edificio construido: ", building_name)
	buildings_built += 1
	
	# Verificar si se completó el juego
	if GameManager.check_game_completion():
		show_game_completion()

func show_game_completion():
	"""Mostrar pantalla de finalización del juego"""
	var completion_panel = Panel.new()
	completion_panel.anchors_preset = Control.PRESET_CENTER
	completion_panel.size = Vector2(500, 300)
	completion_panel.position = Vector2(
		(get_viewport().size.x - completion_panel.size.x) / 2,
		(get_viewport().size.y - completion_panel.size.y) / 2
	)
	
	# Estilo del panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.05, 0.05, 0.05, 0.98)
	style_box.border_color = Color.GOLD
	style_box.border_width_left = 5
	style_box.border_width_right = 5
	style_box.border_width_top = 5
	style_box.border_width_bottom = 5
	style_box.corner_radius_top_left = 15
	style_box.corner_radius_top_right = 15
	style_box.corner_radius_bottom_left = 15
	style_box.corner_radius_bottom_right = 15
	completion_panel.add_theme_stylebox_override("panel", style_box)
	
	# Contenido
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.add_theme_constant_override("separation", 20)
	
	var title = Label.new()
	title.text = "🎉 ¡FELICIDADES! 🎉"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var subtitle = Label.new()
	subtitle.text = "¡Has construido todos los tipos de edificios!"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color.WHITE)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Estadísticas finales
	var stats = GameManager.get_game_stats()
	var stats_text = """Tu ciudad final:
	🏗️ %d edificios construidos
	💰 %s puntos ganados
	⚡ %.1f puntos por segundo
	🏆 %d hitos alcanzados""" % [
		stats.total_buildings_built,
		format_number(stats.total_points_earned),
		stats.total_points_per_second,
		stats.milestones_achieved
	]
	
	var stats_label = Label.new()
	stats_label.text = stats_text
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var continue_label = Label.new()
	continue_label.text = "¡Puedes seguir jugando y expandiendo tu ciudad!"
	continue_label.add_theme_font_size_override("font_size", 14)
	continue_label.add_theme_color_override("font_color", Color.GREEN)
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	vbox.add_child(title)
	vbox.add_child(subtitle)
	vbox.add_child(stats_label)
	vbox.add_child(continue_label)
	completion_panel.add_child(vbox)
	
	get_tree().current_scene.add_child(completion_panel)
	
	# Animación de entrada
	completion_panel.modulate.a = 0.0
	completion_panel.scale = Vector2(0.3, 0.3)
	
	var tween = create_tween()
	tween.parallel().tween_property(completion_panel, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(completion_panel, "scale", Vector2(1.0, 1.0), 0.5)
	tween.tween_interval(8.0)
	tween.parallel().tween_property(completion_panel, "modulate:a", 0.0, 1.0)
	tween.tween_callback(completion_panel.queue_free)

# Resto de funciones existentes (mantenidas del código original)...
func _on_expand_land_button_pressed():
	expansion_mode = !expansion_mode
	if expansion_mode:
		expand_land_button.text = "❌ Cancelar Expansión"
		expand_land_button.modulate = Color.RED
		expand_land_button.disabled = false
		show_expansion_indicators()
		print("🌱 Modo expansión activado.")
		create_instruction_popup("Selecciona una casilla verde para expandir tu terreno", Color.GREEN)
	else:
		expand_land_button.text = "🌱 Expandir Terreno (" + str(grid_manager.land_cost) + ")"
		expand_land_button.modulate = Color.WHITE
		hide_expansion_indicators()
		print("❌ Modo expansión desactivado.")

func create_instruction_popup(message: String, color: Color):
	var popup_label = Label.new()
	popup_label.text = message
	popup_label.add_theme_font_size_override("font_size", 18)
	popup_label.add_theme_color_override("font_color", color)
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_label.position = Vector2(get_viewport().size.x / 2 - 200, 100)
	popup_label.size = Vector2(400, 50)
	
	get_tree().current_scene.add_child(popup_label)
	
	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(popup_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(popup_label.queue_free)

func show_expansion_indicators():
	hide_expansion_indicators()
	var valid_positions = get_valid_expansion_positions()
	for pos in valid_positions:
		var indicator = create_expansion_indicator(pos)
		grid_manager.add_child(indicator)
		expansion_indicators.append(indicator)
	print("📍 ", valid_positions.size(), " posiciones disponibles para expansión")

func hide_expansion_indicators():
	for indicator in expansion_indicators:
		if is_instance_valid(indicator):
			indicator.queue_free()
	expansion_indicators.clear()

func show_building_placement_indicators():
	hide_building_placement_indicators()
	var valid_positions = get_valid_building_positions()
	for pos in valid_positions:
		var indicator = create_building_placement_indicator(pos)
		grid_manager.add_child(indicator)
		building_placement_indicators.append(indicator)
	print("🏗️ ", valid_positions.size(), " posiciones disponibles para construcción")

func hide_building_placement_indicators():
	for indicator in building_placement_indicators:
		if is_instance_valid(indicator):
			indicator.queue_free()
	building_placement_indicators.clear()

func get_valid_building_positions() -> Array:
	var valid_positions = []
	for cell_key in grid_manager.grid_cells:
		var coords = cell_key.split(",")
		var x = int(coords[0])
		var y = int(coords[1])
		var terrain = grid_manager.grid_cells[cell_key]
		if not terrain.has_building:
			valid_positions.append(Vector2i(x, y))
	return valid_positions

func get_valid_expansion_positions() -> Array:
	var valid_positions = []
	for cell_key in grid_manager.grid_cells:
		var coords = cell_key.split(",")
		var x = int(coords[0])
		var y = int(coords[1])
		var adjacent = [
			Vector2i(x + 1, y), Vector2i(x - 1, y),
			Vector2i(x, y + 1), Vector2i(x, y - 1)
		]
		for adj_pos in adjacent:
			if grid_manager.can_expand(adj_pos.x, adj_pos.y):
				if not valid_positions.has(adj_pos):
					valid_positions.append(adj_pos)
	return valid_positions

func create_expansion_indicator(pos: Vector2i) -> Node2D:
	var indicator = Node2D.new()
	var sprite = Sprite2D.new()
	var button = Button.new()
	
	var texture = ImageTexture.new()
	var image = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	image.fill(Color.GREEN)
	texture.set_image(image)
	sprite.texture = texture
	sprite.modulate = Color(0, 1, 0, 0.6)
	
	button.size = Vector2(80, 80)
	button.position = Vector2(-40, -40)
	button.flat = true
	button.modulate = Color.TRANSPARENT
	
	indicator.add_child(sprite)
	indicator.add_child(button)
	indicator.position = grid_manager.grid_to_world(pos)
	
	button.pressed.connect(_on_expansion_position_selected.bind(pos.x, pos.y))
	
	var tween = indicator.create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "modulate:a", 0.3, 0.7)
	tween.tween_property(sprite, "modulate:a", 0.8, 0.7)
	
	return indicator

func create_building_placement_indicator(pos: Vector2i) -> Node2D:
	var indicator = Node2D.new()
	var sprite = Sprite2D.new()
	var button = Button.new()
	
	var texture = ImageTexture.new()
	var image = Image.create(110, 110, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLUE)
	texture.set_image(image)
	sprite.texture = texture
	sprite.modulate = Color(0, 0.5, 1, 0.4)
	
	button.size = Vector2(110, 110)
	button.position = Vector2(-55, -55)
	button.flat = true
	button.modulate = Color.TRANSPARENT
	
	indicator.add_child(sprite)
	indicator.add_child(button)
	indicator.position = grid_manager.grid_to_world(pos)
	
	button.pressed.connect(_on_building_position_selected.bind(pos.x, pos.y))
	
	var tween = indicator.create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "modulate:a", 0.2, 0.5)
	tween.tween_property(sprite, "modulate:a", 0.6, 0.5)
	
	return indicator

func _on_expansion_position_selected(x: int, y: int):
	print("🌱 Posición seleccionada para expansión: (", x, ", ", y, ")")
	if grid_manager.buy_and_place_terrain(x, y):
		total_spent += grid_manager.land_cost
		create_success_effect(Vector2(x * grid_manager.cell_size, y * grid_manager.cell_size), "¡Terreno comprado!")
		expansion_mode = false
		expand_land_button.text = "🌱 Expandir Terreno (" + str(grid_manager.land_cost) + ")"
		expand_land_button.modulate = Color.WHITE
		hide_expansion_indicators()
	else:
		create_error_effect(Vector2(x * grid_manager.cell_size, y * grid_manager.cell_size), "¡No se pudo comprar!")

func _on_building_position_selected(x: int, y: int):
	print("🏗️ Posición seleccionada para edificio: (", x, ", ", y, ")")
	if grid_manager.place_building(x, y, GameManager.building_to_place):
		buildings_built += 1
		create_success_effect(Vector2(x * grid_manager.cell_size, y * grid_manager.cell_size), "¡Edificio construido!")
		GameManager.cancel_placing_mode()
	else:
		create_error_effect(Vector2(x * grid_manager.cell_size, y * grid_manager.cell_size), "¡No se pudo construir!")

func create_success_effect(world_pos: Vector2, message: String):
	var effect_label = Label.new()
	effect_label.text = message
	effect_label.add_theme_font_size_override("font_size", 16)
	effect_label.add_theme_color_override("font_color", Color.GREEN)
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.position = world_pos + Vector2(-50, -80)
	effect_label.size = Vector2(100, 30)
	
	get_tree().current_scene.add_child(effect_label)
	
	var tween = create_tween()
	tween.parallel().tween_property(effect_label, "position:y", effect_label.position.y - 30, 1.5)
	tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(effect_label.queue_free)

func create_error_effect(world_pos: Vector2, message: String):
	var effect_label = Label.new()
	effect_label.text = message
	effect_label.add_theme_font_size_override("font_size", 16)
	effect_label.add_theme_color_override("font_color", Color.RED)
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.position = world_pos + Vector2(-50, -80)
	effect_label.size = Vector2(100, 30)
	
	get_tree().current_scene.add_child(effect_label)
	
	var tween = create_tween()
	for i in range(5):
		tween.tween_property(effect_label, "position:x", effect_label.position.x + 5, 0.1)
		tween.tween_property(effect_label, "position:x", effect_label.position.x - 5, 0.1)
	tween.tween_property(effect_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(effect_label.queue_free)

func _on_terrain_placed(x: int, y: int):
	print("🌱 ¡Nuevo terreno colocado en (", x, ", ", y, ")!")
	if expansion_mode:
		show_expansion_indicators()

func _on_building_placed(x: int, y: int):
	print("🏗️ ¡Edificio colocado en (", x, ", ", y, ")!")
	GameManager.recalculate_total_points_per_second()

func _on_points_changed(new_points: int):
	pass  # La UI se actualiza en _process

func _on_points_per_second_changed(new_pps: float):
	print("⚡ Puntos por segundo actualizados: ", new_pps)

func _on_building_placement_started(building_scene: String):
	print("🏗️ Modo colocación iniciado para: ", building_scene)
	show_building_placement_indicators()
	create_instruction_popup("Selecciona un terreno azul para construir tu edificio", Color.CYAN)
	cancel_placement_button.visible = true
	cancel_placement_button.text = "🚫 Cancelar Construcción"

func _on_building_placement_cancelled():
	print("❌ Colocación de edificio cancelada.")
	hide_building_placement_indicators()
	cancel_placement_button.visible = false

func _on_cancel_placement_pressed():
	print("🚫 Cancelando colocación por botón")
	GameManager.cancel_placing_mode()

func get_game_stats() -> Dictionary:
	var grid_stats = grid_manager.get_grid_stats()
	return {
		"points": GameManager.player_points,
		"pps": GameManager.total_points_per_second,
		"buildings_built": buildings_built,
		"total_spent": total_spent,
		"terrain_count": grid_stats.total_cells,
		"building_count": grid_stats.total_buildings
	}
