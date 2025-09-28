# Thayched.gd - Script específico para Cabaña de Techo de Paja - CORREGIDO
extends Building

func _ready():
	# Configurar las propiedades básicas del edificio
	building_name = "Thayched"  # CORREGIDO: era "Thayvhed"
	cost = 30
	points_per_second = 0.25
	description = "Una vivienda rústica y primitiva. Aunque es más económica, su construcción es menos eficiente para el crecimiento de la población."
	
	# Configurar las sinergias específicas de la cabaña
	synergies = {
		"House": 2,        # +2% con Casa del Aldeano
		"Villa": -20,      # -20% con Villa del Comerciante
		"Castle": -20      # -20% con Castillo
	}
	
	# Llamar al _ready del padre
	super._ready()
	
	print("Cabaña de Techo de Paja inicializada - Nombre: ", building_name, ", PPS: ", points_per_second, ", Sinergias: ", synergies)
