extends Building

func _ready():
	# Configurar las propiedades básicas del edificio
	building_name = "BaseMilitar"
	cost = 2500
	points_per_second = 5.0
	description = "Un hogar modesto para tus aldeanos. Es la base de todo asentamiento."
	
	# Configurar las sinergias específicas de la casa
	synergies = {
		"Tavern": 5,   
		"Chapel": -5,    
		"Castle": 8,
		"House": -2    
	}
	
	# Llamar al _ready del padre
	super._ready()
	
	print("Base Militar inicializada - Nombre: ", building_name, ", PPS: ", points_per_second, ", Sinergias: ", synergies)
