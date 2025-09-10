# Main.gd - Script de la escena principal (ACTUALIZADO SPRINT 2)
extends Node2D

# Referencias a nodos UI
@onready var points_display: Label = $UI/Pontis/PointsDisplay
@onready var points_per_second_display: Label = $UI/Pontis/PointsPerSecondDisplay
@onready var click_button: Button = $UI/ClickButton
@onready var expand_land_button: Button = $UI/ExpandLandButton
@onready var grid_manager: Node2D = $GridManager
@onready var store_ui: VBoxContainer = $UI/StorePanel/StoreUI

# Variables para la expansión de terreno
var expansion_mode: bool = false
var expansion_indicators: Array[Node2D] = []

# Variables para la colocación de edificios
var building_placement_indicators: Array[Node2D] = []

# Timer para puntos automáticos
var points_timer: Timer

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
	
	# Actualizar UI inicial
	_update_ui()

func _process(delta):
	_update_ui()

func _update_ui():
	# Actualizar display de puntos
	points_display.text = "Puntos: " + str(GameManager.player_points)
	
	# Actualizar display de puntos por segundo
	points_per_second_display.text = "PPS: " + str("%.1f" % GameManager.total_points_per_second)
	
	# Actualizar el botón de expandir terreno
	if not expansion_mode:
		expand_land_button.text = "Expandir Terreno (" + str(grid_manager.land_cost) + ")"
		expand_land_button.disabled = not GameManager.can_afford(grid_manager.land_cost)

func _on_click_button_pressed():
	GameManager.add_points(1)

func _on_expand_land_button_pressed():
	expansion_mode = !expansion_mode
	if expansion_mode:
		expand_land_button.text = "Cancelar Expansión"
		expand_land_button.modulate = Color.RED
		expand_land_button.disabled = false
		show_expansion_indicators()
		print("Modo expansión activado. Haz clic en una casilla verde para comprar terreno.")
	else:
		expand_land_button.text = "Expandir Terreno (" + str(grid_manager.land_cost) + ")"
		expand_land_button.modulate = Color.WHITE
		hide_expansion_indicators()
		print("Modo expansión desactivado.")

func show_expansion_indicators():
	hide_expansion_indicators()  # Limpiar indicadores anteriores
	
	# Encontrar todas las posiciones válidas para expansión
	var valid_positions = get_valid_expansion_positions()
	
	# Crear indicadores visuales
	for pos in valid_positions:
		var indicator = create_expansion_indicator(pos)
		grid_manager.add_child(indicator)
		expansion_indicators.append(indicator)

func hide_expansion_indicators():
	for indicator in expansion_indicators:
		if is_instance_valid(indicator):
			indicator.queue_free()
	expansion_indicators.clear()

# NUEVA FUNCIÓN: Mostrar indicadores de colocación de edificios
func show_building_placement_indicators():
	hide_building_placement_indicators()  # Limpiar indicadores anteriores
	
	# Encontrar todas las posiciones válidas para colocar edificios (terrenos libres)
	var valid_positions = get_valid_building_positions()
	
	# Crear indicadores visuales
	for pos in valid_positions:
		var indicator = create_building_placement_indicator(pos)
		grid_manager.add_child(indicator)
		building_placement_indicators.append(indicator)

func hide_building_placement_indicators():
	for indicator in building_placement_indicators:
		if is_instance_valid(indicator):
			indicator.queue_free()
	building_placement_indicators.clear()

# NUEVA FUNCIÓN: Obtener posiciones válidas para edificios
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
	
	# Configurar sprite
	var texture = ImageTexture.new()
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.GREEN)
	texture.set_image(image)
	sprite.texture = texture
	sprite.modulate = Color(0, 1, 0, 0.5)  # Verde semi-transparente
	
	# Configurar botón invisible
	button.size = Vector2(64, 64)
	button.position = Vector2(-32, -32)  # Centrar el botón
	button.flat = true
	button.modulate = Color.TRANSPARENT
	
	# Ensamblar nodos
	indicator.add_child(sprite)
	indicator.add_child(button)
	
	# Posicionar
	indicator.position = grid_manager.grid_to_world(pos)
	
	# Conectar el botón directamente
	button.pressed.connect(_on_expansion_position_selected.bind(pos.x, pos.y))
	
	# Animación de pulso
	var tween = indicator.create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "modulate:a", 0.3, 0.5)
	tween.tween_property(sprite, "modulate:a", 0.7, 0.5)
	
	return indicator

# NUEVA FUNCIÓN: Crear indicador para colocación de edificios
func create_building_placement_indicator(pos: Vector2i) -> Node2D:
	var indicator = Node2D.new()
	var sprite = Sprite2D.new()
	var button = Button.new()
	
	# Configurar sprite
	var texture = ImageTexture.new()
	var image = Image.create(100, 100, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLUE)
	texture.set_image(image)
	sprite.texture = texture
	sprite.modulate = Color(0, 0, 1, 0.3)  # Azul semi-transparente
	
	# Configurar botón invisible
	button.size = Vector2(100, 100)
	button.position = Vector2(-50, -50)  # Centrar el botón
	button.flat = true
	button.modulate = Color.TRANSPARENT
	
	# Ensamblar nodos
	indicator.add_child(sprite)
	indicator.add_child(button)
	
	# Posicionar
	indicator.position = grid_manager.grid_to_world(pos)
	
	# Conectar el botón directamente
	button.pressed.connect(_on_building_position_selected.bind(pos.x, pos.y))
	
	# Animación de pulso
	var tween = indicator.create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "modulate:a", 0.1, 0.3)
	tween.tween_property(sprite, "modulate:a", 0.5, 0.3)
	
	return indicator

func _on_expansion_position_selected(x: int, y: int):
	print("Posición seleccionada para expansión: (", x, ", ", y, ")")
	
	# Intentar comprar terreno
	if grid_manager.buy_and_place_terrain(x, y):
		# Salir del modo expansión después de una compra exitosa
		expansion_mode = false
		expand_land_button.text = "Expandir Terreno (" + str(grid_manager.land_cost) + ")"
		expand_land_button.modulate = Color.WHITE
		hide_expansion_indicators()

# NUEVA FUNCIÓN: Manejar selección de posición para edificio
func _on_building_position_selected(x: int, y: int):
	print("Posición seleccionada para edificio: (", x, ", ", y, ")")
	
	# Intentar colocar el edificio
	if grid_manager.place_building(x, y, GameManager.building_to_place):
		# Salir del modo colocación
		GameManager.cancel_placing_mode()

func _on_terrain_placed(x: int, y: int):
	print("¡Nuevo terreno colocado en (", x, ", ", y, ")!")
	# Si estamos en modo expansión, actualizar los indicadores
	if expansion_mode:
		show_expansion_indicators()

# NUEVA FUNCIÓN: Manejar cuando se coloca un edificio
func _on_building_placed(x: int, y: int):
	print("¡Edificio colocado en (", x, ", ", y, ")!")

func _on_points_changed(new_points: int):
	# La UI se actualiza en _process
	pass

# NUEVA FUNCIÓN: Actualizar cuando cambian los puntos por segundo
func _on_points_per_second_changed(new_pps: float):
	print("Puntos por segundo actualizados: ", new_pps)

func _on_building_placement_started(_building_scene: String):
	print("Modo colocación iniciado. Haz clic en un terreno azul para colocar el edificio.")
	show_building_placement_indicators()

func _on_building_placement_cancelled():
	print("Colocación de edificio cancelada.")
	hide_building_placement_indicators()

# Timer callback para puntos automáticos
func _on_points_timer_timeout():
	var current_pps = GameManager.total_points_per_second
	if current_pps > 0:
		var points_to_add = int(ceil(current_pps))  # Redondear hacia arriba para valores pequeños
		GameManager.add_points(points_to_add)
		print("Timer: Añadidos ", points_to_add, " puntos automáticos (PPS: ", current_pps, ")")
	else:
		print("Timer: Sin puntos que añadir (PPS: ", current_pps, ")")
