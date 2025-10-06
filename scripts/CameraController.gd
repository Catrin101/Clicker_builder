extends Camera2D

# Configuración de zoom
@export var zoom_speed: float = 0.1
@export var zoom_min: float = 0.5
@export var zoom_max: float = 3.0

# Configuración de movimiento
@export var pan_speed: float = 500.0
@export var drag_sensitivity: float = 1.0

# Límites de movimiento
@export var movement_limit: float = 5000.0

# Variables internas
var is_dragging: bool = false
var drag_start_position: Vector2 = Vector2.ZERO
var camera_start_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Asegurar que el zoom inicial esté dentro de los límites
	zoom = Vector2.ONE

func _input(event: InputEvent) -> void:
	# Zoom con rueda del ratón (solo si no está sobre un control de UI)
	if event is InputEventMouseButton:
		var viewport = get_viewport()
		var gui_control = viewport.gui_get_focus_owner()
		var mouse_over_ui = false
		
		# Verificar si el mouse está sobre algún control de UI
		if viewport.gui_get_hovered_control() != null:
			mouse_over_ui = true
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and not mouse_over_ui:
			zoom_camera(zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and not mouse_over_ui:
			zoom_camera(-zoom_speed)
		
		# Iniciar arrastre con clic derecho
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_dragging = true
				drag_start_position = event.position
				camera_start_position = position
			else:
				is_dragging = false
	
	# Arrastrar cámara con el ratón
	elif event is InputEventMouseMotion and is_dragging:
		var drag_offset = (drag_start_position - event.position) * drag_sensitivity / zoom.x
		position = camera_start_position + drag_offset
		clamp_camera_position()

func _process(delta: float) -> void:
	# Zoom con teclas N y M
	if Input.is_action_pressed("ui_page_up") or Input.is_key_pressed(KEY_N):
		zoom_camera(zoom_speed * delta * 5)
	if Input.is_action_pressed("ui_page_down") or Input.is_key_pressed(KEY_M):
		zoom_camera(-zoom_speed * delta * 5)
	
	# Movimiento con teclado
	var direction = Vector2.ZERO
	
	# WASD
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		direction.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		direction.x += 1
	
	# Aplicar movimiento
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		position += direction * pan_speed * delta / zoom.x
		clamp_camera_position()

func zoom_camera(amount: float) -> void:
	var new_zoom = zoom + Vector2.ONE * amount
	new_zoom.x = clamp(new_zoom.x, zoom_min, zoom_max)
	new_zoom.y = clamp(new_zoom.y, zoom_min, zoom_max)
	zoom = new_zoom

func clamp_camera_position() -> void:
	position.x = clamp(position.x, -movement_limit, movement_limit)
	position.y = clamp(position.y, -movement_limit, movement_limit)
