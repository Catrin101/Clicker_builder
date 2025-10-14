# Castle.gd - Script específico para el Castillo
extends Building

func _ready():
	# Configurar las propiedades básicas del edificio
	building_name = "Castle"
	scene_path = "res://escenas/Estructuras/Castle.tscn"
	cost = 2000
	points_per_second = 5.0
	description = "El corazón de tu reino. Esta fortaleza no solo protege a tu pueblo, sino que también sirve como el centro de mando."
	
	# Configurar las sinergias específicas del castillo
	synergies = {
		"Clock": 15,      # +15% con Torre del Reloj
		"Inn": -10        # -10% con Posada
	}
	
	# Llamar al _ready del padre
	super._ready()
	
	print("Castillo inicializado - Nombre: ", building_name, ", PPS: ", points_per_second, ", Sinergias: ", synergies)
