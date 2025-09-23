extends Building

func _ready():
	# Configurar las propiedades básicas del edificio
	building_name = "Chapel"
	cost = 800
	points_per_second = 2.5
	description = "Un lugar de oración y reflexión que satisface las necesidades espirituales de tu gente, mejorando la moral y la estabilidad general del pueblo."
	
	# Configurar las sinergias específicas de la casa
	synergies = {
		"House": 15,      # +15% con Casa del aldeano
		"Tavern": -10,      # -10% con Taverna
	}
	
	# Llamar al _ready del padre
	super._ready()
	
	print("Capilla inicializada - Nombre: ", building_name, ", PPS: ", points_per_second, ", Sinergias: ", synergies)
