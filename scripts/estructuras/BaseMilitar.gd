extends Building

func _ready():
	# Configurar las propiedades básicas del edificio
	building_name = "BaseMilitar"
	cost = 2500
	points_per_second = 6.0
	description = "Todo ciudad en crecimiento nesesita poteccion de una buena Milicia"
	
	synergies = {
		"Tavern": 5,   
		"Chapel": -5,   
		"Castle": 10
	}
	
	# Llamar al _ready del padre
	super._ready()
	
	print("Base Militar inicializada - Nombre: ", building_name, ", PPS: ", points_per_second, ", Sinergias: ", synergies)
