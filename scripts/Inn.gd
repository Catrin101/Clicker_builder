# Inn.gd - Script específico para La Posada del Caminante
extends Building

func _ready():
	# Configurar las propiedades básicas del edificio
	building_name = "Inn"
	cost = 400
	points_per_second = 3.5
	description = "Más que un simple bar, la posada ofrece un lugar para descansar a los viajeros cansados."
	
	# Configurar las sinergias específicas de la posada
	synergies = {
		"Tavern": 10,     # +10% con Taberna
		"Villa": 10,      # +10% con Villa
		"Castle": -5      # -5% con Castillo
	}
	
	# Llamar al _ready del padre
	super._ready()
	
	print("Posada inicializada - Nombre: ", building_name, ", PPS: ", points_per_second, ", Sinergias: ", synergies)
