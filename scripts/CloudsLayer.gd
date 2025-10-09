# CloudsLayer.gd
extends Node2D

# Configuración del movimiento
@export var wind_speed: Vector2 = Vector2(20, 0)  # Velocidad del viento (píxeles/seg)
@export var wind_variation: float = 5.0  # Variación aleatoria
@export var wrap_margin: float = 200.0  # Margen para reposicionar nubes

# Referencia a la cámara
var camera: Camera2D

func _ready():
	camera = get_viewport().get_camera_2d()
	
	# Dar velocidades ligeramente diferentes a cada nube
	for i in get_child_count():
		var cloud = get_child(i)
		if cloud is Sprite2D:
			# Guardar velocidad individual como metadata
			var speed_mult = randf_range(0.8, 1.2)
			cloud.set_meta("speed_multiplier", speed_mult)

func _process(delta):
	if not camera:
		return
	
	# Mover cada nube
	for child in get_children():
		if child is Sprite2D:
			move_cloud(child, delta)

func move_cloud(cloud: Sprite2D, delta: float):
	var speed_mult = cloud.get_meta("speed_multiplier", 1.0)
	var movement = wind_speed * speed_mult * delta
	
	# Agregar variación sutil
	movement.y += sin(Time.get_ticks_msec() / 1000.0 + cloud.get_index()) * wind_variation * delta
	
	cloud.position += movement
	
	# Reposicionar nube cuando sale del área visible
	var viewport_size = get_viewport_rect().size
	var camera_pos = camera.global_position
	
	# Si la nube sale por la derecha, reaparecer por la izquierda
	if cloud.global_position.x > camera_pos.x + viewport_size.x / 2 + wrap_margin:
		cloud.position.x -= viewport_size.x + wrap_margin * 2
	
	# Si sale por la izquierda, reaparecer por la derecha
	elif cloud.global_position.x < camera_pos.x - viewport_size.x / 2 - wrap_margin:
		cloud.position.x += viewport_size.x + wrap_margin * 2
