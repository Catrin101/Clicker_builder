# WelcomePanel.gd - Panel de bienvenida al iniciar el juego
extends ColorRect

# Referencias a nodos
@onready var welcome_panel: Panel = $WelcomePanel
@onready var start_button: Button = $WelcomePanel/WelcomeMargin/WelcomeContainer/StartGameButton
@onready var welcome_message: RichTextLabel = $WelcomePanel/WelcomeMargin/WelcomeContainer/WelcomeMessage

# Variables de animación
var is_animating: bool = false

func _ready():
	# Conectar el botón de inicio
	start_button.pressed.connect(_on_start_button_pressed)
	
	# Verificar si debemos mostrar el panel de bienvenida
	if GameCompletionManager.is_first_time():
		show_welcome()
	else:
		# Si no es la primera vez, ocultar inmediatamente
		hide_welcome_immediate()
	
	print("WelcomePanel inicializado")

func show_welcome():
	visible = true
	is_animating = true
	
	# Efecto de aparición suave
	modulate = Color(1, 1, 1, 0)
	welcome_panel.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)
	tween.tween_property(welcome_panel, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	is_animating = false
	
	print("Panel de bienvenida mostrado")

func hide_welcome():
	if is_animating:
		return
	
	is_animating = true
	
	# Efecto de desaparición suave
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_property(welcome_panel, "scale", Vector2(0.9, 0.9), 0.3)
	
	await tween.finished
	visible = false
	is_animating = false
	
	# Marcar como cerrado
	GameCompletionManager.mark_welcome_closed()
	
	print("Panel de bienvenida cerrado")

func hide_welcome_immediate():
	visible = false
	modulate = Color(1, 1, 1, 0)

func _on_start_button_pressed():
	# Efecto de clic en el botón
	var tween = create_tween()
	tween.tween_property(start_button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(start_button, "scale", Vector2(1, 1), 0.1)
	
	# Marcar que se mostró la bienvenida
	GameCompletionManager.mark_welcome_shown()
	
	# Ocultar el panel
	hide_welcome()

# Función pública para mostrar la bienvenida manualmente (si se necesita)
func show_welcome_manual():
	show_welcome()
