# FeedbackPanel.gd
extends Panel

@onready var message_label: Label = $MarginContainer/MessageLabel

var tween: Tween

func setup(message: String, color: Color, duration: float = 2.5):
	"""Configura el panel de feedback con mensaje, color y duración"""
	
	# Configurar texto
	message_label.text = message
	message_label.add_theme_color_override("font_color", color)
	# Iniciar animación de desvanecimiento
	start_fade_out(duration)

func start_fade_out(duration: float):
	"""Inicia la animación de desvanecimiento"""
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

func _exit_tree():
	"""Limpiar tween al salir del árbol"""
	if tween:
		tween.kill()
