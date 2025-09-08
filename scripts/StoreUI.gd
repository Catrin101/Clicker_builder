# StoreUI.gd - Interfaz de la tienda de edificios
extends VBoxContainer

# Referencias a nodos
@onready var buildings_list: VBoxContainer = $BuildingsList

# Lista de edificios disponibles para comprar
var available_buildings = [
	{
		"name": "Casa del Aldeano",
		"scene_path": "res://escenas/House.tscn",
		"cost": 50,
		"pps": 0.5,
		"description": "Un hogar modesto para tus aldeanos."
	}
	# Aquí se pueden añadir más edificios cuando los creemos
]

func _ready():
	# Crear los elementos de la tienda
	create_store_items()
	
	# Conectar señales del GameManager
	GameManager.points_changed.connect(_on_points_changed)
	GameManager.building_placement_started.connect(_on_building_placement_started)
	GameManager.building_placement_cancelled.connect(_on_building_placement_cancelled)

func create_store_items():
	# Limpiar la lista actual
	for child in buildings_list.get_children():
		child.queue_free()
	
	# Crear un botón para cada edificio
	for building_data in available_buildings:
		var building_item = create_building_item(building_data)
		buildings_list.add_child(building_item)

func create_building_item(building_data: Dictionary) -> Control:
	var container = VBoxContainer.new()
	
	# Botón principal
	var button = Button.new()
	button.text = building_data.name + "\n💰 " + str(building_data.cost) + " monedas"
	button.custom_minimum_size = Vector2(200, 60)
	
	# Label de información
	var info_label = Label.new()
	info_label.text = "⚡ +" + str(building_data.pps) + " PPS\n" + building_data.description
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size.y = 60
	
	# Añadir a contenedor
	container.add_child(button)
	container.add_child(info_label)
	container.add_child(HSeparator.new())
	
	# Conectar señal del botón
	button.pressed.connect(_on_building_button_pressed.bind(building_data))
	
	# Guardar referencia al building_data en el botón para fácil acceso
	button.set_meta("building_data", building_data)
	
	return container

func _on_building_button_pressed(building_data: Dictionary):
	print("Edificio seleccionado: ", building_data.name)
	
	# Verificar si el jugador puede comprarlo
	if not GameManager.can_afford(building_data.cost):
		print("No tienes suficientes puntos para comprar: ", building_data.name)
		return
	
	# Restar los puntos
	if GameManager.subtract_points(building_data.cost):
		# Iniciar modo de colocación
		GameManager.start_placing_mode(building_data.scene_path)

func _on_points_changed(new_points: int):
	# Actualizar el estado de los botones según los puntos disponibles
	update_buttons_state()

func _on_building_placement_started(_building_scene: String):
	# Deshabilitar todos los botones durante la colocación
	set_buttons_enabled(false)

func _on_building_placement_cancelled():
	# Rehabilitar los botones
	set_buttons_enabled(true)
	update_buttons_state()

func set_buttons_enabled(enabled: bool):
	for container in buildings_list.get_children():
		if container.get_child_count() > 0:
			var button = container.get_child(0)
			if button is Button:
				button.disabled = !enabled

func update_buttons_state():
	for container in buildings_list.get_children():
		if container.get_child_count() > 0:
			var button = container.get_child(0)
			if button is Button and button.has_meta("building_data"):
				var building_data = button.get_meta("building_data")
				var can_afford = GameManager.can_afford(building_data.cost)
				
				button.disabled = !can_afford
				
				# Cambiar el color según si puede comprarse o no
				if can_afford:
					button.modulate = Color.WHITE
				else:
					button.modulate = Color.GRAY

# Función para añadir más edificios dinámicamente
func add_building_to_store(building_data: Dictionary):
	available_buildings.append(building_data)
	# Recrear los elementos de la tienda
	call_deferred("create_store_items")
