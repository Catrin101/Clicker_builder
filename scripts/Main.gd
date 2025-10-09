# Main.gd - Script de la escena principal - CORRECCIONES APLICADAS
extends Node2D

# Referencias a nodos UI
@onready var points_display: Label = $UI/StatsPanel/MarginContainer/StatsContainer/QuickStatsContainer/PointsDisplay
@onready var points_per_second_display: Label = $UI/StatsPanel/MarginContainer/StatsContainer/QuickStatsContainer/PointsPerSecondDisplay
@onready var click_button: Button = $UI/ClickButton
@onready var expand_land_button: Button = $UI/ExpandLandButton
@onready var grid_manager: Node2D = $GridManager
@onready var store_ui: VBoxContainer = $UI/StorePanel/StoreUI
@onready var cancel_placement_button: Button = $UI/CancelPlacementButton
@onready var music_player: AudioStreamPlayer = $MusicPlayer
# Referencia al menú de pausa
@onready var pause_menu: Control = $UI/PauseMenu
@onready var pause_button: Button = $UI/PauseButton

# Referencias para InstructionPopup
@export var instruction_popup_scene: PackedScene = preload("res://escenas/InstructionPopup.tscn")
@onready var ui_layer: CanvasLayer = $UI
# Variables para la expansión de terreno
var expansion_mode: bool = false
var expansion_indicators: Array[Node2D] = []

# Variables para la colocación de edificios
var building_placement_indicators: Array[Node2D] = []

# Timer para puntos automáticos
var points_timer: Timer

# Variables para estadísticas
var buildings_built: int = 0
var total_spent: int = 0

func _ready():
	# Crear y configurar el timer para puntos automáticos
	points_timer = Timer.new()
	points_timer.wait_time = 1.0
	points_timer.timeout.connect(_on_points_timer_timeout)
	add_child(points_timer)
	points_timer.start()
	
	# Conectar señales de los botones
	click_button.pressed.connect(_on_click_button_pressed)
	expand_land_button.pressed.connect(_on_expand_land_button_pressed)
	
	# Conectar señales del GameManager
	GameManager.points_changed.connect(_on_points_changed)
	GameManager.points_per_second_changed.connect(_on_points_per_second_changed)
	GameManager.building_placement_started.connect(_on_building_placement_started)
	GameManager.building_placement_cancelled.connect(_on_building_placement_cancelled)
	
	# Conectar señales del GridManager
	grid_manager.terrain_placed.connect(_on_terrain_placed)
	grid_manager.building_placed.connect(_on_building_placed)
	
	# Conectar el botón de cancelación
	cancel_placement_button.pressed.connect(_on_cancel_placement_pressed)
	cancel_placement_button.visible = false  # Inicialmente oculto
	
	# Conectar botón de pausa
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)
	# Actualizar UI inicial
	
	_update_ui()
	
	# Asegurar que la música haga loop
	if music_player and music_player.stream:
		if music_player.stream is AudioStreamOggVorbis:
			music_player.stream.loop = true
		elif music_player.stream is AudioStreamWAV:
			music_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			
	# Verificar que el PauseMenu existe
	if pause_menu:
		print("PauseMenu encontrado y listo")
	else:
		printerr("ERROR: No se encontró PauseMenu en UI")

func _unhandled_input(event):
	# Detectar ESC para pausar
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()

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
	
	# Actualizar el botón de expandir terreno
	if not expansion_mode:
		expand_land_button.text = "🌱 Expandir Terreno (" + str(grid_manager.land_cost) + ")"
		expand_land_button.disabled = not GameManager.can_afford(grid_manager.land_cost)
	
	# Actualizar botón de clic
	click_button.text = "🖱️ Clic (+1)"

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
	
	# Efecto visual mejorado para el clic
	create_click_effect()

# CORRECCIÓN: Función create_click_effect arreglada
func create_click_effect():
	# Crear efecto visual temporal del clic
	var effect_label = Label.new()
	effect_label.text = "+1"
	effect_label.add_theme_font_size_override("font_size", 24)
	effect_label.add_theme_color_override("font_color", Color.GOLD)  # CORRECCIÓN: Quitado el .effect_label duplicado
	effect_label.position = click_button.global_position + Vector2(randf_range(-30, 30), -20)
	
	get_tree().current_scene.add_child(effect_label)
	
	# CORRECCIÓN: Usar tween_delay correctamente
	var tween = create_tween()
	tween.parallel().tween_property(effect_label, "position:y", effect_label.position.y - 50, 1.0)
	tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(effect_label.queue_free)

func _on_expand_land_button_pressed():
	expansion_mode = !expansion_mode
	if expansion_mode:
		expand_land_button.text = "❌ Cancelar Expansión"
		expand_land_button.modulate = Color.RED
		expand_land_button.disabled = false
		show_expansion_indicators()
		print("🌱 Modo expansión activado. Haz clic en una casilla verde para comprar terreno.")
		create_instruction_popup("Selecciona una casilla verde para expandir tu terreno", Color.GREEN)
	else:
		expand_land_button.text = "🌱 Expandir Terreno (" + str(grid_manager.land_cost) + ")"
		expand_land_button.modulate = Color.WHITE
		hide_expansion_indicators()
		print("❌ Modo expansión desactivado.")

func create_instruction_popup(message: String, color: Color):
	var popup = instruction_popup_scene.instantiate()
	
	# Configurar posición centrada
	popup.anchor_left = 0.5
	popup.anchor_right = 0.5
	popup.anchor_top = 0.0
	popup.anchor_bottom = 0.0
	popup.offset_left = -200
	popup.offset_right = 200
	popup.offset_top = 100
	popup.offset_bottom = 150
	popup.grow_horizontal = Control.GROW_DIRECTION_BOTH
	
	ui_layer.add_child(popup)
	popup.setup(message, color, 3.0)

func show_expansion_indicators():
	hide_expansion_indicators()  # Limpiar indicadores anteriores
	
	# Encontrar todas las posiciones válidas para expansión
	var valid_positions = get_valid_expansion_positions()
	
	# Crear indicadores visuales mejorados
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
	hide_building_placement_indicators()  # Limpiar indicadores anteriores
	
	# Encontrar todas las posiciones válidas para colocar edificios
	var valid_positions = get_valid_building_positions()
	
	# Crear indicadores visuales mejorados
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
		
		# Solo añadir si el terreno no tiene edificio
		if not terrain.has_building:
			valid_positions.append(Vector2i(x, y))
	
	return valid_positions

func get_valid_expansion_positions() -> Array:
	var valid_positions = []
	
	# Revisar todas las casillas existentes
	for cell_key in grid_manager.grid_cells:
		var coords = cell_key.split(",")
		var x = int(coords[0])
		var y = int(coords[1])
		
		# Revisar las 4 posiciones adyacentes
		var adjacent = [
			Vector2i(x + 1, y),
			Vector2i(x - 1, y),
			Vector2i(x, y + 1),
			Vector2i(x, y - 1)
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
	
	# Configurar sprite con mejor apariencia
	var texture = ImageTexture.new()
	var image = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	image.fill(Color.GREEN)
	texture.set_image(image)
	sprite.texture = texture
	sprite.modulate = Color(0, 1, 0, 0.6)  # Verde semi-transparente
	
	# Añadir borde
	var border_sprite = Sprite2D.new()
	var border_texture = ImageTexture.new()
	var border_image = Image.create(84, 84, false, Image.FORMAT_RGBA8)
	border_image.fill(Color.DARK_GREEN)
	border_texture.set_image(border_image)
	border_sprite.texture = border_texture
	border_sprite.modulate = Color(0, 0.7, 0, 0.8)
	border_sprite.z_index = -1
	
	# Configurar botón invisible
	button.size = Vector2(80, 80)
	button.position = Vector2(-40, -40)
	button.flat = true
	button.modulate = Color.TRANSPARENT
	
	# Ensamblar nodos
	indicator.add_child(border_sprite)
	indicator.add_child(sprite)
	indicator.add_child(button)
	
	# Posicionar
	indicator.position = grid_manager.grid_to_world(pos)
	
	# Conectar el botón directamente
	button.pressed.connect(_on_expansion_position_selected.bind(pos.x, pos.y))
	
	# Animación de pulso mejorada
	var tween = indicator.create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "modulate:a", 0.3, 0.7)
	tween.tween_property(sprite, "modulate:a", 0.8, 0.7)
	
	return indicator

func create_building_placement_indicator(pos: Vector2i) -> Node2D:
	var indicator = Node2D.new()
	var sprite = Sprite2D.new()
	var button = Button.new()
	
	# Configurar sprite con mejor apariencia
	var texture = ImageTexture.new()
	var image = Image.create(110, 110, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLUE)
	texture.set_image(image)
	sprite.texture = texture
	sprite.modulate = Color(0, 0.5, 1, 0.4)  # Azul semi-transparente
	
	# Añadir borde
	var border_sprite = Sprite2D.new()
	var border_texture = ImageTexture.new()
	var border_image = Image.create(114, 114, false, Image.FORMAT_RGBA8)
	border_image.fill(Color.NAVY_BLUE)
	border_texture.set_image(border_image)
	border_sprite.texture = border_texture
	border_sprite.modulate = Color(0, 0.3, 0.8, 0.6)
	border_sprite.z_index = -1
	
	# Configurar botón invisible
	button.size = Vector2(110, 110)
	button.position = Vector2(-55, -55)
	button.flat = true
	button.modulate = Color.TRANSPARENT
	
	# Ensamblar nodos
	indicator.add_child(border_sprite)
	indicator.add_child(sprite)
	indicator.add_child(button)
	
	# Posicionar
	indicator.position = grid_manager.grid_to_world(pos)
	
	# Conectar el botón directamente
	button.pressed.connect(_on_building_position_selected.bind(pos.x, pos.y))
	
	# Animación de pulso mejorada
	var tween = indicator.create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "modulate:a", 0.2, 0.5)
	tween.tween_property(sprite, "modulate:a", 0.6, 0.5)
	
	return indicator

func _on_expansion_position_selected(x: int, y: int):
	print("🌱 Posición seleccionada para expansión: (", x, ", ", y, ")")
	
	# Guardar el costo actual antes de comprar (porque el costo aumenta después)
	var current_land_cost = grid_manager.land_cost
	
	# Intentar comprar terreno
	if grid_manager.buy_and_place_terrain(x, y):
		total_spent += current_land_cost
		create_success_effect(Vector2(x * grid_manager.cell_size, y * grid_manager.cell_size), "¡Terreno comprado!")
		
		# Salir del modo expansión después de una compra exitosa
		expansion_mode = false
		expand_land_button.text = "🌱 Expandir Terreno (" + str(grid_manager.land_cost) + ")"
		expand_land_button.modulate = Color.WHITE
		hide_expansion_indicators()
	else:
		create_error_effect(Vector2(x * grid_manager.cell_size, y * grid_manager.cell_size), "¡No se pudo comprar!")

func _on_building_position_selected(x: int, y: int):
	print("🏗️ Posición seleccionada para edificio: (", x, ", ", y, ")")
	
	# Intentar colocar el edificio
	if grid_manager.place_building(x, y, GameManager.building_to_place):
		buildings_built += 1
		create_success_effect(Vector2(x * grid_manager.cell_size, y * grid_manager.cell_size), "¡Edificio construido!")
		
		# Salir del modo colocación
		GameManager.cancel_placing_mode()
		
		# Mostrar estadísticas
		print("📊 Estadísticas: ", buildings_built, " edificios construidos, ", total_spent, " puntos gastados")
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
	
	# Animar el efecto
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
	
	# Efecto de sacudida
	var tween = create_tween()
	for i in range(5):
		tween.tween_property(effect_label, "position:x", effect_label.position.x + 5, 0.1)
		tween.tween_property(effect_label, "position:x", effect_label.position.x - 5, 0.1)
	tween.tween_property(effect_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(effect_label.queue_free)

func _on_terrain_placed(x: int, y: int):
	print("🌱 ¡Nuevo terreno colocado en (", x, ", ", y, ")!")
	# Si estamos en modo expansión, actualizar los indicadores
	if expansion_mode:
		show_expansion_indicators()

func _on_building_placed(x: int, y: int):
	print("🏗️ ¡Edificio colocado en (", x, ", ", y, ")!")
	
	# Recalcular automáticamente los PPS
	GameManager.recalculate_total_points_per_second()

func _on_points_changed(new_points: int):
	# La UI se actualiza en _process
	pass

func _on_points_per_second_changed(new_pps: float):
	print("⚡ Puntos por segundo actualizados: ", new_pps)

func _on_building_placement_started(building_scene: String):
	print("🏗️ Modo colocación iniciado para: ", building_scene)
	show_building_placement_indicators()
	create_instruction_popup("Selecciona un terreno azul para construir tu edificio", Color.CYAN)
	
	# Mostrar botón de cancelación
	cancel_placement_button.visible = true
	cancel_placement_button.text = "🚫 Cancelar Construcción"

func _on_building_placement_cancelled():
	print("❌ Colocación de edificio cancelada.")
	hide_building_placement_indicators()
	
	# Ocultar botón de cancelación
	cancel_placement_button.visible = false

func _on_cancel_placement_pressed():
	print("🚫 Cancelando colocación por botón")
	GameManager.cancel_placing_mode()

# Timer callback para puntos automáticos
func _on_points_timer_timeout():
	var current_pps = GameManager.total_points_per_second
	if current_pps > 0:
		var points_to_add = int(ceil(current_pps))
		GameManager.add_points(points_to_add)
		
		# Mostrar efecto visual para PPS altos
		if current_pps >= 5.0:
			create_pps_effect()

func create_pps_effect():
	# Efecto visual para puntos automáticos altos
	var effect_label = Label.new()
	var points_added = int(ceil(GameManager.total_points_per_second))
	effect_label.text = "⚡ +" + str(points_added)
	effect_label.add_theme_font_size_override("font_size", 20)
	effect_label.add_theme_color_override("font_color", Color.YELLOW)
	effect_label.position = Vector2(get_viewport().size.x - 150, 50)
	
	get_tree().current_scene.add_child(effect_label)
	
	# Animar el efecto
	var tween = create_tween()
	tween.parallel().tween_property(effect_label, "position:y", effect_label.position.y - 30, 1.0)
	tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(effect_label.queue_free)

# Función para obtener estadísticas del juego
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
	
# ============================================================================
# FUNCIONES DE PAUSA
# ============================================================================

func toggle_pause():
	if not pause_menu:
		printerr("Error: PauseMenu no está disponible")
		return
	
	if pause_menu.visible:
		# Si el menú está visible, reanudar
		pause_menu.resume_game()
	else:
		# Si el menú está oculto, pausar
		pause_menu.pause_game()

func open_pause_menu():
	if pause_menu:
		pause_menu.pause_game()

func close_pause_menu():
	if pause_menu:
		pause_menu.resume_game()

func _on_pause_button_pressed():
	print("Botón de pausa presionado")
	open_pause_menu()
