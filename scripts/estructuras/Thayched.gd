extends Building

func _ready():
	# Configurar las propiedades básicas del edificio
	building_name = "Thayched"
	scene_path = "res://escenas/Estructuras/Thayched.tscn"
	cost = 30
	points_per_second = 0.25
	description = "Una vivienda rústica y primitiva. Aunque es más económica, su construcción es menos eficiente para el crecimiento de la población."
	
	# Configurar las sinergias específicas de la casa
	synergies = {
		"House": 2,     
		"Villa": -20,    
		"Castle": -20     
	}
	
	# Llamar al _ready del padre
	super._ready()
	
	print("Casa inicializada - Nombre: ", building_name, ", PPS: ", points_per_second, ", Sinergias: ", synergies)
