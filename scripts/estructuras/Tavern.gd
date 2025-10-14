# Tavern.gd - Script específico para La Taberna del Ciervo
extends Building

func _ready():
	# Configurar las propiedades básicas del edificio
	building_name = "Tavern"
	scene_path = "res://escenas/Estructuras/Tavern.tscn"
	cost = 250
	points_per_second = 2.0
	description = "Un animado punto de encuentro para los aldeanos. Aumenta su felicidad y productividad."
	
	# Configurar las sinergias específicas de la taberna
	synergies = {
		"Chapel": -10,    # -10% con Capilla
		"Castle": -10     # -10% con Castillo
	}
	
	# Llamar al _ready del padre
	super._ready()
	
	print("Taberna inicializada - Nombre: ", building_name, ", PPS: ", points_per_second, ", Sinergias: ", synergies)
