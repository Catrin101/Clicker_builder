# OptionsMenu.gd - Menú de opciones del juego - ADAPTADO A TU ESTRUCTURA
extends Control

# Referencias a nodos (coinciden con tu estructura)
@onready var master_volume_slider: HSlider = $OptionsPanel/OptionsMargin/OptionsContainer/SettingsContainer/AudioSection/Master/HSlider
@onready var master_volume_value: Label = $OptionsPanel/OptionsMargin/OptionsContainer/SettingsContainer/AudioSection/Master/Label2

@onready var resolution_option: OptionButton = $OptionsPanel/OptionsMargin/OptionsContainer/SettingsContainer/VideoSection/ResolutionContainer/ResolutionOption
@onready var fullscreen_check: CheckButton = $OptionsPanel/OptionsMargin/OptionsContainer/SettingsContainer/VideoSection/FullscreenContainer/FullscreenCheck

@onready var apply_button: Button = $OptionsPanel/OptionsMargin/OptionsContainer/ButtonsContainer/ApplyButton
@onready var reset_button: Button = $OptionsPanel/OptionsMargin/OptionsContainer/ButtonsContainer/ResetButton
@onready var close_button: Button = $OptionsPanel/OptionsMargin/OptionsContainer/ButtonsContainer/CloseButton

@onready var options_panel: Panel = $OptionsPanel

# Resoluciones disponibles
const RESOLUTIONS = {
	"1920x1080": Vector2i(1920, 1080),
	"1600x900": Vector2i(1600, 900),
	"1366x768": Vector2i(1366, 768),
	"1280x720": Vector2i(1280, 720),
	"1024x768": Vector2i(1024, 768),
	"800x600": Vector2i(800, 600)
}

# Valores por defecto
const DEFAULT_MASTER_VOLUME = 100
const DEFAULT_RESOLUTION = "1280x720"
const DEFAULT_FULLSCREEN = false

# Variables temporales
var temp_master_volume: float = DEFAULT_MASTER_VOLUME
var temp_resolution: String = DEFAULT_RESOLUTION
var temp_fullscreen: bool = DEFAULT_FULLSCREEN

func _ready():
	# Configurar proceso mode para que funcione en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Conectar señales
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	resolution_option.item_selected.connect(_on_resolution_selected)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	
	# Conectar botones
	apply_button.pressed.connect(_on_apply_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Inicializar opciones de resolución
	setup_resolution_options()
	
	# Cargar configuración guardada
	load_settings()
	
	# Ocultar inicialmente
	hide()
	
	print("✅ OptionsMenu inicializado correctamente")

func setup_resolution_options():
	resolution_option.clear()
	var index = 0
	var default_index = 0
	
	for res_name in RESOLUTIONS.keys():
		resolution_option.add_item(res_name)
		if res_name == DEFAULT_RESOLUTION:
			default_index = index
		index += 1
	
	resolution_option.selected = default_index

func show_options():
	show()
	
	# Animar entrada
	options_panel.modulate = Color(1, 1, 1, 0)
	options_panel.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(options_panel, "modulate", Color.WHITE, 0.3)
	tween.tween_property(options_panel, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_options():
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(options_panel, "modulate", Color(1, 1, 1, 0), 0.2)
	tween.tween_property(options_panel, "scale", Vector2(0.9, 0.9), 0.2)
	
	await tween.finished
	hide()

# ============================================================================
# FUNCIONES DE CAMBIO DE VALORES
# ============================================================================

func _on_master_volume_changed(value: float):
	temp_master_volume = value
	master_volume_value.text = str(int(value)) + "%"
	
	# Vista previa en tiempo real
	set_master_volume(value)

func _on_resolution_selected(index: int):
	temp_resolution = resolution_option.get_item_text(index)

func _on_fullscreen_toggled(toggled_on: bool):
	temp_fullscreen = toggled_on

# ============================================================================
# FUNCIONES DE APLICACIÓN DE CONFIGURACIÓN
# ============================================================================

func set_master_volume(value: float):
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	
	# Si el volumen es 0, mutear
	if value <= 0:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)

func set_resolution(res_name: String):
	if RESOLUTIONS.has(res_name):
		var size = RESOLUTIONS[res_name]
		get_window().size = size
		
		# Centrar ventana
		var screen_size = DisplayServer.screen_get_size()
		var window_size = get_window().size
		var centered_pos = (screen_size - window_size) / 2
		get_window().position = centered_pos
		
		print("✅ Resolución cambiada a: ", res_name)

func set_fullscreen(enabled: bool):
	if enabled:
		get_window().mode = Window.MODE_FULLSCREEN
	else:
		get_window().mode = Window.MODE_WINDOWED
	
	print("✅ Pantalla completa: ", enabled)

# ============================================================================
# FUNCIONES DE BOTONES
# ============================================================================

func _on_apply_pressed():
	print("Aplicando configuración...")
	
	# Aplicar configuración de audio
	set_master_volume(temp_master_volume)
	
	# Aplicar configuración de video
	set_resolution(temp_resolution)
	set_fullscreen(temp_fullscreen)
	
	# Guardar configuración
	save_settings()
	
	print("✅ Configuración aplicada y guardada")

func _on_reset_pressed():
	print("Restableciendo valores por defecto...")
	
	# Restaurar valores por defecto
	temp_master_volume = DEFAULT_MASTER_VOLUME
	temp_resolution = DEFAULT_RESOLUTION
	temp_fullscreen = DEFAULT_FULLSCREEN
	
	# Actualizar UI
	master_volume_slider.value = temp_master_volume
	
	# Buscar índice de resolución por defecto
	for i in range(resolution_option.item_count):
		if resolution_option.get_item_text(i) == DEFAULT_RESOLUTION:
			resolution_option.selected = i
			break
	
	fullscreen_check.button_pressed = temp_fullscreen
	
	print("🔄 Valores restablecidos (presiona Aplicar para confirmar)")

func _on_close_pressed():
	print("Cerrando menú de opciones")
	hide_options()

# ============================================================================
# GUARDAR Y CARGAR CONFIGURACIÓN
# ============================================================================

func save_settings():
	var config = ConfigFile.new()
	
	# Audio
	config.set_value("audio", "master_volume", temp_master_volume)
	
	# Video
	config.set_value("video", "resolution", temp_resolution)
	config.set_value("video", "fullscreen", temp_fullscreen)
	
	var error = config.save("user://settings.cfg")
	if error == OK:
		print("✅ Configuración guardada en user://settings.cfg")
	else:
		printerr("❌ Error al guardar configuración: ", error)

func load_settings():
	var config = ConfigFile.new()
	var error = config.load("user://settings.cfg")
	
	if error != OK:
		print("ℹ️ No hay configuración guardada, usando valores por defecto")
		apply_default_settings()
		return
	
	# Cargar audio
	temp_master_volume = config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)
	
	# Cargar video
	temp_resolution = config.get_value("video", "resolution", DEFAULT_RESOLUTION)
	temp_fullscreen = config.get_value("video", "fullscreen", DEFAULT_FULLSCREEN)
	
	# Aplicar configuración cargada
	apply_loaded_settings()
	
	print("✅ Configuración cargada desde user://settings.cfg")

func apply_default_settings():
	temp_master_volume = DEFAULT_MASTER_VOLUME
	temp_resolution = DEFAULT_RESOLUTION
	temp_fullscreen = DEFAULT_FULLSCREEN
	
	apply_loaded_settings()

func apply_loaded_settings():
	# Aplicar a la UI
	master_volume_slider.value = temp_master_volume
	
	# Aplicar audio
	set_master_volume(temp_master_volume)
	
	# Aplicar video
	for i in range(resolution_option.item_count):
		if resolution_option.get_item_text(i) == temp_resolution:
			resolution_option.selected = i
			break
	
	fullscreen_check.button_pressed = temp_fullscreen
	
	set_resolution(temp_resolution)
	set_fullscreen(temp_fullscreen)
