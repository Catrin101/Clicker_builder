extends Building

func _ready():
	# Configurar las propiedades básicas del edificio
	building_name = "Villa"
	cost = 3000
	points_per_second = 6.0
	description = "Una residencia opulenta para los más ricos de la sociedad. La villa atrae a comerciantes influyentes y eleva el prestigio de tu pueblo."
	
	# Configurar las sinergias específicas de la casa
	synergies = {
		"Inn": 10,    
		"Castle": 10,   
		"Tavern": -15, 
		"Thayched": -15   
	}
	
	# Llamar al _ready del padre
	super._ready()
	
	print("Villa inicializada - Nombre: ", building_name, ", PPS: ", points_per_second, ", Sinergias: ", synergies)
