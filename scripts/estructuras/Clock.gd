extends Building

func _ready():
	# Configurar las propiedades básicas del edificio
	building_name = "Clock"
	cost = 1500
	points_per_second = 4.0
	description = "El pináculo de la ingeniería local. La Torre del Reloj mejora la coordinación de los trabajadores y es un símbolo del progreso de tu pueblo."
	
	# Configurar las sinergias específicas de la casa
	synergies = {
		"Tavern": 5,      # +5% con Taberna
		"House": 5,      # +5% con Casa del aldeano
	}
	
	# Llamar al _ready del padre
	super._ready()
	
	print("Clock inicializada - Nombre: ", building_name, ", PPS: ", points_per_second, ", Sinergias: ", synergies)
