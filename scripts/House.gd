# House.gd - Script específico para la Casa del Aldeano
extends Building

func _ready():
	# Configurar las sinergias específicas de la casa
	synergies = {
		"Tavern": 5,      # +5% con Taberna
		"Chapel": 5,      # +5% con Capilla
		"Castle": -5      # -5% con Castillo
	}
	
	# Llamar al _ready del padre
	super._ready()
	
	print("Casa inicializada con sinergias: ", synergies)
