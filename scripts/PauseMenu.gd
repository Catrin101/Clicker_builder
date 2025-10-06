# PauseMenu.gd - Menú de pausa del juego
extends Control

# Referencias a nodos
@onready var pause_panel: Panel = $PausePanel
@onready var resume_button: Button = $PausePanel/PauseMargin/PauseContainer/ButtonsContainer/ResumeButton
@onready var save_button: Button = $PausePanel/PauseMargin/PauseContainer/ButtonsContainer/SaveButton
@onready var load_button: Button = $PausePanel/PauseMargin/PauseContainer/ButtonsContainer/LoadButton
@onready var return_menu_button: Button = $PausePanel/PauseMargin/PauseContainer/ButtonsContainer/ReturnMenuButton
@onready var quit_button: Button = $PausePanel/PauseMargin/PauseContainer/ButtonsContainer/QuitButton

# Variables
var is_paused: bool = false

func _ready():
	# Conectar señales
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	return_menu_button.pressed.connect(_on_return_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Conectar señales del SaveSystem
	SaveSystem.save_completed.connect(_on_save_completed)
	SaveSystem.load_completed.connect(_on_load_completed)
	
	# Ocultar inicialmente
	hide()
	
	print("PauseMenu inicializado")

# COMENTAR O ELIMINAR ESTA FUNCIÓN
# func _input(event):
# 	if event.is_action_pressed("ui_cancel"):
# 		toggle_pause()

func toggle_pause():
	if is_paused:
		resume_game()
	else:
		pause_game()

func pause_game():
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
	
	print("Juego pausado")

func resume_game():
	get_tree().paused = false
	hide()
	is_paused = false
	print("Juego reanudado")

func update_buttons_state():
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
	print("Guardando partida...")
	save_button.text = "💾 Guardando..."
	save_button.disabled = true
	
	# Guardar en slot_1 por defecto (puedes hacer un selector de slots)
	SaveSystem.save_game("slot_1")

func _on_load_pressed():
	print("Cargando partida...")
	load_button.text = "📂 Cargando..."
	load_button.disabled = true
	
	# Cargar desde slot_1 por defecto
	if SaveSystem.has_save_file("slot_1"):
		# Primero despausar
		get_tree().paused = false
		
		# Luego cargar
		SaveSystem.load_game("slot_1")
	else:
		load_button.text = "📂 Cargar Partida"
		load_button.disabled = false
		print("No hay guardado en slot_1")

func _on_return_menu_pressed():
	print("Volviendo al menú principal...")
	
	# Despausar antes de cambiar de escena
	get_tree().paused = false
	
	# Cambiar al menú principal
	get_tree().change_scene_to_file("res://escenas/Menu.tscn")

func _on_quit_pressed():
	print("Saliendo del juego...")
	get_tree().quit()

func _on_save_completed(success: bool, slot_name: String):
	if success:
		save_button.text = "✅ Guardado exitoso"
		await get_tree().create_timer(1.5).timeout
		save_button.text = "💾 Guardar Partida"
		save_button.disabled = false
	else:
		save_button.text = "❌ Error al guardar"
		await get_tree().create_timer(1.5).timeout
		save_button.text = "💾 Guardar Partida"
		save_button.disabled = false

func _on_load_completed(success: bool, slot_name: String):
	if success:
		# Si la carga fue exitosa, ocultar el menú
		hide()
		is_paused = false
	else:
		load_button.text = "❌ Error al cargar"
		await get_tree().create_timer(1.5).timeout
		load_button.text = "📂 Cargar Partida"
		load_button.disabled = false
