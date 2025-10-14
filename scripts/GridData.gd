# Archivo: res://GridData.gd
class_name GridData
extends Resource

@export var land_cost: int
@export var cells: Array[Vector2i]
@export var buildings: Array[BuildingData] # ¡Un array de nuestros recursos BuildingData!
