# CompletionPanel.gd - Panel de felicitación al completar el juego
extends ColorRect

# Referencias a nodos
@onready var completion_panel: Panel = $CompletionPanel
@onready var completion_message: RichTextLabel = $CompletionPanel/CompletionMargin/CompletionContainer/CompletionMessage
@onready var completion_stats_list: VBoxContainer = $CompletionPanel/CompletionMargin/CompletionContainer/CompletionStatsList
@onready var continue_button: Button = $CompletionPanel/CompletionMargin/CompletionContainer/CompletionButtonsContainer/ContinuePlayingButton
@onready var close_button: Button = $CompletionPanel/CompletionMargin/CompletionContainer/CompletionButtonsContainer/CloseCompletionButton

# Variables de animación
var is_animating: bool = false

func _ready():
	# Inicialmente oculto
	visible = false
	
	# Conectar botones
	continue_button.pressed.connect(_on_continue_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Conectar señal de completado del juego
	GameCompletionManager.game_completed.connect(_on_game_completed)
	
	print("CompletionPanel inicializado")

func _on_game_completed():
	print("Señal de juego completado recibida")
	call_deferred("show_completion")

func show_completion():
	# Actualizar el mensaje con información de logros
	update_completion_message()
	
	# Actualizar estadísticas
	update_completion_stats()
	
	visible = true
	is_animating = true
	
	# Efecto de aparición espectacular
	modulate = Color(1, 1, 1, 0)
	completion_panel.scale = Vector2(0.5, 0.5)
	completion_panel.rotation = deg_to_rad(-10)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color.WHITE, 0.7)
	tween.tween_property(completion_panel, "scale", Vector2(1.05, 1.05), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(completion_panel, "rotation", 0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	# Pequeño efecto de rebote
	var bounce_tween = create_tween()
	bounce_tween.tween_property(completion_panel, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	await bounce_tween.finished
	is_animating = false
	
	print("Panel de completado mostrado")

func update_completion_message():
	# Obtener información de progreso
	var buildings_progress = GameCompletionManager.get_buildings_progress()
	var achievements_progress = GameCompletionManager.get_achievements_progress()
	
	# Construir mensaje dinámico
	var message = "[center]¡Increíble trabajo, Constructor Maestro![/center]\n\n"
	message += "Has demostrado tu habilidad construyendo una ciudad próspera y completa.\n\n"
	message += "[b]Tus Logros:[/b]\n"
	message += "• ✅ Construiste al menos un edificio de cada tipo (" + str(buildings_progress.completed) + "/" + str(buildings_progress.total) + ")\n"
	
	# TODO: Descomentar cuando se implemente el sistema de logros
	# if achievements_progress.total > 0:
	#     message += "• ✅ Desbloqueaste todos los logros (" + str(achievements_progress.completed) + "/" + str(achievements_progress.total) + ")\n"
	# else:
	message += "• [color=gray]⏳ (Sistema de logros pendiente de implementar)[/color]\n"
	
	message += "\n[center]Pero tu viaje no termina aquí...[/center]\n\n"
	message += "Puedes continuar expandiendo tu ciudad, optimizando sinergias y alcanzando nuevos récords de producción.\n\n"
	message += "[center][rainbow]¡Gracias por jugar![/rainbow][/center]"
	
	completion_message.text = message

func update_completion_stats():
	# Limpiar lista actual
	for child in completion_stats_list.get_children():
		child.queue_free()
	
	# Obtener estadísticas finales
	var general_stats = StatsManager.get_general_stats()
	var buildings_progress = GameCompletionManager.get_buildings_progress()
	
	# Crear estadísticas
	create_completion_stat("🏠 Total de Edificios Construidos:", str(general_stats.total_buildings))
	create_completion_stat("🏆 Tipos Diferentes Completados:", str(buildings_progress.completed) + "/" + str(buildings_progress.total))
	create_completion_stat("⚡ PPS Máximo Alcanzado:", "%.1f" % general_stats.highest_pps)
	create_completion_stat("💰 Puntos Totales Ganados:", str(general_stats.total_points_earned))
	create_completion_stat("💸 Puntos Totales Gastados:", str(general_stats.total_points_spent))
	create_completion_stat("⏱️ Tiempo Total Jugado:", general_stats.play_time_formatted)
	
	# Mostrar edificios completados
	var completed_buildings = GameCompletionManager.get_completed_buildings()
	if completed_buildings.size() > 0:
		# Añadir separador
		var separator = HSeparator.new()
		completion_stats_list.add_child(separator)
		
		# Título de edificios completados
		var title_label = Label.new()
		title_label.text = "✅ Edificios Completados:"
		title_label.add_theme_font_size_override("font_size", 13)
		title_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
		completion_stats_list.add_child(title_label)
		
		# Lista de edificios
		for building_type in completed_buildings:
			var building_label = Label.new()
			building_label.text = "  • " + format_building_name(building_type)
			building_label.add_theme_font_size_override("font_size", 12)
			completion_stats_list.add_child(building_label)

func create_completion_stat(label_text: String, value_text: String):
	var item = HBoxContainer.new()
	
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 13)
	
	var value = Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_color_override("font_color", Color(1, 1, 0.5))
	value.add_theme_font_size_override("font_size", 13)
	value.custom_minimum_size.x = 150
	
	item.add_child(label)
	item.add_child(value)
	completion_stats_list.add_child(item)

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

func hide_completion():
	if is_animating:
		return
	
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
	# Solo ocultar el panel, el jugador puede seguir jugando
	hide_completion()

func _on_close_button_pressed():
	# Cerrar el panel
	hide_completion()

# Función pública para mostrar el panel manualmente
func show_completion_manual():
	show_completion()	
