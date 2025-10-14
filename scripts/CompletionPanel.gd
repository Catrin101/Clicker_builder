# CompletionPanel.gd - Panel de felicitación con dos columnas
extends ColorRect

# Referencias a nodos - RUTAS CORREGIDAS según main.tscn
@onready var completion_panel: Panel = $CompletionPanel
@onready var completion_margin: HBoxContainer = $CompletionPanel/CompletionMargin

# Panel izquierdo
@onready var left_panel: Panel = $CompletionPanel/CompletionMargin/LeftPanel
@onready var completion_message: RichTextLabel = $CompletionPanel/CompletionMargin/LeftPanel/LeftMargin/CompletionContainer/CompletionMessage
@onready var continue_button: Button = $CompletionPanel/CompletionMargin/LeftPanel/LeftMargin/CompletionContainer/CompletionButtonsContainer/ContinuePlayingButton
@onready var close_button: Button = $CompletionPanel/CompletionMargin/LeftPanel/LeftMargin/CompletionContainer/CompletionButtonsContainer/CloseCompletionButton

# Panel derecho
@onready var right_panel: Panel = $CompletionPanel/CompletionMargin/RightPanel
@onready var completion_stats_list: VBoxContainer = $CompletionPanel/CompletionMargin/RightPanel/RightMargin/StatsScrollContainer/StatsContent/CompletionStatsList

# Variables de animación
var is_animating: bool = false

func _ready():
	# Inicialmente oculto
	visible = false
	
	# Verificar que los nodos existen
	if not continue_button or not close_button:
		push_error("CompletionPanel: No se encontraron los botones")
		return
	
	if not completion_stats_list:
		push_error("CompletionPanel: No se encontró completion_stats_list")
		return
	
	# Conectar botones
	continue_button.pressed.connect(_on_continue_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Conectar señal de completado del juego
	if GameCompletionManager.has_signal("game_completed"):
		GameCompletionManager.game_completed.connect(_on_game_completed)
	else:
		push_error("GameCompletionManager no tiene la señal game_completed")
	
	print("CompletionPanel inicializado correctamente")

func _on_game_completed():
	print("Señal de juego completado recibida")
	call_deferred("show_completion")

func show_completion():
	print("Mostrando panel de completado")
	
	# Actualizar contenido
	update_completion_message()
	update_completion_stats()
	
	visible = true
	is_animating = true
	
	# Asegurar que el panel esté al frente
	get_parent().move_child(self, get_parent().get_child_count() - 1)
	
	# Efecto de aparición espectacular
	modulate = Color(1, 1, 1, 0)
	completion_panel.scale = Vector2(0.5, 0.5)
	completion_panel.rotation = deg_to_rad(-5)
	
	# Animar entrada del panel principal
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color.WHITE, 0.7)
	tween.tween_property(completion_panel, "scale", Vector2(1.05, 1.05), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(completion_panel, "rotation", 0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	# Efecto de rebote
	var bounce_tween = create_tween()
	bounce_tween.tween_property(completion_panel, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Animar paneles izquierdo y derecho con delay
	left_panel.modulate = Color(1, 1, 1, 0)
	right_panel.modulate = Color(1, 1, 1, 0)
	
	var original_left_pos = left_panel.position.x
	var original_right_pos = right_panel.position.x
	left_panel.position.x -= 50
	right_panel.position.x += 50
	
	var panels_tween = create_tween()
	panels_tween.set_parallel(true)
	
	# Panel izquierdo
	panels_tween.tween_property(left_panel, "modulate", Color.WHITE, 0.4).set_delay(0.2)
	panels_tween.tween_property(left_panel, "position:x", original_left_pos, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.2)
	
	# Panel derecho
	panels_tween.tween_property(right_panel, "modulate", Color.WHITE, 0.4).set_delay(0.4)
	panels_tween.tween_property(right_panel, "position:x", original_right_pos, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.4)
	
	await panels_tween.finished
	is_animating = false
	
	print("Panel de completado mostrado con dos columnas")

func update_completion_message():
	if not completion_message:
		push_error("completion_message no existe")
		return
	
	# Obtener información de progreso
	var buildings_progress = GameCompletionManager.get_buildings_progress()
	var achievements_progress = GameCompletionManager.get_achievements_progress()
	
	# Mensaje más compacto para el panel izquierdo
	var message = "[center][wave]¡Increíble trabajo, Constructor Maestro![/wave][/center]\n\n"
	message += "Has demostrado tu habilidad construyendo una ciudad próspera y completa.\n\n"
	message += "[b]🏆 Tus Logros:[/b]\n"
	message += "• ✅ Construiste al menos un edificio de cada tipo\n"
	message += "   [color=cyan](" + str(buildings_progress.completed) + "/" + str(buildings_progress.total) + " tipos completados)[/color]\n\n"
	
	message += "• [color=gray]⏳ Sistema de logros (próximamente)[/color]\n\n"
	
	message += "[center]Pero tu viaje no termina aquí...[/center]\n\n"
	message += "Puedes continuar expandiendo tu ciudad, optimizando sinergias y alcanzando nuevos récords.\n\n"
	message += "[center][rainbow]¡Gracias por jugar![/rainbow][/center]"
	
	completion_message.text = message
	print("Mensaje de completado actualizado")

func update_completion_stats():
	if not completion_stats_list:
		push_error("completion_stats_list no existe")
		return
	
	print("Actualizando estadísticas de completado")
	
	# Limpiar lista actual
	for child in completion_stats_list.get_children():
		child.queue_free()
	
	# Esperar un frame para que se limpien los nodos
	await get_tree().process_frame
	
	# Obtener estadísticas finales
	var general_stats = StatsManager.get_general_stats()
	var buildings_progress = GameCompletionManager.get_buildings_progress()
	
	# Sección: Estadísticas Generales
	create_stat_section_title("📊 Estadísticas Generales")
	
	create_completion_stat("🏠 Total de Edificios:", str(general_stats.total_buildings))
	create_completion_stat("🏆 Tipos Completados:", str(buildings_progress.completed) + "/" + str(buildings_progress.total))
	create_completion_stat("⚡ PPS Máximo:", "%.1f" % general_stats.highest_pps)
	create_completion_stat("💰 Puntos Ganados:", format_large_number(general_stats.total_points_earned))
	create_completion_stat("💸 Puntos Gastados:", format_large_number(general_stats.total_points_spent))
	create_completion_stat("⏱️ Tiempo Jugado:", general_stats.play_time_formatted)
	
	# Separador
	add_separator()
	
	# Sección: Edificios Completados
	var completed_buildings = GameCompletionManager.get_completed_buildings()
	if completed_buildings.size() > 0:
		create_stat_section_title("✅ Edificios Desbloqueados")
		
		# Crear grid de 2 columnas para edificios
		var grid = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 5)
		completion_stats_list.add_child(grid)
		
		for building_type in completed_buildings:
			var building_item = HBoxContainer.new()
			
			var icon = Label.new()
			icon.text = "🏛️"
			icon.add_theme_font_size_override("font_size", 14)
			
			var name_label = Label.new()
			name_label.text = format_building_name(building_type)
			name_label.add_theme_font_size_override("font_size", 12)
			name_label.add_theme_color_override("font_color", Color(0.8, 1, 0.8))
			
			building_item.add_child(icon)
			building_item.add_child(name_label)
			grid.add_child(building_item)
	else:
		var empty_label = Label.new()
		empty_label.text = "  (No hay edificios completados)"
		empty_label.add_theme_font_size_override("font_size", 12)
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		completion_stats_list.add_child(empty_label)
	
	# Separador final
	add_separator()
	
	# Sección: Récords
	create_stat_section_title("🎯 Tus Récords")
	
	# Verificar si existen las funciones antes de llamarlas
	if StatsManager.has_method("get_click_stats"):
		var click_stats = StatsManager.get_click_stats()
		if click_stats.has("total_clicks"):
			create_completion_stat("🖱️ Clics Totales:", str(click_stats.total_clicks))
	
	# Obtener edificio más construido usando get_most_built_type
	if StatsManager.has_method("get_most_built_type"):
		var most_built = StatsManager.get_most_built_type()
		if most_built.type != "" and most_built.count > 0:
			create_completion_stat("⭐ Edificio Favorito:", format_building_name(most_built.type) + " (" + str(most_built.count) + ")")
	elif StatsManager.has_method("get_all_building_counts"):
		# Alternativa: obtener todos los conteos y calcular el más construido
		var building_counts = StatsManager.get_all_building_counts()
		var most_built = get_most_built_building(building_counts)
		if most_built.count > 0:
			create_completion_stat("⭐ Edificio Favorito:", format_building_name(most_built.type) + " (" + str(most_built.count) + ")")
	
	print("Estadísticas actualizadas. Total items: ", completion_stats_list.get_child_count())

func create_stat_section_title(title_text: String):
	var title = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0))
	completion_stats_list.add_child(title)
	
	# Pequeño espacio después del título
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	completion_stats_list.add_child(spacer)

func create_completion_stat(label_text: String, value_text: String):
	var item = HBoxContainer.new()
	item.add_theme_constant_override("separation", 10)
	
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 13)
	
	var value = Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_color_override("font_color", Color(1, 1, 0.5))
	value.add_theme_font_size_override("font_size", 13)
	value.custom_minimum_size.x = 120
	
	item.add_child(label)
	item.add_child(value)
	completion_stats_list.add_child(item)

func add_separator():
	var separator = HSeparator.new()
	completion_stats_list.add_child(separator)
	
	# Pequeño espacio después del separador
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	completion_stats_list.add_child(spacer)

func format_building_name(building_type: String) -> String:
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

func format_large_number(number: int) -> String:
	if number >= 1000000:
		return "%.1fM" % (number / 1000000.0)
	elif number >= 1000:
		return "%.1fK" % (number / 1000.0)
	else:
		return str(number)

func get_most_built_building(building_stats: Dictionary) -> Dictionary:
	var most_built = {"type": "", "count": 0}
	
	for building_type in building_stats:
		var count = building_stats[building_type]
		if count > most_built.count:
			most_built.type = building_type
			most_built.count = count
	
	return most_built

func hide_completion():
	if is_animating:
		return
	
	print("Ocultando panel de completado")
	is_animating = true
	
	# Efecto de desaparición
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_property(completion_panel, "scale", Vector2(0.9, 0.9), 0.3)
	
	await tween.finished
	visible = false
	is_animating = false
	
	print("Panel de completado cerrado")

func _on_continue_button_pressed():
	print("Botón 'Continuar Jugando' presionado")
	hide_completion()

func _on_close_button_pressed():
	print("Botón 'Cerrar' presionado")
	hide_completion()

# Función para testing manual
func show_completion_manual():
	print("Mostrando panel manualmente (para pruebas)")
	show_completion()
