extends AudioStreamPlayer

# Este script se adjunta al nodo AudioStreamPlayer que es hijo del botón.

# El nodo padre (el botón) será el que emita las señales.
@onready var parent_button = get_parent()

# --------------------------------------------------------------------------
# Función llamada automáticamente cuando el nodo entra en el árbol de la escena
func _ready():
	# 1. Conectar la señal 'pressed' del botón padre a la función 'play_sfx' de este nodo.
	if parent_button is Button:
		# Nota: Godot 4 usa 'Callable.bind()' para pasar argumentos en las conexiones.
		parent_button.pressed.connect(play_sfx)

	# 2. Conectar la señal 'mouse_entered' para el sonido de hover
	# (Opcional, si quieres sonido al pasar el ratón)
	#if parent_button.has_signal("mouse_entered"):
	#	parent_button.mouse_entered.connect(play_sfx)


# --------------------------------------------------------------------------
# Función que simplemente reproduce el sonido asignado al AudioStreamPlayer.
# El argumento 'stream' es opcional y permite asignar un nuevo sonido temporal.
func play_sfx(stream: AudioStream = null):
	# Si se pasa un nuevo stream, lo asigna antes de reproducir.
	if stream:
		self.stream = stream
		
	# Detener la reproducción si ya está sonando para asegurar un reinicio rápido (casi instantáneo).
	stop()
	play()
