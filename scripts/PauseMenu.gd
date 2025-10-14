# PauseMenu.gd - VERSIÓN CORREGIDA PARA EXPORTACIÓN
extends Control

# Referencias a nodos
@onready var pause_panel: Panel = $PausePanel
@onready var resume_button: Button = $PausePanel/PauseMargin/PauseContainer/ButtonsContainer/ResumeButton
@onready var save_button: Button = $PausePanel/PauseMargin/PauseContainer/ButtonsContainer/SaveButton
@onready var load_button: Button = $PausePanel/PauseMargin/PauseContainer/ButtonsContainer/LoadButton
@onready var options_button: Button = $PausePanel/PauseMargin/PauseContainer/ButtonsContainer/OptionsButton
@onready var return_menu_button: Button = $PausePanel/PauseMargin/PauseContainer/ButtonsContainer/ReturnMenuButton
@onready var quit_button: Button = $PausePanel/PauseMargin/PauseContainer/ButtonsContainer/QuitButton

# Variables
var is_paused: bool = false

# Escena de opciones
var options_menu_instance: Control = null

func _ready():
	# Conectar señales
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	options_button.pressed.connect(_on_options_pressed)
	return_menu_button.pressed.connect(_on_return_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Conectar señales del SaveSystem
	if SaveSystem:
		SaveSystem.save_completed.connect(_on_save_completed)
		SaveSystem.load_completed.connect(_on_load_completed)
	
	# Buscar OptionsMenu en la escena (si está instanciado)
	var main_scene = get_tree().current_scene
	if main_scene:
		options_menu_instance = main_scene.get_node_or_null("UI/OptionsMenu")
		if options_menu_instance:
			print("✅ OptionsMenu encontrado en UI")
	
	# Ocultar inicialmente
	hide()
	
	print("✅ PauseMenu inicializado")

func toggle_pause():
	if is_paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	is_paused = true
	get_tree().paused = true
	show()
	
	# Actualizar estado de botones
	update_buttons_state()
	
	# Animación de aparición
	pause_panel.modulate = Color(1, 1, 1, 0)
	pause_panel.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.parallel().tween_property(pause_panel, "modulate", Color.WHITE, 0.3)
	tween.parallel().tween_property(pause_panel, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	print("⏸️ Juego pausado")

func resume_game():
	# Cerrar menú de opciones si está abierto
	if options_menu_instance and is_instance_valid(options_menu_instance) and options_menu_instance.visible:
		options_menu_instance.hide_options()
	
	is_paused = false
	get_tree().paused = false
	hide()
	print("▶️ Juego reanudado")

func update_buttons_state():
	if not SaveSystem:
		load_button.disabled = true
		return
	
	# Verificar si hay guardados disponibles
	var has_saves = false
	for i in range(1, SaveSystem.MAX_SAVE_SLOTS + 1):
		if SaveSystem.has_save_file("slot_" + str(i)):
			has_saves = true
			break
	
	load_button.disabled = not has_saves

func _on_resume_pressed():
	resume_game()

func _on_save_pressed():
	if not SaveSystem:
		printerr("❌ SaveSystem no disponible")
		return
	
	print("💾 Guardando partida...")
	save_button.text = "💾 Guardando..."
	save_button.disabled = true
	
	# Guardar en slot_1 por defecto
	SaveSystem.save_game("slot_1")

func _on_load_pressed():
	if not SaveSystem:
		printerr("❌ SaveSystem no disponible")
		return
	
	print("📂 Cargando partida desde pausa...")
	load_button.text = "📂 Cargando..."
	load_button.disabled = true
	
	if SaveSystem.has_save_file("slot_1"):
		# CRÍTICO: Despausar COMPLETAMENTE antes de cargar
		is_paused = false
		get_tree().paused = false
		hide()
		
		# Esperar un frame para asegurar que la despausa se aplicó
		await get_tree().process_frame
		
		# Ahora cargar
		var success = await SaveSystem.load_game("slot_1")
		
		if not success:
			# Si falla, volver a mostrar el menú de pausa
			print("❌ Error al cargar, volviendo al menú de pausa")
			is_paused = true
			get_tree().paused = true
			show()
			if is_instance_valid(load_button):
				load_button.text = "❌ Error al cargar"
				await get_tree().create_timer(1.5).timeout
				load_button.text = "📂 Cargar Partida"
				load_button.disabled = false
	else:
		load_button.text = "📂 Sin guardados"
		await get_tree().create_timer(1.5).timeout
		if is_instance_valid(load_button):
			load_button.text = "📂 Cargar Partida"
			update_buttons_state()

func _on_options_pressed():
	print("⚙️ Abriendo menú de opciones desde pausa")
	
	if not options_menu_instance or not is_instance_valid(options_menu_instance):
		printerr("⚠️ OptionsMenu no disponible")
		return
	
	# Mostrar menú
	options_menu_instance.show_options()

func _on_return_menu_pressed():
	print("🏠 Volviendo al menú principal...")
	
	# CRÍTICO: Deshabilitar botón inmediatamente para evitar doble clic
	return_menu_button.disabled = true
	return_menu_button.text = "🏠 Regresando..."
	
	# Cerrar menú de opciones si está abierto
	if options_menu_instance and is_instance_valid(options_menu_instance):
		if options_menu_instance.visible:
			options_menu_instance.hide_options()
	
	# CRÍTICO PASO 1: Despausar COMPLETAMENTE
	is_paused = false
	get_tree().paused = false
	
	print("   ✅ Juego despausado")
	
	# CRÍTICO PASO 2: Esperar múltiples frames para asegurar limpieza completa
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("   ✅ Frames procesados, cambiando escena...")
	
	# CRÍTICO PASO 3: Usar call_deferred para cambio de escena
	get_tree().call_deferred("change_scene_to_file", "res://escenas/Menu.tscn")
	
	print("   ✅ Cambio de escena solicitado")

func _on_quit_pressed():
	print("🚪 Saliendo del juego...")
	
	# Deshabilitar botón
	quit_button.disabled = true
	quit_button.text = "🚪 Cerrando..."
	
	# CRÍTICO: Despausar antes de cerrar
	is_paused = false
	get_tree().paused = false
	
	# Esperar un frame
	await get_tree().process_frame
	
	# Cerrar el juego
	get_tree().quit()

func _on_save_completed(success: bool, slot_name: String):
	if not is_instance_valid(save_button):
		return
	
	if success:
		save_button.text = "✅ Guardado exitoso"
		await get_tree().create_timer(1.5).timeout
		if is_instance_valid(save_button):
			save_button.text = "💾 Guardar Partida"
			save_button.disabled = false
	else:
		save_button.text = "❌ Error al guardar"
		await get_tree().create_timer(1.5).timeout
		if is_instance_valid(save_button):
			save_button.text = "💾 Guardar Partida"
			save_button.disabled = false

func _on_load_completed(success: bool, slot_name: String):
	if not is_instance_valid(load_button):
		return
	
	# Esta señal se emite después de que SaveSystem termine
	if not success:
		load_button.text = "❌ Error al cargar"
		await get_tree().create_timer(1.5).timeout
		if is_instance_valid(load_button):
			load_button.text = "📂 Cargar Partida"
			update_buttons_state()
