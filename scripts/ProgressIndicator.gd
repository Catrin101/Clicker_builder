# ProgressIndicator.gd - Indicador visual de progreso del juego
extends Panel

# Referencias a nodos
@onready var buildings_progress_bar: TextureProgressBar = $ProgressMargin/ProgressContainer/BuildingsProgressBar
@onready var buildings_progress_label: Label = $ProgressMargin/ProgressContainer/BuildingsProgressLabel
@onready var achievements_progress_bar: TextureProgressBar = $ProgressMargin/ProgressContainer/AchievementsProgressBar
@onready var achievements_progress_label: Label = $ProgressMargin/ProgressContainer/AchievementsProgressLabel

# Variables de configuración
var show_achievements: bool = false  # Por defecto oculto hasta que se implemente el sistema

func _ready():
	# Conectar señales de progreso
	GameCompletionManager.progress_updated.connect(_on_progress_updated)
	GameCompletionManager.game_completed.connect(_on_game_completed)
	
	# Configurar barras de progreso
	setup_progress_bars()
	
	# Actualizar progreso inicial
	update_progress()
	
	# Ocultar sección de logros si no hay sistema implementado
	if not show_achievements:
		achievements_progress_label.visible = false
		achievements_progress_bar.visible = false
	
	print("ProgressIndicator inicializado")

func setup_progress_bars():
	# Configurar barra de edificios
	var buildings_progress = GameCompletionManager.get_buildings_progress()
	buildings_progress_bar.max_value = buildings_progress.total
	buildings_progress_bar.value = buildings_progress.completed
	
	# Configurar barra de logros (cuando se implemente)
	var achievements_progress = GameCompletionManager.get_achievements_progress()
	achievements_progress_bar.max_value = max(achievements_progress.total, 1)  # Evitar división por 0
	achievements_progress_bar.value = achievements_progress.completed

func _on_progress_updated(buildings_progress: float, achievements_progress: float):
	update_progress()

func update_progress():
	var buildings_progress = GameCompletionManager.get_buildings_progress()
	var achievements_progress = GameCompletionManager.get_achievements_progress()
	
	# Actualizar barra de edificios
	buildings_progress_bar.max_value = buildings_progress.total
	buildings_progress_bar.value = buildings_progress.completed
	buildings_progress_label.text = "🏠 Tipos de Edificios: " + str(buildings_progress.completed) + "/" + str(buildings_progress.total)
	
	# Cambiar color según progreso
	if buildings_progress.percentage >= 100:
		buildings_progress_bar.modulate = Color.GREEN
		animate_completion()
	elif buildings_progress.percentage >= 75:
		buildings_progress_bar.modulate = Color.YELLOW
	else:
		buildings_progress_bar.modulate = Color.WHITE
	
	# Actualizar barra de logros (cuando se implemente)
	if show_achievements:
		achievements_progress_bar.max_value = max(achievements_progress.total, 1)
		achievements_progress_bar.value = achievements_progress.completed
		achievements_progress_label.text = "🏆 Logros: " + str(achievements_progress.completed) + "/" + str(achievements_progress.total)

func animate_completion():
	# Animación cuando se completa un tipo de edificio
	var tween = create_tween()
	tween.tween_property(buildings_progress_bar, "modulate", Color(0.5, 1, 0.5, 1), 0.3)
	tween.tween_property(buildings_progress_bar, "modulate", Color.GREEN, 0.3)

func _on_game_completed():
	# Animación especial cuando se completa todo el juego
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(self, "modulate", Color(1.2, 1.2, 0.8, 1), 0.3)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	# Después de la animación, ocultar gradualmente el panel
	await tween.finished
	
	var fade_tween = create_tween()
	fade_tween.tween_interval(2.0)
	fade_tween.tween_property(self, "modulate:a", 0.0, 1.0)
	
	await fade_tween.finished
	visible = false

# Función para mostrar/ocultar sección de logros
func set_achievements_visible(visible_state: bool):
	show_achievements = visible_state
	achievements_progress_label.visible = visible_state
	achievements_progress_bar.visible = visible_state

# Función para actualizar manualmente el progreso
func refresh_progress():
	update_progress()
