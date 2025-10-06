# House.gd - Script específico para la Casa del Aldeano (CORREGIDO)
extends Building

func _ready():
	# Configurar las propiedades básicas del edificio
	building_name = "House"
	scene_path = "res://escenas/Estructuras/House.tscn"
	cost = 50
	points_per_second = 0.5
	description = "Un hogar modesto para tus aldeanos. Es la base de todo asentamiento."
	
	# Configurar las sinergias específicas de la casa
	synergies = {
		"Tavern": 5,      # +5% con Taberna
		"Chapel": 5,      # +5% con Capilla
		"Castle": -5      # -5% con Castillo
	}
	
	# Llamar al _ready del padre
	super._ready()
	
	print("Casa inicializada - Nombre: ", building_name, ", PPS: ", points_per_second, ", Sinergias: ", synergies)
