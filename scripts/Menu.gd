# Menu.gd - VERSIÓN CORREGIDA PARA EXPORTACIÓN
extends Control

# Referencias a nodos
@onready var new_game_button: Button = $MenuContainer/MenuVBox/ButtonsContainer/NewGameButton
@onready var load_game_button: Button = $MenuContainer/MenuVBox/ButtonsContainer/LoadGameButton
@onready var options_button: Button = $MenuContainer/MenuVBox/ButtonsContainer/OptionsButton
@onready var quit_button: Button = $MenuContainer/MenuVBox/ButtonsContainer/QuitButton

# Referencias para parallax
@onready var parallax_background: ParallaxBackground = $ParallaxBackground
@onready var music_player: AudioStreamPlayer = $MusicPlayer

# Escena de opciones
var options_menu_scene_path: String = "res://escenas/OptionsMenu.tscn"
var options_menu_instance: Control = null

# Variables para el efecto parallax
var mouse_position: Vector2 = Vector2.ZERO
var screen_center: Vector2 = Vector2.ZERO
var parallax_strength: float = 30.0
var parallax_smoothness: float = 0.1

# Variable para prevenir múltiples cambios de escena
var is_transitioning: bool = false

func _ready():
	print("🏠 Menu inicializando...")
	
	# CRÍTICO: Asegurar que el juego NO esté pausado al entrar al menú
	get_tree().paused = false
	
	# Conectar señales de botones
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Verificar si hay guardados disponibles
	update_load_button_state()
	
	# Calcular centro de la pantalla
	screen_center = get_viewport().get_visible_rect().size / 2.0
	
	# Configurar música
	setup_music()
	
	print("✅ Menú principal inicializado con parallax")

func setup_music():
	if music_player and music_player.stream:
		# Asegurar que la música haga loop
		if music_player.stream is AudioStreamOggVorbis:
			music_player.stream.loop = true
		elif music_player.stream is AudioStreamWAV:
			music_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		
		print("🎵 Música de menú configurada")

func _process(delta):
	# Actualizar efecto parallax basado en posición del mouse
	update_parallax_effect(delta)

func _input(event):
	# Capturar movimiento del mouse
	if event is InputEventMouseMotion:
		mouse_position = event.position

func update_parallax_effect(delta: float):
	if not parallax_background:
		return
	
	# Calcular offset basado en la distancia del mouse al centro
	var offset_from_center = (mouse_position - screen_center) / screen_center
	
	# Aplicar el efecto con la intensidad configurada
	var target_offset = offset_from_center * parallax_strength
	
	# Suavizar el movimiento usando lerp
	var current_offset = parallax_background.scroll_offset
	parallax_background.scroll_offset = current_offset.lerp(target_offset, parallax_smoothness)

func update_load_button_state():
	if not SaveSystem:
		load_game_button.disabled = true
		load_game_button.text = "📂 Cargar Partida (Sistema no disponible)"
		return
	
	# Verificar si existe al menos un guardado
	var has_saves = false
	for i in range(1, SaveSystem.MAX_SAVE_SLOTS + 1):
		if SaveSystem.has_save_file("slot_" + str(i)):
			has_saves = true
			break
	
	# Deshabilitar botón de cargar si no hay guardados
	load_game_button.disabled = not has_saves
	
	if not has_saves:
		load_game_button.text = "📂 Cargar Partida (Sin guardados)"
	else:
		load_game_button.text = "📂 Cargar Partida"

func _on_new_game_pressed():
	if is_transitioning:
		print("⚠️ Transición ya en progreso, ignorando clic")
		return
	
	is_transitioning = true
	print("🆕 Nueva partida iniciada")
	
	# Deshabilitar botón
	new_game_button.disabled = true
	new_game_button.text = "🆕 Iniciando..."
	
	# Resetear todos los managers antes de empezar
	reset_game_state()
	
	# CRÍTICO: Esperar frames antes de cambiar escena
	await get_tree().process_frame
	await get_tree().process_frame
	
	# CRÍTICO: Usar call_deferred para cambio seguro de escena
	print("   ✅ Cambiando a main.tscn...")
	get_tree().call_deferred("change_scene_to_file", "res://escenas/main.tscn")

func _on_load_game_pressed():
	if is_transitioning:
		print("⚠️ Transición ya en progreso, ignorando clic")
		return
	
	if not SaveSystem:
		printerr("❌ SaveSystem no disponible")
		return
	
	is_transitioning = true
	print("📂 Abriendo selector de partidas guardadas")
	
	# Deshabilitar botón mientras carga
	load_game_button.disabled = true
	load_game_button.text = "📂 Cargando..."
	
	# Verificar que el árbol de escena está disponible
	if not get_tree():
		printerr("❌ Error: get_tree() es null")
		is_transitioning = false
		load_game_button.disabled = false
		load_game_button.text = "❌ Error"
		await get_tree().create_timer(2.0).timeout
		update_load_button_state()
		return
	
	# Cargar slot_1 si existe
	if SaveSystem.has_save_file("slot_1"):
		# Esperar frames antes de cargar
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Cargar con await
		var success = await SaveSystem.load_game("slot_1")
		
		if not success:
			# Si falla, restaurar botón
			print("❌ Error al cargar partida")
			is_transitioning = false
			if is_instance_valid(load_game_button):
				load_game_button.disabled = false
				load_game_button.text = "❌ Error al cargar"
				await get_tree().create_timer(2.0).timeout
				if is_instance_valid(load_game_button):
					update_load_button_state()
		# Si tiene éxito, SaveSystem ya habrá cambiado de escena
	else:
		print("📂 No hay guardados en slot_1")
		is_transitioning = false
		if is_instance_valid(load_game_button):
			load_game_button.disabled = false
			load_game_button.text = "📂 Sin guardados"
			await get_tree().create_timer(2.0).timeout
			if is_instance_valid(load_game_button):
				update_load_button_state()

func _on_options_pressed():
	print("⚙️ Abriendo menú de opciones")
	
	# Cargar escena de opciones si no existe
	if not options_menu_instance:
		if ResourceLoader.exists(options_menu_scene_path):
			var options_scene = load(options_menu_scene_path)
			if options_scene:
				options_menu_instance = options_scene.instantiate()
				add_child(options_menu_instance)
				print("   ✅ OptionsMenu instanciado")
			else:
				printerr("   ❌ Error al cargar OptionsMenu")
				return
		else:
			printerr("   ❌ OptionsMenu.tscn no existe")
			return
	
	# Mostrar menú
	if options_menu_instance and options_menu_instance.has_method("show_options"):
		options_menu_instance.show_options()

func _on_quit_pressed():
	if is_transitioning:
		print("⚠️ Transición ya en progreso, ignorando clic")
		return
	
	is_transitioning = true
	print("🚪 Saliendo del juego")
	
	# Deshabilitar botón
	quit_button.disabled = true
	quit_button.text = "🚪 Cerrando..."
	
	# Esperar un frame
	await get_tree().process_frame
	
	# Salir
	get_tree().quit()

func reset_game_state():
	print("🔄 Reseteando estado del juego...")
	
	# Resetear GameManager
	if GameManager:
		GameManager.player_points = 10
		GameManager.total_points_per_second = 0.0
		GameManager.is_placing_building = false
		GameManager.building_to_place = ""
		GameManager.is_placing_mode = false
		print("   ✅ GameManager reseteado")
	
	# Resetear StatsManager
	if StatsManager and StatsManager.has_method("reset_stats"):
		StatsManager.reset_stats()
		print("   ✅ StatsManager reseteado")
	
	# Resetear GameCompletionManager
	if GameCompletionManager and GameCompletionManager.has_method("reset_completion_state"):
		GameCompletionManager.reset_completion_state()
		print("   ✅ GameCompletionManager reseteado")
	
	print("✅ Estado del juego reseteado completamente")
