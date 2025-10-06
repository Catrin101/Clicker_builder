extends Building

func _ready():
	# Configurar las propiedades básicas del edificio
	building_name = "TreeHouse"
	scene_path = "res://escenas/Estructuras/TreeHouse.tscn"
	cost = 5000
	points_per_second = 8.0
	description = "Un edificio mágico y único, escondido en la cima de los árboles. Proporciona una gran cantidad de monedas por su singularidad y encanto."
	
	# Configurar las sinergias específicas de la casa
	synergies = {
		"Chapel": 15
	}
	
	# Llamar al _ready del padre
	super._ready()
	
	print("TreeHouse inicializada - Nombre: ", building_name, ", PPS: ", points_per_second, ", Sinergias: ", synergies)
